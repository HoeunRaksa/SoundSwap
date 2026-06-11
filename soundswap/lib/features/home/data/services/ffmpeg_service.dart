import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'dart:math';
import 'package:path/path.dart' as p;

import 'package:soundswap/core/video/duration_mode.dart';
import 'package:soundswap/features/home/data/models/audio_settings.dart';
import 'package:soundswap/features/home/data/models/image_to_video_settings.dart';
import 'package:soundswap/features/home/data/models/soundswap_job.dart';

class FfmpegService {
  final Random _random = Random();
  String? _resolvedFfmpegPath;
  String? _resolvedFfprobePath;

  static final Map<String, double> _durationCache = {};
  static final Map<String, VideoDimensions> _dimensionsCache = {};

  static void clearProbeCache() {
    _durationCache.clear();
    _dimensionsCache.clear();
  }

  FfmpegService() {
    _locateExecutables();
  }

  void _locateExecutables() {
    // 1. Check relative to current working directory (dev)
    final devFfmpeg = p.normalize(
      p.join(Directory.current.path, 'tools', 'ffmpeg', 'ffmpeg.exe'),
    );
    final devFfprobe = p.normalize(
      p.join(Directory.current.path, 'tools', 'ffmpeg', 'ffprobe.exe'),
    );

    if (File(devFfmpeg).existsSync() && File(devFfprobe).existsSync()) {
      _resolvedFfmpegPath = devFfmpeg;
      _resolvedFfprobePath = devFfprobe;
      return;
    }

    // 2. Check relative to executable directory (prod)
    final exeDir = p.dirname(Platform.resolvedExecutable);
    final prodFfmpeg = p.normalize(
      p.join(exeDir, 'tools', 'ffmpeg', 'ffmpeg.exe'),
    );
    final prodFfprobe = p.normalize(
      p.join(exeDir, 'tools', 'ffmpeg', 'ffprobe.exe'),
    );

    if (File(prodFfmpeg).existsSync() && File(prodFfprobe).existsSync()) {
      _resolvedFfmpegPath = prodFfmpeg;
      _resolvedFfprobePath = prodFfprobe;
      return;
    }
  }

  bool get isReady =>
      _resolvedFfmpegPath != null && _resolvedFfprobePath != null;

  String get ffmpegPath =>
      _resolvedFfmpegPath ??
      p.normalize(
        p.join(Directory.current.path, 'tools', 'ffmpeg', 'ffmpeg.exe'),
      );
  String get ffprobePath =>
      _resolvedFfprobePath ??
      p.normalize(
        p.join(Directory.current.path, 'tools', 'ffmpeg', 'ffprobe.exe'),
      );

  Future<bool> isExecutableAvailable(String executable) async {
    try {
      final resolvedExecutable = _resolveExecutable(executable);
      if (resolvedExecutable.endsWith('.exe') &&
          !File(resolvedExecutable).existsSync()) {
        return false;
      }
      final result = await Process.run(resolvedExecutable, ['-version']);
      return result.exitCode == 0;
    } on Object {
      return false;
    }
  }

  Future<FfmpegRunResult> replaceAudio(
    SoundSwapJob job, {
    AudioSettings audioSettings = const AudioSettings(),
    DurationMode durationMode = DurationMode.trimAudioToVideo,
  }) async {
    final plan = await prepareReplacement(
      job,
      audioSettings: audioSettings,
      durationMode: durationMode,
    );
    final output = await runReplacement(plan);

    return FfmpegRunResult(
      command: plan.command,
      videoDuration: plan.videoDuration,
      audioDuration: plan.audioDuration,
      randomStart: plan.randomStart,
      stdout: output.stdout,
      stderr: output.stderr,
    );
  }

  Future<FfmpegReplacementPlan> prepareReplacement(
    SoundSwapJob job, {
    AudioSettings audioSettings = const AudioSettings(),
    DurationMode durationMode = DurationMode.trimAudioToVideo,
  }) async {
    final videoDuration = await probeDuration(job.video.path);
    final audioDuration = await probeDuration(job.audio.path);
    final commandPlan = buildReplaceAudioPlan(
      videoPath: job.video.path,
      audioPath: job.audio.path,
      outputPath: job.outputPath,
      videoDuration: videoDuration,
      audioDuration: audioDuration,
      audioSettings: audioSettings,
      durationMode: durationMode,
    );

    return FfmpegReplacementPlan(
      arguments: commandPlan.arguments,
      command: commandPlan.command,
      randomStart: commandPlan.randomStart,
      videoDuration: videoDuration,
      audioDuration: audioDuration,
    );
  }

  Future<ProcessRunOutput> runReplacement(FfmpegReplacementPlan plan) async {
    final result = await _runProcess(_ffmpegExecutable, plan.arguments);
    if (result.exitCode != 0) {
      throw FfmpegFailure(
        command: plan.command,
        exitCode: result.exitCode,
        stderr: result.stderr,
        stdout: result.stdout,
      );
    }
    return result;
  }

  Future<double> probeDuration(String inputPath) async {
    if (_durationCache.containsKey(inputPath)) {
      return _durationCache[inputPath]!;
    }
    final ffprobeExecutable = _ffprobeExecutable;
    final result = await _runProcess(ffprobeExecutable, [
      '-v',
      'error',
      '-show_entries',
      'format=duration',
      '-of',
      'default=noprint_wrappers=1:nokey=1',
      inputPath,
    ]);

    if (result.exitCode != 0) {
      throw FfmpegFailure(
        command: _formatCommand(ffprobeExecutable, [
          '-v',
          'error',
          '-show_entries',
          'format=duration',
          '-of',
          'default=noprint_wrappers=1:nokey=1',
          inputPath,
        ]),
        exitCode: result.exitCode,
        stderr: result.stderr,
        stdout: result.stdout,
      );
    }

    final duration = double.tryParse(result.stdout.trim());
    if (duration == null || duration <= 0) {
      throw FfmpegException(
        'Could not read media duration with ffprobe.\nInput: $inputPath\nOutput: ${result.stdout}',
      );
    }
    _durationCache[inputPath] = duration;
    return duration;
  }

  Future<VideoDimensions> probeVideoDimensions(String inputPath) async {
    if (_dimensionsCache.containsKey(inputPath)) {
      return _dimensionsCache[inputPath]!;
    }
    final ffprobeExecutable = _ffprobeExecutable;
    final arguments = [
      '-v',
      'error',
      '-select_streams',
      'v',
      '-show_entries',
      'stream=width,height,codec_name:stream_side_data=displaymatrix:stream_tags=rotate',
      '-of',
      'json',
      inputPath,
    ];
    final result = await _runProcess(ffprobeExecutable, arguments);

    if (result.exitCode != 0) {
      throw FfmpegFailure(
        command: _formatCommand(ffprobeExecutable, arguments),
        exitCode: result.exitCode,
        stderr: result.stderr,
        stdout: result.stdout,
      );
    }

    try {
      final Map<String, dynamic> data = jsonDecode(result.stdout);
      final streams = data['streams'] as List?;
      if (streams == null || streams.isEmpty) {
        throw FfmpegException('No video streams found in $inputPath');
      }

      int finalWidth = 0;
      int finalHeight = 0;
      int finalRawWidth = 0;
      int finalRawHeight = 0;
      int finalRotation = 0;
      int maxArea = 0;

      for (final streamMap in streams.cast<Map<String, dynamic>>()) {
        final w = streamMap['width'] as int?;
        final h = streamMap['height'] as int?;
        final codec = streamMap['codec_name'] as String?;
        if (codec == 'mjpeg' || codec == 'png' || codec == 'bmp') {
          continue;
        }
        if (w != null && h != null && w > 0 && h > 0) {
          int rotation = 0;
          final sideDataList = streamMap['side_data_list'] as List?;
          if (sideDataList != null) {
            for (final sideData in sideDataList.cast<Map>()) {
              final rot = sideData['rotation'];
              if (rot is num) {
                rotation = rot.toInt().abs();
              }
            }
          }
          final tags = streamMap['tags'] as Map?;
          if (tags != null) {
            final rotStr = tags['rotate'] ?? tags['rotation'];
            if (rotStr != null) {
              final rot = int.tryParse(rotStr.toString());
              if (rot != null) {
                rotation = rot.abs();
              }
            }
          }

          final actualW = (rotation == 90 || rotation == 270) ? h : w;
          final actualH = (rotation == 90 || rotation == 270) ? w : h;

          final area = actualW * actualH;
          if (area > maxArea) {
            maxArea = area;
            finalWidth = actualW;
            finalHeight = actualH;
            finalRawWidth = w;
            finalRawHeight = h;
            finalRotation = rotation;
          }
        }
      }

      if (finalWidth == 0) {
        for (final streamMap in streams.cast<Map<String, dynamic>>()) {
          final w = streamMap['width'] as int?;
          final h = streamMap['height'] as int?;
          if (w != null && h != null && w > 0 && h > 0) {
            final area = w * h;
            if (area > maxArea) {
              maxArea = area;
              finalWidth = w;
              finalHeight = h;
              finalRawWidth = w;
              finalRawHeight = h;
              finalRotation = 0;
            }
          }
        }
      }

      if (finalWidth <= 0 || finalHeight <= 0) {
        throw FfmpegException('Invalid video dimensions for $inputPath');
      }

      final dims = VideoDimensions(
        width: finalWidth,
        height: finalHeight,
        rotation: finalRotation,
        rawWidth: finalRawWidth,
        rawHeight: finalRawHeight,
      );
      _dimensionsCache[inputPath] = dims;
      return dims;
    } catch (e) {
      throw FfmpegException(
        'Could not parse ffprobe output JSON: $e\nInput: $inputPath\nOutput: ${result.stdout}',
      );
    }
  }

  /// Converts a still image into an MP4 video of the specified duration.
  Future<ProcessRunOutput> convertImageToVideo({
    required String imagePath,
    required String outputPath,
    required ImageToVideoSettings settings,
    int width = 1080,
    int height = 1920,
    double? durationOverride,
  }) async {
    final durationSec = durationOverride ?? settings.durationSeconds;
    final fitFilter = _imageVideoScaleFilter(settings.fitMode, width, height);

    final arguments = [
      '-y',
      '-loop',
      '1',
      '-framerate',
      '30',
      '-i',
      imagePath,
      '-t',
      _formatSeconds(durationSec),
      '-vf',
      fitFilter,
      '-c:v',
      'libx264',
      '-preset',
      'veryfast',
      '-crf',
      '18',
      '-pix_fmt',
      'yuv420p',
      '-an',
      outputPath,
    ];

    final result = await _runProcess(_ffmpegExecutable, arguments);
    if (result.exitCode != 0) {
      throw FfmpegFailure(
        command: _formatCommand(_ffmpegExecutable, arguments),
        exitCode: result.exitCode,
        stderr: result.stderr,
        stdout: result.stdout,
      );
    }
    return result;
  }

  String _imageVideoScaleFilter(
    ImageFitMode fitMode,
    int width,
    int height,
  ) {
    return switch (fitMode) {
      ImageFitMode.contain =>
        'scale=$width:$height:force_original_aspect_ratio=decrease,'
        'pad=$width:$height:(ow-iw)/2:(oh-ih)/2:black',
      ImageFitMode.cover =>
        'scale=$width:$height:force_original_aspect_ratio=increase,'
        'crop=$width:$height',
      ImageFitMode.stretch => 'scale=$width:$height',
      ImageFitMode.blurBackgroundFill =>
        'split[fg][bg];'
        '[bg]scale=$width:$height:force_original_aspect_ratio=increase,'
        'crop=$width:$height,gblur=sigma=28[blur];'
        '[fg]scale=$width:$height:force_original_aspect_ratio=decrease[fit];'
        '[blur][fit]overlay=(W-w)/2:(H-h)/2',
    };
  }

  FfmpegCommandPlan buildReplaceAudioPlan({
    required String videoPath,
    required String audioPath,
    required String outputPath,
    required double videoDuration,
    required double audioDuration,
    AudioSettings audioSettings = const AudioSettings(),
    DurationMode durationMode = DurationMode.trimAudioToVideo,
  }) {
    // Keep original only — just copy the video as-is (audio comes from video)
    if (audioSettings.mode == AudioMode.keepOriginalOnly) {
      final arguments = [
        '-y',
        '-i',
        videoPath,
        '-c',
        'copy',
        outputPath,
      ];
      return FfmpegCommandPlan(
        arguments: arguments,
        command: _formatCommand(_ffmpegExecutable, arguments),
        randomStart: 0,
      );
    }

    // Determine output duration flags based on mode
    final outputDuration = _outputDuration(
      videoDuration: videoDuration,
      audioDuration: audioDuration,
      durationMode: durationMode,
    );

    // Volume scalars
    final origVol = (audioSettings.originalAudioVolume / 100.0).toStringAsFixed(3);
    final newVol = (audioSettings.newAudioVolume / 100.0).toStringAsFixed(3);

    // Whether to use stream_loop (audio shorter than video)
    final needsLoop = audioDuration <= videoDuration;

    if (audioSettings.mode == AudioMode.mixOriginalAndNew) {
      // Mix mode: blend original video audio + replacement audio
      final randomStart = needsLoop
          ? 0.0
          : _random.nextDouble() * (audioDuration - videoDuration);

      final arguments = <String>[
        '-y',
        '-i',
        videoPath,
        if (!needsLoop) ...['-ss', _formatSeconds(randomStart)],
        if (needsLoop) ...['-stream_loop', '-1'],
        '-i',
        audioPath,
        '-filter_complex',
        '[0:a]volume=$origVol[oa];[1:a]volume=$newVol[na];[oa][na]amix=inputs=2:duration=shortest[aout]',
        '-map',
        '0:v',
        '-map',
        '[aout]',
        '-c:v',
        'copy',
        '-c:a',
        'aac',
        '-b:a',
        '192k',
        ...outputDuration.flags,
        outputPath,
      ];
      return FfmpegCommandPlan(
        arguments: arguments,
        command: _formatCommand(_ffmpegExecutable, arguments),
        randomStart: randomStart,
      );
    }

    // Replace mode (default): discard original audio, use replacement only
    if (audioDuration > videoDuration) {
      final maxStart = audioDuration - videoDuration;
      final randomStart = _random.nextDouble() * maxStart;
      final arguments = [
        '-y',
        '-i',
        videoPath,
        '-ss',
        _formatSeconds(randomStart),
        '-i',
        audioPath,
        '-map',
        '0:v',
        '-map',
        '1:a',
        '-c:v',
        'copy',
        '-c:a',
        'aac',
        '-b:a',
        '192k',
        if (newVol != '1.000') ...['-filter:a', 'volume=$newVol'],
        ...outputDuration.flags,
        outputPath,
      ];
      return FfmpegCommandPlan(
        arguments: arguments,
        command: _formatCommand(_ffmpegExecutable, arguments),
        randomStart: randomStart,
      );
    }

    final arguments = [
      '-y',
      '-i',
      videoPath,
      '-stream_loop',
      '-1',
      '-i',
      audioPath,
      '-map',
      '0:v',
      '-map',
      '1:a',
      '-c:v',
      'copy',
      '-c:a',
      'aac',
      '-b:a',
      '192k',
      if (newVol != '1.000') ...['-filter:a', 'volume=$newVol'],
      ...outputDuration.flags,
      outputPath,
    ];

    return FfmpegCommandPlan(
      arguments: arguments,
      command: _formatCommand(_ffmpegExecutable, arguments),
      randomStart: 0,
    );
  }

  _DurationFlags _outputDuration({
    required double videoDuration,
    required double audioDuration,
    required DurationMode durationMode,
  }) {
    return switch (durationMode) {
      DurationMode.trimAudioToVideo =>
        _DurationFlags(['-t', _formatSeconds(videoDuration)]),
      DurationMode.trimVideoToAudio =>
        _DurationFlags(['-t', _formatSeconds(audioDuration)]),
      DurationMode.useShortest =>
        _DurationFlags([
          '-t',
          _formatSeconds(videoDuration < audioDuration ? videoDuration : audioDuration),
        ]),
      DurationMode.useLongest =>
        _DurationFlags([
          '-t',
          _formatSeconds(videoDuration > audioDuration ? videoDuration : audioDuration),
        ]),
    };
  }

  Future<ProcessRunOutput> _runProcess(
    String executable,
    List<String> arguments, {
    Duration inactivityTimeout = const Duration(seconds: 60),
  }) async {
    late final Process process;
    try {
      process = await Process.start(executable, arguments);
    } on ProcessException catch (error) {
      throw FfmpegException(
        'Could not start $executable. Make sure FFmpeg is installed and available under tools/ffmpeg/.\n${error.message}',
      );
    }

    final stdoutBuffer = StringBuffer();
    final stderrBuffer = StringBuffer();

    Timer? timer;
    bool timedOut = false;

    void resetTimer() {
      timer?.cancel();
      timer = Timer(inactivityTimeout, () {
        timedOut = true;
        process.kill();
      });
    }

    resetTimer();

    final stdoutCompleter = Completer<void>();
    process.stdout.transform(utf8.decoder).listen(
      (data) {
        stdoutBuffer.write(data);
        resetTimer();
      },
      onDone: () => stdoutCompleter.complete(),
      onError: (e) => stdoutCompleter.completeError(e),
    );

    final stderrCompleter = Completer<void>();
    process.stderr.transform(utf8.decoder).listen(
      (data) {
        stderrBuffer.write(data);
        resetTimer();
      },
      onDone: () => stderrCompleter.complete(),
      onError: (e) => stderrCompleter.completeError(e),
    );

    final exitCode = await process.exitCode;
    timer?.cancel();

    try {
      await stdoutCompleter.future;
      await stderrCompleter.future;
    } catch (_) {}

    if (timedOut) {
      throw const FfmpegException('Failed: FFmpeg timeout');
    }

    return ProcessRunOutput(
      exitCode: exitCode,
      stdout: stdoutBuffer.toString(),
      stderr: stderrBuffer.toString(),
    );
  }

  String _formatSeconds(double seconds) => seconds.toStringAsFixed(3);

  String get _ffmpegExecutable => ffmpegPath;

  String get _ffprobeExecutable => ffprobePath;

  String _resolveExecutable(String executable) {
    if (executable == 'ffmpeg') {
      return ffmpegPath;
    }
    if (executable == 'ffprobe') {
      return ffprobePath;
    }
    return executable;
  }

  String _formatCommand(String executable, List<String> arguments) {
    return [executable, ...arguments.map(_quoteArgument)].join(' ');
  }

  String _quoteArgument(String argument) {
    if (!argument.contains(RegExp(r'[\s"]'))) {
      return argument;
    }
    return '"${argument.replaceAll('"', r'\"')}"';
  }
  Future<void> convertHeicToPng(String inputPath, String outputPath) async {
    final result = await _runProcess(ffmpegPath, [
      '-y',
      '-i',
      inputPath,
      outputPath,
    ]);
    if (result.exitCode != 0) {
      throw FfmpegException(
        'FFmpeg HEIC to PNG conversion failed (exit code ${result.exitCode}): ${result.stderr}',
      );
    }
  }

  /// Extracts a single raw RGB frame (64x64) for visual analysis.
  Future<List<int>?> extractRawFrame(String videoPath, String outRawPath, {int size = 64}) async {
    final expectedBytes = size * size * 3;
    // Try to extract at 1 second first (often has non-black content)
    try {
      final result = await _runProcess(ffmpegPath, [
        '-y',
        '-ss',
        '00:00:01',
        '-i',
        videoPath,
        '-vframes',
        '1',
        '-s',
        '${size}x$size',
        '-pix_fmt',
        'rgb24',
        '-f',
        'rawvideo',
        outRawPath,
      ]);
      if (result.exitCode == 0 && File(outRawPath).existsSync() && File(outRawPath).lengthSync() == expectedBytes) {
        return File(outRawPath).readAsBytesSync();
      }
    } catch (_) {}

    // Fallback: extract from the very beginning (00:00:00)
    try {
      final result = await _runProcess(ffmpegPath, [
        '-y',
        '-i',
        videoPath,
        '-vframes',
        '1',
        '-s',
        '${size}x$size',
        '-pix_fmt',
        'rgb24',
        '-f',
        'rawvideo',
        outRawPath,
      ]);
      if (result.exitCode == 0 && File(outRawPath).existsSync() && File(outRawPath).lengthSync() == expectedBytes) {
        return File(outRawPath).readAsBytesSync();
      }
    } catch (_) {}

    return null;
  }

  /// Uses FFmpeg's cropdetect filter to find the actual content area of a video.
  /// Returns a CropDetectResult with the detected crop rectangle (w:h:x:y).
  /// This works even with colored/blurred side bars, not just black bars.
  Future<CropDetectResult?> detectCropArea(String videoPath) async {
    // Analyze a few seconds of video using cropdetect
    // limit=24 is the threshold for "uniform" detection — a low value catches
    // even non-black borders (blurred backgrounds, colored bars).
    // round=2 avoids odd-number rounding issues.
    // We run on a short segment to keep it fast.
    try {
      final result = await _runProcess(ffmpegPath, [
        '-ss', '00:00:01',
        '-i', videoPath,
        '-t', '3',
        '-vf', 'cropdetect=limit=24:round=2:reset=0',
        '-f', 'null',
        '-',
      ]);

      // cropdetect outputs lines like: [Parsed_cropdetect_0 ... crop=W:H:X:Y
      // We want the last one (most stable detection after analyzing multiple frames)
      final stderr = result.stderr;
      final cropPattern = RegExp(r'crop=(\d+):(\d+):(\d+):(\d+)');
      final matches = cropPattern.allMatches(stderr).toList();

      if (matches.isEmpty) return null;

      // Use the last detected crop (most stable)
      final lastMatch = matches.last;
      final cropW = int.parse(lastMatch.group(1)!);
      final cropH = int.parse(lastMatch.group(2)!);
      final cropX = int.parse(lastMatch.group(3)!);
      final cropY = int.parse(lastMatch.group(4)!);

      return CropDetectResult(
        cropWidth: cropW,
        cropHeight: cropH,
        cropX: cropX,
        cropY: cropY,
      );
    } catch (_) {
      return null;
    }
  }
}

/// Result of FFmpeg cropdetect filter analysis.
class CropDetectResult {
  const CropDetectResult({
    required this.cropWidth,
    required this.cropHeight,
    required this.cropX,
    required this.cropY,
  });

  final int cropWidth;
  final int cropHeight;
  final int cropX;
  final int cropY;

  @override
  String toString() => 'crop=$cropWidth:$cropHeight:$cropX:$cropY';
}


class _DurationFlags {
  const _DurationFlags(this.flags);
  final List<String> flags;
}

class FfmpegCommandPlan {
  const FfmpegCommandPlan({
    required this.arguments,
    required this.command,
    required this.randomStart,
  });

  final List<String> arguments;
  final String command;
  final double randomStart;
}

class FfmpegReplacementPlan {
  const FfmpegReplacementPlan({
    required this.arguments,
    required this.command,
    required this.randomStart,
    required this.videoDuration,
    required this.audioDuration,
  });

  final List<String> arguments;
  final String command;
  final double randomStart;
  final double videoDuration;
  final double audioDuration;
}

class FfmpegRunResult {
  const FfmpegRunResult({
    required this.command,
    required this.videoDuration,
    required this.audioDuration,
    required this.randomStart,
    required this.stdout,
    required this.stderr,
  });

  final String command;
  final double videoDuration;
  final double audioDuration;
  final double randomStart;
  final String stdout;
  final String stderr;
}

class ProcessRunOutput {
  const ProcessRunOutput({
    required this.exitCode,
    required this.stdout,
    required this.stderr,
  });

  final int exitCode;
  final String stdout;
  final String stderr;
}

class VideoDimensions {
  const VideoDimensions({
    required this.width,
    required this.height,
    this.rotation = 0,
    required this.rawWidth,
    required this.rawHeight,
  });

  final int width;
  final int height;
  final int rotation;
  final int rawWidth;
  final int rawHeight;
}

class FfmpegException implements Exception {
  const FfmpegException(this.message);

  final String message;

  @override
  String toString() => message;
}

class FfmpegFailure extends FfmpegException {
  const FfmpegFailure({
    required this.command,
    required this.exitCode,
    required this.stderr,
    required this.stdout,
  }) : super('FFmpeg failed with exit code $exitCode.');

  final String command;
  final int exitCode;
  final String stderr;
  final String stdout;

  @override
  String toString() {
    return '[ERROR] FFmpeg failed\n'
        '[ERROR] Exit code: $exitCode\n'
        '[ERROR] STDERR:\n$stderr\n'
        '[ERROR] STDOUT:\n$stdout\n'
        '[INFO] Running FFmpeg command:\n$command';
  }
}

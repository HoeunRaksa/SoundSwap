import 'dart:convert';
import 'dart:io';
import 'dart:math';

import 'package:path/path.dart' as p;
import 'package:soundswap/features/home/data/models/image_to_video_settings.dart';
import 'package:soundswap/features/home/data/models/media_file.dart';
import 'package:soundswap/features/home/data/services/ffmpeg_service.dart';
import 'package:soundswap/features/long_video/data/models/long_video_plan.dart';

import '../../../../core/video/video_output_settings.dart';

typedef LongVideoProgress = Future<void> Function(String message);

class LongVideoService {
  LongVideoService({FfmpegService? ffmpegService, Random? random})
      : _ffmpegService = ffmpegService ?? FfmpegService(),
        _random = random ?? Random();

  final FfmpegService _ffmpegService;
  final Random _random;

  Future<LongVideoPlan> createPlan({
    required List<MediaFile> videos,
    required List<MediaFile> images,
    required List<MediaFile> audios,
    required String outputFolderPath,
    required String outputName,
    required double targetMinutes,
    required double clipSeconds,
    required LongVideoAudioMode audioMode,
    required ImageToVideoSettings imageSettings,
    String? selectedAudioPath,
    LongVideoDurationMode durationMode = LongVideoDurationMode.exactTargetLength,
    LongVideoAudioBehavior audioBehavior = LongVideoAudioBehavior.trimToFinalVideo,
  }) async {
    if (!_ffmpegService.isReady) {
      throw const FfmpegException(
        'FFmpeg files are missing in tools/ffmpeg. Please add ffmpeg.exe and ffprobe.exe.',
      );
    }
    if (videos.isEmpty && images.isEmpty) {
      throw const FfmpegException('No supported videos or images found.');
    }
    if (audios.isEmpty) {
      throw const FfmpegException('No supported audio files found.');
    }
    if (targetMinutes <= 0) {
      throw const FfmpegException('Target length must be greater than 0.');
    }
    if (clipSeconds <= 0) {
      throw const FfmpegException('Clip length must be greater than 0.');
    }

    final exactTargetSeconds = targetMinutes * 60.0;

    // Determine the baseline audio length
    double audioLength = 0.0;
    if (audios.isNotEmpty) {
      final selectedPath = selectedAudioPath ?? audios.first.path;
      final matchedAudio = audios.firstWhere(
        (a) => a.path == selectedPath,
        orElse: () => audios.first,
      );
      audioLength = await _ffmpegService.probeDuration(matchedAudio.path);
    }

    final allMedia = <MediaFile>[];
    if (videos.isNotEmpty) {
      allMedia.addAll(videos);
    }
    if (images.isNotEmpty) {
      allMedia.addAll(images);
    }
    allMedia.shuffle(_random);

    double videoPlanLength = 0.0;
    for (final media in allMedia) {
      if (media.isImage) {
        videoPlanLength += imageSettings.durationSeconds;
      } else {
        try {
          final d = await _ffmpegService.probeDuration(media.path);
          videoPlanLength += min(d, clipSeconds);
        } catch (_) {
          videoPlanLength += clipSeconds;
        }
      }
    }

    // Resolve target duration based on mode
    double finalTargetSeconds = exactTargetSeconds;
    switch (durationMode) {
      case LongVideoDurationMode.exactTargetLength:
        finalTargetSeconds = exactTargetSeconds;
        break;
      case LongVideoDurationMode.matchAudioLength:
        finalTargetSeconds = audioLength;
        break;
      case LongVideoDurationMode.matchVideoPlanLength:
        finalTargetSeconds = videoPlanLength;
        break;
      case LongVideoDurationMode.useShortest:
        finalTargetSeconds = min(exactTargetSeconds, audioLength);
        break;
      case LongVideoDurationMode.useLongest:
        finalTargetSeconds = max(exactTargetSeconds, audioLength);
        break;
    }

    if (finalTargetSeconds <= 0.001) {
      finalTargetSeconds = exactTargetSeconds > 0 ? exactTargetSeconds : 60.0;
    }

    final clips = <LongVideoClip>[];
    var totalDuration = 0.0;
    var mediaIndex = 0;

    while (totalDuration < finalTargetSeconds && allMedia.isNotEmpty) {
      final media = allMedia[mediaIndex % allMedia.length];
      mediaIndex++;

      final remaining = finalTargetSeconds - totalDuration;
      if (remaining <= 0.001) break;

      double duration;
      double clipDuration;

      if (media.isImage) {
        duration = imageSettings.durationSeconds;
        clipDuration = min(duration, remaining);
      } else {
        duration = await _ffmpegService.probeDuration(media.path);
        clipDuration = min(min(duration, clipSeconds), remaining);
      }

      if (clipDuration <= 0.001) continue;
      clips.add(
        LongVideoClip(
          videoPath: media.path,
          sourceDuration: duration,
          clipDuration: clipDuration,
        ),
      );
      totalDuration += clipDuration;

      if (durationMode == LongVideoDurationMode.matchVideoPlanLength && mediaIndex >= allMedia.length) {
        break;
      }
    }

    if (clips.isEmpty) {
      throw const FfmpegException('Could not build a clip plan.');
    }

    final audioSegments = await _buildAudioSegments(
      audios: audios,
      audioMode: audioMode,
      selectedAudioPath: selectedAudioPath,
      targetSeconds: totalDuration,
      audioBehavior: audioBehavior,
    );

    return LongVideoPlan(
      clips: clips,
      audioSegments: audioSegments,
      estimatedDuration: totalDuration,
      outputPath: _uniqueOutputPath(
        outputFolderPath: outputFolderPath,
        outputName: outputName,
      ),
    );
  }

  Future<void> exportPlan(
    LongVideoPlan plan, {
    required ImageToVideoSettings imageSettings,
    VideoOutputSize? outputSize,
    VideoFitMode? fitMode,
    LongVideoProgress? onProgress,
  }) async {
    final outputDirectory = Directory(p.dirname(plan.outputPath));
    await outputDirectory.create(recursive: true);
    final tempDirectory = Directory(
      p.join(
        outputDirectory.path,
        '.soundswap_long_${DateTime.now().microsecondsSinceEpoch}',
      ),
    );
    await tempDirectory.create(recursive: true);

    try {
      final videoFilter = _buildVideoFilter(
        outputSize: outputSize,
        fitMode: fitMode,
      );

      final clipPaths = <String>[];
      for (var i = 0; i < plan.clips.length; i++) {
        final clip = plan.clips[i];
        final tempClip = p.join(
          tempDirectory.path,
          'clip_${i.toString().padLeft(3, '0')}.mp4',
        );
        await onProgress?.call('Preparing clip ${i + 1}/${plan.clips.length}');

        final mediaFile = MediaFile(path: clip.videoPath);
        if (mediaFile.isImage) {
          var targetW = 1080;
          var targetH = 1920;
          final resolvedSize = _resolveOutputSize(outputSize);
          if (resolvedSize != null) {
            targetW = resolvedSize.width;
            targetH = resolvedSize.height;
          } else {
            try {
              final dims =
                  await _ffmpegService.probeVideoDimensions(clip.videoPath);
              targetW = dims.width;
              targetH = dims.height;
              if (targetW % 2 != 0) targetW += 1;
              if (targetH % 2 != 0) targetH += 1;
            } catch (_) {}
          }

          await _ffmpegService.convertImageToVideo(
            imagePath: clip.videoPath,
            outputPath: tempClip,
            settings: ImageToVideoSettings(
              durationValue: max(1, clip.clipDuration.round()),
              durationUnit: ImageDurationUnit.seconds,
              fitMode: imageSettings.fitMode,
            ),
            width: targetW,
            height: targetH,
            durationOverride: clip.clipDuration,
          );
        } else {
          await _runFfmpeg([
            '-y',
            '-i',
            clip.videoPath,
            '-t',
            _seconds(clip.clipDuration),
            '-an',
            '-vf',
            videoFilter,
            '-c:v',
            'libx264',
            '-preset',
            'veryfast',
            '-crf',
            '20',
            '-pix_fmt',
            'yuv420p',
            tempClip,
          ]);
        }
        clipPaths.add(tempClip);
      }

      final videoList = File(p.join(tempDirectory.path, 'clips.txt'));
      await videoList.writeAsString(_concatList(clipPaths));
      final combinedVideo = p.join(tempDirectory.path, 'combined_video.mp4');
      await onProgress?.call('Combining video clips');
      await _runFfmpeg([
        '-y',
        '-f',
        'concat',
        '-safe',
        '0',
        '-i',
        videoList.path,
        '-c',
        'copy',
        combinedVideo,
      ]);

      final audioPaths = <String>[];
      for (var i = 0; i < plan.audioSegments.length; i++) {
        final segment = plan.audioSegments[i];
        final tempAudio = p.join(
          tempDirectory.path,
          'audio_${i.toString().padLeft(3, '0')}.m4a',
        );
        await onProgress?.call(
          'Preparing audio ${i + 1}/${plan.audioSegments.length}',
        );
        await _runFfmpeg([
          '-y',
          '-i',
          segment.audioPath,
          '-t',
          _seconds(segment.segmentDuration),
          '-vn',
          '-c:a',
          'aac',
          '-b:a',
          '192k',
          tempAudio,
        ]);
        audioPaths.add(tempAudio);
      }

      final audioList = File(p.join(tempDirectory.path, 'audios.txt'));
      await audioList.writeAsString(_concatList(audioPaths));
      final combinedAudio = p.join(tempDirectory.path, 'combined_audio.m4a');
      await onProgress?.call('Combining audio');
      await _runFfmpeg([
        '-y',
        '-f',
        'concat',
        '-safe',
        '0',
        '-i',
        audioList.path,
        '-c',
        'copy',
        combinedAudio,
      ]);

      await onProgress?.call('Writing final MP4');
      await _runFfmpeg([
        '-y',
        '-i',
        combinedVideo,
        '-i',
        combinedAudio,
        '-map',
        '0:v',
        '-map',
        '1:a',
        '-c:v',
        'copy',
        '-c:a',
        'aac',
        '-t',
        _seconds(plan.estimatedDuration),
        plan.outputPath,
      ]);
      await onProgress?.call('Export completed: ${plan.outputName}');
    } finally {
      if (tempDirectory.existsSync()) {
        await tempDirectory.delete(recursive: true);
      }
    }
  }

  Future<List<LongVideoAudioSegment>> _buildAudioSegments({
    required List<MediaFile> audios,
    required LongVideoAudioMode audioMode,
    required String? selectedAudioPath,
    required double targetSeconds,
    required LongVideoAudioBehavior audioBehavior,
  }) async {
    final ordered = <MediaFile>[];
    if (audioMode == LongVideoAudioMode.selectedFile) {
      final selected = audios.firstWhere(
        (audio) => audio.path == selectedAudioPath,
        orElse: () => audios.first,
      );
      ordered.add(selected);
      ordered.addAll(audios.where((audio) => audio.path != selected.path));
    } else {
      ordered.addAll([...audios]..shuffle(_random));
    }

    if (ordered.isEmpty) return const [];

    final segments = <LongVideoAudioSegment>[];
    var remaining = targetSeconds;

    if (audioBehavior == LongVideoAudioBehavior.silenceWhenAudioEnds ||
        audioBehavior == LongVideoAudioBehavior.trimToFinalVideo) {
      final audio = ordered.first;
      final duration = await _ffmpegService.probeDuration(audio.path);
      final segmentDuration = min(duration, remaining);
      if (segmentDuration > 0.001) {
        segments.add(
          LongVideoAudioSegment(
            audioPath: audio.path,
            sourceDuration: duration,
            segmentDuration: segmentDuration,
          ),
        );
      }
    } else if (audioBehavior == LongVideoAudioBehavior.loopToFinalVideo) {
      final audio = ordered.first;
      final duration = await _ffmpegService.probeDuration(audio.path);
      while (remaining > 0.001) {
        final segmentDuration = min(duration, remaining);
        if (segmentDuration <= 0.001) break;
        segments.add(
          LongVideoAudioSegment(
            audioPath: audio.path,
            sourceDuration: duration,
            segmentDuration: segmentDuration,
          ),
        );
        remaining -= segmentDuration;
      }
    } else if (audioBehavior == LongVideoAudioBehavior.randomFillToFinalVideo) {
      var index = 0;
      while (remaining > 0.001) {
        final audio = ordered[index % ordered.length];
        final duration = await _ffmpegService.probeDuration(audio.path);
        final segmentDuration = min(duration, remaining);
        if (segmentDuration <= 0.001) break;
        segments.add(
          LongVideoAudioSegment(
            audioPath: audio.path,
            sourceDuration: duration,
            segmentDuration: segmentDuration,
          ),
        );
        remaining -= segmentDuration;
        index++;
      }
    }

    return segments;
  }

  Future<void> _runFfmpeg(List<String> arguments) async {
    final result = await _runProcess(_ffmpegService.ffmpegPath, arguments);
    if (result.exitCode != 0) {
      throw FfmpegFailure(
        command: _formatCommand(_ffmpegService.ffmpegPath, arguments),
        exitCode: result.exitCode,
        stderr: result.stderr,
        stdout: result.stdout,
      );
    }
  }

  Future<ProcessRunOutput> _runProcess(
      String executable,
      List<String> arguments,
      ) async {
    final process = await Process.start(executable, arguments);
    final stdout = StringBuffer();
    final stderr = StringBuffer();
    final stdoutDone = process.stdout
        .transform(utf8.decoder)
        .forEach(stdout.write);
    final stderrDone = process.stderr
        .transform(utf8.decoder)
        .forEach(stderr.write);
    final exitCode = await process.exitCode;
    await stdoutDone;
    await stderrDone;
    return ProcessRunOutput(
      exitCode: exitCode,
      stdout: stdout.toString(),
      stderr: stderr.toString(),
    );
  }

  String _uniqueOutputPath({
    required String outputFolderPath,
    required String outputName,
  }) {
    final trimmed = outputName.trim().isEmpty
        ? 'long-video'
        : outputName.trim();
    final baseName = p.basenameWithoutExtension(trimmed);
    final directory = Directory(outputFolderPath);
    if (!directory.existsSync()) directory.createSync(recursive: true);
    var candidate = p.join(outputFolderPath, '$baseName.mp4');
    var index = 1;
    while (File(candidate).existsSync()) {
      candidate = p.join(outputFolderPath, '$baseName-$index.mp4');
      index++;
    }
    return candidate;
  }

  String _buildVideoFilter({
    required VideoOutputSize? outputSize,
    required VideoFitMode? fitMode,
  }) {
    final selectedSize = _resolveOutputSize(outputSize);
    final selectedFitMode = _resolveFitMode(fitMode);

    if (selectedSize == null) {
      return 'setsar=1,fps=30';
    }

    final width = selectedSize.width;
    final height = selectedSize.height;

    switch (selectedFitMode) {
      case _ResolvedFitMode.cover:
        return 'scale=$width:$height:force_original_aspect_ratio=increase,crop=$width:$height,setsar=1,fps=30';

      case _ResolvedFitMode.contain:
        return 'scale=$width:$height:force_original_aspect_ratio=decrease,pad=$width:$height:(ow-iw)/2:(oh-ih)/2,setsar=1,fps=30';

      case _ResolvedFitMode.stretch:
        return 'scale=$width:$height,setsar=1,fps=30';
    }
  }

  _ResolvedOutputSize? _resolveOutputSize(VideoOutputSize? outputSize) {
    if (outputSize == null) {
      return const _ResolvedOutputSize(width: 1080, height: 1920);
    }

    final value = '${outputSize.name} ${outputSize.label}'.toLowerCase();

    if (value.contains('original')) {
      return null;
    }

    if (value.contains('2160') || value.contains('3840') || value.contains('4k')) {
      return const _ResolvedOutputSize(width: 2160, height: 3840);
    }

    if (value.contains('720') || value.contains('1280')) {
      return const _ResolvedOutputSize(width: 720, height: 1280);
    }

    return const _ResolvedOutputSize(width: 1080, height: 1920);
  }

  _ResolvedFitMode _resolveFitMode(VideoFitMode? fitMode) {
    if (fitMode == null) return _ResolvedFitMode.cover;

    final value = '${fitMode.name} ${fitMode.label}'.toLowerCase();

    if (value.contains('fill') ||
        value.contains('crop') ||
        value.contains('cover')) {
      return _ResolvedFitMode.cover;
    }

    if (value.contains('stretch')) {
      return _ResolvedFitMode.stretch;
    }

    if (value.contains('fit') ||
        value.contains('inside') ||
        value.contains('blurred') ||
        value.contains('background') ||
        value.contains('contain')) {
      return _ResolvedFitMode.contain;
    }

    if (value.contains('keep') || value.contains('original')) {
      return _ResolvedFitMode.contain;
    }

    return _ResolvedFitMode.cover;
  }

  String _concatList(List<String> paths) {
    return paths
        .map((path) => "file '${path.replaceAll("'", r"'\''")}'")
        .join('\n');
  }

  String _seconds(double value) => value.toStringAsFixed(3);

  String _formatCommand(String executable, List<String> arguments) {
    return [executable, ...arguments.map(_quote)].join(' ');
  }

  String _quote(String value) {
    if (!value.contains(RegExp(r'[\s"]'))) return value;
    return '"${value.replaceAll('"', r'\"')}"';
  }
}

class _ResolvedOutputSize {
  const _ResolvedOutputSize({
    required this.width,
    required this.height,
  });

  final int width;
  final int height;
}

enum _ResolvedFitMode {
  cover,
  contain,
  stretch,
}
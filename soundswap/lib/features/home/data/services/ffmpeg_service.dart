import 'dart:convert';
import 'dart:io';
import 'dart:math';
import 'package:path/path.dart' as p;

import 'package:soundswap/features/home/data/models/soundswap_job.dart';

class FfmpegService {
  final Random _random = Random();
  String? _resolvedFfmpegPath;
  String? _resolvedFfprobePath;

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

  Future<FfmpegRunResult> replaceAudio(SoundSwapJob job) async {
    final plan = await prepareReplacement(job);
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

  Future<FfmpegReplacementPlan> prepareReplacement(SoundSwapJob job) async {
    final videoDuration = await probeDuration(job.video.path);
    final audioDuration = await probeDuration(job.audio.path);
    final commandPlan = buildReplaceAudioPlan(
      videoPath: job.video.path,
      audioPath: job.audio.path,
      outputPath: job.outputPath,
      videoDuration: videoDuration,
      audioDuration: audioDuration,
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
    return duration;
  }

  FfmpegCommandPlan buildReplaceAudioPlan({
    required String videoPath,
    required String audioPath,
    required String outputPath,
    required double videoDuration,
    required double audioDuration,
  }) {
    final formattedVideoDuration = _formatSeconds(videoDuration);

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
        '-t',
        formattedVideoDuration,
        '-shortest',
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
      '-t',
      formattedVideoDuration,
      outputPath,
    ];

    return FfmpegCommandPlan(
      arguments: arguments,
      command: _formatCommand(_ffmpegExecutable, arguments),
      randomStart: 0,
    );
  }

  Future<ProcessRunOutput> _runProcess(
    String executable,
    List<String> arguments,
  ) async {
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
    final stdoutDone = process.stdout
        .transform(utf8.decoder)
        .forEach(stdoutBuffer.write);
    final stderrDone = process.stderr
        .transform(utf8.decoder)
        .forEach(stderrBuffer.write);
    final exitCode = await process.exitCode;

    await stdoutDone;
    await stderrDone;

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

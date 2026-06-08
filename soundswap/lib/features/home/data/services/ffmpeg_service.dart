import 'dart:convert';
import 'dart:io';
import 'dart:math';

import 'package:soundswap/features/home/data/models/soundswap_job.dart';

class FfmpegService {
  final Random _random = Random();

  Future<void> replaceAudio(SoundSwapJob job) async {
    final videoDuration = await _probeDuration(job.video.path);
    final audioDuration = await _probeDuration(job.audio.path);
    final arguments = _buildReplaceAudioArguments(
      videoPath: job.video.path,
      audioPath: job.audio.path,
      outputPath: job.outputPath,
      videoDuration: videoDuration,
      audioDuration: audioDuration,
    );

    await _runProcess('ffmpeg', arguments);
  }

  Future<double> _probeDuration(String inputPath) async {
    final output = await _runProcess('ffprobe', [
      '-v',
      'error',
      '-show_entries',
      'format=duration',
      '-of',
      'default=noprint_wrappers=1:nokey=1',
      inputPath,
    ]);

    final duration = double.tryParse(output.trim());
    if (duration == null || duration <= 0) {
      throw const FfmpegException(
        'Could not read media duration with ffprobe.',
      );
    }
    return duration;
  }

  List<String> _buildReplaceAudioArguments({
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

      return [
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
        '-t',
        formattedVideoDuration,
        '-shortest',
        outputPath,
      ];
    }

    return [
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
      '-t',
      formattedVideoDuration,
      outputPath,
    ];
  }

  Future<String> _runProcess(String executable, List<String> arguments) async {
    late final Process process;
    try {
      process = await Process.start(executable, arguments);
    } on ProcessException catch (error) {
      throw FfmpegException(
        'Could not start $executable. Make sure FFmpeg is installed and available on PATH.\n${error.message}',
      );
    }

    final stderrLines = <String>[];
    final stdoutBuffer = StringBuffer();

    final stdoutDone = process.stdout
        .transform(utf8.decoder)
        .forEach(stdoutBuffer.write);
    // FFmpeg writes most diagnostics to stderr. Keeping the tail gives useful
    // feedback without retaining a large log for long batches.
    final stderrDone = process.stderr
        .transform(utf8.decoder)
        .transform(const LineSplitter())
        .forEach((line) {
          stderrLines.add(line);
          if (stderrLines.length > 20) {
            stderrLines.removeAt(0);
          }
        });

    final exitCode = await process.exitCode;
    await stdoutDone;
    await stderrDone;

    if (exitCode != 0) {
      final message = stderrLines.isEmpty
          ? '$executable exited with code $exitCode.'
          : stderrLines.join('\n');
      throw FfmpegException(message);
    }

    return stdoutBuffer.toString();
  }

  String _formatSeconds(double seconds) => seconds.toStringAsFixed(3);
}

class FfmpegException implements Exception {
  const FfmpegException(this.message);

  final String message;

  @override
  String toString() => message;
}

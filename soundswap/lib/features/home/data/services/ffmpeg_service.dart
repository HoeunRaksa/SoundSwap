import 'dart:convert';
import 'dart:io';

import 'package:soundswap/features/home/data/models/soundswap_job.dart';

class FfmpegService {
  Future<void> replaceAudio(SoundSwapJob job) async {
    final process = await Process.start('ffmpeg', [
      '-i',
      job.video.path,
      '-i',
      job.audio.path,
      '-map',
      '0:v',
      '-map',
      '1:a',
      '-c:v',
      'copy',
      '-shortest',
      job.outputPath,
    ]);

    // FFmpeg writes most diagnostics to stderr. Keeping the tail gives useful
    // feedback without retaining a large log for long batches.
    final stderrLines = <String>[];
    process.stderr
        .transform(utf8.decoder)
        .transform(const LineSplitter())
        .listen((line) {
          stderrLines.add(line);
          if (stderrLines.length > 20) {
            stderrLines.removeAt(0);
          }
        });

    await process.stdout.drain<void>();
    final exitCode = await process.exitCode;
    if (exitCode != 0) {
      final message = stderrLines.isEmpty
          ? 'FFmpeg exited with code $exitCode.'
          : stderrLines.join('\n');
      throw FfmpegException(message);
    }
  }
}

class FfmpegException implements Exception {
  const FfmpegException(this.message);

  final String message;

  @override
  String toString() => message;
}

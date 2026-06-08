import 'dart:convert';
import 'dart:io';

import 'package:archive/archive_io.dart';
import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';

enum FfmpegSetupStep {
  idle,
  downloading,
  extracting,
  validating,
  ready,
  failed,
}

class FfmpegToolPaths {
  const FfmpegToolPaths({required this.ffmpegPath, required this.ffprobePath});

  final String ffmpegPath;
  final String ffprobePath;

  Map<String, Object?> toJson() => {
    'ffmpegPath': ffmpegPath,
    'ffprobePath': ffprobePath,
  };

  static FfmpegToolPaths? fromJson(Map<String, Object?> json) {
    final ffmpegPath = json['ffmpegPath'] as String?;
    final ffprobePath = json['ffprobePath'] as String?;
    if (ffmpegPath == null || ffprobePath == null) {
      return null;
    }
    return FfmpegToolPaths(ffmpegPath: ffmpegPath, ffprobePath: ffprobePath);
  }
}

class FfmpegSetupProgress {
  const FfmpegSetupProgress({
    required this.step,
    required this.message,
    this.progress,
  });

  final FfmpegSetupStep step;
  final String message;
  final double? progress;
}

class FfmpegSetupService {
  static const downloadUrl =
      'https://www.gyan.dev/ffmpeg/builds/ffmpeg-release-essentials.zip';

  Future<Directory> get soundSwapDataDirectory async {
    final support = await getApplicationSupportDirectory();
    final directory = Directory(p.join(support.path, 'SoundSwap'));
    await directory.create(recursive: true);
    return directory;
  }

  Future<Directory> get toolsDirectory async {
    final data = await soundSwapDataDirectory;
    final directory = Directory(p.join(data.path, 'tools', 'ffmpeg'));
    await directory.create(recursive: true);
    return directory;
  }

  Future<File> get pathsFile async {
    final directory = await toolsDirectory;
    return File(p.join(directory.path, 'ffmpeg_paths.json'));
  }

  Future<FfmpegToolPaths?> loadSavedPaths() async {
    final file = await pathsFile;
    if (!file.existsSync()) {
      return null;
    }

    final json = jsonDecode(await file.readAsString());
    if (json is! Map<String, Object?>) {
      return null;
    }

    final paths = FfmpegToolPaths.fromJson(json);
    if (paths == null || !await validatePaths(paths)) {
      return null;
    }
    return paths;
  }

  Future<bool> validatePaths(FfmpegToolPaths paths) async {
    final ffmpeg = File(paths.ffmpegPath);
    final ffprobe = File(paths.ffprobePath);
    return ffmpeg.existsSync() && ffprobe.existsSync();
  }

  Future<void> savePaths(FfmpegToolPaths paths) async {
    final file = await pathsFile;
    await file.writeAsString(
      const JsonEncoder.withIndent('  ').convert(paths.toJson()),
      flush: true,
    );
  }

  Stream<FfmpegSetupProgress> install() async* {
    final directory = await toolsDirectory;
    final archivePath = p.join(directory.path, 'ffmpeg-release-essentials.zip');

    try {
      yield const FfmpegSetupProgress(
        step: FfmpegSetupStep.downloading,
        message: 'Downloading FFmpeg from Gyan FFmpeg Builds...',
        progress: 0,
      );
      await _downloadZip(
        url: Uri.parse(downloadUrl),
        outputPath: archivePath,
        onProgress: (progress) {},
      );

      yield const FfmpegSetupProgress(
        step: FfmpegSetupStep.extracting,
        message: 'Extracting FFmpeg tools...',
      );
      await _extractZip(archivePath: archivePath, outputDirectory: directory);

      yield const FfmpegSetupProgress(
        step: FfmpegSetupStep.validating,
        message: 'Validating ffmpeg.exe and ffprobe.exe...',
      );
      final paths = await _findToolPaths(directory);
      if (paths == null) {
        throw const FfmpegSetupException(
          'Could not find ffmpeg.exe and ffprobe.exe in the extracted archive.',
        );
      }
      await savePaths(paths);

      yield FfmpegSetupProgress(
        step: FfmpegSetupStep.ready,
        message: 'FFmpeg is ready.',
        progress: 1,
      );
    } catch (error, stackTrace) {
      yield FfmpegSetupProgress(
        step: FfmpegSetupStep.failed,
        message: 'FFmpeg setup failed: $error',
      );
      Error.throwWithStackTrace(error, stackTrace);
    }
  }

  Future<void> _downloadZip({
    required Uri url,
    required String outputPath,
    required void Function(double progress) onProgress,
  }) async {
    final client = HttpClient();
    try {
      final request = await client.getUrl(url);
      final response = await request.close();
      if (response.statusCode != HttpStatus.ok) {
        throw FfmpegSetupException(
          'Download failed with HTTP ${response.statusCode}: ${response.reasonPhrase}',
        );
      }

      final file = File(outputPath);
      final sink = file.openWrite();
      var received = 0;
      final total = response.contentLength;
      await for (final chunk in response) {
        received += chunk.length;
        sink.add(chunk);
        if (total > 0) {
          onProgress(received / total);
        }
      }
      await sink.flush();
      await sink.close();
    } finally {
      client.close(force: true);
    }
  }

  Future<void> _extractZip({
    required String archivePath,
    required Directory outputDirectory,
  }) async {
    final inputStream = InputFileStream(archivePath);
    try {
      final archive = ZipDecoder().decodeStream(inputStream);
      for (final file in archive.files) {
        final outputPath = p.normalize(p.join(outputDirectory.path, file.name));
        if (!p.isWithin(outputDirectory.path, outputPath)) {
          throw const FfmpegSetupException(
            'Archive contains an unsafe file path.',
          );
        }

        if (file.isFile) {
          final output = OutputFileStream(outputPath);
          try {
            file.writeContent(output);
          } finally {
            await output.close();
          }
        } else {
          await Directory(outputPath).create(recursive: true);
        }
      }
    } finally {
      await inputStream.close();
    }
  }

  Future<FfmpegToolPaths?> _findToolPaths(Directory directory) async {
    String? ffmpegPath;
    String? ffprobePath;

    await for (final entity in directory.list(recursive: true)) {
      if (entity is! File) {
        continue;
      }
      final name = p.basename(entity.path).toLowerCase();
      if (name == 'ffmpeg.exe') {
        ffmpegPath = entity.path;
      }
      if (name == 'ffprobe.exe') {
        ffprobePath = entity.path;
      }
    }

    if (ffmpegPath == null || ffprobePath == null) {
      return null;
    }
    return FfmpegToolPaths(ffmpegPath: ffmpegPath, ffprobePath: ffprobePath);
  }
}

class FfmpegSetupException implements Exception {
  const FfmpegSetupException(this.message);

  final String message;

  @override
  String toString() => message;
}

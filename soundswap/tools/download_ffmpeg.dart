// ignore_for_file: avoid_print

import 'dart:io';
import 'package:archive/archive_io.dart';
import 'package:path/path.dart' as p;

const downloadUrl =
    'https://www.gyan.dev/ffmpeg/builds/ffmpeg-release-essentials.zip';

void main() async {
  final projectDir = Directory.current.path;
  final toolsDir = Directory(p.join(projectDir, 'tools', 'ffmpeg'));
  if (!toolsDir.existsSync()) {
    print('Creating directory ${toolsDir.path}...');
    await toolsDir.create(recursive: true);
  }

  final zipFile = File(p.join(projectDir, 'tools', 'ffmpeg_temp.zip'));
  final client = HttpClient();

  try {
    print('Downloading FFmpeg release essentials...');
    print('URL: $downloadUrl');

    final request = await client.getUrl(Uri.parse(downloadUrl));
    final response = await request.close();

    if (response.statusCode != HttpStatus.ok) {
      throw HttpException(
        'Download failed with status code ${response.statusCode}',
      );
    }

    final sink = zipFile.openWrite();
    var bytesDownloaded = 0;
    final totalBytes = response.contentLength;

    await for (final chunk in response) {
      bytesDownloaded += chunk.length;
      sink.add(chunk);
      if (totalBytes > 0) {
        final percent = (bytesDownloaded / totalBytes * 100).toStringAsFixed(1);
        stdout.write(
          '\rDownloading: $percent% ($bytesDownloaded / $totalBytes bytes)',
        );
      } else {
        stdout.write('\rDownloading: $bytesDownloaded bytes');
      }
    }
    await sink.flush();
    await sink.close();
    print('\nDownload complete.');

    print('Extracting executables...');
    final inputStream = InputFileStream(zipFile.path);
    final archive = ZipDecoder().decodeStream(inputStream);

    var ffmpegExtracted = false;
    var ffprobeExtracted = false;

    for (final file in archive.files) {
      if (!file.isFile) continue;

      final baseName = p.basename(file.name).toLowerCase();
      if (baseName == 'ffmpeg.exe') {
        final destPath = p.join(toolsDir.path, 'ffmpeg.exe');
        print('Extracting ffmpeg.exe to $destPath...');
        final outStream = OutputFileStream(destPath);
        file.writeContent(outStream);
        await outStream.close();
        ffmpegExtracted = true;
      } else if (baseName == 'ffprobe.exe') {
        final destPath = p.join(toolsDir.path, 'ffprobe.exe');
        print('Extracting ffprobe.exe to $destPath...');
        final outStream = OutputFileStream(destPath);
        file.writeContent(outStream);
        await outStream.close();
        ffprobeExtracted = true;
      }

      if (ffmpegExtracted && ffprobeExtracted) {
        break;
      }
    }

    await inputStream.close();

    if (!ffmpegExtracted || !ffprobeExtracted) {
      throw Exception(
        'Failed to locate ffmpeg.exe and/or ffprobe.exe in the downloaded archive.',
      );
    }

    print('Cleaning up temporary files...');
    if (zipFile.existsSync()) {
      await zipFile.delete();
    }

    print('FFmpeg setup completed successfully!');
    print('ffmpeg.exe path: ${p.join(toolsDir.path, 'ffmpeg.exe')}');
    print('ffprobe.exe path: ${p.join(toolsDir.path, 'ffprobe.exe')}');
  } catch (e) {
    print('\nError during setup: $e');
    if (zipFile.existsSync()) {
      try {
        await zipFile.delete();
      } catch (_) {}
    }
    exit(1);
  } finally {
    client.close();
  }
}

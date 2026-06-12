import 'dart:io';

import 'package:path/path.dart' as p;
import 'package:soundswap/features/home/data/models/media_file.dart';

class ScanStats {
  int totalFilesDiscovered = 0;
  int supportedMediaDiscovered = 0;
  int skippedUnsupportedCount = 0;
  int skippedDestinationFolderCount = 0;
}

class MediaScannerService {
  Future<List<MediaFile>> scanFolder({
    required String folderPath,
    required List<String> extensions,
    ScanStats? stats,
  }) async {
    final rootDir = Directory(folderPath);
    if (!rootDir.existsSync()) {
      return [];
    }

    final normalizedExtensions = extensions.map((e) => e.toLowerCase()).toSet();
    final ignoredFolders = {'videos', 'images', 'duplicates', 'history', 'result', 'results', 'output', 'outputs'};
    final files = <File>[];

    Future<void> scanDirectory(Directory dir) async {
      List<FileSystemEntity> entities;
      try {
        entities = await dir.list(followLinks: false).toList();
      } catch (e) {
        // Skip unreadable subfolders safely without terminating the whole scan
        return;
      }

      for (final entity in entities) {
        if (entity is File) {
          stats?.totalFilesDiscovered++;
          final extension = p.extension(entity.path).toLowerCase();
          if (normalizedExtensions.contains(extension)) {
            stats?.supportedMediaDiscovered++;
            files.add(entity);
          } else {
            stats?.skippedUnsupportedCount++;
          }
        } else if (entity is Directory) {
          final dirName = p.basename(entity.path).toLowerCase();
          if (ignoredFolders.contains(dirName)) {
            stats?.skippedDestinationFolderCount++;
            continue; // Skip ignored folders entirely (do not recurse inside)
          }
          await scanDirectory(entity);
        }
      }
    }

    await scanDirectory(rootDir);

    final uniqueFiles = <String, File>{};
    for (final file in files) {
      uniqueFiles[p.normalize(file.path)] = file;
    }

    final sortedFiles = uniqueFiles.values.toList();
    sortedFiles.sort((a, b) => p.basename(a.path).compareTo(p.basename(b.path)));
    return sortedFiles.map((file) => MediaFile(path: file.path)).toList();
  }

  /// Returns the number of image files detected in [folderPath].
  Future<int> countImages(String folderPath) async {
    const imageExts = {'.jpg', '.jpeg', '.png', '.webp'};
    final rootDir = Directory(folderPath);
    if (!rootDir.existsSync()) return 0;
    var count = 0;
    
    Future<void> scanDir(Directory dir) async {
      List<FileSystemEntity> entities;
      try {
        entities = await dir.list(followLinks: false).toList();
      } catch (e) {
        return;
      }
      for (final entity in entities) {
        if (entity is File) {
          final ext = p.extension(entity.path).toLowerCase();
          if (imageExts.contains(ext)) count++;
        } else if (entity is Directory) {
          // Optimization: Skip result folders for image count as well if needed, 
          // or just scan everything for images. We'll skip common output folders.
          final dirName = p.basename(entity.path).toLowerCase();
          const ignored = {'result', 'results', 'output', 'outputs'};
          if (!ignored.contains(dirName)) {
            await scanDir(entity);
          }
        }
      }
    }

    await scanDir(rootDir);
    return count;
  }
}

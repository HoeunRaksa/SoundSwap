import 'dart:io';

import 'package:path/path.dart' as p;
import 'package:soundswap/features/home/data/models/media_file.dart';

class MediaScannerService {
  Future<List<MediaFile>> scanFolder({
    required String folderPath,
    required List<String> extensions,
  }) async {
    final directory = Directory(folderPath);
    if (!directory.existsSync()) {
      return [];
    }

    final normalizedExtensions = extensions.map((e) => e.toLowerCase()).toSet();
    final files = await directory
        .list(followLinks: false)
        .where((entity) => entity is File)
        .cast<File>()
        .where((file) {
          final extension = p.extension(file.path).toLowerCase();
          return normalizedExtensions.contains(extension);
        })
        .toList();

    files.sort((a, b) => p.basename(a.path).compareTo(p.basename(b.path)));
    return files.map((file) => MediaFile(path: file.path)).toList();
  }
}

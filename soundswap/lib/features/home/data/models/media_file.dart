import 'dart:io';

import 'package:path/path.dart' as p;

class MediaFile {
  const MediaFile({required this.path});

  final String path;

  String get name => p.basename(path);
  File get file => File(path);
}

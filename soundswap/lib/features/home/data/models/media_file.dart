import 'dart:io';

import 'package:path/path.dart' as p;
import 'package:soundswap/core/constants/app_constants.dart';

class MediaFile {
  const MediaFile({required this.path});

  final String path;

  String get name => p.basename(path);
  File get file => File(path);

  bool get isImage {
    final ext = p.extension(path).toLowerCase();
    return AppConstants.supportedImageExtensions.contains(ext);
  }
}

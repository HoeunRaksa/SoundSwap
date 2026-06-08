import 'package:path/path.dart' as p;
import 'package:soundswap/core/constants/app_constants.dart';

class FileNameUtils {
  const FileNameUtils._();

  static String outputFileName(String videoPath) {
    final baseName = p.basenameWithoutExtension(videoPath);
    return '$baseName${AppConstants.outputSuffix}';
  }
}

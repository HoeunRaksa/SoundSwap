import 'dart:io';

import 'package:path/path.dart' as p;

class OutputNamingService {
  const OutputNamingService();

  static const defaultPrefix = 'soundswap';

  List<String> allocateOutputPaths({
    required String outputFolderPath,
    required String prefix,
    required int count,
  }) {
    final normalizedPrefix = normalizePrefix(prefix);
    final start = _nextNumber(outputFolderPath, normalizedPrefix);
    return [
      for (var index = 0; index < count; index++)
        p.join(outputFolderPath, '$normalizedPrefix-${start + index}.mp4'),
    ];
  }

  String allocateSingleOutputPath({
    required String outputFolderPath,
    required String prefix,
  }) {
    return allocateOutputPaths(
      outputFolderPath: outputFolderPath,
      prefix: prefix,
      count: 1,
    ).first;
  }

  String normalizePrefix(String prefix) {
    final trimmed = prefix.trim();
    return trimmed.isEmpty ? defaultPrefix : trimmed;
  }

  int _nextNumber(String outputFolderPath, String prefix) {
    final directory = Directory(outputFolderPath);
    if (!directory.existsSync()) return 1;
    final escapedPrefix = RegExp.escape(prefix);
    final pattern = RegExp(
      '^$escapedPrefix-(\\d+)\\.mp4\$',
      caseSensitive: false,
    );
    var maxNumber = 0;

    for (final entity in directory.listSync(followLinks: false)) {
      if (entity is! File) continue;
      final match = pattern.firstMatch(p.basename(entity.path));
      if (match == null) continue;
      final number = int.tryParse(match.group(1) ?? '');
      if (number != null && number > maxNumber) {
        maxNumber = number;
      }
    }
    return maxNumber + 1;
  }
}

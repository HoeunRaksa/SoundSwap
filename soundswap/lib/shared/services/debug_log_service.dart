import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:path/path.dart' as p;

class DebugLogService {
  DebugLogService({Directory? logDirectory})
    : _logDirectory = logDirectory ?? Directory('logs');

  final Directory _logDirectory;

  File get logFile => File(p.join(_logDirectory.path, 'batch_log.txt'));

  Future<void> clear() async {
    await _logDirectory.create(recursive: true);
    await logFile.writeAsString('');
  }

  Future<void> append(String message) async {
    final line = '${DateTime.now().toIso8601String()} $message';
    debugPrint(line);
    await _logDirectory.create(recursive: true);
    await logFile.writeAsString('$line\n', mode: FileMode.append, flush: true);
  }
}

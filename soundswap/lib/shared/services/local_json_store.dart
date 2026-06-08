import 'dart:convert';
import 'dart:io';

import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';

class LocalJsonStore {
  Future<File> _file(String fileName) async {
    final support = await getApplicationSupportDirectory();
    final directory = Directory(p.join(support.path, 'SoundSwap', 'settings'));
    await directory.create(recursive: true);
    return File(p.join(directory.path, fileName));
  }

  Future<Map<String, Object?>> readMap(String fileName) async {
    final file = await _file(fileName);
    if (!file.existsSync()) return {};
    final decoded = jsonDecode(await file.readAsString());
    return decoded is Map<String, Object?> ? decoded : {};
  }

  Future<void> writeMap(String fileName, Map<String, Object?> value) async {
    final file = await _file(fileName);
    await file.writeAsString(
      const JsonEncoder.withIndent('  ').convert(value),
      flush: true,
    );
  }

  Future<List<Object?>> readList(String fileName) async {
    final file = await _file(fileName);
    if (!file.existsSync()) return [];
    final decoded = jsonDecode(await file.readAsString());
    return decoded is List<Object?> ? decoded : [];
  }

  Future<void> writeList(String fileName, List<Object?> value) async {
    final file = await _file(fileName);
    await file.writeAsString(
      const JsonEncoder.withIndent('  ').convert(value),
      flush: true,
    );
  }
}

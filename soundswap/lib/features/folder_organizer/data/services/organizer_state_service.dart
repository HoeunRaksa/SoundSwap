import 'dart:convert';
import 'dart:io';
import 'package:crypto/crypto.dart';
import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';
import 'package:soundswap/features/folder_organizer/data/models/organizer_state_record.dart';

class OrganizerStateService {
  String _getFolderHash(String folderPath) {
    final bytes = utf8.encode(p.normalize(folderPath).toLowerCase());
    return md5.convert(bytes).toString();
  }

  Future<File> _getStateFile(String folderPath) async {
    final support = await getApplicationSupportDirectory();
    final hash = _getFolderHash(folderPath);
    final directory = Directory(p.join(support.path, 'SoundSwap', 'folder_organizer'));
    if (!directory.existsSync()) {
      await directory.create(recursive: true);
    }
    return File(p.join(directory.path, 'state_$hash.json'));
  }

  Future<List<OrganizerStateRecord>> getRecords(String folderPath) async {
    try {
      final file = await _getStateFile(folderPath);
      if (!file.existsSync()) return [];
      final content = await file.readAsString();
      final decoded = jsonDecode(content);
      if (decoded is List) {
        return decoded
            .whereType<Map<String, dynamic>>()
            .map((e) => OrganizerStateRecord.fromJson(e))
            .toList();
      }
    } catch (_) {
      // Ignored
    }
    return [];
  }

  Future<void> _saveRecordsAtomic(String folderPath, List<OrganizerStateRecord> records) async {
    final file = await _getStateFile(folderPath);
    final tempFile = File('${file.path}.tmp');
    
    final jsonList = records.map((r) => r.toJson()).toList();
    final jsonString = const JsonEncoder.withIndent('  ').convert(jsonList);
    
    await tempFile.writeAsString(jsonString, flush: true);
    
    // Atomic rename
    tempFile.renameSync(file.path);
  }

  Future<void> addRecords(String folderPath, List<OrganizerStateRecord> newRecords) async {
    final records = await getRecords(folderPath);
    
    // Convert to map for fast updates/deduplication based on originalPath
    final map = {for (var r in records) r.originalPath: r};
    
    for (var nr in newRecords) {
      map[nr.originalPath] = nr;
    }
    
    await _saveRecordsAtomic(folderPath, map.values.toList());
  }

  Future<void> clearRecords(String folderPath) async {
    final file = await _getStateFile(folderPath);
    if (file.existsSync()) {
      await file.delete();
    }
  }
}

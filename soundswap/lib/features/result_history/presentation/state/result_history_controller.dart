import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:path/path.dart' as p;
import 'package:soundswap/core/constants/app_constants.dart';
import 'package:soundswap/features/result_history/data/models/result_history_record.dart';
import 'package:soundswap/features/result_history/data/services/result_history_service.dart';

class ResultHistoryController extends ChangeNotifier {
  ResultHistoryController({ResultHistoryService? service})
    : _service = service ?? ResultHistoryService();

  final ResultHistoryService _service;
  List<ResultHistoryRecord> records = [];
  String? message;

  Future<void> load() async {
    records = await _service.load();
    records.sort((a, b) => b.createdAt.compareTo(a.createdAt));
    notifyListeners();
  }

  Future<void> add(ResultHistoryRecord record) async {
    records = [record, ...records];
    await _service.saveAll(records);
    notifyListeners();
  }

  bool hasProcessed(String sourceVideoPath) {
    return records.any((record) => record.originalVideoPath == sourceVideoPath);
  }

  Future<void> removeRecord(ResultHistoryRecord record) async {
    records = records.where((item) => item.id != record.id).toList();
    await _service.saveAll(records);
    message = 'Record removed.';
    notifyListeners();
  }

  Future<void> deleteResultFile(ResultHistoryRecord record) async {
    await _deleteResultFileIfSafe(record);
    await removeRecord(record);
    message = 'Result file deleted.';
    notifyListeners();
  }

  Future<void> clearResultFolder(String resultFolderPath) async {
    final folder = Directory(resultFolderPath);
    if (!folder.existsSync()) return;
    final recordsToClear = records
        .where((record) => record.resultFolderPath == resultFolderPath)
        .toList();

    for (final record in recordsToClear) {
      await _deleteResultFileIfSafe(record);
    }

    records = records
        .where((record) => record.resultFolderPath != resultFolderPath)
        .toList();
    await _service.saveAll(records);
    message = 'Result folder cleared.';
    notifyListeners();
  }

  Future<int> removeDuplicateResults({required bool deleteFiles}) async {
    final seen = <String>{};
    final kept = <ResultHistoryRecord>[];
    final duplicates = <ResultHistoryRecord>[];

    for (final record in records) {
      final key = [
        record.originalVideoPath,
        record.audioPath,
        record.resultFolderPath,
      ].join('|');
      if (seen.contains(key)) {
        duplicates.add(record);
      } else {
        seen.add(key);
        kept.add(record);
      }
    }

    if (deleteFiles) {
      for (final record in duplicates) {
        await _deleteResultFileIfSafe(record);
      }
    }

    records = kept;
    await _service.saveAll(records);
    message = 'Removed ${duplicates.length} duplicate result records.';
    notifyListeners();
    return duplicates.length;
  }

  Future<void> openResultFolder(ResultHistoryRecord record) async {
    final folder = Directory(record.resultFolderPath);
    if (folder.existsSync()) {
      await Process.start('explorer.exe', [folder.path]);
    }
  }

  Future<void> _deleteResultFileIfSafe(ResultHistoryRecord record) async {
    if (!_isRecordedOutputInsideResultFolder(record)) return;
    final file = File(record.outputPath);
    if (file.existsSync()) {
      await file.delete();
    }
  }

  bool _isRecordedOutputInsideResultFolder(ResultHistoryRecord record) {
    if (record.outputPath.isEmpty || record.resultFolderPath.isEmpty) {
      return false;
    }
    if (!AppConstants.supportedVideoExtensions.contains(
      p.extension(record.outputPath).toLowerCase(),
    )) {
      return false;
    }
    return p.isWithin(record.resultFolderPath, record.outputPath);
  }
}

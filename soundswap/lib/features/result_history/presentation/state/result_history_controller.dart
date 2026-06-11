import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:path/path.dart' as p;
import 'package:soundswap/core/constants/app_constants.dart';
import 'package:soundswap/features/result_history/data/models/result_history_record.dart';
import 'package:soundswap/features/result_history/data/services/result_history_service.dart';

enum ResultDateFilter { today, last7Days, last30Days, allTime }

class ResultHistoryController extends ChangeNotifier {
  ResultHistoryController({ResultHistoryService? service})
    : _service = service ?? ResultHistoryService();

  final ResultHistoryService _service;
  List<ResultHistoryRecord> records = [];
  ResultProcessType? processFilter;
  String? resultFolderFilter;
  ResultDateFilter dateFilter = ResultDateFilter.allTime;
  String? searchQuery;
  int visibleLimit = 50;
  String? message;

  List<ResultHistoryRecord> get filteredRecords {
    final filter = processFilter;
    final folder = resultFolderFilter;
    final query = searchQuery?.toLowerCase().trim();

    return records.where((record) {
      final processMatches = filter == null || record.processType == filter;
      final folderMatches =
          folder == null ||
          p.equals(p.normalize(record.resultFolderPath), p.normalize(folder));
      final searchMatches = query == null || query.isEmpty ||
          p.basename(record.outputPath).toLowerCase().contains(query);
      final dateMatches = _dateMatches(record.createdAt);

      return processMatches && folderMatches && searchMatches && dateMatches;
    }).toList();
  }

  List<ResultHistoryRecord> get visibleRecords {
    final filtered = filteredRecords;
    if (filtered.length <= visibleLimit) {
      return filtered;
    }
    return filtered.take(visibleLimit).toList();
  }

  bool get hasMore => filteredRecords.length > visibleLimit;

  void loadMore() {
    visibleLimit += 50;
    notifyListeners();
  }

  bool _dateMatches(DateTime dateTime) {
    final now = DateTime.now();
    final todayStart = DateTime(now.year, now.month, now.day);
    switch (dateFilter) {
      case ResultDateFilter.today:
        return dateTime.isAfter(todayStart);
      case ResultDateFilter.last7Days:
        final sevenDaysAgo = todayStart.subtract(const Duration(days: 7));
        return dateTime.isAfter(sevenDaysAgo);
      case ResultDateFilter.last30Days:
        final thirtyDaysAgo = todayStart.subtract(const Duration(days: 30));
        return dateTime.isAfter(thirtyDaysAgo);
      case ResultDateFilter.allTime:
        return true;
    }
  }

  List<String> get resultFolders {
    final folders = <String>{};
    for (final record in records) {
      if (record.resultFolderPath.trim().isNotEmpty) {
        folders.add(p.normalize(record.resultFolderPath));
      }
    }
    return folders.toList()..sort();
  }

  void setProcessFilter(ResultProcessType? filter) {
    processFilter = filter;
    visibleLimit = 50;
    notifyListeners();
  }

  void setResultFolderFilter(String? folder) {
    resultFolderFilter = folder;
    visibleLimit = 50;
    notifyListeners();
  }

  void setDateFilter(ResultDateFilter filter) {
    dateFilter = filter;
    visibleLimit = 50;
    notifyListeners();
  }

  void setSearchQuery(String? query) {
    searchQuery = query;
    visibleLimit = 50;
    notifyListeners();
  }

  Future<void> load() async {
    records = await _service.load();
    records.sort((a, b) => b.createdAt.compareTo(a.createdAt));
    visibleLimit = 50;
    notifyListeners();
  }

  Future<void> add(ResultHistoryRecord record) async {
    records = [record, ...records];
    await _service.saveAll(records);
    visibleLimit = 50;
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

  Future<void> clearFolderResults(String resultFolderPath, {required bool deleteFiles}) async {
    if (deleteFiles) {
      final folder = Directory(resultFolderPath);
      if (folder.existsSync()) {
        final recordsToClear = records
            .where((record) => record.resultFolderPath == resultFolderPath)
            .toList();

        for (final record in recordsToClear) {
          await _deleteResultFileIfSafe(record);
        }
      }
    }

    records = records
        .where((record) => record.resultFolderPath != resultFolderPath)
        .toList();
    await _service.saveAll(records);
    message = deleteFiles ? 'Result folder cleared (history and files deleted).' : 'Result folder history cleared.';
    notifyListeners();
  }

  Future<void> clearResultFolder(String resultFolderPath) async {
    await clearFolderResults(resultFolderPath, deleteFiles: true);
  }

  Future<void> removeHistoryByFilter(ResultProcessType? filter) async {
    final before = records.length;
    records = records.where((record) {
      if (filter == null) return false;
      return record.processType != filter;
    }).toList();
    await _service.saveAll(records);
    final removed = before - records.length;
    message = 'Removed $removed history records.';
    notifyListeners();
  }

  Future<void> removeHistoryForFolder(String resultFolderPath) async {
    final before = records.length;
    records = records
        .where(
          (record) => !p.equals(
            p.normalize(record.resultFolderPath),
            p.normalize(resultFolderPath),
          ),
        )
        .toList();
    if (resultFolderFilter != null &&
        p.equals(
          p.normalize(resultFolderFilter!),
          p.normalize(resultFolderPath),
        )) {
      resultFolderFilter = null;
    }
    await _service.saveAll(records);
    final removed = before - records.length;
    message = 'Removed $removed history records for the selected folder.';
    notifyListeners();
  }

  Future<void> removeFilesForFolder(String resultFolderPath) async {
    var deleted = 0;
    for (final record in records) {
      if (!p.equals(
        p.normalize(record.resultFolderPath),
        p.normalize(resultFolderPath),
      )) {
        continue;
      }
      final file = File(record.outputPath);
      if (_isRecordedOutputInsideResultFolder(record) && file.existsSync()) {
        await file.delete();
        deleted++;
      }
    }
    message = 'Deleted $deleted result files from the selected folder.';
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

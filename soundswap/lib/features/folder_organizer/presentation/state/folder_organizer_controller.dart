import 'dart:async';
import 'dart:developer' as dev;
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:path/path.dart' as p;
import 'package:soundswap/features/folder_organizer/data/models/organizer_options.dart';
import 'package:soundswap/features/folder_organizer/data/models/organizer_file_item.dart';
import 'package:soundswap/features/folder_organizer/data/models/organizer_history_record.dart';
import 'package:soundswap/features/folder_organizer/data/models/organizer_state_record.dart';
import 'package:soundswap/features/folder_organizer/data/models/organizer_scan_mode.dart';
import 'package:soundswap/features/folder_organizer/data/services/organizer_service.dart';
import 'package:soundswap/features/folder_organizer/data/services/organizer_state_service.dart';
import 'package:soundswap/shared/services/folder_picker_service.dart';

class FolderOrganizerController extends ChangeNotifier {
  FolderOrganizerController({
    OrganizerService? service,
    FolderPickerService? pickerService,
  })  : _service = service ?? OrganizerService(),
        _pickerService = pickerService ?? FolderPickerService();

  final OrganizerService _service;
  final FolderPickerService _pickerService;

  // Configuration settings
  OrganizerOptions options = const OrganizerOptions();

  // Root folder selected by the user
  String? rootFolderPath;

  final OrganizerStateService _stateService = OrganizerStateService();
  List<OrganizerStateRecord> processedState = [];

  // Watch states
  bool isWatching = false;
  StreamSubscription<FileSystemEvent>? _watchSubscription;
  final Set<String> _processingWatchFiles = {};

  // Watch metrics
  int newFilesDetected = 0;
  int organizedCount = 0;
  int watchFailedCount = 0;
  String? currentProcessingFile;

  // Scan states
  bool isScanning = false;
  bool isScanCancelled = false;
  String scanStatus = 'idle'; // 'idle', 'scanning', 'hashing', 'probing', 'completed', 'cancelled'
  List<OrganizerFileItem> scannedItems = [];
  
  // Scan statistics
  int foldersScanned = 0;
  int filesScanned = 0;
  int imagesCount = 0;
  int videosCount = 0;
  int hashedCount = 0;
  int totalToHash = 0;
  int probedCount = 0;
  int totalToProbe = 0;
  int alreadyProcessedSkippedCount = 0;

  // Apply states
  bool isApplying = false;
  String applyStatus = 'idle'; // 'idle', 'applying', 'completed'
  double applyProgress = 0.0;
  String? lastReportPath;

  // Apply statistics
  int imagesMoved = 0;
  int videosMoved = 0;
  int filesRenamed = 0;
  int duplicatesMoved = 0;
  int duplicatesDeleted = 0;
  int skippedCount = 0;
  int failedCount = 0;
  int emptyFoldersRemoved = 0;
  int emptyFoldersSkipped = 0;

  // HEIC statistics
  int heicFound = 0;
  int heicConverted = 0;
  int heicDeleted = 0;
  int heicFailed = 0;

  // Undo states
  bool isUndoing = false;

  // Message banners
  String? errorMessage;
  String? successMessage;
  String? infoMessage;

  // History list
  List<OrganizerHistoryRecord> historyRecords = [];

  // Duration of current scan
  DateTime? _scanStartTime;
  Duration? scanDuration;

  Future<void> _loadHistoryAndSort() async {
    historyRecords = await _service.loadHistory();
    historyRecords.sort((a, b) => b.timestamp.compareTo(a.timestamp));
  }

  /// Initializes the controller by loading settings and history
  Future<void> load() async {
    try {
      // Load history
      await _loadHistoryAndSort();
      
      // Load options
      options = await _service.loadOptions();
      errorMessage = null;
    } catch (e) {
      errorMessage = 'Failed to load settings: $e';
    }
    notifyListeners();
  }

  /// Updates and saves the options
  Future<void> updateOptions(OrganizerOptions value) async {
    options = value;
    notifyListeners();
    refreshPreview();
    await _service.saveOptions(options);
  }

  /// Selects the root folder
  Future<void> pickRootFolder() async {
    try {
      final selected = await _pickerService.pickFolder(
        dialogTitle: 'Select Root Folder to Organize',
      );
      if (selected != null) {
        if (isWatching) {
          await stopWatch();
        }

        rootFolderPath = selected;
        scannedItems.clear();
        scanStatus = 'idle';
        errorMessage = null;
        successMessage = null;
        infoMessage = null;

        foldersScanned = 0;
        filesScanned = 0;
        imagesCount = 0;
        videosCount = 0;
        hashedCount = 0;
        totalToHash = 0;
        probedCount = 0;
        totalToProbe = 0;
        alreadyProcessedSkippedCount = 0;

        newFilesDetected = 0;
        organizedCount = 0;
        watchFailedCount = 0;
        currentProcessingFile = null;
        _processingWatchFiles.clear();

        await _loadProcessedState();
        notifyListeners();
      }
    } catch (e) {
      errorMessage = 'Failed to pick folder: $e';
      notifyListeners();
    }
  }

  Future<void> _loadProcessedState() async {
    if (rootFolderPath != null) {
      processedState = await _stateService.getRecords(rootFolderPath!);
      dev.log('Loaded processed state count: ${processedState.length}', name: 'FolderOrganizer');
    }
  }

  Future<void> clearProcessedState() async {
    if (rootFolderPath != null) {
      await _stateService.clearRecords(rootFolderPath!);
      processedState.clear();
      successMessage = 'Processed state cleared. All files will be treated as new.';
      notifyListeners();
    }
  }

  /// Starts scanning the root folder
  Future<void> startScan({required OrganizerScanMode scanMode}) async {
    final path = rootFolderPath;
    if (path == null || path.isEmpty) {
      errorMessage = 'Please select a root folder first.';
      notifyListeners();
      return;
    }

    processedState.clear();

    isScanning = true;
    isScanCancelled = false;
    scanStatus = 'scanning';
    errorMessage = null;
    successMessage = null;
    infoMessage = null;
    scannedItems.clear();
    
    // Clear scan statistics
    foldersScanned = 0;
    filesScanned = 0;
    imagesCount = 0;
    videosCount = 0;
    hashedCount = 0;
    totalToHash = 0;
    probedCount = 0;
    totalToProbe = 0;
    heicFound = 0;
    alreadyProcessedSkippedCount = 0;
    
    // Clear cached apply statistics and status
    isApplying = false;
    applyStatus = 'idle';
    applyProgress = 0.0;
    lastReportPath = null;
    imagesMoved = 0;
    videosMoved = 0;
    filesRenamed = 0;
    duplicatesMoved = 0;
    duplicatesDeleted = 0;
    skippedCount = 0;
    failedCount = 0;
    emptyFoldersRemoved = 0;
    emptyFoldersSkipped = 0;
    heicConverted = 0;
    heicDeleted = 0;
    heicFailed = 0;
    
    _scanStartTime = DateTime.now();
    scanDuration = null;
    notifyListeners();

    try {
      final stream = _service.scanFolder(
        rootPath: path,
        options: options,
        scanMode: scanMode,
        isCancelled: () => isScanCancelled,
      );
      await for (final event in stream) {
        scanStatus = event['status'] as String;
        foldersScanned = event['foldersScanned'] as int;
        filesScanned = event['filesScanned'] as int;
        imagesCount = event['imagesCount'] as int;
        videosCount = event['videosCount'] as int;
        alreadyProcessedSkippedCount = event['alreadyProcessedSkipped'] as int? ?? 0;
        scannedItems = List<OrganizerFileItem>.from(event['items'] as List);
        
        // Count HEIC/HEIF files
        heicFound = scannedItems.where((item) {
          final ext = p.extension(item.originalPath).toLowerCase().replaceAll('.', '');
          return ext == 'heic' || ext == 'heif';
        }).length;
        
        if (event.containsKey('hashedCount')) {
          hashedCount = event['hashedCount'] as int;
          totalToHash = event['totalToHash'] as int;
        }

        if (event.containsKey('probedCount')) {
          probedCount = event['probedCount'] as int;
          totalToProbe = event['totalToProbe'] as int;
        }

        notifyListeners();
      }
      
      scanDuration = DateTime.now().difference(_scanStartTime!);
      errorMessage = null;

      dev.log('Already processed skipped: $alreadyProcessedSkippedCount', name: 'FolderOrganizer');

      // Determine the scan result message to display
      if (scanStatus == 'cancelled') {
        infoMessage = 'Scan cancelled by user\nFiles scanned: $filesScanned\nImages found: $imagesCount\nVideos found: $videosCount';
      } else if (scannedItems.isEmpty) {
        infoMessage = 'No supported media files found.';
      } else {
        final alreadyOrganizedCount = scannedItems.where((i) => i.action == FileItemAction.alreadyOrganized).length;
        if (alreadyOrganizedCount > 0 || alreadyProcessedSkippedCount > 0) {
          infoMessage = 'Scan completed\nFiles found: ${scannedItems.length}, already organized: $alreadyOrganizedCount, skipped processed: $alreadyProcessedSkippedCount';
        } else {
          infoMessage = 'Scan completed\nFiles scanned: $filesScanned\nImages found: $imagesCount\nVideos found: $videosCount';
        }
      }
    } catch (e) {
      errorMessage = 'Scan failed: $e';
      scanStatus = 'idle';
    } finally {
      isScanning = false;
      notifyListeners();
    }
  }

  /// Cancels an ongoing scan
  void cancelScan() {
    if (isScanning) {
      isScanCancelled = true;
      notifyListeners();
    }
  }

  /// Updates preview changes when options are changed after scanning
  void refreshPreview() {
    final path = rootFolderPath;
    if (path != null && scannedItems.isNotEmpty && !isScanning && !isApplying) {
      try {
        _service.calculateProposedChanges(scannedItems, path, options);
        notifyListeners();
      } catch (e) {
        errorMessage = 'Failed to refresh preview: $e';
        notifyListeners();
      }
    }
  }

  /// Applies the proposed changes to the folders/files
  Future<void> applyChanges() async {
    final path = rootFolderPath;
    if (path == null || scannedItems.isEmpty) {
      errorMessage = 'No scanned items to organize.';
      notifyListeners();
      return;
    }

    isApplying = true;
    applyStatus = 'applying';
    errorMessage = null;
    successMessage = null;
    infoMessage = null;
    applyProgress = 0.0;
    
    imagesMoved = 0;
    videosMoved = 0;
    filesRenamed = 0;
    duplicatesMoved = 0;
    duplicatesDeleted = 0;
    skippedCount = 0;
    failedCount = 0;
    emptyFoldersRemoved = 0;
    emptyFoldersSkipped = 0;
    heicConverted = 0;
    heicDeleted = 0;
    heicFailed = 0;
    lastReportPath = null;
    
    notifyListeners();

    try {
      final stream = _service.applyChanges(
        items: scannedItems,
        rootPath: path,
        options: options,
      );

      await for (final event in stream) {
        applyStatus = event['status'] as String;
        applyProgress = (event['progress'] as double?) ?? 0.0;
        imagesMoved = event['imagesMoved'] as int? ?? imagesMoved;
        videosMoved = event['videosMoved'] as int? ?? videosMoved;
        filesRenamed = event['filesRenamed'] as int? ?? filesRenamed;
        duplicatesMoved = event['duplicatesMoved'] as int? ?? duplicatesMoved;
        duplicatesDeleted = event['duplicatesDeleted'] as int? ?? duplicatesDeleted;
        skippedCount = event['skipped'] as int? ?? skippedCount;
        failedCount = event['failed'] as int? ?? failedCount;
        emptyFoldersRemoved = event['emptyFoldersRemoved'] as int? ?? emptyFoldersRemoved;
        emptyFoldersSkipped = event['emptyFoldersSkipped'] as int? ?? emptyFoldersSkipped;
        heicConverted = event['heicConverted'] as int? ?? heicConverted;
        heicDeleted = event['heicDeleted'] as int? ?? heicDeleted;
        heicFailed = event['heicFailed'] as int? ?? heicFailed;
 
        if (applyStatus == 'completed') {
          lastReportPath = event['reportPath'] as String?;
          final buffer = StringBuffer();
          buffer.write('Organization complete!\nMoved ${imagesMoved + videosMoved} media files. ');
          buffer.write('Renamed $filesRenamed files. ');
          buffer.write('Duplicates: ${duplicatesMoved + duplicatesDeleted} processed. ');
          if (heicFound > 0) {
            buffer.write('\n\nSummary:\n');
            buffer.write('HEIC found: $heicFound\n');
            buffer.write('Converted: $heicConverted\n');
            buffer.write('Deleted originals: $heicDeleted\n');
            buffer.write('Failed: $heicFailed\n');
          }
          buffer.write('Failed: $failedCount. ');
          buffer.write('Empty folders removed: $emptyFoldersRemoved.');
          successMessage = buffer.toString();
          
          // Save success records to state
          final recordsToSave = <OrganizerStateRecord>[];
          final timestamp = DateTime.now();
          for (final item in scannedItems) {
            if (item.action != FileItemAction.error) {
              final record = OrganizerStateRecord(
                originalPath: item.originalPath,
                fileName: item.fileName,
                fileSize: item.sizeBytes,
                lastModified: item.lastModified,
                processedAt: timestamp,
                destinationPath: item.newPath ?? item.originalPath,
                mediaType: item.fileType.name,
                status: 'success',
              );
              recordsToSave.add(record);
              processedState.add(record);
            }
          }

          if (recordsToSave.isNotEmpty) {
            await _stateService.addRecords(path, recordsToSave);
            dev.log('Saved processed state count: ${recordsToSave.length}', name: 'FolderOrganizer');
          }

          // Clear current preview after successful apply
          scannedItems.clear();
          scanStatus = 'idle';
        }
        notifyListeners();
      }

      // Reload history list
      await _loadHistoryAndSort();
      notifyListeners();
    } catch (e) {
      errorMessage = 'Failed to apply changes: $e';
      applyStatus = 'idle';
      notifyListeners();
    } finally {
      isApplying = false;
      notifyListeners();
    }
  }

  /// Undoes a past operation
  Future<void> undoOperation(OrganizerHistoryRecord record) async {
    isUndoing = true;
    errorMessage = null;
    successMessage = null;
    infoMessage = null;
    notifyListeners();

    try {
      final result = await _service.undoOperation(record);
      final undone = result['undoneCount'] as int;
      final failed = result['failedCount'] as int;
      final errors = result['errors'] as List<String>;

      if (failed > 0) {
        errorMessage = 'Undo partially completed.\n'
            'Restored $undone files. Failed to restore $failed files.\n'
            'Errors: ${errors.join(", ")}';
      } else {
        successMessage = 'Successfully reverted operation: restored $undone files.';
      }

      // Reload history
      await _loadHistoryAndSort();
    } catch (e) {
      errorMessage = 'Failed to undo: $e';
    } finally {
      isUndoing = false;
      notifyListeners();
    }
  }

  Future<void> clearOrganizerHistory() async {
    try {
      historyRecords.clear();
      await _service.saveHistory(historyRecords);
      successMessage = 'All organizer history records cleared successfully.';
      errorMessage = null;
      infoMessage = null;
    } catch (e) {
      errorMessage = 'Failed to clear organizer history: $e';
      successMessage = null;
    }
    notifyListeners();
  }

  Future<void> clearAppliedSessions() async {
    try {
      historyRecords = historyRecords.where((r) => r.undoApplied).toList();
      await _service.saveHistory(historyRecords);
      successMessage = 'All applied sessions cleared successfully.';
      errorMessage = null;
      infoMessage = null;
    } catch (e) {
      errorMessage = 'Failed to clear applied sessions: $e';
      successMessage = null;
    }
    notifyListeners();
  }

  Future<void> clearRevertedSessions() async {
    try {
      historyRecords = historyRecords.where((r) => !r.undoApplied).toList();
      await _service.saveHistory(historyRecords);
      successMessage = 'All reverted sessions cleared successfully.';
      errorMessage = null;
      infoMessage = null;
    } catch (e) {
      errorMessage = 'Failed to clear reverted sessions: $e';
      successMessage = null;
    }
    notifyListeners();
  }

  Future<void> deleteHistoryRecord(OrganizerHistoryRecord record) async {
    try {
      historyRecords = historyRecords.where((r) => r.id != record.id).toList();
      await _service.saveHistory(historyRecords);
      successMessage = 'History record deleted successfully.';
      errorMessage = null;
      infoMessage = null;
    } catch (e) {
      errorMessage = 'Failed to delete history record: $e';
      successMessage = null;
    }
    notifyListeners();
  }

  /// Export duplicate report manually
  String getReportContent(OrganizerHistoryRecord record, String format) {
    return _service.generateReportContent(record, format);
  }

  // ─── Watch Mode ─────────────────────────────────────────────────────────────

  Future<void> startWatch() async {
    if (rootFolderPath == null || isWatching) return;
    
    await _loadProcessedState();

    isWatching = true;
    newFilesDetected = 0;
    organizedCount = 0;
    watchFailedCount = 0;
    alreadyProcessedSkippedCount = 0;
    currentProcessingFile = null;
    errorMessage = null;
    infoMessage = 'Auto Watch Mode started on $rootFolderPath';
    notifyListeners();

    try {
      _watchSubscription = Directory(rootFolderPath!).watch().listen((event) {
        if (event is FileSystemDeleteEvent) return;

        final ext = p.extension(event.path).toLowerCase().replaceAll('.', '');
        if (!OrganizerService.imageExtensions.contains(ext) &&
            !OrganizerService.videoExtensions.contains(ext)) {
          return;
        }

        // Avoid infinite loop if destination is inside source folder
        if (options.keepFolderStructure == false && p.isWithin(rootFolderPath!, event.path)) {
          final parent = p.basename(p.dirname(event.path));
          if (parent == 'images' || parent == 'videos') return;
        }

        if (OrganizerService.isExcludedResultFolder(event.path)) {
          return;
        }

        _handleWatchEvent(event.path);
      }, onError: (e) {
        errorMessage = 'Watch error: $e';
        stopWatch();
      });
    } catch (e) {
      errorMessage = 'Failed to start watch: $e';
      isWatching = false;
      notifyListeners();
    }
  }

  Future<void> stopWatch() async {
    await _watchSubscription?.cancel();
    _watchSubscription = null;
    isWatching = false;
    currentProcessingFile = null;
    infoMessage = 'Auto Watch Mode stopped.';
    notifyListeners();
  }

  Future<void> _handleWatchEvent(String filePath) async {
    if (_processingWatchFiles.contains(filePath)) return;
    _processingWatchFiles.add(filePath);

    try {
      newFilesDetected++;
      notifyListeners();

      await _waitUntilFileReady(filePath);

      final file = File(filePath);
      if (!file.existsSync()) return;

      final fileStat = file.statSync();
      final fileSize = fileStat.size;
      final lastModified = fileStat.modified.millisecondsSinceEpoch;

      final isProcessed = processedState.any((r) =>
          r.originalPath == filePath &&
          r.fileSize == fileSize &&
          r.lastModified == lastModified &&
          r.status == 'success');

      if (isProcessed) {
        alreadyProcessedSkippedCount++;
        notifyListeners();
        return;
      }

      currentProcessingFile = p.basename(filePath);
      notifyListeners();

      final record = await _service.applySingleFile(
        filePath: filePath,
        rootPath: rootFolderPath!,
        options: options,
      );

      if (record != null) {
        if (record.status == 'success') {
          organizedCount++;
        } else if (record.status == 'failed') {
          watchFailedCount++;
        }
        await _stateService.addRecords(rootFolderPath!, [record]);
        processedState.add(record);
      }
    } catch (e) {
      watchFailedCount++;
    } finally {
      _processingWatchFiles.remove(filePath);
      currentProcessingFile = null;
      notifyListeners();
    }
  }

  Future<void> _waitUntilFileReady(String path) async {
    int lastSize = -1;
    int stableChecks = 0;

    for (int i = 0; i < 60; i++) {
      final file = File(path);
      if (!file.existsSync()) {
        await Future.delayed(const Duration(seconds: 1));
        continue;
      }
      try {
        final size = await file.length();
        if (size == lastSize) {
          stableChecks++;
        } else {
          stableChecks = 0;
          lastSize = size;
        }
        if (stableChecks >= 2) return;
      } catch (_) {
        stableChecks = 0;
      }
      await Future.delayed(const Duration(seconds: 1));
    }
  }

  @override
  void dispose() {
    _watchSubscription?.cancel();
    super.dispose();
  }
}

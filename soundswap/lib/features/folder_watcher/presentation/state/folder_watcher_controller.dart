import 'dart:async';
import 'dart:io';
import 'dart:math';

import 'package:flutter/foundation.dart';
import 'package:path/path.dart' as p;
import 'package:soundswap/core/constants/app_constants.dart';
import 'package:soundswap/features/folder_watcher/data/models/folder_watcher_settings.dart';
import 'package:soundswap/features/folder_watcher/data/models/watch_processing_item.dart';
import 'package:soundswap/features/folder_watcher/data/services/folder_watcher_settings_service.dart';
import 'package:soundswap/features/home/data/models/media_file.dart';
import 'package:soundswap/features/home/data/models/soundswap_job.dart';
import 'package:soundswap/features/home/data/services/ffmpeg_service.dart';
import 'package:soundswap/features/home/data/services/media_scanner_service.dart';
import 'package:soundswap/features/result_history/data/models/result_history_record.dart';
import 'package:soundswap/features/result_history/presentation/state/result_history_controller.dart';
import 'package:soundswap/shared/services/debug_log_service.dart';
import 'package:soundswap/shared/services/folder_picker_service.dart';

typedef DuplicateConfirmCallback =
    Future<bool> Function(String sourceVideoPath);
typedef PermissionErrorCallback = Future<void> Function(String folderPath);

class FolderWatcherController extends ChangeNotifier {
  FolderWatcherController({
    FolderPickerService? folderPickerService,
    FolderWatcherSettingsService? settingsService,
    FfmpegService? ffmpegService,
    MediaScannerService? mediaScannerService,
    DebugLogService? debugLogService,
  }) : _folderPickerService = folderPickerService ?? FolderPickerService(),
       _settingsService = settingsService ?? FolderWatcherSettingsService(),
       _ffmpegService = ffmpegService ?? FfmpegService(),
       _mediaScannerService = mediaScannerService ?? MediaScannerService(),
       _debugLogService = debugLogService ?? DebugLogService();

  final FolderPickerService _folderPickerService;
  final FolderWatcherSettingsService _settingsService;
  final FfmpegService _ffmpegService;
  final MediaScannerService _mediaScannerService;
  final DebugLogService _debugLogService;
  final Random _random = Random();
  StreamSubscription<FileSystemEvent>? _subscription;
  final _processing = <String>{};

  String? videoFolderPath;
  String? audioFolderPath;
  String? resultFolderPath;
  bool isWatching = false;
  List<String> detectedVideos = [];
  List<WatchProcessingItem> processingQueue = [];
  ResultHistoryRecord? latestCompletedResult;
  String? errorMessage;

  Future<void> load() async {
    final settings = await _settingsService.load();
    videoFolderPath = settings.videoFolderPath;
    audioFolderPath = settings.audioFolderPath;
    resultFolderPath = settings.resultFolderPath;
    notifyListeners();
  }

  Future<void> pickVideoFolder() async {
    await _pickAndSave(
      dialogTitle: 'Select source video folder',
      assign: (path) => videoFolderPath = path,
    );
  }

  Future<void> pickAudioFolder() async {
    await _pickAndSave(
      dialogTitle: 'Select source audio folder',
      assign: (path) => audioFolderPath = path,
    );
  }

  Future<void> pickResultFolder() async {
    await _pickAndSave(
      dialogTitle: 'Select result folder',
      assign: (path) => resultFolderPath = path,
    );
  }

  Future<void> startWatching({
    required ResultHistoryController historyController,
    DuplicateConfirmCallback? onDuplicate,
    PermissionErrorCallback? onPermissionError,
  }) async {
    if (!_hasRequiredFolders) {
      errorMessage = 'Select source video, source audio, and result folders.';
      notifyListeners();
      return;
    }

    await stopWatching();
    try {
      await _validateRequiredFolder(videoFolderPath!, onPermissionError);
      await _validateRequiredFolder(audioFolderPath!, onPermissionError);
      await _validateRequiredFolder(resultFolderPath!, onPermissionError);

      isWatching = true;
      errorMessage = null;
      _subscription = Directory(videoFolderPath!).watch().listen(
        (event) => _handleEvent(
          event,
          historyController: historyController,
          onDuplicate: onDuplicate,
        ),
        onError: (Object error) async {
          errorMessage = error.toString();
          isWatching = false;
          await onPermissionError?.call(videoFolderPath!);
          notifyListeners();
        },
      );
    } catch (error) {
      errorMessage = error.toString();
      isWatching = false;
    }
    notifyListeners();
  }

  Future<void> stopWatching() async {
    await _subscription?.cancel();
    _subscription = null;
    isWatching = false;
    notifyListeners();
  }

  Future<void> _pickAndSave({
    required String dialogTitle,
    required ValueChanged<String> assign,
  }) async {
    final path = await _folderPickerService.pickFolder(
      dialogTitle: dialogTitle,
    );
    if (path != null) {
      assign(path);
      await _saveSettings();
      notifyListeners();
    }
  }

  Future<void> _saveSettings() {
    return _settingsService.save(
      FolderWatcherSettings(
        videoFolderPath: videoFolderPath,
        audioFolderPath: audioFolderPath,
        resultFolderPath: resultFolderPath,
      ),
    );
  }

  void _validateFolderAccess(String folderPath) {
    final directory = Directory(folderPath);
    if (!directory.existsSync()) {
      throw FileSystemException('Folder cannot be accessed', folderPath);
    }
    directory.listSync(followLinks: false);
  }

  Future<void> _validateRequiredFolder(
    String folderPath,
    PermissionErrorCallback? onPermissionError,
  ) async {
    try {
      _validateFolderAccess(folderPath);
    } catch (_) {
      await onPermissionError?.call(folderPath);
      rethrow;
    }
  }

  void _handleEvent(
    FileSystemEvent event, {
    required ResultHistoryController historyController,
    DuplicateConfirmCallback? onDuplicate,
  }) {
    if (event is FileSystemDeleteEvent) return;
    final extension = p.extension(event.path).toLowerCase();
    if (!AppConstants.supportedVideoExtensions.contains(extension)) return;
    if (_processing.contains(event.path)) return;

    detectedVideos = [
      event.path,
      ...detectedVideos.where((p) => p != event.path),
    ].take(20).toList();
    notifyListeners();

    unawaited(
      _processDetectedVideo(
        event.path,
        historyController: historyController,
        onDuplicate: onDuplicate,
      ),
    );
  }

  Future<void> _processDetectedVideo(
    String videoPath, {
    required ResultHistoryController historyController,
    DuplicateConfirmCallback? onDuplicate,
  }) async {
    _processing.add(videoPath);
    MediaFile? selectedAudio;
    String? plannedOutputPath;
    _upsertQueue(
      WatchProcessingItem(
        videoPath: videoPath,
        status: WatchProcessingStatus.waiting,
      ),
    );

    try {
      if (historyController.hasProcessed(videoPath)) {
        final processAgain = await onDuplicate?.call(videoPath) ?? false;
        if (!processAgain) {
          _removeProcessing(videoPath);
          return;
        }
      }

      await _waitUntilFileReady(videoPath);
      selectedAudio = await _pickRandomAudio();
      plannedOutputPath = _nextOutputPath(videoPath);
      final item = WatchProcessingItem(
        videoPath: videoPath,
        audioPath: selectedAudio.path,
        outputPath: plannedOutputPath,
        status: WatchProcessingStatus.processing,
      );
      _upsertQueue(item);

      final job = SoundSwapJob(
        video: MediaFile(path: videoPath),
        audio: selectedAudio,
        outputPath: plannedOutputPath,
      );
      final plan = await _ffmpegService.prepareReplacement(job);
      await _debugLogService.append(
        '[INFO] Auto watcher FFmpeg command:\n${plan.command}',
      );
      await _ffmpegService.runReplacement(plan);

      final record = ResultHistoryRecord(
        id: DateTime.now().microsecondsSinceEpoch.toString(),
        originalVideoPath: videoPath,
        audioPath: selectedAudio.path,
        outputPath: plannedOutputPath,
        resultFolderPath: resultFolderPath!,
        status: ResultHistoryStatus.success,
        createdAt: DateTime.now(),
      );
      await historyController.add(record);
      latestCompletedResult = record;
      _upsertQueue(item.copyWith(status: WatchProcessingStatus.success));
    } catch (error, stackTrace) {
      await _debugLogService.append('[ERROR] Auto watcher failed: $error');
      await _debugLogService.append('[ERROR] StackTrace:\n$stackTrace');
      final failedRecord = ResultHistoryRecord(
        id: DateTime.now().microsecondsSinceEpoch.toString(),
        originalVideoPath: videoPath,
        audioPath: selectedAudio?.path ?? '',
        outputPath: plannedOutputPath ?? '',
        resultFolderPath: resultFolderPath ?? '',
        status: ResultHistoryStatus.failed,
        createdAt: DateTime.now(),
        errorMessage: error.toString(),
      );
      await historyController.add(failedRecord);
      latestCompletedResult = failedRecord;
      _upsertQueue(
        WatchProcessingItem(
          videoPath: videoPath,
          audioPath: selectedAudio?.path,
          outputPath: plannedOutputPath,
          status: WatchProcessingStatus.failed,
          errorMessage: error.toString(),
        ),
      );
    } finally {
      _removeProcessing(videoPath, keepQueueItem: true);
    }
  }

  Future<void> _waitUntilFileReady(String path) async {
    var lastSize = -1;
    var stableChecks = 0;

    for (var i = 0; i < 90; i++) {
      final file = File(path);
      if (!file.existsSync()) {
        await Future<void>.delayed(const Duration(seconds: 1));
        continue;
      }

      try {
        final size = await file.length();
        final handle = await file.open(mode: FileMode.append);
        await handle.close();
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
      await Future<void>.delayed(const Duration(seconds: 1));
    }
    throw FileSystemException('Video file is still locked or copying', path);
  }

  Future<MediaFile> _pickRandomAudio() async {
    final audios = await _mediaScannerService.scanFolder(
      folderPath: audioFolderPath!,
      extensions: AppConstants.supportedAudioExtensions,
    );
    if (audios.isEmpty) {
      throw FileSystemException(
        'No supported audio files found',
        audioFolderPath,
      );
    }
    return audios[_random.nextInt(audios.length)];
  }

  String _nextOutputPath(String videoPath) {
    final baseName = p.basenameWithoutExtension(videoPath);
    var candidate = p.join(resultFolderPath!, '${baseName}_soundswap.mp4');
    var index = 2;
    while (File(candidate).existsSync()) {
      candidate = p.join(resultFolderPath!, '${baseName}_soundswap_$index.mp4');
      index++;
    }
    return candidate;
  }

  void _upsertQueue(WatchProcessingItem item) {
    processingQueue = [
      item,
      ...processingQueue.where(
        (existing) => existing.videoPath != item.videoPath,
      ),
    ].take(30).toList();
    notifyListeners();
  }

  void _removeProcessing(String videoPath, {bool keepQueueItem = false}) {
    _processing.remove(videoPath);
    if (!keepQueueItem) {
      processingQueue = processingQueue
          .where((item) => item.videoPath != videoPath)
          .toList();
    }
    notifyListeners();
  }

  bool get _hasRequiredFolders =>
      videoFolderPath != null &&
      audioFolderPath != null &&
      resultFolderPath != null;

  @override
  void dispose() {
    _subscription?.cancel();
    super.dispose();
  }
}

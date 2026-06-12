import 'dart:async';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:path/path.dart' as p;

import 'package:soundswap/features/folder_organizer/data/models/organizer_file_item.dart';
import 'package:soundswap/features/folder_organizer/data/services/organizer_service.dart';
import 'package:soundswap/features/folder_watcher/data/models/watch_processing_item.dart';
import 'package:soundswap/features/organizer_watch/data/models/organizer_watch_profile.dart';
import 'package:soundswap/features/organizer_watch/data/services/organizer_watch_profiles_service.dart';
import 'package:soundswap/features/result_history/data/models/result_history_record.dart';
import 'package:soundswap/features/result_history/presentation/state/result_history_controller.dart';
import 'package:soundswap/shared/services/debug_log_service.dart';
import 'package:soundswap/shared/services/folder_picker_service.dart';

typedef PermissionErrorCallback = Future<void> Function(String path);

class OrganizerWatchController extends ChangeNotifier {
  OrganizerWatchController({
    OrganizerWatchProfilesService? profilesService,
    OrganizerService? organizerService,
    FolderPickerService? folderPickerService,
    DebugLogService? debugLogService,
  })  : _profilesService = profilesService ?? OrganizerWatchProfilesService(),
        _organizerService = organizerService ?? OrganizerService(),
        _debugLogService = debugLogService ?? DebugLogService();

  final OrganizerWatchProfilesService _profilesService;
  final OrganizerService _organizerService;
  final DebugLogService _debugLogService;

  final _subscriptions = <String, StreamSubscription<FileSystemEvent>>{};
  final _processing = <String>{};

  List<OrganizerWatchProfile> profiles = [];
  List<WatchProcessingItem> queue = [];
  List<String> detectedMedia = [];
  ResultHistoryRecord? latestCompletedResult;
  String? errorMessage;

  bool get isWatching => _subscriptions.isNotEmpty;

  Future<void> load() async {
    profiles = await _profilesService.loadAll();
    notifyListeners();
  }

  void clearError() {
    errorMessage = null;
    notifyListeners();
  }

  Future<void> createProfile(String name) async {
    final profile = OrganizerWatchProfile(
      id: DateTime.now().microsecondsSinceEpoch.toString(),
      name: name.trim().isEmpty ? 'Organizer Watcher' : name.trim(),
    );
    profiles = [profile, ...profiles];
    await _saveProfiles();
    notifyListeners();
  }

  Future<void> deleteProfile(String profileId) async {
    await stopWatching(profileId);
    profiles = profiles.where((p) => p.id != profileId).toList();
    await _saveProfiles();
    notifyListeners();
  }

  Future<void> duplicateProfile(String profileId) async {
    final profile = _profileById(profileId);
    if (profile == null) return;
    final duplicate = profile.copyWith(
      id: DateTime.now().microsecondsSinceEpoch.toString(),
      name: '${profile.name} Copy',
      isActive: false,
    );
    profiles = [duplicate, ...profiles];
    await _saveProfiles();
    notifyListeners();
  }

  Future<void> saveProfile(OrganizerWatchProfile updatedProfile) async {
    await _updateProfile(updatedProfile.id, (_) => updatedProfile);
  }

  Future<void> startWatching({
    required String profileId,
    required ResultHistoryController historyController,
    PermissionErrorCallback? onPermissionError,
  }) async {
    final profile = _profileById(profileId);
    if (profile == null) return;
    if (!profile.hasRequiredFolders) {
      errorMessage = 'Select source and destination folders.';
      notifyListeners();
      return;
    }

    await stopWatching(profileId);
    try {
      _validateFolderAccess(profile.sourceFolderPath!);
      _validateFolderAccess(profile.destinationFolderPath!);

      errorMessage = null;
      if (!profile.isActive) {
        await _updateProfile(profileId, (p) => p.copyWith(isActive: true));
      }

      _subscriptions[profileId] = Directory(profile.sourceFolderPath!)
          .watch()
          .listen(
            (event) => _handleEvent(
              event,
              profileId: profileId,
              historyController: historyController,
            ),
            onError: (Object error) async {
              errorMessage = error.toString();
              await onPermissionError?.call(profile.sourceFolderPath!);
              await stopWatching(profileId);
              notifyListeners();
            },
          );
    } catch (error) {
      errorMessage = error.toString();
      await onPermissionError?.call(profile.sourceFolderPath!);
    }
    notifyListeners();
  }

  Future<void> stopWatching(String profileId) async {
    await _subscriptions.remove(profileId)?.cancel();
    final profile = _profileById(profileId);
    if (profile != null && profile.isActive) {
      await _updateProfile(profileId, (p) => p.copyWith(isActive: false));
    }
    notifyListeners();
  }

  bool isProfileWatching(String profileId) {
    return _subscriptions.containsKey(profileId);
  }

  void _validateFolderAccess(String folderPath) {
    final directory = Directory(folderPath);
    if (!directory.existsSync()) {
      throw FileSystemException('Folder cannot be accessed', folderPath);
    }
    directory.listSync(followLinks: false);
  }

  void _handleEvent(
    FileSystemEvent event, {
    required String profileId,
    required ResultHistoryController historyController,
  }) {
    if (event is FileSystemDeleteEvent) return;
    final extension = p.extension(event.path).toLowerCase().replaceAll('.', '');
    if (!OrganizerService.imageExtensions.contains(extension) &&
        !OrganizerService.videoExtensions.contains(extension)) {
      return;
    }
    
    final processingKey = '$profileId|${event.path}';
    if (_processing.contains(processingKey)) return;

    detectedMedia = [
      event.path,
      ...detectedMedia.where((path) => path != event.path),
    ].take(30).toList();
    notifyListeners();

    _processDetectedMedia(
      profileId: profileId,
      mediaPath: event.path,
      historyController: historyController,
    );
  }

  Future<void> _processDetectedMedia({
    required String profileId,
    required String mediaPath,
    required ResultHistoryController historyController,
  }) async {
    final processingKey = '$profileId|$mediaPath';
    _processing.add(processingKey);

    _upsertQueue(WatchProcessingItem(
      videoPath: mediaPath,
      status: WatchProcessingStatus.waiting,
    ));

    try {
      final profile = _profileById(profileId);
      if (profile == null) return;

      // Ignore if source == destination loop
      if (_isInsideDestination(mediaPath, profile.destinationFolderPath!)) {
        _removeProcessing(processingKey, mediaPath);
        return;
      }

      await _waitUntilFileReady(mediaPath);

      final item = await _organizerService.probeSingleFile(mediaPath, profile.options);
      if (item == null) {
        _removeProcessing(processingKey, mediaPath);
        return;
      }

      _upsertQueue(WatchProcessingItem(
        videoPath: mediaPath,
        status: WatchProcessingStatus.processing,
      ));

      final baseTypeFolder = item.fileType == FileItemType.image ? 'images' : 'videos';
      final destDir = p.join(
        profile.destinationFolderPath!,
        baseTypeFolder,
        item.qualityGroup,
      );
      
      final plannedOutputPath = p.join(destDir, p.basename(mediaPath));
      
      if (historyController.hasProcessed(mediaPath) || File(plannedOutputPath).existsSync()) {
         _removeProcessing(processingKey, mediaPath);
         return;
      }

      await Directory(destDir).create(recursive: true);
      
      // We will move the file
      final file = File(mediaPath);
      await file.rename(plannedOutputPath);

      final record = ResultHistoryRecord(
        id: DateTime.now().microsecondsSinceEpoch.toString(),
        originalVideoPath: mediaPath,
        audioPath: '',
        outputPath: plannedOutputPath,
        resultFolderPath: profile.destinationFolderPath!,
        status: ResultHistoryStatus.success,
        createdAt: DateTime.now(),
        processType: ResultProcessType.organizerWatch,
        outputPrefix: '',
        totalVideos: 1,
      );
      
      await historyController.add(record);
      latestCompletedResult = record;
      
      _upsertQueue(WatchProcessingItem(
        videoPath: mediaPath,
        outputPath: plannedOutputPath,
        status: WatchProcessingStatus.success,
      ));

    } catch (error, stackTrace) {
      await _debugLogService.append('[ERROR] Organizer Watch failed: $error\n$stackTrace');
      
      final profile = _profileById(profileId);
      final failedRecord = ResultHistoryRecord(
        id: DateTime.now().microsecondsSinceEpoch.toString(),
        originalVideoPath: mediaPath,
        audioPath: '',
        outputPath: '',
        resultFolderPath: profile?.destinationFolderPath ?? p.dirname(mediaPath),
        status: ResultHistoryStatus.failed,
        createdAt: DateTime.now(),
        processType: ResultProcessType.organizerWatch,
        outputPrefix: '',
        totalVideos: 1,
        errorMessage: error.toString(),
      );
      
      await historyController.add(failedRecord);
      latestCompletedResult = failedRecord;
      
      _upsertQueue(WatchProcessingItem(
        videoPath: mediaPath,
        status: WatchProcessingStatus.failed,
        errorMessage: error.toString(),
      ));
    } finally {
      _removeProcessing(processingKey, mediaPath, keepQueueItem: true);
    }
  }

  bool _isInsideDestination(String path, String rootPath) {
    return p.isWithin(rootPath, path);
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
    throw FileSystemException('Media file is still locked or copying', path);
  }

  OrganizerWatchProfile? _profileById(String profileId) {
    for (final profile in profiles) {
      if (profile.id == profileId) return profile as dynamic;
    }
    return null;
  }

  Future<void> _updateProfile(
    String profileId,
    OrganizerWatchProfile Function(OrganizerWatchProfile) update,
  ) async {
    profiles = [
      for (final profile in profiles)
        if (profile.id == profileId) update(profile) else profile,
    ];
    await _saveProfiles();
    notifyListeners();
  }

  Future<void> _saveProfiles() => _profilesService.saveAll(profiles);

  void _upsertQueue(WatchProcessingItem item) {
    final index = queue.indexWhere((q) => q.videoPath == item.videoPath);
    if (index >= 0) {
      queue[index] = item;
    } else {
      queue.insert(0, item);
      if (queue.length > 50) queue.removeLast();
    }
    notifyListeners();
  }

  void _removeProcessing(
    String processingKey,
    String videoPath, {
    bool keepQueueItem = false,
  }) {
    _processing.remove(processingKey);
    if (!keepQueueItem) {
      queue.removeWhere((item) => item.videoPath == videoPath);
    }
    notifyListeners();
  }

  void clearQueue() {
    queue.clear();
    detectedMedia.clear();
    notifyListeners();
  }

  @override
  void dispose() {
    for (final subscription in _subscriptions.values) {
      subscription.cancel();
    }
    super.dispose();
  }
}

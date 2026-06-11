import 'dart:async';
import 'dart:io';
import 'dart:math';

import 'package:flutter/foundation.dart';
import 'package:path/path.dart' as p;
import 'package:soundswap/core/constants/app_constants.dart';
import 'package:soundswap/core/video/video_output_settings.dart';
import 'package:soundswap/features/folder_watcher/data/models/folder_watcher_profile.dart';
import 'package:soundswap/features/folder_watcher/data/models/watch_processing_item.dart';
import 'package:soundswap/features/folder_watcher/data/services/folder_watcher_profiles_service.dart';
import 'package:soundswap/features/folder_watcher/data/services/folder_watcher_settings_service.dart';
import 'package:soundswap/features/generator/data/services/ffmpeg_overlay_service.dart';
import 'package:soundswap/features/home/data/models/batch_profile.dart';
import 'package:soundswap/features/home/data/models/media_file.dart';
import 'package:soundswap/features/home/data/models/soundswap_job.dart';
import 'package:soundswap/features/home/data/services/ffmpeg_service.dart';
import 'package:soundswap/features/home/data/services/media_scanner_service.dart';
import 'package:soundswap/features/overlay_tools/data/models/overlay_settings.dart';
import 'package:soundswap/features/result_history/data/models/result_history_record.dart';
import 'package:soundswap/features/result_history/presentation/state/result_history_controller.dart';
import 'package:soundswap/features/templates/data/models/project_template.dart';
import 'package:soundswap/shared/services/debug_log_service.dart';
import 'package:soundswap/shared/services/folder_picker_service.dart';
import 'package:soundswap/shared/services/output_naming_service.dart';

typedef DuplicateConfirmCallback =
    Future<bool> Function(String sourceVideoPath);
typedef PermissionErrorCallback = Future<void> Function(String folderPath);

class FolderWatcherController extends ChangeNotifier {
  FolderWatcherController({
    FolderPickerService? folderPickerService,
    FolderWatcherSettingsService? legacySettingsService,
    FolderWatcherProfilesService? profilesService,
    FfmpegService? ffmpegService,
    FfmpegOverlayService? overlayService,
    MediaScannerService? mediaScannerService,
    DebugLogService? debugLogService,
    OutputNamingService? outputNamingService,
  }) : _folderPickerService = folderPickerService ?? FolderPickerService(),
       _legacySettingsService =
           legacySettingsService ?? FolderWatcherSettingsService(),
       _profilesService = profilesService ?? FolderWatcherProfilesService(),
       _ffmpegService = ffmpegService ?? FfmpegService(),
       _mediaScannerService = mediaScannerService ?? MediaScannerService(),
       _debugLogService = debugLogService ?? DebugLogService(),
       _outputNamingService =
           outputNamingService ?? const OutputNamingService() {
    _overlayService =
        overlayService ?? FfmpegOverlayService(ffmpegService: _ffmpegService);
  }

  final FolderPickerService _folderPickerService;
  final FolderWatcherSettingsService _legacySettingsService;
  final FolderWatcherProfilesService _profilesService;
  final FfmpegService _ffmpegService;
  late final FfmpegOverlayService _overlayService;
  final MediaScannerService _mediaScannerService;
  final DebugLogService _debugLogService;
  final OutputNamingService _outputNamingService;

  final Random _random = Random();
  final _subscriptions = <String, StreamSubscription<FileSystemEvent>>{};
  final _processing = <String>{};

  List<FolderWatcherProfile> profiles = [];
  List<String> detectedVideos = [];
  List<WatchProcessingItem> processingQueue = [];
  ResultHistoryRecord? latestCompletedResult;
  String? errorMessage;
  String? selectedBatchProfileId;

  String? get videoFolderPath =>
      profiles.isEmpty ? null : profiles.first.videoFolderPath;
  String? get audioFolderPath =>
      profiles.isEmpty ? null : profiles.first.audioFolderPath;
  String? get resultFolderPath =>
      profiles.isEmpty ? null : profiles.first.resultFolderPath;
  bool get isWatching => _subscriptions.isNotEmpty;

  Future<void> load() async {
    profiles = await _profilesService.load();
    if (profiles.isEmpty) {
      profiles = await _migrateLegacySettings();
      if (profiles.isNotEmpty) await _saveProfiles();
    }
    notifyListeners();
  }

  Future<void> createProfile(String name, {BatchProfile? importBatchProfile}) async {
    final profile = FolderWatcherProfile(
      id: _newId(),
      name: name.trim().isEmpty ? 'Watcher profile' : name.trim(),
      videoFolderPath: importBatchProfile?.videoFolderPath,
      audioFolderPath: importBatchProfile?.audioFolderPath,
      resultFolderPath: importBatchProfile?.outputFolderPath,
      outputPrefix: importBatchProfile?.outputPrefix ?? '',
      templateId: importBatchProfile?.selectedTemplateId,
      useOverlay: importBatchProfile?.useOverlay ?? false,
      overlaySettings: importBatchProfile?.overlaySettings ?? const OverlaySettings(),
      outputSize: importBatchProfile?.outputSize ?? VideoOutputSize.original,
      fitMode: importBatchProfile?.fitMode ?? VideoFitMode.keepOriginal,
    );
    profiles = [profile, ...profiles];
    await _saveProfiles();
    notifyListeners();
  }

  Future<void> renameProfile(String profileId, String name) async {
    final trimmed = name.trim();
    if (trimmed.isEmpty) return;
    await _updateProfile(
      profileId,
      (profile) => profile.copyWith(name: trimmed),
    );
  }

  Future<void> updateProfileDetails({
    required String profileId,
    required String name,
    required String outputPrefix,
  }) async {
    final trimmed = name.trim();
    await _updateProfile(
      profileId,
      (profile) => profile.copyWith(
        name: trimmed.isEmpty ? profile.name : trimmed,
        outputPrefix: outputPrefix,
      ),
    );
  }

  Future<void> saveProfile(FolderWatcherProfile updatedProfile) async {
    await _updateProfile(
      updatedProfile.id,
      (_) => updatedProfile,
    );
  }

  Future<void> duplicateProfile(String profileId) async {
    final profile = _profileById(profileId);
    if (profile == null) return;
    final duplicate = FolderWatcherProfile(
      id: _newId(),
      name: '${profile.name} Copy',
      videoFolderPath: profile.videoFolderPath,
      audioFolderPath: profile.audioFolderPath,
      resultFolderPath: profile.resultFolderPath,
      outputPrefix: profile.outputPrefix,
      templateId: profile.templateId,
      useOverlay: profile.useOverlay,
      overlaySettings: profile.overlaySettings,
      outputSize: profile.outputSize,
      fitMode: profile.fitMode,
    );
    profiles = [duplicate, ...profiles];
    await _saveProfiles();
    notifyListeners();
  }

  void setSelectedBatchProfile(String? profileId) {
    selectedBatchProfileId = profileId;
    notifyListeners();
  }

  Future<String> applyBatchProfile(BatchProfile batchProfile) async {
    final profileId = 'batch-${batchProfile.id}';
    final watcherProfile = _profileFromBatchProfile(
      id: profileId,
      batchProfile: batchProfile,
    );
    final exists = profiles.any((profile) => profile.id == profileId);
    profiles = exists
        ? [
            for (final profile in profiles)
              if (profile.id == profileId) watcherProfile else profile,
          ]
        : [watcherProfile, ...profiles];
    selectedBatchProfileId = batchProfile.id;
    await _saveProfiles();
    notifyListeners();
    return profileId;
  }

  Future<void> startBatchProfileWatch({
    required BatchProfile batchProfile,
    required ResultHistoryController historyController,
    DuplicateConfirmCallback? onDuplicate,
    PermissionErrorCallback? onPermissionError,
  }) async {
    final profileId = await applyBatchProfile(batchProfile);
    await startWatching(
      profileId: profileId,
      historyController: historyController,
      onDuplicate: onDuplicate,
      onPermissionError: onPermissionError,
    );
  }

  Future<void> deleteProfile(String profileId) async {
    await stopWatching(profileId);
    profiles = profiles.where((profile) => profile.id != profileId).toList();
    await _saveProfiles();
    notifyListeners();
  }

  Future<void> pickProfileVideoFolder(String profileId) async {
    await _pickAndUpdateProfile(
      profileId: profileId,
      dialogTitle: 'Select source video folder',
      update: (profile, path) => profile.copyWith(videoFolderPath: path),
    );
  }

  Future<void> pickProfileAudioFolder(String profileId) async {
    await _pickAndUpdateProfile(
      profileId: profileId,
      dialogTitle: 'Select source audio folder',
      update: (profile, path) => profile.copyWith(audioFolderPath: path),
    );
  }

  Future<void> pickProfileResultFolder(String profileId) async {
    await _pickAndUpdateProfile(
      profileId: profileId,
      dialogTitle: 'Select result folder',
      update: (profile, path) => profile.copyWith(resultFolderPath: path),
    );
  }

  Future<void> setProfilePrefix(String profileId, String prefix) async {
    await _updateProfile(
      profileId,
      (profile) => profile.copyWith(outputPrefix: prefix),
    );
  }

  Future<void> applyTemplateToProfile({
    required String profileId,
    required ProjectTemplate template,
  }) async {
    await _updateProfile(
      profileId,
      (profile) => profile.copyWith(
        templateId: template.id,
        videoFolderPath: template.videoFolder,
        audioFolderPath: template.audioFolder,
        resultFolderPath: template.outputFolder,
        outputPrefix: template.outputPrefix,
        useOverlay: template.useOverlay,
        overlaySettings: template.overlaySettings,
        outputSize: template.outputSize,
        fitMode: template.fitMode,
      ),
    );
  }

  Future<void> startWatching({
    required String profileId,
    required ResultHistoryController historyController,
    DuplicateConfirmCallback? onDuplicate,
    PermissionErrorCallback? onPermissionError,
  }) async {
    final profile = _profileById(profileId);
    if (profile == null) return;
    if (!profile.hasRequiredFolders) {
      errorMessage =
          'Select video, audio, and result folders for ${profile.name}.';
      notifyListeners();
      return;
    }

    await stopWatching(profileId);
    try {
      await _validateRequiredFolder(
        profile.videoFolderPath!,
        onPermissionError,
      );
      await _validateRequiredFolder(
        profile.audioFolderPath!,
        onPermissionError,
      );
      await _validateRequiredFolder(
        profile.resultFolderPath!,
        onPermissionError,
      );

      errorMessage = null;
      if (!profile.isActive) {
        await _updateProfile(profileId, (p) => p.copyWith(isActive: true));
      }
      _subscriptions[profileId] = Directory(profile.videoFolderPath!)
          .watch()
          .listen(
            (event) => _handleEvent(
              event,
              profileId: profileId,
              historyController: historyController,
              onDuplicate: onDuplicate,
            ),
            onError: (Object error) async {
              errorMessage = error.toString();
              await onPermissionError?.call(profile.videoFolderPath!);
              await stopWatching(profileId);
              notifyListeners();
            },
          );
    } catch (error) {
      errorMessage = error.toString();
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

  Future<void> _pickAndUpdateProfile({
    required String profileId,
    required String dialogTitle,
    required FolderWatcherProfile Function(FolderWatcherProfile, String) update,
  }) async {
    final path = await _folderPickerService.pickFolder(
      dialogTitle: dialogTitle,
    );
    if (path == null) return;
    await _updateProfile(profileId, (profile) => update(profile, path));
  }

  Future<void> _updateProfile(
    String profileId,
    FolderWatcherProfile Function(FolderWatcherProfile) update,
  ) async {
    profiles = [
      for (final profile in profiles)
        if (profile.id == profileId) update(profile) else profile,
    ];
    await _saveProfiles();
    notifyListeners();
  }

  Future<void> _saveProfiles() => _profilesService.saveAll(profiles);

  Future<List<FolderWatcherProfile>> _migrateLegacySettings() async {
    final settings = await _legacySettingsService.load();
    if (settings.videoFolderPath == null &&
        settings.audioFolderPath == null &&
        settings.resultFolderPath == null) {
      return [];
    }
    return [
      FolderWatcherProfile(
        id: _newId(),
        name: 'Default watcher',
        videoFolderPath: settings.videoFolderPath,
        audioFolderPath: settings.audioFolderPath,
        resultFolderPath: settings.resultFolderPath,
      ),
    ];
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
    required String profileId,
    required ResultHistoryController historyController,
    DuplicateConfirmCallback? onDuplicate,
  }) {
    if (event is FileSystemDeleteEvent) return;
    final extension = p.extension(event.path).toLowerCase();
    if (!AppConstants.supportedVideoExtensions.contains(extension)) return;
    final processingKey = '$profileId|${event.path}';
    if (_processing.contains(processingKey)) return;

    detectedVideos = [
      event.path,
      ...detectedVideos.where((path) => path != event.path),
    ].take(30).toList();
    notifyListeners();

    unawaited(
      _processDetectedVideo(
        profileId: profileId,
        videoPath: event.path,
        historyController: historyController,
        onDuplicate: onDuplicate,
      ),
    );
  }

  Future<void> _processDetectedVideo({
    required String profileId,
    required String videoPath,
    required ResultHistoryController historyController,
    DuplicateConfirmCallback? onDuplicate,
  }) async {
    final processingKey = '$profileId|$videoPath';
    _processing.add(processingKey);
    MediaFile? selectedAudio;
    String? plannedOutputPath;
    FolderWatcherProfile? activeProfile;
    _upsertQueue(
      WatchProcessingItem(
        videoPath: videoPath,
        status: WatchProcessingStatus.waiting,
      ),
    );

    try {
      var profile = _profileById(profileId);
      if (profile == null) return;
      activeProfile = profile;
      if (historyController.hasProcessed(videoPath)) {
        final processAgain = await onDuplicate?.call(videoPath) ?? false;
        if (!processAgain) {
          _removeProcessing(processingKey, videoPath);
          return;
        }
      }

      await _waitUntilFileReady(videoPath);
      profile = _profileById(profileId);
      if (profile == null) return;
      activeProfile = profile;
      selectedAudio = await _pickRandomAudio(profile);
      plannedOutputPath = _outputNamingService.allocateSingleOutputPath(
        outputFolderPath: profile.resultFolderPath!,
        prefix: profile.outputPrefix,
      );
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
      await Directory(p.dirname(job.outputPath)).create(recursive: true);
      final plan = await _ffmpegService.prepareReplacement(job);
      await _debugLogService.append(
        '[INFO] Auto watcher FFmpeg command:\n${plan.command}',
      );
      await _ffmpegService.runReplacement(plan);
      await _applyOptionalOverlay(job, profile);

      final record = ResultHistoryRecord(
        id: DateTime.now().microsecondsSinceEpoch.toString(),
        originalVideoPath: videoPath,
        audioPath: selectedAudio.path,
        outputPath: plannedOutputPath,
        resultFolderPath: profile.resultFolderPath!,
        status: ResultHistoryStatus.success,
        createdAt: DateTime.now(),
        processType: ResultProcessType.auto,
        outputPrefix: profile.outputPrefix,
        totalVideos: 1,
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
        resultFolderPath: p.dirname(plannedOutputPath ?? videoPath),
        status: ResultHistoryStatus.failed,
        createdAt: DateTime.now(),
        processType: ResultProcessType.auto,
        outputPrefix: activeProfile?.outputPrefix ?? '',
        totalVideos: 1,
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
      _removeProcessing(processingKey, videoPath, keepQueueItem: true);
    }
  }

  Future<void> _applyOptionalOverlay(
    SoundSwapJob job,
    FolderWatcherProfile profile,
  ) async {
    if (!profile.useOverlay &&
        profile.outputSize == VideoOutputSize.original &&
        profile.fitMode == VideoFitMode.keepOriginal) {
      return;
    }
    final tempPath = _temporaryGeneratorOutputPath(job.outputPath);
    final overlayPlan = await _overlayService.prepareOverlay(
      inputPath: job.outputPath,
      outputPath: tempPath,
      outputSize: profile.outputSize,
      fitMode: profile.fitMode,
      overlaySettings: profile.useOverlay ? profile.overlaySettings : null,
    );
    if (overlayPlan == null) return;
    await _debugLogService.append(
      '[INFO] Auto watcher overlay command:\n${overlayPlan.command}',
    );
    await _overlayService.runOverlay(overlayPlan);
    final tempFile = File(tempPath);
    if (tempFile.existsSync()) {
      final targetFile = File(job.outputPath);
      if (targetFile.existsSync()) await targetFile.delete();
      await tempFile.rename(job.outputPath);
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

  Future<MediaFile> _pickRandomAudio(FolderWatcherProfile profile) async {
    final audios = await _mediaScannerService.scanFolder(
      folderPath: profile.audioFolderPath!,
      extensions: AppConstants.supportedAudioExtensions,
    );
    if (audios.isEmpty) {
      throw FileSystemException(
        'No supported audio files found',
        profile.audioFolderPath,
      );
    }
    return audios[_random.nextInt(audios.length)];
  }

  String _temporaryGeneratorOutputPath(String outputPath) {
    final directory = p.dirname(outputPath);
    final name = p.basenameWithoutExtension(outputPath);
    final timestamp = DateTime.now().microsecondsSinceEpoch;
    return p.join(directory, '$name.generator.$timestamp.tmp.mp4');
  }

  void _upsertQueue(WatchProcessingItem item) {
    processingQueue = [
      item,
      ...processingQueue.where(
        (existing) => existing.videoPath != item.videoPath,
      ),
    ].take(40).toList();
    notifyListeners();
  }

  void _removeProcessing(
    String processingKey,
    String videoPath, {
    bool keepQueueItem = false,
  }) {
    _processing.remove(processingKey);
    if (!keepQueueItem) {
      processingQueue = processingQueue
          .where((item) => item.videoPath != videoPath)
          .toList();
    }
    notifyListeners();
  }

  FolderWatcherProfile? _profileById(String profileId) {
    for (final profile in profiles) {
      if (profile.id == profileId) return profile;
    }
    return null;
  }

  FolderWatcherProfile _profileFromBatchProfile({
    required String id,
    required BatchProfile batchProfile,
  }) {
    return FolderWatcherProfile(
      id: id,
      name: batchProfile.name,
      videoFolderPath: batchProfile.videoFolderPath,
      audioFolderPath: batchProfile.audioFolderPath,
      resultFolderPath: batchProfile.outputFolderPath,
      outputPrefix: batchProfile.outputPrefix,
      templateId: batchProfile.selectedTemplateId,
      useOverlay: batchProfile.useOverlay,
      overlaySettings: batchProfile.overlaySettings,
      outputSize: batchProfile.outputSize,
      fitMode: batchProfile.fitMode,
    );
  }

  String _newId() => DateTime.now().microsecondsSinceEpoch.toString();

  @override
  void dispose() {
    for (final subscription in _subscriptions.values) {
      subscription.cancel();
    }
    super.dispose();
  }
}

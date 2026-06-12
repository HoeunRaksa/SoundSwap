import 'dart:async';
import 'dart:io';
import 'dart:math';

import 'package:file_picker/file_picker.dart';
import 'package:flutter/foundation.dart';
import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';
import 'package:soundswap/core/constants/app_constants.dart';
import 'package:soundswap/core/video/duration_mode.dart';
import 'package:soundswap/core/video/video_output_settings.dart';
import 'package:soundswap/features/branding/data/models/branding_preset.dart';
import 'package:soundswap/features/branding/data/models/branding_settings.dart';
import 'package:soundswap/features/generator/data/services/ffmpeg_overlay_service.dart';
import 'package:soundswap/features/home/data/models/audio_settings.dart';
import 'package:soundswap/features/home/data/models/batch_profile.dart';
import 'package:soundswap/features/home/data/models/batch_queue.dart';
import 'package:soundswap/features/home/data/models/image_to_video_settings.dart';
import 'package:soundswap/features/home/data/models/media_file.dart';
import 'package:soundswap/features/home/data/models/soundswap_job.dart';
import 'package:soundswap/features/home/data/services/batch_profiles_service.dart';
import 'package:soundswap/features/home/data/services/ffmpeg_service.dart';
import 'package:soundswap/features/home/data/services/home_state_service.dart';
import 'package:soundswap/features/home/data/services/media_scanner_service.dart';
import 'package:soundswap/features/overlay_tools/data/models/overlay_preset.dart';
import 'package:soundswap/features/overlay_tools/data/models/overlay_settings.dart';
import 'package:soundswap/features/overlay_tools/data/models/overlay_item.dart';
import 'package:soundswap/features/result_history/data/models/result_history_record.dart';
import 'package:soundswap/features/result_history/presentation/state/result_history_controller.dart';
import 'package:soundswap/features/effects/presentation/state/effects_controller.dart';
import 'package:soundswap/features/templates/data/models/project_template.dart';
import 'package:soundswap/features/text_overlay/data/models/text_overlay_preset.dart';
import 'package:soundswap/features/text_overlay/data/models/text_overlay_settings.dart';
import 'package:soundswap/shared/services/debug_log_service.dart';
import 'package:soundswap/shared/services/folder_picker_service.dart';
import 'package:soundswap/shared/services/output_naming_service.dart';

class HomeController extends ChangeNotifier {
  HomeController({
    FolderPickerService? folderPickerService,
    MediaScannerService? mediaScannerService,
    FfmpegService? ffmpegService,
    FfmpegOverlayService? overlayService,
    ResultHistoryController? resultHistoryController,
    OutputNamingService? outputNamingService,
    DebugLogService? debugLogService,
    BatchProfilesService? batchProfilesService,
    HomeStateService? homeStateService,
    EffectsController? effectsController,
  }) : _folderPickerService = folderPickerService ?? FolderPickerService(),
       _mediaScannerService = mediaScannerService ?? MediaScannerService(),
       _ffmpegService = ffmpegService ?? FfmpegService(),
       _resultHistoryController = resultHistoryController,
       _outputNamingService =
           outputNamingService ?? const OutputNamingService(),
       _debugLogService = debugLogService ?? DebugLogService(),
       _batchProfilesService = batchProfilesService ?? BatchProfilesService(),
       _homeStateService = homeStateService ?? HomeStateService(),
       _effectsController = effectsController {
    _overlayService =
        overlayService ?? FfmpegOverlayService(ffmpegService: _ffmpegService);
  }

  final FolderPickerService _folderPickerService;
  final MediaScannerService _mediaScannerService;
  final FfmpegService _ffmpegService;
  late final FfmpegOverlayService _overlayService;
  final ResultHistoryController? _resultHistoryController;
  final OutputNamingService _outputNamingService;
  final DebugLogService _debugLogService;
  final BatchProfilesService _batchProfilesService;
  final HomeStateService _homeStateService;
  final EffectsController? _effectsController;
  final Random _random = Random();
  int maxRetries = 3;

  void setMaxRetries(int value) {
    if (maxRetries == value) return;
    maxRetries = value;
    unawaited(_persistLastState());
    notifyListeners();
  }

  List<String> videoFolders = [];
  List<String> audioFolders = [];
  String? outputFolderPath;
  String? statusMessage;
  String? currentVideoName;
  String? currentAudioName;
  String? currentFfmpegCommand;
  String? latestError;
  String? latestStackTrace;
  String outputNamePrefix = '';
  bool useBranding = false;
  bool useTextOverlay = false;
  bool useOverlay = false;
  bool useTemplate = false;
  String? selectedBrandingPresetId;
  String? selectedTextPresetId;
  String? selectedOverlayPresetId;
  String? selectedTemplateId;
  String? selectedBatchProfileId;
  String? selectedBatchQueueId;
  String? batchProfileMessage;
  BrandingSettings? activeBrandingSettings;
  TextOverlaySettings? activeTextOverlaySettings;
  OverlaySettings? activeOverlaySettings;
  VideoOutputSize outputSize = VideoOutputSize.original;
  VideoFitMode fitMode = VideoFitMode.keepOriginal;
  String? upscaleWarning;
  AudioSettings audioSettings = const AudioSettings();
  DurationMode durationMode = DurationMode.trimAudioToVideo;
  ImageToVideoSettings imageToVideoSettings = const ImageToVideoSettings();
  int detectedImageCount = 0;
  bool joinImages = false;

  void setJoinImages(bool value) {
    if (joinImages == value) return;
    joinImages = value;
    if (jobs.isNotEmpty) {
      jobs = _rebuildJobsFromCurrentQueue();
    }
    unawaited(_persistLastState());
    notifyListeners();
  }

  void setOutputNamePrefix(String value) {
    if (outputNamePrefix == value) return;
    outputNamePrefix = value;
    if (jobs.isNotEmpty) {
      jobs = _rebuildJobsFromCurrentQueue();
    }
    unawaited(_persistLastState());
    notifyListeners();
  }

  Future<void> applyTemplateFolders({
    required List<String> videoFolders,
    required List<String> audioFolders,
    required String? outputFolder,
    required String outputPrefix,
  }) async {
    this.videoFolders = List.from(videoFolders);
    this.audioFolders = List.from(audioFolders);
    outputFolderPath = outputFolder;
    outputNamePrefix = outputPrefix;
    await scanSelectedFolders(clearQueue: true);
    await _persistLastState();
    notifyListeners();
  }

  void setUseBranding(bool value) {
    if (useBranding == value) return;
    useBranding = value;
    if (!value) {
      selectedBrandingPresetId = null;
      activeBrandingSettings = null;
    }
    unawaited(_persistLastState());
    notifyListeners();
  }

  void setBrandingPreset(BrandingPreset? preset) {
    selectedBrandingPresetId = preset?.id;
    activeBrandingSettings = preset?.settings;
    useBranding = preset != null || useBranding;
    unawaited(_persistLastState());
    notifyListeners();
  }

  void setUseTextOverlay(bool value) {
    if (useTextOverlay == value) return;
    useTextOverlay = value;
    if (!value) {
      selectedTextPresetId = null;
      activeTextOverlaySettings = null;
    }
    unawaited(_persistLastState());
    notifyListeners();
  }

  void setUseOverlay(bool value) {
    if (useOverlay == value) return;
    useOverlay = value;
    if (!value) {
      selectedOverlayPresetId = null;
      activeOverlaySettings = null;
    }
    unawaited(_persistLastState());
    notifyListeners();
  }

  void setOverlayPreset(OverlayPreset? preset) {
    selectedOverlayPresetId = preset?.id;
    activeOverlaySettings = preset?.settings;
    useOverlay = preset != null || useOverlay;
    unawaited(_persistLastState());
    notifyListeners();
  }

  void setOverlaySettings(OverlaySettings settings) {
    selectedOverlayPresetId = null;
    activeOverlaySettings = settings;
    useOverlay = settings.hasContent || useOverlay;
    unawaited(_persistLastState());
    notifyListeners();
  }

  void setTextPreset(TextOverlayPreset? preset) {
    selectedTextPresetId = preset?.id;
    activeTextOverlaySettings = preset?.settings;
    useTextOverlay = preset != null || useTextOverlay;
    unawaited(_persistLastState());
    notifyListeners();
  }

  void setUseTemplate(bool value) {
    if (useTemplate == value) return;
    useTemplate = value;
    if (!value) {
      selectedTemplateId = null;
    }
    unawaited(_persistLastState());
    notifyListeners();
  }

  Future<void> setTemplate(ProjectTemplate? template) async {
    selectedTemplateId = template?.id;
    useTemplate = template != null || useTemplate;
    if (template != null) {
      await applyTemplateFolders(
        videoFolders: template.videoFolders,
        audioFolders: template.audioFolders,
        outputFolder: template.outputFolder,
        outputPrefix: template.outputPrefix,
      );
      applyGeneratorSettings(
        useBranding: template.useBranding,
        useTextOverlay: template.useTextOverlay,
        outputSize: template.outputSize,
        fitMode: template.fitMode,
        useOverlay: template.useOverlay,
        brandingSettings: template.branding,
        textOverlaySettings: template.textOverlay,
        overlaySettings: template.overlaySettings,
      );
    }
    unawaited(_persistLastState());
    notifyListeners();
  }

  void setOutputSize(VideoOutputSize value) {
    if (outputSize == value) return;
    outputSize = value;
    upscaleWarning = value == VideoOutputSize.original
        ? null
        : 'Upscaling may not improve quality.';
    unawaited(_persistLastState());
    notifyListeners();
  }

  void setFitMode(VideoFitMode value) {
    if (fitMode == value) return;
    fitMode = value;
    unawaited(_persistLastState());
    notifyListeners();
  }

  void setAudioSettings(AudioSettings value) {
    audioSettings = value;
    unawaited(_persistLastState());
    notifyListeners();
  }

  void setDurationMode(DurationMode value) {
    if (durationMode == value) return;
    durationMode = value;
    unawaited(_persistLastState());
    notifyListeners();
  }

  void setImageToVideoSettings(ImageToVideoSettings value) {
    imageToVideoSettings = value;
    unawaited(_persistLastState());
    notifyListeners();
  }

  void applyGeneratorSettings({
    required bool useBranding,
    required bool useTextOverlay,
    required bool useOverlay,
    required VideoOutputSize outputSize,
    required VideoFitMode fitMode,
    BrandingSettings? brandingSettings,
    TextOverlaySettings? textOverlaySettings,
    OverlaySettings? overlaySettings,
  }) {
    this.useBranding = useBranding;
    this.useTextOverlay = useTextOverlay;
    this.useOverlay = useOverlay;
    this.outputSize = outputSize;
    this.fitMode = fitMode;
    activeBrandingSettings = brandingSettings;
    activeTextOverlaySettings = textOverlaySettings;
    activeOverlaySettings = overlaySettings;
    upscaleWarning = outputSize == VideoOutputSize.original
        ? null
        : 'Upscaling may not improve quality.';
    unawaited(_persistLastState());
    notifyListeners();
  }

  int retryCount = 0;
  bool isScanning = false;
  bool isProcessing = false;
  bool stopRequested = false;
  bool queueGenerated = false;
  int currentIndex = 0;
  List<MediaFile> videos = [];
  List<MediaFile> audios = [];
  List<SoundSwapJob> jobs = [];
  List<String> debugLogs = [];
  List<BatchProfile> batchProfiles = [];
  List<BatchQueue> batchQueues = [];
  Set<String> selectedQueueVideoPaths = {};
  Map<String, BatchProfileRunStatus> batchProfileStatuses = {};

  String get logFilePath => _debugLogService.logFile.path;

  int get successCount =>
      jobs.where((job) => job.status == SoundSwapStatus.success).length;

  int get failedCount =>
      jobs.where((job) => job.status == SoundSwapStatus.failed).length;

  int get skippedCount =>
      jobs.where((job) => job.status == SoundSwapStatus.skipped).length;

  bool get canBuildQueue =>
      videoFolders.isNotEmpty &&
      audioFolders.isNotEmpty &&
      outputFolderPath != null;

  bool get canGenerateQueue => canBuildQueue && !isProcessing && !isScanning;

  bool get canStart => !isProcessing && !isScanning && jobs.isNotEmpty;

  BatchQueue? get selectedBatchQueue {
    for (final queue in batchQueues) {
      if (queue.id == selectedBatchQueueId) return queue;
    }
    return null;
  }

  bool get isFfmpegReady => _ffmpegService.isReady;

  bool get generatorFeaturesEnabled =>
      useBranding ||
      useTextOverlay ||
      useOverlay ||
      outputSize != VideoOutputSize.original ||
      fitMode != VideoFitMode.keepOriginal ||
      (_effectsController?.settings.hasActiveVideoEffects ?? false);

  String? get reencodeReason {
    final activeJob = currentIndex < jobs.length ? jobs[currentIndex] : null;
    if (activeJob != null && activeJob.video.isImage) {
      return 'image-to-video conversion is required';
    }
    if (activeJob != null &&
        p.extension(activeJob.video.path).toLowerCase() !=
            p.extension(activeJob.outputPath).toLowerCase()) {
      return 'format/extension conversion is required';
    }
    if (useBranding) return 'branding overlay is enabled';
    if (useTextOverlay) return 'text overlay is enabled';
    if (useOverlay) return 'image/shape overlay is enabled';
    if (outputSize != VideoOutputSize.original) return 'video resizing is enabled';
    if (fitMode != VideoFitMode.keepOriginal) {
      return 'video crop/fill fit mode is enabled';
    }
    if (_effectsController?.settings.hasActiveVideoEffects ?? false) {
      return 'video effects are enabled';
    }
    return null;
  }

  bool get isFastMode => reencodeReason == null;

  String get errorReport {
    final parts = [
      if (latestError != null) '[ERROR]\n$latestError',
      if (latestStackTrace != null) '[STACKTRACE]\n$latestStackTrace',
      if (currentFfmpegCommand != null)
        '[FFMPEG COMMAND]\n$currentFfmpegCommand',
    ];
    return parts.join('\n\n');
  }

  double get progress {
    if (jobs.isEmpty) {
      return 0;
    }
    return currentIndex / jobs.length;
  }

  Future<void> initialize() async {
    await initializeOutputFolder();
    await loadBatchProfiles();
    await restoreLastState();
  }

  Future<void> initializeOutputFolder() async {
    final documents = await getApplicationDocumentsDirectory();
    outputFolderPath = p.join(documents.path, AppConstants.appName);
    await Directory(outputFolderPath!).create(recursive: true);

    // Log whether FFmpeg binaries are ready
    if (!_ffmpegService.isReady) {
      const message =
          'FFmpeg files are missing in tools/ffmpeg. Please add ffmpeg.exe and ffprobe.exe.';
      statusMessage = message;
      latestError = message;
      await _logError(message);
      stderr.writeln('[ERROR] $message');
    } else {
      await _logInfo('FFmpeg binaries found.');
    }
    notifyListeners();
  }

  Future<void> loadBatchProfiles() async {
    batchProfiles = await _batchProfilesService.load();
    batchProfiles.sort((a, b) => b.updatedAt.compareTo(a.updatedAt));
    notifyListeners();
  }

  Future<void> restoreLastState() async {
    final state = await _homeStateService.load();
    if (state == null) return;
    _applyBatchProfileState(state);
    selectedBatchProfileId = state.id == 'last-home-state' ? null : state.id;
    notifyListeners();
  }

  Future<void> pickVideoFolder() async {
    final path = await _folderPickerService.pickFolder(
      dialogTitle: 'Select video folder',
    );
    if (path != null) {
      if (!videoFolders.contains(path)) {
        videoFolders.add(path);
      }
      selectedBatchProfileId = null;
      selectedBatchQueueId = null;
      await scanSelectedFolders(clearQueue: true);
      unawaited(_persistLastState());
    }
  }

  Future<void> removeVideoFolder(String path) async {
    if (videoFolders.remove(path)) {
      selectedBatchProfileId = null;
      selectedBatchQueueId = null;
      await scanSelectedFolders(clearQueue: true);
      unawaited(_persistLastState());
    }
  }

  Future<void> pickAudioFolder() async {
    final path = await _folderPickerService.pickFolder(
      dialogTitle: 'Select audio folder',
    );
    if (path != null) {
      if (!audioFolders.contains(path)) {
        audioFolders.add(path);
      }
      selectedBatchProfileId = null;
      selectedBatchQueueId = null;
      await scanSelectedFolders(clearQueue: true);
      unawaited(_persistLastState());
    }
  }

  Future<void> removeAudioFolder(String path) async {
    if (audioFolders.remove(path)) {
      selectedBatchProfileId = null;
      selectedBatchQueueId = null;
      await scanSelectedFolders(clearQueue: true);
      unawaited(_persistLastState());
    }
  }

  Future<void> pickOutputFolder() async {
    final path = await _folderPickerService.pickFolder(
      dialogTitle: 'Select output folder',
    );
    if (path != null) {
      outputFolderPath = path;
      selectedBatchProfileId = null;
      selectedBatchQueueId = null;
      await scanSelectedFolders(clearQueue: true);
      unawaited(_persistLastState());
    }
  }

  Future<void> scanSelectedFolders({bool clearQueue = false}) {
    return _scanFolders(buildQueue: false, clearQueue: clearQueue);
  }

  Future<void> generateQueue() {
    return _scanFolders(buildQueue: true, clearQueue: false);
  }

  Future<void> scanAndBuildQueue() {
    return generateQueue();
  }

  Future<void> _scanFolders({
    required bool buildQueue,
    required bool clearQueue,
  }) async {
    if (isProcessing) return;
    FfmpegService.clearProbeCache();

    isScanning = true;
    statusMessage = buildQueue
        ? 'Generating queue...'
        : 'Scanning selected folders...';
    notifyListeners();

    try {
      final totalFolders = videoFolders.length + audioFolders.length;
      debugPrint('feature name: Home Batch');
      debugPrint('selected folders count: $totalFolders');
      debugPrint('recursive scan enabled: true');
      final scanStats = ScanStats();

      videos = [];
      detectedImageCount = 0;
      if (videoFolders.isNotEmpty) {
        await _logInfo('Scanning video folders...');
        final allVideoExts = [
          ...AppConstants.supportedVideoExtensions,
          if (joinImages) ...AppConstants.supportedImageExtensions,
        ];
        
        final Map<String, MediaFile> uniqueVideos = {};
        for (final folder in videoFolders) {
          debugPrint('folder path: $folder');
          final exists = Directory(folder).existsSync();
          debugPrint('folder exists: $exists');
          if (!exists) {
            await _logError('Video folder not found: $folder');
            continue;
          }
          final items = await _mediaScannerService.scanFolder(
            folderPath: folder,
            extensions: allVideoExts,
            stats: scanStats,
          );
          for (final item in items) {
            uniqueVideos[p.normalize(item.path)] = item;
          }
        }
        
        videos = uniqueVideos.values.toList();
        videos.sort((a, b) => a.name.toLowerCase().compareTo(b.name.toLowerCase()));
        detectedImageCount = videos.where((f) => f.isImage).length;
        debugPrint('Join Images enabled: $joinImages');
        debugPrint('videos found count: ${videos.length - detectedImageCount}');
        debugPrint('images found count: $detectedImageCount');
        await _logInfo(
          'Found ${videos.length} media files ($detectedImageCount images) across ${videoFolders.length} folders',
        );
      }
      
      audios = [];
      if (audioFolders.isNotEmpty) {
        await _logInfo('Scanning audio folders...');
        final audioScanExts = [
          ...AppConstants.supportedAudioExtensions,
          ...AppConstants.supportedVideoExtensions,
        ];
        final Map<String, MediaFile> uniqueAudios = {};
        for (final folder in audioFolders) {
          debugPrint('audio folder path: $folder');
          final exists = Directory(folder).existsSync();
          debugPrint('folder exists: $exists');
          debugPrint('recursive scan enabled: true');
          if (!exists) {
            await _logError('Audio folder not found: $folder');
            continue;
          }
          final items = await _mediaScannerService.scanFolder(
            folderPath: folder,
            extensions: audioScanExts,
            stats: scanStats,
          );
          for (final item in items) {
            final isVideoExt = AppConstants.supportedVideoExtensions.contains(p.extension(item.path).toLowerCase());
            if (isVideoExt) {
              final hasAudio = await _ffmpegService.probeHasAudio(item.path);
              if (hasAudio) {
                debugPrint('accepted audio source: ${item.name}, type: video-with-audio');
                uniqueAudios[p.normalize(item.path)] = item;
              } else {
                debugPrint('skipped video source reason if no audio stream');
                await _logInfo('Skipped ${item.name}: No audio stream found.');
              }
            } else {
              debugPrint('supported audio file path found: ${item.path}');
              uniqueAudios[p.normalize(item.path)] = item;
            }
          }
        }
        
        audios = uniqueAudios.values.toList();
        audios.sort((a, b) => a.name.toLowerCase().compareTo(b.name.toLowerCase()));
        debugPrint('total files discovered: ${scanStats.totalFilesDiscovered}');
        debugPrint('final audio pool count: ${audios.length}');
        await _logInfo('Found ${audios.length} audios across ${audioFolders.length} folders');
      }


      if (buildQueue) {
        jobs = _buildJobs();
        queueGenerated = true;
        selectedQueueVideoPaths = {};
        _saveGeneratedQueue();
      } else if (clearQueue) {
        jobs = [];
        queueGenerated = false;
        selectedQueueVideoPaths = {};
        selectedBatchQueueId = null;
      }
      currentIndex = 0;
      statusMessage = _queueMessage();
      unawaited(_persistLastState());
      
      debugPrint('total files discovered: ${scanStats.totalFilesDiscovered}');
      debugPrint('supported media discovered: ${scanStats.supportedMediaDiscovered}');
      debugPrint('skipped unsupported count: ${scanStats.skippedUnsupportedCount}');
      debugPrint('skipped destination-folder count: ${scanStats.skippedDestinationFolderCount}');
      debugPrint('final queue/source count: ${jobs.length}');
    } catch (error, stackTrace) {
      await _recordException(error, stackTrace);
      statusMessage = buildQueue
          ? 'Queue generation failed. See Debug Console.'
          : 'Scan failed. See Debug Console.';
    } finally {
      isScanning = false;
      notifyListeners();
    }
  }

  Future<void> startProcessing({bool removeOldResults = false}) async {
    try {
      FfmpegService.clearProbeCache();
      _ffmpegService.resetCancelFlag();
      _overlayService.resetCancelFlag();
      await _debugLogService.clear();
      debugLogs = [];
      latestError = null;
      latestStackTrace = null;
      currentFfmpegCommand = null;
      currentVideoName = null;
      currentAudioName = null;
      upscaleWarning = outputSize == VideoOutputSize.original
          ? null
          : 'Upscaling may not improve quality.';
      retryCount = 0;
      stopRequested = false;
      statusMessage = 'Validating batch...';
      notifyListeners();

      debugPrint('stopRequested value before start: $stopRequested');
      debugPrint('audio pool count before validation: ${audios.length}');

      if (audios.isEmpty && audioFolders.isNotEmpty) {
        await _logInfo('Audio pool is empty. Rescanning audio folders...');
        await scanSelectedFolders();
        debugPrint('audio pool count after rescan: ${audios.length}');
      }

      await _validateBeforeStart();

      if (removeOldResults) {
        await _removeOldResultsForPrefix();
      }
      jobs = _rebuildJobsFromCurrentQueue();
      _replaceSelectedQueue(jobs: jobs);
      selectedQueueVideoPaths = {};

      isProcessing = true;
      _setProfileStatus(selectedBatchProfileId, BatchProfileRunStatus.running);
      currentIndex = 0;
      statusMessage = 'Starting FFmpeg batch...';
      notifyListeners();

      for (var i = 0; i < jobs.length; i++) {
        if (stopRequested) {
          statusMessage = 'Batch stopped.';
          _setProfileStatus(
            selectedBatchProfileId,
            BatchProfileRunStatus.stopped,
            notify: false,
          );
          break;
        }
        currentIndex = i + 1;
        if (jobs[i].status == SoundSwapStatus.skipped) {
          await _logInfo('Skipping video: ${jobs[i].video.name}');
          continue;
        }
        await _processJobWithRetries(i);
      }

      if (!stopRequested) {
        statusMessage =
            'Completed: $successCount succeeded, $failedCount failed.';
        _setProfileStatus(
          selectedBatchProfileId,
          failedCount == 0
              ? BatchProfileRunStatus.done
              : BatchProfileRunStatus.stopped,
          notify: false,
        );
      }
      if (!stopRequested && jobs.isNotEmpty && failedCount == 0) {
        await _saveCurrentBatchProfile();
      }
      _replaceSelectedQueue(jobs: jobs);
    } catch (error, stackTrace) {
      await _recordException(error, stackTrace);
      statusMessage = 'Batch failed before processing. See Debug Console.';
    } finally {
      isProcessing = false;
      stopRequested = false;
      notifyListeners();
    }
  }

  Future<void> startBatchProfile(BatchProfile profile) async {
    if (isProcessing) return;
    await loadBatchProfile(profile);
  }

  void stopProcessing() {
    if (!isProcessing) {
      _setProfileStatus(selectedBatchProfileId, BatchProfileRunStatus.stopped);
      return;
    }
    stopRequested = true;
    statusMessage = 'Stopping...';
    _ffmpegService.cancelCurrentProcess();
    _overlayService.cancelCurrentProcess();
    notifyListeners();
  }

  Future<void> exportLog() async {
    try {
      final destination = await FilePicker.platform.saveFile(
        dialogTitle: 'Export SoundSwap log',
        fileName: 'batch_log.txt',
      );
      if (destination == null) {
        return;
      }

      final source = _debugLogService.logFile;
      if (!source.existsSync()) {
        throw const BatchValidationException('No log file exists yet.');
      }
      await source.copy(destination);
      await _logInfo('Exported log file:\n$destination');
    } catch (error, stackTrace) {
      await _recordException(error, stackTrace);
    }
  }

  List<SoundSwapJob> _buildJobs() {
    return _buildJobsForVideos(videos);
  }

  List<SoundSwapJob> _buildJobsForVideos(List<MediaFile> sourceVideos) {
    if (sourceVideos.isEmpty || outputFolderPath == null) {
      return [];
    }

    final paths = _outputNamingService.allocateOutputPaths(
      outputFolderPath: outputFolderPath!,
      prefix: outputNamePrefix,
      count: sourceVideos.length,
    );
    final jobsList = <SoundSwapJob>[];
    for (var i = 0; i < sourceVideos.length; i++) {
      jobsList.add(
        SoundSwapJob(
          video: sourceVideos[i],
          audio: _randomAudio(),
          outputPath: paths[i],
        ),
      );
    }
    return jobsList;
  }

  Future<void> _validateBeforeStart() async {
    await _logInfo('Validating required folders and tools...');
    if (videoFolders.isEmpty) {
      throw const BatchValidationException('No video folders selected.');
    }
    if (audioFolders.isEmpty) {
      throw const BatchValidationException('No audio folders selected.');
    }
    if (outputFolderPath == null || outputFolderPath!.isEmpty) {
      throw const BatchValidationException('Output folder is not selected.');
    }

    if (jobs.isEmpty) {
      throw const BatchValidationException(
        'Generate and review the queue before starting.',
      );
    }
    if (audios.isEmpty) {
      throw const BatchValidationException('No supported audios found.');
    }
    for (final job in jobs) {
      if (!File(job.video.path).existsSync()) {
        throw BatchValidationException(
          'Queued video is missing: ${job.video.path}',
        );
      }
    }

    if (!isFfmpegReady) {
      throw const BatchValidationException(
        'FFmpeg files are missing in tools/ffmpeg. Please add ffmpeg.exe and ffprobe.exe.',
      );
    }

    final ffmpegAvailable = await _ffmpegService.isExecutableAvailable(
      'ffmpeg',
    );
    if (!ffmpegAvailable) {
      throw const BatchValidationException(
        'ffmpeg.exe is missing or cannot run. Check Debug Console for details.',
      );
    }
    await _logInfo('ffmpeg available');

    final ffprobeAvailable = await _ffmpegService.isExecutableAvailable(
      'ffprobe',
    );
    if (!ffprobeAvailable) {
      throw const BatchValidationException(
        'ffprobe.exe is missing or cannot run. Check Debug Console for details.',
      );
    }
    await _logInfo('ffprobe available');
  }

  Future<void> _validateJobBeforeRun(SoundSwapJob job) async {
    // 1. Output directory check/creation
    final outputDir = Directory(p.dirname(job.outputPath));
    try {
      await outputDir.create(recursive: true);
    } catch (e) {
      throw FfmpegException('Failed: Output folder is not writable (${outputDir.path})');
    }

    // 2. Validate branding settings if enabled
    if (useBranding && activeBrandingSettings != null) {
      final branding = activeBrandingSettings!;
      if (branding.hasLogo) {
        if (branding.logoPath == null || branding.logoPath!.trim().isEmpty) {
          throw const FfmpegException('Failed: missing overlay logo path');
        }
        if (!File(branding.logoPath!).existsSync()) {
          throw FfmpegException('Failed: missing overlay logo image file (${branding.logoPath})');
        }
      }
      if (branding.hasContactText) {
        if (branding.fontFamily.trim().isEmpty) {
          throw const FfmpegException('Failed: font family is empty in branding settings');
        }
      }
    }

    // 3. Validate text overlay settings if enabled
    if (useTextOverlay && activeTextOverlaySettings != null) {
      final textSettings = activeTextOverlaySettings!;
      if (textSettings.fontFamily.trim().isEmpty) {
        throw const FfmpegException('Failed: font family is empty in text overlay settings');
      }
    }

    // 4. Validate custom overlay items if enabled
    if (useOverlay && activeOverlaySettings != null) {
      final overlaySettings = activeOverlaySettings!;
      
      // Check default font path if specified
      if (overlaySettings.defaultFontPath != null && overlaySettings.defaultFontPath!.trim().isNotEmpty) {
        if (!File(overlaySettings.defaultFontPath!).existsSync()) {
          throw FfmpegException('Failed: missing default font file (${overlaySettings.defaultFontPath})');
        }
      }

      for (final item in overlaySettings.items) {
        if (!item.hasContent) continue;
        
        // Check overlay positions are valid
        if (item.position.xPercent.isNaN || item.position.xPercent.isInfinite ||
            item.position.yPercent.isNaN || item.position.yPercent.isInfinite) {
          throw FfmpegException('Failed: invalid position coordinates for overlay item ${item.name}');
        }
        if (item.width.isNaN || item.width.isInfinite || item.width < 0) {
          throw FfmpegException('Failed: invalid width for overlay item ${item.name}');
        }

        if (item.type == OverlayItemType.image) {
          if (item.imagePath == null || item.imagePath!.trim().isEmpty) {
            throw FfmpegException('Failed: missing image path for item ${item.name}');
          }
          if (!File(item.imagePath!).existsSync()) {
            throw FfmpegException('Failed: missing overlay image file (${item.imagePath})');
          }
        } else if (item.type == OverlayItemType.text) {
          if (item.fontPath != null && item.fontPath!.trim().isNotEmpty) {
            if (!File(item.fontPath!).existsSync()) {
              throw FfmpegException('Failed: missing font file for item ${item.name} (${item.fontPath})');
            }
          }
        }
      }
    }
  }

  Future<void> _processJobWithRetries(int jobIndex) async {
    final originalJob = jobs[jobIndex];

    // Pre-run validation checks
    try {
      await _validateJobBeforeRun(originalJob);
    } catch (validationError) {
      final errorText = validationError.toString();
      jobs[jobIndex] = originalJob.copyWith(
        status: SoundSwapStatus.failed,
        errorMessage: errorText,
      );
      await _recordManualHistory(
        job: jobs[jobIndex],
        status: ResultHistoryStatus.failed,
        errorMessage: errorText,
      );
      await _logError('Validation failed for ${originalJob.video.name}: $errorText');
      notifyListeners();
      return; // Skip processing/retrying and continue batch
    }
    Object? lastError;
    StackTrace? lastStackTrace;
    String? lastCommand;
    String? lastOutput;
    MediaFile? lastSelectedAudio;

    for (var attempt = 0; attempt <= maxRetries; attempt++) {
      final selectedAudio = _randomAudio();
      lastSelectedAudio = selectedAudio;
      retryCount = attempt;
      currentVideoName = originalJob.video.name;
      currentAudioName = selectedAudio.name;
      currentFfmpegCommand = null;
      jobs[jobIndex] = originalJob.copyWith(
        audio: selectedAudio,
        status: SoundSwapStatus.processing,
        retryCount: attempt,
        errorMessage: null,
      );
      notifyListeners();

      String? tempImageVideoPath;
      try {
        await Directory(
          p.dirname(originalJob.outputPath),
        ).create(recursive: true);
        await _logInfo('Processing video: ${originalJob.video.name}');
        await _logInfo('Selected audio: ${selectedAudio.name}');

        // If the source is an image, convert it to a temporary video first
        String effectiveVideoPath = originalJob.video.path;
        if (originalJob.video.isImage) {
          debugPrint('processing item type video/image: image');
          tempImageVideoPath = _temporaryGeneratorOutputPath(
            originalJob.outputPath,
          ).replaceAll('.generator.', '.img2vid.');
          await _logInfo(
            'Converting image to video: ${originalJob.video.name}',
          );
          var targetW = outputSize.width ?? 1080;
          var targetH = outputSize.height ?? 1920;
          if (outputSize == VideoOutputSize.original) {
            // Need a default because we can't probe a video that doesn't exist
            targetW = 1080;
            targetH = 1920;
          }
          try {
            await _ffmpegService.convertImageToVideo(
              imagePath: originalJob.video.path,
              outputPath: tempImageVideoPath,
              settings: imageToVideoSettings,
              width: targetW,
              height: targetH,
            );
            effectiveVideoPath = tempImageVideoPath;
            debugPrint('image converted to video temp path: $tempImageVideoPath');
            await _logInfo('Image converted to video: $tempImageVideoPath');
          } catch (e) {
            if (e is FfmpegCancelException) rethrow;
            debugPrint('failed image conversion reason: $e');
            throw FfmpegException('Image conversion failed: $e');
          }
        } else {
          debugPrint('processing item type video/image: video');
        }

        final effectiveJob = tempImageVideoPath == null
            ? jobs[jobIndex]
            : jobs[jobIndex].copyWith(
                video: MediaFile(path: effectiveVideoPath),
              );

        final plan = await _ffmpegService.prepareReplacement(
          effectiveJob,
          audioSettings: audioSettings,
          durationMode: durationMode,
        );
        currentFfmpegCommand = plan.command;
        final mode = isFastMode ? 'Fast Copy Mode' : 'Re-encode Mode';
        await _logInfo('Selected export mode: $mode');
        await _logInfo('Reason why re-encode is required: ${reencodeReason ?? 'None (Fast Copy Mode active)'}');
        await _logInfo(
          'Random start position: ${plan.randomStart.toStringAsFixed(2)}',
        );
        await _logInfo(
          'Video duration: ${plan.videoDuration.toStringAsFixed(2)} seconds',
        );
        await _logInfo(
          'Audio duration: ${plan.audioDuration.toStringAsFixed(2)} seconds',
        );
        await _logInfo('Running FFmpeg command:\n${plan.command}');
        await _logInfo('Output file:\n${originalJob.outputPath}');
        notifyListeners();

        final output = await _ffmpegService.runReplacement(plan);
        await _logInfo('FFmpeg completed successfully.');
        if (output.stderr.trim().isNotEmpty) {
          await _logInfo('FFmpeg STDERR:\n${output.stderr}');
        }

        // Clean up temp image-to-video file
        if (tempImageVideoPath != null) {
          final tempFile = File(tempImageVideoPath);
          if (tempFile.existsSync()) await tempFile.delete();
        }

        final overlayOutput = await _applyOptionalGeneratorOutput(originalJob);
        if (overlayOutput?.stderr.trim().isNotEmpty ?? false) {
          await _logInfo('Overlay FFmpeg STDERR:\n${overlayOutput!.stderr}');
        }

        jobs[jobIndex] = jobs[jobIndex].copyWith(
          status: SoundSwapStatus.success,
          retryCount: attempt,
          ffmpegCommand: plan.command,
          ffmpegOutput: output.stderr,
          errorMessage: null,
        );
        await _recordManualHistory(
          job: jobs[jobIndex],
          status: ResultHistoryStatus.success,
        );
        notifyListeners();
        return;
      } catch (error, stackTrace) {
        if (error is FfmpegCancelException) {
          await _logInfo('Batch processing stopped by user for ${originalJob.video.name}.');
          jobs[jobIndex] = originalJob.copyWith(
            status: SoundSwapStatus.skipped,
            ffmpegCommand: currentFfmpegCommand,
            errorMessage: 'Cancelled by user',
          );
          
          final outFile = File(originalJob.outputPath);
          if (outFile.existsSync()) {
            await outFile.delete();
          }
          if (tempImageVideoPath != null) {
            final tempFile = File(tempImageVideoPath);
            if (tempFile.existsSync()) await tempFile.delete();
          }
          notifyListeners();
          return;
        }

        lastError = error;
        lastStackTrace = stackTrace;
        lastCommand = currentFfmpegCommand;
        lastOutput = error is FfmpegFailure ? error.stderr : null;
        await _recordException(error, stackTrace);

        if (attempt < maxRetries) {
          await _logInfo(
            'Retrying ${originalJob.video.name}. Retry ${attempt + 1} of $maxRetries.',
          );
        }
      }
    }

    final errorText = lastError?.toString() ?? 'Unknown batch error.';
    jobs[jobIndex] = originalJob.copyWith(
      audio: lastSelectedAudio ?? originalJob.audio,
      status: SoundSwapStatus.failed,
      retryCount: maxRetries,
      ffmpegCommand: lastCommand,
      ffmpegOutput: lastOutput,
      stackTrace: lastStackTrace?.toString(),
      errorMessage: errorText,
    );
    await _recordManualHistory(
      job: jobs[jobIndex],
      status: ResultHistoryStatus.failed,
      errorMessage: errorText,
    );
    await _logError('All retries failed for ${originalJob.video.name}.');
    notifyListeners();
  }


  MediaFile _randomAudio() {
    if (audios.isEmpty) return const MediaFile(path: '');
    return audios[_random.nextInt(audios.length)];
  }

  void toggleQueuedVideoSelection(String videoPath, bool selected) {
    selectedQueueVideoPaths = {
      ...selectedQueueVideoPaths.where((path) => path != videoPath),
      if (selected) videoPath,
    };
    notifyListeners();
  }

  void removeQueuedVideo(String videoPath) {
    final remainingVideos = jobs
        .where((job) => job.video.path != videoPath)
        .map((job) => job.video)
        .toList();
    jobs = _buildJobsForVideos(remainingVideos);
    videos = videos.where((video) => video.path != videoPath).toList();
    _replaceSelectedQueue(videos: videos, jobs: jobs);
    selectedQueueVideoPaths = {
      ...selectedQueueVideoPaths.where((path) => path != videoPath),
    };
    statusMessage = _queueMessage();
    notifyListeners();
  }

  void removeSelectedQueuedVideos() {
    if (selectedQueueVideoPaths.isEmpty) return;
    final selected = selectedQueueVideoPaths;
    final remainingVideos = jobs
        .where((job) => !selected.contains(job.video.path))
        .map((job) => job.video)
        .toList();
    jobs = _buildJobsForVideos(remainingVideos);
    videos = videos.where((video) => !selected.contains(video.path)).toList();
    _replaceSelectedQueue(videos: videos, jobs: jobs);
    selectedQueueVideoPaths = {};
    statusMessage = _queueMessage();
    notifyListeners();
  }

  void toggleJobSkip(int index) {
    if (index < 0 || index >= jobs.length) return;
    final currentStatus = jobs[index].status;
    if (currentStatus == SoundSwapStatus.queued) {
      jobs[index] = jobs[index].copyWith(status: SoundSwapStatus.skipped);
    } else if (currentStatus == SoundSwapStatus.skipped) {
      jobs[index] = jobs[index].copyWith(status: SoundSwapStatus.queued);
    }
    notifyListeners();
  }

  void skipSelectedJobs() {
    for (var i = 0; i < jobs.length; i++) {
      if (selectedQueueVideoPaths.contains(jobs[i].video.path) &&
          jobs[i].status == SoundSwapStatus.queued) {
        jobs[i] = jobs[i].copyWith(status: SoundSwapStatus.skipped);
      }
    }
    selectedQueueVideoPaths = {};
    notifyListeners();
  }

  void unskipSelectedJobs() {
    for (var i = 0; i < jobs.length; i++) {
      if (selectedQueueVideoPaths.contains(jobs[i].video.path) &&
          jobs[i].status == SoundSwapStatus.skipped) {
        jobs[i] = jobs[i].copyWith(status: SoundSwapStatus.queued);
      }
    }
    selectedQueueVideoPaths = {};
    notifyListeners();
  }

  void clearQueue() {
    jobs = [];
    selectedQueueVideoPaths = {};
    queueGenerated = false;
    currentIndex = 0;
    if (selectedBatchQueueId != null) {
      batchQueues = batchQueues
          .where((queue) => queue.id != selectedBatchQueueId)
          .toList();
      selectedBatchQueueId = null;
    }
    statusMessage = 'Queue cleared. Generate a queue to start.';
    notifyListeners();
  }

  void selectBatchQueue(String queueId) {
    final queue = batchQueues.firstWhere(
      (queue) => queue.id == queueId,
      orElse: () => selectedBatchQueue ?? batchQueues.first,
    );
    selectedBatchQueueId = queue.id;
    _applyBatchProfileState(queue.profile);
    selectedBatchProfileId = queue.profile.id;
    videos = queue.videos;
    audios = queue.audios;
    jobs = queue.jobs;
    queueGenerated = true;
    _setProfileStatus(
      selectedBatchProfileId,
      BatchProfileRunStatus.queued,
      notify: false,
    );
    selectedQueueVideoPaths = {};
    statusMessage = 'Ready: ${jobs.length} videos queued.';
    unawaited(_persistLastState());
    notifyListeners();
  }

  List<SoundSwapJob> _rebuildJobsFromCurrentQueue() {
    final sourceVideos = jobs.map((job) => job.video).toList();
    return _buildJobsForVideos(sourceVideos);
  }

  void _saveGeneratedQueue() {
    final now = DateTime.now();
    final profile = _currentBatchProfileSnapshot(
      id: selectedBatchProfileId ?? 'manual-${now.microsecondsSinceEpoch}',
      name: _activeQueueName(),
      createdAt: now,
      updatedAt: now,
    );
    final existingId = selectedBatchQueueIdForProfile(profile.id);
    final queue = BatchQueue(
      id: existingId ?? now.microsecondsSinceEpoch.toString(),
      profile: profile,
      createdAt: now,
      videos: [...videos],
      audios: [...audios],
      jobs: [...jobs],
    );
    selectedBatchQueueId = queue.id;
    _setProfileStatus(profile.id, BatchProfileRunStatus.queued, notify: false);
    batchQueues = [
      queue,
      ...batchQueues.where((item) => item.id != queue.id),
    ].take(12).toList();
  }

  String? selectedBatchQueueIdForProfile(String profileId) {
    for (final queue in batchQueues) {
      if (queue.profile.id == profileId) return queue.id;
    }
    return null;
  }

  void _replaceSelectedQueue({
    List<MediaFile>? videos,
    List<MediaFile>? audios,
    List<SoundSwapJob>? jobs,
    BatchProfile? profile,
  }) {
    final queueId = selectedBatchQueueId;
    if (queueId == null) return;
    batchQueues = [
      for (final queue in batchQueues)
        if (queue.id == queueId)
          queue.copyWith(
            profile: profile,
            videos: videos,
            audios: audios,
            jobs: jobs,
          )
        else
          queue,
    ];
  }

  Future<void> _removeOldResultsForPrefix() async {
    final folder = outputFolderPath;
    if (folder == null) return;
    final directory = Directory(folder);
    if (!directory.existsSync()) return;
    final prefix = _outputNamingService.normalizePrefix(outputNamePrefix);
    final pattern = RegExp(
      '^${RegExp.escape(prefix)}-(\\d+)\\.mp4\$',
      caseSensitive: false,
    );
    var removed = 0;
    for (final entity in directory.listSync(followLinks: false)) {
      if (entity is! File) continue;
      if (!pattern.hasMatch(p.basename(entity.path))) continue;
      await entity.delete();
      removed++;
    }
    await _logInfo('Removed $removed old result files for prefix "$prefix".');
  }

  Future<ProcessRunOutput?> _applyOptionalGeneratorOutput(
    SoundSwapJob job,
  ) async {
    if (!generatorFeaturesEnabled) return null;

    final branding = useBranding ? activeBrandingSettings : null;
    final textOverlay = useTextOverlay ? activeTextOverlaySettings : null;
    final overlaySettings = useOverlay ? activeOverlaySettings : null;
    final tempPath = _temporaryGeneratorOutputPath(job.outputPath);
    final overlayPlan = await _overlayService.prepareOverlay(
      inputPath: job.outputPath,
      outputPath: tempPath,
      outputSize: outputSize,
      fitMode: fitMode,
      branding: branding,
      textOverlay: textOverlay,
      overlaySettings: overlaySettings,
      effects: _effectsController?.settings,
    );
    if (overlayPlan == null) return null;

    await _warnIfUpscaling(job.video.path);
    currentFfmpegCommand = overlayPlan.command;

    // Gather overlay image paths for logging
    final overlayImagePaths = <String>[];
    if (branding?.hasLogo ?? false) {
      overlayImagePaths.add(branding!.logoPath!);
    }
    if (overlaySettings != null) {
      for (final item in overlaySettings.items) {
        if (item.type == OverlayItemType.image && item.imagePath != null) {
          overlayImagePaths.add(item.imagePath!);
        }
      }
    }

    final mode = isFastMode ? 'Fast Copy Mode' : 'Re-encode Mode';

    // Show UI reason
    statusMessage = 'Re-encode Mode because overlay/template is enabled';
    await _logInfo('=== OVERLAY EXPORT START ===');
    await _logInfo('Export Mode: $mode');
    await _logInfo('Input Video: ${job.outputPath}');
    await _logInfo('Input Audio: ${job.audio.path}');
    await _logInfo('Overlay Images: ${overlayImagePaths.isEmpty ? "None" : overlayImagePaths.join(", ")}');
    await _logInfo('Output Path: $tempPath');
    await _logInfo('FFmpeg Command: ${overlayPlan.command}');
    await _logInfo('============================');
    notifyListeners();

    // Show processing step
    statusMessage = 'Processing overlay $currentIndex/${jobs.length}';
    notifyListeners();

    try {
      final output = await _overlayService.runOverlay(overlayPlan);
      final tempFile = File(tempPath);
      if (!tempFile.existsSync()) {
        throw FfmpegException('Overlay output was not created: $tempPath');
      }
      final targetFile = File(job.outputPath);
      if (targetFile.existsSync()) {
        await targetFile.delete();
      }
      await tempFile.rename(job.outputPath);
      
      await _logInfo('=== OVERLAY EXPORT SUCCESS ===');
      await _logInfo('Exit Code: 0');
      await _logInfo('Output Path: ${job.outputPath}');
      await _logInfo('=============================');
      return output;
    } catch (e) {
      final exitCode = e is FfmpegFailure ? e.exitCode : -1;
      final stderr = e is FfmpegFailure ? e.stderr : e.toString();
      await _logError('=== OVERLAY EXPORT FAILURE ===');
      await _logError('Exit Code: $exitCode');
      await _logError('Error: $e');
      await _logError('Stderr:\n$stderr');
      await _logError('=============================');
      rethrow;
    }
  }

  Future<void> _warnIfUpscaling(String sourcePath) async {
    final targetWidth = outputSize.width;
    final targetHeight = outputSize.height;
    if (targetWidth == null || targetHeight == null) return;

    final dimensions = await _ffmpegService.probeVideoDimensions(sourcePath);
    if (dimensions.width < targetWidth || dimensions.height < targetHeight) {
      upscaleWarning = 'Upscaling may not improve quality.';
      await _logInfo(upscaleWarning!);
      notifyListeners();
    }
  }

  String _temporaryGeneratorOutputPath(String outputPath) {
    final directory = p.dirname(outputPath);
    final name = p.basenameWithoutExtension(outputPath);
    final timestamp = DateTime.now().microsecondsSinceEpoch;
    return p.join(directory, '$name.generator.$timestamp.tmp.mp4');
  }

  Future<void> _recordManualHistory({
    required SoundSwapJob job,
    required ResultHistoryStatus status,
    String? errorMessage,
  }) async {
    final history = _resultHistoryController;
    if (history == null) return;
    await history.add(
      ResultHistoryRecord(
        id: DateTime.now().microsecondsSinceEpoch.toString(),
        originalVideoPath: job.video.path,
        audioPath: job.audio.path,
        outputPath: job.outputPath,
        resultFolderPath: p.dirname(job.outputPath),
        status: status,
        createdAt: DateTime.now(),
        processType: ResultProcessType.manual,
        outputPrefix: outputNamePrefix,
        totalVideos: jobs.length,
        errorMessage: errorMessage,
        retryCount: job.retryCount,
      ),
    );
  }

  Future<void> loadBatchProfile(BatchProfile profile) async {
    _applyBatchProfileState(profile);
    selectedBatchProfileId = profile.id;
    selectedBatchQueueId = selectedBatchQueueIdForProfile(profile.id);
    if (selectedBatchQueueId != null) {
      final queue = selectedBatchQueue;
      if (queue != null) {
        videos = queue.videos;
        audios = queue.audios;
        jobs = queue.jobs;
        queueGenerated = true;
      }
    } else {
      videos = [];
      audios = [];
      jobs = [];
      queueGenerated = false;
    }
    selectedQueueVideoPaths = {};
    batchProfileMessage = 'Loaded "${profile.name}".';
    await _persistLastState();
    notifyListeners();
  }

  Future<void> editBatchProfile(BatchProfile profile) async {
    await loadBatchProfile(profile);
    batchProfileMessage = 'Loaded "${profile.name}" for editing.';
    notifyListeners();
  }

  Future<void> saveSelectedBatchProfileChanges() async {
    final profileId = selectedBatchProfileId;
    if (profileId == null) return;
    final existing = _batchProfileById(profileId);
    if (existing == null) return;
    final updated = _currentBatchProfileSnapshot(
      id: existing.id,
      name: existing.name,
      createdAt: existing.createdAt,
      updatedAt: DateTime.now(),
    );
    batchProfiles = [
      updated,
      ...batchProfiles.where((profile) => profile.id != profileId),
    ];
    await _saveBatchProfiles();
    batchProfileMessage = 'Saved edits to "${existing.name}".';
    await _persistLastState();
    notifyListeners();
  }

  Future<void> renameBatchProfile({
    required BatchProfile profile,
    required String name,
  }) async {
    final trimmed = name.trim();
    if (trimmed.isEmpty) return;
    batchProfiles = [
      for (final item in batchProfiles)
        if (item.id == profile.id)
          item.copyWith(name: trimmed, updatedAt: DateTime.now())
        else
          item,
    ];
    await _saveBatchProfiles();
    batchProfileMessage = 'Renamed profile.';
    notifyListeners();
  }

  Future<void> createBatchProfile({
    required String name,
    required List<String> videoFolders,
    required List<String> audioFolders,
    required String? outputFolderPath,
    required String outputPrefix,
  }) async {
    final now = DateTime.now();
    final current = _currentBatchProfileSnapshot(
      id: now.microsecondsSinceEpoch.toString(),
      name: _cleanProfileName(name, fallback: _defaultBatchProfileName()),
      createdAt: now,
      updatedAt: now,
    );
    final profile = BatchProfile(
      id: current.id,
      name: current.name,
      createdAt: current.createdAt,
      updatedAt: current.updatedAt,
      videoFolders: List.from(videoFolders),
      audioFolders: List.from(audioFolders),
      outputFolderPath: _emptyToNull(outputFolderPath),
      outputPrefix: outputPrefix,
      useOverlay: current.useOverlay,
      selectedOverlayPresetId: current.selectedOverlayPresetId,
      overlaySettings: current.overlaySettings,
      useTemplate: current.useTemplate,
      selectedTemplateId: current.selectedTemplateId,
      outputSize: current.outputSize,
      fitMode: current.fitMode,
    );
    batchProfiles = [profile, ...batchProfiles].take(20).toList();
    selectedBatchProfileId = profile.id;
    _applyBatchProfileState(profile);
    await _saveBatchProfiles();
    await _persistLastState();
    batchProfileMessage = 'Created "${profile.name}".';
    notifyListeners();
  }

  Future<void> updateBatchProfileDetails({
    required BatchProfile profile,
    required String name,
    required List<String> videoFolders,
    required List<String> audioFolders,
    required String? outputFolderPath,
    required String outputPrefix,
  }) async {
    final updated = BatchProfile(
      id: profile.id,
      name: _cleanProfileName(name, fallback: profile.name),
      createdAt: profile.createdAt,
      updatedAt: DateTime.now(),
      videoFolders: List.from(videoFolders),
      audioFolders: List.from(audioFolders),
      outputFolderPath: _emptyToNull(outputFolderPath),
      outputPrefix: outputPrefix,
      useOverlay: profile.useOverlay,
      selectedOverlayPresetId: profile.selectedOverlayPresetId,
      overlaySettings: profile.overlaySettings,
      useTemplate: profile.useTemplate,
      selectedTemplateId: profile.selectedTemplateId,
      outputSize: profile.outputSize,
      fitMode: profile.fitMode,
    );
    batchProfiles = [
      updated,
      ...batchProfiles.where((item) => item.id != profile.id),
    ];
    if (selectedBatchProfileId == profile.id) {
      _applyBatchProfileState(updated);
      await _persistLastState();
    }
    final queueId = selectedBatchQueueIdForProfile(profile.id);
    if (queueId != null) {
      batchQueues = [
        for (final queue in batchQueues)
          if (queue.id == queueId) queue.copyWith(profile: updated) else queue,
      ];
    }
    await _saveBatchProfiles();
    batchProfileMessage = 'Updated "${updated.name}".';
    notifyListeners();
  }

  Future<void> deleteBatchProfile(BatchProfile profile) async {
    batchProfiles = batchProfiles
        .where((item) => item.id != profile.id)
        .toList();
    if (selectedBatchProfileId == profile.id) {
      selectedBatchProfileId = null;
    }
    final statuses = {...batchProfileStatuses};
    statuses.remove(profile.id);
    batchProfileStatuses = statuses;
    await _saveBatchProfiles();
    batchProfileMessage = 'Deleted "${profile.name}".';
    notifyListeners();
  }

  Future<void> _saveCurrentBatchProfile() async {
    final now = DateTime.now();
    final selected = selectedBatchProfileId == null
        ? null
        : _batchProfileById(selectedBatchProfileId!);
    final matching = selected ?? _matchingBatchProfile();
    final profile = _currentBatchProfileSnapshot(
      id: matching?.id ?? now.microsecondsSinceEpoch.toString(),
      name: matching?.name ?? _defaultBatchProfileName(),
      createdAt: matching?.createdAt ?? now,
      updatedAt: now,
    );
    selectedBatchProfileId = profile.id;
    _replaceSelectedQueue(profile: profile);
    batchProfiles = [
      profile,
      ...batchProfiles.where((item) => item.id != profile.id),
    ].take(20).toList();
    await _saveBatchProfiles();
    batchProfileMessage = 'Saved recent batch profile "${profile.name}".';
    await _persistLastState();
    notifyListeners();
  }

  Future<void> _saveBatchProfiles() async {
    batchProfiles.sort((a, b) => b.updatedAt.compareTo(a.updatedAt));
    await _batchProfilesService.saveAll(batchProfiles);
  }

  BatchProfile _currentBatchProfileSnapshot({
    required String id,
    required String name,
    required DateTime createdAt,
    required DateTime updatedAt,
  }) {
    return BatchProfile(
      id: id,
      name: name,
      createdAt: createdAt,
      updatedAt: updatedAt,
      videoFolders: videoFolders,
      audioFolders: audioFolders,
      outputFolderPath: outputFolderPath,
      outputPrefix: outputNamePrefix,
      useOverlay: useOverlay,
      selectedOverlayPresetId: selectedOverlayPresetId,
      overlaySettings: activeOverlaySettings ?? const OverlaySettings(),
      useTemplate: useTemplate,
      selectedTemplateId: selectedTemplateId,
      outputSize: outputSize,
      fitMode: fitMode,
      audioSettings: audioSettings,
      durationMode: durationMode,
      imageToVideoSettings: imageToVideoSettings,
      maxRetries: maxRetries,
    );
  }

  void _applyBatchProfileState(BatchProfile profile) {
    videoFolders = List.from(profile.videoFolders);
    audioFolders = List.from(profile.audioFolders);
    outputFolderPath = profile.outputFolderPath ?? outputFolderPath;
    outputNamePrefix = profile.outputPrefix;
    useOverlay = profile.useOverlay;
    selectedOverlayPresetId = profile.selectedOverlayPresetId;
    activeOverlaySettings = profile.overlaySettings;
    useTemplate = profile.useTemplate;
    selectedTemplateId = profile.selectedTemplateId;
    outputSize = profile.outputSize;
    fitMode = profile.fitMode;
    audioSettings = profile.audioSettings;
    durationMode = profile.durationMode;
    imageToVideoSettings = profile.imageToVideoSettings;
    maxRetries = profile.maxRetries;
    upscaleWarning = outputSize == VideoOutputSize.original
        ? null
        : 'Upscaling may not improve quality.';
  }

  Future<void> _persistLastState() async {
    final now = DateTime.now();
    await _homeStateService.save(
      _currentBatchProfileSnapshot(
        id: selectedBatchProfileId ?? 'last-home-state',
        name: 'Last used batch',
        createdAt: now,
        updatedAt: now,
      ),
    );
  }

  BatchProfile? _batchProfileById(String id) {
    for (final profile in batchProfiles) {
      if (profile.id == id) return profile;
    }
    return null;
  }

  BatchProfile? _matchingBatchProfile() {
    for (final profile in batchProfiles) {
      if (_samePathList(profile.videoFolders, videoFolders) &&
          _samePathList(profile.audioFolders, audioFolders) &&
          _samePath(profile.outputFolderPath, outputFolderPath) &&
          profile.outputPrefix == outputNamePrefix &&
          profile.selectedTemplateId == selectedTemplateId &&
          profile.outputSize == outputSize &&
          profile.fitMode == fitMode) {
        return profile;
      }
    }
    return null;
  }

  bool _samePath(String? left, String? right) {
    if (left == null || right == null) return left == right;
    return p.equals(p.normalize(left), p.normalize(right));
  }

  bool _samePathList(List<String> left, List<String> right) {
    if (left.length != right.length) return false;
    for (int i = 0; i < left.length; i++) {
      if (!p.equals(p.normalize(left[i]), p.normalize(right[i]))) return false;
    }
    return true;
  }

  String _defaultBatchProfileName() {
    final prefix = outputNamePrefix.trim();
    if (prefix.isNotEmpty) return prefix;
    final folder = videoFolders.isNotEmpty ? videoFolders.first : null;
    if (folder != null && folder.trim().isNotEmpty) {
      return p.basename(folder);
    }
    return 'Batch profile';
  }

  String _activeQueueName() {
    final selectedProfile = selectedBatchProfileId == null
        ? null
        : _batchProfileById(selectedBatchProfileId!);
    return selectedProfile?.name ?? _defaultBatchProfileName();
  }

  BatchProfileRunStatus statusForProfile(BatchProfile profile) {
    return batchProfileStatuses[profile.id] ?? BatchProfileRunStatus.stopped;
  }

  void _setProfileStatus(
    String? profileId,
    BatchProfileRunStatus status, {
    bool notify = true,
  }) {
    if (profileId == null) return;
    batchProfileStatuses = {...batchProfileStatuses, profileId: status};
    if (notify) notifyListeners();
  }

  String _cleanProfileName(String value, {required String fallback}) {
    final trimmed = value.trim();
    return trimmed.isEmpty ? fallback : trimmed;
  }

  String? _emptyToNull(String? value) {
    final trimmed = value?.trim();
    return trimmed == null || trimmed.isEmpty ? null : trimmed;
  }

  Future<void> _recordException(Object error, StackTrace stackTrace) async {
    final errorText = error.toString();
    final stackText = stackTrace.toString();
    latestError = errorText;
    latestStackTrace = stackText;

    if (error is FfmpegFailure) {
      await _logError('FFmpeg failed');
      await _logError('Exit code: ${error.exitCode}');
      await _logError('STDERR:\n${error.stderr}');
      if (error.stdout.trim().isNotEmpty) {
        await _logError('STDOUT:\n${error.stdout}');
      }
      await _logInfo('Running FFmpeg command:\n${error.command}');
    } else {
      await _logError('Exception:\n$errorText');
    }
    await _logError('StackTrace:\n$stackText');
    notifyListeners();
  }

  Future<void> _logInfo(String message) => _appendLog('[INFO] $message');

  Future<void> _logError(String message) => _appendLog('[ERROR] $message');

  Future<void> _appendLog(String message) async {
    debugLogs = [...debugLogs, message];
    await _debugLogService.append(message);
    notifyListeners();
  }

  String _queueMessage() {
    if (videoFolders.isEmpty || audioFolders.isEmpty) {
      return 'Select video and audio folders to start.';
    }
    if (videos.isEmpty) {
      return 'No supported videos found.';
    }
    if (jobs.isEmpty && !queueGenerated) {
      return 'Folders scanned. Generate Queue to review files.';
    }
    if (audios.isEmpty) {
      return 'Ready: ${jobs.length} videos queued. (Warning: No supported audio files found)';
    }
    return 'Ready: ${jobs.length} videos queued.';
  }
}

class BatchValidationException implements Exception {
  const BatchValidationException(this.message);

  final String message;

  @override
  String toString() => message;
}

enum BatchProfileRunStatus { stopped, queued, running, done }

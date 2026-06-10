import 'dart:async';
import 'dart:io';
import 'dart:math';

import 'package:file_picker/file_picker.dart';
import 'package:flutter/foundation.dart';
import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';
import 'package:soundswap/core/constants/app_constants.dart';
import 'package:soundswap/core/video/video_output_settings.dart';
import 'package:soundswap/features/branding/data/models/branding_preset.dart';
import 'package:soundswap/features/branding/data/models/branding_settings.dart';
import 'package:soundswap/features/generator/data/services/ffmpeg_overlay_service.dart';
import 'package:soundswap/features/home/data/models/batch_profile.dart';
import 'package:soundswap/features/home/data/models/batch_queue.dart';
import 'package:soundswap/features/home/data/models/media_file.dart';
import 'package:soundswap/features/home/data/models/soundswap_job.dart';
import 'package:soundswap/features/home/data/services/batch_profiles_service.dart';
import 'package:soundswap/features/home/data/services/ffmpeg_service.dart';
import 'package:soundswap/features/home/data/services/home_state_service.dart';
import 'package:soundswap/features/home/data/services/media_scanner_service.dart';
import 'package:soundswap/features/overlay_tools/data/models/overlay_preset.dart';
import 'package:soundswap/features/overlay_tools/data/models/overlay_settings.dart';
import 'package:soundswap/features/result_history/data/models/result_history_record.dart';
import 'package:soundswap/features/result_history/presentation/state/result_history_controller.dart';
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
  }) : _folderPickerService = folderPickerService ?? FolderPickerService(),
       _mediaScannerService = mediaScannerService ?? MediaScannerService(),
       _ffmpegService = ffmpegService ?? FfmpegService(),
       _resultHistoryController = resultHistoryController,
       _outputNamingService =
           outputNamingService ?? const OutputNamingService(),
       _debugLogService = debugLogService ?? DebugLogService(),
       _batchProfilesService = batchProfilesService ?? BatchProfilesService(),
       _homeStateService = homeStateService ?? HomeStateService() {
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
  final Random _random = Random();
  static const int _maxRetries = 3;

  String? videoFolderPath;
  String? audioFolderPath;
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

  void setOutputNamePrefix(String value) {
    outputNamePrefix = value;
    if (jobs.isNotEmpty) {
      jobs = _rebuildJobsFromCurrentQueue();
    }
    unawaited(_persistLastState());
    notifyListeners();
  }

  Future<void> applyTemplateFolders({
    required String? videoFolder,
    required String? audioFolder,
    required String? outputFolder,
    required String outputPrefix,
  }) async {
    videoFolderPath = videoFolder;
    audioFolderPath = audioFolder;
    outputFolderPath = outputFolder;
    outputNamePrefix = outputPrefix;
    await scanSelectedFolders(clearQueue: true);
    await _persistLastState();
    notifyListeners();
  }

  void setUseBranding(bool value) {
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
    useTextOverlay = value;
    if (!value) {
      selectedTextPresetId = null;
      activeTextOverlaySettings = null;
    }
    unawaited(_persistLastState());
    notifyListeners();
  }

  void setUseOverlay(bool value) {
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
        videoFolder: template.videoFolder,
        audioFolder: template.audioFolder,
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
    outputSize = value;
    upscaleWarning = value == VideoOutputSize.original
        ? null
        : 'Upscaling may not improve quality.';
    unawaited(_persistLastState());
    notifyListeners();
  }

  void setFitMode(VideoFitMode value) {
    fitMode = value;
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

  bool get canBuildQueue =>
      videoFolderPath != null &&
      audioFolderPath != null &&
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
      fitMode != VideoFitMode.keepOriginal;

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
    if (canBuildQueue) {
      await generateQueue();
    } else {
      notifyListeners();
    }
  }

  Future<void> pickVideoFolder() async {
    final path = await _folderPickerService.pickFolder(
      dialogTitle: 'Select video folder',
    );
    if (path != null) {
      videoFolderPath = path;
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
      audioFolderPath = path;
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

    isScanning = true;
    statusMessage = buildQueue
        ? 'Generating queue...'
        : 'Scanning selected folders...';
    notifyListeners();

    try {
      if (videoFolderPath != null) {
        await _logInfo('Scanning video folder...');
        videos = await _mediaScannerService.scanFolder(
          folderPath: videoFolderPath!,
          extensions: AppConstants.supportedVideoExtensions,
        );
        await _logInfo('Found ${videos.length} videos');
      }
      if (audioFolderPath != null) {
        await _logInfo('Scanning audio folder...');
        audios = await _mediaScannerService.scanFolder(
          folderPath: audioFolderPath!,
          extensions: AppConstants.supportedAudioExtensions,
        );
        await _logInfo('Found ${audios.length} audios');
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
    await generateQueue();
    _setProfileStatus(profile.id, BatchProfileRunStatus.queued);
    await startProcessing(removeOldResults: false);
  }

  void stopProcessing() {
    if (!isProcessing) {
      _setProfileStatus(selectedBatchProfileId, BatchProfileRunStatus.stopped);
      return;
    }
    stopRequested = true;
    statusMessage = 'Stopping after current file...';
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
    if (sourceVideos.isEmpty || audios.isEmpty || outputFolderPath == null) {
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
    if (videoFolderPath == null || videoFolderPath!.isEmpty) {
      throw const BatchValidationException('Video folder is not selected.');
    }
    if (audioFolderPath == null || audioFolderPath!.isEmpty) {
      throw const BatchValidationException('Audio folder is not selected.');
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

  Future<void> _processJobWithRetries(int jobIndex) async {
    final originalJob = jobs[jobIndex];
    Object? lastError;
    StackTrace? lastStackTrace;
    String? lastCommand;
    String? lastOutput;
    MediaFile? lastSelectedAudio;

    for (var attempt = 0; attempt <= _maxRetries; attempt++) {
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

      try {
        await Directory(
          p.dirname(originalJob.outputPath),
        ).create(recursive: true);
        await _logInfo('Processing video: ${originalJob.video.name}');
        await _logInfo('Selected audio: ${selectedAudio.name}');

        final plan = await _ffmpegService.prepareReplacement(jobs[jobIndex]);
        currentFfmpegCommand = plan.command;
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
        lastError = error;
        lastStackTrace = stackTrace;
        lastCommand = currentFfmpegCommand;
        lastOutput = error is FfmpegFailure ? error.stderr : null;
        await _recordException(error, stackTrace);

        if (attempt < _maxRetries) {
          await _logInfo(
            'Retrying ${originalJob.video.name}. Retry ${attempt + 1} of $_maxRetries.',
          );
        }
      }
    }

    final errorText = lastError?.toString() ?? 'Unknown batch error.';
    jobs[jobIndex] = originalJob.copyWith(
      audio: lastSelectedAudio ?? originalJob.audio,
      status: SoundSwapStatus.failed,
      retryCount: _maxRetries,
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

  MediaFile _randomAudio() => audios[_random.nextInt(audios.length)];

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
    final overlayPlan = _overlayService.prepareOverlay(
      inputPath: job.outputPath,
      outputPath: tempPath,
      outputSize: outputSize,
      fitMode: fitMode,
      branding: branding,
      textOverlay: textOverlay,
      overlaySettings: overlaySettings,
    );
    if (overlayPlan == null) return null;

    await _warnIfUpscaling(job.video.path);
    currentFfmpegCommand = overlayPlan.command;
    await _logInfo('Running FFmpeg overlay command:\n${overlayPlan.command}');
    notifyListeners();

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
    await _logInfo('Overlay output file:\n${job.outputPath}');
    return output;
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
    required String? videoFolderPath,
    required String? audioFolderPath,
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
      videoFolderPath: _emptyToNull(videoFolderPath),
      audioFolderPath: _emptyToNull(audioFolderPath),
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
    required String? videoFolderPath,
    required String? audioFolderPath,
    required String? outputFolderPath,
    required String outputPrefix,
  }) async {
    final updated = BatchProfile(
      id: profile.id,
      name: _cleanProfileName(name, fallback: profile.name),
      createdAt: profile.createdAt,
      updatedAt: DateTime.now(),
      videoFolderPath: _emptyToNull(videoFolderPath),
      audioFolderPath: _emptyToNull(audioFolderPath),
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
      videoFolderPath: videoFolderPath,
      audioFolderPath: audioFolderPath,
      outputFolderPath: outputFolderPath,
      outputPrefix: outputNamePrefix,
      useOverlay: useOverlay,
      selectedOverlayPresetId: selectedOverlayPresetId,
      overlaySettings: activeOverlaySettings ?? const OverlaySettings(),
      useTemplate: useTemplate,
      selectedTemplateId: selectedTemplateId,
      outputSize: outputSize,
      fitMode: fitMode,
    );
  }

  void _applyBatchProfileState(BatchProfile profile) {
    videoFolderPath = profile.videoFolderPath;
    audioFolderPath = profile.audioFolderPath;
    outputFolderPath = profile.outputFolderPath ?? outputFolderPath;
    outputNamePrefix = profile.outputPrefix;
    useOverlay = profile.useOverlay;
    selectedOverlayPresetId = profile.selectedOverlayPresetId;
    activeOverlaySettings = profile.overlaySettings;
    useTemplate = profile.useTemplate;
    selectedTemplateId = profile.selectedTemplateId;
    outputSize = profile.outputSize;
    fitMode = profile.fitMode;
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
      if (_samePath(profile.videoFolderPath, videoFolderPath) &&
          _samePath(profile.audioFolderPath, audioFolderPath) &&
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

  String _defaultBatchProfileName() {
    final prefix = outputNamePrefix.trim();
    if (prefix.isNotEmpty) return prefix;
    final folder = videoFolderPath;
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
    if (videoFolderPath == null || audioFolderPath == null) {
      return 'Select folders, then generate a queue.';
    }
    if (videos.isEmpty) {
      return 'No supported videos found.';
    }
    if (audios.isEmpty) {
      return 'No supported audio files found.';
    }
    if (jobs.isEmpty && !queueGenerated) {
      return 'Folders scanned. Generate Queue to review files.';
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

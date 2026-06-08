import 'dart:io';
import 'dart:math';

import 'package:file_picker/file_picker.dart';
import 'package:flutter/foundation.dart';
import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';
import 'package:soundswap/core/constants/app_constants.dart';
import 'package:soundswap/features/home/data/models/media_file.dart';
import 'package:soundswap/features/home/data/models/soundswap_job.dart';
import 'package:soundswap/features/home/data/services/ffmpeg_service.dart';
import 'package:soundswap/features/home/data/services/media_scanner_service.dart';
import 'package:soundswap/shared/services/debug_log_service.dart';
import 'package:soundswap/shared/services/folder_picker_service.dart';

class HomeController extends ChangeNotifier {
  HomeController({
    FolderPickerService? folderPickerService,
    MediaScannerService? mediaScannerService,
    FfmpegService? ffmpegService,
    DebugLogService? debugLogService,
  }) : _folderPickerService = folderPickerService ?? FolderPickerService(),
       _mediaScannerService = mediaScannerService ?? MediaScannerService(),
       _ffmpegService = ffmpegService ?? FfmpegService(),
       _debugLogService = debugLogService ?? DebugLogService();

  final FolderPickerService _folderPickerService;
  final MediaScannerService _mediaScannerService;
  final FfmpegService _ffmpegService;
  final DebugLogService _debugLogService;
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

  void setOutputNamePrefix(String value) {
    outputNamePrefix = value;
    jobs = _buildJobs();
    notifyListeners();
  }

  int retryCount = 0;
  bool isScanning = false;
  bool isProcessing = false;
  int currentIndex = 0;
  List<MediaFile> videos = [];
  List<MediaFile> audios = [];
  List<SoundSwapJob> jobs = [];
  List<String> debugLogs = [];

  String get logFilePath => _debugLogService.logFile.path;

  int get successCount =>
      jobs.where((job) => job.status == SoundSwapStatus.success).length;

  int get failedCount =>
      jobs.where((job) => job.status == SoundSwapStatus.failed).length;

  bool get canBuildQueue =>
      videoFolderPath != null &&
      audioFolderPath != null &&
      outputFolderPath != null;

  bool get canStart => !isProcessing && !isScanning;

  bool get isFfmpegReady => _ffmpegService.isReady;

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

  Future<void> initializeOutputFolder() async {
    final documents = await getApplicationDocumentsDirectory();
    outputFolderPath = p.join(documents.path, AppConstants.appName);
    await Directory(outputFolderPath!).create(recursive: true);
    
    // Log whether FFmpeg binaries are ready
    if (!_ffmpegService.isReady) {
      await _logError('FFmpeg binaries not found at tools/ffmpeg/');
      stderr.writeln('[ERROR] FFmpeg binaries not found at tools/ffmpeg/');
    } else {
      await _logInfo('FFmpeg binaries found.');
    }
    notifyListeners();
  }

  Future<void> pickVideoFolder() async {
    final path = await _folderPickerService.pickFolder(
      dialogTitle: 'Select video folder',
    );
    if (path != null) {
      videoFolderPath = path;
      await scanAndBuildQueue();
    }
  }

  Future<void> pickAudioFolder() async {
    final path = await _folderPickerService.pickFolder(
      dialogTitle: 'Select audio folder',
    );
    if (path != null) {
      audioFolderPath = path;
      await scanAndBuildQueue();
    }
  }

  Future<void> pickOutputFolder() async {
    final path = await _folderPickerService.pickFolder(
      dialogTitle: 'Select output folder',
    );
    if (path != null) {
      outputFolderPath = path;
      await scanAndBuildQueue();
    }
  }

  Future<void> scanAndBuildQueue() async {
    if (isProcessing) return;

    isScanning = true;
    statusMessage = 'Scanning selected folders...';
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

      jobs = _buildJobs();
      currentIndex = 0;
      statusMessage = _queueMessage();
    } catch (error, stackTrace) {
      await _recordException(error, stackTrace);
      statusMessage = 'Scan failed. See Debug Console.';
    } finally {
      isScanning = false;
      notifyListeners();
    }
  }

  Future<void> startProcessing() async {
    try {
      await _debugLogService.clear();
      debugLogs = [];
      latestError = null;
      latestStackTrace = null;
      currentFfmpegCommand = null;
      currentVideoName = null;
      currentAudioName = null;
      retryCount = 0;
      statusMessage = 'Validating batch...';
      notifyListeners();

      await _validateBeforeStart();

      isProcessing = true;
      currentIndex = 0;
      statusMessage = 'Starting FFmpeg batch...';
      jobs = _buildJobs();
      notifyListeners();

      for (var i = 0; i < jobs.length; i++) {
        currentIndex = i + 1;
        await _processJobWithRetries(i);
      }

      statusMessage =
          'Completed: $successCount succeeded, $failedCount failed.';
    } catch (error, stackTrace) {
      await _recordException(error, stackTrace);
      statusMessage = 'Batch failed before processing. See Debug Console.';
    } finally {
      isProcessing = false;
      notifyListeners();
    }
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
    if (videos.isEmpty || audios.isEmpty || outputFolderPath == null) {
      return [];
    }

    final prefix = outputNamePrefix.trim().isEmpty ? 'soundswap' : outputNamePrefix.trim();
    final allocatedPaths = <String>{};
    final jobsList = <SoundSwapJob>[];

    var currentNum = 1;
    for (var i = 0; i < videos.length; i++) {
      String candidatePath;
      while (true) {
        final fileName = '$prefix-$currentNum.mp4';
        candidatePath = p.join(outputFolderPath!, fileName);
        if (!File(candidatePath).existsSync() && !allocatedPaths.contains(candidatePath)) {
          allocatedPaths.add(candidatePath);
          currentNum++;
          break;
        }
        currentNum++;
      }

      jobsList.add(
        SoundSwapJob(
          video: videos[i],
          audio: _randomAudio(),
          outputPath: candidatePath,
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

    await scanAndBuildQueue();

    if (videos.isEmpty) {
      throw const BatchValidationException('No supported videos found.');
    }
    if (audios.isEmpty) {
      throw const BatchValidationException('No supported audios found.');
    }

    if (!isFfmpegReady) {
      throw const BatchValidationException(
        'FFmpeg executables are missing. Check Debug Console for details.',
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

    for (var attempt = 0; attempt <= _maxRetries; attempt++) {
      final selectedAudio = _randomAudio();
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

        jobs[jobIndex] = jobs[jobIndex].copyWith(
          status: SoundSwapStatus.success,
          retryCount: attempt,
          ffmpegCommand: plan.command,
          ffmpegOutput: output.stderr,
          errorMessage: null,
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
      status: SoundSwapStatus.failed,
      retryCount: _maxRetries,
      ffmpegCommand: lastCommand,
      ffmpegOutput: lastOutput,
      stackTrace: lastStackTrace?.toString(),
      errorMessage: errorText,
    );
    await _logError('All retries failed for ${originalJob.video.name}.');
    notifyListeners();
  }

  MediaFile _randomAudio() => audios[_random.nextInt(audios.length)];

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
      return 'Select folders to build a queue.';
    }
    if (videos.isEmpty) {
      return 'No supported videos found.';
    }
    if (audios.isEmpty) {
      return 'No supported audio files found.';
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

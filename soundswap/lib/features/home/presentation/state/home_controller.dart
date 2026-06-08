import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';
import 'package:soundswap/core/constants/app_constants.dart';
import 'package:soundswap/core/utils/file_name_utils.dart';
import 'package:soundswap/features/home/data/models/media_file.dart';
import 'package:soundswap/features/home/data/models/soundswap_job.dart';
import 'package:soundswap/features/home/data/services/ffmpeg_service.dart';
import 'package:soundswap/features/home/data/services/media_scanner_service.dart';
import 'package:soundswap/shared/services/folder_picker_service.dart';

class HomeController extends ChangeNotifier {
  HomeController({
    FolderPickerService? folderPickerService,
    MediaScannerService? mediaScannerService,
    FfmpegService? ffmpegService,
  }) : _folderPickerService = folderPickerService ?? FolderPickerService(),
       _mediaScannerService = mediaScannerService ?? MediaScannerService(),
       _ffmpegService = ffmpegService ?? FfmpegService();

  final FolderPickerService _folderPickerService;
  final MediaScannerService _mediaScannerService;
  final FfmpegService _ffmpegService;

  String? videoFolderPath;
  String? audioFolderPath;
  String? outputFolderPath;
  String? statusMessage;
  bool isScanning = false;
  bool isProcessing = false;
  int currentIndex = 0;
  List<MediaFile> videos = [];
  List<MediaFile> audios = [];
  List<SoundSwapJob> jobs = [];

  int get successCount =>
      jobs.where((job) => job.status == SoundSwapStatus.success).length;

  int get failedCount =>
      jobs.where((job) => job.status == SoundSwapStatus.failed).length;

  bool get canBuildQueue =>
      videoFolderPath != null &&
      audioFolderPath != null &&
      outputFolderPath != null;

  bool get canStart => jobs.isNotEmpty && !isProcessing;

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
    if (!canBuildQueue || isProcessing) {
      notifyListeners();
      return;
    }

    isScanning = true;
    statusMessage = 'Scanning selected folders...';
    notifyListeners();

    videos = await _mediaScannerService.scanFolder(
      folderPath: videoFolderPath!,
      extensions: AppConstants.supportedVideoExtensions,
    );
    audios = await _mediaScannerService.scanFolder(
      folderPath: audioFolderPath!,
      extensions: AppConstants.supportedAudioExtensions,
    );

    jobs = _buildJobs();
    currentIndex = 0;
    isScanning = false;
    statusMessage = _queueMessage();
    notifyListeners();
  }

  Future<void> startProcessing() async {
    if (!canStart) {
      return;
    }

    isProcessing = true;
    currentIndex = 0;
    statusMessage = 'Starting FFmpeg batch...';
    jobs = [
      for (final job in jobs) job.copyWith(status: SoundSwapStatus.queued),
    ];
    notifyListeners();

    for (var i = 0; i < jobs.length; i++) {
      currentIndex = i + 1;
      jobs[i] = jobs[i].copyWith(status: SoundSwapStatus.processing);
      notifyListeners();

      try {
        await Directory(p.dirname(jobs[i].outputPath)).create(recursive: true);
        await _ffmpegService.replaceAudio(jobs[i]);
        jobs[i] = jobs[i].copyWith(status: SoundSwapStatus.success);
      } catch (error) {
        jobs[i] = jobs[i].copyWith(
          status: SoundSwapStatus.failed,
          errorMessage: error.toString(),
        );
      }
      notifyListeners();
    }

    isProcessing = false;
    statusMessage = 'Completed: $successCount succeeded, $failedCount failed.';
    notifyListeners();
  }

  List<SoundSwapJob> _buildJobs() {
    if (videos.isEmpty || audios.isEmpty || outputFolderPath == null) {
      return [];
    }

    return [
      for (var i = 0; i < videos.length; i++)
        SoundSwapJob(
          video: videos[i],
          audio: audios[i % audios.length],
          outputPath: p.join(
            outputFolderPath!,
            FileNameUtils.outputFileName(videos[i].path),
          ),
        ),
    ];
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

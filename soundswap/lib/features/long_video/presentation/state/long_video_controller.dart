import 'package:flutter/foundation.dart';
import 'package:soundswap/core/constants/app_constants.dart';
import 'package:soundswap/features/home/data/models/media_file.dart';

import 'package:soundswap/features/home/data/services/media_scanner_service.dart';
import 'package:soundswap/features/long_video/data/models/long_video_plan.dart';
import 'package:soundswap/features/long_video/data/services/long_video_service.dart';
import 'package:soundswap/shared/services/folder_picker_service.dart';

import '../../../../core/video/video_output_settings.dart';

class LongVideoController extends ChangeNotifier {
  LongVideoController({
    FolderPickerService? folderPickerService,
    MediaScannerService? mediaScannerService,
    LongVideoService? longVideoService,
  }) : _folderPickerService = folderPickerService ?? FolderPickerService(),
        _mediaScannerService = mediaScannerService ?? MediaScannerService(),
        _longVideoService = longVideoService ?? LongVideoService();

  final FolderPickerService _folderPickerService;
  final MediaScannerService _mediaScannerService;
  final LongVideoService _longVideoService;

  String? videoFolderPath;
  String? audioFolderPath;
  String? outputFolderPath;
  String outputName = 'long-video';
  double targetMinutes = 10;
  double clipSeconds = 5;
  LongVideoAudioMode audioMode = LongVideoAudioMode.randomFromFolder;
  String? selectedAudioPath;
  VideoOutputSize outputSize = VideoOutputSize.values.first;
  VideoFitMode fitMode = VideoFitMode.values.first;
  bool isPlanning = false;
  bool isExporting = false;
  String? message;
  String? errorMessage;
  LongVideoPlan? plan;
  List<MediaFile> videos = [];
  List<MediaFile> audios = [];
  List<String> logs = [];

  Future<void> pickVideoFolder() async {
    final path = await _folderPickerService.pickFolder(
      dialogTitle: 'Select video folder',
    );
    if (path == null) return;
    videoFolderPath = path;
    plan = null;
    notifyListeners();
  }

  Future<void> pickAudioFolder() async {
    final path = await _folderPickerService.pickFolder(
      dialogTitle: 'Select audio folder',
    );
    if (path == null) return;
    audioFolderPath = path;
    selectedAudioPath = null;
    plan = null;
    notifyListeners();
  }

  Future<void> pickOutputFolder() async {
    final path = await _folderPickerService.pickFolder(
      dialogTitle: 'Select output folder',
    );
    if (path == null) return;
    outputFolderPath = path;
    plan = null;
    notifyListeners();
  }

  void setOutputName(String value) {
    outputName = value;
    plan = null;
    notifyListeners();
  }

  void setTargetMinutes(String value) {
    targetMinutes = double.tryParse(value) ?? targetMinutes;
    plan = null;
    notifyListeners();
  }

  void setClipSeconds(String value) {
    clipSeconds = double.tryParse(value) ?? clipSeconds;
    plan = null;
    notifyListeners();
  }

  void setAudioMode(LongVideoAudioMode value) {
    audioMode = value;
    plan = null;
    notifyListeners();
  }

  void setSelectedAudio(String? value) {
    selectedAudioPath = value;
    plan = null;
    notifyListeners();
  }

  void setOutputSize(VideoOutputSize value) {
    outputSize = value;
    plan = null;
    notifyListeners();
  }

  void setFitMode(VideoFitMode value) {
    fitMode = value;
    plan = null;
    notifyListeners();
  }

  Future<void> generatePlan() async {
    isPlanning = true;
    errorMessage = null;
    message = 'Generating plan...';
    logs = [];
    notifyListeners();

    try {
      _validateFolders();
      videos = await _mediaScannerService.scanFolder(
        folderPath: videoFolderPath!,
        extensions: AppConstants.supportedVideoExtensions,
      );
      audios = await _mediaScannerService.scanFolder(
        folderPath: audioFolderPath!,
        extensions: AppConstants.supportedAudioExtensions,
      );
      selectedAudioPath ??= audios.isEmpty ? null : audios.first.path;
      plan = await _longVideoService.createPlan(
        videos: videos,
        audios: audios,
        outputFolderPath: outputFolderPath!,
        outputName: outputName,
        targetMinutes: targetMinutes,
        clipSeconds: clipSeconds,
        audioMode: audioMode,
        selectedAudioPath: selectedAudioPath,
      );
      message =
      'Plan ready: ${plan!.clips.length} clips, ${_format(plan!.estimatedDuration)} seconds.';
    } catch (error) {
      errorMessage = error.toString();
      message = 'Plan failed.';
    } finally {
      isPlanning = false;
      notifyListeners();
    }
  }

  Future<void> startExport() async {
    final currentPlan = plan;
    if (currentPlan == null) {
      errorMessage = 'Generate a plan before exporting.';
      notifyListeners();
      return;
    }

    isExporting = true;
    errorMessage = null;
    message = 'Starting export...';
    logs = [];
    notifyListeners();

    try {
      await _longVideoService.exportPlan(
        currentPlan,
        outputSize: outputSize,
        fitMode: fitMode,
        onProgress: (value) async {
          logs = [...logs, value];
          message = value;
          notifyListeners();
        },
      );
    } catch (error) {
      errorMessage = error.toString();
      message = 'Export failed.';
    } finally {
      isExporting = false;
      notifyListeners();
    }
  }

  void clearPlan() {
    plan = null;
    logs = [];
    message = null;
    errorMessage = null;
    notifyListeners();
  }

  void _validateFolders() {
    if (videoFolderPath == null || videoFolderPath!.isEmpty) {
      throw const LongVideoValidationException('Select a video folder.');
    }
    if (audioFolderPath == null || audioFolderPath!.isEmpty) {
      throw const LongVideoValidationException('Select an audio folder.');
    }
    if (outputFolderPath == null || outputFolderPath!.isEmpty) {
      throw const LongVideoValidationException('Select an output folder.');
    }
  }

  String _format(double value) => value.toStringAsFixed(1);
}

class LongVideoValidationException implements Exception {
  const LongVideoValidationException(this.message);

  final String message;

  @override
  String toString() => message;
}
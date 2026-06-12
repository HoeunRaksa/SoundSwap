import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:path/path.dart' as p;
import 'package:soundswap/core/constants/app_constants.dart';
import 'package:soundswap/features/home/data/models/image_to_video_settings.dart';
import 'package:soundswap/features/home/data/models/media_file.dart';
import 'package:soundswap/features/home/data/services/media_scanner_service.dart';
import 'package:soundswap/features/long_video/data/models/long_video_plan.dart';
import 'package:soundswap/features/long_video/data/services/long_video_service.dart';
import 'package:soundswap/features/result_history/data/models/result_history_record.dart';
import 'package:soundswap/features/result_history/presentation/state/result_history_controller.dart';
import 'package:soundswap/shared/services/folder_picker_service.dart';
import 'package:soundswap/features/home/presentation/state/home_controller.dart';
import 'package:soundswap/features/templates/presentation/state/templates_controller.dart';
import 'package:soundswap/features/templates/data/models/project_template.dart';
import 'package:soundswap/features/branding/data/models/branding_settings.dart';
import 'package:soundswap/features/text_overlay/data/models/text_overlay_settings.dart';
import 'package:soundswap/features/overlay_tools/data/models/overlay_settings.dart';
import 'package:soundswap/features/overlay_tools/data/models/overlay_item.dart';

import '../../../../core/video/video_output_settings.dart';

class LongVideoController extends ChangeNotifier {
  LongVideoController({
    FolderPickerService? folderPickerService,
    MediaScannerService? mediaScannerService,
    LongVideoService? longVideoService,
    ResultHistoryController? resultHistoryController,
    HomeController? homeController,
    TemplatesController? templatesController,
  }) : _folderPickerService = folderPickerService ?? FolderPickerService(),
        _mediaScannerService = mediaScannerService ?? MediaScannerService(),
        _longVideoService = longVideoService ?? LongVideoService(),
        _resultHistoryController = resultHistoryController,
        _homeController = homeController,
        _templatesController = templatesController;

  final FolderPickerService _folderPickerService;
  final MediaScannerService _mediaScannerService;
  final LongVideoService _longVideoService;
  final ResultHistoryController? _resultHistoryController;
  final HomeController? _homeController;
  final TemplatesController? _templatesController;

  bool useOverlays = false;
  String selectedOverlayPreset = 'current_overlays';
  bool useTemplate = false;
  String? selectedTemplateId;

  List<String> videoFolders = [];
  List<String> audioFolders = [];
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

  int successCount = 0;
  int failedCount = 0;
  int currentExportIndex = 0;
  String currentClipLabel = '';

  bool useImages = false;
  List<String> imageFolders = [];
  ImageToVideoSettings imageSettings = const ImageToVideoSettings(
    durationValue: 5,
    durationUnit: ImageDurationUnit.seconds,
    fitMode: ImageFitMode.contain,
  );
  int numOutputs = 1;
  List<MediaFile> images = [];

  LongVideoDurationMode durationMode = LongVideoDurationMode.exactTargetLength;
  LongVideoAudioBehavior audioBehavior = LongVideoAudioBehavior.trimToFinalVideo;

  Future<void> pickVideoFolder() async {
    final path = await _folderPickerService.pickFolder(
      dialogTitle: 'Select video folder',
    );
    if (path == null) return;
    if (!videoFolders.contains(path)) videoFolders.add(path);
    plan = null;
    notifyListeners();
  }

  void removeVideoFolder(String path) {
    videoFolders.remove(path);
    plan = null;
    notifyListeners();
  }

  Future<void> pickAudioFolder() async {
    final path = await _folderPickerService.pickFolder(
      dialogTitle: 'Select audio folder',
    );
    if (path == null) return;
    if (!audioFolders.contains(path)) audioFolders.add(path);
    selectedAudioPath = null;
    plan = null;
    notifyListeners();
  }

  void removeAudioFolder(String path) {
    audioFolders.remove(path);
    if (selectedAudioPath != null && selectedAudioPath!.startsWith(path)) {
      selectedAudioPath = null;
    }
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
    if (outputName == value) return;
    outputName = value;
    plan = null;
    notifyListeners();
  }

  void setTargetMinutes(String value) {
    final parsed = double.tryParse(value) ?? targetMinutes;
    if (targetMinutes == parsed) return;
    targetMinutes = parsed;
    plan = null;
    notifyListeners();
  }

  void setClipSeconds(String value) {
    final parsed = double.tryParse(value) ?? clipSeconds;
    if (clipSeconds == parsed) return;
    clipSeconds = parsed;
    plan = null;
    notifyListeners();
  }

  void setAudioMode(LongVideoAudioMode value) {
    if (audioMode == value) return;
    audioMode = value;
    plan = null;
    notifyListeners();
  }

  void setSelectedAudio(String? value) {
    if (selectedAudioPath == value) return;
    selectedAudioPath = value;
    plan = null;
    notifyListeners();
  }

  void setOutputSize(VideoOutputSize value) {
    if (outputSize == value) return;
    outputSize = value;
    plan = null;
    notifyListeners();
  }

  void setFitMode(VideoFitMode value) {
    if (fitMode == value) return;
    fitMode = value;
    plan = null;
    notifyListeners();
  }

  void setNumOutputs(String value) {
    final parsed = int.tryParse(value) ?? 1;
    if (numOutputs == parsed) return;
    numOutputs = parsed;
    plan = null;
    notifyListeners();
  }

  void setUseImages(bool value) {
    if (useImages == value) return;
    useImages = value;
    plan = null;
    notifyListeners();
  }

  Future<void> pickImageFolder() async {
    final path = await _folderPickerService.pickFolder(
      dialogTitle: 'Select image folder',
    );
    if (path == null) return;
    if (!imageFolders.contains(path)) imageFolders.add(path);
    plan = null;
    notifyListeners();
  }

  void removeImageFolder(String path) {
    imageFolders.remove(path);
    plan = null;
    notifyListeners();
  }

  void setImageDurationValue(String value) {
    final val = int.tryParse(value);
    if (val != null) {
      if (imageSettings.durationValue == val) return;
      imageSettings = imageSettings.copyWith(durationValue: val);
      plan = null;
      notifyListeners();
    }
  }

  void setImageDurationUnit(ImageDurationUnit value) {
    if (imageSettings.durationUnit == value) return;
    imageSettings = imageSettings.copyWith(durationUnit: value);
    plan = null;
    notifyListeners();
  }

  void setImageFitMode(ImageFitMode value) {
    if (imageSettings.fitMode == value) return;
    imageSettings = imageSettings.copyWith(fitMode: value);
    plan = null;
    notifyListeners();
  }

  void setDurationMode(LongVideoDurationMode value) {
    if (durationMode == value) return;
    durationMode = value;
    plan = null;
    notifyListeners();
  }

  void setAudioBehavior(LongVideoAudioBehavior value) {
    if (audioBehavior == value) return;
    audioBehavior = value;
    plan = null;
    notifyListeners();
  }

  void setUseOverlays(bool value) {
    if (useOverlays == value) return;
    useOverlays = value;
    plan = null;
    notifyListeners();
  }

  void setSelectedOverlayPreset(String value) {
    if (selectedOverlayPreset == value) return;
    selectedOverlayPreset = value;
    plan = null;
    notifyListeners();
  }

  void setUseTemplate(bool value) {
    if (useTemplate == value) return;
    useTemplate = value;
    plan = null;
    notifyListeners();
  }

  void setSelectedTemplateId(String? value) {
    if (selectedTemplateId == value) return;
    selectedTemplateId = value;
    plan = null;
    notifyListeners();
  }

  List<ProjectTemplate> get templates => _templatesController?.templates ?? [];

  ProjectTemplate? get selectedTemplate =>
      selectedTemplateId == null
          ? null
          : templates.firstWhere((t) => t.id == selectedTemplateId, orElse: () => templates.first);

  String? validateTemplateOrOverlay() {
    if (useTemplate) {
      final t = selectedTemplate;
      if (t == null) {
        return 'No template selected.';
      }
      if (t.useBranding && t.branding.hasLogo && t.branding.logoPath != null) {
        final f = File(t.branding.logoPath!);
        if (!f.existsSync()) {
          return 'Template branding logo file does not exist: ${p.basename(t.branding.logoPath!)}';
        }
      }
      if (t.useOverlay) {
        for (final item in t.overlaySettings.items) {
          if (item.type == OverlayItemType.image && item.imagePath != null) {
            final f = File(item.imagePath!);
            if (!f.existsSync()) {
              return 'Template overlay image file does not exist: ${p.basename(item.imagePath!)}';
            }
          }
          if (item.type == OverlayItemType.text && item.fontPath != null && item.fontPath!.isNotEmpty) {
            final f = File(item.fontPath!);
            if (!f.existsSync()) {
              return 'Template font file does not exist: ${p.basename(item.fontPath!)}';
            }
          }
        }
        if (t.overlaySettings.defaultFontPath != null && t.overlaySettings.defaultFontPath!.isNotEmpty) {
          final f = File(t.overlaySettings.defaultFontPath!);
          if (!f.existsSync()) {
            return 'Template default font file does not exist: ${p.basename(t.overlaySettings.defaultFontPath!)}';
          }
        }
      }
    } else if (useOverlays) {
      final home = _homeController;
      if (home == null) return null;
      if (home.useBranding && home.activeBrandingSettings?.hasLogo == true && home.activeBrandingSettings?.logoPath != null) {
        final f = File(home.activeBrandingSettings!.logoPath!);
        if (!f.existsSync()) {
          return 'Current branding logo file does not exist: ${p.basename(home.activeBrandingSettings!.logoPath!)}';
        }
      }
      if (home.useOverlay && home.activeOverlaySettings != null) {
        for (final item in home.activeOverlaySettings!.items) {
          if (item.type == OverlayItemType.image && item.imagePath != null) {
            final f = File(item.imagePath!);
            if (!f.existsSync()) {
              return 'Current overlay image file does not exist: ${p.basename(item.imagePath!)}';
            }
          }
          if (item.type == OverlayItemType.text && item.fontPath != null && item.fontPath!.isNotEmpty) {
            final f = File(item.fontPath!);
            if (!f.existsSync()) {
              return 'Current font file does not exist: ${p.basename(item.fontPath!)}';
            }
          }
        }
        if (home.activeOverlaySettings!.defaultFontPath != null && home.activeOverlaySettings!.defaultFontPath!.isNotEmpty) {
          final f = File(home.activeOverlaySettings!.defaultFontPath!);
          if (!f.existsSync()) {
            return 'Current default font file does not exist: ${p.basename(home.activeOverlaySettings!.defaultFontPath!)}';
          }
        }
      }
    }
    return null;
  }

  BrandingSettings? getActiveBranding() {
    if (useTemplate && selectedTemplate != null) {
      return selectedTemplate!.useBranding ? selectedTemplate!.branding : null;
    }
    if (useOverlays) {
      return _homeController?.useBranding == true ? _homeController?.activeBrandingSettings : null;
    }
    return null;
  }

  TextOverlaySettings? getActiveTextOverlay() {
    if (useTemplate && selectedTemplate != null) {
      return selectedTemplate!.useTextOverlay ? selectedTemplate!.textOverlay : null;
    }
    if (useOverlays) {
      return _homeController?.useTextOverlay == true ? _homeController?.activeTextOverlaySettings : null;
    }
    return null;
  }

  OverlaySettings? getActiveOverlaySettings() {
    if (useTemplate && selectedTemplate != null) {
      return selectedTemplate!.useOverlay ? selectedTemplate!.overlaySettings : null;
    }
    if (useOverlays) {
      return _homeController?.useOverlay == true ? _homeController?.activeOverlaySettings : null;
    }
    return null;
  }

  Future<void> generatePlan() async {
    isPlanning = true;
    errorMessage = null;
    message = 'Generating plan...';
    logs = [];
    notifyListeners();

    try {
      _validateFolders();
      
      final scanStats = ScanStats();
      final totalFolders = videoFolders.length + audioFolders.length + (useImages ? imageFolders.length : 0);
      debugPrint('feature name: Long Video');
      debugPrint('selected folders count: $totalFolders');
      debugPrint('recursive scan enabled: true');
      
      if (videoFolders.isNotEmpty) {
        videos = [];
        final deduplicated = <String>{};
        for (final folder in videoFolders) {
          debugPrint('folder path: $folder');
          final normalized = p.normalize(folder);
          if (deduplicated.contains(normalized)) continue;
          deduplicated.add(normalized);
          final exists = Directory(normalized).existsSync();
          debugPrint('folder exists: $exists');
          if (!exists) continue;
          final batch = await _mediaScannerService.scanFolder(
            folderPath: normalized,
            extensions: AppConstants.supportedVideoExtensions,
            stats: scanStats,
          );
          videos.addAll(batch);
        }
      } else {
        videos = [];
      }

      if (useImages && imageFolders.isNotEmpty) {
        images = [];
        final deduplicated = <String>{};
        for (final folder in imageFolders) {
          debugPrint('folder path: $folder');
          final normalized = p.normalize(folder);
          if (deduplicated.contains(normalized)) continue;
          deduplicated.add(normalized);
          final exists = Directory(normalized).existsSync();
          debugPrint('folder exists: $exists');
          if (!exists) continue;
          final batch = await _mediaScannerService.scanFolder(
            folderPath: normalized,
            extensions: AppConstants.supportedImageExtensions,
            stats: scanStats,
          );
          images.addAll(batch);
        }
      } else {
        images = [];
      }

      audios = [];
      if (audioFolders.isNotEmpty) {
        final deduplicated = <String>{};
        for (final folder in audioFolders) {
          debugPrint('folder path: $folder');
          final normalized = p.normalize(folder);
          if (deduplicated.contains(normalized)) continue;
          deduplicated.add(normalized);
          final exists = Directory(normalized).existsSync();
          debugPrint('folder exists: $exists');
          if (!exists) continue;
          final batch = await _mediaScannerService.scanFolder(
            folderPath: normalized,
            extensions: AppConstants.supportedAudioExtensions,
            stats: scanStats,
          );
          audios.addAll(batch);
        }
      }
      selectedAudioPath ??= audios.isEmpty ? null : audios.first.path;

      plan = await _longVideoService.createPlan(
        videos: videos,
        images: useImages ? images : [],
        audios: audios,
        outputFolderPath: outputFolderPath!,
        outputName: outputName,
        targetMinutes: targetMinutes,
        clipSeconds: clipSeconds,
        audioMode: audioMode,
        imageSettings: imageSettings,
        selectedAudioPath: selectedAudioPath,
        durationMode: durationMode,
        audioBehavior: audioBehavior,
      );
      final currentPlan = plan!;
      final targetSec = targetMinutes * 60;
      final diff = (currentPlan.estimatedDuration - targetSec).abs();
      if (diff > 0.5 && durationMode == LongVideoDurationMode.exactTargetLength) {
        message = 'Plan ready (⚠ ${diff.toStringAsFixed(1)}s mismatch): ${currentPlan.clips.length} clips, ${_format(currentPlan.estimatedDuration)}s.';
      } else {
        message = 'Plan ready: ${currentPlan.clips.length} clips, ${_format(currentPlan.estimatedDuration)}s.';
      }

      debugPrint('total files discovered: ${scanStats.totalFilesDiscovered}');
      debugPrint('supported media discovered: ${scanStats.supportedMediaDiscovered}');
      debugPrint('skipped unsupported count: ${scanStats.skippedUnsupportedCount}');
      debugPrint('skipped destination-folder count: ${scanStats.skippedDestinationFolderCount}');
      debugPrint('final queue/source count: ${videos.length}');
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

    final validationError = validateTemplateOrOverlay();
    if (validationError != null) {
      errorMessage = 'Validation Failed: $validationError';
      isExporting = false;
      notifyListeners();
      return;
    }

    isExporting = true;
    errorMessage = null;
    message = 'Starting export...';
    logs = [];
    successCount = 0;
    failedCount = 0;
    currentExportIndex = 0;
    currentClipLabel = '';
    notifyListeners();

    try {
      final total = numOutputs;
      for (var k = 1; k <= total; k++) {
        if (!isExporting) break;

        currentExportIndex = k;
        final isOverlayOrTemplateEnabled = useOverlays || useTemplate;
        final modeText = isOverlayOrTemplateEnabled
            ? 'Re-encode Mode'
            : 'Fast Copy Mode';
        
        message = 'Exporting video $k of $total ($modeText)...';
        notifyListeners();

        final currentOutputName = total > 1
            ? '${p.basenameWithoutExtension(outputName.trim().isEmpty ? 'long-video' : outputName.trim())}-$k'
            : outputName;

        LongVideoPlan? loopPlan;
        try {
          loopPlan = await _longVideoService.createPlan(
            videos: videos,
            images: useImages ? images : [],
            audios: audios,
            outputFolderPath: outputFolderPath!,
            outputName: currentOutputName,
            targetMinutes: targetMinutes,
            clipSeconds: clipSeconds,
            audioMode: audioMode,
            imageSettings: imageSettings,
            selectedAudioPath: selectedAudioPath,
            durationMode: durationMode,
            audioBehavior: audioBehavior,
          );

          await _longVideoService.exportPlan(
            loopPlan,
            imageSettings: imageSettings,
            outputSize: outputSize,
            fitMode: fitMode,
            branding: getActiveBranding(),
            textOverlay: getActiveTextOverlay(),
            overlaySettings: getActiveOverlaySettings(),
            onProgress: (value) async {
              final progressMsg = '[Video $k/$total] Stage: $value | Mode: $modeText';
              logs = [...logs, progressMsg];
              message = progressMsg;
              currentClipLabel = '$value ($modeText)';
              notifyListeners();
            },
          );
          successCount++;

          final record = ResultHistoryRecord(
            id: DateTime.now().microsecondsSinceEpoch.toString(),
            originalVideoPath: loopPlan.clips.isNotEmpty ? loopPlan.clips.first.videoPath : '',
            audioPath: loopPlan.audioSegments.isNotEmpty ? loopPlan.audioSegments.first.audioPath : '',
            outputPath: loopPlan.outputPath,
            resultFolderPath: outputFolderPath!,
            status: ResultHistoryStatus.success,
            createdAt: DateTime.now(),
            processType: ResultProcessType.longVideo,
            outputPrefix: currentOutputName,
            totalVideos: loopPlan.clips.length,
          );
          await _resultHistoryController?.add(record);
        } catch (error) {
          failedCount++;
          final record = ResultHistoryRecord(
            id: DateTime.now().microsecondsSinceEpoch.toString(),
            originalVideoPath: loopPlan?.clips.isNotEmpty == true ? loopPlan!.clips.first.videoPath : '',
            audioPath: loopPlan?.audioSegments.isNotEmpty == true ? loopPlan!.audioSegments.first.audioPath : '',
            outputPath: loopPlan?.outputPath ?? p.join(outputFolderPath!, '$currentOutputName.mp4'),
            resultFolderPath: outputFolderPath!,
            status: ResultHistoryStatus.failed,
            createdAt: DateTime.now(),
            processType: ResultProcessType.longVideo,
            outputPrefix: currentOutputName,
            totalVideos: loopPlan?.clips.length ?? 0,
            errorMessage: error.toString(),
          );
          await _resultHistoryController?.add(record);
          // Continue to next output instead of rethrowing for multi-output batches
          logs = [...logs, '[Video $k/$total] FAILED: $error'];
          message = '[Video $k/$total] Failed — continuing...';
          notifyListeners();
        }
      }
      if (failedCount == 0) {
        message = 'All $total export${total > 1 ? 's' : ''} completed! ✓ $successCount succeeded.';
      } else {
        message = 'Completed: ✓ $successCount succeeded, ✗ $failedCount failed.';
        if (failedCount == total) errorMessage = 'All exports failed. Check logs.';
      }
    } catch (error) {
      errorMessage = error.toString();
      message = 'Export failed.';
    } finally {
      isExporting = false;
      notifyListeners();
    }
  }

  void stopExport() {
    isExporting = false;
    notifyListeners();
  }

  void clearPlan() {
    plan = null;
    logs = [];
    message = null;
    errorMessage = null;
    successCount = 0;
    failedCount = 0;
    currentExportIndex = 0;
    currentClipLabel = '';
    notifyListeners();
  }

  /// Whether a plan exists and has no critical mismatch for exact mode.
  bool get canExport {
    if (plan == null) return false;
    if (isExporting || isPlanning) return false;
    return true;
  }

  /// A human-readable summary of the current plan for pre-export review.
  LongVideoPlanSummary? get planSummary {
    final currentPlan = plan;
    if (currentPlan == null) return null;
    final targetSec = targetMinutes * 60;
    final videoDuration = currentPlan.clips.fold(0.0, (sum, c) => sum + c.clipDuration);
    final audioDuration = currentPlan.audioSegments.fold(0.0, (sum, s) => sum + s.segmentDuration);
    final imageClips = currentPlan.clips.where((c) => MediaFile(path: c.videoPath).isImage).length;
    final videoClips = currentPlan.clips.length - imageClips;
    final diff = (currentPlan.estimatedDuration - targetSec).abs();
    final hasMismatch = durationMode == LongVideoDurationMode.exactTargetLength && diff > 0.5;
    return LongVideoPlanSummary(
      targetDuration: targetSec,
      plannedVideoDuration: videoDuration,
      plannedAudioDuration: audioDuration,
      estimatedFinalDuration: currentPlan.estimatedDuration,
      numVideoClips: videoClips,
      numImageClips: imageClips,
      hasMismatch: hasMismatch,
      mismatchSeconds: diff,
    );
  }

  void _validateFolders() {
    if (useImages) {
      final hasVideos = videoFolders.isNotEmpty;
      final hasImages = imageFolders.isNotEmpty;
      if (!hasVideos && !hasImages) {
        throw const LongVideoValidationException(
          'Select either a video folder or an image folder (or both) when images are enabled.',
        );
      }
    } else {
      if (videoFolders.isEmpty) {
        throw const LongVideoValidationException('Select a video folder.');
      }
    }
    if (audioFolders.isEmpty) {
      throw const LongVideoValidationException('Select an audio folder.');
    }
    if (outputFolderPath == null || outputFolderPath!.isEmpty) {
      throw const LongVideoValidationException('Select an output folder.');
    }
  }

  String _format(double value) => value.toStringAsFixed(1);

  String _fmtDuration(double seconds) {
    final m = (seconds ~/ 60).toString().padLeft(2, '0');
    final s = (seconds % 60).toStringAsFixed(0).padLeft(2, '0');
    return '$m:$s';
  }

  // ignore: unused_element
  String get _targetLabel => _fmtDuration(targetMinutes * 60);
}

class LongVideoValidationException implements Exception {
  const LongVideoValidationException(this.message);

  final String message;

  @override
  String toString() => message;
}

class LongVideoPlanSummary {
  const LongVideoPlanSummary({
    required this.targetDuration,
    required this.plannedVideoDuration,
    required this.plannedAudioDuration,
    required this.estimatedFinalDuration,
    required this.numVideoClips,
    required this.numImageClips,
    required this.hasMismatch,
    required this.mismatchSeconds,
  });

  final double targetDuration;
  final double plannedVideoDuration;
  final double plannedAudioDuration;
  final double estimatedFinalDuration;
  final int numVideoClips;
  final int numImageClips;
  final bool hasMismatch;
  final double mismatchSeconds;

  String _fmt(double s) {
    final m = (s ~/ 60).toString().padLeft(2, '0');
    final sec = (s % 60).toStringAsFixed(0).padLeft(2, '0');
    return '$m:$sec';
  }

  String get targetLabel => _fmt(targetDuration);
  String get plannedVideoLabel => _fmt(plannedVideoDuration);
  String get plannedAudioLabel => _fmt(plannedAudioDuration);
  String get estimatedLabel => _fmt(estimatedFinalDuration);
  int get totalClips => numVideoClips + numImageClips;
}
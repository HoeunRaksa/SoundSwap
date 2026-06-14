import 'package:soundswap/core/video/video_output_settings.dart';
import 'package:soundswap/features/home/data/models/audio_settings.dart';
import 'package:soundswap/features/home/data/models/image_to_video_settings.dart';
import 'package:soundswap/features/long_video/data/models/long_video_plan.dart';

class LongVideoSettings {
  const LongVideoSettings({
    this.useOverlay = false,
    this.useTemplate = false,
    this.selectedTemplateId,
    this.selectedTemplateIds = const [],
    this.outputSize = VideoOutputSize.original,
    this.fitMode = VideoFitMode.fillCrop,
    this.audioMode = LongVideoAudioMode.randomFromFolder,
    this.audioSettings = const AudioSettings(),
    this.selectedAudioPath,
    this.audioBehavior = LongVideoAudioBehavior.trimToFinalVideo,
    this.targetMinutes = 10,
    this.clipSeconds = 5,
    this.useImages = false,
    this.numOutputs = 1,
    this.imageSettings = const ImageToVideoSettings(
      durationValue: 5,
      durationUnit: ImageDurationUnit.seconds,
      fitMode: ImageFitMode.contain,
    ),
    this.durationMode = LongVideoDurationMode.exactTargetLength,
  });

  final bool useOverlay;
  final bool useTemplate;
  final String? selectedTemplateId;
  final List<String> selectedTemplateIds;
  final VideoOutputSize outputSize;
  final VideoFitMode fitMode;
  final LongVideoAudioMode audioMode;
  final AudioSettings audioSettings;
  final String? selectedAudioPath;
  final LongVideoAudioBehavior audioBehavior;
  final double targetMinutes;
  final double clipSeconds;
  final bool useImages;
  final int numOutputs;
  final ImageToVideoSettings imageSettings;
  final LongVideoDurationMode durationMode;

  Map<String, Object?> toJson() => {
        'useOverlay': useOverlay,
        'useTemplate': useTemplate,
        'selectedTemplateId': selectedTemplateId,
        'selectedTemplateIds': selectedTemplateIds,
        'outputSize': outputSize.name,
        'fitMode': fitMode.name,
        'audioMode': audioMode.name,
        'audioSettings': audioSettings.toJson(),
        'selectedAudioPath': selectedAudioPath,
        'audioBehavior': audioBehavior.name,
        'targetMinutes': targetMinutes,
        'clipSeconds': clipSeconds,
        'useImages': useImages,
        'numOutputs': numOutputs,
        'imageSettings': imageSettings.toJson(),
        'durationMode': durationMode.name,
      };

  factory LongVideoSettings.fromJson(Map<String, Object?> json) {
    return LongVideoSettings(
      useOverlay: json['useOverlay'] as bool? ?? false,
      useTemplate: json['useTemplate'] as bool? ?? false,
      selectedTemplateId: json['selectedTemplateId'] as String?,
      selectedTemplateIds: (json['selectedTemplateIds'] as List<dynamic>?)?.map((e) => e as String).toList() ?? const [],
      outputSize: VideoOutputSize.values.firstWhere(
        (e) => e.name == json['outputSize'],
        orElse: () => VideoOutputSize.original,
      ),
      fitMode: VideoFitMode.values.firstWhere(
        (e) => e.name == json['fitMode'],
        orElse: () => VideoFitMode.fillCrop,
      ),
      audioMode: LongVideoAudioMode.values.firstWhere(
        (e) => e.name == json['audioMode'],
        orElse: () => LongVideoAudioMode.randomFromFolder,
      ),
      audioSettings: json['audioSettings'] != null
          ? AudioSettings.fromJson(json['audioSettings'] as Map<String, Object?>)
          : const AudioSettings(),
      selectedAudioPath: json['selectedAudioPath'] as String?,
      audioBehavior: LongVideoAudioBehavior.values.firstWhere(
        (e) => e.name == json['audioBehavior'],
        orElse: () => LongVideoAudioBehavior.trimToFinalVideo,
      ),
      targetMinutes: (json['targetMinutes'] as num?)?.toDouble() ?? 10,
      clipSeconds: (json['clipSeconds'] as num?)?.toDouble() ?? 5,
      useImages: json['useImages'] as bool? ?? false,
      numOutputs: (json['numOutputs'] as num?)?.toInt() ?? 1,
      imageSettings: json['imageSettings'] != null
          ? ImageToVideoSettings.fromJson(json['imageSettings'] as Map<String, Object?>)
          : const ImageToVideoSettings(
              durationValue: 5,
              durationUnit: ImageDurationUnit.seconds,
              fitMode: ImageFitMode.contain,
            ),
      durationMode: LongVideoDurationMode.values.firstWhere(
        (e) => e.name == json['durationMode'],
        orElse: () => LongVideoDurationMode.exactTargetLength,
      ),
    );
  }

  LongVideoSettings copyWith({
    bool? useOverlay,
    bool? useTemplate,
    String? selectedTemplateId,
    List<String>? selectedTemplateIds,
    VideoOutputSize? outputSize,
    VideoFitMode? fitMode,
    LongVideoAudioMode? audioMode,
    AudioSettings? audioSettings,
    String? selectedAudioPath,
    LongVideoAudioBehavior? audioBehavior,
    double? targetMinutes,
    double? clipSeconds,
    bool? useImages,
    int? numOutputs,
    ImageToVideoSettings? imageSettings,
    LongVideoDurationMode? durationMode,
  }) {
    return LongVideoSettings(
      useOverlay: useOverlay ?? this.useOverlay,
      useTemplate: useTemplate ?? this.useTemplate,
      selectedTemplateId: selectedTemplateId ?? this.selectedTemplateId,
      selectedTemplateIds: selectedTemplateIds ?? this.selectedTemplateIds,
      outputSize: outputSize ?? this.outputSize,
      fitMode: fitMode ?? this.fitMode,
      audioMode: audioMode ?? this.audioMode,
      audioSettings: audioSettings ?? this.audioSettings,
      selectedAudioPath: selectedAudioPath ?? this.selectedAudioPath,
      audioBehavior: audioBehavior ?? this.audioBehavior,
      targetMinutes: targetMinutes ?? this.targetMinutes,
      clipSeconds: clipSeconds ?? this.clipSeconds,
      useImages: useImages ?? this.useImages,
      numOutputs: numOutputs ?? this.numOutputs,
      imageSettings: imageSettings ?? this.imageSettings,
      durationMode: durationMode ?? this.durationMode,
    );
  }
}

import 'package:soundswap/core/video/video_output_settings.dart';
import 'package:soundswap/features/overlay_tools/data/models/overlay_settings.dart';

class BatchProfile {
  const BatchProfile({
    required this.id,
    required this.name,
    required this.createdAt,
    required this.updatedAt,
    this.videoFolderPath,
    this.audioFolderPath,
    this.outputFolderPath,
    this.outputPrefix = '',
    this.useOverlay = false,
    this.selectedOverlayPresetId,
    this.overlaySettings = const OverlaySettings(),
    this.useTemplate = false,
    this.selectedTemplateId,
    this.outputSize = VideoOutputSize.original,
    this.fitMode = VideoFitMode.keepOriginal,
  });

  final String id;
  final String name;
  final DateTime createdAt;
  final DateTime updatedAt;
  final String? videoFolderPath;
  final String? audioFolderPath;
  final String? outputFolderPath;
  final String outputPrefix;
  final bool useOverlay;
  final String? selectedOverlayPresetId;
  final OverlaySettings overlaySettings;
  final bool useTemplate;
  final String? selectedTemplateId;
  final VideoOutputSize outputSize;
  final VideoFitMode fitMode;

  Map<String, Object?> toJson() => {
    'id': id,
    'name': name,
    'createdAt': createdAt.toIso8601String(),
    'updatedAt': updatedAt.toIso8601String(),
    'videoFolderPath': videoFolderPath,
    'audioFolderPath': audioFolderPath,
    'outputFolderPath': outputFolderPath,
    'outputPrefix': outputPrefix,
    'useOverlay': useOverlay,
    'selectedOverlayPresetId': selectedOverlayPresetId,
    'overlaySettings': overlaySettings.toJson(),
    'useTemplate': useTemplate,
    'selectedTemplateId': selectedTemplateId,
    'outputSize': outputSize.name,
    'fitMode': fitMode.name,
  };

  factory BatchProfile.fromJson(Map<String, Object?> json) {
    return BatchProfile(
      id: json['id'] as String? ?? '',
      name: json['name'] as String? ?? 'Batch profile',
      createdAt:
          DateTime.tryParse(json['createdAt'] as String? ?? '') ??
          DateTime.now(),
      updatedAt:
          DateTime.tryParse(json['updatedAt'] as String? ?? '') ??
          DateTime.now(),
      videoFolderPath: json['videoFolderPath'] as String?,
      audioFolderPath: json['audioFolderPath'] as String?,
      outputFolderPath: json['outputFolderPath'] as String?,
      outputPrefix: json['outputPrefix'] as String? ?? '',
      useOverlay: json['useOverlay'] as bool? ?? false,
      selectedOverlayPresetId: json['selectedOverlayPresetId'] as String?,
      overlaySettings: OverlaySettings.fromJson(
        (json['overlaySettings'] as Map?)?.cast<String, Object?>() ?? {},
      ),
      useTemplate: json['useTemplate'] as bool? ?? false,
      selectedTemplateId: json['selectedTemplateId'] as String?,
      outputSize: VideoOutputSize.values.firstWhere(
        (value) => value.name == json['outputSize'],
        orElse: () => VideoOutputSize.original,
      ),
      fitMode: VideoFitMode.values.firstWhere(
        (value) => value.name == json['fitMode'],
        orElse: () => VideoFitMode.keepOriginal,
      ),
    );
  }

  BatchProfile copyWith({
    String? name,
    DateTime? updatedAt,
    String? videoFolderPath,
    String? audioFolderPath,
    String? outputFolderPath,
    String? outputPrefix,
    bool? useOverlay,
    String? selectedOverlayPresetId,
    OverlaySettings? overlaySettings,
    bool? useTemplate,
    String? selectedTemplateId,
    VideoOutputSize? outputSize,
    VideoFitMode? fitMode,
    bool clearSelectedOverlayPreset = false,
    bool clearSelectedTemplate = false,
  }) {
    return BatchProfile(
      id: id,
      name: name ?? this.name,
      createdAt: createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      videoFolderPath: videoFolderPath ?? this.videoFolderPath,
      audioFolderPath: audioFolderPath ?? this.audioFolderPath,
      outputFolderPath: outputFolderPath ?? this.outputFolderPath,
      outputPrefix: outputPrefix ?? this.outputPrefix,
      useOverlay: useOverlay ?? this.useOverlay,
      selectedOverlayPresetId: clearSelectedOverlayPreset
          ? null
          : selectedOverlayPresetId ?? this.selectedOverlayPresetId,
      overlaySettings: overlaySettings ?? this.overlaySettings,
      useTemplate: useTemplate ?? this.useTemplate,
      selectedTemplateId: clearSelectedTemplate
          ? null
          : selectedTemplateId ?? this.selectedTemplateId,
      outputSize: outputSize ?? this.outputSize,
      fitMode: fitMode ?? this.fitMode,
    );
  }
}

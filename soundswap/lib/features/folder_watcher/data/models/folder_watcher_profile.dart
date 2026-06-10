import 'package:soundswap/core/video/video_output_settings.dart';
import 'package:soundswap/features/overlay_tools/data/models/overlay_settings.dart';

class FolderWatcherProfile {
  const FolderWatcherProfile({
    required this.id,
    required this.name,
    this.videoFolderPath,
    this.audioFolderPath,
    this.resultFolderPath,
    this.outputPrefix = '',
    this.templateId,
    this.useOverlay = false,
    this.overlaySettings = const OverlaySettings(),
    this.outputSize = VideoOutputSize.original,
    this.fitMode = VideoFitMode.keepOriginal,
  });

  final String id;
  final String name;
  final String? videoFolderPath;
  final String? audioFolderPath;
  final String? resultFolderPath;
  final String outputPrefix;
  final String? templateId;
  final bool useOverlay;
  final OverlaySettings overlaySettings;
  final VideoOutputSize outputSize;
  final VideoFitMode fitMode;

  bool get hasRequiredFolders =>
      videoFolderPath != null &&
      audioFolderPath != null &&
      resultFolderPath != null;

  Map<String, Object?> toJson() => {
    'id': id,
    'name': name,
    'videoFolderPath': videoFolderPath,
    'audioFolderPath': audioFolderPath,
    'resultFolderPath': resultFolderPath,
    'outputPrefix': outputPrefix,
    'templateId': templateId,
    'useOverlay': useOverlay,
    'overlaySettings': overlaySettings.toJson(),
    'outputSize': outputSize.name,
    'fitMode': fitMode.name,
  };

  factory FolderWatcherProfile.fromJson(Map<String, Object?> json) {
    return FolderWatcherProfile(
      id: json['id'] as String? ?? '',
      name: json['name'] as String? ?? 'Watcher profile',
      videoFolderPath: json['videoFolderPath'] as String?,
      audioFolderPath: json['audioFolderPath'] as String?,
      resultFolderPath: json['resultFolderPath'] as String?,
      outputPrefix: json['outputPrefix'] as String? ?? '',
      templateId: json['templateId'] as String?,
      useOverlay: json['useOverlay'] as bool? ?? false,
      overlaySettings: OverlaySettings.fromJson(
        (json['overlaySettings'] as Map?)?.cast<String, Object?>() ?? {},
      ),
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

  FolderWatcherProfile copyWith({
    String? name,
    String? videoFolderPath,
    String? audioFolderPath,
    String? resultFolderPath,
    String? outputPrefix,
    String? templateId,
    bool? useOverlay,
    OverlaySettings? overlaySettings,
    VideoOutputSize? outputSize,
    VideoFitMode? fitMode,
  }) {
    return FolderWatcherProfile(
      id: id,
      name: name ?? this.name,
      videoFolderPath: videoFolderPath ?? this.videoFolderPath,
      audioFolderPath: audioFolderPath ?? this.audioFolderPath,
      resultFolderPath: resultFolderPath ?? this.resultFolderPath,
      outputPrefix: outputPrefix ?? this.outputPrefix,
      templateId: templateId ?? this.templateId,
      useOverlay: useOverlay ?? this.useOverlay,
      overlaySettings: overlaySettings ?? this.overlaySettings,
      outputSize: outputSize ?? this.outputSize,
      fitMode: fitMode ?? this.fitMode,
    );
  }
}

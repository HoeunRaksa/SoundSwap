import 'package:soundswap/core/video/video_output_settings.dart';
import 'package:soundswap/features/overlay_tools/data/models/overlay_settings.dart';

class FolderWatcherProfile {
  const FolderWatcherProfile({
    required this.id,
    required this.name,
    this.videoFolders = const [],
    this.audioFolders = const [],
    this.resultFolderPath,
    this.outputPrefix = '',
    this.templateId,
    this.useOverlay = false,
    this.overlaySettings = const OverlaySettings(),
    this.outputSize = VideoOutputSize.original,
    this.fitMode = VideoFitMode.keepOriginal,
    this.isActive = false,
  });

  final String id;
  final String name;
  final List<String> videoFolders;
  final List<String> audioFolders;
  final String? resultFolderPath;
  final String outputPrefix;
  final String? templateId;
  final bool useOverlay;
  final OverlaySettings overlaySettings;
  final VideoOutputSize outputSize;
  final VideoFitMode fitMode;
  final bool isActive;

  bool get hasRequiredFolders =>
      videoFolders.isNotEmpty &&
      audioFolders.isNotEmpty &&
      resultFolderPath != null;

  Map<String, Object?> toJson() => {
    'id': id,
    'name': name,
    'videoFolders': videoFolders,
    'audioFolders': audioFolders,
    'resultFolderPath': resultFolderPath,
    'outputPrefix': outputPrefix,
    'templateId': templateId,
    'useOverlay': useOverlay,
    'overlaySettings': overlaySettings.toJson(),
    'outputSize': outputSize.name,
    'fitMode': fitMode.name,
    'isActive': isActive,
  };

  factory FolderWatcherProfile.fromJson(Map<String, Object?> json) {
    return FolderWatcherProfile(
      id: json['id'] as String? ?? '',
      name: json['name'] as String? ?? 'Watcher profile',
      videoFolders: (json['videoFolders'] as List?)?.cast<String>() ?? (json['videoFolderPath'] != null ? [json['videoFolderPath'] as String] : []),
      audioFolders: (json['audioFolders'] as List?)?.cast<String>() ?? (json['audioFolderPath'] != null ? [json['audioFolderPath'] as String] : []),
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
      isActive: json['isActive'] as bool? ?? false,
    );
  }

  FolderWatcherProfile copyWith({
    String? name,
    List<String>? videoFolders,
    List<String>? audioFolders,
    String? resultFolderPath,
    String? outputPrefix,
    String? templateId,
    bool? useOverlay,
    OverlaySettings? overlaySettings,
    VideoOutputSize? outputSize,
    VideoFitMode? fitMode,
    bool? isActive,
  }) {
    return FolderWatcherProfile(
      id: id,
      name: name ?? this.name,
      videoFolders: videoFolders ?? this.videoFolders,
      audioFolders: audioFolders ?? this.audioFolders,
      resultFolderPath: resultFolderPath ?? this.resultFolderPath,
      outputPrefix: outputPrefix ?? this.outputPrefix,
      templateId: templateId ?? this.templateId,
      useOverlay: useOverlay ?? this.useOverlay,
      overlaySettings: overlaySettings ?? this.overlaySettings,
      outputSize: outputSize ?? this.outputSize,
      fitMode: fitMode ?? this.fitMode,
      isActive: isActive ?? this.isActive,
    );
  }
}

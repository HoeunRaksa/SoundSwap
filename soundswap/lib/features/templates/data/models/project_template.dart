import 'package:soundswap/core/video/video_output_settings.dart';
import 'package:soundswap/features/branding/data/models/branding_settings.dart';
import 'package:soundswap/features/overlay_tools/data/models/overlay_settings.dart';
import 'package:soundswap/features/text_overlay/data/models/text_overlay_settings.dart';

class ProjectTemplate {
  const ProjectTemplate({
    required this.id,
    required this.name,
    required this.createdAt,
    this.videoFolders = const [],
    this.audioFolders = const [],
    this.outputFolder,
    this.outputPrefix = '',
    this.branding = const BrandingSettings(),
    this.textOverlay = const TextOverlaySettings(),
    this.overlaySettings = const OverlaySettings(),
    this.useBranding = false,
    this.useTextOverlay = false,
    this.useOverlay = false,
    this.outputSize = VideoOutputSize.original,
    this.fitMode = VideoFitMode.keepOriginal,
    this.thumbnailPath,
    this.version = 1,
  });

  final String id;
  final String name;
  final DateTime createdAt;
  final List<String> videoFolders;
  final List<String> audioFolders;
  final String? outputFolder;
  final String outputPrefix;
  final BrandingSettings branding;
  final TextOverlaySettings textOverlay;
  final OverlaySettings overlaySettings;
  final bool useBranding;
  final bool useTextOverlay;
  final bool useOverlay;
  final VideoOutputSize outputSize;
  final VideoFitMode fitMode;
  final String? thumbnailPath;
  final int version;

  Map<String, Object?> toJson() => {
    'id': id,
    'name': name,
    'createdAt': createdAt.toIso8601String(),
    'videoFolders': videoFolders,
    'audioFolders': audioFolders,
    'outputFolder': outputFolder,
    'outputPrefix': outputPrefix,
    'branding': branding.toJson(),
    'textOverlay': textOverlay.toJson(),
    'overlaySettings': overlaySettings.toJson(),
    'useBranding': useBranding,
    'useTextOverlay': useTextOverlay,
    'useOverlay': useOverlay,
    'outputSize': outputSize.name,
    'fitMode': fitMode.name,
    'thumbnailPath': thumbnailPath,
    'version': version,
  };

  factory ProjectTemplate.fromJson(Map<String, Object?> json) {
    return ProjectTemplate(
      id: json['id'] as String? ?? '',
      name: json['name'] as String? ?? 'Untitled',
      createdAt:
          DateTime.tryParse(json['createdAt'] as String? ?? '') ??
          DateTime.now(),
      videoFolders: (json['videoFolders'] as List?)?.cast<String>() ??
          (json['videoFolder'] != null ? [json['videoFolder'] as String] : []),
      audioFolders: (json['audioFolders'] as List?)?.cast<String>() ??
          (json['audioFolder'] != null ? [json['audioFolder'] as String] : []),
      outputFolder: json['outputFolder'] as String?,
      outputPrefix: json['outputPrefix'] as String? ?? '',
      branding: BrandingSettings.fromJson(
        (json['branding'] as Map?)?.cast<String, Object?>() ?? {},
      ),
      textOverlay: TextOverlaySettings.fromJson(
        (json['textOverlay'] as Map?)?.cast<String, Object?>() ?? {},
      ),
      overlaySettings: OverlaySettings.fromJson(
        (json['overlaySettings'] as Map?)?.cast<String, Object?>() ?? {},
      ),
      useBranding: json['useBranding'] as bool? ?? false,
      useTextOverlay: json['useTextOverlay'] as bool? ?? false,
      useOverlay: json['useOverlay'] as bool? ?? false,
      outputSize: VideoOutputSize.values.firstWhere(
        (value) => value.name == json['outputSize'],
        orElse: () => VideoOutputSize.original,
      ),
      fitMode: VideoFitMode.values.firstWhere(
        (value) => value.name == json['fitMode'],
        orElse: () => VideoFitMode.keepOriginal,
      ),
      thumbnailPath: json['thumbnailPath'] as String?,
      version: json['version'] as int? ?? 1,
    );
  }
}

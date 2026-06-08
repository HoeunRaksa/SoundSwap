import 'package:soundswap/features/branding/data/models/branding_settings.dart';
import 'package:soundswap/features/text_overlay/data/models/text_overlay_settings.dart';

class ProjectTemplate {
  const ProjectTemplate({
    required this.id,
    required this.name,
    required this.createdAt,
    this.videoFolder,
    this.audioFolder,
    this.outputFolder,
    this.outputPrefix = '',
    this.branding = const BrandingSettings(),
    this.textOverlay = const TextOverlaySettings(),
  });

  final String id;
  final String name;
  final DateTime createdAt;
  final String? videoFolder;
  final String? audioFolder;
  final String? outputFolder;
  final String outputPrefix;
  final BrandingSettings branding;
  final TextOverlaySettings textOverlay;

  Map<String, Object?> toJson() => {
    'id': id,
    'name': name,
    'createdAt': createdAt.toIso8601String(),
    'videoFolder': videoFolder,
    'audioFolder': audioFolder,
    'outputFolder': outputFolder,
    'outputPrefix': outputPrefix,
    'branding': branding.toJson(),
    'textOverlay': textOverlay.toJson(),
  };

  factory ProjectTemplate.fromJson(Map<String, Object?> json) {
    return ProjectTemplate(
      id: json['id'] as String? ?? '',
      name: json['name'] as String? ?? 'Untitled',
      createdAt:
          DateTime.tryParse(json['createdAt'] as String? ?? '') ??
          DateTime.now(),
      videoFolder: json['videoFolder'] as String?,
      audioFolder: json['audioFolder'] as String?,
      outputFolder: json['outputFolder'] as String?,
      outputPrefix: json['outputPrefix'] as String? ?? '',
      branding: BrandingSettings.fromJson(
        (json['branding'] as Map?)?.cast<String, Object?>() ?? {},
      ),
      textOverlay: TextOverlaySettings.fromJson(
        (json['textOverlay'] as Map?)?.cast<String, Object?>() ?? {},
      ),
    );
  }
}

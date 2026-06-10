import 'package:soundswap/features/branding/data/models/branding_settings.dart';

class BrandingPreset {
  const BrandingPreset({
    required this.id,
    required this.name,
    required this.createdAt,
    required this.settings,
  });

  final String id;
  final String name;
  final DateTime createdAt;
  final BrandingSettings settings;

  Map<String, Object?> toJson() => {
    'id': id,
    'name': name,
    'createdAt': createdAt.toIso8601String(),
    'settings': settings.toJson(),
  };

  factory BrandingPreset.fromJson(Map<String, Object?> json) {
    return BrandingPreset(
      id: json['id'] as String? ?? '',
      name: json['name'] as String? ?? 'Untitled preset',
      createdAt:
          DateTime.tryParse(json['createdAt'] as String? ?? '') ??
          DateTime.now(),
      settings: BrandingSettings.fromJson(
        (json['settings'] as Map?)?.cast<String, Object?>() ?? {},
      ),
    );
  }

  BrandingPreset copyWith({String? name, BrandingSettings? settings}) {
    return BrandingPreset(
      id: id,
      name: name ?? this.name,
      createdAt: createdAt,
      settings: settings ?? this.settings,
    );
  }
}

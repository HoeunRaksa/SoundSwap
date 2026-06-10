import 'package:soundswap/features/overlay_tools/data/models/overlay_settings.dart';

class OverlayPreset {
  const OverlayPreset({
    required this.id,
    required this.name,
    required this.createdAt,
    required this.settings,
  });

  final String id;
  final String name;
  final DateTime createdAt;
  final OverlaySettings settings;

  Map<String, Object?> toJson() => {
    'id': id,
    'name': name,
    'createdAt': createdAt.toIso8601String(),
    'settings': settings.toJson(),
  };

  factory OverlayPreset.fromJson(Map<String, Object?> json) {
    return OverlayPreset(
      id: json['id'] as String? ?? '',
      name: json['name'] as String? ?? 'Untitled overlay',
      createdAt:
          DateTime.tryParse(json['createdAt'] as String? ?? '') ??
          DateTime.now(),
      settings: OverlaySettings.fromJson(
        (json['settings'] as Map?)?.cast<String, Object?>() ?? {},
      ),
    );
  }

  OverlayPreset copyWith({String? name, OverlaySettings? settings}) {
    return OverlayPreset(
      id: id,
      name: name ?? this.name,
      createdAt: createdAt,
      settings: settings ?? this.settings,
    );
  }
}

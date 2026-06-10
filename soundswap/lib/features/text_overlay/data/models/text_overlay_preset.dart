import 'package:soundswap/features/text_overlay/data/models/text_overlay_settings.dart';

class TextOverlayPreset {
  const TextOverlayPreset({
    required this.id,
    required this.name,
    required this.createdAt,
    required this.settings,
  });

  final String id;
  final String name;
  final DateTime createdAt;
  final TextOverlaySettings settings;

  Map<String, Object?> toJson() => {
    'id': id,
    'name': name,
    'createdAt': createdAt.toIso8601String(),
    'settings': settings.toJson(),
  };

  factory TextOverlayPreset.fromJson(Map<String, Object?> json) {
    return TextOverlayPreset(
      id: json['id'] as String? ?? '',
      name: json['name'] as String? ?? 'Untitled preset',
      createdAt:
          DateTime.tryParse(json['createdAt'] as String? ?? '') ??
          DateTime.now(),
      settings: TextOverlaySettings.fromJson(
        (json['settings'] as Map?)?.cast<String, Object?>() ?? {},
      ),
    );
  }

  TextOverlayPreset copyWith({String? name, TextOverlaySettings? settings}) {
    return TextOverlayPreset(
      id: id,
      name: name ?? this.name,
      createdAt: createdAt,
      settings: settings ?? this.settings,
    );
  }
}

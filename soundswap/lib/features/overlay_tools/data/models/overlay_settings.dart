import 'package:soundswap/features/overlay_tools/data/models/overlay_item.dart';

class OverlaySettings {
  const OverlaySettings({
    this.items = const [],
    this.defaultFontPath,
    this.defaultFontFamily = 'Arial',
  });

  final List<OverlayItem> items;
  final String? defaultFontPath;
  final String defaultFontFamily;

  bool get hasContent => items.any((item) => item.hasContent);

  Map<String, Object?> toJson() => {
    'items': items.map((item) => item.toJson()).toList(),
    'defaultFontPath': defaultFontPath,
    'defaultFontFamily': defaultFontFamily,
  };

  factory OverlaySettings.fromJson(Map<String, Object?> json) {
    final values = json['items'];
    return OverlaySettings(
      items: values is List
          ? values
                .whereType<Map>()
                .map(
                  (value) =>
                      OverlayItem.fromJson(value.cast<String, Object?>()),
                )
                .toList()
          : const [],
      defaultFontPath: json['defaultFontPath'] as String?,
      defaultFontFamily: json['defaultFontFamily'] as String? ?? 'Arial',
    );
  }

  OverlaySettings copyWith({
    List<OverlayItem>? items,
    String? defaultFontPath,
    String? defaultFontFamily,
    bool clearDefaultFontPath = false,
  }) {
    return OverlaySettings(
      items: items ?? this.items,
      defaultFontPath: clearDefaultFontPath
          ? null
          : defaultFontPath ?? this.defaultFontPath,
      defaultFontFamily: defaultFontFamily ?? this.defaultFontFamily,
    );
  }
}

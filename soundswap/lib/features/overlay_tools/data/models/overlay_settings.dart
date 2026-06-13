import 'package:soundswap/features/overlay_tools/data/models/overlay_item.dart';

class SafeAreaPadding {
  const SafeAreaPadding({
    required this.top,
    required this.bottom,
    required this.left,
    required this.right,
  });

  final double top;
  final double bottom;
  final double left;
  final double right;

  Map<String, Object?> toJson() => {
    'top': top,
    'bottom': bottom,
    'left': left,
    'right': right,
  };

  factory SafeAreaPadding.fromJson(Map<String, Object?> json) {
    return SafeAreaPadding(
      top: (json['top'] as num?)?.toDouble() ?? 0,
      bottom: (json['bottom'] as num?)?.toDouble() ?? 0,
      left: (json['left'] as num?)?.toDouble() ?? 0,
      right: (json['right'] as num?)?.toDouble() ?? 0,
    );
  }

  SafeAreaPadding copyWith({
    double? top,
    double? bottom,
    double? left,
    double? right,
  }) {
    return SafeAreaPadding(
      top: top ?? this.top,
      bottom: bottom ?? this.bottom,
      left: left ?? this.left,
      right: right ?? this.right,
    );
  }
}

class OverlaySettings {
  const OverlaySettings({
    this.items = const [],
    this.defaultFontPath,
    this.defaultFontFamily = 'Arial',
    this.safeAreaPreset = 'none',
    this.showSafeAreaGuides = false,
    this.customSafeAreaPadding,
  });

  final List<OverlayItem> items;
  final String? defaultFontPath;
  final String defaultFontFamily;
  final String safeAreaPreset;
  final bool showSafeAreaGuides;
  final SafeAreaPadding? customSafeAreaPadding;

  SafeAreaPadding? get activeSafeArea {
    if (!showSafeAreaGuides) return null;
    switch (safeAreaPreset) {
      case 'facebook_reels':
        return const SafeAreaPadding(top: 220, bottom: 320, left: 80, right: 220);
      case 'tiktok':
        return const SafeAreaPadding(top: 192, bottom: 384, left: 80, right: 220);
      case 'youtube_shorts':
        return const SafeAreaPadding(top: 180, bottom: 280, left: 80, right: 80);
      case 'custom':
        return customSafeAreaPadding;
      default:
        return null;
    }
  }

  bool get hasContent => items.any((item) => item.hasContent);

  Map<String, Object?> toJson() => {
    'items': items.map((item) => item.toJson()).toList(),
    'defaultFontPath': defaultFontPath,
    'defaultFontFamily': defaultFontFamily,
    'safeAreaPreset': safeAreaPreset,
    'showSafeAreaGuides': showSafeAreaGuides,
    'customSafeAreaPadding': customSafeAreaPadding?.toJson(),
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
      safeAreaPreset: json['safeAreaPreset'] as String? ?? 'none',
      showSafeAreaGuides: json['showSafeAreaGuides'] as bool? ?? false,
      customSafeAreaPadding: json['customSafeAreaPadding'] != null
          ? SafeAreaPadding.fromJson(
              (json['customSafeAreaPadding'] as Map).cast<String, Object?>())
          : null,
    );
  }

  OverlaySettings copyWith({
    List<OverlayItem>? items,
    String? defaultFontPath,
    String? defaultFontFamily,
    bool clearDefaultFontPath = false,
    String? safeAreaPreset,
    bool? showSafeAreaGuides,
    SafeAreaPadding? customSafeAreaPadding,
  }) {
    return OverlaySettings(
      items: items ?? this.items,
      defaultFontPath: clearDefaultFontPath
          ? null
          : defaultFontPath ?? this.defaultFontPath,
      defaultFontFamily: defaultFontFamily ?? this.defaultFontFamily,
      safeAreaPreset: safeAreaPreset ?? this.safeAreaPreset,
      showSafeAreaGuides: showSafeAreaGuides ?? this.showSafeAreaGuides,
      customSafeAreaPadding: customSafeAreaPadding ?? this.customSafeAreaPadding,
    );
  }

  OverlaySettings deepCopy() {
    return OverlaySettings.fromJson(toJson());
  }
}

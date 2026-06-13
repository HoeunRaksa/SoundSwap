import 'package:soundswap/core/video/video_output_settings.dart';

enum TextOverlayPosition { top, center, bottom }

class TextOverlaySettings {
  const TextOverlaySettings({
    this.title = '',
    this.subtitle = '',
    this.promotionText = '',
    this.priceText = '',
    this.position = TextOverlayPosition.bottom,
    this.fontFamily = 'Battambang',
    this.fontPath,
    this.fontSource,
    this.bold = false,
    this.italic = false,
    this.fontSize = 46,
    this.textColor = '#FFFFFF',
    this.shadow = true,
    this.backgroundBox = false,
    this.opacity = 1.0,
    this.layerOrder = 0,
    this.textAlignment = 'left',
    this.titlePosition = const NormalizedPosition(xPercent: 0.08, yPercent: 0.12),
    this.subtitlePosition = const NormalizedPosition(xPercent: 0.08, yPercent: 0.20),
    this.promotionPosition = const NormalizedPosition(xPercent: 0.08, yPercent: 0.72),
    this.pricePosition = const NormalizedPosition(xPercent: 0.08, yPercent: 0.82),
  });

  final String title;
  final String subtitle;
  final String promotionText;
  final String priceText;
  final TextOverlayPosition position;
  final String fontFamily;
  final String? fontPath;
  final String? fontSource;
  final bool bold;
  final bool italic;
  final double fontSize;
  final String textColor;
  final bool shadow;
  final bool backgroundBox;
  final double opacity;
  final int layerOrder;
  final String textAlignment;
  final NormalizedPosition titlePosition;
  final NormalizedPosition subtitlePosition;
  final NormalizedPosition promotionPosition;
  final NormalizedPosition pricePosition;

  Map<String, Object?> toJson() => {
    'title': title,
    'subtitle': subtitle,
    'promotionText': promotionText,
    'priceText': priceText,
    'position': position.name,
    'fontFamily': fontFamily,
    'fontPath': fontPath,
    'fontSource': fontSource,
    'bold': bold,
    'italic': italic,
    'fontSize': fontSize,
    'textColor': textColor,
    'shadow': shadow,
    'backgroundBox': backgroundBox,
    'opacity': opacity,
    'layerOrder': layerOrder,
    'textAlignment': textAlignment,
    'titlePosition': titlePosition.toJson(),
    'subtitlePosition': subtitlePosition.toJson(),
    'promotionPosition': promotionPosition.toJson(),
    'pricePosition': pricePosition.toJson(),
  };

  factory TextOverlaySettings.fromJson(Map<String, Object?> json) {
    final legacyPosition = TextOverlayPosition.values.firstWhere(
      (value) => value.name == json['position'],
      orElse: () => TextOverlayPosition.bottom,
    );
    return TextOverlaySettings(
      title: json['title'] as String? ?? '',
      subtitle: json['subtitle'] as String? ?? '',
      promotionText: json['promotionText'] as String? ?? '',
      priceText: json['priceText'] as String? ?? '',
      position: legacyPosition,
      fontFamily: json['fontFamily'] as String? ?? 'Battambang',
      fontPath: json['fontPath'] as String?,
      fontSource: json['fontSource'] as String?,
      bold: json['bold'] as bool? ?? false,
      italic: json['italic'] as bool? ?? false,
      fontSize: (json['fontSize'] as num?)?.toDouble() ?? 46,
      textColor: json['textColor'] as String? ?? '#FFFFFF',
      shadow: json['shadow'] as bool? ?? true,
      backgroundBox: json['backgroundBox'] as bool? ?? false,
      opacity: (json['opacity'] as num?)?.toDouble() ?? 1.0,
      layerOrder: json['layerOrder'] as int? ?? 0,
      textAlignment: json['textAlignment'] as String? ?? 'left',
      titlePosition: NormalizedPosition.fromJson(
        json['titlePosition'],
        fallback: const NormalizedPosition(xPercent: 0.08, yPercent: 0.12),
      ),
      subtitlePosition: NormalizedPosition.fromJson(
        json['subtitlePosition'],
        fallback: const NormalizedPosition(xPercent: 0.08, yPercent: 0.20),
      ),
      promotionPosition: NormalizedPosition.fromJson(
        json['promotionPosition'],
        fallback: _legacyFallback(legacyPosition, 0),
      ),
      pricePosition: NormalizedPosition.fromJson(
        json['pricePosition'],
        fallback: _legacyFallback(legacyPosition, 1),
      ),
    );
  }

  TextOverlaySettings copyWith({
    String? title,
    String? subtitle,
    String? promotionText,
    String? priceText,
    TextOverlayPosition? position,
    String? fontFamily,
    String? fontPath,
    String? fontSource,
    bool? bold,
    bool? italic,
    double? fontSize,
    String? textColor,
    bool? shadow,
    bool? backgroundBox,
    double? opacity,
    int? layerOrder,
    String? textAlignment,
    NormalizedPosition? titlePosition,
    NormalizedPosition? subtitlePosition,
    NormalizedPosition? promotionPosition,
    NormalizedPosition? pricePosition,
  }) {
    return TextOverlaySettings(
      title: title ?? this.title,
      subtitle: subtitle ?? this.subtitle,
      promotionText: promotionText ?? this.promotionText,
      priceText: priceText ?? this.priceText,
      position: position ?? this.position,
      fontFamily: fontFamily ?? this.fontFamily,
      fontPath: fontPath ?? this.fontPath,
      fontSource: fontSource ?? this.fontSource,
      bold: bold ?? this.bold,
      italic: italic ?? this.italic,
      fontSize: fontSize ?? this.fontSize,
      textColor: textColor ?? this.textColor,
      shadow: shadow ?? this.shadow,
      backgroundBox: backgroundBox ?? this.backgroundBox,
      opacity: opacity ?? this.opacity,
      layerOrder: layerOrder ?? this.layerOrder,
      textAlignment: textAlignment ?? this.textAlignment,
      titlePosition: titlePosition ?? this.titlePosition,
      subtitlePosition: subtitlePosition ?? this.subtitlePosition,
      promotionPosition: promotionPosition ?? this.promotionPosition,
      pricePosition: pricePosition ?? this.pricePosition,
    );
  }

  bool get hasContent =>
      title.trim().isNotEmpty ||
      subtitle.trim().isNotEmpty ||
      promotionText.trim().isNotEmpty ||
      priceText.trim().isNotEmpty;

  String buildDrawTextPreview() {
    final items = [
      (text: title, position: titlePosition),
      (text: subtitle, position: subtitlePosition),
      (text: promotionText, position: promotionPosition),
      (text: priceText, position: pricePosition),
    ].where((value) => value.text.trim().isNotEmpty);
    if (items.isEmpty) return 'No text overlay configured.';
    return items
        .map(
          (item) =>
              'drawtext=text="${item.text}":font="$fontFamily":fontsize=${fontSize.toStringAsFixed(0)}:fontcolor=$textColor:x=w*${item.position.xPercent.toStringAsFixed(3)}:y=h*${item.position.yPercent.toStringAsFixed(3)}',
        )
        .join(',\n');
  }

  static NormalizedPosition _legacyFallback(
    TextOverlayPosition position,
    int offset,
  ) {
    final baseY = switch (position) {
      TextOverlayPosition.top => 0.08,
      TextOverlayPosition.center => 0.45,
      TextOverlayPosition.bottom => 0.76,
    };
    return NormalizedPosition(
      xPercent: 0.08,
      yPercent: (baseY + offset * 0.08).clamp(0, 1).toDouble(),
    );
  }
}

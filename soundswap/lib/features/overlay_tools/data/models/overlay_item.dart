import 'package:soundswap/core/video/video_output_settings.dart';

enum OverlayItemType { text, image }

class OverlayItem {
  const OverlayItem({
    required this.id,
    required this.type,
    required this.position,
    this.name = '',
    this.text = '',
    this.imagePath,
    this.fontFamily = 'Arial',
    this.fontPath,
    this.fontSize = 46,
    this.colorHex = '#FFFFFF',
    this.width = 0.3,
    this.shadow = true,
    this.backgroundBox = false,
  });

  final String id;
  final OverlayItemType type;
  final String name;
  final String text;
  final String? imagePath;
  final String fontFamily;
  final String? fontPath;
  final double fontSize;
  final String colorHex;
  final double width;
  final bool shadow;
  final bool backgroundBox;
  final NormalizedPosition position;

  bool get hasContent {
    return switch (type) {
      OverlayItemType.text => text.trim().isNotEmpty,
      OverlayItemType.image => imagePath != null && imagePath!.isNotEmpty,
    };
  }

  Map<String, Object?> toJson() => {
    'id': id,
    'type': type.name,
    'name': name,
    'text': text,
    'imagePath': imagePath,
    'fontFamily': fontFamily,
    'fontPath': fontPath,
    'fontSize': fontSize,
    'colorHex': colorHex,
    'width': width,
    'shadow': shadow,
    'backgroundBox': backgroundBox,
    'position': position.toJson(),
  };

  factory OverlayItem.fromJson(Map<String, Object?> json) {
    return OverlayItem(
      id: json['id'] as String? ?? '',
      type: OverlayItemType.values.firstWhere(
        (value) => value.name == json['type'],
        orElse: () => OverlayItemType.text,
      ),
      name: json['name'] as String? ?? '',
      text: json['text'] as String? ?? '',
      imagePath: json['imagePath'] as String?,
      fontFamily: json['fontFamily'] as String? ?? 'Arial',
      fontPath: json['fontPath'] as String?,
      fontSize: (json['fontSize'] as num?)?.toDouble() ?? 46,
      colorHex: json['colorHex'] as String? ?? '#FFFFFF',
      width: ((json['width'] as num?)?.toDouble() ?? 0.3)
          .clamp(0.08, 1)
          .toDouble(),
      shadow: json['shadow'] as bool? ?? true,
      backgroundBox: json['backgroundBox'] as bool? ?? false,
      position: NormalizedPosition.fromJson(json['position']),
    );
  }

  OverlayItem copyWith({
    String? name,
    String? text,
    String? imagePath,
    String? fontFamily,
    String? fontPath,
    double? fontSize,
    String? colorHex,
    double? width,
    bool? shadow,
    bool? backgroundBox,
    NormalizedPosition? position,
  }) {
    return OverlayItem(
      id: id,
      type: type,
      name: name ?? this.name,
      text: text ?? this.text,
      imagePath: imagePath ?? this.imagePath,
      fontFamily: fontFamily ?? this.fontFamily,
      fontPath: fontPath ?? this.fontPath,
      fontSize: fontSize ?? this.fontSize,
      colorHex: colorHex ?? this.colorHex,
      width: (width ?? this.width).clamp(0.08, 1).toDouble(),
      shadow: shadow ?? this.shadow,
      backgroundBox: backgroundBox ?? this.backgroundBox,
      position: position ?? this.position,
    );
  }
}

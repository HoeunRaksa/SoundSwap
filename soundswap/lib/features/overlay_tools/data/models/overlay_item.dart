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
    this.fontFamily = 'Battambang',
    this.fontPath,
    this.fontSource,
    this.bold = false,
    this.italic = false,
    this.fontSize = 46,
    this.colorHex = '#FFFFFF',
    this.width = 0.3,
    this.shadow = true,
    this.backgroundBox = false,
    this.customWidth,
    this.customHeight,
    this.scale,
    this.lockAspectRatio = true,
    this.opacity = 1.0,
    this.layerOrder = 0,
    this.textAlignment = 'left',
    this.imageFitMode = 'contain',
    this.rotation = 0.0,
    this.locked = false,
    this.hidden = false,
    this.folder,
    this.scaleX = 1.0,
    this.scaleY = 1.0,
    this.startTime = 0.0,
    this.endTime,
    this.animationEntrance,
    this.animationEntranceDuration = 0.5,
    this.animationExit,
    this.animationExitDuration = 0.5,
    this.lineHeight = 1.2,
    this.letterSpacing = 0.0,
    this.strokeWidth = 0.0,
    this.strokeColorHex = '#000000',
  });

  final String id;
  final OverlayItemType type;
  final String name;
  final String text;
  final String? imagePath;
  final String fontFamily;
  final String? fontPath;
  final String? fontSource;
  final bool bold;
  final bool italic;
  final double fontSize;
  final String colorHex;
  final double width;
  final bool shadow;
  final bool backgroundBox;
  final NormalizedPosition position;
  final double? customWidth;
  final double? customHeight;
  final double? scale;
  final bool lockAspectRatio;
  final double opacity;
  final int layerOrder;
  final String textAlignment;
  final String imageFitMode;
  final double rotation;
  final bool locked;
  final bool hidden;
  final String? folder;
  final double scaleX;
  final double scaleY;
  final double startTime;
  final double? endTime;
  final String? animationEntrance;
  final double animationEntranceDuration;
  final String? animationExit;
  final double animationExitDuration;
  final double lineHeight;
  final double letterSpacing;
  final double strokeWidth;
  final String strokeColorHex;

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
    'fontPath': _sanitizeFontPath(fontPath),
    'fontSource': fontSource,
    'bold': bold,
    'italic': italic,
    'fontSize': fontSize,
    'colorHex': colorHex,
    'width': width,
    'shadow': shadow,
    'backgroundBox': backgroundBox,
    'position': position.toJson(),
    'customWidth': customWidth,
    'customHeight': customHeight,
    'scale': scale,
    'lockAspectRatio': lockAspectRatio,
    'opacity': opacity,
    'layerOrder': layerOrder,
    'textAlignment': textAlignment,
    'imageFitMode': imageFitMode,
    'rotation': rotation,
    'locked': locked,
    'hidden': hidden,
    'folder': folder,
    'scaleX': scaleX,
    'scaleY': scaleY,
    'startTime': startTime,
    'endTime': endTime,
    'animationEntrance': animationEntrance,
    'animationEntranceDuration': animationEntranceDuration,
    'animationExit': animationExit,
    'animationExitDuration': animationExitDuration,
    'lineHeight': lineHeight,
    'letterSpacing': letterSpacing,
    'strokeWidth': strokeWidth,
    'strokeColorHex': strokeColorHex,
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
      fontFamily: json['fontFamily'] as String? ?? 'Battambang',
      fontPath: json['fontPath'] as String?,
      fontSource: json['fontSource'] as String?,
      bold: json['bold'] as bool? ?? false,
      italic: json['italic'] as bool? ?? false,
      fontSize: (json['fontSize'] as num?)?.toDouble() ?? 46,
      colorHex: json['colorHex'] as String? ?? '#FFFFFF',
      width: (json['width'] as num?)?.toDouble() ?? 0.3,
      shadow: json['shadow'] as bool? ?? true,
      backgroundBox: json['backgroundBox'] as bool? ?? false,
      position: NormalizedPosition.fromJson(json['position']),
      customWidth: (json['customWidth'] as num?)?.toDouble(),
      customHeight: (json['customHeight'] as num?)?.toDouble(),
      scale: (json['scale'] as num?)?.toDouble(),
      lockAspectRatio: json['lockAspectRatio'] as bool? ?? true,
      opacity: (json['opacity'] as num?)?.toDouble() ?? 1.0,
      layerOrder: json['layerOrder'] as int? ?? 0,
      textAlignment: json['textAlignment'] as String? ?? 'left',
      imageFitMode: json['imageFitMode'] as String? ?? 'contain',
      rotation: (json['rotation'] as num?)?.toDouble() ?? 0.0,
      locked: json['locked'] as bool? ?? false,
      hidden: json['hidden'] as bool? ?? false,
      folder: json['folder'] as String?,
      scaleX: (json['scaleX'] as num?)?.toDouble() ?? 1.0,
      scaleY: (json['scaleY'] as num?)?.toDouble() ?? 1.0,
      startTime: (json['startTime'] as num?)?.toDouble() ?? 0.0,
      endTime: (json['endTime'] as num?)?.toDouble(),
      animationEntrance: json['animationEntrance'] as String?,
      animationEntranceDuration: (json['animationEntranceDuration'] as num?)?.toDouble() ?? 0.5,
      animationExit: json['animationExit'] as String?,
      animationExitDuration: (json['animationExitDuration'] as num?)?.toDouble() ?? 0.5,
      lineHeight: (json['lineHeight'] as num?)?.toDouble() ?? 1.2,
      letterSpacing: (json['letterSpacing'] as num?)?.toDouble() ?? 0.0,
      strokeWidth: (json['strokeWidth'] as num?)?.toDouble() ?? 0.0,
      strokeColorHex: json['strokeColorHex'] as String? ?? '#000000',
    );
  }

  OverlayItem copyWith({
    String? name,
    String? text,
    String? imagePath,
    String? fontFamily,
    String? fontPath,
    String? fontSource,
    bool? bold,
    bool? italic,
    double? fontSize,
    String? colorHex,
    double? width,
    bool? shadow,
    bool? backgroundBox,
    NormalizedPosition? position,
    double? customWidth,
    double? customHeight,
    double? scale,
    bool? lockAspectRatio,
    double? opacity,
    int? layerOrder,
    String? textAlignment,
    String? imageFitMode,
    double? rotation,
    bool? locked,
    bool? hidden,
    String? folder,
    bool clearFolder = false,
    double? scaleX,
    double? scaleY,
    double? startTime,
    double? endTime,
    bool clearEndTime = false,
    String? animationEntrance,
    bool clearAnimationEntrance = false,
    double? animationEntranceDuration,
    String? animationExit,
    bool clearAnimationExit = false,
    double? animationExitDuration,
    double? lineHeight,
    double? letterSpacing,
    double? strokeWidth,
    String? strokeColorHex,
  }) {
    return OverlayItem(
      id: id,
      type: type,
      name: name ?? this.name,
      text: text ?? this.text,
      imagePath: imagePath ?? this.imagePath,
      fontFamily: fontFamily ?? this.fontFamily,
      fontPath: fontPath ?? this.fontPath,
      fontSource: fontSource ?? this.fontSource,
      bold: bold ?? this.bold,
      italic: italic ?? this.italic,
      fontSize: fontSize ?? this.fontSize,
      colorHex: colorHex ?? this.colorHex,
      width: width ?? this.width,
      shadow: shadow ?? this.shadow,
      backgroundBox: backgroundBox ?? this.backgroundBox,
      position: position ?? this.position,
      customWidth: customWidth ?? this.customWidth,
      customHeight: customHeight ?? this.customHeight,
      scale: scale ?? this.scale,
      lockAspectRatio: lockAspectRatio ?? this.lockAspectRatio,
      opacity: opacity ?? this.opacity,
      layerOrder: layerOrder ?? this.layerOrder,
      textAlignment: textAlignment ?? this.textAlignment,
      imageFitMode: imageFitMode ?? this.imageFitMode,
      rotation: rotation ?? this.rotation,
      locked: locked ?? this.locked,
      hidden: hidden ?? this.hidden,
      folder: clearFolder ? null : (folder ?? this.folder),
      scaleX: scaleX ?? this.scaleX,
      scaleY: scaleY ?? this.scaleY,
      startTime: startTime ?? this.startTime,
      endTime: clearEndTime ? null : (endTime ?? this.endTime),
      animationEntrance: clearAnimationEntrance ? null : (animationEntrance ?? this.animationEntrance),
      animationEntranceDuration: animationEntranceDuration ?? this.animationEntranceDuration,
      animationExit: clearAnimationExit ? null : (animationExit ?? this.animationExit),
      animationExitDuration: animationExitDuration ?? this.animationExitDuration,
      lineHeight: lineHeight ?? this.lineHeight,
      letterSpacing: letterSpacing ?? this.letterSpacing,
      strokeWidth: strokeWidth ?? this.strokeWidth,
      strokeColorHex: strokeColorHex ?? this.strokeColorHex,
    );
  }

  static String? _sanitizeFontPath(String? path) {
    if (path == null) return null;
    final lowerPath = path.toLowerCase();
    if (lowerPath.contains(r'appdata\local\microsoft\windows\fonts') ||
        lowerPath.contains(r'windows\fonts')) {
      return null;
    }
    return path;
  }
}

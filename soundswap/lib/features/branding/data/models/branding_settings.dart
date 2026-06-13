import 'package:soundswap/core/video/video_output_settings.dart';

class BrandingSettings {
  const BrandingSettings({
    this.logoPath,
    this.phoneNumber = '',
    this.telegram = '',
    this.facebookPage = '',
    this.fontFamily = 'Battambang',
    this.fontPath,
    this.fontSource,
    this.bold = false,
    this.italic = false,
    this.fontSize = 24.2,
    this.textColor = '#FFFFFF',
    this.logoPosition = NormalizedPosition.topLeft,
    this.textPosition = NormalizedPosition.lowerLeft,
  });

  final String? logoPath;
  final String phoneNumber;
  final String telegram;
  final String facebookPage;
  final String fontFamily;
  final String? fontPath;
  final String? fontSource;
  final bool bold;
  final bool italic;
  final double fontSize;
  final String textColor;
  final NormalizedPosition logoPosition;
  final NormalizedPosition textPosition;

  Map<String, Object?> toJson() => {
    'logoPath': logoPath,
    'phoneNumber': phoneNumber,
    'telegram': telegram,
    'facebookPage': facebookPage,
    'fontFamily': fontFamily,
    'fontPath': _sanitizeFontPath(fontPath),
    'fontSource': fontSource,
    'bold': bold,
    'italic': italic,
    'fontSize': fontSize,
    'textColor': textColor,
    'logoPosition': logoPosition.toJson(),
    'textPosition': textPosition.toJson(),
  };

  factory BrandingSettings.fromJson(Map<String, Object?> json) {
    return BrandingSettings(
      logoPath: json['logoPath'] as String?,
      phoneNumber: json['phoneNumber'] as String? ?? '',
      telegram: json['telegram'] as String? ?? '',
      facebookPage: json['facebookPage'] as String? ?? '',
      fontFamily: json['fontFamily'] as String? ?? 'Battambang',
      fontPath: json['fontPath'] as String?,
      fontSource: json['fontSource'] as String?,
      bold: json['bold'] as bool? ?? false,
      italic: json['italic'] as bool? ?? false,
      fontSize: (json['fontSize'] as num?)?.toDouble() ?? 24.2,
      textColor: json['textColor'] as String? ?? '#FFFFFF',
      logoPosition: NormalizedPosition.fromJson(json['logoPosition']),
      textPosition: NormalizedPosition.fromJson(
        json['textPosition'],
        fallback: NormalizedPosition.lowerLeft,
      ),
    );
  }

  BrandingSettings copyWith({
    String? logoPath,
    String? phoneNumber,
    String? telegram,
    String? facebookPage,
    String? fontFamily,
    String? fontPath,
    String? fontSource,
    bool? bold,
    bool? italic,
    double? fontSize,
    String? textColor,
    NormalizedPosition? logoPosition,
    NormalizedPosition? textPosition,
  }) {
    return BrandingSettings(
      logoPath: logoPath ?? this.logoPath,
      phoneNumber: phoneNumber ?? this.phoneNumber,
      telegram: telegram ?? this.telegram,
      facebookPage: facebookPage ?? this.facebookPage,
      fontFamily: fontFamily ?? this.fontFamily,
      fontPath: fontPath ?? this.fontPath,
      fontSource: fontSource ?? this.fontSource,
      bold: bold ?? this.bold,
      italic: italic ?? this.italic,
      fontSize: fontSize ?? this.fontSize,
      textColor: textColor ?? this.textColor,
      logoPosition: logoPosition ?? this.logoPosition,
      textPosition: textPosition ?? this.textPosition,
    );
  }

  bool get hasLogo => logoPath != null && logoPath!.trim().isNotEmpty;

  bool get hasContactText =>
      phoneNumber.trim().isNotEmpty ||
      telegram.trim().isNotEmpty ||
      facebookPage.trim().isNotEmpty;

  String get contactText {
    return [
      phoneNumber,
      telegram,
      facebookPage,
    ].where((value) => value.trim().isNotEmpty).join('\n');
  }

  bool get hasContent => hasLogo || hasContactText;

  String buildOverlayPreview() {
    final parts = <String>[
      if (logoPath != null && logoPath!.isNotEmpty)
        '-i "$logoPath" -filter_complex "[video][logo] overlay=x=w*${logoPosition.xPercent.toStringAsFixed(3)}:y=h*${logoPosition.yPercent.toStringAsFixed(3)}"',
      if (hasContactText)
        'drawtext=text="${contactText.replaceAll('\n', r'\n')}":font="$fontFamily":fontsize=${fontSize.toStringAsFixed(0)}:fontcolor=$textColor:x=w*${textPosition.xPercent.toStringAsFixed(3)}:y=h*${textPosition.yPercent.toStringAsFixed(3)}',
    ];
    return parts.isEmpty ? 'No branding overlay configured.' : parts.join('\n');
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

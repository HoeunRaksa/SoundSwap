import 'package:soundswap/core/video/video_output_settings.dart';

class BrandingSettings {
  const BrandingSettings({
    this.logoPath,
    this.phoneNumber = '',
    this.telegram = '',
    this.facebookPage = '',
    this.fontFamily = 'Arial',
    this.fontSize = 42,
    this.textColor = '#FFFFFF',
    this.logoPosition = NormalizedPosition.topLeft,
    this.textPosition = NormalizedPosition.lowerLeft,
  });

  final String? logoPath;
  final String phoneNumber;
  final String telegram;
  final String facebookPage;
  final String fontFamily;
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
      fontFamily: json['fontFamily'] as String? ?? 'Arial',
      fontSize: (json['fontSize'] as num?)?.toDouble() ?? 42,
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
}

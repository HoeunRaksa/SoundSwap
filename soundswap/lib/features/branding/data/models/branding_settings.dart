class BrandingSettings {
  const BrandingSettings({
    this.logoPath,
    this.phoneNumber = '',
    this.telegram = '',
    this.facebookPage = '',
  });

  final String? logoPath;
  final String phoneNumber;
  final String telegram;
  final String facebookPage;

  Map<String, Object?> toJson() => {
    'logoPath': logoPath,
    'phoneNumber': phoneNumber,
    'telegram': telegram,
    'facebookPage': facebookPage,
  };

  factory BrandingSettings.fromJson(Map<String, Object?> json) {
    return BrandingSettings(
      logoPath: json['logoPath'] as String?,
      phoneNumber: json['phoneNumber'] as String? ?? '',
      telegram: json['telegram'] as String? ?? '',
      facebookPage: json['facebookPage'] as String? ?? '',
    );
  }

  BrandingSettings copyWith({
    String? logoPath,
    String? phoneNumber,
    String? telegram,
    String? facebookPage,
  }) {
    return BrandingSettings(
      logoPath: logoPath ?? this.logoPath,
      phoneNumber: phoneNumber ?? this.phoneNumber,
      telegram: telegram ?? this.telegram,
      facebookPage: facebookPage ?? this.facebookPage,
    );
  }

  String buildOverlayPreview() {
    final parts = <String>[
      if (logoPath != null && logoPath!.isNotEmpty)
        '-i "$logoPath" -filter_complex "[0:v][1:v] overlay=24:24"',
      if (phoneNumber.isNotEmpty) 'drawtext=text="$phoneNumber":x=24:y=h-80',
      if (telegram.isNotEmpty) 'drawtext=text="$telegram":x=24:y=h-48',
      if (facebookPage.isNotEmpty) 'drawtext=text="$facebookPage":x=24:y=h-24',
    ];
    return parts.isEmpty ? 'No branding overlay configured.' : parts.join('\n');
  }
}

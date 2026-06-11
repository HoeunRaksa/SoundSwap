enum ImageDurationUnit { seconds, minutes }

enum ImageFitMode { contain, cover, stretch, blurBackgroundFill }

extension ImageDurationUnitLabel on ImageDurationUnit {
  String get label => switch (this) {
    ImageDurationUnit.seconds => 'seconds',
    ImageDurationUnit.minutes => 'minutes',
  };
}

extension ImageFitModeLabel on ImageFitMode {
  String get label => switch (this) {
    ImageFitMode.contain => 'Contain',
    ImageFitMode.cover => 'Cover',
    ImageFitMode.stretch => 'Stretch',
    ImageFitMode.blurBackgroundFill => 'Blur Background Fill',
  };

  String get ffmpegFilter {
    return switch (this) {
      ImageFitMode.contain =>
        'scale=iw*min(W/iw\\,H/ih):ih*min(W/iw\\,H/ih),pad=W:H:(W-iw)/2:(H-ih)/2:black',
      ImageFitMode.cover =>
        'scale=iw*max(W/iw\\,H/ih):ih*max(W/iw\\,H/ih),crop=W:H',
      ImageFitMode.stretch => 'scale=W:H',
      ImageFitMode.blurBackgroundFill =>
        'split[fg][bg];[bg]scale=W:H:force_original_aspect_ratio=increase,crop=W:H,gblur=sigma=28[blur];[fg]scale=W:H:force_original_aspect_ratio=decrease[fit];[blur][fit]overlay=(W-w)/2:(H-h)/2',
    };
  }
}

class ImageToVideoSettings {
  const ImageToVideoSettings({
    this.durationValue = 10,
    this.durationUnit = ImageDurationUnit.seconds,
    this.fitMode = ImageFitMode.contain,
  });

  final int durationValue;
  final ImageDurationUnit durationUnit;
  final ImageFitMode fitMode;

  double get durationSeconds {
    return switch (durationUnit) {
      ImageDurationUnit.seconds => durationValue.toDouble(),
      ImageDurationUnit.minutes => durationValue * 60.0,
    };
  }

  Map<String, Object?> toJson() => {
    'durationValue': durationValue,
    'durationUnit': durationUnit.name,
    'fitMode': fitMode.name,
  };

  factory ImageToVideoSettings.fromJson(Map<String, Object?> json) {
    return ImageToVideoSettings(
      durationValue: (json['durationValue'] as num?)?.toInt() ?? 10,
      durationUnit: ImageDurationUnit.values.firstWhere(
        (u) => u.name == json['durationUnit'],
        orElse: () => ImageDurationUnit.seconds,
      ),
      fitMode: ImageFitMode.values.firstWhere(
        (f) => f.name == json['fitMode'],
        orElse: () => ImageFitMode.contain,
      ),
    );
  }

  ImageToVideoSettings copyWith({
    int? durationValue,
    ImageDurationUnit? durationUnit,
    ImageFitMode? fitMode,
  }) {
    return ImageToVideoSettings(
      durationValue: durationValue ?? this.durationValue,
      durationUnit: durationUnit ?? this.durationUnit,
      fitMode: fitMode ?? this.fitMode,
    );
  }
}

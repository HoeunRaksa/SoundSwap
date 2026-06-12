enum VideoOutputSize { original, vertical720, vertical1080, vertical2160 }

enum VideoFitMode { keepOriginal, fitInsideBlurred, fillCrop, stretch }

class NormalizedPosition {
  const NormalizedPosition({required this.xPercent, required this.yPercent});

  final double xPercent;
  final double yPercent;

  static const topLeft = NormalizedPosition(xPercent: 0.08, yPercent: 0.08);
  static const lowerLeft = NormalizedPosition(xPercent: 0.08, yPercent: 0.78);
  static const center = NormalizedPosition(xPercent: 0.5, yPercent: 0.5);

  Map<String, Object?> toJson() => {'xPercent': xPercent, 'yPercent': yPercent};

  factory NormalizedPosition.fromJson(
    Object? value, {
    NormalizedPosition fallback = NormalizedPosition.topLeft,
  }) {
    if (value is! Map) return fallback;
    
    double x = (value['xPercent'] ?? value['x'])?.toDouble() ?? fallback.xPercent;
    double y = (value['yPercent'] ?? value['y'])?.toDouble() ?? fallback.yPercent;

    // Migrate from old absolute pixel coordinates (assuming 1080x1920 reference)
    if (x > 1.0) x = x / 1080.0;
    if (y > 1.0) y = y / 1920.0;

    return NormalizedPosition(
      xPercent: x.clamp(0.0, 1.0),
      yPercent: y.clamp(0.0, 1.0),
    );
  }

  NormalizedPosition copyWith({double? xPercent, double? yPercent}) {
    return NormalizedPosition(
      xPercent: xPercent ?? this.xPercent,
      yPercent: yPercent ?? this.yPercent,
    );
  }
}

extension VideoOutputSizeLabel on VideoOutputSize {
  String get label {
    return switch (this) {
      VideoOutputSize.original => 'Original Size',
      VideoOutputSize.vertical720 => '720 x 1280 Vertical',
      VideoOutputSize.vertical1080 => '1080 x 1920 Vertical',
      VideoOutputSize.vertical2160 => '2160 x 3840 Vertical (4K)',
    };
  }

  int? get width {
    return switch (this) {
      VideoOutputSize.original => null,
      VideoOutputSize.vertical720 => 720,
      VideoOutputSize.vertical1080 => 1080,
      VideoOutputSize.vertical2160 => 2160,
    };
  }

  int? get height {
    return switch (this) {
      VideoOutputSize.original => null,
      VideoOutputSize.vertical720 => 1280,
      VideoOutputSize.vertical1080 => 1920,
      VideoOutputSize.vertical2160 => 3840,
    };
  }

  int get previewWidth => width ?? 1080;
  int get previewHeight => height ?? 1920;
}

extension VideoFitModeLabel on VideoFitMode {
  String get label {
    return switch (this) {
      VideoFitMode.keepOriginal => 'Keep Original',
      VideoFitMode.fitInsideBlurred => 'Fit Inside + Blurred Background',
      VideoFitMode.fillCrop => 'Fill and Crop',
      VideoFitMode.stretch => 'Stretch',
    };
  }

  String get helperText {
    return switch (this) {
      VideoFitMode.keepOriginal => 'Recommended',
      VideoFitMode.fitInsideBlurred =>
        'Keeps full frame with a soft background',
      VideoFitMode.fillCrop => 'Fills the canvas and trims edges',
      VideoFitMode.stretch => 'Not recommended',
    };
  }
}

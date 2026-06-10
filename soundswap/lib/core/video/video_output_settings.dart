enum VideoOutputSize { original, vertical720, vertical1080, vertical2160 }

enum VideoFitMode { keepOriginal, fitInsideBlurred, fillCrop, stretch }

class NormalizedPosition {
  const NormalizedPosition({required this.x, required this.y});

  final double x;
  final double y;

  static const topLeft = NormalizedPosition(x: 0.08, y: 0.08);
  static const lowerLeft = NormalizedPosition(x: 0.08, y: 0.78);
  static const center = NormalizedPosition(x: 0.5, y: 0.5);

  Map<String, Object?> toJson() => {'x': x, 'y': y};

  factory NormalizedPosition.fromJson(
    Object? value, {
    NormalizedPosition fallback = NormalizedPosition.topLeft,
  }) {
    if (value is! Map) return fallback;
    final x = (value['x'] as num?)?.toDouble() ?? fallback.x;
    final y = (value['y'] as num?)?.toDouble() ?? fallback.y;
    return NormalizedPosition(
      x: x.clamp(0, 1).toDouble(),
      y: y.clamp(0, 1).toDouble(),
    );
  }

  NormalizedPosition copyWith({double? x, double? y}) {
    return NormalizedPosition(
      x: (x ?? this.x).clamp(0, 1).toDouble(),
      y: (y ?? this.y).clamp(0, 1).toDouble(),
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

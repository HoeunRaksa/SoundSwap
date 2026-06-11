class EffectsSettings {
  const EffectsSettings({
    this.randomAudioStart = false,
    this.slightZoom = false,
    this.brightnessAdjustment = false,
    this.speedVariation = false,
  });

  final bool randomAudioStart;
  final bool slightZoom;
  final bool brightnessAdjustment;
  final bool speedVariation;

  Map<String, Object?> toJson() => {
    'randomAudioStart': randomAudioStart,
    'slightZoom': slightZoom,
    'brightnessAdjustment': brightnessAdjustment,
    'speedVariation': speedVariation,
  };

  factory EffectsSettings.fromJson(Map<String, Object?> json) {
    return EffectsSettings(
      randomAudioStart: json['randomAudioStart'] as bool? ?? false,
      slightZoom: json['slightZoom'] as bool? ?? false,
      brightnessAdjustment: json['brightnessAdjustment'] as bool? ?? false,
      speedVariation: json['speedVariation'] as bool? ?? false,
    );
  }

  EffectsSettings copyWith({
    bool? randomAudioStart,
    bool? slightZoom,
    bool? brightnessAdjustment,
    bool? speedVariation,
  }) {
    return EffectsSettings(
      randomAudioStart: randomAudioStart ?? this.randomAudioStart,
      slightZoom: slightZoom ?? this.slightZoom,
      brightnessAdjustment: brightnessAdjustment ?? this.brightnessAdjustment,
      speedVariation: speedVariation ?? this.speedVariation,
    );
  }

  bool get hasActiveVideoEffects =>
      slightZoom || brightnessAdjustment || speedVariation;

  String buildFilterPreview() {
    final filters = <String>[
      if (slightZoom) 'scale=iw*1.03:ih*1.03,crop=iw:ih',
      if (brightnessAdjustment) 'eq=brightness=0.04:saturation=1.05',
      if (speedVariation) 'setpts=PTS/1.02',
    ];
    if (filters.isEmpty && !randomAudioStart) {
      return 'No effects enabled.';
    }
    return [
      if (randomAudioStart) 'Audio: random -ss start enabled',
      if (filters.isNotEmpty) 'Video filters: ${filters.join(',')}',
    ].join('\n');
  }
}

enum AudioMode { replaceOriginal, mixOriginalAndNew, keepOriginalOnly }

extension AudioModeLabel on AudioMode {
  String get label {
    return switch (this) {
      AudioMode.replaceOriginal => 'Replace Original Audio',
      AudioMode.mixOriginalAndNew => 'Mix Original + New Audio',
      AudioMode.keepOriginalOnly => 'Keep Original Only',
    };
  }

  String get description {
    return switch (this) {
      AudioMode.replaceOriginal => 'Replaces the video\'s audio with the new track.',
      AudioMode.mixOriginalAndNew => 'Blends the original and new audio together.',
      AudioMode.keepOriginalOnly => 'Keeps the original audio; ignores the audio folder.',
    };
  }
}

class AudioSettings {
  const AudioSettings({
    this.mode = AudioMode.replaceOriginal,
    this.originalAudioVolume = 0,
    this.newAudioVolume = 100,
  });

  /// The audio blending mode.
  final AudioMode mode;

  /// Volume of the original video audio stream (0–100).
  final int originalAudioVolume;

  /// Volume of the replacement audio track (0–300).
  final int newAudioVolume;

  Map<String, Object?> toJson() => {
    'mode': mode.name,
    'originalAudioVolume': originalAudioVolume,
    'newAudioVolume': newAudioVolume,
  };

  factory AudioSettings.fromJson(Map<String, Object?> json) {
    return AudioSettings(
      mode: AudioMode.values.firstWhere(
        (m) => m.name == json['mode'],
        orElse: () => AudioMode.replaceOriginal,
      ),
      originalAudioVolume: (json['originalAudioVolume'] as num?)?.toInt() ?? 0,
      newAudioVolume: (json['newAudioVolume'] as num?)?.toInt() ?? 100,
    );
  }

  AudioSettings copyWith({
    AudioMode? mode,
    int? originalAudioVolume,
    int? newAudioVolume,
  }) {
    return AudioSettings(
      mode: mode ?? this.mode,
      originalAudioVolume: originalAudioVolume ?? this.originalAudioVolume,
      newAudioVolume: newAudioVolume ?? this.newAudioVolume,
    );
  }
}

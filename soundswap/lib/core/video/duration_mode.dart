enum DurationMode { trimAudioToVideo, trimVideoToAudio, useShortest, useLongest }

extension DurationModeLabel on DurationMode {
  String get label {
    return switch (this) {
      DurationMode.trimAudioToVideo => 'Trim Audio to Video',
      DurationMode.trimVideoToAudio => 'Trim Video to Audio',
      DurationMode.useShortest => 'Use Shortest',
      DurationMode.useLongest => 'Use Longest',
    };
  }

  String get description {
    return switch (this) {
      DurationMode.trimAudioToVideo =>
        'Video length controls output. Audio is cut if longer.',
      DurationMode.trimVideoToAudio =>
        'Audio length controls output. Video is cut if longer.',
      DurationMode.useShortest => 'Output ends at whichever source is shorter.',
      DurationMode.useLongest =>
        'Continue until the longest source ends (may produce silence or freeze frame).',
    };
  }
}

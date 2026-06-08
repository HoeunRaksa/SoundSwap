class FolderWatcherSettings {
  const FolderWatcherSettings({
    this.videoFolderPath,
    this.audioFolderPath,
    this.resultFolderPath,
  });

  final String? videoFolderPath;
  final String? audioFolderPath;
  final String? resultFolderPath;

  Map<String, Object?> toJson() => {
    'videoFolderPath': videoFolderPath,
    'audioFolderPath': audioFolderPath,
    'resultFolderPath': resultFolderPath,
  };

  factory FolderWatcherSettings.fromJson(Map<String, Object?> json) {
    return FolderWatcherSettings(
      videoFolderPath: json['videoFolderPath'] as String?,
      audioFolderPath: json['audioFolderPath'] as String?,
      resultFolderPath: json['resultFolderPath'] as String?,
    );
  }

  FolderWatcherSettings copyWith({
    String? videoFolderPath,
    String? audioFolderPath,
    String? resultFolderPath,
  }) {
    return FolderWatcherSettings(
      videoFolderPath: videoFolderPath ?? this.videoFolderPath,
      audioFolderPath: audioFolderPath ?? this.audioFolderPath,
      resultFolderPath: resultFolderPath ?? this.resultFolderPath,
    );
  }
}

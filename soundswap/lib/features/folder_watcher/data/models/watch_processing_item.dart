enum WatchProcessingStatus { queued, waiting, processing, success, failed }

class WatchProcessingItem {
  const WatchProcessingItem({
    required this.videoPath,
    required this.status,
    this.audioPath,
    this.outputPath,
    this.errorMessage,
  });

  final String videoPath;
  final String? audioPath;
  final String? outputPath;
  final WatchProcessingStatus status;
  final String? errorMessage;

  WatchProcessingItem copyWith({
    String? audioPath,
    String? outputPath,
    WatchProcessingStatus? status,
    String? errorMessage,
  }) {
    return WatchProcessingItem(
      videoPath: videoPath,
      audioPath: audioPath ?? this.audioPath,
      outputPath: outputPath ?? this.outputPath,
      status: status ?? this.status,
      errorMessage: errorMessage,
    );
  }
}

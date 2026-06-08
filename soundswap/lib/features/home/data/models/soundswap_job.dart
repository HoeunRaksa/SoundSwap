import 'package:path/path.dart' as p;
import 'package:soundswap/features/home/data/models/media_file.dart';

enum SoundSwapStatus { queued, processing, success, failed }

class SoundSwapJob {
  const SoundSwapJob({
    required this.video,
    required this.audio,
    required this.outputPath,
    this.status = SoundSwapStatus.queued,
    this.errorMessage,
  });

  final MediaFile video;
  final MediaFile audio;
  final String outputPath;
  final SoundSwapStatus status;
  final String? errorMessage;

  String get outputName => p.basename(outputPath);

  SoundSwapJob copyWith({SoundSwapStatus? status, String? errorMessage}) {
    return SoundSwapJob(
      video: video,
      audio: audio,
      outputPath: outputPath,
      status: status ?? this.status,
      errorMessage: errorMessage,
    );
  }
}

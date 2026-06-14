import 'package:path/path.dart' as p;
import 'package:soundswap/features/home/data/models/media_file.dart';
import 'package:soundswap/features/templates/data/models/project_template.dart';

enum SoundSwapStatus { queued, processing, success, failed, skipped }

class SoundSwapJob {
  const SoundSwapJob({
    required this.video,
    required this.audio,
    required this.outputPath,
    this.status = SoundSwapStatus.queued,
    this.retryCount = 0,
    this.template,
    this.ffmpegCommand,
    this.ffmpegOutput,
    this.stackTrace,
    this.errorMessage,
  });

  final MediaFile video;
  final MediaFile audio;
  final String outputPath;
  final SoundSwapStatus status;
  final int retryCount;
  final ProjectTemplate? template;
  final String? ffmpegCommand;
  final String? ffmpegOutput;
  final String? stackTrace;
  final String? errorMessage;

  String get outputName => p.basename(outputPath);

  SoundSwapJob copyWith({
    MediaFile? video,
    MediaFile? audio,
    SoundSwapStatus? status,
    int? retryCount,
    ProjectTemplate? template,
    bool explicitNullTemplate = false,
    String? ffmpegCommand,
    String? ffmpegOutput,
    String? stackTrace,
    String? errorMessage,
  }) {
    return SoundSwapJob(
      video: video ?? this.video,
      audio: audio ?? this.audio,
      outputPath: outputPath,
      status: status ?? this.status,
      retryCount: retryCount ?? this.retryCount,
      template: explicitNullTemplate ? null : (template ?? this.template),
      ffmpegCommand: ffmpegCommand ?? this.ffmpegCommand,
      ffmpegOutput: ffmpegOutput ?? this.ffmpegOutput,
      stackTrace: stackTrace ?? this.stackTrace,
      errorMessage: errorMessage ?? this.errorMessage,
    );
  }
}

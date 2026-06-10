import 'package:soundswap/features/home/data/models/batch_profile.dart';
import 'package:soundswap/features/home/data/models/media_file.dart';
import 'package:soundswap/features/home/data/models/soundswap_job.dart';

class BatchQueue {
  const BatchQueue({
    required this.id,
    required this.profile,
    required this.createdAt,
    required this.videos,
    required this.audios,
    required this.jobs,
  });

  final String id;
  final BatchProfile profile;
  final DateTime createdAt;
  final List<MediaFile> videos;
  final List<MediaFile> audios;
  final List<SoundSwapJob> jobs;

  String get displayName =>
      profile.name.trim().isEmpty ? 'Batch queue' : profile.name.trim();

  BatchQueue copyWith({
    BatchProfile? profile,
    List<MediaFile>? videos,
    List<MediaFile>? audios,
    List<SoundSwapJob>? jobs,
  }) {
    return BatchQueue(
      id: id,
      profile: profile ?? this.profile,
      createdAt: createdAt,
      videos: videos ?? this.videos,
      audios: audios ?? this.audios,
      jobs: jobs ?? this.jobs,
    );
  }
}

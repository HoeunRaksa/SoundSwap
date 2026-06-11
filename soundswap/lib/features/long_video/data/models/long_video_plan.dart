import 'package:path/path.dart' as p;

enum LongVideoAudioMode { selectedFile, randomFromFolder }

enum LongVideoDurationMode {
  exactTargetLength,
  matchAudioLength,
  matchVideoPlanLength,
  useShortest,
  useLongest,
}

enum LongVideoAudioBehavior {
  trimToFinalVideo,
  loopToFinalVideo,
  randomFillToFinalVideo,
  silenceWhenAudioEnds,
}

class LongVideoClip {
  const LongVideoClip({
    required this.videoPath,
    required this.sourceDuration,
    required this.clipDuration,
  });

  final String videoPath;
  final double sourceDuration;
  final double clipDuration;

  String get name => p.basename(videoPath);
}

class LongVideoAudioSegment {
  const LongVideoAudioSegment({
    required this.audioPath,
    required this.sourceDuration,
    required this.segmentDuration,
  });

  final String audioPath;
  final double sourceDuration;
  final double segmentDuration;

  String get name => p.basename(audioPath);
}

class LongVideoPlan {
  const LongVideoPlan({
    required this.clips,
    required this.audioSegments,
    required this.estimatedDuration,
    required this.outputPath,
  });

  final List<LongVideoClip> clips;
  final List<LongVideoAudioSegment> audioSegments;
  final double estimatedDuration;
  final String outputPath;

  String get outputName => p.basename(outputPath);
}
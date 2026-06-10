enum ResultHistoryStatus { success, failed }

enum ResultProcessType { auto, manual }

class ResultHistoryRecord {
  const ResultHistoryRecord({
    required this.id,
    required this.originalVideoPath,
    required this.audioPath,
    required this.outputPath,
    required this.resultFolderPath,
    required this.status,
    required this.createdAt,
    this.processType = ResultProcessType.auto,
    this.outputPrefix = '',
    this.totalVideos = 1,
    this.errorMessage,
  });

  final String id;
  final String originalVideoPath;
  final String audioPath;
  final String outputPath;
  final String resultFolderPath;
  final ResultHistoryStatus status;
  final DateTime createdAt;
  final ResultProcessType processType;
  final String outputPrefix;
  final int totalVideos;
  final String? errorMessage;

  Map<String, Object?> toJson() => {
    'id': id,
    'originalVideoPath': originalVideoPath,
    'audioPath': audioPath,
    'outputPath': outputPath,
    'resultFolderPath': resultFolderPath,
    'status': status.name,
    'createdAt': createdAt.toIso8601String(),
    'processType': processType.name,
    'outputPrefix': outputPrefix,
    'totalVideos': totalVideos,
    'errorMessage': errorMessage,
  };

  factory ResultHistoryRecord.fromJson(Map<String, Object?> json) {
    return ResultHistoryRecord(
      id: json['id'] as String? ?? '',
      originalVideoPath: json['originalVideoPath'] as String? ?? '',
      audioPath: json['audioPath'] as String? ?? '',
      outputPath: json['outputPath'] as String? ?? '',
      resultFolderPath: json['resultFolderPath'] as String? ?? '',
      status: ResultHistoryStatus.values.firstWhere(
        (value) => value.name == json['status'],
        orElse: () => ResultHistoryStatus.failed,
      ),
      createdAt:
          DateTime.tryParse(json['createdAt'] as String? ?? '') ??
          DateTime.now(),
      processType: ResultProcessType.values.firstWhere(
        (value) => value.name == json['processType'],
        orElse: () => ResultProcessType.auto,
      ),
      outputPrefix: json['outputPrefix'] as String? ?? '',
      totalVideos: json['totalVideos'] as int? ?? 1,
      errorMessage: json['errorMessage'] as String?,
    );
  }
}

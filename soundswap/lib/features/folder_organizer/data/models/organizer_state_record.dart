class OrganizerStateRecord {
  final String originalPath;
  final String fileName;
  final int fileSize;
  final int lastModified;
  final DateTime processedAt;
  final String destinationPath;
  final String mediaType;
  final String status;

  OrganizerStateRecord({
    required this.originalPath,
    required this.fileName,
    required this.fileSize,
    required this.lastModified,
    required this.processedAt,
    required this.destinationPath,
    required this.mediaType,
    required this.status,
  });

  factory OrganizerStateRecord.fromJson(Map<String, dynamic> json) {
    return OrganizerStateRecord(
      originalPath: json['originalPath'] as String? ?? '',
      fileName: json['fileName'] as String? ?? '',
      fileSize: json['fileSize'] as int? ?? 0,
      lastModified: json['lastModified'] as int? ?? 0,
      processedAt: json['processedAt'] != null 
          ? DateTime.parse(json['processedAt'] as String) 
          : DateTime.now(),
      destinationPath: json['destinationPath'] as String? ?? '',
      mediaType: json['mediaType'] as String? ?? '',
      status: json['status'] as String? ?? '',
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'originalPath': originalPath,
      'fileName': fileName,
      'fileSize': fileSize,
      'lastModified': lastModified,
      'processedAt': processedAt.toIso8601String(),
      'destinationPath': destinationPath,
      'mediaType': mediaType,
      'status': status,
    };
  }

  OrganizerStateRecord copyWith({
    String? originalPath,
    String? fileName,
    int? fileSize,
    int? lastModified,
    DateTime? processedAt,
    String? destinationPath,
    String? mediaType,
    String? status,
  }) {
    return OrganizerStateRecord(
      originalPath: originalPath ?? this.originalPath,
      fileName: fileName ?? this.fileName,
      fileSize: fileSize ?? this.fileSize,
      lastModified: lastModified ?? this.lastModified,
      processedAt: processedAt ?? this.processedAt,
      destinationPath: destinationPath ?? this.destinationPath,
      mediaType: mediaType ?? this.mediaType,
      status: status ?? this.status,
    );
  }
}

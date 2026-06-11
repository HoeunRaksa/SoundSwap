class OrganizerHistoryEntry {
  OrganizerHistoryEntry({
    required this.originalPath,
    this.newPath,
    required this.action,
    required this.fileType,
  });

  final String originalPath;
  final String? newPath;
  final String action;
  final String fileType;

  Map<String, Object?> toJson() => {
        'originalPath': originalPath,
        'newPath': newPath,
        'action': action,
        'fileType': fileType,
      };

  factory OrganizerHistoryEntry.fromJson(Map<String, Object?> json) {
    return OrganizerHistoryEntry(
      originalPath: json['originalPath'] as String,
      newPath: json['newPath'] as String?,
      action: json['action'] as String? ?? 'skip',
      fileType: json['fileType'] as String? ?? 'image',
    );
  }
}

class OrganizerHistoryRecord {
  OrganizerHistoryRecord({
    required this.id,
    required this.timestamp,
    required this.rootFolder,
    required this.entries,
    this.undoApplied = false,
    this.emptyFoldersRemoved = 0,
    this.emptyFoldersSkipped = 0,
  });

  final String id;
  final DateTime timestamp;
  final String rootFolder;
  final List<OrganizerHistoryEntry> entries;
  bool undoApplied;
  final int emptyFoldersRemoved;
  final int emptyFoldersSkipped;

  Map<String, Object?> toJson() => {
        'id': id,
        'timestamp': timestamp.toIso8601String(),
        'rootFolder': rootFolder,
        'entries': entries.map((e) => e.toJson()).toList(),
        'undoApplied': undoApplied,
        'emptyFoldersRemoved': emptyFoldersRemoved,
        'emptyFoldersSkipped': emptyFoldersSkipped,
      };

  factory OrganizerHistoryRecord.fromJson(Map<String, Object?> json) {
    return OrganizerHistoryRecord(
      id: json['id'] as String,
      timestamp: DateTime.parse(json['timestamp'] as String),
      rootFolder: json['rootFolder'] as String,
      entries: (json['entries'] as List? ?? [])
          .whereType<Map>()
          .map((e) => OrganizerHistoryEntry.fromJson(e.cast<String, Object?>()))
          .toList(),
      undoApplied: json['undoApplied'] as bool? ?? false,
      emptyFoldersRemoved: json['emptyFoldersRemoved'] as int? ?? 0,
      emptyFoldersSkipped: json['emptyFoldersSkipped'] as int? ?? 0,
    );
  }
}

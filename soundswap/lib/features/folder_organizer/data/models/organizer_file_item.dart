enum FileItemType {
  image,
  video,
}

enum FileItemAction {
  move, // Move to images/ or videos/
  rename, // Rename according to prefix and counter
  moveAndRename, // Both move and rename
  duplicateMove, // Move duplicate to Duplicates/
  duplicateDelete, // Delete duplicate permanently
  skip, // Keep original place and name
  alreadyOrganized, // Already in the correct destination folder
  convert, // Convert HEIC/HEIF to PNG
  error, // Error during scan/processing
}

/// Orientation of the media file detected via dimension probing.
/// 'vertical'  → height > width  (portrait / reel / short)
/// 'landscape' → width > height  (standard widescreen)
/// 'square'    → width == height
enum MediaOrientation {
  vertical,
  landscape,
  square,
}

class OrganizerFileItem {
  OrganizerFileItem({
    required this.originalPath,
    required this.fileName,
    required this.fileType,
    required this.sizeBytes,
    this.newPath,
    this.hash,
    this.action = FileItemAction.skip,
    this.isDuplicate = false,
    this.duplicateOfPath,
    this.errorMessage,
    this.width,
    this.height,
    this.orientation,
    this.qualityGroup,
    this.reason,
    this.rotation,
    this.displayWidth,
    this.displayHeight,
    this.visualOrientation,
    this.finalOrientation,
  });

  final String originalPath;
  final String fileName;
  final FileItemType fileType;
  final int sizeBytes;
  String? newPath;
  String? hash;
  FileItemAction action;
  bool isDuplicate;
  String? duplicateOfPath;
  String? errorMessage;
  int? width;
  int? height;
  MediaOrientation? orientation;

  /// 'goodQuality' | 'lowerQuality' etc.
  String? qualityGroup;
  
  /// Quality classification reason or description
  String? reason;

  int? rotation;
  int? displayWidth;
  int? displayHeight;
  MediaOrientation? visualOrientation;
  MediaOrientation? finalOrientation;

  OrganizerFileItem copyWith({
    String? originalPath,
    String? fileName,
    FileItemType? fileType,
    int? sizeBytes,
    String? newPath,
    String? hash,
    FileItemAction? action,
    bool? isDuplicate,
    String? duplicateOfPath,
    String? errorMessage,
    int? width,
    int? height,
    MediaOrientation? orientation,
    String? qualityGroup,
    String? reason,
    int? rotation,
    int? displayWidth,
    int? displayHeight,
    MediaOrientation? visualOrientation,
    MediaOrientation? finalOrientation,
  }) {
    return OrganizerFileItem(
      originalPath: originalPath ?? this.originalPath,
      fileName: fileName ?? this.fileName,
      fileType: fileType ?? this.fileType,
      sizeBytes: sizeBytes ?? this.sizeBytes,
      newPath: newPath ?? this.newPath,
      hash: hash ?? this.hash,
      action: action ?? this.action,
      isDuplicate: isDuplicate ?? this.isDuplicate,
      duplicateOfPath: duplicateOfPath ?? this.duplicateOfPath,
      errorMessage: errorMessage ?? this.errorMessage,
      width: width ?? this.width,
      height: height ?? this.height,
      orientation: orientation ?? this.orientation,
      qualityGroup: qualityGroup ?? this.qualityGroup,
      reason: reason ?? this.reason,
      rotation: rotation ?? this.rotation,
      displayWidth: displayWidth ?? this.displayWidth,
      displayHeight: displayHeight ?? this.displayHeight,
      visualOrientation: visualOrientation ?? this.visualOrientation,
      finalOrientation: finalOrientation ?? this.finalOrientation,
    );
  }

  Map<String, Object?> toJson() => {
        'originalPath': originalPath,
        'fileName': fileName,
        'fileType': fileType.name,
        'sizeBytes': sizeBytes,
        'newPath': newPath,
        'hash': hash,
        'action': action.name,
        'isDuplicate': isDuplicate,
        'duplicateOfPath': duplicateOfPath,
        'errorMessage': errorMessage,
        'width': width,
        'height': height,
        'orientation': orientation?.name,
        'qualityGroup': qualityGroup,
        'reason': reason,
        'rotation': rotation,
        'displayWidth': displayWidth,
        'displayHeight': displayHeight,
        'visualOrientation': visualOrientation?.name,
        'finalOrientation': finalOrientation?.name,
      };

  factory OrganizerFileItem.fromJson(Map<String, Object?> json) {
    return OrganizerFileItem(
      originalPath: json['originalPath'] as String,
      fileName: json['fileName'] as String,
      fileType: FileItemType.values.firstWhere(
        (e) => e.name == json['fileType'],
        orElse: () => FileItemType.image,
      ),
      sizeBytes: json['sizeBytes'] as int,
      newPath: json['newPath'] as String?,
      hash: json['hash'] as String?,
      action: FileItemAction.values.firstWhere(
        (e) => e.name == json['action'],
        orElse: () => FileItemAction.skip,
      ),
      isDuplicate: json['isDuplicate'] as bool? ?? false,
      duplicateOfPath: json['duplicateOfPath'] as String?,
      errorMessage: json['errorMessage'] as String?,
      width: json['width'] as int?,
      height: json['height'] as int?,
      orientation: json['orientation'] != null
          ? MediaOrientation.values.firstWhere(
              (e) => e.name == json['orientation'],
              orElse: () => MediaOrientation.landscape,
            )
          : null,
      qualityGroup: json['qualityGroup'] as String?,
      reason: json['reason'] as String?,
      rotation: json['rotation'] as int?,
      displayWidth: json['displayWidth'] as int?,
      displayHeight: json['displayHeight'] as int?,
      visualOrientation: json['visualOrientation'] != null
          ? MediaOrientation.values.firstWhere(
              (e) => e.name == json['visualOrientation'],
              orElse: () => MediaOrientation.landscape,
            )
          : null,
      finalOrientation: json['finalOrientation'] != null
          ? MediaOrientation.values.firstWhere(
              (e) => e.name == json['finalOrientation'],
              orElse: () => MediaOrientation.landscape,
            )
          : null,
    );
  }
}

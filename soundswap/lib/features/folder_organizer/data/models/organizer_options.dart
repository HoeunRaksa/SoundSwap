enum RenameMode {
  keepNames,
  keepPrefix,
  custom,
}

enum DuplicateAction {
  move,
  skip,
  delete,
}

enum OrganizerMode {
  typeOnly,
  byQuality,
}

class OrganizerOptions {
  const OrganizerOptions({
    // keepFolderStructure: true  → organize inside each source folder (Case 2)
    // keepFolderStructure: false → collect all files into root destination folders (Case 1)
    this.keepFolderStructure = true,
    this.removeEmptyFolders = false,
    this.includeHiddenFolders = false,
    this.detectDuplicates = true,
    this.organizeFiles = true,
    this.renameFiles = false,
    this.renameMode = RenameMode.keepNames,
    this.customImagePrefix = 'product-image',
    this.customVideoPrefix = 'product-video',
    this.startNumber = 1,
    this.numberPadding = 3,
    this.duplicateAction = DuplicateAction.move,
    this.exportReport = true,
    this.organizeMode = OrganizerMode.typeOnly,
    this.qualityWidth = 1080,
    this.qualityHeight = 1920,
    this.convertHeicToPng = false,
    this.deleteOriginalHeic = false,
    this.preferVisualOrientation = true,
  });

  final bool keepFolderStructure;
  final bool removeEmptyFolders;
  final bool includeHiddenFolders;
  final bool detectDuplicates;
  final bool organizeFiles;
  final bool renameFiles;
  final RenameMode renameMode;
  final String customImagePrefix;
  final String customVideoPrefix;
  final int startNumber;
  final int numberPadding;
  final DuplicateAction duplicateAction;
  final bool exportReport;
  final OrganizerMode organizeMode;
  final int qualityWidth;
  final int qualityHeight;
  final bool convertHeicToPng;
  final bool deleteOriginalHeic;
  final bool preferVisualOrientation;

  Map<String, Object?> toJson() => {
        'keepFolderStructure': keepFolderStructure,
        'removeEmptyFolders': removeEmptyFolders,
        'includeHiddenFolders': includeHiddenFolders,
        'detectDuplicates': detectDuplicates,
        'organizeFiles': organizeFiles,
        'renameFiles': renameFiles,
        'renameMode': renameMode.name,
        'customImagePrefix': customImagePrefix,
        'customVideoPrefix': customVideoPrefix,
        'startNumber': startNumber,
        'numberPadding': numberPadding,
        'duplicateAction': duplicateAction.name,
        'exportReport': exportReport,
        'organizeMode': organizeMode.name,
        'qualityWidth': qualityWidth,
        'qualityHeight': qualityHeight,
        'convertHeicToPng': convertHeicToPng,
        'deleteOriginalHeic': deleteOriginalHeic,
        'preferVisualOrientation': preferVisualOrientation,
      };

  factory OrganizerOptions.fromJson(Map<String, Object?> json) {
    // Support legacy key 'scanSubfolders' — old value was inverted logic
    bool keepFolderStructure = true;
    if (json.containsKey('keepFolderStructure')) {
      keepFolderStructure = json['keepFolderStructure'] as bool? ?? true;
    } else if (json.containsKey('scanSubfolders')) {
      // Previously scanSubfolders=true meant "scan recursively" which roughly
      // maps to keepFolderStructure=true.
      keepFolderStructure = json['scanSubfolders'] as bool? ?? true;
    }

    return OrganizerOptions(
      keepFolderStructure: keepFolderStructure,
      removeEmptyFolders: json['removeEmptyFolders'] as bool? ?? false,
      includeHiddenFolders: json['includeHiddenFolders'] as bool? ?? false,
      detectDuplicates: json['detectDuplicates'] as bool? ?? true,
      organizeFiles: json['organizeFiles'] as bool? ?? true,
      renameFiles: json['renameFiles'] as bool? ?? false,
      renameMode: RenameMode.values.firstWhere(
        (e) => e.name == json['renameMode'],
        orElse: () => RenameMode.keepNames,
      ),
      customImagePrefix: json['customImagePrefix'] as String? ?? 'product-image',
      customVideoPrefix: json['customVideoPrefix'] as String? ?? 'product-video',
      startNumber: json['startNumber'] as int? ?? 1,
      numberPadding: json['numberPadding'] as int? ?? 3,
      duplicateAction: DuplicateAction.values.firstWhere(
        (e) => e.name == json['duplicateAction'],
        orElse: () => DuplicateAction.move,
      ),
      exportReport: json['exportReport'] as bool? ?? true,
      organizeMode: OrganizerMode.values.firstWhere(
        (e) => e.name == json['organizeMode'],
        orElse: () => OrganizerMode.typeOnly,
      ),
      qualityWidth: json['qualityWidth'] as int? ?? 1080,
      qualityHeight: json['qualityHeight'] as int? ?? 1920,
      convertHeicToPng: json['convertHeicToPng'] as bool? ?? false,
      deleteOriginalHeic: json['deleteOriginalHeic'] as bool? ?? false,
      preferVisualOrientation: json['preferVisualOrientation'] as bool? ?? true,
    );
  }

  OrganizerOptions copyWith({
    bool? keepFolderStructure,
    bool? removeEmptyFolders,
    bool? includeHiddenFolders,
    bool? detectDuplicates,
    bool? organizeFiles,
    bool? renameFiles,
    RenameMode? renameMode,
    String? customImagePrefix,
    String? customVideoPrefix,
    int? startNumber,
    int? numberPadding,
    DuplicateAction? duplicateAction,
    bool? exportReport,
    OrganizerMode? organizeMode,
    int? qualityWidth,
    int? qualityHeight,
    bool? convertHeicToPng,
    bool? deleteOriginalHeic,
    bool? preferVisualOrientation,
  }) {
    return OrganizerOptions(
      keepFolderStructure: keepFolderStructure ?? this.keepFolderStructure,
      removeEmptyFolders: removeEmptyFolders ?? this.removeEmptyFolders,
      includeHiddenFolders: includeHiddenFolders ?? this.includeHiddenFolders,
      detectDuplicates: detectDuplicates ?? this.detectDuplicates,
      organizeFiles: organizeFiles ?? this.organizeFiles,
      renameFiles: renameFiles ?? this.renameFiles,
      renameMode: renameMode ?? this.renameMode,
      customImagePrefix: customImagePrefix ?? this.customImagePrefix,
      customVideoPrefix: customVideoPrefix ?? this.customVideoPrefix,
      startNumber: startNumber ?? this.startNumber,
      numberPadding: numberPadding ?? this.numberPadding,
      duplicateAction: duplicateAction ?? this.duplicateAction,
      exportReport: exportReport ?? this.exportReport,
      organizeMode: organizeMode ?? this.organizeMode,
      qualityWidth: qualityWidth ?? this.qualityWidth,
      qualityHeight: qualityHeight ?? this.qualityHeight,
      convertHeicToPng: convertHeicToPng ?? this.convertHeicToPng,
      deleteOriginalHeic: deleteOriginalHeic ?? this.deleteOriginalHeic,
      preferVisualOrientation: preferVisualOrientation ?? this.preferVisualOrientation,
    );
  }
}

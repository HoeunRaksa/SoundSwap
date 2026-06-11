import 'dart:developer' as dev;
import 'dart:io';
import 'package:path/path.dart' as p;
import 'package:crypto/crypto.dart';
import 'package:soundswap/features/folder_organizer/data/models/organizer_options.dart';
import 'package:soundswap/features/folder_organizer/data/models/organizer_file_item.dart';
import 'package:soundswap/features/folder_organizer/data/models/organizer_history_record.dart';
import 'package:soundswap/shared/services/local_json_store.dart';
import 'package:soundswap/features/home/data/services/ffmpeg_service.dart';

/// Folders whose names are reserved for organizer output.
/// We never skip/delete these as source, but we do skip them when scanning
/// to avoid re-processing already-organized files.
const _reservedFolderNames = {
  'duplicates',
};

class OrganizerService {
  OrganizerService({
    LocalJsonStore? store,
    FfmpegService? ffmpegService,
  })  : _store = store ?? LocalJsonStore(),
        _ffmpegService = ffmpegService ?? FfmpegService();

  final LocalJsonStore _store;
  final FfmpegService _ffmpegService;
  static const _historyFileName = 'organizer_history.json';

  static const imageExtensions = {'jpg', 'jpeg', 'png', 'webp', 'gif', 'heic', 'heif'};
  static const videoExtensions = {'mp4', 'mov', 'mkv', 'avi', 'webm'};

  // ─── History ──────────────────────────────────────────────────────────────────

  Future<List<OrganizerHistoryRecord>> loadHistory() async {
    try {
      final values = await _store.readList(_historyFileName);
      return values
          .whereType<Map>()
          .map((v) => OrganizerHistoryRecord.fromJson(v.cast<String, Object?>()))
          .toList();
    } catch (_) {
      return [];
    }
  }

  Future<void> saveHistory(List<OrganizerHistoryRecord> records) async {
    await _store.writeList(_historyFileName, records.map((r) => r.toJson()).toList());
  }

  // ─── Options ──────────────────────────────────────────────────────────────────

  Future<OrganizerOptions> loadOptions() async {
    try {
      final map = await _store.readMap('organizer_options.json');
      if (map.isEmpty) return const OrganizerOptions();
      return OrganizerOptions.fromJson(map);
    } catch (_) {
      return const OrganizerOptions();
    }
  }

  Future<void> saveOptions(OrganizerOptions options) async {
    try {
      await _store.writeMap('organizer_options.json', options.toJson());
    } catch (_) {}
  }

  // ─── Quality helpers ──────────────────────────────────────────────────────────

  static MediaOrientation _orientationOf(int w, int h) {
    if (w == h) return MediaOrientation.square;
    if (h > w) return MediaOrientation.vertical;
    return MediaOrientation.landscape;
  }

  /// Returns orientation-based quality classification folder name.
  static String _classifyQuality(int w, int h, MediaOrientation finalOrientation) {
    if (finalOrientation == MediaOrientation.vertical) {
      // Portrait
      final minDim = w < h ? w : h;
      final maxDim = w > h ? w : h;
      if (minDim >= 1080 && maxDim >= 1920) {
        return 'portraitQuality';
      } else {
        return 'lowerPortrait';
      }
    } else if (finalOrientation == MediaOrientation.landscape) {
      // Landscape
      final minDim = w < h ? w : h;
      final maxDim = w > h ? w : h;
      if (maxDim >= 1920 && minDim >= 1080) {
        return 'landscapeQuality';
      } else {
        return 'lowerLandscape';
      }
    } else {
      // Square
      if (w >= 1080) {
        return 'squareQuality';
      } else {
        return 'lowerSquare';
      }
    }
  }

  // ─── Scan ─────────────────────────────────────────────────────────────────────

  /// Scans [rootPath] and produces a list of proposed [OrganizerFileItem]s.
  ///
  /// keepFolderStructure = true  (Case 2):
  ///   Recursively scan all subfolders.
  ///   Each file's destination is inside its OWN parent folder:
  ///     PageA/a.mp4 → PageA/videos/a.mp4
  ///
  /// keepFolderStructure = false (Case 1):
  ///   Recursively scan all subfolders.
  ///   Destination is always at root level:
  ///     PageA/a.mp4 → Root/videos/a.mp4
  Stream<Map<String, dynamic>> scanFolder({
    required String rootPath,
    required OrganizerOptions options,
    bool Function()? isCancelled,
  }) async* {
    final rootDir = Directory(rootPath);
    if (!rootDir.existsSync()) {
      throw FileSystemException('Root directory does not exist', rootPath);
    }

    final List<OrganizerFileItem> scannedItems = [];
    int foldersScanned = 0;
    int filesScanned = 0;
    int imagesCount = 0;
    int videosCount = 0;
    int filesSkipped = 0;

    dev.log(
      '[Organizer] Starting scan\n'
      '  Root path: $rootPath\n'
      '  Keep folder structure: ${options.keepFolderStructure}\n'
      '  Remove empty folders: ${options.removeEmptyFolders}\n'
      '  Organize mode: ${options.organizeMode.name}',
      name: 'OrganizerService',
    );

    // ── Collect all files recursively ─────────────────────────────────────────
    final queue = <Directory>[rootDir];

    while (queue.isNotEmpty) {
      if (isCancelled?.call() ?? false) {
        dev.log('[Organizer] Scan cancelled by user', name: 'OrganizerService');
        break;
      }

      final dir = queue.removeAt(0);
      foldersScanned++;

      yield {
        'status': 'scanning',
        'foldersScanned': foldersScanned,
        'filesScanned': filesScanned,
        'imagesCount': imagesCount,
        'videosCount': videosCount,
        'items': scannedItems,
      };

      try {
        for (final entity in dir.listSync(followLinks: false)) {
          final baseName = p.basename(entity.path);

          if (!options.includeHiddenFolders &&
              (baseName.startsWith('.') || baseName.startsWith('\$'))) {
            filesSkipped++;
            dev.log(
              '[Organizer] Skipped: ${entity.path}\n'
              '  Reason: Hidden file/folder',
              name: 'OrganizerService',
            );
            continue;
          }

          if (entity is Directory) {
            // Skip reserved output folders so we don't re-process organized files
            if (_reservedFolderNames.contains(baseName.toLowerCase())) {
              filesSkipped++;
              dev.log(
                '[Organizer] Skipped: ${entity.path}\n'
                '  Reason: Destination folder',
                name: 'OrganizerService',
              );
              continue;
            }
            queue.add(entity);
          } else if (entity is File) {
            final item = _fileToItem(entity, baseName);
            if (item != null) {
              if (item.fileType == FileItemType.image) {
                imagesCount++;
              } else {
                videosCount++;
              }
              filesScanned++;
              scannedItems.add(item);
              dev.log(
                '[Organizer] Scanned: ${entity.path}',
                name: 'OrganizerService',
              );
            } else {
              filesSkipped++;
              dev.log(
                '[Organizer] Skipped: ${entity.path}\n'
                '  Reason: Unsupported file type',
                name: 'OrganizerService',
              );
            }
          }
        }
      } catch (e) {
        filesSkipped++;
        dev.log(
          '[Organizer] Skipped directory: ${dir.path}\n'
          '  Reason: Inaccessible/Permission denied ($e)',
          name: 'OrganizerService',
        );
      }
    }

    // ── Duplicate detection ───────────────────────────────────────────────────

    if (!(isCancelled?.call() ?? false) && options.detectDuplicates && scannedItems.isNotEmpty) {
      int hashedCount = 0;
      for (final item in scannedItems) {
        if (isCancelled?.call() ?? false) break;
        yield {
          'status': 'hashing',
          'foldersScanned': foldersScanned,
          'filesScanned': filesScanned,
          'imagesCount': imagesCount,
          'videosCount': videosCount,
          'items': scannedItems,
          'hashedCount': hashedCount,
          'totalToHash': scannedItems.length,
        };

        try {
          final stream = File(item.originalPath).openRead();
          final hash = await md5.bind(stream).first;
          item.hash = hash.toString();
        } catch (e) {
          item.errorMessage = 'Hashing error: ${e.toString()}';
        }
        hashedCount++;
      }

      final Map<String, List<OrganizerFileItem>> hashGroups = {};
      for (final item in scannedItems) {
        final hash = item.hash;
        if (hash != null && hash.isNotEmpty) {
          hashGroups.putIfAbsent(hash, () => []).add(item);
        }
      }

      for (final group in hashGroups.values) {
        if (group.length > 1) {
          group.sort((a, b) => a.originalPath.length.compareTo(b.originalPath.length));
          final original = group.first;
          for (int i = 1; i < group.length; i++) {
            group[i].isDuplicate = true;
            group[i].duplicateOfPath = original.originalPath;
          }
        }
      }
    }

    // ── Quality probing ───────────────────────────────────────────────────────

    if (!(isCancelled?.call() ?? false) && options.organizeMode == OrganizerMode.byQuality && scannedItems.isNotEmpty) {
      int probedCount = 0;
      for (final item in scannedItems) {
        if (isCancelled?.call() ?? false) break;
        yield {
          'status': 'probing',
          'foldersScanned': foldersScanned,
          'filesScanned': filesScanned,
          'imagesCount': imagesCount,
          'videosCount': videosCount,
          'items': scannedItems,
          'probedCount': probedCount,
          'totalToProbe': scannedItems.length,
        };

        try {
          final dims = await _ffmpegService.probeVideoDimensions(item.originalPath);
          final displayW = dims.width;
          final displayH = dims.height;
          final rawW = dims.rawWidth;
          final rawH = dims.rawHeight;
          final rotation = dims.rotation;

          item.width = rawW;
          item.height = rawH;
          item.rotation = rotation;
          item.displayWidth = displayW;
          item.displayHeight = displayH;

          final metadataOrientation = _orientationOf(displayW, displayH);
          MediaOrientation? visualOrient;
          int? visualW;
          int? visualH;
          String visualReason = 'not analyzed';
          double visualConfidence = 0.0;

          if (item.fileType == FileItemType.video && options.preferVisualOrientation) {
            final visualRes = await _detectVisualOrientation(item.originalPath, displayW, displayH);
            visualOrient = visualRes.orientation;
            visualW = visualRes.visualWidth;
            visualH = visualRes.visualHeight;
            visualReason = visualRes.reason;
            visualConfidence = visualRes.confidence;
          }

          item.visualOrientation = visualOrient;

          // Priority: Visual orientation if enabled and confidently detected,
          // then rotation metadata, display width/height, raw fallback
          final MediaOrientation finalOrient;
          String orientSource;
          if (visualOrient != null && visualOrient != metadataOrientation) {
            finalOrient = visualOrient;
            orientSource = 'VISUAL (overrides metadata ${metadataOrientation.name})';
          } else if (visualOrient != null) {
            finalOrient = visualOrient;
            orientSource = 'visual (agrees with metadata)';
          } else {
            finalOrient = metadataOrientation;
            orientSource = 'metadata (${displayW}x$displayH)';
          }
          item.finalOrientation = finalOrient;
          item.orientation = finalOrient;

          final widthForQuality = visualW ?? displayW;
          final heightForQuality = visualH ?? displayH;
          item.qualityGroup = _classifyQuality(widthForQuality, heightForQuality, finalOrient);

          final orientName = finalOrient == MediaOrientation.vertical
              ? 'Portrait'
              : finalOrient == MediaOrientation.landscape
                  ? 'Landscape'
                  : 'Square';

          // Build a detailed reason string for the preview table
          final reasonParts = <String>[
            '$orientName ${widthForQuality}x$heightForQuality',
          ];
          if (visualOrient != null && visualOrient != metadataOrientation) {
            reasonParts.add('Visual: ${visualW}x$visualH ($visualReason)');
          } else if (visualOrient != null) {
            reasonParts.add('Visual confirms metadata');
          }
          reasonParts.add('→ ${item.qualityGroup}');
          item.reason = reasonParts.join(' | ');

          // Full diagnostic log
          dev.log(
            '[Organizer] QUALITY DIAGNOSTIC: ${p.basename(item.originalPath)}\n'
            '  Raw dimensions:     ${rawW}x$rawH\n'
            '  Rotation:           $rotation°\n'
            '  Display dimensions: ${displayW}x$displayH\n'
            '  Metadata orient:    ${metadataOrientation.name}\n'
            '  Visual detection:   ${visualOrient?.name ?? "null"} (confidence: ${visualConfidence.toStringAsFixed(2)})\n'
            '  Visual reason:      $visualReason\n'
            '  Visual dimensions:  ${visualW ?? "N/A"}x${visualH ?? "N/A"}\n'
            '  Orient source:      $orientSource\n'
            '  Final orientation:  ${finalOrient.name}\n'
            '  Quality dims used:  ${widthForQuality}x$heightForQuality\n'
            '  Quality folder:     ${item.qualityGroup}\n'
            '  Full reason:        ${item.reason}',
            name: 'OrganizerService',
          );
        } catch (e) {
          item.qualityGroup = 'lowerLandscape';
          item.orientation = null;
          item.visualOrientation = null;
          item.finalOrientation = null;
          item.reason = 'Resolution unknown → lowerLandscape';
          dev.log(
            '[Organizer] PROBE FAILED: ${p.basename(item.originalPath)} — $e',
            name: 'OrganizerService',
          );
        }
        probedCount++;
      }
    }

    // ── Calculate proposed changes ────────────────────────────────────────────

    calculateProposedChanges(scannedItems, rootPath, options);

    final finalStatus = (isCancelled?.call() ?? false) ? 'cancelled' : 'completed';

    dev.log(
      '[Organizer] Scan $finalStatus\n'
      '  Root path: $rootPath\n'
      '  Files scanned: $filesScanned\n'
      '  Files skipped: $filesSkipped\n'
      '  Images found: $imagesCount\n'
      '  Videos found: $videosCount',
      name: 'OrganizerService',
    );

    if (scannedItems.isEmpty) {
      final reason = checkNoFilesReason(rootPath, options);
      yield {
        'status': finalStatus,
        'foldersScanned': foldersScanned,
        'filesScanned': filesScanned,
        'imagesCount': imagesCount,
        'videosCount': videosCount,
        'items': scannedItems,
        'noFilesReason': reason,
      };
    } else {
      yield {
        'status': finalStatus,
        'foldersScanned': foldersScanned,
        'filesScanned': filesScanned,
        'imagesCount': imagesCount,
        'videosCount': videosCount,
        'items': scannedItems,
      };
    }
  }

  OrganizerFileItem? _fileToItem(File entity, String baseName) {
    final ext = p.extension(entity.path).replaceAll('.', '').toLowerCase();
    FileItemType? fileType;
    if (imageExtensions.contains(ext)) {
      fileType = FileItemType.image;
    } else if (videoExtensions.contains(ext)) {
      fileType = FileItemType.video;
    }
    if (fileType == null) return null;

    return OrganizerFileItem(
      originalPath: entity.path,
      fileName: baseName,
      fileType: fileType,
      sizeBytes: entity.lengthSync(),
    );
  }

  // ─── Calculate proposed changes ───────────────────────────────────────────────

  /// Determines the action and destination path for every item.
  ///
  /// keepFolderStructure = false (Case 1):
  ///   All files go to [rootPath]/images/ or [rootPath]/videos/ (or with quality group).
  ///
  /// keepFolderStructure = true (Case 2):
  ///   Files go to their source folder's images/ or videos/ subdirectory.
  void calculateProposedChanges(
    List<OrganizerFileItem> items,
    String rootPath,
    OrganizerOptions options,
  ) {
    final Set<String> plannedPaths = {};

    // ── 1. Handle duplicates ───────────────────────────────────────────────────
    if (options.detectDuplicates) {
      for (final item in items) {
        if (!item.isDuplicate) continue;

        if (options.duplicateAction == DuplicateAction.move) {
          item.action = FileItemAction.duplicateMove;
          final duplicatesDir = p.join(rootPath, 'Duplicates');
          String targetPath = p.join(duplicatesDir, item.fileName);
          if (_pathOccupied(targetPath, plannedPaths)) {
            targetPath = _makeUniquePath(duplicatesDir, item.fileName, plannedPaths, '-duplicate');
          }
          item.newPath = targetPath;
          plannedPaths.add(p.normalize(targetPath).toLowerCase());
        } else if (options.duplicateAction == DuplicateAction.delete) {
          item.action = FileItemAction.duplicateDelete;
          item.newPath = null;
        } else {
          item.action = FileItemAction.skip;
          item.newPath = item.originalPath;
          plannedPaths.add(p.normalize(item.originalPath).toLowerCase());
        }
      }
    }

    // ── 2. Group remaining files by their destination directory ────────────────
    final Map<String, List<OrganizerFileItem>> destinationGroups = {};

    for (final item in items) {
      if (item.isDuplicate && options.duplicateAction != DuplicateAction.skip) {
        continue;
      }

      String targetDir;

      if (!options.organizeFiles) {
        // No organization — keep in place
        targetDir = p.dirname(item.originalPath);
      } else if (!options.keepFolderStructure) {
        // Case 1: everything goes to root
        targetDir = _buildTargetDir(rootPath, item, options);
      } else {
        // Case 2: organize inside each file's own parent
        final parent = p.dirname(item.originalPath);
        final originalParent = _getOriginalParent(parent, rootPath);
        targetDir = _buildTargetDir(originalParent, item, options);
      }

      destinationGroups.putIfAbsent(targetDir, () => []).add(item);
    }

    // ── 3. Assign actions and new paths ───────────────────────────────────────
    destinationGroups.forEach((targetDir, groupItems) {
      int imageCounter = options.startNumber;
      int videoCounter = options.startNumber;

      for (final item in groupItems) {
        final ext = p.extension(item.originalPath).toLowerCase().replaceAll('.', '');
        final isHeic = ext == 'heic' || ext == 'heif';
        final shouldConvert = isHeic && options.convertHeicToPng;
        final outputExt = shouldConvert ? '.png' : p.extension(item.originalPath);

        if (!options.organizeFiles) {
          if (shouldConvert) {
            final targetPath = p.join(targetDir, '${p.basenameWithoutExtension(item.fileName)}.png');
            item.newPath = _pathOccupied(targetPath, plannedPaths)
                ? _makeUniquePath(targetDir, '${p.basenameWithoutExtension(item.fileName)}.png', plannedPaths, '')
                : targetPath;
            item.action = FileItemAction.convert;
            plannedPaths.add(p.normalize(item.newPath!).toLowerCase());
          } else {
            item.action = FileItemAction.skip;
            item.newPath = item.originalPath;
            plannedPaths.add(p.normalize(item.originalPath).toLowerCase());
          }
          continue;
        }

        if (options.renameFiles && options.renameMode != RenameMode.keepNames) {
          String newFileName;

          if (options.renameMode == RenameMode.custom) {
            final prefix = item.fileType == FileItemType.image
                ? options.customImagePrefix
                : options.customVideoPrefix;
            String proposed;
            do {
              final numStr =
                  (item.fileType == FileItemType.image ? imageCounter : videoCounter)
                      .toString()
                      .padLeft(options.numberPadding, '0');
              proposed = '$prefix-$numStr$outputExt';
              if (item.fileType == FileItemType.image) {
                imageCounter++;
              } else {
                videoCounter++;
              }
            } while (_pathOccupied(p.join(targetDir, proposed), plannedPaths));
            newFileName = proposed;
          } else {
            // keepPrefix
            final basePrefix = p.basenameWithoutExtension(item.fileName);
            int localCounter = options.startNumber;
            String proposed;
            do {
              final numStr = localCounter.toString().padLeft(options.numberPadding, '0');
              proposed = '$basePrefix-$numStr$outputExt';
              localCounter++;
            } while (_pathOccupied(p.join(targetDir, proposed), plannedPaths));
            newFileName = proposed;
          }

          item.newPath = p.join(targetDir, newFileName);
          if (shouldConvert) {
            item.action = FileItemAction.convert;
          } else {
            final isSame = _isSamePath(item.newPath!, item.originalPath);
            item.action = isSame
                ? (options.organizeFiles ? FileItemAction.alreadyOrganized : FileItemAction.skip)
                : (targetDir == p.dirname(item.originalPath)
                    ? FileItemAction.rename
                    : FileItemAction.moveAndRename);
          }
        } else {
          // No rename — just move (or skip if already in place)
          final newBaseName = shouldConvert
              ? '${p.basenameWithoutExtension(item.fileName)}.png'
              : item.fileName;
          String targetPath = p.join(targetDir, newBaseName);
          if (!_isSamePath(targetPath, item.originalPath) && _pathOccupied(targetPath, plannedPaths)) {
            targetPath = _makeUniquePath(targetDir, newBaseName, plannedPaths, '');
          }
          item.newPath = targetPath;
          
          if (shouldConvert) {
            item.action = FileItemAction.convert;
          } else {
            final isSame = _isSamePath(targetPath, item.originalPath);
            item.action = isSame
                ? (options.organizeFiles ? FileItemAction.alreadyOrganized : FileItemAction.skip)
                : FileItemAction.move;
            if (isSame) {
              item.newPath = item.originalPath;
            }
          }
        }

        plannedPaths.add(p.normalize(item.newPath!).toLowerCase());
      }
    });

    for (final item in items) {
      if (item.isDuplicate) {
        item.reason = 'Duplicate of ${p.basename(item.duplicateOfPath ?? "")}';
      } else if (item.reason == null || item.reason!.isEmpty) {
        if (options.organizeMode == OrganizerMode.byQuality) {
          item.reason = 'Resolution unknown';
        } else {
          item.reason = item.fileType == FileItemType.image ? 'Image file' : 'Video file';
        }
      }
    }

    for (final item in items) {
      final selectedFolder = item.newPath != null 
          ? p.dirname(item.newPath!) 
          : 'None (Skipped/Deleted)';
          
      if (item.fileType == FileItemType.video) {
        final visualStr = item.visualOrientation?.name ?? 'not detected';
        dev.log(
          '[Organizer] Video Debug:\n'
          '  - path: ${item.originalPath}\n'
          '  - raw size: ${item.width ?? "unknown"}x${item.height ?? "unknown"}\n'
          '  - rotation: ${item.rotation ?? 0}\n'
          '  - display size: ${item.displayWidth ?? "unknown"}x${item.displayHeight ?? "unknown"}\n'
          '  - visual detection result: $visualStr\n'
          '  - selected quality folder: $selectedFolder\n'
          '  - reason: ${item.reason}',
          name: 'OrganizerService',
        );
      } else {
        dev.log(
          '[Organizer] File Debug:\n'
          '  - path: ${item.originalPath}\n'
          '  - detected width: ${item.width ?? "unknown"}\n'
          '  - detected height: ${item.height ?? "unknown"}\n'
          '  - orientation: ${item.orientation?.name ?? "unknown"}\n'
          '  - selected folder: $selectedFolder\n'
          '  - reason: ${item.reason}',
          name: 'OrganizerService',
        );
      }
    }
  }

  /// Builds the destination directory path for [item] relative to [baseDir].
  String _buildTargetDir(String baseDir, OrganizerFileItem item, OrganizerOptions options) {
    if (options.organizeMode == OrganizerMode.byQuality) {
      String group = item.qualityGroup ?? 'lowerLandscape';
      if (group == 'unknown' || 
          group == 'largeSize' || 
          group == 'goodQuality' || 
          group == 'lowerQuality' || 
          group == 'lowerVertical') {
        group = 'lowerLandscape';
      }
      return item.fileType == FileItemType.image
          ? p.join(baseDir, 'images', group)
          : p.join(baseDir, 'videos', group);
    } else {
      // Type mode
      final parentName = p.basename(p.dirname(item.originalPath));
      // Skip if already inside images/ or videos/
      if (parentName == 'images' || parentName == 'videos') {
        return p.dirname(item.originalPath);
      }
      return item.fileType == FileItemType.image
          ? p.join(baseDir, 'images')
          : p.join(baseDir, 'videos');
    }
  }

  bool _pathOccupied(String path, Set<String> plannedPaths) {
    final norm = p.normalize(path).toLowerCase();
    return File(path).existsSync() || plannedPaths.contains(norm);
  }

  String _makeUniquePath(
    String dir,
    String fileName,
    Set<String> plannedPaths,
    String suffix,
  ) {
    final ext = p.extension(fileName);
    final base = p.basenameWithoutExtension(fileName);
    int counter = 1;
    String candidate;
    do {
      candidate = p.join(dir, '$base$suffix-$counter$ext');
      counter++;
    } while (_pathOccupied(candidate, plannedPaths));
    return candidate;
  }

  // ─── Apply changes ─────────────────────────────────────────────────────────────

  Stream<Map<String, dynamic>> applyChanges({
    required List<OrganizerFileItem> items,
    required String rootPath,
    required OrganizerOptions options,
  }) async* {
    final List<OrganizerHistoryEntry> historyEntries = [];

    final int total = items.length;
    int processed = 0;
    int imagesMoved = 0;
    int videosMoved = 0;
    int filesRenamed = 0;
    int duplicatesMoved = 0;
    int duplicatesDeleted = 0;
    int skipped = 0;
    int failed = 0;
    int heicConverted = 0;
    int heicDeleted = 0;
    int heicFailed = 0;

    yield _applyProgress(0.0, imagesMoved, videosMoved, filesRenamed,
        duplicatesMoved, duplicatesDeleted, skipped, failed, heicConverted: heicConverted, heicDeleted: heicDeleted, heicFailed: heicFailed);

    for (final item in items) {
      if (item.action == FileItemAction.skip) {
        skipped++;
        processed++;
        yield _applyProgress(processed / total, imagesMoved, videosMoved,
            filesRenamed, duplicatesMoved, duplicatesDeleted, skipped, failed, heicConverted: heicConverted, heicDeleted: heicDeleted, heicFailed: heicFailed);
        continue;
      }

      try {
        final originalFile = File(item.originalPath);
        if (!originalFile.existsSync() && item.action != FileItemAction.duplicateDelete) {
          throw FileSystemException('Source file not found', item.originalPath);
        }

        if (item.action == FileItemAction.duplicateDelete) {
          await originalFile.delete();
          duplicatesDeleted++;
          historyEntries.add(_historyEntry(item));
        } else if (item.action == FileItemAction.convert) {
          final targetPath = item.newPath!;
          final targetDir = Directory(p.dirname(targetPath));
          if (!targetDir.existsSync()) {
            await targetDir.create(recursive: true);
          }

          try {
            dev.log('[Organizer] HEIC found: ${item.originalPath}', name: 'OrganizerService');

            await _ffmpegService.convertHeicToPng(item.originalPath, targetPath);
            
            // Verify PNG exists
            final outFile = File(targetPath);
            if (!outFile.existsSync()) {
              throw FileSystemException('Output PNG file does not exist', targetPath);
            }
            // Verify PNG size > 0
            if (outFile.lengthSync() <= 0) {
              throw FileSystemException('Output PNG file is empty (0 bytes)', targetPath);
            }
            // Verify PNG can be opened
            try {
              final fd = await outFile.open(mode: FileMode.read);
              await fd.close();
            } catch (e) {
              throw FileSystemException('Output PNG file cannot be opened/read: $e', targetPath);
            }

            dev.log('[Organizer] PNG created: $targetPath', name: 'OrganizerService');
            heicConverted++;
            imagesMoved++;
            
            if (options.deleteOriginalHeic) {
              await originalFile.delete();
              heicDeleted++;
              dev.log('[Organizer] Original deleted: ${item.originalPath}', name: 'OrganizerService');
            }

            historyEntries.add(_historyEntry(item));
          } catch (e) {
            heicFailed++;
            failed++;
            item.action = FileItemAction.error;
            item.errorMessage = 'HEIC to PNG conversion failed: $e';
            dev.log('[Organizer] Failed conversions: HEIC/HEIF conversion failed: $e', name: 'OrganizerService');
            historyEntries.add(OrganizerHistoryEntry(
              originalPath: item.originalPath,
              newPath: item.newPath,
              action: 'error',
              fileType: item.fileType.name,
            ));
          }
        } else {
          final targetPath = item.newPath!;
          final targetDir = Directory(p.dirname(targetPath));
          if (!targetDir.existsSync()) {
            await targetDir.create(recursive: true);
          }

          await _moveFile(originalFile, targetPath);

          if (item.action == FileItemAction.duplicateMove) {
            duplicatesMoved++;
          } else {
            if (item.action == FileItemAction.move ||
                item.action == FileItemAction.moveAndRename) {
              if (item.fileType == FileItemType.image) {
                imagesMoved++;
              } else {
                videosMoved++;
              }
            }
            if (item.action == FileItemAction.rename ||
                item.action == FileItemAction.moveAndRename) {
              filesRenamed++;
            }
          }

          historyEntries.add(_historyEntry(item));
        }
      } catch (e) {
        failed++;
        item.action = FileItemAction.error;
        item.errorMessage = e.toString();
        historyEntries.add(OrganizerHistoryEntry(
          originalPath: item.originalPath,
          newPath: item.newPath,
          action: 'error',
          fileType: item.fileType.name,
        ));
      }

      processed++;
      yield _applyProgress(processed / total, imagesMoved, videosMoved,
          filesRenamed, duplicatesMoved, duplicatesDeleted, skipped, failed, heicConverted: heicConverted, heicDeleted: heicDeleted, heicFailed: heicFailed);
    }

    // ── Empty folder cleanup ───────────────────────────────────────────────────

    int emptyFoldersRemoved = 0;
    int emptyFoldersSkipped = 0;

    if (options.removeEmptyFolders) {
      yield {
        'status': 'cleaning',
        'progress': 1.0,
        'imagesMoved': imagesMoved,
        'videosMoved': videosMoved,
        'filesRenamed': filesRenamed,
        'duplicatesMoved': duplicatesMoved,
        'duplicatesDeleted': duplicatesDeleted,
        'skipped': skipped,
        'failed': failed,
        'emptyFoldersRemoved': emptyFoldersRemoved,
        'emptyFoldersSkipped': emptyFoldersSkipped,
        'heicConverted': heicConverted,
        'heicDeleted': heicDeleted,
        'heicFailed': heicFailed,
      };

      final result = await _removeEmptyFolders(rootPath, options);
      emptyFoldersRemoved = result['removed'] as int;
      emptyFoldersSkipped = result['skipped'] as int;
    }

    dev.log(
      '[Organizer] Apply complete\n'
      '  Root: $rootPath\n'
      '  keepFolderStructure: ${options.keepFolderStructure}\n'
      '  Images moved: $imagesMoved\n'
      '  Videos moved: $videosMoved\n'
      '  Failed: $failed\n'
      '  Empty folders removed: $emptyFoldersRemoved\n'
      '  Empty folders skipped: $emptyFoldersSkipped',
      name: 'OrganizerService',
    );

    // ── Save history ───────────────────────────────────────────────────────────

    final sessionRecord = OrganizerHistoryRecord(
      id: DateTime.now().millisecondsSinceEpoch.toString(),
      timestamp: DateTime.now(),
      rootFolder: rootPath,
      entries: historyEntries,
      emptyFoldersRemoved: emptyFoldersRemoved,
      emptyFoldersSkipped: emptyFoldersSkipped,
    );

    final historyList = await loadHistory();
    historyList.insert(0, sessionRecord);
    await saveHistory(historyList);

    // ── Export report ──────────────────────────────────────────────────────────

    String? reportPath;
    if (options.exportReport) {
      try {
        final reportText = generateReportContent(sessionRecord, 'txt');
        final reportDir = Directory(p.join(rootPath, 'Reports'));
        if (!reportDir.existsSync()) {
          await reportDir.create(recursive: true);
        }
        final reportFile = File(p.join(
          reportDir.path,
          'organizer-report-${sessionRecord.id}.txt',
        ));
        await reportFile.writeAsString(reportText);
        reportPath = reportFile.path;
      } catch (_) {}
    }

    yield {
      'status': 'completed',
      'record': sessionRecord,
      'reportPath': reportPath,
      'imagesMoved': imagesMoved,
      'videosMoved': videosMoved,
      'filesRenamed': filesRenamed,
      'duplicatesMoved': duplicatesMoved,
      'duplicatesDeleted': duplicatesDeleted,
      'skipped': skipped,
      'failed': failed,
      'emptyFoldersRemoved': emptyFoldersRemoved,
      'emptyFoldersSkipped': emptyFoldersSkipped,
      'heicConverted': heicConverted,
      'heicDeleted': heicDeleted,
      'heicFailed': heicFailed,
    };
  }

  Map<String, dynamic> _applyProgress(
    double progress,
    int imagesMoved,
    int videosMoved,
    int filesRenamed,
    int duplicatesMoved,
    int duplicatesDeleted,
    int skipped,
    int failed, {
    int heicConverted = 0,
    int heicDeleted = 0,
    int heicFailed = 0,
  }) =>
      {
        'status': 'applying',
        'progress': progress,
        'imagesMoved': imagesMoved,
        'videosMoved': videosMoved,
        'filesRenamed': filesRenamed,
        'duplicatesMoved': duplicatesMoved,
        'duplicatesDeleted': duplicatesDeleted,
        'skipped': skipped,
        'failed': failed,
        'emptyFoldersRemoved': 0,
        'emptyFoldersSkipped': 0,
        'heicConverted': heicConverted,
        'heicDeleted': heicDeleted,
        'heicFailed': heicFailed,
      };

  OrganizerHistoryEntry _historyEntry(OrganizerFileItem item) {
    return OrganizerHistoryEntry(
      originalPath: item.originalPath,
      newPath: item.newPath,
      action: item.action.name,
      fileType: item.fileType.name,
    );
  }

  Future<void> _moveFile(File file, String targetPath) async {
    try {
      await file.rename(targetPath);
    } on FileSystemException {
      // Fallback for cross-volume moves on Windows
      await file.copy(targetPath);
      await file.delete();
    }
  }

  // ─── Empty folder cleanup ─────────────────────────────────────────────────────

  /// Never delete these folder names, no matter what.
  static const _protectedFolderNames = {
    'images',
    'videos',
    'portraitquality',
    'landscapequality',
    'squarequality',
    'lowerportrait',
    'lowerlandscape',
    'lowersquare',
    'unknown',
    'duplicates',
    'reports',
  };

  /// Recursively removes empty folders under [rootPath], deepest-first.
  /// Never removes [rootPath] itself nor any protected folder names.
  Future<Map<String, int>> _removeEmptyFolders(
    String rootPath,
    OrganizerOptions options,
  ) async {
    final rootNorm = _normPath(rootPath);
    int removed = 0;
    int skipped = 0;

    // Collect all subdirectories under root
    final List<String> allDirs = [];
    try {
      final queue = <Directory>[Directory(rootPath)];
      while (queue.isNotEmpty) {
        final dir = queue.removeAt(0);
        for (final entity in dir.listSync(followLinks: false)) {
          if (entity is Directory) {
            allDirs.add(entity.path);
            queue.add(entity);
          }
        }
      }
    } catch (_) {}

    // Sort deepest first (longest path first)
    allDirs.sort((a, b) => b.length.compareTo(a.length));

    for (final dirPath in allDirs) {
      final normDir = _normPath(dirPath);

      // Never delete root
      if (normDir == rootNorm) continue;

      // Never delete protected folder names
      final baseName = p.basename(dirPath).toLowerCase();
      if (_protectedFolderNames.contains(baseName)) {
        skipped++;
        continue;
      }

      // Only delete if completely empty (no files, no subdirs, no hidden)
      try {
        final dir = Directory(dirPath);
        if (!dir.existsSync()) continue;

        final contents = dir.listSync(followLinks: false);
        if (contents.isEmpty) {
          await dir.delete();
          removed++;
          dev.log('[Organizer] Removed empty folder: $dirPath', name: 'OrganizerService');
        } else {
          skipped++;
        }
      } catch (e) {
        skipped++;
        dev.log('[Organizer] Could not remove folder $dirPath: $e', name: 'OrganizerService');
      }
    }

    return {'removed': removed, 'skipped': skipped};
  }

  String _normPath(String path) {
    return p.normalize(path).toLowerCase();
  }

  // ─── Undo ─────────────────────────────────────────────────────────────────────

  Future<Map<String, dynamic>> undoOperation(OrganizerHistoryRecord record) async {
    int undone = 0;
    int failed = 0;
    final List<String> errors = [];
    final Set<String> potentiallyEmptyDirs = {};

    for (final entry in record.entries) {
      if (entry.action == 'skip' || entry.action == 'error') continue;

      if (entry.action == 'duplicateDelete') {
        failed++;
        errors.add('Cannot restore permanently deleted: ${entry.originalPath}');
        continue;
      }

      final currentPath = entry.newPath;
      if (currentPath == null) continue;

      final file = File(currentPath);
      if (!file.existsSync()) {
        failed++;
        errors.add('File not found at: $currentPath');
        continue;
      }

      try {
        if (entry.action == 'convert') {
          final originalExists = File(entry.originalPath).existsSync();
          if (originalExists) {
            // Revert conversion by deleting the created PNG
            await file.delete();
            undone++;
          } else {
            // Original HEIC was deleted and cannot be restored
            failed++;
            errors.add('Cannot restore original HEIC (permanently deleted): ${entry.originalPath}');
          }
          potentiallyEmptyDirs.add(p.dirname(currentPath));
          continue;
        }

        final originalDir = Directory(p.dirname(entry.originalPath));
        if (!originalDir.existsSync()) {
          await originalDir.create(recursive: true);
        }
        await _moveFile(file, entry.originalPath);
        potentiallyEmptyDirs.add(p.dirname(currentPath));
        undone++;
      } catch (e) {
        failed++;
        errors.add('Failed to restore ${p.basename(currentPath)}: $e');
      }
    }

    // Clean up empty directories left after undo
    for (final dirPath in potentiallyEmptyDirs) {
      try {
        final dir = Directory(dirPath);
        if (dir.existsSync() && dir.listSync().isEmpty) {
          await dir.delete();
          final parent = dir.parent;
          if (parent.existsSync() && parent.listSync().isEmpty) {
            await parent.delete();
          }
        }
      } catch (_) {}
    }

    record.undoApplied = true;
    final historyList = await loadHistory();
    final index = historyList.indexWhere((r) => r.id == record.id);
    if (index != -1) {
      historyList[index] = record;
      await saveHistory(historyList);
    }

    return {
      'undoneCount': undone,
      'failedCount': failed,
      'errors': errors,
    };
  }

  // ─── Report ───────────────────────────────────────────────────────────────────

  String generateReportContent(OrganizerHistoryRecord record, String format) {
    if (format.toLowerCase() == 'csv') {
      final buffer = StringBuffer();
      buffer.writeln('Original Path,New Path,Type,Action,Status');
      for (final entry in record.entries) {
        final statusStr = entry.action == 'error' ? 'Failed' : 'Success';
        buffer.writeln(
          '"${entry.originalPath}","${entry.newPath ?? 'DELETED'}","${entry.fileType}","${entry.action}","$statusStr"',
        );
      }
      buffer.writeln('');
      buffer.writeln('Empty Folders Removed,${record.emptyFoldersRemoved}');
      buffer.writeln('Empty Folders Skipped,${record.emptyFoldersSkipped}');
      return buffer.toString();
    } else {
      final buffer = StringBuffer();
      buffer.writeln('==================================================');
      buffer.writeln('SOUNDSWAP FOLDER ORGANIZER REPORT');
      buffer.writeln('Session ID: ${record.id}');
      buffer.writeln('Date: ${record.timestamp}');
      buffer.writeln('Root Folder: ${record.rootFolder}');
      buffer.writeln('==================================================\n');

      final moved = record.entries
          .where((e) => e.action == 'move' || e.action == 'moveAndRename')
          .toList();
      final renamed = record.entries
          .where((e) => e.action == 'rename' || e.action == 'moveAndRename')
          .toList();
      final duplicates =
          record.entries.where((e) => e.action.startsWith('duplicate')).toList();
      final errorEntries = record.entries.where((e) => e.action == 'error').toList();

      final heicEntries = record.entries.where((e) {
        final ext = p.extension(e.originalPath).replaceAll('.', '').toLowerCase();
        return ext == 'heic' || ext == 'heif';
      }).toList();

      buffer.writeln('SUMMARY:');
      buffer.writeln('  Total Actions:        ${record.entries.length}');
      buffer.writeln('  Files Moved:          ${moved.length}');
      buffer.writeln('  Files Renamed:        ${renamed.length}');
      buffer.writeln('  Duplicates Processed: ${duplicates.length}');
      if (heicEntries.isNotEmpty) {
        final heicFound = heicEntries.length;
        final heicConverted = heicEntries.where((e) => e.action == 'convert').length;
        final heicDeleted = heicEntries.where((e) => e.action == 'convert' && !File(e.originalPath).existsSync()).length;
        final heicFailed = heicEntries.where((e) => e.action == 'error').length;
        buffer.writeln('  HEIC Files Found:     $heicFound');
        buffer.writeln('  HEIC Converted:       $heicConverted');
        buffer.writeln('  HEIC Deleted:         $heicDeleted');
        buffer.writeln('  HEIC Failed:          $heicFailed');
      }
      buffer.writeln('  Errors:               ${errorEntries.length}');
      buffer.writeln('  Empty Folders Removed: ${record.emptyFoldersRemoved}');
      buffer.writeln('  Empty Folders Skipped: ${record.emptyFoldersSkipped}');
      buffer.writeln('\n--------------------------------------------------');

      final converted = record.entries.where((e) => e.action == 'convert').toList();
      if (converted.isNotEmpty) {
        buffer.writeln('\nCONVERTED FILES (HEIC to PNG):');
        for (final e in converted) {
          buffer.writeln(
              '  [${e.fileType.toUpperCase()}] ${p.basename(e.originalPath)} → ${e.newPath}');
        }
      }
      if (moved.isNotEmpty) {
        buffer.writeln('\nMOVED FILES:');
        for (final e in moved) {
          buffer.writeln(
              '  [${e.fileType.toUpperCase()}] ${p.basename(e.originalPath)} → ${e.newPath}');
        }
      }
      if (renamed.isNotEmpty) {
        buffer.writeln('\nRENAMED FILES:');
        for (final e in renamed) {
          buffer.writeln(
              '  [${e.fileType.toUpperCase()}] ${p.basename(e.originalPath)} → ${p.basename(e.newPath ?? "")}');
        }
      }
      if (duplicates.isNotEmpty) {
        buffer.writeln('\nDUPLICATE ACTIONS:');
        for (final e in duplicates) {
          final act = e.action == 'duplicateDelete' ? 'Permanently Deleted' : 'Moved to Duplicates/';
          buffer.writeln('  [${e.fileType.toUpperCase()}] ${e.originalPath} → $act');
        }
      }
      if (errorEntries.isNotEmpty) {
        buffer.writeln('\nERRORS:');
        for (final e in errorEntries) {
          buffer.writeln('  Failed: ${e.originalPath}');
        }
      }

      return buffer.toString();
    }
  }

  bool _isInsideDestination(String path, String rootPath) {
    final relPath = p.relative(path, from: rootPath);
    final parts = p.split(relPath);
    for (final part in parts) {
      if (_reservedFolderNames.contains(part.toLowerCase())) {
        return true;
      }
    }
    return false;
  }

  String checkNoFilesReason(String rootPath, OrganizerOptions options) {
    final rootDir = Directory(rootPath);
    if (!rootDir.existsSync()) {
      return 'No supported media files found';
    }

    bool hasOtherFilesOrDirs = false;
    bool hasMediaInDestinations = false;
    bool hasDestinations = false;

    final queue = <Directory>[rootDir];
    while (queue.isNotEmpty) {
      final dir = queue.removeAt(0);
      try {
        for (final entity in dir.listSync(followLinks: false)) {
          final baseName = p.basename(entity.path);
          if (!options.includeHiddenFolders &&
              (baseName.startsWith('.') || baseName.startsWith('\$'))) {
            continue;
          }

          final isDest = _isInsideDestination(entity.path, rootPath);

          if (entity is Directory) {
            if (isDest) {
              hasDestinations = true;
            } else {
              hasOtherFilesOrDirs = true;
            }
            queue.add(entity);
          } else if (entity is File) {
            if (isDest) {
              final ext = p.extension(entity.path).replaceAll('.', '').toLowerCase();
              if (imageExtensions.contains(ext) || videoExtensions.contains(ext)) {
                hasMediaInDestinations = true;
              }
            } else {
              hasOtherFilesOrDirs = true;
            }
          }
        }
      } catch (_) {}
    }

    if (hasDestinations && !hasOtherFilesOrDirs) {
      return 'Only destination folders remain';
    } else if (hasMediaInDestinations) {
      return 'All files already organized';
    } else {
      return 'No supported media files found';
    }
  }

  bool _isSamePath(String path1, String path2) {
    return p.normalize(path1).toLowerCase() == p.normalize(path2).toLowerCase();
  }

  String _getOriginalParent(String path, String rootPath) {
    final rootNorm = p.normalize(rootPath).toLowerCase();
    String current = p.normalize(path);
    
    while (true) {
      final currentNorm = current.toLowerCase();
      if (currentNorm == rootNorm || !currentNorm.startsWith(rootNorm)) {
        break;
      }
      final baseName = p.basename(current).toLowerCase();
      if (baseName == 'images' ||
          baseName == 'videos' ||
          baseName == 'portraitquality' ||
          baseName == 'landscapequality' ||
          baseName == 'squarequality' ||
          baseName == 'lowerportrait' ||
          baseName == 'lowerlandscape' ||
          baseName == 'lowersquare' ||
          baseName == 'unknown' ||
          baseName == 'duplicates') {
        current = p.dirname(current);
      } else {
        break;
      }
    }
    return current;
  }

  /// Detects the visual orientation of a video by analyzing its actual content area.
  ///
  /// Uses two methods:
  /// 1. **FFmpeg cropdetect** (primary) — detects the actual content rectangle even with
  ///    colored/blurred side bars, not just black bars.
  /// 2. **Raw frame pixel analysis** (fallback) — analyzes a 64x64 thumbnail for
  ///    uniform border regions.
  ///
  /// Only returns a non-null orientation if meaningful borders (pillarbox/letterbox)
  /// are actually detected. If no bars are found, returns null so that metadata-based
  /// orientation is used instead.
  Future<VisualDetectionResult> _detectVisualOrientation(
    String videoPath,
    int originalWidth,
    int originalHeight,
  ) async {
    // ── Method 1: cropdetect ─────────────────────────────────────────────────
    try {
      final crop = await _ffmpegService.detectCropArea(videoPath);
      if (crop != null && crop.cropWidth > 0 && crop.cropHeight > 0) {
        final cropW = crop.cropWidth;
        final cropH = crop.cropHeight;

        // Check if cropdetect found significant borders
        // At least 5% of the frame width or height must be cropped to count
        final widthDiffRatio = (originalWidth - cropW) / originalWidth;
        final heightDiffRatio = (originalHeight - cropH) / originalHeight;
        final hasSideBars = widthDiffRatio > 0.05;
        final hasTopBottomBars = heightDiffRatio > 0.05;

        dev.log(
          '[Organizer] cropdetect: ${crop.toString()}\n'
          '  Original: ${originalWidth}x$originalHeight\n'
          '  Crop area: ${cropW}x$cropH\n'
          '  Width cropped: ${(widthDiffRatio * 100).toStringAsFixed(1)}%\n'
          '  Height cropped: ${(heightDiffRatio * 100).toStringAsFixed(1)}%\n'
          '  Side bars: $hasSideBars  Top/Bottom bars: $hasTopBottomBars',
          name: 'OrganizerService',
        );

        if (hasSideBars || hasTopBottomBars) {
          // Bars detected — use the crop dimensions for orientation
          final MediaOrientation cropOrientation;
          if (cropH > cropW) {
            cropOrientation = MediaOrientation.vertical;
          } else if (cropW > cropH) {
            cropOrientation = MediaOrientation.landscape;
          } else {
            cropOrientation = MediaOrientation.square;
          }

          final metaOrientation = _orientationOf(originalWidth, originalHeight);
          // Only override if the visual orientation differs from metadata
          if (cropOrientation != metaOrientation) {
            return VisualDetectionResult(
              orientation: cropOrientation,
              confidence: 0.95,
              reason: 'cropdetect: content ${cropW}x$cropH inside ${originalWidth}x$originalHeight frame',
              visualWidth: cropW,
              visualHeight: cropH,
            );
          } else {
            // Same orientation as metadata — still report the cropped dimensions
            return VisualDetectionResult(
              orientation: cropOrientation,
              confidence: 0.90,
              reason: 'cropdetect: content ${cropW}x$cropH (same orientation as metadata)',
              visualWidth: cropW,
              visualHeight: cropH,
            );
          }
        }

        // No significant bars — cropdetect agrees with full frame
        dev.log(
          '[Organizer] cropdetect: no significant bars detected, crop area is ~full frame',
          name: 'OrganizerService',
        );
      }
    } catch (e) {
      dev.log(
        '[Organizer] cropdetect failed, falling back to raw frame analysis: $e',
        name: 'OrganizerService',
      );
    }

    // ── Method 2: Raw frame pixel analysis (fallback) ────────────────────────
    final tempName = 'temp_frame_${DateTime.now().microsecondsSinceEpoch}.raw';
    final tempPath = p.join(Directory.current.path, tempName);

    try {
      const size = 64;
      final bytes = await _ffmpegService.extractRawFrame(videoPath, tempPath, size: size);
      final expectedBytes = size * size * 3;
      if (bytes == null || bytes.length < expectedBytes) {
        return const VisualDetectionResult(
          orientation: null,
          confidence: 0.0,
          reason: 'Insufficient raw frame bytes',
        );
      }

      // Calculate per-column and per-row average brightness
      // A "uniform" column or row (bar area) will have low variance
      final colBrightness = List<double>.filled(size, 0);
      final rowBrightness = List<double>.filled(size, 0);

      for (int y = 0; y < size; y++) {
        for (int x = 0; x < size; x++) {
          final idx = (y * size + x) * 3;
          final brightness = (bytes[idx] + bytes[idx + 1] + bytes[idx + 2]) / 3.0;
          colBrightness[x] += brightness / size; // Average per column
          rowBrightness[y] += brightness / size; // Average per row
        }
      }

      // Detect uniform border columns (left/right bars)
      // A bar region has columns where brightness is very uniform (low std deviation)
      // compared to the content area
      int leftBarEnd = 0;
      int rightBarStart = size;

      // Find left bar: columns from left edge with very low brightness or very uniform brightness
      for (int x = 0; x < size ~/ 2; x++) {
        // Check if this column is "bar-like" by comparing to its neighbors
        if (x < size - 1) {
          final diff = (colBrightness[x] - colBrightness[x + 1]).abs();
          // Also check column variance
          double colVariance = 0;
          for (int y = 0; y < size; y++) {
            final idx = (y * size + x) * 3;
            final b = (bytes[idx] + bytes[idx + 1] + bytes[idx + 2]) / 3.0;
            colVariance += (b - colBrightness[x]).abs();
          }
          colVariance /= size;

          // Low variance AND similar to previous bar columns = still in bar region
          if (colVariance < 15 && diff < 10) {
            leftBarEnd = x + 1;
          } else {
            break;
          }
        }
      }

      // Find right bar: columns from right edge
      for (int x = size - 1; x >= size ~/ 2; x--) {
        if (x > 0) {
          final diff = (colBrightness[x] - colBrightness[x - 1]).abs();
          double colVariance = 0;
          for (int y = 0; y < size; y++) {
            final idx = (y * size + x) * 3;
            final b = (bytes[idx] + bytes[idx + 1] + bytes[idx + 2]) / 3.0;
            colVariance += (b - colBrightness[x]).abs();
          }
          colVariance /= size;

          if (colVariance < 15 && diff < 10) {
            rightBarStart = x;
          } else {
            break;
          }
        }
      }

      // Detect uniform top/bottom rows
      int topBarEnd = 0;
      int bottomBarStart = size;

      for (int y = 0; y < size ~/ 2; y++) {
        if (y < size - 1) {
          final diff = (rowBrightness[y] - rowBrightness[y + 1]).abs();
          double rowVariance = 0;
          for (int x = 0; x < size; x++) {
            final idx = (y * size + x) * 3;
            final b = (bytes[idx] + bytes[idx + 1] + bytes[idx + 2]) / 3.0;
            rowVariance += (b - rowBrightness[y]).abs();
          }
          rowVariance /= size;

          if (rowVariance < 15 && diff < 10) {
            topBarEnd = y + 1;
          } else {
            break;
          }
        }
      }

      for (int y = size - 1; y >= size ~/ 2; y--) {
        if (y > 0) {
          final diff = (rowBrightness[y] - rowBrightness[y - 1]).abs();
          double rowVariance = 0;
          for (int x = 0; x < size; x++) {
            final idx = (y * size + x) * 3;
            final b = (bytes[idx] + bytes[idx + 1] + bytes[idx + 2]) / 3.0;
            rowVariance += (b - rowBrightness[y]).abs();
          }
          rowVariance /= size;

          if (rowVariance < 15 && diff < 10) {
            bottomBarStart = y;
          } else {
            break;
          }
        }
      }

      final activeWidth = rightBarStart - leftBarEnd;
      final activeHeight = bottomBarStart - topBarEnd;
      final sideBarsDetected = leftBarEnd >= 3 || (size - rightBarStart) >= 3;
      final topBottomBarsDetected = topBarEnd >= 3 || (size - bottomBarStart) >= 3;

      dev.log(
        '[Organizer] Raw frame analysis (${size}x$size):\n'
        '  Left bar end: $leftBarEnd  Right bar start: $rightBarStart\n'
        '  Top bar end: $topBarEnd  Bottom bar start: $bottomBarStart\n'
        '  Active area: ${activeWidth}x$activeHeight (of ${size}x$size)\n'
        '  Side bars: $sideBarsDetected  Top/Bottom bars: $topBottomBarsDetected',
        name: 'OrganizerService',
      );

      if (!sideBarsDetected && !topBottomBarsDetected) {
        // No bars detected — visual analysis cannot determine orientation
        return const VisualDetectionResult(
          orientation: null,
          confidence: 0.0,
          reason: 'Raw frame: no border bars detected',
        );
      }

      // Map back to original dimensions
      final visualWidth = (activeWidth / size * originalWidth).round();
      final visualHeight = (activeHeight / size * originalHeight).round();

      final MediaOrientation orientation;
      if (visualHeight > visualWidth) {
        orientation = MediaOrientation.vertical;
      } else if (visualWidth > visualHeight) {
        orientation = MediaOrientation.landscape;
      } else {
        orientation = MediaOrientation.square;
      }

      final confidence = (sideBarsDetected || topBottomBarsDetected) ? 0.85 : 0.6;

      return VisualDetectionResult(
        orientation: orientation,
        confidence: confidence,
        reason: 'Raw frame: content ${visualWidth}x$visualHeight inside ${originalWidth}x$originalHeight',
        visualWidth: visualWidth,
        visualHeight: visualHeight,
      );
    } catch (e) {
      return VisualDetectionResult(
        orientation: null,
        confidence: 0.0,
        reason: 'Error: $e',
      );
    } finally {
      try {
        final f = File(tempPath);
        if (f.existsSync()) {
          f.deleteSync();
        }
      } catch (_) {}
    }
  }
}

class VisualDetectionResult {
  const VisualDetectionResult({
    this.orientation,
    this.confidence = 0.0,
    this.reason = '',
    this.visualWidth,
    this.visualHeight,
  });

  final MediaOrientation? orientation;
  final double confidence;
  final String reason;
  final int? visualWidth;
  final int? visualHeight;
}


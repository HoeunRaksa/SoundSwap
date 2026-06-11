import 'dart:io';
import 'package:flutter_test/flutter_test.dart';
import 'package:path/path.dart' as p;
import 'package:soundswap/features/folder_organizer/data/models/organizer_options.dart';
import 'package:soundswap/features/folder_organizer/data/models/organizer_file_item.dart';
import 'package:soundswap/features/folder_organizer/data/services/organizer_service.dart';
import 'package:soundswap/features/folder_organizer/data/models/organizer_history_record.dart';
import 'package:soundswap/features/folder_organizer/presentation/state/folder_organizer_controller.dart';
import 'package:soundswap/shared/services/folder_picker_service.dart';
import 'package:soundswap/features/home/data/services/ffmpeg_service.dart';
import 'package:soundswap/shared/services/local_json_store.dart';

class MockFolderPickerService implements FolderPickerService {
  String? pickedFolder;

  @override
  Future<String?> pickFolder({String? dialogTitle}) async {
    return pickedFolder;
  }
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  late Directory tempDir;
  late OrganizerService service;
  late FakeLocalJsonStore fakeStore;

  setUp(() async {
    tempDir = await Directory.systemTemp.createTemp('folder_organizer_test');
    fakeStore = FakeLocalJsonStore();
    service = OrganizerService(store: fakeStore);
  });

  tearDown(() async {
    if (tempDir.existsSync()) {
      await tempDir.delete(recursive: true);
    }
  });

  group('Re-scanning and folder reuse behaviors', () {
    test('traverses images/ and videos/ normally and detects media inside them', () async {
      // Create destination folders
      final videosDir = Directory(p.join(tempDir.path, 'videos'))..createSync();
      final imagesDir = Directory(p.join(tempDir.path, 'images'))..createSync();

      final videoFile = File(p.join(videosDir.path, 'v1.mp4'))..writeAsStringSync('data');
      final imageFile = File(p.join(imagesDir.path, 'i1.jpg'))..writeAsStringSync('data');

      final stream = service.scanFolder(rootPath: tempDir.path, options: const OrganizerOptions());
      final events = await stream.toList();
      final completedEvent = events.last;
      
      expect(completedEvent['status'], equals('completed'));
      final items = completedEvent['items'] as List<OrganizerFileItem>;

      // We should successfully scan both files inside the destination folders!
      expect(items.length, equals(2));
      final paths = items.map((i) => i.originalPath).toList();
      expect(paths, contains(videoFile.path));
      expect(paths, contains(imageFile.path));
    });

    test('marks files as alreadyOrganized when they are already in the correct destination directory', () async {
      final imagesDir = Directory(p.join(tempDir.path, 'images'))..createSync();
      final imageFile = File(p.join(imagesDir.path, 'i1.jpg'))..writeAsStringSync('data');

      final stream = service.scanFolder(
        rootPath: tempDir.path,
        options: const OrganizerOptions(
          organizeFiles: true,
          renameFiles: false,
          keepFolderStructure: false,
        ),
      );
      final events = await stream.toList();
      final items = events.last['items'] as List<OrganizerFileItem>;

      expect(items.length, equals(1));
      final item = items.first;
      expect(item.originalPath, equals(imageFile.path));
      expect(item.action, equals(FileItemAction.alreadyOrganized));
    });

    test('moves files from images/ or videos/ into quality subfolders in quality mode', () async {
      final imagesDir = Directory(p.join(tempDir.path, 'images'))..createSync();
      final imageFile = File(p.join(imagesDir.path, 'i1.jpg'))..writeAsStringSync('data');

      // Setup options with quality mode
      final options = const OrganizerOptions(
        organizeFiles: true,
        organizeMode: OrganizerMode.byQuality,
        renameFiles: false,
        keepFolderStructure: false,
      );

      final stream = service.scanFolder(rootPath: tempDir.path, options: options);
      final events = await stream.toList();
      final items = events.last['items'] as List<OrganizerFileItem>;

      expect(items.length, equals(1));
      final item = items.first;
      expect(item.originalPath, equals(imageFile.path));
      
      // Since quality probing wasn't performed or failed in test (no FFmpeg mock probe setup here),
      // it defaults/fails to qualityGroup = 'landscape/lowQuality'.
      // The target path should be tempDir/images/landscape/lowQuality/i1.jpg, which is different from tempDir/images/i1.jpg.
      // Therefore, the action should be FileItemAction.move (moving into correct quality folder)!
      expect(item.action, equals(FileItemAction.move));
      expect(p.normalize(item.newPath!), equals(p.normalize(p.join(imagesDir.path, 'landscape', 'lowQuality', 'i1.jpg'))));
    });
  });

  group('FolderOrganizerController Banner and Reset tests', () {
    test('displays "Files found: X, already organized: Y" if organized files are scanned', () async {
      final picker = MockFolderPickerService();
      final controller = FolderOrganizerController(service: service, pickerService: picker);
      controller.rootFolderPath = tempDir.path;

      // Create an already organized file
      final imagesDir = Directory(p.join(tempDir.path, 'images'))..createSync();
      File(p.join(imagesDir.path, 'i1.jpg')).writeAsStringSync('data');

      await controller.startScan();

      expect(controller.scannedItems.length, equals(1));
      expect(controller.infoMessage, equals('Scan completed\nFiles found: 1, already organized: 1'));
    });

    test('displays "No supported media files found." if directory has no media files at all', () async {
      final picker = MockFolderPickerService();
      final controller = FolderOrganizerController(service: service, pickerService: picker);
      controller.rootFolderPath = tempDir.path;

      // Put only non-media file
      File(p.join(tempDir.path, 'notes.txt')).writeAsStringSync('data');

      await controller.startScan();

      expect(controller.scannedItems, isEmpty);
      expect(controller.infoMessage, equals('No supported media files found.'));
    });
  });

  group('HEIC/HEIF support tests', () {
    late FakeFfmpegService fakeFfmpeg;
    late OrganizerService serviceWithFake;

    setUp(() {
      fakeFfmpeg = FakeFfmpegService();
      serviceWithFake = OrganizerService(store: fakeStore, ffmpegService: fakeFfmpeg);
    });

    test('detects heic/heif as image files during scan', () async {
      File(p.join(tempDir.path, 'photo1.heic')).writeAsStringSync('data');
      File(p.join(tempDir.path, 'photo2.heif')).writeAsStringSync('data');

      final stream = serviceWithFake.scanFolder(rootPath: tempDir.path, options: const OrganizerOptions());
      final events = await stream.toList();
      final items = events.last['items'] as List<OrganizerFileItem>;

      expect(items.length, equals(2));
      for (final item in items) {
        expect(item.fileType, equals(FileItemType.image));
      }
    });

    test('when convertHeicToPng is OFF, HEIC files keep original extension and action is move', () async {
      File(p.join(tempDir.path, 'photo1.heic')).writeAsStringSync('data');
      final options = const OrganizerOptions(
        organizeFiles: true,
        convertHeicToPng: false,
      );

      final stream = serviceWithFake.scanFolder(rootPath: tempDir.path, options: options);
      final events = await stream.toList();
      final items = events.last['items'] as List<OrganizerFileItem>;

      expect(items.length, equals(1));
      final item = items.first;
      expect(item.action, equals(FileItemAction.move));
      expect(p.extension(item.newPath!), equals('.heic'));
    });

    test('when convertHeicToPng is ON, HEIC files target .png extension, action is convert, and keeps original file', () async {
      final heicFile = File(p.join(tempDir.path, 'photo1.heic'))..writeAsStringSync('data');
      final options = const OrganizerOptions(
        organizeFiles: true,
        convertHeicToPng: true,
      );

      // Verify Scan & proposed changes
      final scanStream = serviceWithFake.scanFolder(rootPath: tempDir.path, options: options);
      final scanEvents = await scanStream.toList();
      final items = scanEvents.last['items'] as List<OrganizerFileItem>;

      expect(items.length, equals(1));
      final item = items.first;
      expect(item.action, equals(FileItemAction.convert));
      expect(p.extension(item.newPath!), equals('.png'));

      // Verify apply changes (successful conversion)
      final applyStream = serviceWithFake.applyChanges(
        items: items,
        rootPath: tempDir.path,
        options: options,
      );
      final applyEvents = await applyStream.toList();
      final finalEvent = applyEvents.last;

      expect(finalEvent['status'], equals('completed'));
      expect(fakeFfmpeg.convertCalled, isTrue);
      expect(fakeFfmpeg.lastInputPath, equals(heicFile.path));
      expect(fakeFfmpeg.lastOutputPath, equals(item.newPath));

      // Original HEIC file should still exist!
      expect(heicFile.existsSync(), isTrue);
      // New PNG file should exist (created by fake converter)
      expect(File(item.newPath!).existsSync(), isTrue);
    });

    test('handles conversion failure safely without deleting original HEIC', () async {
      final heicFile = File(p.join(tempDir.path, 'photo1.heic'));
      heicFile.writeAsStringSync('data');
      final options = const OrganizerOptions(
        organizeFiles: true,
        convertHeicToPng: true,
      );

      fakeFfmpeg.shouldFail = true;

      // Scan
      final scanStream = serviceWithFake.scanFolder(rootPath: tempDir.path, options: options);
      final scanEvents = await scanStream.toList();
      final items = scanEvents.last['items'] as List<OrganizerFileItem>;

      // Apply (failing conversion)
      final applyStream = serviceWithFake.applyChanges(
        items: items,
        rootPath: tempDir.path,
        options: options,
      );
      final applyEvents = await applyStream.toList();
      
      expect(applyEvents.last['failed'], equals(1));
      expect(applyEvents.last['heicFailed'], equals(1));
      expect(items.first.action, equals(FileItemAction.error));
      expect(items.first.errorMessage, contains('HEIC to PNG conversion failed'));

      // Original HEIC must still exist
      expect(heicFile.existsSync(), isTrue);
    });

    test('when convertHeicToPng is ON and deleteOriginalHeic is ON, HEIC files are deleted after successful conversion', () async {
      final heicFile = File(p.join(tempDir.path, 'photo1.heic'));
      heicFile.writeAsStringSync('data');
      final options = const OrganizerOptions(
        organizeFiles: true,
        convertHeicToPng: true,
        deleteOriginalHeic: true,
      );

      // Verify Scan & proposed changes
      final scanStream = serviceWithFake.scanFolder(rootPath: tempDir.path, options: options);
      final scanEvents = await scanStream.toList();
      final items = scanEvents.last['items'] as List<OrganizerFileItem>;

      expect(items.length, equals(1));
      final item = items.first;

      // Verify apply changes
      final applyStream = serviceWithFake.applyChanges(
        items: items,
        rootPath: tempDir.path,
        options: options,
      );
      final applyEvents = await applyStream.toList();
      final finalEvent = applyEvents.last;

      expect(finalEvent['status'], equals('completed'));
      expect(finalEvent['heicConverted'], equals(1));
      expect(finalEvent['heicDeleted'], equals(1));

      // Original HEIC file should be DELETED!
      expect(heicFile.existsSync(), isFalse);
      // New PNG file should exist
      expect(File(item.newPath!).existsSync(), isTrue);
    });

    test('when convertHeicToPng is ON and deleteOriginalHeic is OFF, undoing deletes converted PNG and keeps original HEIC', () async {
      final heicFile = File(p.join(tempDir.path, 'photo1.heic'));
      heicFile.writeAsStringSync('data');
      final options = const OrganizerOptions(
        organizeFiles: true,
        convertHeicToPng: true,
        deleteOriginalHeic: false,
      );

      final scanStream = serviceWithFake.scanFolder(rootPath: tempDir.path, options: options);
      final scanEvents = await scanStream.toList();
      final items = scanEvents.last['items'] as List<OrganizerFileItem>;

      final applyStream = serviceWithFake.applyChanges(
        items: items,
        rootPath: tempDir.path,
        options: options,
      );
      final applyEvents = await applyStream.toList();
      final finalEvent = applyEvents.last;
      final record = finalEvent['record'] as OrganizerHistoryRecord;

      expect(heicFile.existsSync(), isTrue);
      expect(File(items.first.newPath!).existsSync(), isTrue);

      // Now undo
      final undoResult = await serviceWithFake.undoOperation(record);
      expect(undoResult['undoneCount'], equals(1));
      expect(undoResult['failedCount'], equals(0));

      // PNG should be deleted, original HEIC should still exist
      expect(heicFile.existsSync(), isTrue);
      expect(File(items.first.newPath!).existsSync(), isFalse);
    });

    test('when convertHeicToPng is ON and deleteOriginalHeic is ON, undoing fails to restore HEIC and does not delete PNG', () async {
      final heicFile = File(p.join(tempDir.path, 'photo1.heic'));
      heicFile.writeAsStringSync('data');
      final options = const OrganizerOptions(
        organizeFiles: true,
        convertHeicToPng: true,
        deleteOriginalHeic: true,
      );

      final scanStream = serviceWithFake.scanFolder(rootPath: tempDir.path, options: options);
      final scanEvents = await scanStream.toList();
      final items = scanEvents.last['items'] as List<OrganizerFileItem>;

      final applyStream = serviceWithFake.applyChanges(
        items: items,
        rootPath: tempDir.path,
        options: options,
      );
      final applyEvents = await applyStream.toList();
      final finalEvent = applyEvents.last;
      final record = finalEvent['record'] as OrganizerHistoryRecord;

      expect(heicFile.existsSync(), isFalse);
      expect(File(items.first.newPath!).existsSync(), isTrue);

      // Now undo
      final undoResult = await serviceWithFake.undoOperation(record);
      expect(undoResult['undoneCount'], equals(0));
      expect(undoResult['failedCount'], equals(1));
      expect(undoResult['errors'].first, contains('Cannot restore original HEIC (permanently deleted)'));

      // PNG should still exist, HEIC is still missing
      expect(heicFile.existsSync(), isFalse);
      expect(File(items.first.newPath!).existsSync(), isTrue);
    });
  });

  group('Social Media quality classification tests', () {
    late FakeFfmpegService fakeFfmpeg;
    late OrganizerService serviceWithFake;

    setUp(() {
      fakeFfmpeg = FakeFfmpegService();
      serviceWithFake = OrganizerService(store: fakeStore, ffmpegService: fakeFfmpeg);
    });

    test('classifies portrait Full HD+ dimensions as portraitQuality', () async {
      // 1080x1920 (portrait Full HD+)
      final options = const OrganizerOptions(
        organizeFiles: true,
        organizeMode: OrganizerMode.byQuality,
      );
      fakeFfmpeg.probeDims = const VideoDimensions(width: 1080, height: 1920, rawWidth: 1080, rawHeight: 1920);

      final file = File(p.join(tempDir.path, 'video.mp4'));
      file.writeAsStringSync('data');
      final scanStream = serviceWithFake.scanFolder(rootPath: tempDir.path, options: options);
      final scanEvents = await scanStream.toList();
      final items = scanEvents.last['items'] as List<OrganizerFileItem>;

      expect(items.length, equals(1));
      expect(items.first.qualityGroup, equals('portrait/highQuality'));
      expect(items.first.orientation, equals(MediaOrientation.vertical));
    });

    test('detects visual portrait content inside a landscape video frame', () async {
      // Raw: 1920x1080, no rotation, but vertical content visually
      final options = const OrganizerOptions(
        organizeFiles: true,
        organizeMode: OrganizerMode.byQuality,
        preferVisualOrientation: true,
      );
      
      fakeFfmpeg.probeDims = const VideoDimensions(
        width: 1920,
        height: 1080,
        rotation: 0,
        rawWidth: 1920,
        rawHeight: 1080,
      );

      // Generate a 64x64 RGB frame where:
      // columns 0-15 are black, 16-47 are active (white), 48-63 are black (pillarbox)
      final mockBytes = List<int>.filled(64 * 64 * 3, 0);
      for (int y = 0; y < 64; y++) {
        for (int x = 16; x < 48; x++) {
          final idx = (y * 64 + x) * 3;
          mockBytes[idx] = 255;     // R
          mockBytes[idx + 1] = 255; // G
          mockBytes[idx + 2] = 255; // B
        }
      }
      fakeFfmpeg.rawFrameBytes = mockBytes;

      final file = File(p.join(tempDir.path, 'visual_portrait.mp4'));
      file.writeAsStringSync('data');
      
      final scanStream = serviceWithFake.scanFolder(rootPath: tempDir.path, options: options);
      final scanEvents = await scanStream.toList();
      final items = scanEvents.last['items'] as List<OrganizerFileItem>;

      expect(items.length, equals(1));
      final item = items.first;
      expect(item.width, equals(1920));
      expect(item.height, equals(1080));
      expect(item.displayWidth, equals(1920));
      expect(item.displayHeight, equals(1080));
      expect(item.visualOrientation, equals(MediaOrientation.vertical));
      expect(item.finalOrientation, equals(MediaOrientation.vertical));
      expect(item.qualityGroup, equals('portrait/lowQuality'));
    });

    test('classifies portrait lower resolution as lowerPortrait if width < 1080 or height < 1920', () async {
      // 720x1280 (portrait lowerPortrait)
      final options = const OrganizerOptions(
        organizeFiles: true,
        organizeMode: OrganizerMode.byQuality,
      );
      fakeFfmpeg.probeDims = const VideoDimensions(width: 720, height: 1280, rawWidth: 720, rawHeight: 1280);

      final file = File(p.join(tempDir.path, 'video.mp4'));
      file.writeAsStringSync('data');
      final scanStream = serviceWithFake.scanFolder(rootPath: tempDir.path, options: options);
      final scanEvents = await scanStream.toList();
      final items = scanEvents.last['items'] as List<OrganizerFileItem>;

      expect(items.length, equals(1));
      expect(items.first.qualityGroup, equals('portrait/lowQuality'));
      expect(items.first.orientation, equals(MediaOrientation.vertical));
    });

    test('classifies portrait dimensions under 720x1280 as lowerPortrait', () async {
      // 480x640 (portrait lowerPortrait)
      final options = const OrganizerOptions(
        organizeFiles: true,
        organizeMode: OrganizerMode.byQuality,
      );
      fakeFfmpeg.probeDims = const VideoDimensions(width: 480, height: 640, rawWidth: 480, rawHeight: 640);

      final file = File(p.join(tempDir.path, 'video.mp4'));
      file.writeAsStringSync('data');
      final scanStream = serviceWithFake.scanFolder(rootPath: tempDir.path, options: options);
      final scanEvents = await scanStream.toList();
      final items = scanEvents.last['items'] as List<OrganizerFileItem>;

      expect(items.length, equals(1));
      expect(items.first.qualityGroup, equals('portrait/lowQuality'));
      expect(items.first.orientation, equals(MediaOrientation.vertical));
    });

    test('classifies landscape dimensions >= 1920x1080 as landscapeQuality', () async {
      // 1920x1080 (landscape quality)
      final options = const OrganizerOptions(
        organizeFiles: true,
        organizeMode: OrganizerMode.byQuality,
      );
      fakeFfmpeg.probeDims = const VideoDimensions(width: 1920, height: 1080, rawWidth: 1920, rawHeight: 1080);

      final file = File(p.join(tempDir.path, 'video.mp4'));
      file.writeAsStringSync('data');
      final scanStream = serviceWithFake.scanFolder(rootPath: tempDir.path, options: options);
      final scanEvents = await scanStream.toList();
      final items = scanEvents.last['items'] as List<OrganizerFileItem>;

      expect(items.length, equals(1));
      expect(items.first.qualityGroup, equals('landscape/highQuality'));
      expect(items.first.orientation, equals(MediaOrientation.landscape));
    });

    test('classifies landscape dimensions below 1920x1080 as lowerLandscape', () async {
      // 1280x720 (landscape lowerLandscape)
      final options = const OrganizerOptions(
        organizeFiles: true,
        organizeMode: OrganizerMode.byQuality,
      );
      fakeFfmpeg.probeDims = const VideoDimensions(width: 1280, height: 720, rawWidth: 1280, rawHeight: 720);

      final file = File(p.join(tempDir.path, 'video.mp4'));
      file.writeAsStringSync('data');
      final scanStream = serviceWithFake.scanFolder(rootPath: tempDir.path, options: options);
      final scanEvents = await scanStream.toList();
      final items = scanEvents.last['items'] as List<OrganizerFileItem>;

      expect(items.length, equals(1));
      expect(items.first.qualityGroup, equals('landscape/lowQuality'));
      expect(items.first.orientation, equals(MediaOrientation.landscape));
    });

    test('classifies square dimensions >= 1080x1080 as squareQuality', () async {
      // 1080x1080 (squareQuality)
      final options = const OrganizerOptions(
        organizeFiles: true,
        organizeMode: OrganizerMode.byQuality,
      );
      fakeFfmpeg.probeDims = const VideoDimensions(width: 1080, height: 1080, rawWidth: 1080, rawHeight: 1080);

      final file = File(p.join(tempDir.path, 'video.mp4'));
      file.writeAsStringSync('data');
      final scanStream = serviceWithFake.scanFolder(rootPath: tempDir.path, options: options);
      final scanEvents = await scanStream.toList();
      final items = scanEvents.last['items'] as List<OrganizerFileItem>;

      expect(items.length, equals(1));
      expect(items.first.qualityGroup, equals('square/highQuality'));
      expect(items.first.orientation, equals(MediaOrientation.square));
    });

    test('classifies square dimensions below 1080x1080 as lowerSquare', () async {
      // 720x720 (square lowerSquare)
      final options = const OrganizerOptions(
        organizeFiles: true,
        organizeMode: OrganizerMode.byQuality,
      );
      fakeFfmpeg.probeDims = const VideoDimensions(width: 720, height: 720, rawWidth: 720, rawHeight: 720);

      final file = File(p.join(tempDir.path, 'video.mp4'));
      file.writeAsStringSync('data');
      final scanStream = serviceWithFake.scanFolder(rootPath: tempDir.path, options: options);
      final scanEvents = await scanStream.toList();
      final items = scanEvents.last['items'] as List<OrganizerFileItem>;

      expect(items.length, equals(1));
      expect(items.first.qualityGroup, equals('square/lowQuality'));
      expect(items.first.orientation, equals(MediaOrientation.square));
    });

    test('swaps width and height for classification if rotation is 90 or 270 degrees', () async {
      // Raw: 3840x2160, Rotation: 90 -> Display: 2160x3840 (portraitQuality)
      final options = const OrganizerOptions(
        organizeFiles: true,
        organizeMode: OrganizerMode.byQuality,
      );
      fakeFfmpeg.probeDims = const VideoDimensions(
        width: 2160,
        height: 3840,
        rotation: 90,
        rawWidth: 3840,
        rawHeight: 2160,
      );

      final file = File(p.join(tempDir.path, 'phone_video.mp4'));
      file.writeAsStringSync('data');
      final scanStream = serviceWithFake.scanFolder(rootPath: tempDir.path, options: options);
      final scanEvents = await scanStream.toList();
      final items = scanEvents.last['items'] as List<OrganizerFileItem>;

      expect(items.length, equals(1));
      final item = items.first;
      expect(item.width, equals(3840));
      expect(item.height, equals(2160));
      expect(item.rotation, equals(90));
      expect(item.displayWidth, equals(2160));
      expect(item.displayHeight, equals(3840));
      expect(item.qualityGroup, equals('portrait/highQuality'));
      expect(item.orientation, equals(MediaOrientation.vertical));
    });

    test('defaults to landscape/lowQuality on probing failure and logs warning', () async {
      final options = const OrganizerOptions(
        organizeFiles: true,
        organizeMode: OrganizerMode.byQuality,
      );
      fakeFfmpeg.shouldFailProbing = true;

      final file = File(p.join(tempDir.path, 'video.mp4'));
      file.writeAsStringSync('data');
      final scanStream = serviceWithFake.scanFolder(rootPath: tempDir.path, options: options);
      final scanEvents = await scanStream.toList();
      final items = scanEvents.last['items'] as List<OrganizerFileItem>;

      expect(items.length, equals(1));
      expect(items.first.qualityGroup, equals('landscape/lowQuality'));
      expect(items.first.reason, equals('Resolution unknown → landscape/lowQuality'));
    });
  });
}

class FakeFfmpegService extends FfmpegService {
  bool convertCalled = false;
  String? lastInputPath;
  String? lastOutputPath;
  bool shouldFail = false;
  VideoDimensions probeDims = const VideoDimensions(width: 1920, height: 1080, rawWidth: 1920, rawHeight: 1080);
  bool shouldFailProbing = false;
  List<int>? rawFrameBytes;

  @override
  Future<void> convertHeicToPng(String inputPath, String outputPath) async {
    convertCalled = true;
    lastInputPath = inputPath;
    lastOutputPath = outputPath;
    if (shouldFail) {
      throw FfmpegException('Failed to convert HEIC to PNG');
    }
    // Simulate output creation
    final file = File(outputPath);
    if (!file.existsSync()) {
      file.createSync(recursive: true);
    }
    file.writeAsStringSync('png content');
  }

  @override
  Future<VideoDimensions> probeVideoDimensions(String inputPath) async {
    if (shouldFailProbing) {
      throw FfmpegException('Mock probing failure');
    }
    return probeDims;
  }

  @override
  Future<List<int>?> extractRawFrame(String videoPath, String outRawPath, {int size = 64}) async {
    if (rawFrameBytes != null) {
      final f = File(outRawPath);
      if (!f.parent.existsSync()) {
        f.parent.createSync(recursive: true);
      }
      f.writeAsBytesSync(rawFrameBytes!);
      return rawFrameBytes;
    }
    return null;
  }

  @override
  Future<CropDetectResult?> detectCropArea(String videoPath) async {
    return null;
  }
}

class FakeLocalJsonStore extends LocalJsonStore {
  final Map<String, dynamic> _storage = {};

  @override
  Future<Map<String, Object?>> readMap(String fileName) async {
    return Map<String, Object?>.from(_storage[fileName] as Map? ?? {});
  }

  @override
  Future<void> writeMap(String fileName, Map<String, Object?> value) async {
    _storage[fileName] = value;
  }

  @override
  Future<List<Object?>> readList(String fileName) async {
    return List<Object?>.from(_storage[fileName] as List? ?? []);
  }

  @override
  Future<void> writeList(String fileName, List<Object?> value) async {
    _storage[fileName] = value;
  }
}


import 'dart:async';
import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:path/path.dart' as p;
import 'package:soundswap/core/constants/app_constants.dart';
import 'package:soundswap/shared/services/folder_picker_service.dart';

class FolderWatcherController extends ChangeNotifier {
  FolderWatcherController({FolderPickerService? folderPickerService})
    : _folderPickerService = folderPickerService ?? FolderPickerService();

  final FolderPickerService _folderPickerService;
  StreamSubscription<FileSystemEvent>? _subscription;
  String? watchFolder;
  bool isWatching = false;
  List<String> detectedVideos = [];
  String? errorMessage;

  Future<void> pickWatchFolder() async {
    final path = await _folderPickerService.pickFolder(
      dialogTitle: 'Select watch folder',
    );
    if (path != null) {
      watchFolder = path;
      detectedVideos = [];
      notifyListeners();
    }
  }

  Future<void> startWatching() async {
    if (watchFolder == null) return;
    await stopWatching();
    try {
      isWatching = true;
      _subscription = Directory(watchFolder!).watch().listen(
        _handleEvent,
        onError: (Object error) {
          errorMessage = error.toString();
          isWatching = false;
          notifyListeners();
        },
      );
    } catch (error) {
      errorMessage = error.toString();
      isWatching = false;
    }
    notifyListeners();
  }

  Future<void> stopWatching() async {
    await _subscription?.cancel();
    _subscription = null;
    isWatching = false;
    notifyListeners();
  }

  void _handleEvent(FileSystemEvent event) {
    final extension = p.extension(event.path).toLowerCase();
    if (!AppConstants.supportedVideoExtensions.contains(extension)) return;
    if (!detectedVideos.contains(event.path)) {
      detectedVideos = [event.path, ...detectedVideos];
      notifyListeners();
    }
  }

  @override
  void dispose() {
    _subscription?.cancel();
    super.dispose();
  }
}

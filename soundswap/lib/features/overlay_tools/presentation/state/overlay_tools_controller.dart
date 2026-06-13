import 'dart:async';
import 'dart:io';
import 'package:file_picker/file_picker.dart';
import 'package:flutter/foundation.dart';
import 'package:path/path.dart' as p;
// ignore_for_file: avoid_print
import 'package:soundswap/core/video/video_output_settings.dart';
import 'package:soundswap/features/overlay_tools/data/models/overlay_item.dart';
import 'package:soundswap/features/overlay_tools/data/models/overlay_preset.dart';
import 'package:soundswap/features/overlay_tools/data/models/overlay_settings.dart';
import 'package:soundswap/features/overlay_tools/data/services/overlay_preset_service.dart';
import 'package:soundswap/features/overlay_tools/data/services/overlay_settings_service.dart';
import 'package:soundswap/features/overlay_tools/data/models/asset_library_item.dart';
import 'package:soundswap/features/overlay_tools/data/services/asset_library_service.dart';
import 'package:soundswap/features/templates/data/models/project_workspace.dart';
import 'package:soundswap/features/templates/data/services/workspace_service.dart';
import 'package:soundswap/features/templates/presentation/state/templates_controller.dart';
import 'package:soundswap/features/templates/data/models/project_template.dart';
import 'package:soundswap/features/home/presentation/state/home_controller.dart';
import 'package:soundswap/features/branding/presentation/state/branding_controller.dart';
import 'package:soundswap/features/text_overlay/presentation/state/text_overlay_controller.dart';

class OverlayToolsController extends ChangeNotifier {
  OverlayToolsController({
    OverlaySettingsService? settingsService,
    OverlayPresetService? presetService,
    AssetLibraryService? assetLibraryService,
    WorkspaceService? workspaceService,
  }) : _settingsService = settingsService ?? OverlaySettingsService(),
       _presetService = presetService ?? OverlayPresetService(),
       _assetLibraryService = assetLibraryService ?? AssetLibraryService(),
       _workspaceService = workspaceService ?? WorkspaceService();

  final OverlaySettingsService _settingsService;
  final OverlayPresetService _presetService;
  final AssetLibraryService _assetLibraryService;
  final WorkspaceService _workspaceService;

  OverlaySettings settings = const OverlaySettings();
  List<OverlayPreset> presets = [];
  List<AssetLibraryItem> assets = [];
  List<ProjectWorkspace> workspaces = [];

  String? selectedItemId;
  final Set<String> selectedItemIds = {};
  String? message;
  String? errorMessage;

  // Timeline playback simulation
  double currentTime = 0.0;
  bool isPlaying = false;
  double timelineDuration = 30.0;
  Timer? _playbackTimer;

  OverlayItem? get selectedItem {
    for (final item in settings.items) {
      if (item.id == selectedItemId) return item;
    }
    return null;
  }

  Future<void> load() async {
    try {
      settings = await _settingsService.load();
      presets = await _presetService.load();
      assets = await _assetLibraryService.load();
      workspaces = await _workspaceService.load();
      if (settings.items.isNotEmpty) {
        selectedItemId = settings.items.first.id;
        selectedItemIds.clear();
        selectedItemIds.add(settings.items.first.id);
      }
      errorMessage = null;
    } catch (error) {
      errorMessage = error.toString();
    }
    notifyListeners();
  }

  // --- Asset Library ---
  Future<void> addAssetToLibrary(String path) async {
    final name = path.split(Platform.isWindows ? '\\' : '/').last;
    final item = AssetLibraryItem(
      id: _newId(),
      name: name,
      path: path,
      createdAt: DateTime.now(),
    );
    assets = [item, ...assets];
    await _assetLibraryService.saveAll(assets);
    notifyListeners();
  }

  Future<void> removeAssetFromLibrary(String id) async {
    assets = assets.where((e) => e.id != id).toList();
    await _assetLibraryService.saveAll(assets);
    notifyListeners();
  }

  Future<void> addAssetToCanvas(AssetLibraryItem asset) async {
    final item = OverlayItem(
      id: _newId(),
      type: OverlayItemType.image,
      name: asset.name,
      imagePath: asset.path,
      position: const NormalizedPosition(xPercent: 0.1, yPercent: 0.1),
      width: 0.3,
    );
    await _replaceSettings(
      settings.copyWith(items: [item, ...settings.items]),
      selectedId: item.id,
    );
  }

  // --- Workspaces ---
  Future<void> saveWorkspace(String name, {
    required HomeController home,
    required BrandingController branding,
    required TextOverlayController textOverlay,
    required List<ProjectTemplate> templatesList,
  }) async {
    final workspace = ProjectWorkspace(
      id: _newId(),
      name: name.trim().isEmpty ? 'Workspace ${workspaces.length + 1}' : name.trim(),
      createdAt: DateTime.now(),
      videoFolders: home.videoFolders,
      audioFolders: home.audioFolders,
      outputFolder: home.outputFolderPath,
      outputPrefix: home.outputNamePrefix,
      useBranding: home.useBranding,
      useTextOverlay: home.useTextOverlay,
      useOverlay: home.useOverlay || settings.items.isNotEmpty,
      outputSize: home.outputSize,
      fitMode: home.fitMode,
      branding: home.activeBrandingSettings ?? branding.settings,
      textOverlay: home.activeTextOverlaySettings ?? textOverlay.settings,
      overlaySettings: settings,
      templates: templatesList,
      assets: assets,
    );
    workspaces = [workspace, ...workspaces];
    await _workspaceService.saveAll(workspaces);
    message = 'Workspace saved.';
    notifyListeners();
  }

  Future<void> loadWorkspace(ProjectWorkspace ws, {
    required HomeController home,
    required BrandingController branding,
    required TextOverlayController textOverlay,
    required TemplatesController templatesCtrl,
  }) async {
    await home.applyTemplateFolders(
      videoFolders: ws.videoFolders,
      audioFolders: ws.audioFolders,
      outputFolder: ws.outputFolder,
      outputPrefix: ws.outputPrefix,
    );
    await branding.update(ws.branding);
    await textOverlay.update(ws.textOverlay);
    await applySettings(ws.overlaySettings);
    home.applyGeneratorSettings(
      useBranding: ws.useBranding,
      useTextOverlay: ws.useTextOverlay,
      useOverlay: ws.useOverlay,
      outputSize: ws.outputSize,
      fitMode: ws.fitMode,
      brandingSettings: ws.branding,
      textOverlaySettings: ws.textOverlay,
      overlaySettings: ws.overlaySettings,
    );

    assets = ws.assets;
    await _assetLibraryService.saveAll(assets);

    await templatesCtrl.updateTemplates(ws.templates);

    message = 'Workspace loaded.';
    notifyListeners();
  }

  Future<void> deleteWorkspace(ProjectWorkspace workspace) async {
    workspaces = workspaces.where((w) => w.id != workspace.id).toList();
    await _workspaceService.saveAll(workspaces);
    message = 'Workspace deleted.';
    notifyListeners();
  }

  // --- Timeline Simulation Player ---
  void togglePlayback() {
    if (isPlaying) {
      pausePlayback();
    } else {
      startPlayback();
    }
  }

  void startPlayback() {
    if (isPlaying) return;
    isPlaying = true;
    notifyListeners();
    _playbackTimer = Timer.periodic(const Duration(milliseconds: 50), (timer) {
      currentTime += 0.05;
      if (currentTime >= timelineDuration) {
        currentTime = 0.0;
      }
      notifyListeners();
    });
  }

  void pausePlayback() {
    isPlaying = false;
    _playbackTimer?.cancel();
    _playbackTimer = null;
    notifyListeners();
  }

  void seek(double time) {
    currentTime = time.clamp(0.0, timelineDuration);
    notifyListeners();
  }

  // --- Layer Management ---
  Future<void> addText() async {
    final item = OverlayItem(
      id: _newId(),
      type: OverlayItemType.text,
      name: 'Text overlay',
      text: 'New text',
      position: const NormalizedPosition(xPercent: 0.1, yPercent: 0.18),
      fontPath: settings.defaultFontPath,
      fontFamily: settings.defaultFontFamily,
      startTime: 0.0,
      endTime: null,
    );
    await _replaceSettings(
      settings.copyWith(items: [item, ...settings.items]),
      selectedId: item.id,
    );
  }

  Future<void> addImage() async {
    final result = await FilePicker.platform.pickFiles(type: FileType.image);
    final path = result?.files.single.path;
    if (path == null) return;

    final width = 0.25.clamp(0.05, 0.8);
    final xPercent = (0.5 - width / 2).clamp(0.0, 1.0 - width);
    final yPercent = (0.5 - width / 2).clamp(0.0, 1.0 - width);

    final item = OverlayItem(
      id: _newId(),
      type: OverlayItemType.image,
      name: p.basename(path),
      imagePath: path,
      position: NormalizedPosition(xPercent: xPercent, yPercent: yPercent),
      width: width,
      startTime: 0.0,
      endTime: null,
    );
    
    debugPrint('--- ADD IMAGE DEBUG ---');
    debugPrint('selected picker path: $path');
    debugPrint('created overlay item id: ${item.id}');
    debugPrint('created overlay item image path: ${item.imagePath}');
    debugPrint('xPercent: $xPercent, yPercent: $yPercent');
    debugPrint('widthPercent: $width');
    
    await _replaceSettings(
      settings.copyWith(items: [item, ...settings.items]),
      selectedId: item.id,
    );
    
    debugPrint('selected layer id: $selectedItemId');
    debugPrint('-----------------------');
  }

  Future<void> pickDefaultFont() async {
    final result = await FilePicker.platform.pickFiles(
      type: FileType.custom,
      allowedExtensions: ['ttf', 'otf'],
    );
    final path = result?.files.single.path;
    if (path == null) return;
    await _replaceSettings(settings.copyWith(defaultFontPath: path));
  }

  Future<void> clearDefaultFont() async {
    await _replaceSettings(settings.copyWith(clearDefaultFontPath: true));
  }

  void selectItem(String id) {
    selectedItemId = id;
    selectedItemIds.clear();
    selectedItemIds.add(id);
    notifyListeners();
  }

  void toggleItemSelection(String id) {
    if (selectedItemIds.contains(id)) {
      selectedItemIds.remove(id);
      if (selectedItemId == id) {
        selectedItemId = selectedItemIds.isNotEmpty ? selectedItemIds.first : null;
      }
    } else {
      selectedItemIds.add(id);
      selectedItemId = id;
    }
    notifyListeners();
  }

  void clearSelection() {
    selectedItemId = null;
    selectedItemIds.clear();
    notifyListeners();
  }

  Future<void> updateSelected(OverlayItem item) async {
    await updateItem(item);
  }

  Future<void> updateItem(OverlayItem item, {bool saveToDisk = true}) async {
    await _replaceSettings(
      settings.copyWith(
        items: [
          for (final existing in settings.items)
            if (existing.id == item.id) item else existing,
        ],
      ),
      selectedId: item.id,
      saveToDisk: saveToDisk,
    );
  }

  Future<void> applyTimingToAll() async {
    final item = selectedItem;
    if (item == null) return;

    final nextItems = settings.items.map((e) {
      if (e.id == item.id) return e;
      return e.copyWith(
        startTime: item.startTime,
        endTime: item.endTime,
        clearEndTime: item.endTime == null,
        animationEntrance: item.animationEntrance,
        animationEntranceDuration: item.animationEntranceDuration,
        animationExit: item.animationExit,
        animationExitDuration: item.animationExitDuration,
      );
    }).toList();

    await _replaceSettings(settings.copyWith(items: nextItems));
    message = 'Timing and animations applied to all overlays.';
    notifyListeners();
  }

  Future<void> moveItem(String id, NormalizedPosition position, {bool saveToDisk = true}) async {
    final item = _itemById(id);
    if (item == null || item.locked) return;
    await updateItem(item.copyWith(position: position), saveToDisk: saveToDisk);
  }

  Future<void> resizeItem(String id, double width, {bool saveToDisk = true}) async {
    final item = _itemById(id);
    if (item == null || item.locked) return;
    await updateItem(item.copyWith(width: width), saveToDisk: saveToDisk);
  }

  Future<void> duplicateItem(String id) async {
    final item = _itemById(id);
    if (item == null) return;
    final newItem = item.copyWith(
      name: '${item.name} Copy',
      position: item.position.copyWith(
        xPercent: (item.position.xPercent + 0.03).clamp(0.0, 1.0),
        yPercent: (item.position.yPercent + 0.03).clamp(0.0, 1.0),
      ),
    );
    final index = settings.items.indexWhere((e) => e.id == id);
    final nextItems = [...settings.items];
    if (index != -1) {
      nextItems.insert(index, newItem);
    } else {
      nextItems.add(newItem);
    }
    await _replaceSettings(
      settings.copyWith(items: nextItems),
      selectedId: newItem.id,
    );
  }

  Future<void> toggleLock(String id) async {
    final item = _itemById(id);
    if (item == null) return;
    await updateItem(item.copyWith(locked: !item.locked));
  }

  Future<void> toggleHidden(String id) async {
    final item = _itemById(id);
    if (item == null) return;
    await updateItem(item.copyWith(hidden: !item.hidden));
  }

  Future<void> setItemFolder(String id, String? folderName) async {
    final item = _itemById(id);
    if (item == null) return;
    await updateItem(item.copyWith(
      folder: folderName,
      clearFolder: folderName == null,
    ));
  }

  Future<void> bringForward(String id) async {
    final item = _itemById(id);
    if (item == null) return;
    final maxOrder = settings.items.fold(0, (max, e) => e.layerOrder > max ? e.layerOrder : max);
    await updateItem(item.copyWith(layerOrder: maxOrder + 1));
  }

  Future<void> sendBackward(String id) async {
    final item = _itemById(id);
    if (item == null) return;
    final minOrder = settings.items.fold(0, (min, e) => e.layerOrder < min ? e.layerOrder : min);
    await updateItem(item.copyWith(layerOrder: minOrder - 1));
  }

  Future<void> reorderItems(int oldIndex, int newIndex) async {
    final items = [...settings.items];
    if (oldIndex < 0 || oldIndex >= items.length) return;
    if (newIndex < 0 || newIndex > items.length) return;
    if (newIndex > oldIndex) newIndex--;
    final item = items.removeAt(oldIndex);
    items.insert(newIndex, item);
    final reordered = <OverlayItem>[
      for (var i = 0; i < items.length; i++)
        items[i].copyWith(layerOrder: i),
    ];
    await _replaceSettings(
      settings.copyWith(items: reordered),
      selectedId: selectedItemId,
    );
  }

  Future<void> removeSelected() async {
    final id = selectedItemId;
    if (id == null) return;
    final remaining = settings.items.where((item) => item.id != id).toList();
    await _replaceSettings(
      settings.copyWith(items: remaining),
      selectedId: remaining.isEmpty ? null : remaining.first.id,
    );
  }

  Future<void> savePreset(String name) async {
    final preset = OverlayPreset(
      id: _newId(),
      name: name.trim().isEmpty ? 'Untitled overlay' : name.trim(),
      createdAt: DateTime.now(),
      settings: settings,
    );
    presets = [preset, ...presets];
    await _presetService.saveAll(presets);
    message = 'Overlay preset saved.';
    notifyListeners();
  }

  Future<void> loadPreset(OverlayPreset preset) async {
    await _replaceSettings(
      preset.settings,
      selectedId: preset.settings.items.isEmpty
          ? null
          : preset.settings.items.first.id,
    );
    message = 'Overlay preset applied.';
  }

  Future<void> applySettings(OverlaySettings value) async {
    await _replaceSettings(
      value,
      selectedId: value.items.isEmpty ? null : value.items.first.id,
    );
    message = 'Overlay settings applied.';
  }

  Future<void> clearCanvas() async {
    await _replaceSettings(const OverlaySettings(), selectedId: null);
    message = 'Canvas cleared.';
  }

  Future<void> loadOverlaySettings(OverlaySettings value) async {
    await _replaceSettings(
      value,
      selectedId: value.items.isEmpty ? null : value.items.first.id,
    );
    message = 'Overlay settings loaded.';
  }

  Future<void> renamePreset({
    required OverlayPreset preset,
    required String name,
  }) async {
    final nextName = name.trim();
    if (nextName.isEmpty) return;
    presets = [
      for (final item in presets)
        if (item.id == preset.id) item.copyWith(name: nextName) else item,
    ];
    await _presetService.saveAll(presets);
    message = 'Overlay preset renamed.';
    notifyListeners();
  }

  Future<void> deletePreset(OverlayPreset preset) async {
    presets = presets.where((item) => item.id != preset.id).toList();
    await _presetService.saveAll(presets);
    message = 'Overlay preset deleted.';
    notifyListeners();
  }

  // --- Alignment Panel Calculations ---
  final Map<String, double> _exactHeights = {};

  void reportExactHeight(String id, double heightPercent) {
    _exactHeights[id] = heightPercent;
  }

  double _getEstimatedHeight(OverlayItem item) {
    if (_exactHeights.containsKey(item.id)) {
      return _exactHeights[item.id]!;
    }
    return item.customHeight ?? (item.type == OverlayItemType.image ? item.width : 0.05);
  }

  Future<void> alignLeft() async {
    final selected = settings.items.where((e) => selectedItemIds.contains(e.id)).toList();
    if (selected.isEmpty) return;
    
    final nextItems = settings.items.map((e) {
      if (selectedItemIds.contains(e.id) && !e.locked) {
        final targetX = 0.0;
        debugPrint('--- ALIGN DEBUG ---');
        debugPrint('Action: Align Left, Item ID: ${e.id}');
        debugPrint('Old X: ${e.position.xPercent}, New X: $targetX');
        debugPrint('-------------------');
        return e.copyWith(position: e.position.copyWith(xPercent: targetX));
      }
      return e;
    }).toList();
    await _replaceSettings(settings.copyWith(items: nextItems));
  }

  Future<void> alignRight() async {
    final selected = settings.items.where((e) => selectedItemIds.contains(e.id)).toList();
    if (selected.isEmpty) return;
    
    final nextItems = settings.items.map((e) {
      if (selectedItemIds.contains(e.id) && !e.locked) {
        final targetX = 1.0 - e.width;
        debugPrint('--- ALIGN DEBUG ---');
        debugPrint('Action: Align Right, Item ID: ${e.id}');
        debugPrint('Old X: ${e.position.xPercent}, New X: $targetX');
        debugPrint('-------------------');
        return e.copyWith(position: e.position.copyWith(xPercent: targetX));
      }
      return e;
    }).toList();
    await _replaceSettings(settings.copyWith(items: nextItems));
  }

  Future<void> alignCenterX() async {
    final selected = settings.items.where((e) => selectedItemIds.contains(e.id)).toList();
    if (selected.isEmpty) return;
    
    final nextItems = settings.items.map((e) {
      if (selectedItemIds.contains(e.id) && !e.locked) {
        final targetX = 0.5 - e.width / 2;
        debugPrint('--- ALIGN DEBUG ---');
        debugPrint('Action: Center X, Item ID: ${e.id}');
        debugPrint('Old X: ${e.position.xPercent}, New X: $targetX');
        debugPrint('-------------------');
        return e.copyWith(position: e.position.copyWith(xPercent: targetX));
      }
      return e;
    }).toList();
    await _replaceSettings(settings.copyWith(items: nextItems));
  }

  Future<void> alignTop() async {
    final selected = settings.items.where((e) => selectedItemIds.contains(e.id)).toList();
    if (selected.isEmpty) return;
    
    final nextItems = settings.items.map((e) {
      if (selectedItemIds.contains(e.id) && !e.locked) {
        final targetY = 0.0;
        debugPrint('--- ALIGN DEBUG ---');
        debugPrint('Action: Align Top, Item ID: ${e.id}');
        debugPrint('Old Y: ${e.position.yPercent}, New Y: $targetY');
        debugPrint('-------------------');
        return e.copyWith(position: e.position.copyWith(yPercent: targetY));
      }
      return e;
    }).toList();
    await _replaceSettings(settings.copyWith(items: nextItems));
  }

  Future<void> alignBottom() async {
    final selected = settings.items.where((e) => selectedItemIds.contains(e.id)).toList();
    if (selected.isEmpty) return;
    
    final nextItems = settings.items.map((e) {
      if (selectedItemIds.contains(e.id) && !e.locked) {
        final h = _getEstimatedHeight(e);
        final targetY = 1.0 - h;
        debugPrint('--- ALIGN DEBUG ---');
        debugPrint('Action: Align Bottom, Item ID: ${e.id}');
        debugPrint('Old Y: ${e.position.yPercent}, New Y: $targetY');
        debugPrint('-------------------');
        return e.copyWith(position: e.position.copyWith(yPercent: targetY));
      }
      return e;
    }).toList();
    await _replaceSettings(settings.copyWith(items: nextItems));
  }

  Future<void> alignCenterY() async {
    final selected = settings.items.where((e) => selectedItemIds.contains(e.id)).toList();
    if (selected.isEmpty) return;
    
    final nextItems = settings.items.map((e) {
      if (selectedItemIds.contains(e.id) && !e.locked) {
        final h = _getEstimatedHeight(e);
        final targetY = 0.5 - h / 2;
        debugPrint('--- ALIGN DEBUG ---');
        debugPrint('Action: Center Y, Item ID: ${e.id}');
        debugPrint('Old Y: ${e.position.yPercent}, New Y: $targetY');
        debugPrint('-------------------');
        return e.copyWith(position: e.position.copyWith(yPercent: targetY));
      }
      return e;
    }).toList();
    await _replaceSettings(settings.copyWith(items: nextItems));
  }

  Future<void> distributeHorizontal() async {
    final selected = settings.items.where((e) => selectedItemIds.contains(e.id)).toList();
    if (selected.length < 3) return;
    selected.sort((a, b) => (a.position.xPercent + a.width / 2).compareTo(b.position.xPercent + b.width / 2));
    final firstCenter = selected.first.position.xPercent + selected.first.width / 2;
    final lastCenter = selected.last.position.xPercent + selected.last.width / 2;
    final spacing = (lastCenter - firstCenter) / (selected.length - 1);

    final nextItems = settings.items.map((e) {
      final index = selected.indexWhere((s) => s.id == e.id);
      if (index != -1 && !e.locked) {
        final targetCenter = firstCenter + index * spacing;
        return e.copyWith(position: e.position.copyWith(xPercent: targetCenter - e.width / 2));
      }
      return e;
    }).toList();
    await _replaceSettings(settings.copyWith(items: nextItems));
  }

  Future<void> distributeVertical() async {
    final selected = settings.items.where((e) => selectedItemIds.contains(e.id)).toList();
    if (selected.length < 3) return;
    selected.sort((a, b) => (a.position.yPercent + _getEstimatedHeight(a) / 2).compareTo(b.position.yPercent + _getEstimatedHeight(b) / 2));
    final firstCenter = selected.first.position.yPercent + _getEstimatedHeight(selected.first) / 2;
    final lastCenter = selected.last.position.yPercent + _getEstimatedHeight(selected.last) / 2;
    final spacing = (lastCenter - firstCenter) / (selected.length - 1);

    final nextItems = settings.items.map((e) {
      final index = selected.indexWhere((s) => s.id == e.id);
      if (index != -1 && !e.locked) {
        final targetCenter = firstCenter + index * spacing;
        final h = _getEstimatedHeight(e);
        return e.copyWith(position: e.position.copyWith(yPercent: targetCenter - h / 2));
      }
      return e;
    }).toList();
    await _replaceSettings(settings.copyWith(items: nextItems));
  }

  Future<void> _replaceSettings(
    OverlaySettings value, {
    String? selectedId,
    bool saveToDisk = true,
  }) async {
    settings = value;
    selectedItemId = selectedId ?? selectedItemId;
    if (selectedItemId != null &&
        !settings.items.any((item) => item.id == selectedItemId)) {
      selectedItemId = settings.items.isEmpty ? null : settings.items.first.id;
    }
    if (selectedItemId != null) {
      selectedItemIds.clear();
      selectedItemIds.add(selectedItemId!);
    } else {
      selectedItemIds.clear();
    }
    notifyListeners();
    if (saveToDisk) {
      await _settingsService.save(settings);
    }
  }

  Future<void> saveSettingsToDisk() async {
    await _settingsService.save(settings);
  }

  String _newId() => DateTime.now().microsecondsSinceEpoch.toString();

  OverlayItem? _itemById(String id) {
    for (final item in settings.items) {
      if (item.id == id) return item;
    }
    return null;
  }

  @override
  void dispose() {
    _playbackTimer?.cancel();
    super.dispose();
  }
}

import 'package:file_picker/file_picker.dart';
import 'package:flutter/foundation.dart';
import 'package:soundswap/core/video/video_output_settings.dart';
import 'package:soundswap/features/overlay_tools/data/models/overlay_item.dart';
import 'package:soundswap/features/overlay_tools/data/models/overlay_preset.dart';
import 'package:soundswap/features/overlay_tools/data/models/overlay_settings.dart';
import 'package:soundswap/features/overlay_tools/data/services/overlay_preset_service.dart';
import 'package:soundswap/features/overlay_tools/data/services/overlay_settings_service.dart';

class OverlayToolsController extends ChangeNotifier {
  OverlayToolsController({
    OverlaySettingsService? settingsService,
    OverlayPresetService? presetService,
  }) : _settingsService = settingsService ?? OverlaySettingsService(),
       _presetService = presetService ?? OverlayPresetService();

  final OverlaySettingsService _settingsService;
  final OverlayPresetService _presetService;

  OverlaySettings settings = const OverlaySettings();
  List<OverlayPreset> presets = [];
  String? selectedItemId;
  String? message;
  String? errorMessage;

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
      if (settings.items.isNotEmpty) {
        selectedItemId = settings.items.first.id;
      }
      errorMessage = null;
    } catch (error) {
      errorMessage = error.toString();
    }
    notifyListeners();
  }

  Future<void> addText() async {
    final item = OverlayItem(
      id: _newId(),
      type: OverlayItemType.text,
      name: 'Text overlay',
      text: 'New text',
      position: const NormalizedPosition(x: 0.1, y: 0.18),
      fontPath: settings.defaultFontPath,
      fontFamily: settings.defaultFontFamily,
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

    final item = OverlayItem(
      id: _newId(),
      type: OverlayItemType.image,
      name: 'Image overlay',
      imagePath: path,
      position: const NormalizedPosition(x: 0.08, y: 0.08),
      width: 0.22,
    );
    await _replaceSettings(
      settings.copyWith(items: [item, ...settings.items]),
      selectedId: item.id,
    );
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
    notifyListeners();
  }

  Future<void> updateSelected(OverlayItem item) async {
    await updateItem(item);
  }

  Future<void> updateItem(OverlayItem item) async {
    await _replaceSettings(
      settings.copyWith(
        items: [
          for (final existing in settings.items)
            if (existing.id == item.id) item else existing,
        ],
      ),
      selectedId: item.id,
    );
  }

  Future<void> moveItem(String id, NormalizedPosition position) async {
    final item = _itemById(id);
    if (item == null) return;
    await updateItem(item.copyWith(position: position));
  }

  Future<void> resizeItem(String id, double width) async {
    final item = _itemById(id);
    if (item == null) return;
    await updateItem(item.copyWith(width: width));
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

  Future<void> _replaceSettings(
    OverlaySettings value, {
    String? selectedId,
  }) async {
    settings = value;
    selectedItemId = selectedId ?? selectedItemId;
    if (selectedItemId != null &&
        !settings.items.any((item) => item.id == selectedItemId)) {
      selectedItemId = settings.items.isEmpty ? null : settings.items.first.id;
    }
    notifyListeners();
    await _settingsService.save(settings);
  }

  String _newId() => DateTime.now().microsecondsSinceEpoch.toString();

  OverlayItem? _itemById(String id) {
    for (final item in settings.items) {
      if (item.id == id) return item;
    }
    return null;
  }
}

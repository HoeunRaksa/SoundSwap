import 'package:flutter/foundation.dart';
import 'package:soundswap/features/text_overlay/data/models/text_overlay_preset.dart';
import 'package:soundswap/features/text_overlay/data/models/text_overlay_settings.dart';
import 'package:soundswap/features/text_overlay/data/services/text_overlay_preset_service.dart';
import 'package:soundswap/features/text_overlay/data/services/text_overlay_settings_service.dart';
import 'package:soundswap/features/fonts/data/services/font_service.dart';

class TextOverlayController extends ChangeNotifier {
  TextOverlayController({
    TextOverlaySettingsService? service,
    TextOverlayPresetService? presetService,
  }) : _service = service ?? TextOverlaySettingsService(),
       _presetService = presetService ?? TextOverlayPresetService();

  final TextOverlaySettingsService _service;
  final TextOverlayPresetService _presetService;
  TextOverlaySettings settings = const TextOverlaySettings();
  List<TextOverlayPreset> presets = [];
  bool isLoading = false;
  String? errorMessage;
  String? message;

  Future<void> load() async {
    isLoading = true;
    notifyListeners();
    try {
      settings = await _service.load();
      presets = await _presetService.load();
      errorMessage = null;
    } catch (error) {
      errorMessage = error.toString();
    } finally {
      isLoading = false;
      notifyListeners();
    }
  }

  Future<void> update(TextOverlaySettings value) async {
    if (value.fontFamily != settings.fontFamily) {
      await FontService().copyWindowsFontIfSelected(value.fontFamily);
    }
    settings = value;
    notifyListeners();
    await _service.save(settings);
  }

  Future<void> savePreset(String name) async {
    final presetName = name.trim().isEmpty ? 'Untitled text' : name.trim();
    final preset = TextOverlayPreset(
      id: DateTime.now().microsecondsSinceEpoch.toString(),
      name: presetName,
      createdAt: DateTime.now(),
      settings: settings,
    );
    presets = [preset, ...presets];
    await _presetService.saveAll(presets);
    message = 'Text preset saved.';
    notifyListeners();
  }

  Future<void> loadPreset(TextOverlayPreset preset) async {
    await update(preset.settings);
    message = 'Text preset loaded.';
    notifyListeners();
  }

  Future<void> renamePreset({
    required TextOverlayPreset preset,
    required String name,
  }) async {
    final nextName = name.trim();
    if (nextName.isEmpty) return;
    presets = [
      for (final item in presets)
        if (item.id == preset.id) item.copyWith(name: nextName) else item,
    ];
    await _presetService.saveAll(presets);
    message = 'Text preset renamed.';
    notifyListeners();
  }

  Future<void> deletePreset(TextOverlayPreset preset) async {
    presets = presets.where((item) => item.id != preset.id).toList();
    await _presetService.saveAll(presets);
    message = 'Text preset deleted.';
    notifyListeners();
  }
}

import 'package:file_picker/file_picker.dart';
import 'package:flutter/foundation.dart';
import 'package:soundswap/features/branding/data/models/branding_preset.dart';
import 'package:soundswap/features/branding/data/models/branding_settings.dart';
import 'package:soundswap/features/branding/data/services/branding_preset_service.dart';
import 'package:soundswap/features/branding/data/services/branding_settings_service.dart';

class BrandingController extends ChangeNotifier {
  BrandingController({
    BrandingSettingsService? service,
    BrandingPresetService? presetService,
  }) : _service = service ?? BrandingSettingsService(),
       _presetService = presetService ?? BrandingPresetService();

  final BrandingSettingsService _service;
  final BrandingPresetService _presetService;
  BrandingSettings settings = const BrandingSettings();
  List<BrandingPreset> presets = [];
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

  Future<void> pickLogo() async {
    final result = await FilePicker.platform.pickFiles(type: FileType.image);
    final path = result?.files.single.path;
    if (path != null) {
      await update(settings.copyWith(logoPath: path));
    }
  }

  Future<void> update(BrandingSettings value) async {
    settings = value;
    notifyListeners();
    await _service.save(settings);
  }

  Future<void> savePreset(String name) async {
    final presetName = name.trim().isEmpty ? 'Untitled branding' : name.trim();
    final preset = BrandingPreset(
      id: DateTime.now().microsecondsSinceEpoch.toString(),
      name: presetName,
      createdAt: DateTime.now(),
      settings: settings,
    );
    presets = [preset, ...presets];
    await _presetService.saveAll(presets);
    message = 'Branding preset saved.';
    notifyListeners();
  }

  Future<void> loadPreset(BrandingPreset preset) async {
    await update(preset.settings);
    message = 'Branding preset loaded.';
    notifyListeners();
  }

  Future<void> renamePreset({
    required BrandingPreset preset,
    required String name,
  }) async {
    final nextName = name.trim();
    if (nextName.isEmpty) return;
    presets = [
      for (final item in presets)
        if (item.id == preset.id) item.copyWith(name: nextName) else item,
    ];
    await _presetService.saveAll(presets);
    message = 'Branding preset renamed.';
    notifyListeners();
  }

  Future<void> deletePreset(BrandingPreset preset) async {
    presets = presets.where((item) => item.id != preset.id).toList();
    await _presetService.saveAll(presets);
    message = 'Branding preset deleted.';
    notifyListeners();
  }
}

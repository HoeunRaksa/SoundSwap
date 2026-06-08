import 'package:flutter/foundation.dart';
import 'package:soundswap/features/effects/data/models/effects_settings.dart';
import 'package:soundswap/features/effects/data/services/effects_settings_service.dart';

class EffectsController extends ChangeNotifier {
  EffectsController({EffectsSettingsService? service})
    : _service = service ?? EffectsSettingsService();

  final EffectsSettingsService _service;
  EffectsSettings settings = const EffectsSettings();
  String? errorMessage;

  Future<void> load() async {
    try {
      settings = await _service.load();
      errorMessage = null;
    } catch (error) {
      errorMessage = error.toString();
    }
    notifyListeners();
  }

  Future<void> update(EffectsSettings value) async {
    settings = value;
    notifyListeners();
    await _service.save(settings);
  }
}

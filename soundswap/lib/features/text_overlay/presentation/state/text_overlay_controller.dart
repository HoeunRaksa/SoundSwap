import 'package:flutter/foundation.dart';
import 'package:soundswap/features/text_overlay/data/models/text_overlay_settings.dart';
import 'package:soundswap/features/text_overlay/data/services/text_overlay_settings_service.dart';

class TextOverlayController extends ChangeNotifier {
  TextOverlayController({TextOverlaySettingsService? service})
    : _service = service ?? TextOverlaySettingsService();

  final TextOverlaySettingsService _service;
  TextOverlaySettings settings = const TextOverlaySettings();
  bool isLoading = false;
  String? errorMessage;

  Future<void> load() async {
    isLoading = true;
    notifyListeners();
    try {
      settings = await _service.load();
      errorMessage = null;
    } catch (error) {
      errorMessage = error.toString();
    } finally {
      isLoading = false;
      notifyListeners();
    }
  }

  Future<void> update(TextOverlaySettings value) async {
    settings = value;
    notifyListeners();
    await _service.save(settings);
  }
}

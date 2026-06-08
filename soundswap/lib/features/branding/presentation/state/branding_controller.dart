import 'package:file_picker/file_picker.dart';
import 'package:flutter/foundation.dart';
import 'package:soundswap/features/branding/data/models/branding_settings.dart';
import 'package:soundswap/features/branding/data/services/branding_settings_service.dart';

class BrandingController extends ChangeNotifier {
  BrandingController({BrandingSettingsService? service})
    : _service = service ?? BrandingSettingsService();

  final BrandingSettingsService _service;
  BrandingSettings settings = const BrandingSettings();
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
}

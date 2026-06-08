import 'package:soundswap/features/branding/data/models/branding_settings.dart';
import 'package:soundswap/shared/services/local_json_store.dart';

class BrandingSettingsService {
  BrandingSettingsService({LocalJsonStore? store})
    : _store = store ?? LocalJsonStore();

  final LocalJsonStore _store;
  static const _fileName = 'branding_settings.json';

  Future<BrandingSettings> load() async {
    return BrandingSettings.fromJson(await _store.readMap(_fileName));
  }

  Future<void> save(BrandingSettings settings) {
    return _store.writeMap(_fileName, settings.toJson());
  }
}

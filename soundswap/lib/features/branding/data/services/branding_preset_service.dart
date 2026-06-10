import 'package:soundswap/features/branding/data/models/branding_preset.dart';
import 'package:soundswap/shared/services/local_json_store.dart';

class BrandingPresetService {
  BrandingPresetService({LocalJsonStore? store})
    : _store = store ?? LocalJsonStore();

  final LocalJsonStore _store;
  static const _fileName = 'branding_presets.json';

  Future<List<BrandingPreset>> load() async {
    final values = await _store.readList(_fileName);
    return values
        .whereType<Map>()
        .map((value) => BrandingPreset.fromJson(value.cast<String, Object?>()))
        .toList();
  }

  Future<void> saveAll(List<BrandingPreset> presets) {
    return _store.writeList(
      _fileName,
      presets.map((preset) => preset.toJson()).toList(),
    );
  }
}

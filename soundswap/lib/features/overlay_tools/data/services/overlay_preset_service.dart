import 'package:soundswap/features/overlay_tools/data/models/overlay_preset.dart';
import 'package:soundswap/shared/services/local_json_store.dart';

class OverlayPresetService {
  OverlayPresetService({LocalJsonStore? store})
    : _store = store ?? LocalJsonStore();

  final LocalJsonStore _store;
  static const _fileName = 'overlay_presets.json';

  Future<List<OverlayPreset>> load() async {
    final values = await _store.readList(_fileName);
    return values
        .whereType<Map>()
        .map((value) => OverlayPreset.fromJson(value.cast<String, Object?>()))
        .toList();
  }

  Future<void> saveAll(List<OverlayPreset> presets) {
    return _store.writeList(
      _fileName,
      presets.map((preset) => preset.toJson()).toList(),
    );
  }
}

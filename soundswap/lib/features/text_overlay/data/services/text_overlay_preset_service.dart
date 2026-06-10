import 'package:soundswap/features/text_overlay/data/models/text_overlay_preset.dart';
import 'package:soundswap/shared/services/local_json_store.dart';

class TextOverlayPresetService {
  TextOverlayPresetService({LocalJsonStore? store})
    : _store = store ?? LocalJsonStore();

  final LocalJsonStore _store;
  static const _fileName = 'text_overlay_presets.json';

  Future<List<TextOverlayPreset>> load() async {
    final values = await _store.readList(_fileName);
    return values
        .whereType<Map>()
        .map(
          (value) => TextOverlayPreset.fromJson(value.cast<String, Object?>()),
        )
        .toList();
  }

  Future<void> saveAll(List<TextOverlayPreset> presets) {
    return _store.writeList(
      _fileName,
      presets.map((preset) => preset.toJson()).toList(),
    );
  }
}

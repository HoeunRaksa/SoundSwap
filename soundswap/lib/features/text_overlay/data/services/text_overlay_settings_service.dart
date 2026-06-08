import 'package:soundswap/features/text_overlay/data/models/text_overlay_settings.dart';
import 'package:soundswap/shared/services/local_json_store.dart';

class TextOverlaySettingsService {
  TextOverlaySettingsService({LocalJsonStore? store})
    : _store = store ?? LocalJsonStore();

  final LocalJsonStore _store;
  static const _fileName = 'text_overlay_settings.json';

  Future<TextOverlaySettings> load() async {
    return TextOverlaySettings.fromJson(await _store.readMap(_fileName));
  }

  Future<void> save(TextOverlaySettings settings) {
    return _store.writeMap(_fileName, settings.toJson());
  }
}

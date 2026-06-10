import 'package:soundswap/features/overlay_tools/data/models/overlay_settings.dart';
import 'package:soundswap/shared/services/local_json_store.dart';

class OverlaySettingsService {
  OverlaySettingsService({LocalJsonStore? store})
    : _store = store ?? LocalJsonStore();

  final LocalJsonStore _store;
  static const _fileName = 'overlay_settings.json';

  Future<OverlaySettings> load() async {
    return OverlaySettings.fromJson(await _store.readMap(_fileName));
  }

  Future<void> save(OverlaySettings settings) {
    return _store.writeMap(_fileName, settings.toJson());
  }
}

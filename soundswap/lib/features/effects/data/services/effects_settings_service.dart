import 'package:soundswap/features/effects/data/models/effects_settings.dart';
import 'package:soundswap/shared/services/local_json_store.dart';

class EffectsSettingsService {
  EffectsSettingsService({LocalJsonStore? store})
    : _store = store ?? LocalJsonStore();

  final LocalJsonStore _store;
  static const _fileName = 'effects_settings.json';

  Future<EffectsSettings> load() async {
    return EffectsSettings.fromJson(await _store.readMap(_fileName));
  }

  Future<void> save(EffectsSettings settings) {
    return _store.writeMap(_fileName, settings.toJson());
  }
}

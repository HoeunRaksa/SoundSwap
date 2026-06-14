import 'package:soundswap/features/long_video/data/models/long_video_settings.dart';
import 'package:soundswap/shared/services/local_json_store.dart';

class LongVideoSettingsService {
  LongVideoSettingsService({LocalJsonStore? store})
      : _store = store ?? LocalJsonStore();

  final LocalJsonStore _store;
  static const _fileName = 'long_video_settings.json';

  Future<LongVideoSettings?> load() async {
    final value = await _store.readMap(_fileName);
    if (value.isEmpty) return null;
    return LongVideoSettings.fromJson(value);
  }

  Future<void> save(LongVideoSettings settings) {
    return _store.writeMap(_fileName, settings.toJson());
  }
}

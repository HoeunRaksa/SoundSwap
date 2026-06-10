import 'package:soundswap/features/home/data/models/batch_profile.dart';
import 'package:soundswap/shared/services/local_json_store.dart';

class HomeStateService {
  HomeStateService({LocalJsonStore? store})
    : _store = store ?? LocalJsonStore();

  final LocalJsonStore _store;
  static const _fileName = 'home_state.json';

  Future<BatchProfile?> load() async {
    final value = await _store.readMap(_fileName);
    if (value.isEmpty) return null;
    return BatchProfile.fromJson(value);
  }

  Future<void> save(BatchProfile state) {
    return _store.writeMap(_fileName, state.toJson());
  }
}

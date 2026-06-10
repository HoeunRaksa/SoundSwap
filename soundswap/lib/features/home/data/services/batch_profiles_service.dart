import 'package:soundswap/features/home/data/models/batch_profile.dart';
import 'package:soundswap/shared/services/local_json_store.dart';

class BatchProfilesService {
  BatchProfilesService({LocalJsonStore? store})
    : _store = store ?? LocalJsonStore();

  final LocalJsonStore _store;
  static const _fileName = 'batch_profiles.json';

  Future<List<BatchProfile>> load() async {
    final values = await _store.readList(_fileName);
    return values
        .whereType<Map>()
        .map((value) => BatchProfile.fromJson(value.cast<String, Object?>()))
        .toList();
  }

  Future<void> saveAll(List<BatchProfile> profiles) {
    return _store.writeList(
      _fileName,
      profiles.map((profile) => profile.toJson()).toList(),
    );
  }
}

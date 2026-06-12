import 'package:soundswap/features/organizer_watch/data/models/organizer_watch_profile.dart';
import 'package:soundswap/shared/services/local_json_store.dart';

class OrganizerWatchProfilesService {
  OrganizerWatchProfilesService({LocalJsonStore? store})
      : _store = store ?? LocalJsonStore();

  final LocalJsonStore _store;
  static const _fileName = 'organizer_watch_profiles.json';

  Future<List<OrganizerWatchProfile>> loadAll() async {
    try {
      final values = await _store.readList(_fileName);
      return values
          .whereType<Map>()
          .map((v) => OrganizerWatchProfile.fromJson(v.cast<String, Object?>()))
          .toList();
    } catch (_) {
      return [];
    }
  }

  Future<void> saveAll(List<OrganizerWatchProfile> profiles) async {
    await _store.writeList(
      _fileName,
      profiles.map((p) => p.toJson()).toList(),
    );
  }
}

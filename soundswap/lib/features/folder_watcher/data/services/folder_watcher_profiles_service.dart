import 'package:soundswap/features/folder_watcher/data/models/folder_watcher_profile.dart';
import 'package:soundswap/shared/services/local_json_store.dart';

class FolderWatcherProfilesService {
  FolderWatcherProfilesService({LocalJsonStore? store})
    : _store = store ?? LocalJsonStore();

  final LocalJsonStore _store;
  static const _fileName = 'folder_watcher_profiles.json';

  Future<List<FolderWatcherProfile>> load() async {
    final values = await _store.readList(_fileName);
    return values
        .whereType<Map>()
        .map(
          (value) =>
              FolderWatcherProfile.fromJson(value.cast<String, Object?>()),
        )
        .where((profile) => profile.id.isNotEmpty)
        .toList();
  }

  Future<void> saveAll(List<FolderWatcherProfile> profiles) {
    return _store.writeList(
      _fileName,
      profiles.map((profile) => profile.toJson()).toList(),
    );
  }
}

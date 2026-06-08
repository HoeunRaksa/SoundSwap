import 'package:soundswap/features/folder_watcher/data/models/folder_watcher_settings.dart';
import 'package:soundswap/shared/services/local_json_store.dart';

class FolderWatcherSettingsService {
  FolderWatcherSettingsService({LocalJsonStore? store})
    : _store = store ?? LocalJsonStore();

  final LocalJsonStore _store;
  static const _fileName = 'folder_watcher_settings.json';

  Future<FolderWatcherSettings> load() async {
    return FolderWatcherSettings.fromJson(await _store.readMap(_fileName));
  }

  Future<void> save(FolderWatcherSettings settings) {
    return _store.writeMap(_fileName, settings.toJson());
  }
}

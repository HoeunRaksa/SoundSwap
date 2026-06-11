import 'package:soundswap/features/overlay_tools/data/models/asset_library_item.dart';
import 'package:soundswap/shared/services/local_json_store.dart';

class AssetLibraryService {
  AssetLibraryService({LocalJsonStore? store})
    : _store = store ?? LocalJsonStore();

  final LocalJsonStore _store;
  static const _fileName = 'asset_library.json';

  Future<List<AssetLibraryItem>> load() async {
    final values = await _store.readList(_fileName);
    return values
        .whereType<Map>()
        .map((value) => AssetLibraryItem.fromJson(value.cast<String, Object?>()))
        .toList();
  }

  Future<void> saveAll(List<AssetLibraryItem> items) {
    return _store.writeList(
      _fileName,
      items.map((item) => item.toJson()).toList(),
    );
  }
}

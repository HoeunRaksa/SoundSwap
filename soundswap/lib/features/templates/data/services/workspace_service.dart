import 'package:soundswap/features/templates/data/models/project_workspace.dart';
import 'package:soundswap/shared/services/local_json_store.dart';

class WorkspaceService {
  WorkspaceService({LocalJsonStore? store})
    : _store = store ?? LocalJsonStore();

  final LocalJsonStore _store;
  static const _fileName = 'workspaces.json';

  Future<List<ProjectWorkspace>> load() async {
    final values = await _store.readList(_fileName);
    return values
        .whereType<Map>()
        .map((value) => ProjectWorkspace.fromJson(value.cast<String, Object?>()))
        .toList();
  }

  Future<void> saveAll(List<ProjectWorkspace> items) {
    return _store.writeList(
      _fileName,
      items.map((item) => item.toJson()).toList(),
    );
  }
}

import 'package:soundswap/features/templates/data/models/project_template.dart';
import 'package:soundswap/shared/services/local_json_store.dart';

class TemplatesService {
  TemplatesService({LocalJsonStore? store})
    : _store = store ?? LocalJsonStore();

  final LocalJsonStore _store;
  static const _fileName = 'project_templates.json';

  Future<List<ProjectTemplate>> load() async {
    final values = await _store.readList(_fileName);
    return values
        .whereType<Map>()
        .map((value) => ProjectTemplate.fromJson(value.cast<String, Object?>()))
        .toList();
  }

  Future<void> saveAll(List<ProjectTemplate> templates) {
    return _store.writeList(
      _fileName,
      templates.map((template) => template.toJson()).toList(),
    );
  }
}

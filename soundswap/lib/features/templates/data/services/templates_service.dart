import 'package:flutter/cupertino.dart';
import '../../../../shared/services/local_json_store.dart';
import '../models/project_template.dart';

class TemplatesService {
  TemplatesService({LocalJsonStore? store})
    : _store = store ?? LocalJsonStore();

  final LocalJsonStore _store;
  static const _fileName = 'project_templates.json';

  Future<List<ProjectTemplate>> load() async {
    debugPrint('\n[TemplatesService] Loading templates from $_fileName...');
    final values = await _store.readList(_fileName);
    final templates = values
        .whereType<Map>()
        .map((value) => ProjectTemplate.fromJson(value.cast<String, Object?>()))
        .toList();
    for (final t in templates) {
      debugPrint('[TemplatesService] Loaded: ${t.name} (id: ${t.id}) -> thumbnailPath: ${t.thumbnailPath}');
      debugPrint('[TemplatesService] loaded thumbnailPath=${t.thumbnailPath}');
    }
    return templates;
  }

  Future<void> saveAll(List<ProjectTemplate> templates) async {
    debugPrint('\n[TemplatesService] Saving ${templates.length} templates...');
    for (final t in templates) {
      debugPrint('[TemplatesService] Saving: ${t.name} (id: ${t.id}) -> thumbnailPath: ${t.thumbnailPath}');
    }
    await _store.writeList(
      _fileName,
      templates.map((template) => template.toJson()).toList(),
    );
    for (final t in templates) {
      debugPrint('[TemplatesService] saved thumbnailPath=${t.thumbnailPath}');
    }
  }
}

import 'dart:io';

import 'package:soundswap/features/product_import/data/models/product_row.dart';
import 'package:soundswap/shared/services/local_json_store.dart';

class ProductImportService {
  ProductImportService({LocalJsonStore? store})
    : _store = store ?? LocalJsonStore();

  final LocalJsonStore _store;
  static const _fileName = 'product_rows.json';

  Future<List<ProductRow>> loadSavedRows() async {
    final values = await _store.readList(_fileName);
    return values
        .whereType<Map>()
        .map((value) => ProductRow.fromJson(value.cast<String, Object?>()))
        .toList();
  }

  Future<void> saveRows(List<ProductRow> rows) {
    return _store.writeList(
      _fileName,
      rows.map((row) => row.toJson()).toList(),
    );
  }

  Future<List<ProductRow>> importCsv(String path) async {
    final content = await File(path).readAsString();
    final lines = content
        .split(RegExp(r'\r?\n'))
        .where((line) => line.trim().isNotEmpty)
        .toList();
    if (lines.isEmpty) return [];

    final headers = _parseCsvLine(lines.first).map((h) => h.trim()).toList();
    final rows = <ProductRow>[];
    for (final line in lines.skip(1)) {
      final values = _parseCsvLine(line);
      String value(String key) {
        final index = headers.indexOf(key);
        return index >= 0 && index < values.length ? values[index] : '';
      }

      rows.add(
        ProductRow(
          name: value('name'),
          price: value('price'),
          description: value('description'),
          phone: value('phone'),
        ),
      );
    }
    return rows;
  }

  // Lightweight CSV parsing for the expected product import columns. It keeps
  // quoted commas intact without adding another dependency.
  List<String> _parseCsvLine(String line) {
    final values = <String>[];
    final buffer = StringBuffer();
    var inQuotes = false;

    for (var i = 0; i < line.length; i++) {
      final char = line[i];
      if (char == '"') {
        if (inQuotes && i + 1 < line.length && line[i + 1] == '"') {
          buffer.write('"');
          i++;
        } else {
          inQuotes = !inQuotes;
        }
      } else if (char == ',' && !inQuotes) {
        values.add(buffer.toString());
        buffer.clear();
      } else {
        buffer.write(char);
      }
    }
    values.add(buffer.toString());
    return values;
  }
}

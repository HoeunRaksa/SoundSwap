import 'package:file_picker/file_picker.dart';
import 'package:flutter/foundation.dart';
import 'package:soundswap/features/product_import/data/models/product_row.dart';
import 'package:soundswap/features/product_import/data/services/product_import_service.dart';

class ProductImportController extends ChangeNotifier {
  ProductImportController({ProductImportService? service})
    : _service = service ?? ProductImportService();

  final ProductImportService _service;
  List<ProductRow> rows = [];
  String? sourcePath;
  String? errorMessage;

  Future<void> load() async {
    rows = await _service.loadSavedRows();
    notifyListeners();
  }

  Future<void> importCsv() async {
    final result = await FilePicker.platform.pickFiles(
      type: FileType.custom,
      allowedExtensions: ['csv'],
    );
    final path = result?.files.single.path;
    if (path == null) return;
    try {
      rows = await _service.importCsv(path);
      sourcePath = path;
      errorMessage = null;
      await _service.saveRows(rows);
    } catch (error) {
      errorMessage = error.toString();
    }
    notifyListeners();
  }
}

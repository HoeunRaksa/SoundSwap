import 'package:flutter/material.dart';
import 'package:file_picker/file_picker.dart';
import 'package:soundswap/features/fonts/data/services/font_service.dart';

enum FontFilter { all, builtIn, imported, windows, favorites }

class FontsController extends ChangeNotifier {
  FontsController({FontService? fontService})
      : _fontService = fontService ?? FontService() {
    _fontService.addListener(_onFontServiceChanged);
  }

  final FontService _fontService;
  
  List<AppFont> get builtInFonts => _fontService.builtInFonts;
  List<AppFont> get importedFonts => _fontService.importedFonts;
  List<AppFont> get windowsFonts => _fontService.windowsFonts;
  List<AppFont> get favoriteFonts => _fontService.favoriteFonts;

  String? selectedFont;
  String? message;
  bool isImporting = false;
  bool isScanning = false;
  
  String searchQuery = '';
  FontFilter currentFilter = FontFilter.all;

  @override
  void dispose() {
    _fontService.removeListener(_onFontServiceChanged);
    super.dispose();
  }

  void _onFontServiceChanged() {
    notifyListeners();
  }

  List<AppFont> get filteredFonts {
    List<AppFont> list = [];
    switch (currentFilter) {
      case FontFilter.all:
        list = [...builtInFonts, ...importedFonts, ...windowsFonts];
        break;
      case FontFilter.builtIn:
        list = builtInFonts;
        break;
      case FontFilter.imported:
        list = importedFonts;
        break;
      case FontFilter.windows:
        list = windowsFonts;
        break;
      case FontFilter.favorites:
        list = favoriteFonts;
        break;
    }

    if (searchQuery.isNotEmpty) {
      final q = searchQuery.toLowerCase();
      list = list.where((f) => 
        f.familyName.toLowerCase().contains(q) || 
        f.filePath.toLowerCase().contains(q)
      ).toList();
    }
    
    // Sort uniquely
    final unique = <String, AppFont>{};
    for (var f in list) {
      if (!unique.containsKey(f.familyName)) {
        unique[f.familyName] = f;
      }
    }
    final sorted = unique.values.toList()
      ..sort((a, b) => a.familyName.compareTo(b.familyName));
    return sorted;
  }

  void setSearchQuery(String q) {
    searchQuery = q;
    notifyListeners();
  }

  void setFilter(FontFilter filter) {
    currentFilter = filter;
    notifyListeners();
  }

  void selectFont(String familyName) {
    selectedFont = familyName;
    notifyListeners();
  }

  bool isFavorite(String familyName) => _fontService.isFavorite(familyName);

  Future<void> toggleFavorite(AppFont font) async {
    await _fontService.toggleFavorite(font);
  }

  Future<void> refresh() async {
    isScanning = true;
    notifyListeners();

    await _fontService.loadImportedFonts();
    await _fontService.discoverWindowsFonts();

    isScanning = false;
    notifyListeners();
  }

  Future<void> importFont() async {
    final result = await FilePicker.platform.pickFiles(
      type: FileType.custom,
      allowedExtensions: ['ttf', 'otf'],
    );
    if (result != null && result.files.single.path != null) {
      isImporting = true;
      notifyListeners();
      
      final path = result.files.single.path!;
      await _fontService.importFont(path);
      
      isImporting = false;
      message = 'Font imported successfully.';
      notifyListeners();
    }
  }

  Future<void> deleteFont(String familyName) async {
    await _fontService.deleteFont(familyName);
    if (selectedFont == familyName) {
      selectedFont = null;
    }
    message = 'Font deleted.';
    notifyListeners();
  }
  
  void clearMessage() {
    message = null;
    notifyListeners();
  }
}

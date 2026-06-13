import 'dart:convert';
import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:path/path.dart' as p;

enum FontSource { builtIn, imported, windows }

class AppFont {
  const AppFont({
    required this.familyName,
    required this.filePath,
    required this.source,
    this.copiedPath,
  });

  final String familyName;
  final String filePath;
  final FontSource source;
  final String? copiedPath;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is AppFont &&
          runtimeType == other.runtimeType &&
          familyName == other.familyName;

  @override
  int get hashCode => familyName.hashCode;

  Map<String, dynamic> toJson() => {
    'familyName': familyName,
    'filePath': filePath,
    'source': source.name,
    'copiedPath': copiedPath,
  };

  factory AppFont.fromJson(Map<String, dynamic> json) => AppFont(
    familyName: json['familyName'] as String,
    filePath: json['filePath'] as String,
    source: FontSource.values.firstWhere(
      (e) => e.name == json['source'],
      orElse: () => FontSource.imported,
    ),
    copiedPath: json['copiedPath'] as String?,
  );

  AppFont copyWith({
    String? familyName,
    String? filePath,
    FontSource? source,
    String? copiedPath,
  }) {
    return AppFont(
      familyName: familyName ?? this.familyName,
      filePath: filePath ?? this.filePath,
      source: source ?? this.source,
      copiedPath: copiedPath ?? this.copiedPath,
    );
  }
}

class FontService extends ChangeNotifier {
  static final FontService _instance = FontService._internal();
  factory FontService() => _instance;
  FontService._internal();

  final List<AppFont> _importedFonts = [];
  final List<AppFont> _builtInFonts = [
    const AppFont(familyName: 'Battambang', filePath: '', source: FontSource.builtIn),
    const AppFont(familyName: 'Hanuman', filePath: '', source: FontSource.builtIn),
    const AppFont(familyName: 'KhmerOS', filePath: '', source: FontSource.builtIn),
    const AppFont(familyName: 'Roboto', filePath: '', source: FontSource.builtIn),
    const AppFont(familyName: 'Khmer OS Siemreap', filePath: '', source: FontSource.builtIn),
    const AppFont(familyName: '.Mondulkiri U h', filePath: '', source: FontSource.builtIn),
    const AppFont(familyName: 'KunKhmer', filePath: '', source: FontSource.builtIn),
    const AppFont(familyName: 'AKbalthom Chamnap Chhun', filePath: '', source: FontSource.builtIn),
    const AppFont(familyName: 'AKbalthom Choeung Ek', filePath: '', source: FontSource.builtIn),
  ];
  final List<AppFont> _windowsFonts = [];
  List<AppFont> _favoriteFonts = [];

  List<AppFont> get builtInFonts => List.unmodifiable(_builtInFonts);
  List<AppFont> get importedFonts => List.unmodifiable(_importedFonts);
  List<AppFont> get windowsFonts => List.unmodifiable(_windowsFonts);
  List<AppFont> get favoriteFonts {
    if (_favoriteFonts.isEmpty) {
      return List.unmodifiable(_builtInFonts);
    }
    return List.unmodifiable(_favoriteFonts);
  }

  List<String> get allFonts {
    final families = <String>{};
    for (final font in _builtInFonts) { families.add(font.familyName); }
    for (final font in _importedFonts) { families.add(font.familyName); }
    for (final font in _windowsFonts) { families.add(font.familyName); }
    final sorted = families.toList()..sort();
    return sorted;
  }

  Future<Directory> getFontsDirectory() async {
    String basePath = Directory.current.path;
    if (Platform.isWindows) {
      final exeDir = p.dirname(Platform.resolvedExecutable);
      if (File(p.join(exeDir, 'data', 'flutter_assets', 'AssetManifest.json')).existsSync()) {
        basePath = exeDir;
      }
    }
    final dir = Directory(p.join(basePath, 'user_data', 'fonts'));
    if (!await dir.exists()) {
      await dir.create(recursive: true);
    }
    return dir;
  }

  Future<void> installBundledFonts() async {
    final dir = await getFontsDirectory();
    final bundled = [
      'Battambang-Regular.ttf',
      'Battambang-Bold.ttf',
      'Hanuman-Regular.ttf',
      'Hanuman-Bold.ttf',
      'KhmerOS.ttf',
      'Roboto-Regular.ttf',
      'Roboto-Bold.ttf',
      'KhmerOSSiemreap.ttf',
      'mond40uhgs.ttf',
      'KunKhmer.ttf',
      'AKbalthom Chamnap Chhun Version 1.10.ttf',
      'AKbalthom Choeung Ek.ttf',
    ];

    for (final fontName in bundled) {
      final destPath = p.join(dir.path, fontName);
      final destFile = File(destPath);
      if (!await destFile.exists()) {
        try {
          final byteData = await rootBundle.load('assets/fonts/$fontName');
          await destFile.writeAsBytes(byteData.buffer.asUint8List(byteData.offsetInBytes, byteData.lengthInBytes));
          debugPrint('Extracted bundled font: $fontName');
        } catch (e) {
          debugPrint('Failed to extract bundled font $fontName: $e');
        }
      }
    }
  }

  Future<File> getFavoritesFile() async {
    String basePath = Directory.current.path;
    if (Platform.isWindows) {
      final exeDir = p.dirname(Platform.resolvedExecutable);
      if (File(p.join(exeDir, 'data', 'flutter_assets', 'AssetManifest.json')).existsSync()) {
        basePath = exeDir;
      }
    }
    final dir = Directory(p.join(basePath, 'user_data', 'settings'));
    if (!await dir.exists()) {
      await dir.create(recursive: true);
    }
    return File(p.join(dir.path, 'favorite_fonts.json'));
  }

  Future<void> loadFavorites() async {
    try {
      final file = await getFavoritesFile();
      if (await file.exists()) {
        final content = await file.readAsString();
        final List<dynamic> jsonList = jsonDecode(content);
        _favoriteFonts = jsonList.map((e) => AppFont.fromJson(e)).toList();
      } else {
        // Defaults
        _favoriteFonts = List.from(_builtInFonts);
        await saveFavorites();
      }
    } catch (e) {
      debugPrint('Error loading favorites: $e');
      _favoriteFonts = List.from(_builtInFonts);
    }
    notifyListeners();
  }

  Future<void> saveFavorites() async {
    try {
      final file = await getFavoritesFile();
      final jsonList = _favoriteFonts.map((f) => f.toJson()).toList();
      await file.writeAsString(jsonEncode(jsonList));
    } catch (e) {
      debugPrint('Error saving favorites: $e');
    }
  }

  bool isFavorite(String familyName) {
    return _favoriteFonts.any((f) => f.familyName == familyName);
  }

  Future<void> toggleFavorite(AppFont font) async {
    final index = _favoriteFonts.indexWhere((f) => f.familyName == font.familyName);
    if (index >= 0) {
      _favoriteFonts.removeAt(index);
      debugPrint('Removed ${font.familyName} from favorites');
    } else {
      AppFont favFont = font;
      // Copy if it's a windows font
      if (font.source == FontSource.windows) {
        favFont = await _copyAndLoadWindowsFont(font) ?? font;
      }
      _favoriteFonts.add(favFont);
      debugPrint('Added ${font.familyName} to favorites');
    }
    await saveFavorites();
    notifyListeners();
  }

  String _resolveFamilyName(String fileName) {
    var name = p.basenameWithoutExtension(fileName);
    name = name.replaceAll(RegExp(r'-(Regular|Bold|Italic|BoldItalic)$', caseSensitive: false), '');
    return name;
  }

  Future<void> loadImportedFonts() async {
    _importedFonts.clear();
    final dir = await getFontsDirectory();
    final files = dir.listSync();
    
    final groupedFonts = <String, List<File>>{};
    
    for (final file in files) {
      if (file is File) {
        final ext = p.extension(file.path).toLowerCase();
        if (ext == '.ttf' || ext == '.otf') {
          final familyName = _resolveFamilyName(file.path);
          groupedFonts.putIfAbsent(familyName, () => []).add(file);
        }
      }
    }
    
    for (final entry in groupedFonts.entries) {
      final familyName = entry.key;
      final loader = FontLoader(familyName);
      for (final file in entry.value) {
        final bytes = await file.readAsBytes();
        loader.addFont(Future.value(ByteData.view(bytes.buffer)));
      }
      try {
        await loader.load();
        
        // Find regular variant if exists, otherwise first file for filePath
        final regularFile = entry.value.firstWhere(
          (f) => f.path.toLowerCase().contains('regular'), 
          orElse: () => entry.value.first
        );
        
        _importedFonts.add(AppFont(
          familyName: familyName,
          filePath: regularFile.path,
          source: FontSource.imported,
        ));
        debugPrint('Loaded custom font: $familyName with ${entry.value.length} variants');
      } catch (e) {
        debugPrint('Failed to load font $familyName: $e');
      }
    }
    await loadFavorites();
  }

  Future<void> discoverWindowsFonts() async {
    if (!Platform.isWindows) return;
    _windowsFonts.clear();
    
    final systemFontsDir = r'C:\Windows\Fonts';
    final userFontsDir = Platform.environment['LOCALAPPDATA'] != null 
        ? p.join(Platform.environment['LOCALAPPDATA']!, r'Microsoft\Windows\Fonts')
        : '';

    await _scanRegistry(r'HKLM\SOFTWARE\Microsoft\Windows NT\CurrentVersion\Fonts', systemFontsDir);
    await _scanRegistry(r'HKCU\SOFTWARE\Microsoft\Windows NT\CurrentVersion\Fonts', userFontsDir);
    notifyListeners();
  }

  Future<void> _scanRegistry(String key, String fallbackDir) async {
    try {
      final result = await Process.run('reg', ['query', key, '/s']);
      if (result.exitCode == 0) {
        final lines = result.stdout.toString().split('\n');
        for (var line in lines) {
          line = line.trim();
          if (line.isEmpty || !line.contains('REG_SZ')) continue;
          
          final parts = line.split(RegExp(r'\s+REG_SZ\s+'));
          if (parts.length == 2) {
            var rawFamilyName = parts[0].trim();
            final fileName = parts[1].trim();

            if (!fileName.toLowerCase().endsWith('.ttf') && !fileName.toLowerCase().endsWith('.otf')) {
              continue;
            }

            rawFamilyName = rawFamilyName.replaceAll(' (TrueType)', '').replaceAll(' (OpenType)', '');
            
            String fullPath = fileName;
            if (!p.isAbsolute(fullPath)) {
              fullPath = p.join(fallbackDir, fileName);
            }

            if (File(fullPath).existsSync()) {
              _windowsFonts.add(AppFont(
                familyName: rawFamilyName,
                filePath: fullPath,
                source: FontSource.windows,
              ));
            }
          }
        }
      }
    } catch (e) {
      debugPrint('Failed to query registry $key: $e');
    }
  }

  Future<void> importFont(String sourcePath) async {
    final dir = await getFontsDirectory();
    final fileName = p.basename(sourcePath);
    final destPath = p.join(dir.path, fileName);
    
    final sourceFile = File(sourcePath);
    if (!File(destPath).existsSync() || sourceFile.path != destPath) {
      await sourceFile.copy(destPath);
    }
    
    final familyName = p.basenameWithoutExtension(destPath);
    try {
      final bytes = await File(destPath).readAsBytes();
      final loader = FontLoader(familyName);
      loader.addFont(Future.value(ByteData.view(bytes.buffer)));
      await loader.load();
      
      final existingIndex = _importedFonts.indexWhere((f) => f.familyName == familyName);
      final newFont = AppFont(familyName: familyName, filePath: destPath, source: FontSource.imported);
      if (existingIndex >= 0) {
        _importedFonts[existingIndex] = newFont;
      } else {
        _importedFonts.add(newFont);
      }
      debugPrint('Successfully imported and loaded font: $familyName');
      notifyListeners();
    } catch (e) {
      debugPrint('Failed to load imported font $familyName: $e');
    }
  }

  Future<AppFont?> _copyAndLoadWindowsFont(AppFont font) async {
    if (_importedFonts.any((f) => f.familyName == font.familyName)) return font;

    debugPrint('Copying Windows font "${font.familyName}" to user_data/fonts...');
    final dir = await getFontsDirectory();
    final safeName = font.familyName.replaceAll(RegExp(r'[^\w\s-]'), '').trim().replaceAll(' ', '');
    final ext = p.extension(font.filePath);
    final destPath = p.join(dir.path, '$safeName$ext');

    try {
      final sourceFile = File(font.filePath);
      await sourceFile.copy(destPath);

      final bytes = await File(destPath).readAsBytes();
      final loader = FontLoader(font.familyName);
      loader.addFont(Future.value(ByteData.view(bytes.buffer)));
      await loader.load();
      
      final newFont = AppFont(
        familyName: font.familyName,
        filePath: font.filePath,
        source: font.source,
        copiedPath: destPath,
      );
      
      // Also add to imported internally so it doesn't get copied again
      _importedFonts.add(AppFont(
        familyName: font.familyName,
        filePath: destPath,
        source: FontSource.imported,
      ));
      
      debugPrint('Successfully copied and loaded Windows font as: ${font.familyName}');
      return newFont;
    } catch (e) {
      debugPrint('Failed to load copied Windows font ${font.familyName}: $e');
      return null;
    }
  }

  Future<void> copyWindowsFontIfSelected(String familyName) async {
    if (_importedFonts.any((f) => f.familyName == familyName)) return;
    if (_builtInFonts.any((f) => f.familyName == familyName)) return;

    final winFontIndex = _windowsFonts.indexWhere((f) => f.familyName == familyName);
    if (winFontIndex >= 0) {
      await _copyAndLoadWindowsFont(_windowsFonts[winFontIndex]);
    }
  }

  Future<void> deleteFont(String familyName) async {
    final font = _importedFonts.firstWhere((f) => f.familyName == familyName, orElse: () => const AppFont(familyName: '', filePath: '', source: FontSource.imported));
    if (font.filePath.isNotEmpty) {
      final file = File(font.filePath);
      if (await file.exists()) {
        await file.delete();
      }
      _importedFonts.removeWhere((f) => f.familyName == familyName);
      
      // Remove from favorites if exists
      _favoriteFonts.removeWhere((f) => f.familyName == familyName);
      await saveFavorites();
      
      debugPrint('Deleted custom font: $familyName');
      notifyListeners();
    }
  }
}

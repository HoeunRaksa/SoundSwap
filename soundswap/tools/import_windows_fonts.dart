import 'dart:convert';
import 'dart:io';

void main() async {
  final jsonFile = File('D:/SoundSwap/soundswap/tools/scanned_fonts.json');
  final jsonStr = await jsonFile.readAsString();
  final List<dynamic> fontsList = jsonDecode(jsonStr);

  print('Found ${fontsList.length} total font files.');

  // Group by family
  final Map<String, Map<String, dynamic>> families = {};

  for (var f in fontsList) {
    String family = (f['family'] as String).trim();
    if (family.isEmpty) continue;
    
    // Ignore pure symbols or non-text fonts if needed
    if (family == 'Webdings' || family == 'Wingdings') continue;

    String path = f['path'];
    String weight = f['weight']; // e.g. "Normal", "Bold", "Black", "Light"
    String style = f['style']; // e.g. "Normal", "Italic"

    if (!families.containsKey(family)) {
      families[family] = {};
    }

    // We prioritize "Normal" style over "Italic" for the same weight
    String wKey = weight.toLowerCase();
    
    // Skip italics to save space, unless user strictly wants them
    if (style.toLowerCase() == 'italic' || style.toLowerCase() == 'oblique') {
      // only keep if we don't have regular for this weight yet, but honestly let's just skip italics
      // to keep it simple and small, as per user's previous preference
      if (!families[family]!.containsKey(wKey)) {
         families[family]![wKey] = path;
      }
    } else {
      families[family]![wKey] = path;
    }
  }

  print('Unique font families: ${families.length}');

  // Prepare copying
  final destDir = Directory('D:/SoundSwap/soundswap/assets/fonts');
  if (!await destDir.exists()) {
    await destDir.create(recursive: true);
  }

  // To avoid duplicates, we check existing files
  final existingFiles = destDir.listSync().map((e) => e.path.split(Platform.pathSeparator).last).toSet();

  List<Map<String, dynamic>> finalFonts = [];

  for (var family in families.keys) {
    var weights = families[family]!;
    
    String? regularPath = weights['normal'] ?? weights['regular'] ?? weights['medium'] ?? weights.values.first;
    String? boldPath = weights['bold'] ?? weights['black'] ?? weights['heavy'];

    if (regularPath == null) continue;

    String rName = regularPath.split('\\').last;
    String rDest = '${destDir.path}/$rName';
    
    if (!existingFiles.contains(rName)) {
      File(regularPath).copySync(rDest);
    }

    Map<String, dynamic> fontDef = {
      'family': family,
      'fonts': [
        <String, dynamic>{'asset': 'assets/fonts/$rName'}
      ]
    };

    if (boldPath != null && boldPath != regularPath) {
      String bName = boldPath.split('\\').last;
      String bDest = '${destDir.path}/$bName';
      if (!existingFiles.contains(bName)) {
        File(boldPath).copySync(bDest);
      }
      fontDef['fonts'].add({
        'asset': 'assets/fonts/$bName',
        'weight': 700
      });
    }

    finalFonts.add(fontDef);
  }

  print('Copied files. Now updating pubspec.yaml...');

  // Update pubspec.yaml
  final pubspecFile = File('D:/SoundSwap/soundswap/pubspec.yaml');
  List<String> pubspecLines = await pubspecFile.readAsLines();
  
  // Find where fonts: starts
  int fontsIndex = -1;
  int flutterIndex = pubspecLines.indexOf('flutter:');
  if (flutterIndex != -1) {
    for (int i = flutterIndex + 1; i < pubspecLines.length; i++) {
      if (pubspecLines[i].startsWith('  fonts:')) {
        fontsIndex = i;
        break;
      } else if (!pubspecLines[i].startsWith(' ') && pubspecLines[i].trim().isNotEmpty) {
        break;
      }
    }
  }

  if (fontsIndex != -1) {
    // Read existing fonts to avoid duplicates
    Set<String> existingFamilies = {};
    for (int i = fontsIndex + 1; i < pubspecLines.length; i++) {
      if (pubspecLines[i].startsWith('    - family:')) {
        existingFamilies.add(pubspecLines[i].split(':')[1].trim());
      } else if (!pubspecLines[i].startsWith(' ') && pubspecLines[i].trim().isNotEmpty) {
        break;
      }
    }

    List<String> newFontLines = [];
    for (var f in finalFonts) {
      if (!existingFamilies.contains(f['family'])) {
        newFontLines.add('    - family: ${f['family']}');
        newFontLines.add('      fonts:');
        for (var ft in f['fonts']) {
          newFontLines.add('        - asset: ${ft['asset']}');
          if (ft['weight'] != null) {
            newFontLines.add('          weight: ${ft['weight']}');
          }
        }
      }
    }

    if (newFontLines.isNotEmpty) {
      // Find end of fonts block
      int endFonts = fontsIndex + 1;
      while (endFonts < pubspecLines.length && (pubspecLines[endFonts].startsWith(' ') || pubspecLines[endFonts].trim().isEmpty)) {
        endFonts++;
      }
      pubspecLines.insertAll(endFonts, newFontLines);
      await pubspecFile.writeAsString(pubspecLines.join('\n') + '\n');
    }
  }

  print('Updating FontService...');

  // Read existing builtInFonts from font_service.dart
  final fsFile = File('D:/SoundSwap/soundswap/lib/features/fonts/data/services/font_service.dart');
  String fsContent = await fsFile.readAsString();

  // We need to parse all existing families to add to builtInFonts and favorites
  List<String> allFamilies = [];
  for (var f in finalFonts) {
    allFamilies.add(f['family']);
  }

  // But we shouldn't replace existing. We should just insert into the list.
  // Instead of doing it by regex, let's output a JSON of the families so we can inject them properly.
  final familiesJsonFile = File('D:/SoundSwap/soundswap/tools/families.json');
  await familiesJsonFile.writeAsString(jsonEncode(allFamilies));

  print('Done! Wrote families to tools/families.json');
}

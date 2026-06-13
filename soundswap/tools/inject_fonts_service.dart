import 'dart:convert';
import 'dart:io';

void main() async {
  final familiesJsonFile = File('D:/SoundSwap/soundswap/tools/families.json');
  final List<dynamic> families = jsonDecode(await familiesJsonFile.readAsString());

  // Get all copied font files in assets/fonts to add to installBundledFonts
  final destDir = Directory('D:/SoundSwap/soundswap/assets/fonts');
  final fontFiles = destDir.listSync().whereType<File>().map((f) => f.uri.pathSegments.last).toList();

  final fsFile = File('D:/SoundSwap/soundswap/lib/features/fonts/data/services/font_service.dart');
  final lines = await fsFile.readAsLines();

  // Inject into _builtInFonts
  int builtInStart = -1;
  int builtInEnd = -1;
  for (int i = 0; i < lines.length; i++) {
    if (lines[i].contains('final List<AppFont> _builtInFonts = [')) {
      builtInStart = i;
    }
    if (builtInStart != -1 && i > builtInStart && lines[i].trim() == '];') {
      builtInEnd = i;
      break;
    }
  }

  if (builtInStart != -1 && builtInEnd != -1) {
    List<String> newBuiltIn = [];
    newBuiltIn.add('  final List<AppFont> _builtInFonts = [');
    for (var family in families) {
      newBuiltIn.add('    const AppFont(familyName: \'${family.replaceAll('\'', '\\\'')}\', filePath: \'\', source: FontSource.builtIn),');
    }
    newBuiltIn.add('  ];');

    lines.replaceRange(builtInStart, builtInEnd + 1, newBuiltIn);
  }

  // Inject into installBundledFonts
  int bundledStart = -1;
  int bundledEnd = -1;
  for (int i = 0; i < lines.length; i++) {
    if (lines[i].contains('final bundled = [')) {
      bundledStart = i;
    }
    if (bundledStart != -1 && i > bundledStart && lines[i].trim() == '];') {
      bundledEnd = i;
      break;
    }
  }

  if (bundledStart != -1 && bundledEnd != -1) {
    List<String> newBundled = [];
    newBundled.add('    final bundled = [');
    for (var file in fontFiles) {
      newBundled.add('      \'${file.replaceAll('\'', '\\\'')}\',');
    }
    newBundled.add('    ];');

    lines.replaceRange(bundledStart, bundledEnd + 1, newBundled);
  }

  await fsFile.writeAsString(lines.join('\n') + '\n');
  print('Successfully injected 1000+ fonts into FontService.');
}

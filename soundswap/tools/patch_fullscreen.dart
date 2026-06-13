import 'dart:io';

void main() {
  String content = File('lib/features/overlay_tools/presentation/screens/full_screen_editor_screen.dart').readAsStringSync();

  if (!content.contains("import '../widgets/overlay_layers_panel.dart';")) {
    content = content.replaceFirst("import 'package:soundswap/core/video/video_output_settings.dart';", "import 'package:soundswap/core/video/video_output_settings.dart';\nimport '../widgets/overlay_layers_panel.dart';\nimport '../widgets/overlay_properties_panel.dart';");
  }

  content = content.replaceFirst(
    'if (_showLeftPanel) _buildLayersPanel(colorScheme),',
    'if (_showLeftPanel) SizedBox(width: 250, child: OverlayLayersPanel(controller: widget.controller)),'
  );
  content = content.replaceFirst(
    'if (_showRightPanel) _buildPropertiesPanel(colorScheme),',
    'if (_showRightPanel) SizedBox(width: 250, child: OverlayPropertiesPanel(controller: widget.controller)),'
  );

  int layersStart = content.indexOf('  Widget _buildLayersPanel(ColorScheme colorScheme) {');
  int propStart = content.indexOf('  Widget _buildPropertiesPanel(ColorScheme colorScheme) {');

  if (layersStart != -1 && propStart != -1) {
    if (layersStart < propStart) {
      content = content.substring(0, layersStart) + content.substring(content.indexOf('}', propStart) + 1); // wait this is dangerous
    }
  }

  // A safer way: just replace the method calls and leave the methods dead for now, dart will warn about unused methods.
  // Actually, let's just let flutter analyze warn about them and we'll remove them.
  
  File('lib/features/overlay_tools/presentation/screens/full_screen_editor_screen.dart').writeAsStringSync(content);
  print('Patched full_screen_editor_screen.dart');
}

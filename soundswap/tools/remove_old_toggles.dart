import 'dart:io';

void main() {
  String content = File('lib/features/overlay_tools/presentation/screens/full_screen_editor_screen.dart').readAsStringSync();

  String oldToggleButtons = '''
            // Panel Toggles
            ToggleButtons(
              isSelected: [_showLeftPanel, _showRightPanel],
              onPressed: (index) {
                setState(() {
                  if (index == 0) _showLeftPanel = !_showLeftPanel;
                  if (index == 1) _showRightPanel = !_showRightPanel;
                });
              },
              borderRadius: BorderRadius.circular(8),
              constraints: const BoxConstraints(minHeight: 36, minWidth: 40),
              children: const [
                Tooltip(message: 'Toggle Layers', child: Icon(Icons.layers_outlined)),
                Tooltip(message: 'Toggle Properties', child: Icon(Icons.tune)),
              ],
            ),
''';

  content = content.replaceAll(oldToggleButtons, '');

  File('lib/features/overlay_tools/presentation/screens/full_screen_editor_screen.dart').writeAsStringSync(content);
  print('Removed old ToggleButtons');
}

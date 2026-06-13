import 'dart:io';

void main() {
  String content = File('lib/features/overlay_tools/presentation/screens/full_screen_editor_screen.dart').readAsStringSync();

  // 1. Remove local _showLeftPanel and _showRightPanel variables
  content = content.replaceFirst('  bool _showLeftPanel = true;\n  bool _showRightPanel = true;', '  bool _focusMode = false;');

  // 2. Add TAB shortcut
  content = content.replaceFirst(
    'const SingleActivator(LogicalKeyboardKey.escape): () => Navigator.of(context).pop(),',
    'const SingleActivator(LogicalKeyboardKey.escape): () => Navigator.of(context).pop(),\n            const SingleActivator(LogicalKeyboardKey.tab): () {\n              final current = widget.controller.settings.showFullScreenPropertiesPanel;\n              widget.controller.updateSettings(widget.controller.settings.copyWith(showFullScreenPropertiesPanel: !current));\n            },'
  );

  // 3. Update Left Panel visibility
  content = content.replaceFirst(
    'if (_showLeftPanel) \n                          SizedBox(',
    'if (!_focusMode && widget.controller.settings.showFullScreenLayersPanel) \n                          SizedBox('
  );
  
  content = content.replaceFirst(
    'if (_showLeftPanel)\n                          SizedBox(',
    'if (!_focusMode && widget.controller.settings.showFullScreenLayersPanel)\n                          SizedBox('
  );

  // 4. Update Right Panel visibility
  content = content.replaceFirst(
    'if (_showRightPanel) \n                          SizedBox(',
    'if (!_focusMode && widget.controller.settings.showFullScreenPropertiesPanel) \n                          SizedBox('
  );
  
  content = content.replaceFirst(
    'if (_showRightPanel)\n                          SizedBox(',
    'if (!_focusMode && widget.controller.settings.showFullScreenPropertiesPanel)\n                          SizedBox('
  );

  // 5. Update Toolbar to have toggles and hide on focus mode
  String oldScaffold = 'body: Column(\n                children: [\n                  _buildToolbar(colorScheme),\n                  const Divider(height: 1),';
  String newScaffold = 'body: Column(\n                children: [\n                  if (!_focusMode) ...[\n                    _buildToolbar(colorScheme),\n                    const Divider(height: 1),\n                  ],';
  content = content.replaceFirst(oldScaffold, newScaffold);

  // 6. Change double click
  content = content.replaceFirst(
    'onDoubleTap: () => Navigator.of(context).pop(),',
    'onDoubleTap: () => setState(() => _focusMode = !_focusMode),'
  );

  // 7. Add Collapse buttons to Toolbar
  String oldToolbarRow = 'Row(\n        children: [\n          IconButton(\n            tooltip: \'Exit Full Screen (ESC)\',\n            icon: const Icon(Icons.close),\n            onPressed: () => Navigator.of(context).pop(),\n          ),\n          const SizedBox(width: 8),\n          const Text(\n            \'Full Screen Editor\',\n            style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),\n          ),\n          const SizedBox(width: 16),\n          ListenableBuilder(';
  
  String newToolbarRow = 'Row(\n        children: [\n          IconButton(\n            tooltip: \'Exit Full Screen (ESC)\',\n            icon: const Icon(Icons.close),\n            onPressed: () => Navigator.of(context).pop(),\n          ),\n          const SizedBox(width: 8),\n          IconButton(\n            tooltip: widget.controller.settings.showFullScreenLayersPanel ? "Collapse Layers Panel" : "Expand Layers Panel",\n            icon: Icon(widget.controller.settings.showFullScreenLayersPanel ? Icons.keyboard_double_arrow_left : Icons.keyboard_double_arrow_right),\n            onPressed: () => widget.controller.updateSettings(widget.controller.settings.copyWith(showFullScreenLayersPanel: !widget.controller.settings.showFullScreenLayersPanel)),\n          ),\n          const SizedBox(width: 8),\n          const Text(\n            \'Full Screen Editor\',\n            style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),\n          ),\n          const SizedBox(width: 16),\n          ListenableBuilder(';
  content = content.replaceFirst(oldToolbarRow, newToolbarRow);

  String oldToolbarEnd = '          const Spacer(),\n          const Text(\'Zoom: \'),';
  String newToolbarEnd = '          const Spacer(),\n          const Text(\'Zoom: \'),'; // actually we need to add the right panel toggle at the end
  
  // Actually, we can add the right panel toggle after the settings
  String oldZoomEnd = 'if (val != null) setState(() => _zoomScale = val);\n              },\n            ),\n          ],';
  String newZoomEnd = 'if (val != null) setState(() => _zoomScale = val);\n              },\n            ),\n            const SizedBox(width: 16),\n            IconButton(\n              tooltip: widget.controller.settings.showFullScreenPropertiesPanel ? "Collapse Properties Panel (TAB)" : "Expand Properties Panel (TAB)",\n              icon: Icon(widget.controller.settings.showFullScreenPropertiesPanel ? Icons.keyboard_double_arrow_right : Icons.keyboard_double_arrow_left),\n              onPressed: () => widget.controller.updateSettings(widget.controller.settings.copyWith(showFullScreenPropertiesPanel: !widget.controller.settings.showFullScreenPropertiesPanel)),\n            ),\n          ],';
  content = content.replaceFirst(oldZoomEnd, newZoomEnd);

  File('lib/features/overlay_tools/presentation/screens/full_screen_editor_screen.dart').writeAsStringSync(content);
  print('Patched full screen layout logic');
}

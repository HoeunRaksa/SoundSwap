import 'dart:io';

void main() {
  // 1. Fix overlay_templates_panel.dart
  String panelContent = File('lib/features/overlay_tools/presentation/widgets/overlay_templates_panel.dart').readAsStringSync();
  panelContent = panelContent.replaceAll(
    "name: '\\\${_templateNameController.text.isEmpty ? controller.editingTemplateName ?? 'Untitled' : _templateNameController.text} (Copy)',",
    'name: "\\\${_templateNameController.text.isEmpty ? controller.editingTemplateName ?? \'Untitled\' : _templateNameController.text} (Copy)",'
  );
  
  // also fix the new line issue in string interpolation
  panelContent = panelContent.replaceAll(
    "'\\\\\$textCount text overlays, \\\\\$imageCount image overlays'",
    "'\\\$textCount text overlays, \\\$imageCount image overlays'"
  );
  panelContent = panelContent.replaceAll(
    "'Font: \\\\\$fontName'",
    "'Font: \\\$fontName'"
  );
  panelContent = panelContent.replaceAll(
    "'Prefix: \\\\\$prefix'",
    "'Prefix: \\\$prefix'"
  );
  
  File('lib/features/overlay_tools/presentation/widgets/overlay_templates_panel.dart').writeAsStringSync(panelContent);

  // 2. Fix overlay_tools_screen.dart
  String screenContent = File('lib/features/overlay_tools/presentation/screens/overlay_tools_screen.dart').readAsStringSync();
  
  String oldCall = '''
                                  builder: (context) => FullScreenEditorScreen(
                                    controller: widget.controller,
                                    outputSize: _previewSize,
                                  ),
''';
  
  String newCall = '''
                                  builder: (context) => FullScreenEditorScreen(
                                    controller: widget.controller,
                                    templatesController: widget.templatesController,
                                    homeController: widget.homeController,
                                    brandingController: widget.brandingController,
                                    textOverlayController: widget.textOverlayController,
                                    outputSize: _previewSize,
                                  ),
''';
  
  screenContent = screenContent.replaceAll(oldCall, newCall);
  
  // Actually, wait, there might be slight indentation differences. Let's do a regex replace.
  screenContent = screenContent.replaceAll(
    'controller: widget.controller,\n                                    outputSize: _previewSize,',
    'controller: widget.controller,\n                                    templatesController: widget.templatesController,\n                                    homeController: widget.homeController,\n                                    brandingController: widget.brandingController,\n                                    textOverlayController: widget.textOverlayController,\n                                    outputSize: _previewSize,'
  );
  screenContent = screenContent.replaceAll(
    'controller: widget.controller,\n                                              outputSize: _previewSize,',
    'controller: widget.controller,\n                                              templatesController: widget.templatesController,\n                                              homeController: widget.homeController,\n                                              brandingController: widget.brandingController,\n                                              textOverlayController: widget.textOverlayController,\n                                              outputSize: _previewSize,'
  );

  File('lib/features/overlay_tools/presentation/screens/overlay_tools_screen.dart').writeAsStringSync(screenContent);
  print('Fixed constructor calls and string interpolations');
}

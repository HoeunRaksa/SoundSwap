import 'dart:io';

void main() {
  String screenContent = File('lib/features/overlay_tools/presentation/screens/overlay_tools_screen.dart').readAsStringSync();
  
  screenContent = screenContent.replaceAll(
    'FullScreenEditorScreen(\n                                  controller: widget.controller,\n                                  outputSize: _previewSize,\n                                )',
    'FullScreenEditorScreen(\n                                  controller: widget.controller,\n                                  templatesController: widget.templatesController,\n                                  homeController: widget.homeController,\n                                  brandingController: widget.brandingController,\n                                  textOverlayController: widget.textOverlayController,\n                                  outputSize: _previewSize,\n                                )'
  );
  
  screenContent = screenContent.replaceAll(
    'FullScreenEditorScreen(\n                                            controller: widget.controller,\n                                            outputSize: _previewSize,\n                                          )',
    'FullScreenEditorScreen(\n                                            controller: widget.controller,\n                                            templatesController: widget.templatesController,\n                                            homeController: widget.homeController,\n                                            brandingController: widget.brandingController,\n                                            textOverlayController: widget.textOverlayController,\n                                            outputSize: _previewSize,\n                                          )'
  );

  File('lib/features/overlay_tools/presentation/screens/overlay_tools_screen.dart').writeAsStringSync(screenContent);
  print('Fixed constructor calls robustly');
}

import 'dart:io';

void main() {
  String content = File('lib/features/overlay_tools/presentation/screens/full_screen_editor_screen.dart').readAsStringSync();

  String oldScaleW = 'final scaleW = (availableWidth - 64) / widget.outputSize.previewWidth;';
  String newScaleW = 'final scaleW = (availableWidth - 16) / widget.outputSize.previewWidth;';
  content = content.replaceFirst(oldScaleW, newScaleW);

  String oldScaleH = 'final scaleH = (availableHeight - 64) / widget.outputSize.previewHeight;';
  String newScaleH = 'final scaleH = (availableHeight - 16) / widget.outputSize.previewHeight;';
  content = content.replaceFirst(oldScaleH, newScaleH);

  String oldFitHeight = 'computedScale = (availableHeight - 64) / widget.outputSize.previewHeight;';
  String newFitHeight = 'computedScale = (availableHeight - 16) / widget.outputSize.previewHeight;';
  content = content.replaceFirst(oldFitHeight, newFitHeight);

  String oldFitWidth = 'computedScale = (availableWidth - 64) / widget.outputSize.previewWidth;';
  String newFitWidth = 'computedScale = (availableWidth - 16) / widget.outputSize.previewWidth;';
  content = content.replaceFirst(oldFitWidth, newFitWidth);

  String oldScrollW = 'final scrollableWidth = availableWidth > canvasWidth + 64 ? availableWidth : canvasWidth + 64;';
  String newScrollW = 'final scrollableWidth = availableWidth > canvasWidth + 16 ? availableWidth : canvasWidth + 16;';
  content = content.replaceFirst(oldScrollW, newScrollW);

  String oldScrollH = 'final scrollableHeight = availableHeight > canvasHeight + 64 ? availableHeight : canvasHeight + 64;';
  String newScrollH = 'final scrollableHeight = availableHeight > canvasHeight + 16 ? availableHeight : canvasHeight + 16;';
  content = content.replaceFirst(oldScrollH, newScrollH);

  File('lib/features/overlay_tools/presentation/screens/full_screen_editor_screen.dart').writeAsStringSync(content);
  print('Patched bounds');
}

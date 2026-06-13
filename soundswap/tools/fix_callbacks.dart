import 'dart:io';

void main() {
  String content = File('lib/features/overlay_tools/presentation/screens/overlay_tools_screen.dart').readAsStringSync();

  content = content.replaceAll('widget.controller.updateItemWidth', '(id, w) => widget.controller.resizeItem(id, w, saveToDisk: false)');
  content = content.replaceAll('widget.controller.updateItemsPosition', '(positions) { positions.forEach((id, pos) => widget.controller.moveItem(id, pos, saveToDisk: false)); }');
  content = content.replaceAll('widget.controller.updateItemSize', '(id, w, h) { final match = widget.controller.settings.items.firstWhere((e) => e.id == id); widget.controller.updateItem(match.copyWith(widthPercent: w, customHeightPercent: h), saveToDisk: false); }');
  
  content = content.replaceAll('widget.controller.alignCenterHorizontal', 'widget.controller.alignCenterX');
  content = content.replaceAll('widget.controller.alignCenterVertical', 'widget.controller.alignCenterY');

  File('lib/features/overlay_tools/presentation/screens/overlay_tools_screen.dart').writeAsStringSync(content);
  print('Fixed remaining callbacks in overlay_tools_screen.dart.');
}

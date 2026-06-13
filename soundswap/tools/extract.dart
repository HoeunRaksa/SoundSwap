import 'dart:io';

void main() {
  final content = File('lib/features/overlay_tools/presentation/screens/overlay_tools_screen.dart').readAsStringSync();

  // Extract Layers Tab
  final layersStart = content.indexOf('Widget _buildLayersTab');
  final transformStart = content.indexOf('Widget _buildTransformTab');
  final alignStart = content.indexOf('Widget _buildAlignTab');
  
  final layersTabCode = content.substring(layersStart, transformStart);
  final transformTabCode = content.substring(transformStart, alignStart);

  File('layers_raw.txt').writeAsStringSync(layersTabCode);
  File('transform_raw.txt').writeAsStringSync(transformTabCode);

  // Extract controllers
  final _onControllerChangeStart = content.indexOf('void _syncFromState() {');
  final buildStart = content.indexOf('Widget build(BuildContext context) {');
  final controllersCode = content.substring(_onControllerChangeStart, buildStart);
  File('controllers_raw.txt').writeAsStringSync(controllersCode);

  print('Extracted successfully.');
}

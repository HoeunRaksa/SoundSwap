import 'dart:io';

void main() {
  String content = File('lib/features/overlay_tools/presentation/screens/overlay_tools_screen.dart').readAsStringSync();

  if (!content.contains("import '../widgets/overlay_layers_panel.dart';")) {
    content = content.replaceFirst("import 'package:soundswap/shared/widgets/empty_state.dart';", "import 'package:soundswap/shared/widgets/empty_state.dart';\nimport '../widgets/overlay_layers_panel.dart';\nimport '../widgets/overlay_properties_panel.dart';");
  }

  // Replace _buildLayersTab call
  content = content.replaceAll('_buildLayersTab(context)', 'OverlayLayersPanel(controller: widget.controller)');
  // Replace _buildTransformTab call
  content = content.replaceAll('_buildTransformTab(context)', 'OverlayPropertiesPanel(controller: widget.controller)');

  // Remove _buildLayersTab definition
  int start = content.indexOf('  Widget _buildLayersTab(BuildContext context) {');
  int end = content.indexOf('  Widget _buildTransformTab(BuildContext context) {');
  if (start != -1 && end != -1) {
    content = content.replaceRange(start, end, '');
  }

  // Remove _buildTransformTab definition
  start = content.indexOf('  Widget _buildTransformTab(BuildContext context) {');
  end = content.indexOf('  Widget _buildAlignTab(BuildContext context) {');
  if (start != -1 && end != -1) {
    content = content.replaceRange(start, end, '');
  }

  // Remove _OverlayListTile definition
  start = content.indexOf('class _OverlayListTile extends StatelessWidget {');
  end = content.indexOf('class _TemplateTile extends StatelessWidget {');
  if (start != -1 && end != -1) {
    content = content.replaceRange(start, end, '');
  }

  // Remove controllers and sync state
  start = content.indexOf('  final _nameController = TextEditingController();');
  end = content.indexOf('  @override\n  Widget build(BuildContext context) {');
  if (start != -1 && end != -1) {
    content = content.replaceRange(start, end, '''
  VideoOutputSize _previewSize = VideoOutputSize.vertical1080;
  bool _showGrid = false;
  bool _enableSnapping = true;
  double _zoomScale = 1.0;

''');
  }

  // Remove _buildCleanImagePath
  start = content.indexOf('  Widget _buildCleanImagePath(BuildContext context, String? imagePath) {');
  end = content.indexOf('class _TemplateTile extends StatelessWidget {');
  if (start != -1 && end != -1) {
    content = content.replaceRange(start, end, '');
  }

  File('lib/features/overlay_tools/presentation/screens/overlay_tools_screen.dart').writeAsStringSync(content);
  print('Patched successfully via Dart.');
}

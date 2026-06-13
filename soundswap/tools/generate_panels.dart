import 'dart:io';

void main() {
  final tileRaw = File('tile_raw.txt').readAsStringSync();
  final layersRaw = File('layers_raw.txt').readAsStringSync();
  final transformRaw = File('transform_raw.txt').readAsStringSync();
  final controllersRaw = File('controllers_raw.txt').readAsStringSync();

  // OVERLAY LAYERS PANEL
  String layersPanel = '''
import 'package:flutter/material.dart';
import 'package:soundswap/features/overlay_tools/data/models/overlay_item.dart';
import 'package:soundswap/features/overlay_tools/presentation/state/overlay_tools_controller.dart';
import 'package:soundswap/shared/widgets/empty_state.dart';

class OverlayLayersPanel extends StatefulWidget {
  const OverlayLayersPanel({required this.controller, super.key});
  final OverlayToolsController controller;

  @override
  State<OverlayLayersPanel> createState() => _OverlayLayersPanelState();
}

class _OverlayLayersPanelState extends State<OverlayLayersPanel> {
  final _folderNameController = TextEditingController();

  @override
  void dispose() {
    _folderNameController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return _buildLayersTab(context);
  }

''';
  // replace widget.controller with widget.controller
  String l = layersRaw.replaceAll('Widget _buildLayersTab(BuildContext context) {', 'Widget _buildLayersTab(BuildContext context) {');
  layersPanel += l + '\n}\n\n' + tileRaw;

  File('lib/features/overlay_tools/presentation/widgets/overlay_layers_panel.dart').writeAsStringSync(layersPanel);

  // OVERLAY PROPERTIES PANEL
  String propertiesPanel = '''
import 'package:flutter/material.dart';
import 'package:soundswap/core/responsive/app_responsive.dart';
import 'package:soundswap/features/overlay_tools/data/models/overlay_item.dart';
import 'package:soundswap/features/overlay_tools/presentation/state/overlay_tools_controller.dart';
import 'package:soundswap/shared/widgets/font_dropdown_widget.dart';

class OverlayPropertiesPanel extends StatefulWidget {
  const OverlayPropertiesPanel({required this.controller, super.key});
  final OverlayToolsController controller;

  @override
  State<OverlayPropertiesPanel> createState() => _OverlayPropertiesPanelState();
}

class _OverlayPropertiesPanelState extends State<OverlayPropertiesPanel> {
  final _nameController = TextEditingController();
  final _textController = TextEditingController();
  final _fontSizeController = TextEditingController();
  final _colorController = TextEditingController();
  final _widthController = TextEditingController();
  final _customHeightController = TextEditingController();
  final _opacityController = TextEditingController();
  final _rotationController = TextEditingController();
  final _startTimeController = TextEditingController();
  final _endTimeController = TextEditingController();

  final _nameFocus = FocusNode();
  final _textFocus = FocusNode();
  final _fontSizeFocus = FocusNode();
  final _colorFocus = FocusNode();
  final _widthFocus = FocusNode();
  final _customHeightFocus = FocusNode();
  final _opacityFocus = FocusNode();
  final _rotationFocus = FocusNode();
  final _startTimeFocus = FocusNode();
  final _endTimeFocus = FocusNode();

  bool _showAdvancedTiming = false;

  @override
  void initState() {
    super.initState();
    widget.controller.addListener(_syncFromState);
    _syncFromState();
  }

  @override
  void dispose() {
    widget.controller.removeListener(_syncFromState);
    _nameController.dispose();
    _textController.dispose();
    _fontSizeController.dispose();
    _colorController.dispose();
    _widthController.dispose();
    _customHeightController.dispose();
    _opacityController.dispose();
    _rotationController.dispose();
    _startTimeController.dispose();
    _endTimeController.dispose();
    _nameFocus.dispose();
    _textFocus.dispose();
    _fontSizeFocus.dispose();
    _colorFocus.dispose();
    _widthFocus.dispose();
    _customHeightFocus.dispose();
    _opacityFocus.dispose();
    _rotationFocus.dispose();
    _startTimeFocus.dispose();
    _endTimeFocus.dispose();
    super.dispose();
  }

''';
  // Add controllers Raw (remove @override at bottom)
  String c = controllersRaw.replaceAll('@override', '');
  c = c.replaceAll('widget.templatesController.markTemplateAsDirty();', ''); // Strip out templates dependency
  
  propertiesPanel += c + '\n';
  propertiesPanel += '''
  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: widget.controller,
      builder: (context, _) => _buildTransformTab(context),
    );
  }
''';

  String t = transformRaw.replaceAll('Widget _buildTransformTab(BuildContext context) {', 'Widget _buildTransformTab(BuildContext context) {');
  // Strip out TwoColumn widget and recreate it or import it.
  t = t.replaceAll('_TwoColumn(', 'Row(children: [Expanded(child: ');
  // Since _TwoColumn was used, we will just redefine _TwoColumn below
  
  propertiesPanel += t + '\n}\n\n';

  propertiesPanel += '''
class _TwoColumn extends StatelessWidget {
  const _TwoColumn({required this.left, required this.right});
  final Widget left;
  final Widget right;
  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Expanded(child: left),
        const SizedBox(width: 8),
        Expanded(child: right),
      ],
    );
  }
}
''';

  File('lib/features/overlay_tools/presentation/widgets/overlay_properties_panel.dart').writeAsStringSync(propertiesPanel);

  print('Panels generated successfully!');
}

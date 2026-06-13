import re

with open('lib/features/overlay_tools/presentation/screens/overlay_tools_screen.dart', 'r', encoding='utf-8') as f:
    lines = f.readlines()

# Add imports
imports = "import '../widgets/overlay_layers_panel.dart';\nimport '../widgets/overlay_properties_panel.dart';\n"
for i, line in enumerate(lines):
    if "import 'package:soundswap/shared/widgets/empty_state.dart';" in line:
        lines.insert(i + 1, imports)
        break

with open('lib/features/overlay_tools/presentation/screens/overlay_tools_screen.dart', 'w', encoding='utf-8') as f:
    f.writelines(lines)

with open('lib/features/overlay_tools/presentation/screens/overlay_tools_screen.dart', 'r', encoding='utf-8') as f:
    content = f.read()

# Replace _buildLayersTab call
content = content.replace('_buildLayersTab(context)', 'OverlayLayersPanel(controller: widget.controller)')
# Replace _buildTransformTab call
content = content.replace('_buildTransformTab(context)', 'OverlayPropertiesPanel(controller: widget.controller)')

# Remove _buildLayersTab definition
start = content.find('Widget _buildLayersTab(BuildContext context) {')
end = content.find('Widget _buildTransformTab(BuildContext context) {')
if start != -1 and end != -1:
    content = content[:start] + content[end:]

# Remove _buildTransformTab definition
start = content.find('Widget _buildTransformTab(BuildContext context) {')
end = content.find('Widget _buildAlignTab(BuildContext context) {')
if start != -1 and end != -1:
    content = content[:start] + content[end:]

# Remove _OverlayListTile definition
start = content.find('class _OverlayListTile extends StatelessWidget {')
end = content.find('class _TemplateTile extends StatelessWidget {')
if start != -1 and end != -1:
    content = content[:start] + content[end:]

# Remove controllers and sync state
start = content.find('  final _nameController = TextEditingController();')
end = content.find('  @override\n  Widget build(BuildContext context) {')
if start != -1 and end != -1:
    content = content[:start] + '''
  VideoOutputSize _previewSize = VideoOutputSize.vertical1080;
  bool _showGrid = false;
  bool _enableSnapping = true;
  double _zoomScale = 1.0;

''' + content[end:]

# Remove _buildCleanImagePath
start = content.find('  Widget _buildCleanImagePath(BuildContext context, String? imagePath) {')
end = content.find('class _TemplateTile extends StatelessWidget {')
if start != -1 and end != -1:
    content = content[:start] + content[end:]


with open('lib/features/overlay_tools/presentation/screens/overlay_tools_screen.dart', 'w', encoding='utf-8') as f:
    f.write(content)

print('Patched successfully via Python.')

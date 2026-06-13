import 'dart:io';

void main() {
  String content = File('lib/features/overlay_tools/presentation/screens/full_screen_editor_screen.dart').readAsStringSync();

  // 1. Add imports
  if (!content.contains("import 'package:soundswap/features/templates/presentation/state/templates_controller.dart';")) {
    content = content.replaceFirst(
      "import 'package:soundswap/features/overlay_tools/presentation/state/overlay_tools_controller.dart';",
      "import 'package:soundswap/features/overlay_tools/presentation/state/overlay_tools_controller.dart';\nimport 'package:soundswap/features/templates/presentation/state/templates_controller.dart';\nimport 'package:soundswap/features/home/presentation/state/home_controller.dart';\nimport 'package:soundswap/features/branding/presentation/state/branding_controller.dart';\nimport 'package:soundswap/features/text_overlay/presentation/state/text_overlay_controller.dart';"
    );
  }

  // 2. Update constructor
  String oldConstructor = '''
class FullScreenEditorScreen extends StatefulWidget {
  const FullScreenEditorScreen({
    required this.controller,
    required this.outputSize,
    super.key,
  });

  final OverlayToolsController controller;
  final VideoOutputSize outputSize;
''';

  String newConstructor = '''
class FullScreenEditorScreen extends StatefulWidget {
  const FullScreenEditorScreen({
    required this.controller,
    required this.templatesController,
    required this.homeController,
    required this.brandingController,
    required this.textOverlayController,
    required this.outputSize,
    super.key,
  });

  final OverlayToolsController controller;
  final TemplatesController templatesController;
  final HomeController homeController;
  final BrandingController brandingController;
  final TextOverlayController textOverlayController;
  final VideoOutputSize outputSize;
''';

  content = content.replaceFirst(oldConstructor, newConstructor);

  // 3. Add Save Template logic
  String oldToolbar = '''
  Widget _buildToolbar(ColorScheme colorScheme) {
    return Container(
      color: colorScheme.surfaceContainer,
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: Row(
        children: [
          IconButton(
            tooltip: 'Exit Full Screen (ESC)',
            icon: const Icon(Icons.close),
            onPressed: () => Navigator.of(context).pop(),
          ),
          const SizedBox(width: 8),
          const Text(
            'Full Screen Editor',
            style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
          ),
          const SizedBox(width: 24),
''';

  String newToolbar = '''
  Future<void> _handleSaveTemplate() async {
    final tCtrl = widget.templatesController;
    if (tCtrl.editingTemplateId != null) {
      // Update existing
      await tCtrl.updateEditingTemplate(
        name: tCtrl.editingTemplateName ?? 'Untitled',
        home: widget.homeController,
        branding: widget.brandingController,
        textOverlay: widget.textOverlayController,
        overlay: widget.controller,
      );
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Updated template: \${tCtrl.editingTemplateName}')));
    } else {
      // Save As New
      final textController = TextEditingController();
      final name = await showDialog<String>(
        context: context,
        builder: (context) => AlertDialog(
          title: const Text('Save As New Template'),
          content: TextField(
            controller: textController,
            autofocus: true,
            decoration: const InputDecoration(labelText: 'Template name'),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Cancel'),
            ),
            FilledButton(
              onPressed: () => Navigator.pop(context, textController.text),
              child: const Text('Save'),
            ),
          ],
        ),
      );
      textController.dispose();

      if (name != null && name.trim().isNotEmpty) {
        await tCtrl.saveCurrent(
          name: name.trim(),
          home: widget.homeController,
          branding: widget.brandingController,
          textOverlay: widget.textOverlayController,
          overlay: widget.controller,
        );
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Saved template: \$name')));
      }
    }
  }

  Widget _buildToolbar(ColorScheme colorScheme) {
    return Container(
      color: colorScheme.surfaceContainer,
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: Row(
        children: [
          IconButton(
            tooltip: 'Exit Full Screen (ESC)',
            icon: const Icon(Icons.close),
            onPressed: () => Navigator.of(context).pop(),
          ),
          const SizedBox(width: 8),
          const Text(
            'Full Screen Editor',
            style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
          ),
          const SizedBox(width: 16),
          ListenableBuilder(
            listenable: widget.templatesController,
            builder: (context, _) {
              final isEditing = widget.templatesController.editingTemplateId != null;
              return FilledButton.icon(
                onPressed: _handleSaveTemplate,
                icon: const Icon(Icons.save),
                label: Text(isEditing ? 'Update Template' : 'Save Template'),
              );
            }
          ),
          const SizedBox(width: 24),
''';

  content = content.replaceFirst(oldToolbar, newToolbar);

  File('lib/features/overlay_tools/presentation/screens/full_screen_editor_screen.dart').writeAsStringSync(content);
  print('Patched full_screen_editor_screen.dart with templates');
}

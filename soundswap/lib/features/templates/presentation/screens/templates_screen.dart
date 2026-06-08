import 'package:flutter/material.dart';
import 'package:soundswap/core/responsive/app_responsive.dart';
import 'package:soundswap/features/branding/presentation/state/branding_controller.dart';
import 'package:soundswap/features/home/presentation/state/home_controller.dart';
import 'package:soundswap/features/templates/data/models/project_template.dart';
import 'package:soundswap/features/templates/presentation/state/templates_controller.dart';
import 'package:soundswap/features/text_overlay/presentation/state/text_overlay_controller.dart';
import 'package:soundswap/shared/widgets/feature_page.dart';
import 'package:soundswap/shared/widgets/empty_state.dart';

class TemplatesScreen extends StatefulWidget {
  const TemplatesScreen({
    required this.controller,
    required this.homeController,
    required this.brandingController,
    required this.textOverlayController,
    super.key,
  });

  final TemplatesController controller;
  final HomeController homeController;
  final BrandingController brandingController;
  final TextOverlayController textOverlayController;

  @override
  State<TemplatesScreen> createState() => _TemplatesScreenState();
}

class _TemplatesScreenState extends State<TemplatesScreen> {
  final _nameController = TextEditingController();

  @override
  void dispose() {
    _nameController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: widget.controller,
      builder: (context, _) {
        return FeaturePage(
          title: 'Templates',
          subtitle:
              'Save folder selections, output prefix, branding, and text overlay settings.',
          children: [
            SettingsSection(
              title: 'Save current setup',
              icon: Icons.save_outlined,
              children: [
                TextField(
                  controller: _nameController,
                  decoration: const InputDecoration(labelText: 'Template name'),
                  style: TextStyle(fontSize: AppResponsive.bodySize(context)),
                ),
                FilledButton.icon(
                  onPressed: () => widget.controller.saveCurrent(
                    name: _nameController.text,
                    home: widget.homeController,
                    branding: widget.brandingController,
                    textOverlay: widget.textOverlayController,
                  ),
                  icon: const Icon(Icons.add),
                  label: const Text('Save Template'),
                ),
                if (widget.controller.message != null)
                  Text(widget.controller.message!),
              ],
            ),
            SettingsSection(
              title: 'Saved templates',
              icon: Icons.dashboard_customize_outlined,
              children: [
                if (widget.controller.templates.isEmpty)
                  const SizedBox(
                    height: 180,
                    child: EmptyState(
                      icon: Icons.inbox_outlined,
                      title: 'No templates yet',
                      message: 'Save your current setup to reuse it later.',
                    ),
                  )
                else
                  for (final template in widget.controller.templates)
                    _TemplateTile(
                      template: template,
                      onLoad: () => widget.controller.loadTemplate(
                        template: template,
                        home: widget.homeController,
                        branding: widget.brandingController,
                        textOverlay: widget.textOverlayController,
                      ),
                      onRename: () => _renameTemplate(template),
                      onDelete: () => _confirmDeleteTemplate(template),
                    ),
              ],
            ),
          ],
        );
      },
    );
  }

  Future<void> _renameTemplate(ProjectTemplate template) async {
    final controller = TextEditingController(text: template.name);
    final newName = await showDialog<String>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Rename template'),
        content: TextField(
          controller: controller,
          autofocus: true,
          decoration: const InputDecoration(labelText: 'Template name'),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(context, controller.text),
            child: const Text('Save'),
          ),
        ],
      ),
    );
    controller.dispose();
    if (newName != null) {
      await widget.controller.renameTemplate(template: template, name: newName);
    }
  }

  Future<void> _confirmDeleteTemplate(ProjectTemplate template) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete template?'),
        content: Text('Delete "${template.name}"?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Delete'),
          ),
        ],
      ),
    );
    if (confirmed == true) {
      await widget.controller.deleteTemplate(template);
    }
  }
}

class _TemplateTile extends StatelessWidget {
  const _TemplateTile({
    required this.template,
    required this.onLoad,
    required this.onRename,
    required this.onDelete,
  });

  final ProjectTemplate template;
  final VoidCallback onLoad;
  final VoidCallback onRename;
  final VoidCallback onDelete;

  @override
  Widget build(BuildContext context) {
    return ListTile(
      contentPadding: EdgeInsets.zero,
      leading: const Icon(Icons.folder_special_outlined),
      title: Text(template.name),
      subtitle: Text(
        [
          if (template.videoFolder != null) 'Video: ${template.videoFolder}',
          if (template.audioFolder != null) 'Audio: ${template.audioFolder}',
          if (template.outputFolder != null) 'Output: ${template.outputFolder}',
        ].join('\n'),
        maxLines: 3,
        overflow: TextOverflow.ellipsis,
      ),
      trailing: Wrap(
        spacing: AppResponsive.cardGap(context) / 2,
        children: [
          OutlinedButton(onPressed: onLoad, child: const Text('Load')),
          IconButton(
            tooltip: 'Rename',
            onPressed: onRename,
            icon: const Icon(Icons.edit),
          ),
          IconButton(
            tooltip: 'Delete',
            onPressed: onDelete,
            icon: const Icon(Icons.delete_outline),
          ),
        ],
      ),
    );
  }
}

import 'package:flutter/material.dart';
import 'package:path/path.dart' as p;
import 'package:soundswap/core/responsive/app_responsive.dart';
import 'package:soundswap/features/branding/presentation/state/branding_controller.dart';
import 'package:soundswap/features/home/presentation/state/home_controller.dart';
import 'package:soundswap/features/overlay_tools/data/models/overlay_item.dart';
import 'package:soundswap/features/overlay_tools/presentation/state/overlay_tools_controller.dart';
import 'package:soundswap/features/templates/data/models/project_template.dart';
import 'package:soundswap/features/templates/presentation/state/templates_controller.dart';
import 'package:soundswap/features/text_overlay/presentation/state/text_overlay_controller.dart';
import 'package:soundswap/shared/widgets/empty_state.dart';

class OverlayTemplatesPanel extends StatefulWidget {
  const OverlayTemplatesPanel({
    required this.controller,
    required this.templatesController,
    required this.homeController,
    required this.brandingController,
    required this.textOverlayController,
    super.key,
  });

  final OverlayToolsController controller;
  final TemplatesController templatesController;
  final HomeController homeController;
  final BrandingController brandingController;
  final TextOverlayController textOverlayController;

  @override
  State<OverlayTemplatesPanel> createState() => _OverlayTemplatesPanelState();
}

class _OverlayTemplatesPanelState extends State<OverlayTemplatesPanel> {
  final _templateNameController = TextEditingController();

  @override
  void dispose() {
    _templateNameController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: widget.templatesController,
      builder: (context, _) {
        final controller = widget.templatesController;
        return Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              TextField(
                controller: _templateNameController,
                decoration: InputDecoration(
                  labelText: controller.editingTemplateId != null ? 'Updating Template: \${controller.editingTemplateName}' : 'New template name',
                  border: const OutlineInputBorder(),
                  isDense: true,
                ),
              ),
              const SizedBox(height: 8),
              Row(
                children: [
                  if (controller.editingTemplateId != null) ...[
                    FilledButton.icon(
                      onPressed: () async {
                        await controller.updateEditingTemplate(
                          name: _templateNameController.text.isEmpty ? controller.editingTemplateName ?? 'Untitled' : _templateNameController.text,
                          home: widget.homeController,
                          branding: widget.brandingController,
                          textOverlay: widget.textOverlayController,
                          overlay: widget.controller,
                        );
                        _templateNameController.clear();
                      },
                      icon: const Icon(Icons.update),
                      label: const Text('Update Template'),
                    ),
                    const SizedBox(width: 8),
                    OutlinedButton.icon(
                      onPressed: () async {
                        await controller.saveCurrent(
                          name: "\${_templateNameController.text.isEmpty ? controller.editingTemplateName ?? 'Untitled' : _templateNameController.text} (Copy)",
                          home: widget.homeController,
                          branding: widget.brandingController,
                          textOverlay: widget.textOverlayController,
                          overlay: widget.controller,
                        );
                      },
                      icon: const Icon(Icons.copy),
                      label: const Text('Save As New'),
                    ),
                    const SizedBox(width: 8),
                    OutlinedButton.icon(
                      onPressed: _handleCancelEdit,
                      icon: const Icon(Icons.cancel_outlined),
                      label: const Text('Cancel Edit'),
                    ),
                  ] else ...[
                    FilledButton.icon(
                      onPressed: () async {
                        await controller.saveCurrent(
                          name: _templateNameController.text,
                          home: widget.homeController,
                          branding: widget.brandingController,
                          textOverlay: widget.textOverlayController,
                          overlay: widget.controller,
                        );
                        _templateNameController.clear();
                      },
                      icon: const Icon(Icons.save_outlined),
                      label: const Text('Save Current'),
                    ),
                  ],
                ],
              ),
              if (controller.message != null) ...[
                const SizedBox(height: 8),
                Text(controller.message!),
              ],
              const SizedBox(height: 16),
              const Divider(),
              const SizedBox(height: 16),
              Expanded(
                child: controller.templates.isEmpty
                    ? const EmptyState(
                        icon: Icons.inbox_outlined,
                        title: 'No templates yet',
                        message: 'No templates yet. Create overlays, then save them as a template.',
                      )
                    : ListView.builder(
                        itemCount: controller.templates.length,
                        itemBuilder: (context, index) {
                          final template = controller.templates[index];
                          return _TemplateTile(
                            template: template,
                            onApply: () => controller.loadTemplate(
                              template: template,
                              home: widget.homeController,
                              branding: widget.brandingController,
                              textOverlay: widget.textOverlayController,
                              overlay: widget.controller,
                            ),
                            onEditContent: () => _handleEditTemplate(template),
                            onRename: () => _renameTemplate(template),
                            onDelete: () => _confirmDeleteTemplate(template),
                          );
                        },
                      ),
              ),
            ],
          ),
        );
      },
    );
  }

  Future<void> _renameTemplate(ProjectTemplate template) async {
    final controller = TextEditingController(text: template.name);
    final name = await showDialog<String>(
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
    if (name != null && name.trim().isNotEmpty) {
      await widget.templatesController.renameTemplate(
        template: template,
        name: name,
      );
    }
  }

  Future<void> _confirmDeleteTemplate(ProjectTemplate template) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete template?'),
        content: Text('Delete "\${template.name}"?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(context, true),
            style: FilledButton.styleFrom(backgroundColor: Colors.red),
            child: const Text('Delete'),
          ),
        ],
      ),
    );
    if (confirmed == true) {
      await widget.templatesController.deleteTemplate(template);
    }
  }

  Future<void> _handleEditTemplate(ProjectTemplate template) async {
    final controller = widget.templatesController;
    if (controller.hasUnsavedTemplateChanges) {
      final action = await _showUnsavedChangesDialog();
      if (action == null || action == 'Cancel') return;
      if (action == 'Save') {
        await controller.updateEditingTemplate(
          name: _templateNameController.text.isEmpty ? controller.editingTemplateName ?? 'Untitled' : _templateNameController.text,
          home: widget.homeController,
          branding: widget.brandingController,
          textOverlay: widget.textOverlayController,
          overlay: widget.controller,
        );
      }
    }
    _templateNameController.text = template.name;
    await controller.beginEditingTemplate(
      template: template,
      home: widget.homeController,
      branding: widget.brandingController,
      textOverlay: widget.textOverlayController,
      overlay: widget.controller,
    );
  }

  Future<void> _handleCancelEdit() async {
    final controller = widget.templatesController;
    if (controller.hasUnsavedTemplateChanges) {
      final action = await _showUnsavedChangesDialog();
      if (action == null || action == 'Cancel') return;
      if (action == 'Save') {
        await controller.updateEditingTemplate(
          name: _templateNameController.text.isEmpty ? controller.editingTemplateName ?? 'Untitled' : _templateNameController.text,
          home: widget.homeController,
          branding: widget.brandingController,
          textOverlay: widget.textOverlayController,
          overlay: widget.controller,
        );
      }
    }
    controller.cancelEditingTemplate();
    _templateNameController.clear();
  }

  Future<String?> _showUnsavedChangesDialog() async {
    return showDialog<String>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Unsaved changes'),
        content: const Text('You have unsaved changes in the currently editing template. Save them?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, 'Cancel'),
            child: const Text('Cancel'),
          ),
          OutlinedButton(
            onPressed: () => Navigator.pop(context, 'Discard'),
            child: const Text('Discard'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(context, 'Save'),
            child: const Text('Save'),
          ),
        ],
      ),
    );
  }
}

class _TemplateTile extends StatelessWidget {
  const _TemplateTile({
    required this.template,
    required this.onApply,
    required this.onEditContent,
    required this.onRename,
    required this.onDelete,
  });

  final ProjectTemplate template;
  final VoidCallback onApply;
  final VoidCallback onEditContent;
  final VoidCallback onRename;
  final VoidCallback onDelete;

  @override
  Widget build(BuildContext context) {
    final textCount = template.overlaySettings.items.where((item) => item.type == OverlayItemType.text).length;
    final imageCount = template.overlaySettings.items.where((item) => item.type == OverlayItemType.image).length;
    final fontName = template.overlaySettings.defaultFontPath == null
        ? template.overlaySettings.defaultFontFamily
        : p.basename(template.overlaySettings.defaultFontPath!);
    final prefix = template.outputPrefix.trim().isEmpty ? 'soundswap' : template.outputPrefix.trim();

    return Card(
      margin: const EdgeInsets.only(bottom: 8),
      color: Theme.of(context).colorScheme.surfaceContainerLow,
      child: Padding(
        padding: const EdgeInsets.all(12.0),
        child: Row(
          children: [
            const Icon(Icons.dashboard_customize_outlined, size: 28, color: Colors.blue),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    template.name,
                    style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    [
                      '\$textCount text overlays, \$imageCount image overlays',
                      'Font: \$fontName',
                      'Prefix: \$prefix',
                    ].join('\\n'),
                    style: TextStyle(
                      fontSize: 11,
                      color: Theme.of(context).colorScheme.onSurfaceVariant.withValues(alpha: 0.8),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(width: 8),
            Wrap(
              spacing: 4,
              children: [
                OutlinedButton(
                  onPressed: onApply,
                  child: const Text('Apply'),
                ),
                IconButton(
                  tooltip: 'Edit Content',
                  onPressed: onEditContent,
                  icon: const Icon(Icons.edit, size: 20),
                ),
                IconButton(
                  tooltip: 'Rename',
                  onPressed: onRename,
                  icon: const Icon(Icons.drive_file_rename_outline, size: 20),
                ),
                IconButton(
                  tooltip: 'Delete',
                  onPressed: onDelete,
                  icon: const Icon(Icons.delete_outline, size: 20, color: Colors.red),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

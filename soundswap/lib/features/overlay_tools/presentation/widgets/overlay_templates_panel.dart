import 'dart:io';
import 'package:flutter/material.dart';
import 'package:path/path.dart' as p;
import 'package:soundswap/features/branding/presentation/state/branding_controller.dart';
import 'package:soundswap/features/home/presentation/state/home_controller.dart';
import 'package:soundswap/features/overlay_tools/data/models/overlay_item.dart';
import 'package:soundswap/features/overlay_tools/presentation/state/overlay_tools_controller.dart';
import 'package:soundswap/features/templates/data/models/project_template.dart';
import 'package:soundswap/features/templates/presentation/state/templates_controller.dart';
import 'package:soundswap/features/text_overlay/presentation/state/text_overlay_controller.dart';
import 'package:soundswap/features/overlay_tools/presentation/screens/full_screen_editor_screen.dart';
import 'package:soundswap/shared/widgets/empty_state.dart';
import 'package:soundswap/features/overlay_tools/utils/template_render_data.dart';
import 'package:soundswap/features/templates/data/services/template_thumbnail_generator.dart';

class OverlayTemplatesPanel extends StatelessWidget {
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
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: templatesController,
      builder: (context, _) {
        return Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              if (templatesController.message != null) ...[
                Text(templatesController.message!),
                const SizedBox(height: 16),
              ],
              Expanded(
                child: templatesController.templates.isEmpty
                    ? const EmptyState(
                        icon: Icons.inbox_outlined,
                        title: 'No templates yet',
                        message: 'No templates yet. Create overlays, then save them as a template.',
                      )
                    : SingleChildScrollView(
                        child: Wrap(
                          spacing: 16,
                          runSpacing: 16,
                          children: templatesController.templates.map((template) {
                            return SizedBox(
                              width: 240,
                              child: _TemplateTile(
                                template: template,
                                templatesController: templatesController,
                                overlayController: controller,
                                isActive: homeController.selectedTemplateId == template.id,
                                onApply: () => templatesController.loadTemplate(
                                  template: template,
                                  home: homeController,
                                  branding: brandingController,
                                  textOverlay: textOverlayController,
                                  overlay: controller,
                                ),
                                onEditContent: () => _handleEditTemplate(context, template),
                                onDelete: () => _confirmDeleteTemplate(context, template),
                              ),
                            );
                          }).toList(),
                        ),
                      ),
              ),
            ],
          ),
        );
      },
    );
  }

  Future<void> _confirmDeleteTemplate(BuildContext context, ProjectTemplate template) async {
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
            style: FilledButton.styleFrom(backgroundColor: Colors.red),
            child: const Text('Delete'),
          ),
        ],
      ),
    );
    if (confirmed == true) {
      await templatesController.deleteTemplate(template);
    }
  }

  Future<void> _handleEditTemplate(BuildContext context, ProjectTemplate template) async {
    await templatesController.beginEditingTemplate(
      template: template,
      home: homeController,
      branding: brandingController,
      textOverlay: textOverlayController,
      overlay: controller,
    );
    if (context.mounted) {
      Navigator.of(context).push(
        MaterialPageRoute(
          builder: (context) => FullScreenEditorScreen(
            controller: controller,
            templatesController: templatesController,
            homeController: homeController,
            brandingController: brandingController,
            textOverlayController: textOverlayController,
            outputSize: homeController.outputSize,
          ),
        ),
      );
    }
  }
}

class _TemplateTile extends StatefulWidget {
  const _TemplateTile({
    required this.template,
    required this.onApply,
    required this.onEditContent,
    required this.onDelete,
    required this.templatesController,
    required this.isActive,
    required this.overlayController,
  });

  final ProjectTemplate template;
  final VoidCallback onApply;
  final VoidCallback onEditContent;
  final VoidCallback onDelete;
  final TemplatesController templatesController;
  final bool isActive;
  final OverlayToolsController overlayController;

  @override
  State<_TemplateTile> createState() => _TemplateTileState();
}

class _TemplateTileState extends State<_TemplateTile> {
  bool _isLoadingThumbnail = false;
  bool _isHovered = false;
  String? _temporaryThumbnailPath;

  @override
  void initState() {
    super.initState();
    _checkThumbnail();
  }

  @override
  void didUpdateWidget(covariant _TemplateTile oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.template.thumbnailPath != widget.template.thumbnailPath ||
        oldWidget.template.version != widget.template.version ||
        oldWidget.isActive != widget.isActive) {
      _checkThumbnail();
    }
  }

  Future<void> _checkThumbnail() async {
    final path = widget.template.thumbnailPath;
    final exists = path != null && File(path).existsSync();

    print('[TemplateThumbnail] template=${widget.template.name}');
    print('[TemplateThumbnail] path=$path');
    print('[TemplateThumbnail] exists=$exists');
    if (exists) {
      print('[TemplateThumbnail] size=${File(path).lengthSync()}');
    }
    print('[TemplateThumbnail] itemCount=${widget.template.overlaySettings.items.length}');

    if (exists) {
      if (mounted) {
        setState(() {
          _temporaryThumbnailPath = null;
        });
      }
      return;
    }

    if (widget.template.overlaySettings.items.isNotEmpty) {
      setState(() => _isLoadingThumbnail = true);
      try {
        await widget.templatesController.ensureThumbnail(
          widget.template,
          activeWorkspaceItems: widget.overlayController.settings.items,
        );
      } catch (e, st) {
        print('ERROR: Failed to generate thumbnail for ${widget.template.name}: $e\n$st');
      } finally {
        if (mounted) {
          setState(() => _isLoadingThumbnail = false);
        }
      }
    } else if (widget.isActive) {
      setState(() => _isLoadingThumbnail = true);
      try {
        final tempPath = await TemplateThumbnailGenerator.generateThumbnail(
          widget.template,
          activeWorkspaceItems: widget.overlayController.settings.items,
        );
        if (mounted) {
          setState(() {
            _temporaryThumbnailPath = tempPath;
          });
        }
      } catch (e, st) {
        print('ERROR: Failed to generate temporary thumbnail for ${widget.template.name}: $e\n$st');
      } finally {
        if (mounted) {
          setState(() => _isLoadingThumbnail = false);
        }
      }
    } else {
      if (mounted) {
        setState(() {
          _temporaryThumbnailPath = null;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final allItems = TemplateRenderData.buildItems(
      branding: widget.template.useBranding ? widget.template.branding : null,
      textOverlay: widget.template.useTextOverlay ? widget.template.textOverlay : null,
      overlaySettings: widget.template.useOverlay ? widget.template.overlaySettings : widget.template.overlaySettings.copyWith(items: []),
    );

    final textCount = allItems.where((e) => e.type == OverlayItemType.text).length;
    final imageCount = allItems.where((e) => e.type == OverlayItemType.image).length;
    final fonts = allItems
        .where((e) => e.type == OverlayItemType.text)
        .map((e) => e.fontFamily)
        .toSet()
        .join(', ');

    final resolvedPath = widget.template.thumbnailPath ?? _temporaryThumbnailPath;
    final hasThumbnail = resolvedPath != null && File(resolvedPath).existsSync();

    return MouseRegion(
      onEnter: (_) => setState(() => _isHovered = true),
      onExit: (_) => setState(() => _isHovered = false),
      child: Card(
        clipBehavior: Clip.antiAlias,
        color: widget.isActive
            ? Theme.of(context).colorScheme.primaryContainer.withValues(alpha: 0.3)
            : Theme.of(context).colorScheme.surfaceContainerLow,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
          side: widget.isActive
              ? BorderSide(color: Theme.of(context).colorScheme.primary, width: 2)
              : BorderSide.none,
        ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        mainAxisSize: MainAxisSize.min,
        children: [
          AspectRatio(
            aspectRatio: 9 / 16,
            child: hasThumbnail
                ? Image.file(
                    File(resolvedPath!),
                    key: ValueKey('${widget.template.id}-${widget.template.version}-$resolvedPath'),
                    fit: BoxFit.cover,
                  )
                : Container(
                    color: Theme.of(context).colorScheme.surfaceContainerHighest,
                    child: _isLoadingThumbnail
                        ? const Center(
                            child: Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                SizedBox(width: 24, height: 24, child: CircularProgressIndicator(strokeWidth: 2)),
                                SizedBox(height: 12),
                                Text(
                                  'Generating\npreview...',
                                  textAlign: TextAlign.center,
                                  style: TextStyle(fontSize: 12, color: Colors.grey),
                                ),
                              ],
                            ),
                          )
                        : const Center(
                            child: Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Icon(Icons.image_not_supported, size: 28, color: Colors.grey),
                                SizedBox(height: 8),
                                Text(
                                  'Preview\nunavailable',
                                  textAlign: TextAlign.center,
                                  style: TextStyle(fontSize: 12, color: Colors.grey),
                                ),
                              ],
                            ),
                          ),
                  ),
          ),
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                if (widget.isActive)
                  Container(
                    margin: const EdgeInsets.only(bottom: 8),
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    decoration: BoxDecoration(
                      color: Theme.of(context).colorScheme.primary,
                      borderRadius: BorderRadius.circular(4),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(Icons.check, size: 14, color: Theme.of(context).colorScheme.onPrimary),
                        const SizedBox(width: 4),
                        Text(
                          'Active Template',
                          style: TextStyle(
                            fontSize: 11,
                            fontWeight: FontWeight.bold,
                            color: Theme.of(context).colorScheme.onPrimary,
                          ),
                        ),
                      ],
                    ),
                  ),
                Text(
                  widget.template.name,
                  style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 8),
                Text(
                  [
                    '$textCount texts • $imageCount images',
                    'Font: ${fonts.isEmpty ? "None" : fonts}',
                  ].join('\n'),
                  style: TextStyle(
                    fontSize: 13,
                    height: 1.5,
                    color: Theme.of(context).colorScheme.onSurfaceVariant.withValues(alpha: 0.8),
                  ),
                ),
                const SizedBox(height: 16),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Expanded(
                      child: FilledButton(
                        onPressed: widget.onApply,
                        style: FilledButton.styleFrom(
                          visualDensity: VisualDensity.compact,
                        ),
                        child: const Text('Apply'),
                      ),
                    ),
                    const SizedBox(width: 8),
                    IconButton(
                      tooltip: 'Edit',
                      onPressed: widget.onEditContent,
                      icon: const Icon(Icons.edit, size: 20),
                      style: IconButton.styleFrom(
                        backgroundColor: Theme.of(context).colorScheme.surfaceContainerHigh,
                      ),
                    ),
                    IconButton(
                      tooltip: 'Delete',
                      onPressed: widget.onDelete,
                      icon: const Icon(Icons.delete_outline, size: 20, color: Colors.red),
                      style: IconButton.styleFrom(
                        backgroundColor: Theme.of(context).colorScheme.surfaceContainerHigh,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ), // closes Column
    ), // closes Card
  ); // closes MouseRegion
  }
}

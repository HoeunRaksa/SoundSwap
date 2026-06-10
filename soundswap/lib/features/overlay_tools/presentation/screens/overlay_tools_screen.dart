import 'package:flutter/material.dart';
import 'package:path/path.dart' as p;
import 'package:soundswap/core/responsive/app_responsive.dart';
import 'package:soundswap/core/video/video_output_settings.dart';
import 'package:soundswap/features/branding/presentation/state/branding_controller.dart';
import 'package:soundswap/features/home/presentation/state/home_controller.dart';
import 'package:soundswap/features/overlay_tools/data/models/overlay_item.dart';
import 'package:soundswap/features/overlay_tools/presentation/state/overlay_tools_controller.dart';
import 'package:soundswap/features/templates/data/models/project_template.dart';
import 'package:soundswap/features/templates/presentation/state/templates_controller.dart';
import 'package:soundswap/features/text_overlay/presentation/state/text_overlay_controller.dart';
import 'package:soundswap/shared/widgets/empty_state.dart';
import 'package:soundswap/shared/widgets/feature_page.dart';
import 'package:soundswap/shared/widgets/overlay_preview_canvas.dart';

class OverlayToolsScreen extends StatefulWidget {
  const OverlayToolsScreen({
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
  State<OverlayToolsScreen> createState() => _OverlayToolsScreenState();
}

class _OverlayToolsScreenState extends State<OverlayToolsScreen> {
  final _nameController = TextEditingController();
  final _textController = TextEditingController();
  final _fontSizeController = TextEditingController();
  final _colorController = TextEditingController();
  final _widthController = TextEditingController();
  final _templateNameController = TextEditingController();
  final _nameFocus = FocusNode();
  final _textFocus = FocusNode();
  final _fontSizeFocus = FocusNode();
  final _colorFocus = FocusNode();
  final _widthFocus = FocusNode();
  VideoOutputSize _previewSize = VideoOutputSize.vertical1080;

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
    _templateNameController.dispose();
    _nameFocus.dispose();
    _textFocus.dispose();
    _fontSizeFocus.dispose();
    _colorFocus.dispose();
    _widthFocus.dispose();
    super.dispose();
  }

  void _syncFromState() {
    if (_nameFocus.hasFocus ||
        _textFocus.hasFocus ||
        _fontSizeFocus.hasFocus ||
        _colorFocus.hasFocus ||
        _widthFocus.hasFocus) {
      return;
    }
    final item = widget.controller.selectedItem;
    if (item == null) {
      _setText(_nameController, '');
      _setText(_textController, '');
      _setText(_fontSizeController, '');
      _setText(_colorController, '');
      _setText(_widthController, '');
      return;
    }
    _setText(_nameController, item.name);
    _setText(_textController, item.text);
    _setText(_fontSizeController, item.fontSize.toStringAsFixed(0));
    _setText(_colorController, item.colorHex);
    _setText(_widthController, (item.width * 100).toStringAsFixed(0));
  }

  void _setText(TextEditingController controller, String value) {
    if (controller.text != value) controller.text = value;
  }

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: widget.controller,
      builder: (context, _) {
        return ListenableBuilder(
          listenable: widget.templatesController,
          builder: (context, _) {
            return FeaturePage(
              title: 'Overlay & Templates',
              subtitle:
                  'Create text and image overlays, preview placement, then save or apply reusable templates.',
              children: [
                ResponsiveLayout(
                  small: Column(
                    children: [
                      _buildPreview(context),
                      SizedBox(height: AppResponsive.cardGap(context)),
                      _buildEditor(context),
                    ],
                  ),
                  medium: _TwoColumn(
                    left: _buildPreview(context),
                    right: _buildEditor(context),
                  ),
                  large: _TwoColumn(
                    left: _buildPreview(context),
                    right: _buildEditor(context),
                  ),
                ),
                _buildTemplateSection(context),
              ],
            );
          },
        );
      },
    );
  }

  Widget _buildPreview(BuildContext context) {
    final controller = widget.controller;
    final items = [
      for (final item in controller.settings.items)
        PreviewOverlayItem(
          id: item.id,
          label: item.name.isEmpty ? _itemTypeLabel(item) : item.name,
          kind: item.type == OverlayItemType.image
              ? PreviewOverlayKind.logo
              : PreviewOverlayKind.text,
          position: item.position,
          text: item.text,
          imagePath: item.imagePath,
          colorHex: item.colorHex,
          fontSize: item.fontSize,
          width: item.width,
          backgroundBox: item.backgroundBox,
          shadow: item.shadow,
          selected: item.id == controller.selectedItemId,
        ),
    ];

    return SettingsSection(
      title: 'Preview',
      icon: Icons.open_with,
      children: [
        Row(
          children: [
            FilledButton.icon(
              onPressed: controller.addText,
              icon: const Icon(Icons.text_fields),
              label: const Text('Add Text'),
            ),
            SizedBox(width: AppResponsive.cardGap(context) / 2),
            OutlinedButton.icon(
              onPressed: controller.addImage,
              icon: const Icon(Icons.image_outlined),
              label: const Text('Add Image'),
            ),
          ],
        ),
        DropdownButtonFormField<VideoOutputSize>(
          initialValue: _previewSize,
          isExpanded: true,
          decoration: const InputDecoration(labelText: 'Preview size'),
          items: [
            for (final size in VideoOutputSize.values)
              DropdownMenuItem(value: size, child: Text(size.label)),
          ],
          onChanged: (value) {
            if (value != null) setState(() => _previewSize = value);
          },
        ),
        OverlayPreviewCanvas(
          outputSize: _previewSize,
          items: items,
          onSelected: controller.selectItem,
          onPositionChanged: controller.moveItem,
          onWidthChanged: controller.resizeItem,
        ),
      ],
    );
  }

  Widget _buildEditor(BuildContext context) {
    final item = widget.controller.selectedItem;
    return SettingsSection(
      title: 'Selected overlay',
      icon: Icons.edit_outlined,
      children: [
        if (widget.controller.settings.items.isEmpty)
          const SizedBox(
            height: 180,
            child: EmptyState(
              icon: Icons.layers_clear_outlined,
              title: 'No overlays yet',
              message:
                  'Use Add Text or Add Image to create your first overlay.',
            ),
          )
        else ...[
          SizedBox(
            height: 140,
            child: ListView(
              children: [
                for (final overlay in widget.controller.settings.items)
                  _OverlayListTile(
                    item: overlay,
                    selected: overlay.id == widget.controller.selectedItemId,
                    onTap: () => widget.controller.selectItem(overlay.id),
                  ),
              ],
            ),
          ),
          const Divider(),
          if (item == null)
            const Text('Select an overlay to edit it.')
          else
            _buildSelectedEditor(context, item),
        ],
      ],
    );
  }

  Widget _buildSelectedEditor(BuildContext context, OverlayItem item) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        TextField(
          controller: _nameController,
          focusNode: _nameFocus,
          decoration: const InputDecoration(labelText: 'Name'),
          onChanged: (value) =>
              widget.controller.updateSelected(item.copyWith(name: value)),
        ),
        if (item.type == OverlayItemType.text) ...[
          TextField(
            controller: _textController,
            focusNode: _textFocus,
            minLines: 2,
            maxLines: 6,
            decoration: const InputDecoration(labelText: 'Text'),
            onChanged: (value) =>
                widget.controller.updateSelected(item.copyWith(text: value)),
          ),
          DropdownButtonFormField<String>(
            initialValue: item.fontFamily,
            isExpanded: true,
            decoration: const InputDecoration(labelText: 'Font'),
            items: const [
              DropdownMenuItem(value: 'Arial', child: Text('Arial')),
              DropdownMenuItem(value: 'Segoe UI', child: Text('Segoe UI')),
              DropdownMenuItem(value: 'Tahoma', child: Text('Tahoma')),
              DropdownMenuItem(value: 'Verdana', child: Text('Verdana')),
              DropdownMenuItem(
                value: 'Times New Roman',
                child: Text('Times New Roman'),
              ),
            ],
            onChanged: (value) {
              if (value != null) {
                widget.controller.updateSelected(
                  item.copyWith(fontFamily: value),
                );
              }
            },
          ),
          TextField(
            controller: _fontSizeController,
            focusNode: _fontSizeFocus,
            keyboardType: TextInputType.number,
            decoration: const InputDecoration(labelText: 'Font size'),
            onChanged: (value) {
              final size = double.tryParse(value);
              if (size != null) {
                widget.controller.updateSelected(
                  item.copyWith(fontSize: size.clamp(10, 240).toDouble()),
                );
              }
            },
          ),
          TextField(
            controller: _colorController,
            focusNode: _colorFocus,
            decoration: const InputDecoration(
              labelText: 'Text color',
              hintText: '#FFFFFF',
            ),
            onChanged: (value) => widget.controller.updateSelected(
              item.copyWith(colorHex: value),
            ),
          ),
          SwitchListTile(
            contentPadding: EdgeInsets.zero,
            title: const Text('Text shadow'),
            value: item.shadow,
            onChanged: (value) =>
                widget.controller.updateSelected(item.copyWith(shadow: value)),
          ),
          SwitchListTile(
            contentPadding: EdgeInsets.zero,
            title: const Text('Background box'),
            value: item.backgroundBox,
            onChanged: (value) => widget.controller.updateSelected(
              item.copyWith(backgroundBox: value),
            ),
          ),
          OutlinedButton.icon(
            onPressed: widget.controller.pickDefaultFont,
            icon: const Icon(Icons.font_download_outlined),
            label: Text(
              widget.controller.settings.defaultFontPath == null
                  ? 'Choose Custom Font'
                  : 'Font: ${p.basename(widget.controller.settings.defaultFontPath!)}',
            ),
          ),
        ] else ...[
          Text(
            item.imagePath == null ? 'No image selected' : item.imagePath!,
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
          ),
        ],
        TextField(
          controller: _widthController,
          focusNode: _widthFocus,
          keyboardType: TextInputType.number,
          decoration: const InputDecoration(labelText: 'Size percent'),
          onChanged: (value) {
            final width = double.tryParse(value);
            if (width != null) {
              widget.controller.updateSelected(
                item.copyWith(width: (width / 100).clamp(0.08, 1).toDouble()),
              );
            }
          },
        ),
        OutlinedButton.icon(
          onPressed: widget.controller.removeSelected,
          icon: const Icon(Icons.delete_outline),
          label: const Text('Remove'),
        ),
      ],
    );
  }

  Widget _buildTemplateSection(BuildContext context) {
    final controller = widget.templatesController;
    return SettingsSection(
      title: 'Templates',
      icon: Icons.dashboard_customize_outlined,
      children: [
        Row(
          children: [
            Expanded(
              child: TextField(
                controller: _templateNameController,
                decoration: const InputDecoration(
                  labelText: 'Template name',
                  hintText: 'PVC Factory',
                ),
              ),
            ),
            SizedBox(width: AppResponsive.cardGap(context) / 2),
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
              label: const Text('Save Current as Template'),
            ),
          ],
        ),
        if (controller.message != null) Text(controller.message!),
        if (controller.templates.isEmpty)
          const SizedBox(
            height: 180,
            child: EmptyState(
              icon: Icons.inbox_outlined,
              title: 'No templates yet',
              message:
                  'No templates yet. Create overlays, then save them as a template.',
            ),
          )
        else
          for (final template in controller.templates)
            _TemplateTile(
              template: template,
              onApply: () => controller.loadTemplate(
                template: template,
                home: widget.homeController,
                branding: widget.brandingController,
                textOverlay: widget.textOverlayController,
                overlay: widget.controller,
              ),
              onRename: () => _renameTemplate(template),
              onDelete: () => _confirmDeleteTemplate(template),
            ),
      ],
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
    if (name != null) {
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
      await widget.templatesController.deleteTemplate(template);
    }
  }

  String _itemTypeLabel(OverlayItem item) {
    return item.type == OverlayItemType.text ? 'Text overlay' : 'Image overlay';
  }
}

class _OverlayListTile extends StatelessWidget {
  const _OverlayListTile({
    required this.item,
    required this.selected,
    required this.onTap,
  });

  final OverlayItem item;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return ListTile(
      selected: selected,
      dense: true,
      contentPadding: EdgeInsets.zero,
      leading: Icon(
        item.type == OverlayItemType.text
            ? Icons.text_fields
            : Icons.image_outlined,
      ),
      title: Text(item.name.isEmpty ? 'Overlay' : item.name),
      subtitle: Text(
        item.type == OverlayItemType.text
            ? item.text
            : p.basename(item.imagePath ?? ''),
        maxLines: 1,
        overflow: TextOverflow.ellipsis,
      ),
      onTap: onTap,
    );
  }
}

class _TemplateTile extends StatelessWidget {
  const _TemplateTile({
    required this.template,
    required this.onApply,
    required this.onRename,
    required this.onDelete,
  });

  final ProjectTemplate template;
  final VoidCallback onApply;
  final VoidCallback onRename;
  final VoidCallback onDelete;

  @override
  Widget build(BuildContext context) {
    final textCount = template.overlaySettings.items
        .where((item) => item.type == OverlayItemType.text)
        .length;
    final imageCount = template.overlaySettings.items
        .where((item) => item.type == OverlayItemType.image)
        .length;
    final fontName = template.overlaySettings.defaultFontPath == null
        ? template.overlaySettings.defaultFontFamily
        : p.basename(template.overlaySettings.defaultFontPath!);
    final prefix = template.outputPrefix.trim().isEmpty
        ? 'soundswap'
        : template.outputPrefix.trim();

    return ListTile(
      contentPadding: EdgeInsets.zero,
      leading: const Icon(Icons.dashboard_customize_outlined),
      title: Text(template.name),
      subtitle: Text(
        [
          '$textCount text overlays',
          '$imageCount image overlays',
          'Font: $fontName',
          'Output prefix: $prefix',
          'Size: ${template.outputSize.label}',
          'Fit: ${template.fitMode.label}',
        ].join('\n'),
        maxLines: 6,
        overflow: TextOverflow.ellipsis,
      ),
      trailing: Wrap(
        spacing: AppResponsive.cardGap(context) / 2,
        children: [
          OutlinedButton(
            onPressed: onApply,
            child: const Text('Apply Template'),
          ),
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

class _TwoColumn extends StatelessWidget {
  const _TwoColumn({required this.left, required this.right});

  final Widget left;
  final Widget right;

  @override
  Widget build(BuildContext context) {
    final gap = AppResponsive.cardGap(context);
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Expanded(child: left),
        SizedBox(width: gap),
        Expanded(child: right),
      ],
    );
  }
}

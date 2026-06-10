import 'package:flutter/material.dart';
import 'package:soundswap/core/responsive/app_responsive.dart';
import 'package:soundswap/core/video/video_output_settings.dart';
import 'package:soundswap/features/text_overlay/data/models/text_overlay_preset.dart';
import 'package:soundswap/features/text_overlay/data/models/text_overlay_settings.dart';
import 'package:soundswap/features/text_overlay/presentation/state/text_overlay_controller.dart';
import 'package:soundswap/shared/widgets/empty_state.dart';
import 'package:soundswap/shared/widgets/feature_page.dart';
import 'package:soundswap/shared/widgets/overlay_preview_canvas.dart';

class TextOverlayScreen extends StatefulWidget {
  const TextOverlayScreen({required this.controller, super.key});

  final TextOverlayController controller;

  @override
  State<TextOverlayScreen> createState() => _TextOverlayScreenState();
}

class _TextOverlayScreenState extends State<TextOverlayScreen> {
  final _titleController = TextEditingController();
  final _subtitleController = TextEditingController();
  final _promotionController = TextEditingController();
  final _priceController = TextEditingController();
  final _fontSizeController = TextEditingController();
  final _colorController = TextEditingController();
  final _presetNameController = TextEditingController();
  final _titleFocus = FocusNode();
  final _subtitleFocus = FocusNode();
  final _promotionFocus = FocusNode();
  final _priceFocus = FocusNode();
  final _fontSizeFocus = FocusNode();
  final _colorFocus = FocusNode();
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
    _titleController.dispose();
    _subtitleController.dispose();
    _promotionController.dispose();
    _priceController.dispose();
    _fontSizeController.dispose();
    _colorController.dispose();
    _presetNameController.dispose();
    _titleFocus.dispose();
    _subtitleFocus.dispose();
    _promotionFocus.dispose();
    _priceFocus.dispose();
    _fontSizeFocus.dispose();
    _colorFocus.dispose();
    super.dispose();
  }

  void _syncFromState() {
    if (_titleFocus.hasFocus ||
        _subtitleFocus.hasFocus ||
        _promotionFocus.hasFocus ||
        _priceFocus.hasFocus ||
        _fontSizeFocus.hasFocus ||
        _colorFocus.hasFocus) {
      return;
    }
    final settings = widget.controller.settings;
    _setTextIfChanged(_titleController, settings.title);
    _setTextIfChanged(_subtitleController, settings.subtitle);
    _setTextIfChanged(_promotionController, settings.promotionText);
    _setTextIfChanged(_priceController, settings.priceText);
    _setTextIfChanged(
      _fontSizeController,
      settings.fontSize.toStringAsFixed(0),
    );
    _setTextIfChanged(_colorController, settings.textColor);
  }

  void _setTextIfChanged(TextEditingController controller, String value) {
    if (controller.text != value) {
      controller.text = value;
    }
  }

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: widget.controller,
      builder: (context, _) {
        final settings = widget.controller.settings;
        return FeaturePage(
          title: 'Text Overlay',
          subtitle:
              'Create reusable text overlays with manual drag positioning and optional effects.',
          children: [
            ResponsiveLayout(
              small: Column(
                children: [
                  _buildSettings(context, settings),
                  SizedBox(height: AppResponsive.cardGap(context)),
                  _buildPreview(context, settings),
                ],
              ),
              medium: _TwoColumn(
                left: _buildSettings(context, settings),
                right: _buildPreview(context, settings),
              ),
              large: _TwoColumn(
                left: _buildSettings(context, settings),
                right: _buildPreview(context, settings),
              ),
            ),
            _buildPresetSection(context),
            SettingsSection(
              title: 'Prepared FFmpeg drawtext support',
              icon: Icons.terminal,
              children: [
                SelectableText(
                  settings.buildDrawTextPreview(),
                  style: TextStyle(
                    fontFamily: 'Consolas',
                    fontSize: AppResponsive.bodySize(context),
                  ),
                ),
              ],
            ),
          ],
        );
      },
    );
  }

  Widget _buildSettings(BuildContext context, TextOverlaySettings settings) {
    return SettingsSection(
      title: 'Overlay text and style',
      icon: Icons.text_fields,
      children: [
        _OverlayField(
          label: 'Title',
          controller: _titleController,
          focusNode: _titleFocus,
          maxLines: 2,
          onChanged: (value) =>
              widget.controller.update(settings.copyWith(title: value)),
        ),
        _OverlayField(
          label: 'Subtitle',
          controller: _subtitleController,
          focusNode: _subtitleFocus,
          maxLines: 3,
          onChanged: (value) =>
              widget.controller.update(settings.copyWith(subtitle: value)),
        ),
        _OverlayField(
          label: 'Promotion text',
          controller: _promotionController,
          focusNode: _promotionFocus,
          maxLines: 3,
          onChanged: (value) =>
              widget.controller.update(settings.copyWith(promotionText: value)),
        ),
        _OverlayField(
          label: 'Price text',
          controller: _priceController,
          focusNode: _priceFocus,
          maxLines: 2,
          onChanged: (value) =>
              widget.controller.update(settings.copyWith(priceText: value)),
        ),
        DropdownButtonFormField<String>(
          key: ValueKey(settings.fontFamily),
          initialValue: settings.fontFamily,
          decoration: const InputDecoration(labelText: 'Font family'),
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
              widget.controller.update(settings.copyWith(fontFamily: value));
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
              widget.controller.update(
                settings.copyWith(fontSize: size.clamp(12, 220).toDouble()),
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
          onChanged: (value) =>
              widget.controller.update(settings.copyWith(textColor: value)),
        ),
        SwitchListTile(
          contentPadding: EdgeInsets.zero,
          title: const Text('Text shadow'),
          value: settings.shadow,
          onChanged: (value) =>
              widget.controller.update(settings.copyWith(shadow: value)),
        ),
        SwitchListTile(
          contentPadding: EdgeInsets.zero,
          title: const Text('Background box'),
          value: settings.backgroundBox,
          onChanged: (value) =>
              widget.controller.update(settings.copyWith(backgroundBox: value)),
        ),
      ],
    );
  }

  Widget _buildPreview(BuildContext context, TextOverlaySettings settings) {
    return SettingsSection(
      title: 'Preview and position',
      icon: Icons.drag_indicator,
      children: [
        DropdownButtonFormField<VideoOutputSize>(
          key: ValueKey(_previewSize),
          initialValue: _previewSize,
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
          items: [
            PreviewOverlayItem(
              id: 'title',
              label: 'Title',
              kind: PreviewOverlayKind.text,
              position: settings.titlePosition,
              text: settings.title,
              colorHex: settings.textColor,
              fontSize: settings.fontSize,
              backgroundBox: settings.backgroundBox,
              shadow: settings.shadow,
            ),
            PreviewOverlayItem(
              id: 'subtitle',
              label: 'Subtitle',
              kind: PreviewOverlayKind.text,
              position: settings.subtitlePosition,
              text: settings.subtitle,
              colorHex: settings.textColor,
              fontSize: settings.fontSize,
              backgroundBox: settings.backgroundBox,
              shadow: settings.shadow,
            ),
            PreviewOverlayItem(
              id: 'promotion',
              label: 'Promotion',
              kind: PreviewOverlayKind.text,
              position: settings.promotionPosition,
              text: settings.promotionText,
              colorHex: settings.textColor,
              fontSize: settings.fontSize,
              backgroundBox: settings.backgroundBox,
              shadow: settings.shadow,
            ),
            PreviewOverlayItem(
              id: 'price',
              label: 'Price',
              kind: PreviewOverlayKind.text,
              position: settings.pricePosition,
              text: settings.priceText,
              colorHex: settings.textColor,
              fontSize: settings.fontSize,
              backgroundBox: settings.backgroundBox,
              shadow: settings.shadow,
            ),
          ],
          onPositionChanged: (id, position) {
            final next = switch (id) {
              'title' => settings.copyWith(titlePosition: position),
              'subtitle' => settings.copyWith(subtitlePosition: position),
              'promotion' => settings.copyWith(promotionPosition: position),
              'price' => settings.copyWith(pricePosition: position),
              _ => settings,
            };
            widget.controller.update(next);
          },
        ),
      ],
    );
  }

  Widget _buildPresetSection(BuildContext context) {
    return SettingsSection(
      title: 'Text presets',
      icon: Icons.bookmark_border,
      children: [
        Row(
          children: [
            Expanded(
              child: TextField(
                controller: _presetNameController,
                decoration: const InputDecoration(
                  labelText: 'Preset name',
                  hintText: 'Promotion',
                ),
              ),
            ),
            SizedBox(width: AppResponsive.cardGap(context) / 2),
            FilledButton.icon(
              onPressed: () {
                widget.controller.savePreset(_presetNameController.text);
                _presetNameController.clear();
              },
              icon: const Icon(Icons.add),
              label: const Text('Save'),
            ),
          ],
        ),
        if (widget.controller.message != null) Text(widget.controller.message!),
        if (widget.controller.presets.isEmpty)
          const SizedBox(
            height: 180,
            child: EmptyState(
              icon: Icons.bookmark_remove_outlined,
              title: 'No text presets',
              message: 'Save overlay text as a reusable preset.',
            ),
          )
        else
          for (final preset in widget.controller.presets)
            _TextPresetTile(
              preset: preset,
              onLoad: () => widget.controller.loadPreset(preset),
              onRename: () => _renamePreset(preset),
              onDelete: () => _confirmDeletePreset(preset),
            ),
      ],
    );
  }

  Future<void> _renamePreset(TextOverlayPreset preset) async {
    final controller = TextEditingController(text: preset.name);
    final name = await showDialog<String>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Rename text preset'),
        content: TextField(
          controller: controller,
          autofocus: true,
          decoration: const InputDecoration(labelText: 'Preset name'),
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
      await widget.controller.renamePreset(preset: preset, name: name);
    }
  }

  Future<void> _confirmDeletePreset(TextOverlayPreset preset) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete text preset?'),
        content: Text('Delete "${preset.name}"?'),
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
      await widget.controller.deletePreset(preset);
    }
  }
}

class _OverlayField extends StatelessWidget {
  const _OverlayField({
    required this.label,
    required this.controller,
    required this.focusNode,
    required this.onChanged,
    required this.maxLines,
  });

  final String label;
  final TextEditingController controller;
  final FocusNode focusNode;
  final ValueChanged<String> onChanged;
  final int maxLines;

  @override
  Widget build(BuildContext context) {
    return TextFormField(
      controller: controller,
      focusNode: focusNode,
      onChanged: onChanged,
      minLines: 1,
      maxLines: maxLines,
      decoration: InputDecoration(labelText: label),
      style: TextStyle(fontSize: AppResponsive.bodySize(context)),
    );
  }
}

class _TextPresetTile extends StatelessWidget {
  const _TextPresetTile({
    required this.preset,
    required this.onLoad,
    required this.onRename,
    required this.onDelete,
  });

  final TextOverlayPreset preset;
  final VoidCallback onLoad;
  final VoidCallback onRename;
  final VoidCallback onDelete;

  @override
  Widget build(BuildContext context) {
    final settings = preset.settings;
    final preview = [
      settings.title,
      settings.subtitle,
      settings.promotionText,
      settings.priceText,
    ].where((value) => value.trim().isNotEmpty).join(' / ');

    return ListTile(
      contentPadding: EdgeInsets.zero,
      leading: const Icon(Icons.bookmark_outline),
      title: Text(preset.name),
      subtitle: Text(
        preview.isEmpty ? 'No text configured' : preview,
        maxLines: 2,
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

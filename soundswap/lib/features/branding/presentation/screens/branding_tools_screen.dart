import 'package:flutter/material.dart';
import 'package:soundswap/core/responsive/app_responsive.dart';
import 'package:soundswap/core/video/video_output_settings.dart';
import 'package:soundswap/features/branding/data/models/branding_preset.dart';
import 'package:soundswap/features/branding/data/models/branding_settings.dart';
import 'package:soundswap/features/branding/presentation/state/branding_controller.dart';
import 'package:soundswap/shared/widgets/empty_state.dart';
import 'package:soundswap/shared/widgets/feature_page.dart';
import 'package:soundswap/shared/widgets/overlay_preview_canvas.dart';

class BrandingToolsScreen extends StatefulWidget {
  const BrandingToolsScreen({required this.controller, super.key});

  final BrandingController controller;

  @override
  State<BrandingToolsScreen> createState() => _BrandingToolsScreenState();
}

class _BrandingToolsScreenState extends State<BrandingToolsScreen> {
  final _phoneController = TextEditingController();
  final _telegramController = TextEditingController();
  final _facebookController = TextEditingController();
  final _fontSizeController = TextEditingController();
  final _colorController = TextEditingController();
  final _presetNameController = TextEditingController();
  final _phoneFocus = FocusNode();
  final _telegramFocus = FocusNode();
  final _facebookFocus = FocusNode();
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
    _phoneController.dispose();
    _telegramController.dispose();
    _facebookController.dispose();
    _fontSizeController.dispose();
    _colorController.dispose();
    _presetNameController.dispose();
    _phoneFocus.dispose();
    _telegramFocus.dispose();
    _facebookFocus.dispose();
    _fontSizeFocus.dispose();
    _colorFocus.dispose();
    super.dispose();
  }

  void _syncFromState() {
    if (_phoneFocus.hasFocus ||
        _telegramFocus.hasFocus ||
        _facebookFocus.hasFocus ||
        _fontSizeFocus.hasFocus ||
        _colorFocus.hasFocus) {
      return;
    }
    final settings = widget.controller.settings;
    _setTextIfChanged(_phoneController, settings.phoneNumber);
    _setTextIfChanged(_telegramController, settings.telegram);
    _setTextIfChanged(_facebookController, settings.facebookPage);
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
          title: 'Branding Tools',
          subtitle:
              'Create reusable logo and contact overlays with manual preview positioning.',
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
              title: 'Prepared FFmpeg overlay support',
              icon: Icons.terminal,
              children: [
                SelectableText(
                  settings.buildOverlayPreview(),
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

  Widget _buildSettings(BuildContext context, BrandingSettings settings) {
    return SettingsSection(
      title: 'Logo and contact details',
      icon: Icons.branding_watermark_outlined,
      children: [
        OutlinedButton.icon(
          onPressed: widget.controller.pickLogo,
          icon: Icon(
            Icons.image_outlined,
            size: AppResponsive.iconSize(context),
          ),
          label: const Text('Select Logo Image'),
        ),
        Text(
          settings.logoPath ?? 'No logo selected',
          maxLines: 2,
          overflow: TextOverflow.ellipsis,
          style: TextStyle(fontSize: AppResponsive.bodySize(context)),
        ),
        _BrandingField(
          label: 'Phone number',
          controller: _phoneController,
          focusNode: _phoneFocus,
          onChanged: (value) =>
              widget.controller.update(settings.copyWith(phoneNumber: value)),
        ),
        _BrandingField(
          label: 'Telegram',
          controller: _telegramController,
          focusNode: _telegramFocus,
          onChanged: (value) =>
              widget.controller.update(settings.copyWith(telegram: value)),
        ),
        _BrandingField(
          label: 'Facebook page name',
          controller: _facebookController,
          focusNode: _facebookFocus,
          onChanged: (value) =>
              widget.controller.update(settings.copyWith(facebookPage: value)),
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
                settings.copyWith(fontSize: size.clamp(12, 180).toDouble()),
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
      ],
    );
  }

  Widget _buildPreview(BuildContext context, BrandingSettings settings) {
    final items = [
      PreviewOverlayItem(
        id: 'logo',
        label: 'Logo',
        kind: PreviewOverlayKind.logo,
        position: settings.logoPosition,
        imagePath: settings.logoPath,
      ),
      PreviewOverlayItem(
        id: 'brandingText',
        label: 'Contact',
        kind: PreviewOverlayKind.text,
        position: settings.textPosition,
        text: settings.contactText,
        colorHex: settings.textColor,
        fontSize: settings.fontSize,
        backgroundBox: true,
        shadow: true,
      ),
    ];

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
          items: items,
          onPositionChanged: (id, position) {
            if (id == 'logo') {
              widget.controller.update(
                settings.copyWith(logoPosition: position),
              );
            } else {
              widget.controller.update(
                settings.copyWith(textPosition: position),
              );
            }
          },
        ),
      ],
    );
  }

  Widget _buildPresetSection(BuildContext context) {
    return SettingsSection(
      title: 'Branding presets',
      icon: Icons.bookmark_border,
      children: [
        Row(
          children: [
            Expanded(
              child: TextField(
                controller: _presetNameController,
                decoration: const InputDecoration(
                  labelText: 'Preset name',
                  hintText: 'PVC Factory',
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
              title: 'No branding presets',
              message: 'Save logo and contact settings as a preset.',
            ),
          )
        else
          for (final preset in widget.controller.presets)
            _BrandingPresetTile(
              preset: preset,
              onLoad: () => widget.controller.loadPreset(preset),
              onRename: () => _renamePreset(preset),
              onDelete: () => _confirmDeletePreset(preset),
            ),
      ],
    );
  }

  Future<void> _renamePreset(BrandingPreset preset) async {
    final controller = TextEditingController(text: preset.name);
    final name = await showDialog<String>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Rename branding preset'),
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

  Future<void> _confirmDeletePreset(BrandingPreset preset) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete branding preset?'),
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

class _BrandingField extends StatelessWidget {
  const _BrandingField({
    required this.label,
    required this.controller,
    required this.focusNode,
    required this.onChanged,
  });

  final String label;
  final TextEditingController controller;
  final FocusNode focusNode;
  final ValueChanged<String> onChanged;

  @override
  Widget build(BuildContext context) {
    return TextFormField(
      controller: controller,
      focusNode: focusNode,
      onChanged: onChanged,
      maxLines: 1,
      decoration: InputDecoration(labelText: label),
      style: TextStyle(fontSize: AppResponsive.bodySize(context)),
    );
  }
}

class _BrandingPresetTile extends StatelessWidget {
  const _BrandingPresetTile({
    required this.preset,
    required this.onLoad,
    required this.onRename,
    required this.onDelete,
  });

  final BrandingPreset preset;
  final VoidCallback onLoad;
  final VoidCallback onRename;
  final VoidCallback onDelete;

  @override
  Widget build(BuildContext context) {
    return ListTile(
      contentPadding: EdgeInsets.zero,
      leading: const Icon(Icons.bookmark_outline),
      title: Text(preset.name),
      subtitle: Text(
        preset.settings.contactText.isEmpty
            ? 'Logo only'
            : preset.settings.contactText,
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

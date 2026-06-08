import 'package:flutter/material.dart';
import 'package:soundswap/core/responsive/app_responsive.dart';
import 'package:soundswap/features/text_overlay/data/models/text_overlay_settings.dart';
import 'package:soundswap/features/text_overlay/presentation/state/text_overlay_controller.dart';
import 'package:soundswap/shared/widgets/feature_page.dart';

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
  final _titleFocus = FocusNode();
  final _subtitleFocus = FocusNode();
  final _promotionFocus = FocusNode();

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
    _titleFocus.dispose();
    _subtitleFocus.dispose();
    _promotionFocus.dispose();
    super.dispose();
  }

  void _syncFromState() {
    if (_titleFocus.hasFocus ||
        _subtitleFocus.hasFocus ||
        _promotionFocus.hasFocus) {
      return;
    }
    final settings = widget.controller.settings;
    _setTextIfChanged(_titleController, settings.title);
    _setTextIfChanged(_subtitleController, settings.subtitle);
    _setTextIfChanged(_promotionController, settings.promotionText);
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
              'Save reusable title, subtitle, and promotion text for later drawtext generation.',
          children: [
            SettingsSection(
              title: 'Overlay copy',
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
                  onChanged: (value) => widget.controller.update(
                    settings.copyWith(subtitle: value),
                  ),
                ),
                _OverlayField(
                  label: 'Price / promotion text',
                  controller: _promotionController,
                  focusNode: _promotionFocus,
                  maxLines: 3,
                  onChanged: (value) => widget.controller.update(
                    settings.copyWith(promotionText: value),
                  ),
                ),
                SegmentedButton<TextOverlayPosition>(
                  segments: const [
                    ButtonSegment(
                      value: TextOverlayPosition.top,
                      label: Text('Top'),
                    ),
                    ButtonSegment(
                      value: TextOverlayPosition.center,
                      label: Text('Center'),
                    ),
                    ButtonSegment(
                      value: TextOverlayPosition.bottom,
                      label: Text('Bottom'),
                    ),
                  ],
                  selected: {settings.position},
                  onSelectionChanged: (selection) => widget.controller.update(
                    settings.copyWith(position: selection.first),
                  ),
                ),
              ],
            ),
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

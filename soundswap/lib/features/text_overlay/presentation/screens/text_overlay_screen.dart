import 'package:flutter/material.dart';
import 'package:soundswap/core/responsive/app_responsive.dart';
import 'package:soundswap/features/text_overlay/data/models/text_overlay_settings.dart';
import 'package:soundswap/features/text_overlay/presentation/state/text_overlay_controller.dart';
import 'package:soundswap/shared/widgets/feature_page.dart';

class TextOverlayScreen extends StatelessWidget {
  const TextOverlayScreen({required this.controller, super.key});

  final TextOverlayController controller;

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: controller,
      builder: (context, _) {
        final settings = controller.settings;
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
                  value: settings.title,
                  onChanged: (value) =>
                      controller.update(settings.copyWith(title: value)),
                ),
                _OverlayField(
                  label: 'Subtitle',
                  value: settings.subtitle,
                  onChanged: (value) =>
                      controller.update(settings.copyWith(subtitle: value)),
                ),
                _OverlayField(
                  label: 'Price / promotion text',
                  value: settings.promotionText,
                  onChanged: (value) => controller.update(
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
                  onSelectionChanged: (selection) => controller.update(
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
    required this.value,
    required this.onChanged,
  });

  final String label;
  final String value;
  final ValueChanged<String> onChanged;

  @override
  Widget build(BuildContext context) {
    return TextFormField(
      key: ValueKey('$label$value'),
      initialValue: value,
      onChanged: onChanged,
      decoration: InputDecoration(labelText: label),
      style: TextStyle(fontSize: AppResponsive.bodySize(context)),
    );
  }
}

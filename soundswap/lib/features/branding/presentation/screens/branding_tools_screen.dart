import 'package:flutter/material.dart';
import 'package:soundswap/core/responsive/app_responsive.dart';
import 'package:soundswap/features/branding/presentation/state/branding_controller.dart';
import 'package:soundswap/shared/widgets/feature_page.dart';

class BrandingToolsScreen extends StatelessWidget {
  const BrandingToolsScreen({required this.controller, super.key});

  final BrandingController controller;

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: controller,
      builder: (context, _) {
        final settings = controller.settings;
        return FeaturePage(
          title: 'Branding Tools',
          subtitle:
              'Prepare logo and contact overlays for future FFmpeg branding workflows.',
          children: [
            SettingsSection(
              title: 'Logo and contact details',
              icon: Icons.branding_watermark_outlined,
              children: [
                OutlinedButton.icon(
                  onPressed: controller.pickLogo,
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
                  value: settings.phoneNumber,
                  onChanged: (value) =>
                      controller.update(settings.copyWith(phoneNumber: value)),
                ),
                _BrandingField(
                  label: 'Telegram',
                  value: settings.telegram,
                  onChanged: (value) =>
                      controller.update(settings.copyWith(telegram: value)),
                ),
                _BrandingField(
                  label: 'Facebook page name',
                  value: settings.facebookPage,
                  onChanged: (value) =>
                      controller.update(settings.copyWith(facebookPage: value)),
                ),
              ],
            ),
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
}

class _BrandingField extends StatelessWidget {
  const _BrandingField({
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

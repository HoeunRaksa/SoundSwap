import 'package:flutter/material.dart';
import 'package:soundswap/core/responsive/app_responsive.dart';
import 'package:soundswap/features/branding/presentation/state/branding_controller.dart';
import 'package:soundswap/shared/widgets/feature_page.dart';

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
  final _phoneFocus = FocusNode();
  final _telegramFocus = FocusNode();
  final _facebookFocus = FocusNode();

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
    _phoneFocus.dispose();
    _telegramFocus.dispose();
    _facebookFocus.dispose();
    super.dispose();
  }

  void _syncFromState() {
    if (_phoneFocus.hasFocus ||
        _telegramFocus.hasFocus ||
        _facebookFocus.hasFocus) {
      return;
    }
    final settings = widget.controller.settings;
    _setTextIfChanged(_phoneController, settings.phoneNumber);
    _setTextIfChanged(_telegramController, settings.telegram);
    _setTextIfChanged(_facebookController, settings.facebookPage);
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
              'Prepare logo and contact overlays for future FFmpeg branding workflows.',
          children: [
            SettingsSection(
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
                  onChanged: (value) => widget.controller.update(
                    settings.copyWith(phoneNumber: value),
                  ),
                ),
                _BrandingField(
                  label: 'Telegram',
                  controller: _telegramController,
                  focusNode: _telegramFocus,
                  onChanged: (value) => widget.controller.update(
                    settings.copyWith(telegram: value),
                  ),
                ),
                _BrandingField(
                  label: 'Facebook page name',
                  controller: _facebookController,
                  focusNode: _facebookFocus,
                  onChanged: (value) => widget.controller.update(
                    settings.copyWith(facebookPage: value),
                  ),
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

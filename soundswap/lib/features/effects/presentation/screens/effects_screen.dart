import 'package:flutter/material.dart';
import 'package:soundswap/core/responsive/app_responsive.dart';
import 'package:soundswap/features/effects/presentation/state/effects_controller.dart';
import 'package:soundswap/shared/widgets/feature_page.dart';

class EffectsScreen extends StatelessWidget {
  const EffectsScreen({required this.controller, super.key});

  final EffectsController controller;

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: controller,
      builder: (context, _) {
        final settings = controller.settings;
        return FeaturePage(
          title: 'Effects',
          subtitle:
              'Prepare optional FFmpeg effects. Defaults stay off and the batch flow is unchanged.',
          children: [
            SettingsSection(
              title: 'Effect toggles',
              icon: Icons.tune,
              children: [
                _EffectSwitch(
                  title: 'Random audio start',
                  value: settings.randomAudioStart,
                  onChanged: (value) => controller.update(
                    settings.copyWith(randomAudioStart: value),
                  ),
                ),
                _EffectSwitch(
                  title: 'Slight zoom',
                  value: settings.slightZoom,
                  onChanged: (value) =>
                      controller.update(settings.copyWith(slightZoom: value)),
                ),
                _EffectSwitch(
                  title: 'Brightness adjustment',
                  value: settings.brightnessAdjustment,
                  onChanged: (value) => controller.update(
                    settings.copyWith(brightnessAdjustment: value),
                  ),
                ),
                _EffectSwitch(
                  title: 'Speed variation',
                  value: settings.speedVariation,
                  onChanged: (value) => controller.update(
                    settings.copyWith(speedVariation: value),
                  ),
                ),
              ],
            ),
            SettingsSection(
              title: 'Prepared filter options',
              icon: Icons.terminal,
              children: [
                SelectableText(
                  settings.buildFilterPreview(),
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

class _EffectSwitch extends StatelessWidget {
  const _EffectSwitch({
    required this.title,
    required this.value,
    required this.onChanged,
  });

  final String title;
  final bool value;
  final ValueChanged<bool> onChanged;

  @override
  Widget build(BuildContext context) {
    return SwitchListTile(
      value: value,
      onChanged: onChanged,
      title: Text(
        title,
        style: TextStyle(fontSize: AppResponsive.bodySize(context)),
      ),
      contentPadding: EdgeInsets.zero,
    );
  }
}

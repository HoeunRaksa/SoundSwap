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
        final colorScheme = Theme.of(context).colorScheme;
        final bodySize = AppResponsive.bodySize(context);

        return FeaturePage(
          title: 'Effects',
          subtitle:
              'Optional FFmpeg effects applied during batch export. All effects are off by default — enable only what you need.',
          children: [
            SettingsSection(
              title: 'Visual & Audio Effects',
              icon: Icons.auto_fix_high_outlined,
              children: [
                _EffectTile(
                  icon: Icons.shuffle_outlined,
                  title: 'Random audio start',
                  subtitle:
                      'Picks a random position in the audio track instead of always starting from 0:00.',
                  value: settings.randomAudioStart,
                  onChanged: (value) =>
                      controller.update(settings.copyWith(randomAudioStart: value)),
                ),
                _EffectTile(
                  icon: Icons.zoom_in_outlined,
                  title: 'Slight zoom',
                  subtitle:
                      'Applies a subtle Ken Burns zoom effect to add motion to static clips.',
                  value: settings.slightZoom,
                  onChanged: (value) =>
                      controller.update(settings.copyWith(slightZoom: value)),
                ),
                _EffectTile(
                  icon: Icons.brightness_6_outlined,
                  title: 'Brightness adjustment',
                  subtitle:
                      'Normalizes brightness across clips for consistent visual quality.',
                  value: settings.brightnessAdjustment,
                  onChanged: (value) => controller.update(
                    settings.copyWith(brightnessAdjustment: value),
                  ),
                ),
                _EffectTile(
                  icon: Icons.speed_outlined,
                  title: 'Speed variation',
                  subtitle:
                      'Slightly varies playback speed for a more natural, organic feel.',
                  value: settings.speedVariation,
                  onChanged: (value) => controller.update(
                    settings.copyWith(speedVariation: value),
                  ),
                ),
              ],
            ),
            SettingsSection(
              title: 'FFmpeg Filter Preview',
              icon: Icons.code_outlined,
              children: [
                Container(
                  padding: EdgeInsets.all(AppResponsive.cardGap(context)),
                  decoration: BoxDecoration(
                    color: colorScheme.surfaceContainerHighest,
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: colorScheme.outlineVariant),
                  ),
                  child: SelectableText(
                    settings.buildFilterPreview().isEmpty
                        ? '(no effects active)'
                        : settings.buildFilterPreview(),
                    style: TextStyle(
                      fontFamily: 'Consolas',
                      fontSize: bodySize - 1,
                      color: settings.buildFilterPreview().isEmpty
                          ? colorScheme.onSurfaceVariant
                          : colorScheme.primary,
                      height: 1.6,
                    ),
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

class _EffectTile extends StatelessWidget {
  const _EffectTile({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.value,
    required this.onChanged,
  });

  final IconData icon;
  final String title;
  final String subtitle;
  final bool value;
  final ValueChanged<bool> onChanged;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final bodySize = AppResponsive.bodySize(context);

    return InkWell(
      onTap: () => onChanged(!value),
      borderRadius: BorderRadius.circular(8),
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 6, horizontal: 4),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            Container(
              width: 36,
              height: 36,
              decoration: BoxDecoration(
                color: value
                    ? colorScheme.primaryContainer
                    : colorScheme.surfaceContainerHighest,
                borderRadius: BorderRadius.circular(8),
              ),
              child: Icon(
                icon,
                size: 18,
                color: value
                    ? colorScheme.onPrimaryContainer
                    : colorScheme.onSurfaceVariant,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: TextStyle(
                      fontSize: bodySize,
                      fontWeight: FontWeight.w600,
                      color: colorScheme.onSurface,
                    ),
                  ),
                  Text(
                    subtitle,
                    style: TextStyle(
                      fontSize: bodySize - 2,
                      color: colorScheme.onSurfaceVariant,
                      height: 1.4,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(width: 12),
            Switch(
              value: value,
              onChanged: onChanged,
            ),
          ],
        ),
      ),
    );
  }
}

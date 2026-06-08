import 'package:flutter/material.dart';
import 'package:soundswap/core/responsive/app_responsive.dart';

class FeaturePage extends StatelessWidget {
  const FeaturePage({
    required this.title,
    required this.subtitle,
    required this.children,
    super.key,
  });

  final String title;
  final String subtitle;
  final List<Widget> children;

  @override
  Widget build(BuildContext context) {
    final gap = AppResponsive.cardGap(context);

    return ResponsiveCenter(
      child: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(
              title,
              style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                fontSize: AppResponsive.titleSize(context),
                fontWeight: FontWeight.bold,
              ),
            ),
            SizedBox(height: gap / 2),
            Text(
              subtitle,
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                color: Theme.of(context).colorScheme.onSurfaceVariant,
                fontSize: AppResponsive.bodySize(context),
              ),
            ),
            SizedBox(height: gap),
            ...children.expand((child) => [child, SizedBox(height: gap)]),
          ],
        ),
      ),
    );
  }
}

class SettingsSection extends StatelessWidget {
  const SettingsSection({
    required this.title,
    required this.children,
    this.icon,
    super.key,
  });

  final String title;
  final IconData? icon;
  final List<Widget> children;

  @override
  Widget build(BuildContext context) {
    final gap = AppResponsive.cardGap(context);
    final colorScheme = Theme.of(context).colorScheme;

    return Card(
      child: Padding(
        padding: EdgeInsets.all(gap),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Row(
              children: [
                if (icon != null) ...[
                  Icon(
                    icon,
                    color: colorScheme.primary,
                    size: AppResponsive.iconSize(context),
                  ),
                  SizedBox(width: gap / 2),
                ],
                Text(
                  title,
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    fontSize: AppResponsive.bodySize(context) + 2,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ],
            ),
            SizedBox(height: gap),
            ...children.expand((child) => [child, SizedBox(height: gap / 2)]),
          ],
        ),
      ),
    );
  }
}

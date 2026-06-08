import 'package:flutter/material.dart';
import 'package:soundswap/core/responsive/app_responsive.dart';

class MetricCard extends StatelessWidget {
  const MetricCard({
    required this.label,
    required this.value,
    required this.icon,
    super.key,
  });

  final String label;
  final String value;
  final IconData icon;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final gap = AppResponsive.cardGap(context) * 0.75;

    return Card(
      child: Padding(
        padding: EdgeInsets.all(gap),
        child: Row(
          children: [
            Icon(
              icon,
              size: AppResponsive.iconSize(context),
              color: colorScheme.primary,
            ),
            SizedBox(width: gap),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    label,
                    style: Theme.of(context).textTheme.labelLarge?.copyWith(
                      color: colorScheme.onSurfaceVariant,
                      fontSize: AppResponsive.bodySize(context) - 1,
                    ),
                  ),
                  SizedBox(height: gap / 3),
                  Text(
                    value,
                    style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                      fontSize: AppResponsive.titleSize(context) - 9,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

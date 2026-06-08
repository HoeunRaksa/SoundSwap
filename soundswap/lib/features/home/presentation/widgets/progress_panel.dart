import 'package:flutter/material.dart';
import 'package:soundswap/core/responsive/app_responsive.dart';
import 'package:soundswap/features/home/presentation/state/home_controller.dart';

class ProgressPanel extends StatelessWidget {
  const ProgressPanel({required this.controller, super.key});

  final HomeController controller;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final total = controller.jobs.length;
    final current = total == 0 ? 0 : controller.currentIndex;
    final gap = AppResponsive.cardGap(context);

    if (total == 0) {
      return Card(
        child: Padding(
          padding: EdgeInsets.all(gap),
          child: Text(
            controller.statusMessage ?? 'Select folders to begin.',
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
              color: colorScheme.onSurfaceVariant,
              fontSize: AppResponsive.bodySize(context),
            ),
          ),
        ),
      );
    }

    return Card(
      child: Padding(
        padding: EdgeInsets.all(gap),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Expanded(
                  child: Text(
                    controller.statusMessage ?? 'Processing...',
                    style: Theme.of(context).textTheme.titleMedium?.copyWith(
                      fontSize: AppResponsive.bodySize(context) + 1,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
                Text(
                  '$current / $total',
                  style: Theme.of(context).textTheme.labelLarge?.copyWith(
                    color: colorScheme.onSurfaceVariant,
                    fontSize: AppResponsive.bodySize(context),
                  ),
                ),
              ],
            ),
            SizedBox(height: gap),
            LinearProgressIndicator(
              value: controller.isProcessing ? controller.progress : null,
              minHeight: 8,
              borderRadius: BorderRadius.circular(
                AppResponsive.cardRadius(context),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

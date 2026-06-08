import 'package:flutter/material.dart';
import 'package:soundswap/features/home/presentation/state/home_controller.dart';

class ProgressPanel extends StatelessWidget {
  const ProgressPanel({required this.controller, super.key});

  final HomeController controller;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final total = controller.jobs.length;
    final current = total == 0 ? 0 : controller.currentIndex;

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(18),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Expanded(
                  child: Text(
                    controller.statusMessage ?? 'Select folders to begin.',
                    style: Theme.of(context).textTheme.titleMedium,
                  ),
                ),
                Text(
                  '$current / $total',
                  style: Theme.of(context).textTheme.labelLarge?.copyWith(
                    color: colorScheme.onSurfaceVariant,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 14),
            LinearProgressIndicator(
              value: controller.isProcessing ? controller.progress : null,
              minHeight: 8,
              borderRadius: BorderRadius.circular(8),
            ),
            const SizedBox(height: 16),
            Row(
              children: [
                FilledButton.icon(
                  onPressed: controller.canStart
                      ? controller.startProcessing
                      : null,
                  icon: controller.isProcessing
                      ? const SizedBox(
                          width: 18,
                          height: 18,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        )
                      : const Icon(Icons.play_arrow),
                  label: Text(
                    controller.isProcessing ? 'Running' : 'Start Batch',
                  ),
                ),
                const SizedBox(width: 12),
                OutlinedButton.icon(
                  onPressed: controller.isProcessing || controller.isScanning
                      ? null
                      : controller.scanAndBuildQueue,
                  icon: const Icon(Icons.refresh),
                  label: const Text('Rescan'),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

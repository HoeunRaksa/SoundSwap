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
    final progressState = _BatchProgressState.fromController(controller);

    if (total == 0) {
      return Card(
        child: Padding(
          padding: EdgeInsets.all(gap),
          child: LayoutBuilder(
            builder: (context, constraints) {
              final message = Text(
                controller.statusMessage ?? 'Select folders to begin.',
                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  color: colorScheme.onSurfaceVariant,
                  fontSize: AppResponsive.bodySize(context),
                ),
              );
              if (constraints.maxWidth < 260) {
                return Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _ProgressStatusChip(state: progressState),
                    SizedBox(height: gap / 2),
                    message,
                  ],
                );
              }
              return Row(
                children: [
                  _ProgressStatusChip(state: progressState),
                  SizedBox(width: gap / 2),
                  Expanded(child: message),
                ],
              );
            },
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
                _ProgressStatusChip(state: progressState),
                SizedBox(width: gap / 2),
                Expanded(
                  child: Text(
                    progressState.message,
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
            if (controller.isProcessing)
              LinearProgressIndicator(
                value: controller.progress,
                minHeight: 8,
                color: Colors.green.shade700,
                backgroundColor: colorScheme.surfaceContainerHighest,
                borderRadius: BorderRadius.circular(
                  AppResponsive.cardRadius(context),
                ),
              )
            else
              Container(
                height: 8,
                decoration: BoxDecoration(
                  color: colorScheme.surfaceContainerHighest,
                  borderRadius: BorderRadius.circular(
                    AppResponsive.cardRadius(context),
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }
}

class _BatchProgressState {
  const _BatchProgressState({
    required this.label,
    required this.message,
    required this.color,
    required this.icon,
  });

  final String label;
  final String message;
  final Color color;
  final IconData icon;

  static _BatchProgressState fromController(HomeController controller) {
    if (controller.isProcessing) {
      return _BatchProgressState(
        label: 'Running',
        message: controller.statusMessage ?? 'Running batch...',
        color: Colors.green.shade700,
        icon: Icons.play_circle_fill,
      );
    }

    final total = controller.jobs.length;
    final finished = controller.successCount + controller.failedCount;
    if (total > 0 && finished == total && controller.failedCount > 0) {
      return _BatchProgressState(
        label: 'Failed',
        message:
            'Failed: ${controller.failedCount} failed, ${controller.successCount} completed.',
        color: Colors.red.shade700,
        icon: Icons.error,
      );
    }

    if (total > 0 && finished == total && controller.successCount == total) {
      return _BatchProgressState(
        label: 'Completed',
        message: 'Completed: $total videos exported.',
        color: Colors.green.shade700,
        icon: Icons.check_circle,
      );
    }

    return _BatchProgressState(
      label: 'Queue ready',
      message: total > 0
          ? 'Queue ready: $total videos queued.'
          : controller.statusMessage ?? 'Select folders to begin.',
      color: Colors.blue.shade700,
      icon: Icons.playlist_add_check_circle,
    );
  }
}

class _ProgressStatusChip extends StatelessWidget {
  const _ProgressStatusChip({required this.state});

  final _BatchProgressState state;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
      decoration: BoxDecoration(
        color: state.color.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(999),
        border: Border.all(color: state.color.withValues(alpha: 0.22)),
      ),
      child: FittedBox(
        fit: BoxFit.scaleDown,
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              state.icon,
              size: AppResponsive.iconSize(context) - 8,
              color: state.color,
            ),
            const SizedBox(width: 5),
            Text(
              state.label,
              style: TextStyle(
                color: state.color,
                fontSize: AppResponsive.bodySize(context) - 3,
                fontWeight: FontWeight.w800,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

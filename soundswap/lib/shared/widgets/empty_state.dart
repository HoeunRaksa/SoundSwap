import 'package:flutter/material.dart';
import 'package:soundswap/core/responsive/app_responsive.dart';

/// Professional empty state widget — shown when lists/panels have no content.
/// Inspired by Notion and Linear's empty state patterns.
class EmptyState extends StatelessWidget {
  const EmptyState({
    required this.icon,
    required this.title,
    required this.message,
    this.action,
    this.actionLabel,
    this.compact = false,
    super.key,
  });

  final IconData icon;
  final String title;
  final String message;

  /// Optional primary CTA button.
  final VoidCallback? action;
  final String? actionLabel;

  /// Compact mode for smaller containers.
  final bool compact;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final gap = AppResponsive.cardGap(context);
    final iconSize = compact
        ? AppResponsive.iconSize(context) + 8
        : AppResponsive.iconSize(context) + 20;

    return Center(
      child: ConstrainedBox(
        constraints: BoxConstraints(maxWidth: compact ? 320 : 420),
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // Icon container
              Container(
                width: iconSize + 24,
                height: iconSize + 24,
                decoration: BoxDecoration(
                  color: colorScheme.primaryContainer.withValues(alpha: 0.5),
                  shape: BoxShape.circle,
                ),
                child: Center(
                  child: Icon(
                    icon,
                    size: iconSize,
                    color: colorScheme.primary,
                  ),
                ),
              ),
              SizedBox(height: compact ? gap / 2 : gap),
              Text(
                title,
                textAlign: TextAlign.center,
                style: Theme.of(context).textTheme.titleMedium?.copyWith(
                      fontSize: compact
                          ? AppResponsive.bodySize(context)
                          : AppResponsive.bodySize(context) + 3,
                      fontWeight: FontWeight.w700,
                      letterSpacing: -0.2,
                    ),
              ),
              SizedBox(height: gap / 4),
              Text(
                message,
                textAlign: TextAlign.center,
                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                      color: colorScheme.onSurfaceVariant,
                      fontSize: compact
                          ? AppResponsive.bodySize(context) - 2
                          : AppResponsive.bodySize(context) - 1,
                      height: 1.5,
                    ),
              ),
              if (action != null && actionLabel != null) ...[
                SizedBox(height: gap),
                FilledButton.icon(
                  onPressed: action,
                  icon: const Icon(Icons.add),
                  label: Text(actionLabel!),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}

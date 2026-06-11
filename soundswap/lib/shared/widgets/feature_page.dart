import 'package:flutter/material.dart';
import 'package:soundswap/core/responsive/app_responsive.dart';

/// A polished, Notion/Raycast-inspired feature page scaffold.
/// Used by every feature screen for consistent structure.
class FeaturePage extends StatelessWidget {
  const FeaturePage({
    required this.title,
    required this.subtitle,
    required this.children,
    this.actions,
    super.key,
  });

  final String title;
  final String subtitle;
  final List<Widget> children;

  /// Optional trailing actions shown next to the page title.
  final List<Widget>? actions;

  @override
  Widget build(BuildContext context) {
    final gap = AppResponsive.cardGap(context);

    return ResponsiveCenter(
      child: SingleChildScrollView(
        padding: EdgeInsets.only(bottom: gap * 2),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // ── Page header ──────────────────────────────────────────────
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        title,
                        style: Theme.of(context)
                            .textTheme
                            .headlineMedium
                            ?.copyWith(
                              fontSize: AppResponsive.titleSize(context),
                              fontWeight: FontWeight.w800,
                              letterSpacing: -0.5,
                            ),
                      ),
                      SizedBox(height: gap / 4),
                      Text(
                        subtitle,
                        style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                              color: Theme.of(context)
                                  .colorScheme
                                  .onSurfaceVariant,
                              fontSize: AppResponsive.bodySize(context),
                              height: 1.4,
                            ),
                      ),
                    ],
                  ),
                ),
                if (actions != null) ...[
                  SizedBox(width: gap),
                  Wrap(
                    spacing: gap / 2,
                    children: actions!,
                  ),
                ],
              ],
            ),
            SizedBox(height: gap * 1.25),
            // ── Page content ─────────────────────────────────────────────
            ...children.expand((child) => [child, SizedBox(height: gap)]),
          ],
        ),
      ),
    );
  }
}

/// A card-based section used by all feature pages.
/// Replaces ad-hoc Card + Padding patterns with consistent styling.
class SettingsSection extends StatelessWidget {
  const SettingsSection({
    required this.title,
    required this.children,
    this.icon,
    this.trailing,
    this.padding,
    super.key,
  });

  final String title;
  final IconData? icon;
  final List<Widget> children;

  /// Optional widget placed at the end of the section header row.
  final Widget? trailing;

  /// Override inner padding. Defaults to cardGap on all sides.
  final EdgeInsetsGeometry? padding;

  @override
  Widget build(BuildContext context) {
    final gap = AppResponsive.cardGap(context);
    final colorScheme = Theme.of(context).colorScheme;

    return Card(
      child: Padding(
        padding: padding ?? EdgeInsets.all(gap),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Header
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
                Expanded(
                  child: Text(
                    title,
                    style: Theme.of(context).textTheme.titleMedium?.copyWith(
                          fontSize: AppResponsive.bodySize(context) + 1,
                          fontWeight: FontWeight.w700,
                          letterSpacing: -0.1,
                        ),
                  ),
                ),
                ?trailing,
              ],
            ),
            SizedBox(height: gap),
            // Children
            ...children.expand(
              (child) => [child, SizedBox(height: gap / 2)],
            ),
          ],
        ),
      ),
    );
  }
}

/// A compact info row used inside cards.
class InfoRow extends StatelessWidget {
  const InfoRow({
    required this.label,
    required this.value,
    this.icon,
    this.valueColor,
    super.key,
  });

  final String label;
  final String value;
  final IconData? icon;
  final Color? valueColor;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final bodySize = AppResponsive.bodySize(context);

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 2),
      child: Row(
        children: [
          if (icon != null) ...[
            Icon(icon, size: 14, color: colorScheme.onSurfaceVariant),
            const SizedBox(width: 6),
          ],
          Text(
            label,
            style: TextStyle(
              fontSize: bodySize - 2,
              color: colorScheme.onSurfaceVariant,
            ),
          ),
          const SizedBox(width: 6),
          Expanded(
            child: Text(
              value,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              textAlign: TextAlign.end,
              style: TextStyle(
                fontSize: bodySize - 2,
                fontWeight: FontWeight.w600,
                color: valueColor ?? colorScheme.onSurface,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

/// Status badge / chip — used throughout the app.
class StatusBadge extends StatelessWidget {
  const StatusBadge({
    required this.label,
    required this.color,
    this.icon,
    super.key,
  });

  final String label;
  final Color color;
  final IconData? icon;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.14),
        borderRadius: BorderRadius.circular(999),
        border: Border.all(color: color.withValues(alpha: 0.3), width: 0.8),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (icon != null) ...[
            Icon(icon, size: 10, color: color),
            const SizedBox(width: 4),
          ],
          Text(
            label,
            style: TextStyle(
              color: color,
              fontSize: 11,
              fontWeight: FontWeight.w700,
              letterSpacing: 0.2,
            ),
          ),
        ],
      ),
    );
  }
}

/// Inline warning / info / success banner.
class InlineBanner extends StatelessWidget {
  const InlineBanner({
    required this.message,
    required this.type,
    this.onDismiss,
    super.key,
  });

  final String message;
  final BannerType type;
  final VoidCallback? onDismiss;

  @override
  Widget build(BuildContext context) {
    final (color, icon) = switch (type) {
      BannerType.info => (Colors.blue.shade700, Icons.info_outline),
      BannerType.warning => (Colors.orange.shade700, Icons.warning_amber_rounded),
      BannerType.error => (Theme.of(context).colorScheme.error, Icons.error_outline),
      BannerType.success => (Colors.green.shade700, Icons.check_circle_outline),
    };

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: color.withValues(alpha: 0.3)),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, size: 16, color: color),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              message,
              style: TextStyle(
                fontSize: 12,
                color: color,
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
          if (onDismiss != null) ...[
            const SizedBox(width: 4),
            GestureDetector(
              onTap: onDismiss,
              child: Icon(Icons.close, size: 14, color: color),
            ),
          ],
        ],
      ),
    );
  }
}

enum BannerType { info, warning, error, success }

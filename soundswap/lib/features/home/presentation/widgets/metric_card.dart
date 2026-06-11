import 'package:flutter/material.dart';
import 'package:soundswap/core/responsive/app_responsive.dart';

/// Dashboard metric card — horizontal Row layout.
///
/// Overflow-safe by design:
/// - Fixed Row height driven by [mainAxisExtent] in the parent GridView.
/// - Label uses maxLines:1 + ellipsis.
/// - Value uses [FittedBox] so the large number auto-scales instead of
///   overflowing at any window size from 1280×720 up to 4K.
/// - No clipping used anywhere.
/// - Hover state animates card elevation + icon-color glow.
class MetricCard extends StatefulWidget {
  const MetricCard({
    required this.label,
    required this.value,
    required this.icon,
    this.iconColor,
    this.subLabel,
    this.trend,
    super.key,
  });

  final String label;
  final String value;
  final IconData icon;
  final Color? iconColor;
  final String? subLabel;
  final int? trend;

  @override
  State<MetricCard> createState() => _MetricCardState();
}

class _MetricCardState extends State<MetricCard> {
  bool _hovered = false;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final effectiveIconColor = widget.iconColor ?? colorScheme.primary;
    final bodySize = AppResponsive.bodySize(context);

    return MouseRegion(
      onEnter: (_) => setState(() => _hovered = true),
      onExit: (_) => setState(() => _hovered = false),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 160),
        curve: Curves.easeOut,
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(12),
          boxShadow: _hovered
              ? [
                  BoxShadow(
                    color: effectiveIconColor.withValues(alpha: 0.18),
                    blurRadius: 12,
                    offset: const Offset(0, 3),
                  ),
                ]
              : [],
        ),
        child: Card(
          elevation: _hovered ? 3 : 0,
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                // ── Icon container ──────────────────────────────────────────
                SizedBox(
                  width: 36,
                  height: 36,
                  child: DecoratedBox(
                    decoration: BoxDecoration(
                      color: effectiveIconColor.withValues(alpha: 0.12),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Icon(
                      widget.icon,
                      size: 17,
                      color: effectiveIconColor,
                    ),
                  ),
                ),
                const SizedBox(width: 10),

                // ── Label + Value ───────────────────────────────────────────
                Expanded(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      // Label — always single line
                      Text(
                        widget.label,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(
                          fontSize: bodySize - 2,
                          fontWeight: FontWeight.w500,
                          color: colorScheme.onSurfaceVariant,
                        ),
                      ),

                      // Value — FittedBox prevents overflow at any window size.
                      FittedBox(
                        fit: BoxFit.scaleDown,
                        alignment: Alignment.centerLeft,
                        child: Text(
                          widget.value,
                          maxLines: 1,
                          style: TextStyle(
                            fontSize: bodySize + 5,
                            fontWeight: FontWeight.w800,
                            color: colorScheme.onSurface,
                            letterSpacing: -0.5,
                            height: 1.2,
                          ),
                        ),
                      ),

                      if (widget.subLabel != null)
                        FittedBox(
                          fit: BoxFit.scaleDown,
                          alignment: Alignment.centerLeft,
                          child: Text(
                            widget.subLabel!,
                            maxLines: 1,
                            style: TextStyle(
                              fontSize: bodySize - 3,
                              color: colorScheme.onSurfaceVariant,
                            ),
                          ),
                        ),
                    ],
                  ),
                ),

                // ── Trend chip ──────────────────────────────────────────────
                if (widget.trend != null) ...[
                  const SizedBox(width: 6),
                  _TrendChip(trend: widget.trend!),
                ],
              ],
            ),
          ),
        ),
      ),
    );
  }
}

// ── Trend chip ──────────────────────────────────────────────────────────────

class _TrendChip extends StatelessWidget {
  const _TrendChip({required this.trend});
  final int trend;

  @override
  Widget build(BuildContext context) {
    final isUp = trend > 0;
    final isNeutral = trend == 0;
    final color = isNeutral
        ? Colors.grey
        : isUp
            ? Colors.green.shade700
            : Colors.red.shade700;
    final icon = isNeutral
        ? Icons.remove
        : isUp
            ? Icons.trending_up
            : Icons.trending_down;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 2),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(6),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 11, color: color),
          const SizedBox(width: 2),
          Text(
            isNeutral ? '—' : '${trend.abs()}',
            style: TextStyle(
              fontSize: 10,
              fontWeight: FontWeight.w700,
              color: color,
            ),
          ),
        ],
      ),
    );
  }
}

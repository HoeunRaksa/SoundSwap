import 'package:flutter/material.dart';
import 'package:soundswap/core/responsive/app_responsive.dart';

class EmptyState extends StatelessWidget {
  const EmptyState({
    required this.icon,
    required this.title,
    required this.message,
    super.key,
  });

  final IconData icon;
  final String title;
  final String message;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final gap = AppResponsive.cardGap(context);

    return Center(
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 420),
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                icon,
                size: AppResponsive.iconSize(context),
                color: colorScheme.primary,
              ),
              SizedBox(height: gap / 2),
              Text(
                title,
                style: Theme.of(context).textTheme.titleLarge?.copyWith(
                  fontSize: AppResponsive.bodySize(context) + 2,
                ),
              ),
              SizedBox(height: gap / 3),
              Text(
                message,
                textAlign: TextAlign.center,
                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  color: colorScheme.onSurfaceVariant,
                  fontSize: AppResponsive.bodySize(context) - 1,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

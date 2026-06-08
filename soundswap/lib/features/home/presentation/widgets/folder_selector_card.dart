import 'package:flutter/material.dart';
import 'package:soundswap/core/responsive/app_responsive.dart';

class FolderSelectorCard extends StatelessWidget {
  const FolderSelectorCard({
    required this.title,
    required this.path,
    required this.icon,
    required this.onPressed,
    super.key,
  });

  final String title;
  final String? path;
  final IconData icon;
  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    final gap = AppResponsive.cardGap(context);
    final iconBoxSize = AppResponsive.iconSize(context) * 2;

    return Card(
      child: Padding(
        padding: EdgeInsets.all(gap),
        child: AppResponsive.isSmall(context)
            ? Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  _FolderInfo(
                    title: title,
                    path: path,
                    icon: icon,
                    iconBoxSize: iconBoxSize,
                  ),
                  SizedBox(height: gap),
                  _BrowseButton(onPressed: onPressed),
                ],
              )
            : Row(
                children: [
                  Expanded(
                    child: _FolderInfo(
                      title: title,
                      path: path,
                      icon: icon,
                      iconBoxSize: iconBoxSize,
                    ),
                  ),
                  SizedBox(width: gap),
                  _BrowseButton(onPressed: onPressed),
                ],
              ),
      ),
    );
  }
}

class _FolderInfo extends StatelessWidget {
  const _FolderInfo({
    required this.title,
    required this.path,
    required this.icon,
    required this.iconBoxSize,
  });

  final String title;
  final String? path;
  final IconData icon;
  final double iconBoxSize;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final gap = AppResponsive.cardGap(context);

    return Row(
      children: [
        Container(
          width: iconBoxSize,
          height: iconBoxSize,
          decoration: BoxDecoration(
            color: colorScheme.primaryContainer,
            borderRadius: BorderRadius.circular(
              AppResponsive.cardRadius(context),
            ),
          ),
          child: Icon(
            icon,
            size: AppResponsive.iconSize(context),
            color: colorScheme.onPrimaryContainer,
          ),
        ),
        SizedBox(width: gap),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                style: Theme.of(context).textTheme.titleSmall?.copyWith(
                  fontSize: AppResponsive.bodySize(context) + 1,
                ),
              ),
              SizedBox(height: gap / 3),
              Text(
                path ?? 'Not selected',
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                  color: colorScheme.onSurfaceVariant,
                  fontSize: AppResponsive.bodySize(context) - 1,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

class _BrowseButton extends StatelessWidget {
  const _BrowseButton({required this.onPressed});

  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: AppResponsive.buttonHeight(context),
      child: OutlinedButton.icon(
        onPressed: onPressed,
        icon: Icon(Icons.folder_open, size: AppResponsive.iconSize(context)),
        label: Text(
          'Browse',
          style: TextStyle(fontSize: AppResponsive.bodySize(context)),
        ),
      ),
    );
  }
}

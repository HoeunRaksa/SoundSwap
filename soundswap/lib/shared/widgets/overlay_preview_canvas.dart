import 'dart:io';

import 'package:flutter/material.dart';
import 'package:soundswap/core/responsive/app_responsive.dart';
import 'package:soundswap/core/video/video_output_settings.dart';

enum PreviewOverlayKind { logo, text }

class PreviewOverlayItem {
  const PreviewOverlayItem({
    required this.id,
    required this.label,
    required this.kind,
    required this.position,
    this.text,
    this.imagePath,
    this.colorHex = '#FFFFFF',
    this.fontSize = 42,
    this.width = 0.24,
    this.backgroundBox = false,
    this.shadow = false,
    this.selected = false,
  });

  final String id;
  final String label;
  final PreviewOverlayKind kind;
  final NormalizedPosition position;
  final String? text;
  final String? imagePath;
  final String colorHex;
  final double fontSize;
  final double width;
  final bool backgroundBox;
  final bool shadow;
  final bool selected;
}

class OverlayPreviewCanvas extends StatelessWidget {
  const OverlayPreviewCanvas({
    required this.outputSize,
    required this.items,
    required this.onPositionChanged,
    this.onSelected,
    this.onWidthChanged,
    super.key,
  });

  final VideoOutputSize outputSize;
  final List<PreviewOverlayItem> items;
  final void Function(String itemId, NormalizedPosition position)
  onPositionChanged;
  final ValueChanged<String>? onSelected;
  final void Function(String itemId, double width)? onWidthChanged;

  @override
  Widget build(BuildContext context) {
    final gap = AppResponsive.cardGap(context);
    final colorScheme = Theme.of(context).colorScheme;
    final aspectRatio = outputSize.previewWidth / outputSize.previewHeight;

    return LayoutBuilder(
      builder: (context, constraints) {
        final maxWidth = constraints.maxWidth.isFinite
            ? constraints.maxWidth
            : 360.0;
        final width = maxWidth.clamp(220.0, 420.0);

        return Column(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            Text(
              '${outputSize.previewWidth} x ${outputSize.previewHeight} preview',
              style: Theme.of(context).textTheme.labelMedium?.copyWith(
                color: colorScheme.onSurfaceVariant,
                fontSize: AppResponsive.bodySize(context) - 1,
              ),
            ),
            SizedBox(height: gap / 2),
            SizedBox(
              width: width,
              child: AspectRatio(
                aspectRatio: aspectRatio,
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(
                    AppResponsive.cardRadius(context),
                  ),
                  child: DecoratedBox(
                    decoration: BoxDecoration(
                      color: colorScheme.surfaceContainerHighest,
                      border: Border.all(color: colorScheme.outlineVariant),
                    ),
                    child: LayoutBuilder(
                      builder: (context, preview) {
                        return Stack(
                          children: [
                            Positioned.fill(
                              child: _PreviewFrame(outputSize: outputSize),
                            ),
                            for (final item in items)
                              _DraggablePreviewItem(
                                item: item,
                                size: preview.biggest,
                                onChanged: onPositionChanged,
                                onSelected: onSelected,
                                onWidthChanged: onWidthChanged,
                              ),
                          ],
                        );
                      },
                    ),
                  ),
                ),
              ),
            ),
          ],
        );
      },
    );
  }
}

class _PreviewFrame extends StatelessWidget {
  const _PreviewFrame({required this.outputSize});

  final VideoOutputSize outputSize;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return CustomPaint(
      painter: _RuleOfThirdsPainter(colorScheme.outlineVariant),
      child: Center(
        child: Icon(
          Icons.smart_display_outlined,
          size: AppResponsive.iconSize(context) * 2.4,
          color: colorScheme.onSurfaceVariant.withValues(alpha: 0.32),
        ),
      ),
    );
  }
}

class _DraggablePreviewItem extends StatelessWidget {
  const _DraggablePreviewItem({
    required this.item,
    required this.size,
    required this.onChanged,
    this.onSelected,
    this.onWidthChanged,
  });

  final PreviewOverlayItem item;
  final Size size;
  final void Function(String itemId, NormalizedPosition position) onChanged;
  final ValueChanged<String>? onSelected;
  final void Function(String itemId, double width)? onWidthChanged;

  @override
  Widget build(BuildContext context) {
    return Positioned(
      left: item.position.x * size.width,
      top: item.position.y * size.height,
      child: GestureDetector(
        onTap: () => onSelected?.call(item.id),
        onPanUpdate: (details) {
          final next = item.position.copyWith(
            x: item.position.x + details.delta.dx / size.width,
            y: item.position.y + details.delta.dy / size.height,
          );
          onChanged(item.id, next);
        },
        child: MouseRegion(
          cursor: SystemMouseCursors.move,
          child: Stack(
            clipBehavior: Clip.none,
            children: [
              _PreviewItemSurface(item: item, previewSize: size),
              if (item.selected) _SelectionFrame(item: item),
              if (item.selected && onWidthChanged != null)
                Positioned(
                  right: -10,
                  bottom: -10,
                  child: GestureDetector(
                    onPanUpdate: (details) {
                      final nextWidth =
                          item.width + details.delta.dx / size.width;
                      onWidthChanged!(
                        item.id,
                        nextWidth.clamp(0.08, 1).toDouble(),
                      );
                    },
                    child: const DecoratedBox(
                      decoration: BoxDecoration(
                        color: Colors.white,
                        shape: BoxShape.circle,
                        boxShadow: [
                          BoxShadow(blurRadius: 4, color: Colors.black26),
                        ],
                      ),
                      child: SizedBox(
                        width: 18,
                        height: 18,
                        child: Icon(Icons.open_in_full, size: 11),
                      ),
                    ),
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }
}

class _PreviewItemSurface extends StatelessWidget {
  const _PreviewItemSurface({required this.item, required this.previewSize});

  final PreviewOverlayItem item;
  final Size previewSize;

  @override
  Widget build(BuildContext context) {
    return switch (item.kind) {
      PreviewOverlayKind.logo => _LogoPreview(item: item, size: previewSize),
      PreviewOverlayKind.text => _TextPreview(item: item),
    };
  }
}

class _LogoPreview extends StatelessWidget {
  const _LogoPreview({required this.item, required this.size});

  final PreviewOverlayItem item;
  final Size size;

  @override
  Widget build(BuildContext context) {
    final logoWidth = size.width * 0.18;
    final previewWidth = size.width * item.width;
    final imagePath = item.imagePath;
    final imageFile = imagePath == null ? null : File(imagePath);

    return DecoratedBox(
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.88),
        borderRadius: BorderRadius.circular(6),
      ),
      child: SizedBox(
        width: previewWidth,
        height: previewWidth,
        child: imageFile != null && imageFile.existsSync()
            ? Image.file(imageFile, fit: BoxFit.contain)
            : Icon(
                Icons.image_outlined,
                size: logoWidth * 0.5,
                color: Theme.of(context).colorScheme.primary,
              ),
      ),
    );
  }
}

class _TextPreview extends StatelessWidget {
  const _TextPreview({required this.item});

  final PreviewOverlayItem item;

  @override
  Widget build(BuildContext context) {
    final text = (item.text == null || item.text!.trim().isEmpty)
        ? item.label
        : item.text!;
    final color = _colorFromHex(item.colorHex);
    final previewFontSize = (item.fontSize / 3.2).clamp(11.0, 28.0);

    return DecoratedBox(
      decoration: BoxDecoration(
        color: item.backgroundBox
            ? Colors.black.withValues(alpha: 0.48)
            : Colors.transparent,
        borderRadius: BorderRadius.circular(4),
      ),
      child: Padding(
        padding: EdgeInsets.symmetric(
          horizontal: item.backgroundBox ? 8 : 0,
          vertical: item.backgroundBox ? 5 : 0,
        ),
        child: Text(
          text,
          maxLines: 6,
          overflow: TextOverflow.ellipsis,
          style: TextStyle(
            color: color,
            fontSize: previewFontSize,
            fontWeight: FontWeight.w700,
            shadows: item.shadow
                ? const [
                    Shadow(
                      blurRadius: 3,
                      offset: Offset(1, 1),
                      color: Colors.black87,
                    ),
                  ]
                : null,
          ),
        ),
      ),
    );
  }
}

class _SelectionFrame extends StatelessWidget {
  const _SelectionFrame({required this.item});

  final PreviewOverlayItem item;

  @override
  Widget build(BuildContext context) {
    return Positioned.fill(
      child: IgnorePointer(
        child: DecoratedBox(
          decoration: BoxDecoration(
            border: Border.all(
              color: Theme.of(context).colorScheme.primary,
              width: 2,
            ),
            borderRadius: BorderRadius.circular(4),
          ),
        ),
      ),
    );
  }
}

class _RuleOfThirdsPainter extends CustomPainter {
  const _RuleOfThirdsPainter(this.color);

  final Color color;

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = color.withValues(alpha: 0.45)
      ..strokeWidth = 1;
    for (final fraction in [1 / 3, 2 / 3]) {
      canvas.drawLine(
        Offset(size.width * fraction, 0),
        Offset(size.width * fraction, size.height),
        paint,
      );
      canvas.drawLine(
        Offset(0, size.height * fraction),
        Offset(size.width, size.height * fraction),
        paint,
      );
    }
  }

  @override
  bool shouldRepaint(_RuleOfThirdsPainter oldDelegate) {
    return color != oldDelegate.color;
  }
}

Color _colorFromHex(String value) {
  final hex = value.replaceFirst('#', '').trim();
  if (hex.length != 6) return Colors.white;
  final parsed = int.tryParse('FF$hex', radix: 16);
  return parsed == null ? Colors.white : Color(parsed);
}

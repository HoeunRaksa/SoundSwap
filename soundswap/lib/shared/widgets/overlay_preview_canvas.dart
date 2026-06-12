import 'dart:io';
import 'package:flutter/material.dart';
import 'package:soundswap/core/responsive/app_responsive.dart';
import 'package:soundswap/core/video/video_output_settings.dart';
import 'package:soundswap/features/overlay_tools/utils/overlay_position_calculator.dart';

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
    this.customHeight,
    this.lockAspectRatio = true,
    this.backgroundBox = false,
    this.shadow = false,
    this.selected = false,
    this.opacity = 1.0,
    this.layerOrder = 0,
    this.textAlignment = 'left',
    this.imageFitMode = 'contain',
    this.rotation = 0.0,
    this.locked = false,
    this.hidden = false,
    this.folder,
    this.scaleX = 1.0,
    this.scaleY = 1.0,
    this.startTime = 0.0,
    this.endTime,
    this.animationEntrance,
    this.animationEntranceDuration = 0.5,
    this.animationExit,
    this.animationExitDuration = 0.5,
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
  final double? customHeight;
  final bool lockAspectRatio;
  final bool backgroundBox;
  final bool shadow;
  final bool selected;
  final double opacity;
  final int layerOrder;
  final String textAlignment;
  final String imageFitMode;
  final double rotation;
  final bool locked;
  final bool hidden;
  final String? folder;
  final double scaleX;
  final double scaleY;
  final double startTime;
  final double? endTime;
  final String? animationEntrance;
  final double animationEntranceDuration;
  final String? animationExit;
  final double animationExitDuration;
}

class OverlayPreviewCanvas extends StatefulWidget {
  const OverlayPreviewCanvas({
    required this.outputSize,
    required this.items,
    required this.onPositionChanged,
    this.onSelected,
    this.onWidthChanged,
    this.showGrid = false,
    this.safeAreaMode = 'none',
    this.enableSnapping = true,
    this.zoomScale = 1.0,
    this.currentTime = 0.0,
    this.selectedItemIds = const {},
    this.onMultiPositionChanged,
    this.onSizeChanged,
    super.key,
  });

  final VideoOutputSize outputSize;
  final List<PreviewOverlayItem> items;
  final void Function(String itemId, NormalizedPosition position) onPositionChanged;
  final ValueChanged<String>? onSelected;
  final void Function(String itemId, double width)? onWidthChanged;
  final bool showGrid;
  final String safeAreaMode;
  final bool enableSnapping;
  final double zoomScale;
  final double currentTime;
  final Set<String> selectedItemIds;
  final void Function(Map<String, NormalizedPosition> positions)? onMultiPositionChanged;
  final void Function(String itemId, double width, double? customHeight)? onSizeChanged;

  @override
  State<OverlayPreviewCanvas> createState() => _OverlayPreviewCanvasState();
}

class _OverlayPreviewCanvasState extends State<OverlayPreviewCanvas> {
  double? _snapLineX;
  double? _snapLineY;

  @override
  Widget build(BuildContext context) {
    final gap = AppResponsive.cardGap(context);
    final colorScheme = Theme.of(context).colorScheme;
    final aspectRatio = widget.outputSize.previewWidth / widget.outputSize.previewHeight;

    // Filter visible items by timing rules
    final visibleItems = widget.items.where((item) {
      if (item.hidden) return false;
      if (widget.currentTime < item.startTime) return false;
      if (item.endTime != null && widget.currentTime > item.endTime!) return false;
      return true;
    }).toList();

    return LayoutBuilder(
      builder: (context, constraints) {
        final maxWidth = constraints.maxWidth.isFinite ? constraints.maxWidth : 360.0;
        final baseWidth = maxWidth.clamp(220.0, 420.0);
        final width = baseWidth * widget.zoomScale;

        Widget canvasWidget = AspectRatio(
          aspectRatio: aspectRatio,
          child: ClipRRect(
            borderRadius: BorderRadius.circular(AppResponsive.cardRadius(context)),
            child: DecoratedBox(
              decoration: BoxDecoration(
                color: colorScheme.surfaceContainerHighest,
                border: Border.all(color: colorScheme.outlineVariant),
              ),
              child: LayoutBuilder(
                builder: (context, preview) {
                  final previewSize = preview.biggest;
                  return Stack(
                    clipBehavior: Clip.none,
                    children: [
                      // Checkerboard pattern behind the entire canvas
                      Positioned.fill(
                        child: CustomPaint(
                          painter: const _CheckerboardPainter(),
                        ),
                      ),
                      // Grid Lines
                      if (widget.showGrid)
                        Positioned.fill(
                          child: CustomPaint(
                            painter: const _GridPainter(enabled: true),
                          ),
                        ),
                      // Safe Area Guidelines
                      if (widget.safeAreaMode != 'none')
                        Positioned.fill(
                          child: CustomPaint(
                            painter: _SafeAreaPainter(mode: widget.safeAreaMode),
                          ),
                        ),
                      // Active Snapping Guides (X axis alignment)
                      if (_snapLineX != null)
                        Positioned(
                          left: _snapLineX! * previewSize.width,
                          top: 0,
                          bottom: 0,
                          child: Container(
                            width: 1.5,
                            color: Colors.red,
                          ),
                        ),
                      // Active Snapping Guides (Y axis alignment)
                      if (_snapLineY != null)
                        Positioned(
                          top: _snapLineY! * previewSize.height,
                          left: 0,
                          right: 0,
                          child: Container(
                            height: 1.5,
                            color: Colors.red,
                          ),
                        ),
                      // Draggable overlay items
                      for (final item in [...visibleItems]..sort((a, b) => a.layerOrder.compareTo(b.layerOrder)))
                        _DraggablePreviewItem(
                          item: item,
                          allItems: widget.items,
                          size: previewSize,
                          enableSnapping: widget.enableSnapping,
                          onChanged: widget.onPositionChanged,
                          onSelected: widget.onSelected,
                          onWidthChanged: widget.onWidthChanged,
                          onSizeChanged: widget.onSizeChanged,
                          selectedItemIds: widget.selectedItemIds,
                          onMultiPositionChanged: widget.onMultiPositionChanged,
                          currentTime: widget.currentTime,
                          onSnapChanged: (snapX, snapY) {
                            setState(() {
                              _snapLineX = snapX;
                              _snapLineY = snapY;
                            });
                          },
                        ),
                    ],
                  );
                },
              ),
            ),
          ),
        );

        return Column(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            Text(
              '${widget.outputSize.previewWidth} x ${widget.outputSize.previewHeight} preview (${(widget.zoomScale * 100).toInt()}%)',
              style: Theme.of(context).textTheme.labelMedium?.copyWith(
                color: colorScheme.onSurfaceVariant,
                fontSize: AppResponsive.bodySize(context) - 1,
              ),
            ),
            SizedBox(height: gap / 2),
            Container(
              height: 480,
              decoration: BoxDecoration(
                color: colorScheme.surfaceContainerLow,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: colorScheme.outlineVariant.withValues(alpha: 0.5)),
              ),
              child: SingleChildScrollView(
                scrollDirection: Axis.vertical,
                child: SingleChildScrollView(
                  scrollDirection: Axis.horizontal,
                  child: Padding(
                    padding: const EdgeInsets.all(24.0),
                    child: Center(
                      child: SizedBox(
                        width: width,
                        child: canvasWidget,
                      ),
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

class _DraggablePreviewItem extends StatelessWidget {
  const _DraggablePreviewItem({
    required this.item,
    required this.allItems,
    required this.size,
    required this.enableSnapping,
    required this.onChanged,
    this.onSelected,
    this.onWidthChanged,
    this.onSizeChanged,
    required this.selectedItemIds,
    this.onMultiPositionChanged,
    required this.currentTime,
    required this.onSnapChanged,
  });

  final PreviewOverlayItem item;
  final List<PreviewOverlayItem> allItems;
  final Size size;
  final bool enableSnapping;
  final void Function(String itemId, NormalizedPosition position) onChanged;
  final ValueChanged<String>? onSelected;
  final void Function(String itemId, double width)? onWidthChanged;
  final void Function(String itemId, double width, double? customHeight)? onSizeChanged;
  final Set<String> selectedItemIds;
  final void Function(Map<String, NormalizedPosition> positions)? onMultiPositionChanged;
  final double currentTime;
  final void Function(double? snapX, double? snapY) onSnapChanged;

  @override
  Widget build(BuildContext context) {
    final isSelected = item.selected || selectedItemIds.contains(item.id);

    // Calculate animation values
    double animationOpacity = 1.0;
    double animationOffsetX = 0.0;
    double animationOffsetY = 0.0;

    // Entrance animation
    final timeIn = currentTime - item.startTime;
    if (timeIn >= 0 && timeIn < item.animationEntranceDuration && item.animationEntranceDuration > 0) {
      final t = timeIn / item.animationEntranceDuration;
      switch (item.animationEntrance) {
        case 'fade':
          animationOpacity = t;
          break;
        case 'slide_left':
          animationOffsetX = -100.0 * (1.0 - t);
          break;
        case 'slide_right':
          animationOffsetX = 100.0 * (1.0 - t);
          break;
        case 'slide_up':
          animationOffsetY = 100.0 * (1.0 - t);
          break;
        case 'slide_down':
          animationOffsetY = -100.0 * (1.0 - t);
          break;
      }
    }

    // Exit animation
    if (item.endTime != null) {
      final timeOut = item.endTime! - currentTime;
      if (timeOut >= 0 && timeOut < item.animationExitDuration && item.animationExitDuration > 0) {
        final t = timeOut / item.animationExitDuration;
        switch (item.animationExit) {
          case 'fade':
            animationOpacity *= t;
            break;
          case 'slide_left':
            animationOffsetX = -100.0 * (1.0 - t);
            break;
          case 'slide_right':
            animationOffsetX = 100.0 * (1.0 - t);
            break;
          case 'slide_up':
            animationOffsetY = 100.0 * (1.0 - t);
            break;
          case 'slide_down':
            animationOffsetY = -100.0 * (1.0 - t);
            break;
        }
      }
    }

    Widget content = Transform.rotate(
      angle: item.rotation * 3.141592653589793 / 180,
      child: Transform.scale(
        scaleX: item.scaleX,
        scaleY: item.scaleY,
        child: Opacity(
          opacity: item.opacity * animationOpacity,
          child: _PreviewItemSurface(item: item, previewSize: size),
        ),
      ),
    );

    final targetPos = OverlayPositionCalculator.previewPosition(
      videoRect: Rect.fromLTWH(0, 0, size.width, size.height),
      xPercent: item.position.xPercent,
      yPercent: item.position.yPercent,
    );

    return Positioned(
      left: targetPos.dx + animationOffsetX,
      top: targetPos.dy + animationOffsetY,
      child: Stack(
        clipBehavior: Clip.none,
        children: [
          // Drag-to-move trigger area (center content)
          GestureDetector(
            onTap: () {
              if (onSelected != null) {
                onSelected!(item.id);
              }
            },
            onPanUpdate: (details) {
              if (item.locked) return;

              final deltaX = details.delta.dx / size.width;
              final deltaY = details.delta.dy / size.height;

              // If multi-selected, drag all together
              if (selectedItemIds.contains(item.id) && selectedItemIds.length > 1 && onMultiPositionChanged != null) {
                final Map<String, NormalizedPosition> nextPositions = {};
                for (final selectedId in selectedItemIds) {
                  final sibling = allItems.firstWhere((e) => e.id == selectedId, orElse: () => item);
                  if (sibling.locked) continue;
                  nextPositions[selectedId] = NormalizedPosition(
                    xPercent: (sibling.position.xPercent + deltaX).clamp(0.0, 1.0),
                    yPercent: (sibling.position.yPercent + deltaY).clamp(0.0, 1.0),
                  );
                }
                onMultiPositionChanged!(nextPositions);
                return;
              }

              // Standard single item drag with snapping
              double nextX = item.position.xPercent + deltaX;
              double nextY = item.position.yPercent + deltaY;

              double? guideX;
              double? guideY;

              if (enableSnapping) {
                // Snap to centers/edges of other items or canvas borders
                final centerX = nextX + item.width / 2;
                if ((centerX - 0.5).abs() < 0.02) {
                  nextX = 0.5 - item.width / 2;
                  guideX = 0.5;
                } else if ((nextX - 0.08).abs() < 0.015) {
                  nextX = 0.08;
                  guideX = 0.08;
                } else if ((nextX + item.width - 0.92).abs() < 0.015) {
                  nextX = 0.92 - item.width;
                  guideX = 0.92;
                }

                // Match alignment with other items
                for (final other in allItems) {
                  if (other.id == item.id) continue;
                  // Horizontal snap
                  if ((nextX - other.position.xPercent).abs() < 0.015) {
                    nextX = other.position.xPercent;
                    guideX = nextX;
                  } else if ((nextX + item.width - (other.position.xPercent + other.width)).abs() < 0.015) {
                    nextX = other.position.xPercent + other.width - item.width;
                    guideX = nextX + item.width;
                  }
                }

                final computedHeight = item.lockAspectRatio
                    ? item.width
                    : (item.customHeight ?? item.width);
                final centerY = nextY + computedHeight / 2;

                if ((centerY - 0.5).abs() < 0.02) {
                  nextY = 0.5 - computedHeight / 2;
                  guideY = 0.5;
                } else if ((nextY - 0.08).abs() < 0.015) {
                  nextY = 0.08;
                  guideY = 0.08;
                } else if ((nextY + computedHeight - 0.78).abs() < 0.015) {
                  nextY = 0.78 - computedHeight;
                  guideY = 0.78;
                }

                // Vertical snap
                for (final other in allItems) {
                  if (other.id == item.id) continue;
                  final otherH = other.lockAspectRatio ? other.width : (other.customHeight ?? other.width);
                  if ((nextY - other.position.yPercent).abs() < 0.015) {
                    nextY = other.position.yPercent;
                    guideY = nextY;
                  } else if ((nextY + computedHeight - (other.position.yPercent + otherH)).abs() < 0.015) {
                    nextY = other.position.yPercent + otherH - computedHeight;
                    guideY = nextY + computedHeight;
                  }
                }
              }

              onChanged(item.id, NormalizedPosition(xPercent: nextX, yPercent: nextY));
              onSnapChanged(guideX, guideY);
            },
            onPanEnd: (_) => onSnapChanged(null, null),
            child: MouseRegion(
              cursor: item.locked ? SystemMouseCursors.basic : SystemMouseCursors.move,
              child: content,
            ),
          ),
          // Selection handles (rendered on top of surface)
          if (isSelected)
            Positioned.fill(
              child: _SelectionHandlesFrame(
                locked: item.locked,
                onResize: (dx, dy, left, right, top, bottom) {
                  if (item.locked) return;

                  double nextX = item.position.xPercent;
                  double nextY = item.position.yPercent;
                  double nextW = item.width;
                  double nextH = item.customHeight ?? item.width;

                  final changeX = dx / size.width;
                  final changeY = dy / size.height;

                  if (left) {
                    final oldMaxX = nextX + nextW;
                    nextX = (nextX + changeX).clamp(0.0, oldMaxX - 0.05);
                    nextW = oldMaxX - nextX;
                  }
                  if (right) {
                    nextW = (nextW + changeX).clamp(0.05, 1.0);
                  }
                  if (top) {
                    final oldMaxY = nextY + nextH;
                    nextY = (nextY + changeY).clamp(0.0, oldMaxY - 0.05);
                    nextH = oldMaxY - nextY;
                  }
                  if (bottom) {
                    nextH = (nextH + changeY).clamp(0.05, 1.0);
                  }

                  if (onSizeChanged != null) {
                    onSizeChanged!(item.id, nextW, item.lockAspectRatio ? null : nextH);
                  } else if (onWidthChanged != null) {
                    onWidthChanged!(item.id, nextW);
                  }
                  onChanged(item.id, NormalizedPosition(xPercent: nextX, yPercent: nextY));
                },
              ),
            ),
        ],
      ),
    );
  }
}

class _SelectionHandlesFrame extends StatelessWidget {
  const _SelectionHandlesFrame({
    required this.locked,
    required this.onResize,
  });

  final bool locked;
  final void Function(double dx, double dy, bool left, bool right, bool top, bool bottom) onResize;

  @override
  Widget build(BuildContext context) {
    return Stack(
        clipBehavior: Clip.none,
        children: [
          // Orange Selection Border
          Positioned.fill(
            child: IgnorePointer(
              child: Container(
                decoration: BoxDecoration(
                  border: Border.all(
                    color: locked ? Colors.red : Colors.orange,
                    width: 2.0,
                  ),
                  borderRadius: BorderRadius.circular(4),
                ),
              ),
            ),
          ),
          if (!locked) ...[
            // 4 Corners
            _buildResizeHandle(Alignment.topLeft, true, false, true, false, SystemMouseCursors.resizeUpLeftDownRight),
            _buildResizeHandle(Alignment.topRight, false, true, true, false, SystemMouseCursors.resizeUpRightDownLeft),
            _buildResizeHandle(Alignment.bottomLeft, true, false, false, true, SystemMouseCursors.resizeUpRightDownLeft),
            _buildResizeHandle(Alignment.bottomRight, false, true, false, true, SystemMouseCursors.resizeUpLeftDownRight),
            // 4 Edges
            _buildResizeHandle(Alignment.centerLeft, true, false, false, false, SystemMouseCursors.resizeLeftRight),
            _buildResizeHandle(Alignment.centerRight, false, true, false, false, SystemMouseCursors.resizeLeftRight),
            _buildResizeHandle(Alignment.topCenter, false, false, true, false, SystemMouseCursors.resizeUpDown),
            _buildResizeHandle(Alignment.bottomCenter, false, false, false, true, SystemMouseCursors.resizeUpDown),
          ],
        ],
      );
  }

  Widget _buildResizeHandle(
    Alignment alignment,
    bool left,
    bool right,
    bool top,
    bool bottom,
    MouseCursor cursor,
  ) {
    return Align(
      alignment: alignment,
      child: GestureDetector(
        onPanUpdate: (details) {
          onResize(details.delta.dx, details.delta.dy, left, right, top, bottom);
        },
        child: MouseRegion(
          cursor: cursor,
          child: Container(
            width: 10,
            height: 10,
            decoration: BoxDecoration(
              color: Colors.white,
              border: Border.all(color: Colors.orange, width: 2),
              borderRadius: BorderRadius.circular(2),
              boxShadow: const [
                BoxShadow(blurRadius: 2, color: Colors.black26),
              ],
            ),
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
      PreviewOverlayKind.text => _TextPreview(item: item, previewSize: previewSize),
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

    return Container(
      width: previewWidth,
      decoration: BoxDecoration(
        border: Border.all(
          color: Colors.grey.withValues(alpha: 0.3),
          width: 1,
        ),
      ),
      child: imageFile != null && imageFile.existsSync()
          ? Stack(
              children: [
                Positioned.fill(
                  child: CustomPaint(
                    painter: const _CheckerboardPainter(),
                  ),
                ),
                Image.file(
                  imageFile,
                  fit: switch (item.imageFitMode) {
                    'cover' => BoxFit.cover,
                    'stretch' => BoxFit.fill,
                    _ => BoxFit.contain,
                  },
                ),
              ],
            )
          : AspectRatio(
              aspectRatio: 1.0,
              child: Stack(
                children: [
                  Positioned.fill(
                    child: CustomPaint(
                      painter: const _CheckerboardPainter(),
                    ),
                  ),
                  Center(
                    child: Icon(
                      Icons.image_outlined,
                      size: logoWidth * 0.5,
                      color: Theme.of(context).colorScheme.primary,
                    ),
                  ),
                ],
              ),
            ),
    );
  }
}

class _TextPreview extends StatelessWidget {
  const _TextPreview({required this.item, required this.previewSize});

  final PreviewOverlayItem item;
  final Size previewSize;

  @override
  Widget build(BuildContext context) {
    final text = (item.text == null || item.text!.trim().isEmpty) ? item.label : item.text!;
    final color = _colorFromHex(item.colorHex);

    const referenceHeight = 1920.0;
    final scale = previewSize.height / referenceHeight;
    final previewFontSize = (item.fontSize * scale).clamp(8.0, 120.0);
    final width = previewSize.width * item.width;

    return SizedBox(
      width: width,
      child: DecoratedBox(
        decoration: BoxDecoration(
          color: item.backgroundBox ? Colors.black.withValues(alpha: 0.48) : Colors.transparent,
          borderRadius: BorderRadius.circular(4),
        ),
        child: Padding(
          padding: EdgeInsets.symmetric(
            horizontal: item.backgroundBox ? 8 : 0,
            vertical: item.backgroundBox ? 5 : 0,
          ),
          child: Text(
            text,
            maxLines: 12,
            overflow: TextOverflow.ellipsis,
            textAlign: switch (item.textAlignment) {
              'center' => TextAlign.center,
              'right' => TextAlign.right,
              _ => TextAlign.left,
            },
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
      ),
    );
  }
}

class _CheckerboardPainter extends CustomPainter {
  const _CheckerboardPainter();

  static const double squareSize = 6.0;

  @override
  void paint(Canvas canvas, Size size) {
    final paintLight = Paint()..color = const Color(0xFFE0E0E0);
    final paintDark = Paint()..color = const Color(0xFFF5F5F5);

    for (double y = 0; y < size.height; y += squareSize) {
      for (double x = 0; x < size.width; x += squareSize) {
        final isDark = ((x / squareSize).floor() + (y / squareSize).floor()) % 2 == 0;
        final rect = Rect.fromLTWH(
          x,
          y,
          (size.width - x < squareSize) ? size.width - x : squareSize,
          (size.height - y < squareSize) ? size.height - y : squareSize,
        );
        canvas.drawRect(rect, isDark ? paintDark : paintLight);
      }
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

class _GridPainter extends CustomPainter {
  const _GridPainter({required this.enabled});

  final bool enabled;
  static const double gridSize = 24.0;

  @override
  void paint(Canvas canvas, Size size) {
    if (!enabled) return;

    final paint = Paint()
      ..color = Colors.grey.withValues(alpha: 0.25)
      ..strokeWidth = 0.5;

    for (double x = 0; x < size.width; x += gridSize) {
      canvas.drawLine(Offset(x, 0), Offset(x, size.height), paint);
    }
    for (double y = 0; y < size.height; y += gridSize) {
      canvas.drawLine(Offset(0, y), Offset(size.width, y), paint);
    }
  }

  @override
  bool shouldRepaint(covariant _GridPainter oldDelegate) => enabled != oldDelegate.enabled;
}

class _SafeAreaPainter extends CustomPainter {
  const _SafeAreaPainter({required this.mode});

  final String mode;

  @override
  void paint(Canvas canvas, Size size) {
    if (mode == 'none') return;

    final paintLine = Paint()
      ..color = Colors.red.withValues(alpha: 0.6)
      ..strokeWidth = 1.5
      ..style = PaintingStyle.stroke;

    final paintUnsafe = Paint()
      ..color = Colors.black.withValues(alpha: 0.15)
      ..style = PaintingStyle.fill;

    if (mode == 'tiktok') {
      canvas.drawRect(Rect.fromLTWH(0, 0, size.width, size.height * 0.10), paintUnsafe);
      canvas.drawRect(Rect.fromLTWH(0, size.height * 0.80, size.width, size.height * 0.20), paintUnsafe);
      canvas.drawRect(Rect.fromLTWH(size.width * 0.82, size.height * 0.10, size.width * 0.18, size.height * 0.70), paintUnsafe);

      canvas.drawRect(Rect.fromLTRB(0, size.height * 0.10, size.width * 0.82, size.height * 0.80), paintLine);
    } else if (mode == 'shorts') {
      canvas.drawRect(Rect.fromLTWH(0, 0, size.width, size.height * 0.12), paintUnsafe);
      canvas.drawRect(Rect.fromLTWH(0, size.height * 0.85, size.width, size.height * 0.15), paintUnsafe);
      canvas.drawRect(Rect.fromLTWH(size.width * 0.85, size.height * 0.12, size.width * 0.15, size.height * 0.73), paintUnsafe);

      canvas.drawRect(Rect.fromLTRB(0, size.height * 0.12, size.width * 0.85, size.height * 0.85), paintLine);
    } else if (mode == 'reels') {
      canvas.drawRect(Rect.fromLTWH(0, 0, size.width, size.height * 0.10), paintUnsafe);
      canvas.drawRect(Rect.fromLTWH(0, size.height * 0.80, size.width, size.height * 0.20), paintUnsafe);
      canvas.drawRect(Rect.fromLTWH(size.width * 0.85, size.height * 0.10, size.width * 0.15, size.height * 0.70), paintUnsafe);

      canvas.drawRect(Rect.fromLTRB(0, size.height * 0.10, size.width * 0.85, size.height * 0.80), paintLine);
    }
  }

  @override
  bool shouldRepaint(covariant _SafeAreaPainter oldDelegate) => mode != oldDelegate.mode;
}

Color _colorFromHex(String value) {
  final hex = value.replaceFirst('#', '').trim();
  if (hex.length != 6) return Colors.white;
  final parsed = int.tryParse('FF$hex', radix: 16);
  return parsed == null ? Colors.white : Color(parsed);
}

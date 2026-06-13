// ignore_for_file: avoid_print
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:soundswap/core/responsive/app_responsive.dart';
import 'package:soundswap/core/video/video_output_settings.dart';
import 'package:soundswap/features/overlay_tools/utils/overlay_position_calculator.dart';
import 'package:soundswap/features/overlay_tools/data/models/overlay_settings.dart';

enum PreviewOverlayKind { logo, text }

class PreviewOverlayItem {
  const PreviewOverlayItem({
    required this.id,
    required this.label,
    required this.kind,
    required this.position,
    this.text,
    this.imagePath,
    this.fontFamily = 'Battambang',
    this.bold = false,
    this.italic = false,
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
  final String fontFamily;
  final bool bold;
  final bool italic;
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
    this.safeAreaPadding,
    this.enableSnapping = true,
    this.zoomScale = 1.0,
    this.currentTime = 0.0,
    this.selectedItemIds = const {},
    this.onMultiPositionChanged,
    this.onSizeChanged,
    this.onHeightReported,
    this.onDragEnd,
    super.key,
  });

  final VideoOutputSize outputSize;
  final List<PreviewOverlayItem> items;
  final void Function(String itemId, NormalizedPosition position) onPositionChanged;
  final ValueChanged<String>? onSelected;
  final void Function(String itemId, double width)? onWidthChanged;
  final bool showGrid;
  final SafeAreaPadding? safeAreaPadding;
  final bool enableSnapping;
  final double zoomScale;
  final double currentTime;
  final Set<String> selectedItemIds;
  final void Function(Map<String, NormalizedPosition> positions)? onMultiPositionChanged;
  final void Function(String itemId, double width, double? customHeight)? onSizeChanged;
  final void Function(String itemId, double heightPercent)? onHeightReported;
  final VoidCallback? onDragEnd;

  @override
  State<OverlayPreviewCanvas> createState() => _OverlayPreviewCanvasState();
}

class _OverlayPreviewCanvasState extends State<OverlayPreviewCanvas> {
  double? _snapLineX;
  double? _snapLineY;
  final GlobalKey _canvasKey = GlobalKey();

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
                    key: _canvasKey,
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
                      if (widget.safeAreaPadding != null)
                        Positioned.fill(
                          child: CustomPaint(
                            painter: _SafeAreaPainter(padding: widget.safeAreaPadding!),
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
                          canvasKey: _canvasKey,
                          enableSnapping: widget.enableSnapping,
                          safeAreaPadding: widget.safeAreaPadding,
                          onChanged: widget.onPositionChanged,
                          onSelected: widget.onSelected,
                          onWidthChanged: widget.onWidthChanged,
                          onSizeChanged: widget.onSizeChanged,
                          onHeightReported: widget.onHeightReported,
                          selectedItemIds: widget.selectedItemIds,
                          onMultiPositionChanged: widget.onMultiPositionChanged,
                          currentTime: widget.currentTime,
                          onSnapChanged: (x, y) {
                            if (mounted) {
                              setState(() {
                                _snapLineX = x;
                                _snapLineY = y;
                              });
                            }
                          },
                          onDragEnd: widget.onDragEnd,
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

class _DraggablePreviewItem extends StatefulWidget {
  const _DraggablePreviewItem({
    required this.item,
    required this.allItems,
    required this.size,
    required this.canvasKey,
    required this.enableSnapping,
    this.safeAreaPadding,
    required this.onChanged,
    this.onSelected,
    this.onWidthChanged,
    this.onSizeChanged,
    this.onHeightReported,
    required this.selectedItemIds,
    this.onMultiPositionChanged,
    required this.currentTime,
    required this.onSnapChanged,
    this.onDragEnd,
  });

  final PreviewOverlayItem item;
  final List<PreviewOverlayItem> allItems;
  final Size size;
  final bool enableSnapping;
  final SafeAreaPadding? safeAreaPadding;
  final void Function(String itemId, NormalizedPosition position) onChanged;
  final ValueChanged<String>? onSelected;
  final void Function(String itemId, double width)? onWidthChanged;
  final void Function(String itemId, double width, double? customHeight)? onSizeChanged;
  final void Function(String itemId, double heightPercent)? onHeightReported;
  final Set<String> selectedItemIds;
  final void Function(Map<String, NormalizedPosition> positions)? onMultiPositionChanged;
  final double currentTime;
  final GlobalKey canvasKey;
  final void Function(double? snapX, double? snapY) onSnapChanged;
  final VoidCallback? onDragEnd;

  @override
  State<_DraggablePreviewItem> createState() => _DraggablePreviewItemState();
}

class _DraggablePreviewItemState extends State<_DraggablePreviewItem> {
  Offset? _grabOffset;
  NormalizedPosition? _startPosition;
  Map<String, NormalizedPosition>? _multiStartPositions;

  @override
  Widget build(BuildContext context) {
    final item = widget.item;
    final selectedItemIds = widget.selectedItemIds;
    final size = widget.size;
    final allItems = widget.allItems;
    final enableSnapping = widget.enableSnapping;
    final canvasKey = widget.canvasKey;
    final onSelected = widget.onSelected;
    final onChanged = widget.onChanged;
    final onMultiPositionChanged = widget.onMultiPositionChanged;
    final onSnapChanged = widget.onSnapChanged;
    final onHeightReported = widget.onHeightReported;
    final onDragEnd = widget.onDragEnd;
    final onSizeChanged = widget.onSizeChanged;
    final onWidthChanged = widget.onWidthChanged;
    final currentTime = widget.currentTime;

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
      child: _SizeReporter(
        onSize: (reportedSize) {
          if (onHeightReported != null) {
            onHeightReported(item.id, reportedSize.height / size.height);
          }
        },
        child: Stack(
          clipBehavior: Clip.none,
          children: [
          // Drag-to-move trigger area (center content)
          Builder(builder: (dragContext) {
            return GestureDetector(
              onTap: () {
              if (onSelected != null) {
                onSelected(item.id);
              }
            },
            onPanStart: (details) {
              if (item.locked) return;
              final box = canvasKey.currentContext?.findRenderObject() as RenderBox?;
              if (box == null) return;
              
              final pointerCanvasLocal = box.globalToLocal(details.globalPosition);
              final itemLeftPx = size.width * item.position.xPercent;
              final itemTopPx = size.height * item.position.yPercent;
              
              _grabOffset = Offset(
                pointerCanvasLocal.dx - itemLeftPx,
                pointerCanvasLocal.dy - itemTopPx,
              );
              _startPosition = item.position;

              if (selectedItemIds.contains(item.id) && selectedItemIds.length > 1) {
                _multiStartPositions = {};
                for (final id in selectedItemIds) {
                  final sibling = allItems.firstWhere((e) => e.id == id, orElse: () => item);
                  _multiStartPositions![id] = sibling.position;
                }
              }

              print('--- DRAG START ---');
              print('pointerCanvasX/Y: ${pointerCanvasLocal.dx}, ${pointerCanvasLocal.dy}');
              print('itemLeftPx/topPx: $itemLeftPx, $itemTopPx');
              print('grabOffsetX/Y: ${_grabOffset?.dx}, ${_grabOffset?.dy}');
            },
            onPanUpdate: (details) {
              if (item.locked || _grabOffset == null || _startPosition == null) return;

              final box = canvasKey.currentContext?.findRenderObject() as RenderBox?;
              if (box == null) return;
              
              final pointerCanvasLocal = box.globalToLocal(details.globalPosition);
              
              final newLeftPx = pointerCanvasLocal.dx - _grabOffset!.dx;
              final newTopPx = pointerCanvasLocal.dy - _grabOffset!.dy;
              
              final newXPercent = newLeftPx / size.width;
              final newYPercent = newTopPx / size.height;

              print('--- DRAG UPDATE ---');
              print('pointerCanvasX/Y: ${pointerCanvasLocal.dx}, ${pointerCanvasLocal.dy}');
              print('newLeftPx/newTopPx: $newLeftPx, $newTopPx');
              print('raw xPercent/yPercent: $newXPercent, $newYPercent');

              // If multi-selected, drag all together
              if (selectedItemIds.contains(item.id) && selectedItemIds.length > 1 && onMultiPositionChanged != null && _multiStartPositions != null) {
                final Map<String, NormalizedPosition> nextPositions = {};
                final deltaX = newXPercent - _startPosition!.xPercent;
                final deltaY = newYPercent - _startPosition!.yPercent;

                for (final selectedId in selectedItemIds) {
                  final sibling = allItems.firstWhere((e) => e.id == selectedId, orElse: () => item);
                  if (sibling.locked) continue;
                  final computedSiblingHeight = sibling.lockAspectRatio ? sibling.width : (sibling.customHeight ?? sibling.width);
                  final startPos = _multiStartPositions![selectedId] ?? sibling.position;
                  
                  nextPositions[selectedId] = NormalizedPosition(
                    xPercent: (startPos.xPercent + deltaX).clamp(0.0, 1.0 - sibling.width),
                    yPercent: (startPos.yPercent + deltaY).clamp(0.0, 1.0 - computedSiblingHeight),
                  );
                }
                onMultiPositionChanged(nextPositions);
                return;
              }

              // Standard single item drag with snapping
              double nextX = newXPercent;
              double nextY = newYPercent;

              double? guideX;
              double? guideY;

              final itemBox = dragContext.findRenderObject() as RenderBox?;
              final itemPixelHeight = itemBox?.size.height ?? 0.0;
              final heightPercent = itemPixelHeight > 0 
                  ? (itemPixelHeight / size.height) 
                  : (item.lockAspectRatio ? item.width : (item.customHeight ?? item.width));

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

                final centerY = nextY + heightPercent / 2;

                if ((centerY - 0.5).abs() < 0.02) {
                  nextY = 0.5 - heightPercent / 2;
                  guideY = 0.5;
                } else if ((nextY - 0.08).abs() < 0.015) {
                  nextY = 0.08;
                  guideY = 0.08;
                } else if ((nextY + heightPercent - 0.78).abs() < 0.015) {
                  nextY = 0.78 - heightPercent;
                  guideY = 0.78;
                }

                // Vertical snap
                for (final other in allItems) {
                  if (other.id == item.id) continue;
                  final otherH = other.lockAspectRatio ? other.width : (other.customHeight ?? other.width);
                  if ((nextY - other.position.yPercent).abs() < 0.015) {
                    nextY = other.position.yPercent;
                    guideY = nextY;
                  } else if ((nextY + heightPercent - (other.position.yPercent + otherH)).abs() < 0.015) {
                    nextY = other.position.yPercent + otherH - heightPercent;
                    guideY = nextY + heightPercent;
                  }
                }

                if (widget.safeAreaPadding != null) {
                  final sLeft = widget.safeAreaPadding!.left / 1080.0;
                  final sRight = 1.0 - (widget.safeAreaPadding!.right / 1080.0);
                  final sTop = widget.safeAreaPadding!.top / 1920.0;
                  final sBottom = 1.0 - (widget.safeAreaPadding!.bottom / 1920.0);

                  // Horizontal snap to safe area
                  if ((nextX - sLeft).abs() < 0.015) {
                    nextX = sLeft;
                    guideX = sLeft;
                  } else if ((nextX + item.width - sRight).abs() < 0.015) {
                    nextX = sRight - item.width;
                    guideX = sRight;
                  }

                  // Vertical snap to safe area
                  if ((nextY - sTop).abs() < 0.015) {
                    nextY = sTop;
                    guideY = sTop;
                  } else if ((nextY + heightPercent - sBottom).abs() < 0.015) {
                    nextY = sBottom - heightPercent;
                    guideY = sBottom;
                  }
                }
              }

              nextX = nextX.clamp(0.0, 1.0 - item.width);
              
              final maxYPercent = 1.0 - heightPercent;
              nextY = nextY.clamp(0.0, maxYPercent);

              print('--- DRAG CLAMP DEBUG ---');
              print('canvasHeight: ${size.height}');
              print('itemPixelHeight: $itemPixelHeight');
              print('heightPercent: $heightPercent');
              print('localCanvasY: ${pointerCanvasLocal.dy}');
              print('maxYPercent: $maxYPercent');
              print('yPercent after clamp: $nextY');

              onChanged(item.id, NormalizedPosition(xPercent: nextX, yPercent: nextY));
              onSnapChanged(guideX, guideY);
            },
            onPanEnd: (_) {
              _grabOffset = null;
              _startPosition = null;
              _multiStartPositions = null;
              onSnapChanged(null, null);
              if (onDragEnd != null) onDragEnd();
            },
            child: MouseRegion(
              cursor: item.locked ? SystemMouseCursors.basic : SystemMouseCursors.move,
              child: content,
            ),
          );
        }),
        // Selection handles (rendered on top of surface)
          if (isSelected)
            Positioned.fill(
              child: _SelectionHandlesFrame(
                locked: item.locked,
                onResize: (details, left, right, top, bottom) {
                  if (item.locked) return;

                  final box = canvasKey.currentContext?.findRenderObject() as RenderBox?;
                  if (box == null) return;
                  
                  final localCurrent = box.globalToLocal(details.globalPosition);
                  final localPrev = box.globalToLocal(details.globalPosition - details.delta);
                  final localDelta = localCurrent - localPrev;

                  final changeX = localDelta.dx / size.width;
                  final changeY = localDelta.dy / size.height;

                  double nextX = item.position.xPercent;
                  double nextY = item.position.yPercent;
                  double nextW = item.width;
                  double nextH = item.customHeight ?? item.width;

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

                  nextX = nextX.clamp(0.0, 1.0 - nextW);
                  nextY = nextY.clamp(0.0, 1.0 - (item.lockAspectRatio ? nextW : nextH));

                  if (onSizeChanged != null) {
                    onSizeChanged(item.id, nextW, item.lockAspectRatio ? null : nextH);
                  } else if (onWidthChanged != null) {
                    onWidthChanged(item.id, nextW);
                  }
                  
                  onChanged(item.id, NormalizedPosition(xPercent: nextX, yPercent: nextY));
                },
                onResizeEnd: () {
                  if (onDragEnd != null) onDragEnd();
                },
              ),
            ),
        ],
      ),
    ));
  }
}

class _SelectionHandlesFrame extends StatelessWidget {
  const _SelectionHandlesFrame({
    required this.locked,
    required this.onResize,
    this.onResizeEnd,
  });

  final bool locked;
  final void Function(DragUpdateDetails details, bool left, bool right, bool top, bool bottom) onResize;
  final VoidCallback? onResizeEnd;

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
          onResize(details, left, right, top, bottom);
        },
        onPanEnd: (_) {
          if (onResizeEnd != null) onResizeEnd!();
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
                  key: ValueKey('${item.id}-${item.imagePath}'),
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
    
    // Debug log for font applied to preview
    debugPrint('Preview Applied Font - Family: ${item.fontFamily}, Bold: ${item.bold}, Italic: ${item.italic}');

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
              fontFamily: item.fontFamily,
              fontFamilyFallback: const ['Battambang'],
              fontWeight: item.bold ? FontWeight.w700 : FontWeight.normal,
              fontStyle: item.italic ? FontStyle.italic : FontStyle.normal,
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
  const _SafeAreaPainter({required this.padding});

  final SafeAreaPadding padding;

  @override
  void paint(Canvas canvas, Size size) {
    final paintLine = Paint()
      ..color = Colors.red.withValues(alpha: 0.6)
      ..strokeWidth = 1.5
      ..style = PaintingStyle.stroke;

    final paintUnsafe = Paint()
      ..color = Colors.black.withValues(alpha: 0.15)
      ..style = PaintingStyle.fill;

    final textPainter = TextPainter(
      text: const TextSpan(
        text: 'Safe area',
        style: TextStyle(
          color: Colors.red,
          fontSize: 10,
          fontWeight: FontWeight.bold,
        ),
      ),
      textDirection: TextDirection.ltr,
    );
    textPainter.layout();

    final safeLeft = size.width * (padding.left / 1080.0);
    final safeRight = size.width * (1.0 - padding.right / 1080.0);
    final safeTop = size.height * (padding.top / 1920.0);
    final safeBottom = size.height * (1.0 - padding.bottom / 1920.0);

    // Draw Unsafe Area Shading
    // Top
    canvas.drawRect(Rect.fromLTRB(0, 0, size.width, safeTop), paintUnsafe);
    // Bottom
    canvas.drawRect(Rect.fromLTRB(0, safeBottom, size.width, size.height), paintUnsafe);
    // Left (between top and bottom)
    canvas.drawRect(Rect.fromLTRB(0, safeTop, safeLeft, safeBottom), paintUnsafe);
    // Right (between top and bottom)
    canvas.drawRect(Rect.fromLTRB(safeRight, safeTop, size.width, safeBottom), paintUnsafe);

    // Draw Safe Area Outline (dashed would require custom math, using solid for now or a dashed path)
    final path = Path()..addRect(Rect.fromLTRB(safeLeft, safeTop, safeRight, safeBottom));
    
    // Draw solid line
    canvas.drawPath(path, paintLine);

    // Draw label near top right of the safe area
    textPainter.paint(
      canvas,
      Offset(safeRight - textPainter.width - 4, safeTop + 4),
    );
  }

  @override
  bool shouldRepaint(covariant _SafeAreaPainter oldDelegate) {
    return padding.top != oldDelegate.padding.top ||
           padding.bottom != oldDelegate.padding.bottom ||
           padding.left != oldDelegate.padding.left ||
           padding.right != oldDelegate.padding.right;
  }
}

Color _colorFromHex(String value) {
  final hex = value.replaceFirst('#', '').trim();
  if (hex.length != 6) return Colors.white;
  final parsed = int.tryParse('FF$hex', radix: 16);
  return parsed == null ? Colors.white : Color(parsed);
}

class _SizeReporter extends StatefulWidget {
  final Widget child;
  final void Function(Size size) onSize;

  const _SizeReporter({required this.child, required this.onSize});

  @override
  State<_SizeReporter> createState() => _SizeReporterState();
}

class _SizeReporterState extends State<_SizeReporter> {
  Size? _oldSize;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback(_checkSize);
  }

  @override
  void didUpdateWidget(_SizeReporter oldWidget) {
    super.didUpdateWidget(oldWidget);
    WidgetsBinding.instance.addPostFrameCallback(_checkSize);
  }

  void _checkSize(_) {
    if (!mounted) return;
    final size = context.size;
    if (size != null && size != _oldSize) {
      _oldSize = size;
      widget.onSize(size);
    }
  }

  @override
  Widget build(BuildContext context) => widget.child;
}

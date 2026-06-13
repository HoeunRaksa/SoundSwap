import 'dart:io';

void main() {
  String content = File('lib/features/overlay_tools/presentation/screens/full_screen_editor_screen.dart').readAsStringSync();

  String oldBuildCanvas = '''
  Widget _buildCanvasArea(ColorScheme colorScheme, List<PreviewOverlayItem> items) {
    return GestureDetector(
      onDoubleTap: () => Navigator.of(context).pop(), // Double click toggles fullscreen
      child: Container(
        color: colorScheme.surfaceContainerHighest.withValues(alpha: 0.3),
        child: Center(
          child: SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: SingleChildScrollView(
              child: Padding(
                padding: const EdgeInsets.all(48.0),
                child: OverlayPreviewCanvas(
                  fillConstraints: true,
                  outputSize: widget.outputSize,
                  items: items,
                  zoomScale: _zoomScale,
                  showGrid: _showGrid,
                  enableSnapping: _enableSnapping,
                  safeAreaPadding: widget.controller.settings.showSafeAreaGuides ? widget.controller.settings.activeSafeArea : null,
                  selectedItemIds: widget.controller.selectedItemIds,
                  onSelected: widget.controller.selectItem,
                  onPositionChanged: (id, pos) => widget.controller.moveItem(id, pos, saveToDisk: false),
                  onWidthChanged: (id, w) => widget.controller.resizeItem(id, w, saveToDisk: false),
                  onDragEnd: () => widget.controller.saveSettingsToDisk(),
                  // Multi-select updates
                  onMultiPositionChanged: (positions) {
                    for (final entry in positions.entries) {
                      widget.controller.moveItem(entry.key, entry.value, saveToDisk: false);
                    }
                  },
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
''';

  String newBuildCanvas = '''
  Widget _buildCanvasArea(ColorScheme colorScheme, List<PreviewOverlayItem> items) {
    return GestureDetector(
      onDoubleTap: () => Navigator.of(context).pop(),
      child: Container(
        color: colorScheme.surfaceContainerHighest.withValues(alpha: 0.3),
        child: LayoutBuilder(
          builder: (context, constraints) {
            final availableWidth = constraints.maxWidth;
            final availableHeight = constraints.maxHeight;
            final aspectRatio = widget.outputSize.previewWidth / widget.outputSize.previewHeight;
            
            double computedScale = 1.0;
            
            if (_zoomScale == 0.0) {
               // Fit Screen
               final scaleW = (availableWidth - 64) / widget.outputSize.previewWidth;
               final scaleH = (availableHeight - 64) / widget.outputSize.previewHeight;
               computedScale = scaleW < scaleH ? scaleW : scaleH;
            } else if (_zoomScale == -1.0) {
               // Fit Height
               computedScale = (availableHeight - 64) / widget.outputSize.previewHeight;
            } else if (_zoomScale == -2.0) {
               // Fit Width
               computedScale = (availableWidth - 64) / widget.outputSize.previewWidth;
            } else {
               computedScale = _zoomScale;
            }
            
            // Clamp to avoid layout errors if screen is tiny
            computedScale = computedScale.clamp(0.01, 10.0);
            
            final canvasWidth = widget.outputSize.previewWidth * computedScale;
            final canvasHeight = widget.outputSize.previewHeight * computedScale;
            
            // Outer container takes available size. InteractiveViewer takes that size.
            // InteractiveViewer's child must be large enough to contain the canvas + padding.
            final scrollableWidth = availableWidth > canvasWidth + 64 ? availableWidth : canvasWidth + 64;
            final scrollableHeight = availableHeight > canvasHeight + 64 ? availableHeight : canvasHeight + 64;
            
            return InteractiveViewer(
              constrained: false, // allow panning if larger than viewport
              minScale: 1.0, // zoom is handled by our computedScale, so InteractiveViewer zoom is locked
              maxScale: 1.0, 
              child: Container(
                width: scrollableWidth,
                height: scrollableHeight,
                alignment: Alignment.center,
                child: SizedBox(
                  width: canvasWidth,
                  height: canvasHeight,
                  child: OverlayPreviewCanvas(
                    fillConstraints: true,
                    zoomScale: computedScale, // Pass computed absolute scale directly
                    outputSize: widget.outputSize,
                    items: items,
                    showGrid: _showGrid,
                    enableSnapping: _enableSnapping,
                    safeAreaPadding: widget.controller.settings.showSafeAreaGuides ? widget.controller.settings.activeSafeArea : null,
                    selectedItemIds: widget.controller.selectedItemIds,
                    onSelected: widget.controller.selectItem,
                    onPositionChanged: (id, pos) => widget.controller.moveItem(id, pos, saveToDisk: false),
                    onWidthChanged: (id, w) => widget.controller.resizeItem(id, w, saveToDisk: false),
                    onDragEnd: () => widget.controller.saveSettingsToDisk(),
                    onMultiPositionChanged: (positions) {
                      for (final entry in positions.entries) {
                        widget.controller.moveItem(entry.key, entry.value, saveToDisk: false);
                      }
                    },
                  ),
                ),
              ),
            );
          },
        ),
      ),
    );
  }
''';

  content = content.replaceFirst(oldBuildCanvas, newBuildCanvas);
  
  content = content.replaceFirst(
    "DropdownMenuItem(value: 0.0, child: Text('Fit Screen')),",
    "DropdownMenuItem(value: 0.0, child: Text('Fit Screen')),\n              DropdownMenuItem(value: -1.0, child: Text('Fit Height')),\n              DropdownMenuItem(value: -2.0, child: Text('Fit Width')),"
  );

  File('lib/features/overlay_tools/presentation/screens/full_screen_editor_screen.dart').writeAsStringSync(content);
  print('Patched full_screen_editor_screen.dart canvas scaling');
}

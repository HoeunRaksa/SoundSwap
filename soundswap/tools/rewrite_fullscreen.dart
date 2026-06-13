import 'dart:io';

void main() {
  String newContent = '''
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:soundswap/core/video/video_output_settings.dart';
import 'package:soundswap/features/overlay_tools/data/models/overlay_item.dart';
import 'package:soundswap/features/overlay_tools/presentation/state/overlay_tools_controller.dart';
import 'package:soundswap/shared/widgets/overlay_preview_canvas.dart';
import '../widgets/overlay_layers_panel.dart';
import '../widgets/overlay_properties_panel.dart';

class FullScreenEditorScreen extends StatefulWidget {
  const FullScreenEditorScreen({
    required this.controller,
    required this.outputSize,
    super.key,
  });

  final OverlayToolsController controller;
  final VideoOutputSize outputSize;

  @override
  State<FullScreenEditorScreen> createState() => _FullScreenEditorScreenState();
}

class _FullScreenEditorScreenState extends State<FullScreenEditorScreen> {
  bool _showGrid = false;
  bool _enableSnapping = true;
  double _zoomScale = 0.0; // Fit Screen

  bool _showLeftPanel = true;
  bool _showRightPanel = true;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return ListenableBuilder(
      listenable: widget.controller,
      builder: (context, _) {
        final items = [
          for (final item in widget.controller.settings.items)
            PreviewOverlayItem(
              id: item.id,
              label: item.name.isEmpty ? (item.type == OverlayItemType.image ? 'Image' : 'Text') : item.name,
              kind: item.type == OverlayItemType.image ? PreviewOverlayKind.logo : PreviewOverlayKind.text,
              position: item.position,
              text: item.text,
              imagePath: item.imagePath,
              fontFamily: item.fontFamily,
              bold: item.bold,
              italic: item.italic,
              colorHex: item.colorHex,
              fontSize: item.fontSize,
              width: item.width,
              customHeight: item.customHeight,
              lockAspectRatio: item.lockAspectRatio,
              backgroundBox: item.backgroundBox,
              shadow: item.shadow,
              selected: item.id == widget.controller.selectedItemId || widget.controller.selectedItemIds.contains(item.id),
              opacity: item.opacity,
              layerOrder: item.layerOrder,
              textAlignment: item.textAlignment,
              hidden: item.hidden,
              locked: item.locked,
              imageFitMode: item.imageFitMode,
            )
        ];

        return CallbackShortcuts(
          bindings: {
            const SingleActivator(LogicalKeyboardKey.escape): () => Navigator.of(context).pop(),
          },
          child: Focus(
            autofocus: true,
            child: Scaffold(
              body: Column(
                children: [
                  _buildToolbar(colorScheme),
                  const Divider(height: 1),
                  Expanded(
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        if (_showLeftPanel) 
                          SizedBox(
                            width: 280, 
                            child: Material(
                              color: colorScheme.surfaceContainerLow,
                              child: OverlayLayersPanel(controller: widget.controller),
                            ),
                          ),
                        Expanded(
                          child: _buildCanvasArea(colorScheme, items),
                        ),
                        if (_showRightPanel) 
                          SizedBox(
                            width: 320, 
                            child: Material(
                              color: colorScheme.surfaceContainerLow,
                              child: OverlayPropertiesPanel(controller: widget.controller),
                            ),
                          ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _buildToolbar(ColorScheme colorScheme) {
    return Container(
      color: colorScheme.surfaceContainer,
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: Row(
        children: [
          IconButton(
            tooltip: 'Exit Full Screen (ESC)',
            icon: const Icon(Icons.close),
            onPressed: () => Navigator.of(context).pop(),
          ),
          const SizedBox(width: 8),
          const Text(
            'Full Screen Editor',
            style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
          ),
          const SizedBox(width: 24),
          FilledButton.icon(
            onPressed: widget.controller.addText,
            icon: const Icon(Icons.text_fields),
            label: const Text('Add Text'),
          ),
          const SizedBox(width: 8),
          FilledButton.icon(
            onPressed: widget.controller.addImage,
            icon: const Icon(Icons.image_outlined),
            label: const Text('Add Image'),
          ),
          const SizedBox(width: 24),
          const SizedBox(height: 24, child: VerticalDivider(width: 1)),
          const SizedBox(width: 16),
          DropdownButton<double>(
            value: _zoomScale,
            underline: const SizedBox(),
            items: const [
              DropdownMenuItem(value: 0.0, child: Text('Fit Screen')),
              DropdownMenuItem(value: 0.5, child: Text('50%')),
              DropdownMenuItem(value: 1.0, child: Text('100%')),
              DropdownMenuItem(value: 1.5, child: Text('150%')),
              DropdownMenuItem(value: 2.0, child: Text('200%')),
              DropdownMenuItem(value: 3.0, child: Text('300%')),
            ],
            onChanged: (val) {
              if (val != null) setState(() => _zoomScale = val);
            },
          ),
          const SizedBox(width: 16),
          Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Checkbox(
                value: widget.controller.settings.showSafeAreaGuides,
                onChanged: (val) {
                  if (val != null) {
                    widget.controller.updateSettings(
                      widget.controller.settings.copyWith(showSafeAreaGuides: val),
                    );
                  }
                },
              ),
              const Text('Guides'),
              const SizedBox(width: 8),
              DropdownButton<String>(
                value: widget.controller.settings.safeAreaPreset,
                underline: const SizedBox(),
                items: const [
                  DropdownMenuItem(value: 'none', child: Text('None')),
                  DropdownMenuItem(value: 'facebook_reels', child: Text('FB Reels')),
                  DropdownMenuItem(value: 'tiktok', child: Text('TikTok')),
                  DropdownMenuItem(value: 'youtube_shorts', child: Text('YT Shorts')),
                  DropdownMenuItem(value: 'custom', child: Text('Custom')),
                ],
                onChanged: widget.controller.settings.showSafeAreaGuides ? (val) {
                  if (val != null) {
                    widget.controller.updateSettings(
                      widget.controller.settings.copyWith(safeAreaPreset: val),
                    );
                  }
                } : null,
              ),
            ],
          ),
          const SizedBox(width: 16),
          Checkbox(
            value: _showGrid,
            onChanged: (val) => setState(() => _showGrid = val ?? false),
          ),
          const Text('Grid'),
          const SizedBox(width: 16),
          Checkbox(
            value: _enableSnapping,
            onChanged: (val) => setState(() => _enableSnapping = val ?? true),
          ),
          const Text('Snap'),
          const Spacer(),
          // Panel Toggles
          ToggleButtons(
            isSelected: [_showLeftPanel, _showRightPanel],
            onPressed: (index) {
              setState(() {
                if (index == 0) _showLeftPanel = !_showLeftPanel;
                if (index == 1) _showRightPanel = !_showRightPanel;
              });
            },
            borderRadius: BorderRadius.circular(8),
            children: const [
              Tooltip(message: 'Toggle Layers Panel', child: Padding(padding: EdgeInsets.symmetric(horizontal: 12), child: Icon(Icons.layers))),
              Tooltip(message: 'Toggle Properties Panel', child: Padding(padding: EdgeInsets.symmetric(horizontal: 12), child: Icon(Icons.tune))),
            ],
          ),
        ],
      ),
    );
  }

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
}
''';
  File('lib/features/overlay_tools/presentation/screens/full_screen_editor_screen.dart').writeAsStringSync(newContent);
  print('Rewritten full_screen_editor_screen.dart');
}

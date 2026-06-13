import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:soundswap/core/video/video_output_settings.dart';
import 'package:soundswap/features/branding/presentation/state/branding_controller.dart';
import 'package:soundswap/features/home/presentation/state/home_controller.dart';
import 'package:soundswap/features/overlay_tools/data/models/overlay_item.dart';
import 'package:soundswap/features/overlay_tools/presentation/state/overlay_tools_controller.dart';
import 'package:soundswap/features/templates/presentation/state/templates_controller.dart';
import 'package:soundswap/features/text_overlay/presentation/state/text_overlay_controller.dart';
import 'package:soundswap/features/overlay_tools/utils/template_render_data.dart';
import 'package:soundswap/shared/widgets/overlay_preview_canvas.dart';

import '../widgets/overlay_layers_panel.dart';
import '../widgets/overlay_properties_panel.dart';

class FullScreenEditorScreen extends StatefulWidget {
  const FullScreenEditorScreen({
    required this.controller,
    required this.templatesController,
    required this.homeController,
    required this.brandingController,
    required this.textOverlayController,
    required this.outputSize,
    super.key,
  });

  final OverlayToolsController controller;
  final TemplatesController templatesController;
  final HomeController homeController;
  final BrandingController brandingController;
  final TextOverlayController textOverlayController;
  final VideoOutputSize outputSize;

  @override
  State<FullScreenEditorScreen> createState() => _FullScreenEditorScreenState();
}

class _FullScreenEditorScreenState extends State<FullScreenEditorScreen> {
  bool _showGrid = false;
  bool _enableSnapping = true;

  /// 0.0 = Fit Screen
  /// -1.0 = Fit Height
  /// -2.0 = Fit Width
  double _zoomScale = -1.0;

  bool _focusMode = false;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return ListenableBuilder(
      listenable: widget.controller,
      builder: (context, _) {
        final allItems = TemplateRenderData.buildItems(
          branding: widget.brandingController.settings,
          textOverlay: widget.textOverlayController.settings,
          overlaySettings: widget.controller.settings,
        );

        final items = allItems.map((item) {
          return PreviewOverlayItem(
            id: item.id,
            label: item.name.isEmpty
                ? (item.type == OverlayItemType.image ? 'Image' : 'Text')
                : item.name,
            kind: item.type == OverlayItemType.image
                ? PreviewOverlayKind.logo
                : PreviewOverlayKind.text,
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
            selected: item.id == widget.controller.selectedItemId ||
                widget.controller.selectedItemIds.contains(item.id),
            opacity: item.opacity,
            layerOrder: item.layerOrder,
            textAlignment: item.textAlignment,
            hidden: item.hidden,
            locked: item.locked,
            imageFitMode: item.imageFitMode,
            rotation: item.rotation,
            folder: item.folder,
            scaleX: item.scaleX,
            scaleY: item.scaleY,
            startTime: item.startTime,
            endTime: item.endTime,
            animationEntrance: item.animationEntrance,
            animationEntranceDuration: item.animationEntranceDuration,
            animationExit: item.animationExit,
            animationExitDuration: item.animationExitDuration,
            lineHeight: item.lineHeight,
            letterSpacing: item.letterSpacing,
            strokeWidth: item.strokeWidth,
            strokeColorHex: item.strokeColorHex,
          );
        }).toList();

        return CallbackShortcuts(
          bindings: {
            const SingleActivator(LogicalKeyboardKey.escape): () {
              Navigator.of(context).pop();
            },
            const SingleActivator(LogicalKeyboardKey.tab): () {
              final current =
                  widget.controller.settings.showFullScreenPropertiesPanel;
              widget.controller.updateSettings(
                widget.controller.settings.copyWith(
                  showFullScreenPropertiesPanel: !current,
                ),
              );
            },
          },
          child: Focus(
            autofocus: true,
            child: Scaffold(
              body: Column(
                children: [
                  if (!_focusMode) ...[
                    _buildToolbar(colorScheme),
                    const Divider(height: 1),
                  ],
                  Expanded(
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        if (!_focusMode &&
                            widget.controller.settings.showFullScreenLayersPanel)
                          SizedBox(
                            width: 280,
                            child: Material(
                              color: colorScheme.surfaceContainerLow,
                              child: OverlayLayersPanel(
                                controller: widget.controller,
                              ),
                            ),
                          ),
                        Expanded(
                          child: _buildCanvasArea(colorScheme, items),
                        ),
                        if (!_focusMode &&
                            widget.controller.settings
                                .showFullScreenPropertiesPanel)
                          SizedBox(
                            width: 320,
                            child: Material(
                              color: colorScheme.surfaceContainerLow,
                              child: OverlayPropertiesPanel(
                                controller: widget.controller,
                              ),
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

  Future<void> _handleSaveTemplate() async {
    final tCtrl = widget.templatesController;

    if (tCtrl.editingTemplateId != null) {
      await tCtrl.updateEditingTemplate(
        name: tCtrl.editingTemplateName ?? 'Untitled',
        home: widget.homeController,
        branding: widget.brandingController,
        textOverlay: widget.textOverlayController,
        overlay: widget.controller,
      );

      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Updated template: ${tCtrl.editingTemplateName}')),
      );
      return;
    }

    final textController = TextEditingController();

    final name = await showDialog<String>(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text('Save As New Template'),
          content: TextField(
            controller: textController,
            autofocus: true,
            decoration: const InputDecoration(labelText: 'Template name'),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Cancel'),
            ),
            FilledButton(
              onPressed: () => Navigator.pop(context, textController.text),
              child: const Text('Save'),
            ),
          ],
        );
      },
    );

    textController.dispose();

    if (name == null || name.trim().isEmpty) return;

    await tCtrl.saveCurrent(
      name: name.trim(),
      home: widget.homeController,
      branding: widget.brandingController,
      textOverlay: widget.textOverlayController,
      overlay: widget.controller,
    );

    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('Saved template: ${name.trim()}')),
    );
  }

  Future<void> _handleSaveAsNewTemplate() async {
    final tCtrl = widget.templatesController;
    final textController = TextEditingController(
      text: '${tCtrl.editingTemplateName ?? "Untitled"} (Copy)'
    );

    final name = await showDialog<String>(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text('Save As New Template'),
          content: TextField(
            controller: textController,
            autofocus: true,
            decoration: const InputDecoration(labelText: 'Template name'),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Cancel'),
            ),
            FilledButton(
              onPressed: () => Navigator.pop(context, textController.text),
              child: const Text('Save'),
            ),
          ],
        );
      },
    );

    textController.dispose();

    if (name == null || name.trim().isEmpty) return;

    await tCtrl.saveCurrent(
      name: name.trim(),
      home: widget.homeController,
      branding: widget.brandingController,
      textOverlay: widget.textOverlayController,
      overlay: widget.controller,
    );

    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('Saved as new template: ${name.trim()}')),
    );
  }

  Widget _buildToolbar(ColorScheme colorScheme) {
    return Container(
      color: colorScheme.surfaceContainer,
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: Wrap(
        spacing: 8,
        runSpacing: 8,
        crossAxisAlignment: WrapCrossAlignment.center,
        children: [
          IconButton(
            tooltip: 'Exit Full Screen (ESC)',
            icon: const Icon(Icons.close),
            onPressed: () => Navigator.of(context).pop(),
          ),
          IconButton(
            tooltip: widget.controller.settings.showFullScreenLayersPanel
                ? 'Collapse Layers Panel'
                : 'Expand Layers Panel',
            icon: Icon(
              widget.controller.settings.showFullScreenLayersPanel
                  ? Icons.keyboard_double_arrow_left
                  : Icons.keyboard_double_arrow_right,
            ),
            onPressed: () {
              widget.controller.updateSettings(
                widget.controller.settings.copyWith(
                  showFullScreenLayersPanel:
                  !widget.controller.settings.showFullScreenLayersPanel,
                ),
              );
            },
          ),
          ListenableBuilder(
            listenable: widget.templatesController,
            builder: (context, _) {
              final isEditing = widget.templatesController.editingTemplateId != null;
              final templateName = isEditing 
                  ? widget.templatesController.editingTemplateName ?? 'Untitled'
                  : 'New Template';
              return Text(
                templateName,
                style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                overflow: TextOverflow.ellipsis,
                maxLines: 1,
              );
            },
          ),
          const SizedBox(width: 8),
          ListenableBuilder(
            listenable: widget.templatesController,
            builder: (context, _) {
              final isEditing = widget.templatesController.editingTemplateId != null;
              return Wrap(
                spacing: 8,
                runSpacing: 8,
                children: [
                  FilledButton.icon(
                    onPressed: _handleSaveTemplate,
                    icon: const Icon(Icons.save, size: 18),
                    label: Text(isEditing ? 'Update' : 'Save'),
                    style: FilledButton.styleFrom(
                      minimumSize: const Size(0, 36),
                      padding: const EdgeInsets.symmetric(horizontal: 12),
                    ),
                  ),
                  if (isEditing)
                    OutlinedButton.icon(
                      onPressed: _handleSaveAsNewTemplate,
                      icon: const Icon(Icons.copy, size: 18),
                      label: const Text('Save As New'),
                      style: OutlinedButton.styleFrom(
                        minimumSize: const Size(0, 36),
                        padding: const EdgeInsets.symmetric(horizontal: 12),
                      ),
                    ),
                ],
              );
            },
          ),
          const SizedBox(width: 8),
          FilledButton.icon(
            onPressed: widget.controller.addText,
            icon: const Icon(Icons.text_fields, size: 18),
            label: const Text('Add Text'),
            style: FilledButton.styleFrom(
              minimumSize: const Size(0, 36),
              padding: const EdgeInsets.symmetric(horizontal: 12),
            ),
          ),
          FilledButton.icon(
            onPressed: widget.controller.addImage,
            icon: const Icon(Icons.image_outlined, size: 18),
            label: const Text('Add Image'),
            style: FilledButton.styleFrom(
              minimumSize: const Size(0, 36),
              padding: const EdgeInsets.symmetric(horizontal: 12),
            ),
          ),
          const SizedBox(height: 24, child: VerticalDivider(width: 1)),
          DropdownButton<double>(
            value: _zoomScale,
            isDense: true,
            underline: const SizedBox(),
            items: const [
              DropdownMenuItem(value: 0.0, child: Text('Fit Screen')),
              DropdownMenuItem(value: -1.0, child: Text('Fit Height')),
              DropdownMenuItem(value: -2.0, child: Text('Fit Width')),
              DropdownMenuItem(value: 0.5, child: Text('50%')),
              DropdownMenuItem(value: 1.0, child: Text('100%')),
              DropdownMenuItem(value: 1.5, child: Text('150%')),
              DropdownMenuItem(value: 2.0, child: Text('200%')),
              DropdownMenuItem(value: 3.0, child: Text('300%')),
            ],
            onChanged: (value) {
              if (value != null) {
                setState(() => _zoomScale = value);
              }
            },
          ),
          Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Checkbox(
                visualDensity: VisualDensity.compact,
                value: widget.controller.settings.showSafeAreaGuides,
                onChanged: (value) {
                  if (value == null) return;
                  widget.controller.updateSettings(
                    widget.controller.settings.copyWith(showSafeAreaGuides: value),
                  );
                },
              ),
              const Text('Guides'),
            ],
          ),
          DropdownButton<String>(
            value: widget.controller.settings.safeAreaPreset,
            isDense: true,
            underline: const SizedBox(),
            items: const [
              DropdownMenuItem(value: 'none', child: Text('None')),
              DropdownMenuItem(value: 'facebook_reels', child: Text('FB Reels')),
              DropdownMenuItem(value: 'tiktok', child: Text('TikTok')),
              DropdownMenuItem(value: 'youtube_shorts', child: Text('YT Shorts')),
              DropdownMenuItem(value: 'custom', child: Text('Custom')),
            ],
            onChanged: widget.controller.settings.showSafeAreaGuides
                ? (value) {
              if (value == null) return;
              widget.controller.updateSettings(
                widget.controller.settings.copyWith(safeAreaPreset: value),
              );
            }
                : null,
          ),
          Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Checkbox(
                visualDensity: VisualDensity.compact,
                value: _showGrid,
                onChanged: (value) => setState(() => _showGrid = value ?? false),
              ),
              const Text('Grid'),
            ],
          ),
          Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Checkbox(
                visualDensity: VisualDensity.compact,
                value: _enableSnapping,
                onChanged: (value) {
                  setState(() => _enableSnapping = value ?? true);
                },
              ),
              const Text('Snap'),
            ],
          ),
          IconButton(
            tooltip: widget.controller.settings.showFullScreenPropertiesPanel
                ? 'Collapse Properties Panel'
                : 'Expand Properties Panel',
            icon: Icon(
              widget.controller.settings.showFullScreenPropertiesPanel
                  ? Icons.keyboard_double_arrow_right
                  : Icons.keyboard_double_arrow_left,
            ),
            onPressed: () {
              widget.controller.updateSettings(
                widget.controller.settings.copyWith(
                  showFullScreenPropertiesPanel:
                  !widget.controller.settings.showFullScreenPropertiesPanel,
                ),
              );
            },
          ),
        ],
      ),
    );
  }

  Widget _buildCanvasArea(
      ColorScheme colorScheme,
      List<PreviewOverlayItem> items,
      ) {
    return GestureDetector(
      onDoubleTap: () => setState(() => _focusMode = !_focusMode),
      child: Container(
        color: colorScheme.surfaceContainerHighest.withValues(alpha: 0.3),
        child: LayoutBuilder(
          builder: (context, constraints) {
            final availableWidth = constraints.maxWidth;
            final availableHeight = constraints.maxHeight;

            final previewWidth = widget.outputSize.previewWidth.toDouble();
            final previewHeight = widget.outputSize.previewHeight.toDouble();

            const horizontalPadding = 24.0;
            const verticalPadding = 24.0;

            final usableWidth =
            math.max(1.0, availableWidth - horizontalPadding);
            final usableHeight =
            math.max(1.0, availableHeight - verticalPadding);

            double computedScale;

            if (_zoomScale == 0.0) {
              computedScale = math.min(
                usableWidth / previewWidth,
                usableHeight / previewHeight,
              );
            } else if (_zoomScale == -1.0) {
              computedScale = usableHeight / previewHeight;
            } else if (_zoomScale == -2.0) {
              computedScale = usableWidth / previewWidth;
            } else {
              computedScale = _zoomScale;
            }

            computedScale = computedScale.clamp(0.01, 10.0);

            final canvasWidth = previewWidth * computedScale;
            final canvasHeight = previewHeight * computedScale;

            final childWidth = math.max(availableWidth, canvasWidth + 48);
            final childHeight = math.max(availableHeight, canvasHeight + 48);

            final zoomLabel = _zoomScale == 0.0
                ? 'Fit Screen'
                : _zoomScale == -1.0
                ? 'Fit Height'
                : _zoomScale == -2.0
                ? 'Fit Width'
                : '${(_zoomScale * 100).round()}%';

            return Stack(
              children: [
                Positioned.fill(
                  child: InteractiveViewer(
                    constrained: false,
                    panEnabled: true,
                    scaleEnabled: false,
                    boundaryMargin: const EdgeInsets.all(500),
                    child: SizedBox(
                      width: childWidth,
                      height: childHeight,
                      child: Center(
                        child: SizedBox(
                          width: canvasWidth,
                          height: canvasHeight,
                          child: OverlayPreviewCanvas(
                            fillConstraints: true,
                            zoomScale: computedScale,
                            outputSize: widget.outputSize,
                            items: items,
                            showGrid: _showGrid,
                            enableSnapping: _enableSnapping,
                            safeAreaPadding: widget
                                .controller.settings.showSafeAreaGuides
                                ? widget.controller.settings.activeSafeArea
                                : null,
                            selectedItemIds: widget.controller.selectedItemIds,
                            onSelected: widget.controller.selectItem,
                            onPositionChanged: (id, position) {
                              widget.controller.moveItem(
                                id,
                                position,
                                saveToDisk: false,
                              );
                            },
                            onWidthChanged: (id, width) {
                              widget.controller.resizeItem(
                                id,
                                width,
                                saveToDisk: false,
                              );
                            },
                            onDragEnd: () {
                              widget.controller.saveSettingsToDisk();
                            },
                            onMultiPositionChanged: (positions) {
                              for (final entry in positions.entries) {
                                widget.controller.moveItem(
                                  entry.key,
                                  entry.value,
                                  saveToDisk: false,
                                );
                              }
                            },
                          ),
                        ),
                      ),
                    ),
                  ),
                ),
                Positioned(
                  top: 16,
                  left: 16,
                  child: IgnorePointer(
                    child: DecoratedBox(
                      decoration: BoxDecoration(
                        color: Colors.black.withValues(alpha: 0.75),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Padding(
                        padding: const EdgeInsets.all(8),
                        child: Text(
                          'Mode: $zoomLabel\n'
                              'Available: ${availableWidth.toStringAsFixed(0)} x ${availableHeight.toStringAsFixed(0)}\n'
                              'Canvas: ${canvasWidth.toStringAsFixed(0)} x ${canvasHeight.toStringAsFixed(0)}\n'
                              'Scale: ${(computedScale * 100).toStringAsFixed(0)}%',
                          style: const TextStyle(
                            color: Colors.yellowAccent,
                            fontSize: 12,
                            height: 1.3,
                          ),
                        ),
                      ),
                    ),
                  ),
                ),
              ],
            );
          },
        ),
      ),
    );
  }
}
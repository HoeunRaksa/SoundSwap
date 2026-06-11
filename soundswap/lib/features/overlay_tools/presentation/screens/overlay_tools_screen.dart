import 'dart:io';
import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:path/path.dart' as p;
import 'package:soundswap/core/responsive/app_responsive.dart';
import 'package:soundswap/core/video/video_output_settings.dart';
import 'package:soundswap/features/branding/presentation/state/branding_controller.dart';
import 'package:soundswap/features/home/presentation/state/home_controller.dart';
import 'package:soundswap/features/overlay_tools/data/models/overlay_item.dart';
import 'package:soundswap/features/overlay_tools/presentation/state/overlay_tools_controller.dart';
import 'package:soundswap/features/templates/data/models/project_template.dart';
import 'package:soundswap/features/templates/presentation/state/templates_controller.dart';
import 'package:soundswap/features/text_overlay/presentation/state/text_overlay_controller.dart';
import 'package:soundswap/shared/widgets/empty_state.dart';
import 'package:soundswap/shared/widgets/feature_page.dart';
import 'package:soundswap/shared/widgets/overlay_preview_canvas.dart';

class OverlayToolsScreen extends StatefulWidget {
  const OverlayToolsScreen({
    required this.controller,
    required this.templatesController,
    required this.homeController,
    required this.brandingController,
    required this.textOverlayController,
    super.key,
  });

  final OverlayToolsController controller;
  final TemplatesController templatesController;
  final HomeController homeController;
  final BrandingController brandingController;
  final TextOverlayController textOverlayController;

  @override
  State<OverlayToolsScreen> createState() => _OverlayToolsScreenState();
}

class _OverlayToolsScreenState extends State<OverlayToolsScreen> {
  final _nameController = TextEditingController();
  final _textController = TextEditingController();
  final _fontSizeController = TextEditingController();
  final _colorController = TextEditingController();
  final _widthController = TextEditingController();
  final _customHeightController = TextEditingController();
  final _opacityController = TextEditingController();
  final _rotationController = TextEditingController();
  final _templateNameController = TextEditingController();
  final _workspaceNameController = TextEditingController();
  final _folderNameController = TextEditingController();
  final _startTimeController = TextEditingController();
  final _endTimeController = TextEditingController();

  final _nameFocus = FocusNode();
  final _textFocus = FocusNode();
  final _fontSizeFocus = FocusNode();
  final _colorFocus = FocusNode();
  final _widthFocus = FocusNode();
  final _customHeightFocus = FocusNode();
  final _opacityFocus = FocusNode();
  final _rotationFocus = FocusNode();
  final _startTimeFocus = FocusNode();
  final _endTimeFocus = FocusNode();

  VideoOutputSize _previewSize = VideoOutputSize.vertical1080;
  bool _showGrid = false;
  String _safeAreaMode = 'none';
  bool _enableSnapping = true;
  double _zoomScale = 1.0;
  bool _showAdvancedTiming = false;

  @override
  void initState() {
    super.initState();
    widget.controller.addListener(_syncFromState);
    _syncFromState();
  }

  @override
  void dispose() {
    widget.controller.removeListener(_syncFromState);
    _nameController.dispose();
    _textController.dispose();
    _fontSizeController.dispose();
    _colorController.dispose();
    _widthController.dispose();
    _customHeightController.dispose();
    _opacityController.dispose();
    _rotationController.dispose();
    _templateNameController.dispose();
    _workspaceNameController.dispose();
    _folderNameController.dispose();
    _startTimeController.dispose();
    _endTimeController.dispose();
    _nameFocus.dispose();
    _textFocus.dispose();
    _fontSizeFocus.dispose();
    _colorFocus.dispose();
    _widthFocus.dispose();
    _customHeightFocus.dispose();
    _opacityFocus.dispose();
    _rotationFocus.dispose();
    _startTimeFocus.dispose();
    _endTimeFocus.dispose();
    super.dispose();
  }

  void _syncFromState() {
    final items = widget.controller.settings.items;
    bool hasCustomTiming = false;
    for (final item in items) {
      if (item.startTime > 0 || item.endTime != null || item.animationEntrance != null || item.animationExit != null) {
        hasCustomTiming = true;
        break;
      }
    }
    if (hasCustomTiming && !_showAdvancedTiming) {
      _showAdvancedTiming = true;
    }

    if (_nameFocus.hasFocus ||
        _textFocus.hasFocus ||
        _fontSizeFocus.hasFocus ||
        _colorFocus.hasFocus ||
        _widthFocus.hasFocus ||
        _customHeightFocus.hasFocus ||
        _opacityFocus.hasFocus ||
        _rotationFocus.hasFocus ||
        _startTimeFocus.hasFocus ||
        _endTimeFocus.hasFocus) {
      return;
    }
    final item = widget.controller.selectedItem;
    if (item == null) {
      _setText(_nameController, '');
      _setText(_textController, '');
      _setText(_fontSizeController, '');
      _setText(_colorController, '');
      _setText(_widthController, '');
      _setText(_customHeightController, '');
      _setText(_opacityController, '');
      _setText(_rotationController, '');
      _setText(_startTimeController, '');
      _setText(_endTimeController, '');
      return;
    }
    _setText(_nameController, item.name);
    _setText(_textController, item.text);
    _setText(_fontSizeController, item.fontSize.toStringAsFixed(0));
    _setText(_colorController, item.colorHex);
    _setText(_widthController, (item.width * 100).toStringAsFixed(0));
    _setText(_customHeightController, item.customHeight != null ? (item.customHeight! * 100).toStringAsFixed(0) : '');
    _setText(_opacityController, (item.opacity * 100).toStringAsFixed(0));
    _setText(_rotationController, item.rotation.toStringAsFixed(0));
    _setText(_startTimeController, item.startTime.toStringAsFixed(1));
    _setText(_endTimeController, (item.endTime ?? widget.controller.timelineDuration).toStringAsFixed(1));
  }

  void _setText(TextEditingController controller, String value) {
    if (controller.text != value) controller.text = value;
  }

  @override
  Widget build(BuildContext context) {
    final gap = AppResponsive.cardGap(context);

    return ListenableBuilder(
      listenable: widget.controller,
      builder: (context, _) {
        return ListenableBuilder(
          listenable: widget.templatesController,
          builder: (context, _) {
            return FeaturePage(
              title: 'Overlay & Templates Studio',
              subtitle:
                  'Design overlays with layer folders, precise transforms, alignment tools, asset libraries, workspaces, and timeline animations.',
              children: [
                // Top Canva-style Toolbar Card
                Card(
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                    child: Wrap(
                      spacing: gap,
                      runSpacing: gap / 2,
                      alignment: WrapAlignment.start,
                      crossAxisAlignment: WrapCrossAlignment.center,
                      children: [
                        FilledButton.icon(
                          onPressed: widget.controller.addText,
                          icon: const Icon(Icons.text_fields),
                          label: const Text('Add Text'),
                        ),
                        FilledButton.icon(
                          onPressed: widget.controller.addImage,
                          icon: const Icon(Icons.image_outlined),
                          label: const Text('Add Image'),
                        ),
                        const SizedBox(width: 8),
                        DropdownButton<VideoOutputSize>(
                          value: _previewSize,
                          items: [
                            for (final size in VideoOutputSize.values)
                              DropdownMenuItem(value: size, child: Text(size.label)),
                          ],
                          onChanged: (value) {
                            if (value != null) setState(() => _previewSize = value);
                          },
                        ),
                        DropdownButton<double>(
                          value: _zoomScale,
                          items: const [
                            DropdownMenuItem(value: 0.5, child: Text('Zoom: 50%')),
                            DropdownMenuItem(value: 1.0, child: Text('Zoom: 100%')),
                            DropdownMenuItem(value: 1.5, child: Text('Zoom: 150%')),
                            DropdownMenuItem(value: 2.0, child: Text('Zoom: 200%')),
                          ],
                          onChanged: (value) {
                            if (value != null) setState(() => _zoomScale = value);
                          },
                        ),
                        DropdownButton<String>(
                          value: _safeAreaMode,
                          items: const [
                            DropdownMenuItem(value: 'none', child: Text('No guides')),
                            DropdownMenuItem(value: 'tiktok', child: Text('TikTok guides')),
                            DropdownMenuItem(value: 'shorts', child: Text('Shorts guides')),
                            DropdownMenuItem(value: 'reels', child: Text('Reels guides')),
                          ],
                          onChanged: (value) {
                            if (value != null) setState(() => _safeAreaMode = value);
                          },
                        ),
                        Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Checkbox(
                              value: _showGrid,
                              onChanged: (value) {
                                if (value != null) setState(() => _showGrid = value);
                              },
                            ),
                            const Text('Grid'),
                          ],
                        ),
                        Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Checkbox(
                              value: _enableSnapping,
                              onChanged: (value) {
                                if (value != null) setState(() => _enableSnapping = value);
                              },
                            ),
                            const Text('Snap'),
                          ],
                        ),
                      ],
                    ),
                  ),
                ),
                ResponsiveLayout(
                  small: Column(
                    children: [
                      _buildPreviewAndTimeline(context),
                      SizedBox(height: gap),
                      _buildSidebarTabs(context),
                    ],
                  ),
                  medium: _TwoColumn(
                    left: _buildPreviewAndTimeline(context),
                    right: _buildSidebarTabs(context),
                  ),
                  large: _TwoColumn(
                    left: _buildPreviewAndTimeline(context),
                    right: _buildSidebarTabs(context),
                  ),
                ),
                _buildTemplateSection(context),
              ],
            );
          },
        );
      },
    );
  }

  Widget _buildPreviewAndTimeline(BuildContext context) {
    final controller = widget.controller;
    final gap = AppResponsive.cardGap(context);

    final items = [
      for (final item in controller.settings.items)
        PreviewOverlayItem(
          id: item.id,
          label: item.name.isEmpty ? _itemTypeLabel(item) : item.name,
          kind: item.type == OverlayItemType.image ? PreviewOverlayKind.logo : PreviewOverlayKind.text,
          position: item.position,
          text: item.text,
          imagePath: item.imagePath,
          colorHex: item.colorHex,
          fontSize: item.fontSize,
          width: item.width,
          customHeight: item.customHeight,
          lockAspectRatio: item.lockAspectRatio,
          backgroundBox: item.backgroundBox,
          shadow: item.shadow,
          selected: item.id == controller.selectedItemId || controller.selectedItemIds.contains(item.id),
          opacity: item.opacity,
          layerOrder: item.layerOrder,
          textAlignment: item.textAlignment,
          imageFitMode: item.imageFitMode,
          rotation: item.rotation,
          locked: item.locked,
          hidden: item.hidden,
          folder: item.folder,
          scaleX: item.scaleX,
          scaleY: item.scaleY,
          startTime: item.startTime,
          endTime: item.endTime,
          animationEntrance: item.animationEntrance,
          animationEntranceDuration: item.animationEntranceDuration,
          animationExit: item.animationExit,
          animationExitDuration: item.animationExitDuration,
        ),
    ];

    return Card(
      child: Padding(
        padding: EdgeInsets.all(gap),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Row(
              children: [
                Icon(Icons.aspect_ratio, color: Theme.of(context).colorScheme.primary),
                const SizedBox(width: 8),
                Text(
                  'Canvas Preview',
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            RepaintBoundary(
              child: OverlayPreviewCanvas(
                outputSize: _previewSize,
                items: items,
                onSelected: controller.selectItem,
                onPositionChanged: controller.moveItem,
                onWidthChanged: controller.resizeItem,
                showGrid: _showGrid,
                safeAreaMode: _safeAreaMode,
                enableSnapping: _enableSnapping,
                zoomScale: _zoomScale,
                currentTime: controller.currentTime,
                selectedItemIds: controller.selectedItemIds,
                onMultiPositionChanged: (positions) {
                  positions.forEach((id, pos) {
                    controller.moveItem(id, pos);
                  });
                },
                onSizeChanged: (id, w, h) {
                  final match = controller.settings.items.firstWhere((e) => e.id == id);
                  controller.updateItem(match.copyWith(width: w, customHeight: h));
                },
              ),
            ),
            const Divider(height: 24),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Row(
                  children: [
                    Icon(
                      Icons.history_toggle_off,
                      color: _showAdvancedTiming
                          ? Theme.of(context).colorScheme.primary
                          : Theme.of(context).colorScheme.onSurfaceVariant,
                    ),
                    const SizedBox(width: 8),
                    Text(
                      'Advanced Timing',
                      style: Theme.of(context).textTheme.titleSmall?.copyWith(
                            fontWeight: FontWeight.bold,
                          ),
                    ),
                  ],
                ),
                Switch(
                  value: _showAdvancedTiming,
                  onChanged: (val) {
                    setState(() {
                      _showAdvancedTiming = val;
                    });
                  },
                ),
              ],
            ),
            if (_showAdvancedTiming) ...[
              const Divider(height: 16),
              // Seek Player Simulation Controls
              Row(
                children: [
                  IconButton(
                    icon: Icon(controller.isPlaying ? Icons.pause_circle_filled : Icons.play_circle_filled),
                    iconSize: 36,
                    color: Theme.of(context).colorScheme.primary,
                    onPressed: controller.togglePlayback,
                  ),
                  IconButton(
                    icon: const Icon(Icons.stop),
                    onPressed: () {
                      controller.pausePlayback();
                      controller.seek(0.0);
                    },
                  ),
                  const SizedBox(width: 8),
                  Text(
                    '${controller.currentTime.toStringAsFixed(2)}s / ${controller.timelineDuration.toStringAsFixed(2)}s',
                    style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13),
                  ),
                  Expanded(
                    child: Slider(
                      value: controller.currentTime,
                      max: controller.timelineDuration,
                      onChanged: controller.seek,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              // Timeline Range tracks
              if (controller.settings.items.isNotEmpty) ...[
                const Text(
                  'Timeline Tracks (Duration Range)',
                  style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12),
                ),
                const SizedBox(height: 8),
                Container(
                  constraints: const BoxConstraints(maxHeight: 180),
                  decoration: BoxDecoration(
                    color: Theme.of(context).colorScheme.surfaceContainerLow,
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: Theme.of(context).colorScheme.outlineVariant.withValues(alpha: 0.3)),
                  ),
                  child: ListView.separated(
                    shrinkWrap: true,
                    physics: const ClampingScrollPhysics(),
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                    itemCount: controller.settings.items.length,
                    separatorBuilder: (context, index) => const Divider(height: 8),
                    itemBuilder: (context, index) {
                      final item = controller.settings.items[index];
                      return Row(
                        children: [
                          SizedBox(
                            width: 110,
                            child: Text(
                              item.name.isEmpty ? _itemTypeLabel(item) : item.name,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w600),
                            ),
                          ),
                          Expanded(
                            child: RangeSlider(
                              values: RangeValues(item.startTime, item.endTime ?? controller.timelineDuration),
                              min: 0.0,
                              max: controller.timelineDuration,
                              divisions: (controller.timelineDuration * 2).toInt(),
                              labels: RangeLabels(
                                '${item.startTime.toStringAsFixed(1)}s',
                                '${(item.endTime ?? controller.timelineDuration).toStringAsFixed(1)}s',
                              ),
                              onChanged: (values) {
                                controller.updateItem(item.copyWith(
                                  startTime: values.start,
                                  endTime: values.end,
                                ));
                              },
                            ),
                          ),
                        ],
                      );
                    },
                  ),
                ),
              ],
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildSidebarTabs(BuildContext context) {
    return Card(
      child: DefaultTabController(
        length: 5,
        child: Column(
          children: [
            TabBar(
              isScrollable: true,
              tabAlignment: TabAlignment.start,
              tabs: const [
                Tab(icon: Icon(Icons.layers_outlined), text: 'Layers'),
                Tab(icon: Icon(Icons.tune), text: 'Transform'),
                Tab(icon: Icon(Icons.align_horizontal_center), text: 'Align'),
                Tab(icon: Icon(Icons.folder_special_outlined), text: 'Assets'),
                Tab(icon: Icon(Icons.save_as_outlined), text: 'Workspaces'),
              ],
            ),
            SizedBox(
              height: 640,
              child: TabBarView(
                children: [
                  _buildLayersTab(context),
                  _buildTransformTab(context),
                  _buildAlignTab(context),
                  _buildAssetsTab(context),
                  _buildWorkspacesTab(context),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  // --- TAB 1: Layers Tab ---
  Widget _buildLayersTab(BuildContext context) {
    final controller = widget.controller;

    if (controller.settings.items.isEmpty) {
      return const EmptyState(
        icon: Icons.layers_clear_outlined,
        title: 'No overlays yet',
        message: 'Add text or image layers to start editing.',
      );
    }

    return Padding(
      padding: const EdgeInsets.all(12.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            children: [
              Expanded(
                child: TextField(
                  controller: _folderNameController,
                  decoration: const InputDecoration(
                    labelText: 'Create Group Folder',
                    isDense: true,
                  ),
                ),
              ),
              const SizedBox(width: 8),
              IconButton(
                icon: const Icon(Icons.create_new_folder_outlined),
                onPressed: () {
                  final name = _folderNameController.text.trim();
                  if (name.isNotEmpty) {
                    // Creating folders is done by setting items' folder names
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(content: Text('Folder "$name" ready. Set items to this folder.')),
                    );
                    _folderNameController.clear();
                  }
                },
              ),
            ],
          ),
          const SizedBox(height: 12),
          const Text(
            'Active Layer Stack (drag to reorder)',
            style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12),
          ),
          const SizedBox(height: 6),
          Expanded(
            child: ReorderableListView.builder(
              buildDefaultDragHandles: false,
              itemCount: controller.settings.items.length,
              onReorder: controller.reorderItems,
              itemBuilder: (context, index) {
                final overlay = controller.settings.items[index];
                final isSelected = controller.selectedItemIds.contains(overlay.id);

                return _OverlayListTile(
                  key: ValueKey(overlay.id),
                  item: overlay,
                  index: index,
                  selected: isSelected,
                  onTap: () => controller.selectItem(overlay.id),
                  onLockToggled: () => controller.toggleLock(overlay.id),
                  onHiddenToggled: () => controller.toggleHidden(overlay.id),
                  onDuplicate: () => controller.duplicateItem(overlay.id),
                  onDelete: () async {
                    controller.selectItem(overlay.id);
                    await controller.removeSelected();
                  },
                  onFolderChanged: (folder) => controller.setItemFolder(overlay.id, folder),
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  // --- TAB 2: Transform / Properties Tab ---
  Widget _buildTransformTab(BuildContext context) {
    final item = widget.controller.selectedItem;
    final gap = AppResponsive.cardGap(context);

    if (item == null) {
      return const Center(
        child: Padding(
          padding: EdgeInsets.all(24.0),
          child: Text('Select an overlay layer to adjust transform properties.'),
        ),
      );
    }

    final isText = item.type == OverlayItemType.text;

    return SingleChildScrollView(
      padding: EdgeInsets.all(gap),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          TextField(
            controller: _nameController,
            focusNode: _nameFocus,
            decoration: const InputDecoration(
              labelText: 'Layer Name',
              border: OutlineInputBorder(),
            ),
            onChanged: (value) => widget.controller.updateSelected(item.copyWith(name: value)),
          ),
          SizedBox(height: gap),
          if (isText) ...[
            TextField(
              controller: _textController,
              focusNode: _textFocus,
              minLines: 2,
              maxLines: 4,
              decoration: const InputDecoration(
                labelText: 'Text Content',
                border: OutlineInputBorder(),
              ),
              onChanged: (value) => widget.controller.updateSelected(item.copyWith(text: value)),
            ),
            SizedBox(height: gap),
            DropdownButtonFormField<String>(
              initialValue: item.textAlignment,
              isExpanded: true,
              decoration: const InputDecoration(
                labelText: 'Text Alignment',
                border: OutlineInputBorder(),
              ),
              items: const [
                DropdownMenuItem(value: 'left', child: Text('Left')),
                DropdownMenuItem(value: 'center', child: Text('Center')),
                DropdownMenuItem(value: 'right', child: Text('Right')),
              ],
              onChanged: (value) {
                if (value != null) {
                  widget.controller.updateSelected(item.copyWith(textAlignment: value));
                }
              },
            ),
            SizedBox(height: gap),
            DropdownButtonFormField<String>(
              initialValue: item.fontFamily,
              isExpanded: true,
              decoration: const InputDecoration(
                labelText: 'Font Family',
                border: OutlineInputBorder(),
              ),
              items: const [
                DropdownMenuItem(value: 'Arial', child: Text('Arial')),
                DropdownMenuItem(value: 'Segoe UI', child: Text('Segoe UI')),
                DropdownMenuItem(value: 'Tahoma', child: Text('Tahoma')),
                DropdownMenuItem(value: 'Verdana', child: Text('Verdana')),
                DropdownMenuItem(value: 'Times New Roman', child: Text('Times New Roman')),
              ],
              onChanged: (value) {
                if (value != null) {
                  widget.controller.updateSelected(item.copyWith(fontFamily: value));
                }
              },
            ),
            SizedBox(height: gap),
            Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: _fontSizeController,
                    focusNode: _fontSizeFocus,
                    keyboardType: TextInputType.number,
                    decoration: const InputDecoration(
                      labelText: 'Font Size',
                      border: OutlineInputBorder(),
                    ),
                    onChanged: (value) {
                      final size = double.tryParse(value);
                      if (size != null) {
                        widget.controller.updateSelected(
                          item.copyWith(fontSize: size.clamp(10, 240).toDouble()),
                        );
                      }
                    },
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: TextField(
                    controller: _colorController,
                    focusNode: _colorFocus,
                    decoration: const InputDecoration(
                      labelText: 'Color Hex',
                      hintText: '#FFFFFF',
                      border: OutlineInputBorder(),
                    ),
                    onChanged: (value) => widget.controller.updateSelected(item.copyWith(colorHex: value)),
                  ),
                ),
              ],
            ),
            SwitchListTile(
              contentPadding: EdgeInsets.zero,
              title: const Text('Text Shadow'),
              value: item.shadow,
              onChanged: (value) => widget.controller.updateSelected(item.copyWith(shadow: value)),
            ),
            SwitchListTile(
              contentPadding: EdgeInsets.zero,
              title: const Text('Background Box'),
              value: item.backgroundBox,
              onChanged: (value) => widget.controller.updateSelected(item.copyWith(backgroundBox: value)),
            ),
            OutlinedButton.icon(
              onPressed: widget.controller.pickDefaultFont,
              icon: const Icon(Icons.font_download_outlined),
              label: Text(
                widget.controller.settings.defaultFontPath == null
                    ? 'Choose Custom Font File'
                    : 'Font: ${p.basename(widget.controller.settings.defaultFontPath!)}',
              ),
            ),
            SizedBox(height: gap),
          ] else ...[
            _buildCleanImagePath(context, item.imagePath),
            SizedBox(height: gap),
            DropdownButtonFormField<String>(
              initialValue: item.imageFitMode,
              isExpanded: true,
              decoration: const InputDecoration(
                labelText: 'Fit Mode',
                border: OutlineInputBorder(),
              ),
              items: const [
                DropdownMenuItem(value: 'contain', child: Text('Contain')),
                DropdownMenuItem(value: 'cover', child: Text('Cover')),
                DropdownMenuItem(value: 'stretch', child: Text('Stretch')),
              ],
              onChanged: (value) {
                if (value != null) {
                  widget.controller.updateSelected(item.copyWith(imageFitMode: value));
                }
              },
            ),
            SwitchListTile(
              contentPadding: EdgeInsets.zero,
              title: const Text('Lock Aspect Ratio'),
              value: item.lockAspectRatio,
              onChanged: (value) {
                widget.controller.updateSelected(
                  item.copyWith(
                    lockAspectRatio: value,
                    customHeight: value ? null : item.width,
                  ),
                );
              },
            ),
            SizedBox(height: gap),
          ],
          // Precision Positioning
          Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('X Pos: ${(item.position.x * 100).toStringAsFixed(0)}%', style: const TextStyle(fontSize: 11)),
                    Slider(
                      value: item.position.x.clamp(0.0, 1.0),
                      onChanged: (val) => widget.controller.moveItem(item.id, item.position.copyWith(x: val)),
                    ),
                  ],
                ),
              ),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('Y Pos: ${(item.position.y * 100).toStringAsFixed(0)}%', style: const TextStyle(fontSize: 11)),
                    Slider(
                      value: item.position.y.clamp(0.0, 1.0),
                      onChanged: (val) => widget.controller.moveItem(item.id, item.position.copyWith(y: val)),
                    ),
                  ],
                ),
              ),
            ],
          ),
          SizedBox(height: gap),
          Row(
            children: [
              Expanded(
                child: TextField(
                  controller: _widthController,
                  focusNode: _widthFocus,
                  keyboardType: TextInputType.number,
                  decoration: InputDecoration(
                    labelText: isText ? 'Wrapping Width %' : 'Width %',
                    border: const OutlineInputBorder(),
                  ),
                  onChanged: (value) {
                    final widthVal = double.tryParse(value);
                    if (widthVal != null) {
                      final nextW = widthVal / 100;
                      widget.controller.updateSelected(
                        item.copyWith(
                          width: nextW,
                          customHeight: item.lockAspectRatio ? null : (item.customHeight ?? nextW),
                        ),
                      );
                    }
                  },
                ),
              ),
              if (!isText && !item.lockAspectRatio) ...[
                const SizedBox(width: 12),
                Expanded(
                  child: TextField(
                    controller: _customHeightController,
                    focusNode: _customHeightFocus,
                    keyboardType: TextInputType.number,
                    decoration: const InputDecoration(
                      labelText: 'Height %',
                      border: OutlineInputBorder(),
                    ),
                    onChanged: (value) {
                      final heightVal = double.tryParse(value);
                      if (heightVal != null) {
                        widget.controller.updateSelected(
                          item.copyWith(customHeight: heightVal / 100),
                        );
                      }
                    },
                  ),
                ),
              ],
            ],
          ),
          SizedBox(height: gap),
          // Precision Scales (ScaleX, ScaleY)
          Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('Scale X: ${item.scaleX.toStringAsFixed(1)}', style: const TextStyle(fontSize: 11)),
                    Slider(
                      value: item.scaleX,
                      min: 0.1,
                      max: 3.0,
                      onChanged: (val) => widget.controller.updateItem(item.copyWith(scaleX: val)),
                    ),
                  ],
                ),
              ),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('Scale Y: ${item.scaleY.toStringAsFixed(1)}', style: const TextStyle(fontSize: 11)),
                    Slider(
                      value: item.scaleY,
                      min: 0.1,
                      max: 3.0,
                      onChanged: (val) => widget.controller.updateItem(item.copyWith(scaleY: val)),
                    ),
                  ],
                ),
              ),
            ],
          ),
          SizedBox(height: gap),
          // Rotation Slider
          Row(
            children: [
              const Text('Rotation:', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12)),
              Expanded(
                child: Slider(
                  value: item.rotation,
                  min: 0,
                  max: 360,
                  divisions: 360,
                  onChanged: (value) {
                    widget.controller.updateSelected(item.copyWith(rotation: value.roundToDouble()));
                  },
                ),
              ),
              SizedBox(
                width: 70,
                child: TextField(
                  controller: _rotationController,
                  focusNode: _rotationFocus,
                  keyboardType: TextInputType.number,
                  decoration: const InputDecoration(
                    suffixText: '°',
                    border: OutlineInputBorder(),
                  ),
                  onChanged: (value) {
                    final val = double.tryParse(value);
                    if (val != null) {
                      widget.controller.updateSelected(
                        item.copyWith(rotation: val.clamp(0.0, 360.0)),
                      );
                    }
                  },
                ),
              ),
            ],
          ),
          SizedBox(height: gap),
          // Opacity Slider
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('Opacity: ${(item.opacity * 100).toStringAsFixed(0)}%', style: const TextStyle(fontSize: 11)),
              Slider(
                value: item.opacity.clamp(0.0, 1.0),
                onChanged: (val) => widget.controller.updateItem(item.copyWith(opacity: val)),
              ),
            ],
          ),
          if (_showAdvancedTiming) ...[
            const Divider(height: 24),
            Row(
              children: [
                Icon(Icons.timer_outlined, size: 18, color: Theme.of(context).colorScheme.primary),
                const SizedBox(width: 8),
                const Text(
                  'Timing Options',
                  style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13),
                ),
              ],
            ),
            const SizedBox(height: 12),
            SegmentedButton<bool>(
              segments: const [
                ButtonSegment<bool>(
                  value: false,
                  label: Text('Entire Video'),
                  icon: Icon(Icons.video_label),
                ),
                ButtonSegment<bool>(
                  value: true,
                  label: Text('Custom Duration'),
                  icon: Icon(Icons.timer),
                ),
              ],
              selected: {item.startTime > 0 || item.endTime != null},
              onSelectionChanged: (value) {
                final isCustom = value.first;
                if (isCustom) {
                  widget.controller.updateItem(item.copyWith(
                    startTime: 0.0,
                    endTime: widget.controller.timelineDuration > 5.0 ? 5.0 : widget.controller.timelineDuration,
                  ));
                } else {
                  widget.controller.updateItem(item.copyWith(
                    startTime: 0.0,
                    clearEndTime: true,
                  ));
                }
              },
            ),
            const SizedBox(height: 16),
            if (item.startTime > 0 || item.endTime != null) ...[
              Row(
                children: [
                  Expanded(
                    child: TextField(
                      controller: _startTimeController,
                      focusNode: _startTimeFocus,
                      keyboardType: const TextInputType.numberWithOptions(decimal: true),
                      decoration: const InputDecoration(
                        labelText: 'Start Seconds',
                        border: OutlineInputBorder(),
                        suffixText: 's',
                        isDense: true,
                      ),
                      onChanged: (val) {
                        final parsed = double.tryParse(val);
                        if (parsed != null) {
                          widget.controller.updateItem(item.copyWith(
                            startTime: parsed.clamp(0.0, item.endTime ?? widget.controller.timelineDuration),
                          ));
                        }
                      },
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: TextField(
                      controller: _endTimeController,
                      focusNode: _endTimeFocus,
                      keyboardType: const TextInputType.numberWithOptions(decimal: true),
                      decoration: const InputDecoration(
                        labelText: 'End Seconds',
                        border: OutlineInputBorder(),
                        suffixText: 's',
                        isDense: true,
                      ),
                      onChanged: (val) {
                        final parsed = double.tryParse(val);
                        if (parsed != null) {
                          widget.controller.updateItem(item.copyWith(
                            endTime: parsed.clamp(item.startTime, widget.controller.timelineDuration),
                          ));
                        }
                      },
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Duration: ${item.startTime.toStringAsFixed(1)}s - ${(item.endTime ?? widget.controller.timelineDuration).toStringAsFixed(1)}s',
                    style: const TextStyle(fontSize: 11, fontWeight: FontWeight.bold),
                  ),
                  RangeSlider(
                    values: RangeValues(item.startTime, item.endTime ?? widget.controller.timelineDuration),
                    min: 0.0,
                    max: widget.controller.timelineDuration,
                    divisions: (widget.controller.timelineDuration * 2).toInt(),
                    labels: RangeLabels(
                      '${item.startTime.toStringAsFixed(1)}s',
                      '${(item.endTime ?? widget.controller.timelineDuration).toStringAsFixed(1)}s',
                    ),
                    onChanged: (values) {
                      widget.controller.updateItem(item.copyWith(
                        startTime: values.start,
                        endTime: values.end,
                      ));
                    },
                  ),
                ],
              ),
              const SizedBox(height: 12),
            ],
            // ANIMATIONS CONFIGURATION
            const Text(
              'Timeline Animations',
              style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13),
            ),
            const SizedBox(height: 8),
            DropdownButtonFormField<String?>(
              initialValue: item.animationEntrance,
              decoration: const InputDecoration(
                labelText: 'Entrance Transition (Fade/Slide)',
                border: OutlineInputBorder(),
              ),
              items: const [
                DropdownMenuItem(value: null, child: Text('None (Cut)')),
                DropdownMenuItem(value: 'fade', child: Text('Fade In')),
                DropdownMenuItem(value: 'slide_left', child: Text('Slide from Left')),
                DropdownMenuItem(value: 'slide_right', child: Text('Slide from Right')),
                DropdownMenuItem(value: 'slide_up', child: Text('Slide from Bottom')),
                DropdownMenuItem(value: 'slide_down', child: Text('Slide from Top')),
              ],
              onChanged: (val) => widget.controller.updateItem(item.copyWith(animationEntrance: val)),
            ),
            const SizedBox(height: 8),
            Row(
              children: [
                const Text('Entrance Duration:', style: TextStyle(fontSize: 11)),
                Expanded(
                  child: Slider(
                    value: item.animationEntranceDuration,
                    min: 0.1,
                    max: 5.0,
                    onChanged: (val) => widget.controller.updateItem(item.copyWith(animationEntranceDuration: val)),
                  ),
                ),
                Text('${item.animationEntranceDuration.toStringAsFixed(1)}s', style: const TextStyle(fontSize: 11)),
              ],
            ),
            const SizedBox(height: 12),
            DropdownButtonFormField<String?>(
              initialValue: item.animationExit,
              decoration: const InputDecoration(
                labelText: 'Exit Transition (Fade/Slide)',
                border: OutlineInputBorder(),
              ),
              items: const [
                DropdownMenuItem(value: null, child: Text('None (Cut)')),
                DropdownMenuItem(value: 'fade', child: Text('Fade Out')),
                DropdownMenuItem(value: 'slide_left', child: Text('Slide to Left')),
                DropdownMenuItem(value: 'slide_right', child: Text('Slide to Right')),
                DropdownMenuItem(value: 'slide_up', child: Text('Slide to Top')),
                DropdownMenuItem(value: 'slide_down', child: Text('Slide to Bottom')),
              ],
              onChanged: (val) => widget.controller.updateItem(item.copyWith(animationExit: val)),
            ),
            const SizedBox(height: 8),
            Row(
              children: [
                const Text('Exit Duration:', style: TextStyle(fontSize: 11)),
                Expanded(
                  child: Slider(
                    value: item.animationExitDuration,
                    min: 0.1,
                    max: 5.0,
                    onChanged: (val) => widget.controller.updateItem(item.copyWith(animationExitDuration: val)),
                  ),
                ),
                Text('${item.animationExitDuration.toStringAsFixed(1)}s', style: const TextStyle(fontSize: 11)),
              ],
            ),
            const SizedBox(height: 16),
            FilledButton.icon(
              onPressed: () {
                widget.controller.applyTimingToAll();
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Timing & animations applied to all overlays!')),
                );
              },
              icon: const Icon(Icons.copy_all_outlined),
              label: const Text('Apply timing to all overlays'),
              style: FilledButton.styleFrom(
                minimumSize: const Size.fromHeight(40),
              ),
            ),
          ],
        ],
      ),
    );
  }

  // --- TAB 3: Align & Distribute Tab ---
  Widget _buildAlignTab(BuildContext context) {
    final controller = widget.controller;
    final gap = AppResponsive.cardGap(context);

    return Padding(
      padding: const EdgeInsets.all(16.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(
            'Alignment Tools (${controller.selectedItemIds.length} layers selected)',
            style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13),
          ),
          const SizedBox(height: 4),
          const Text(
            'If one item is selected, aligns to canvas bounds. If multiple are selected, aligns to outer bounds.',
            style: TextStyle(fontSize: 11, color: Colors.grey),
          ),
          const SizedBox(height: 16),
          Wrap(
            spacing: 12,
            runSpacing: 12,
            children: [
              ElevatedButton.icon(
                onPressed: controller.selectedItemIds.isEmpty ? null : controller.alignLeft,
                icon: const Icon(Icons.align_horizontal_left),
                label: const Text('Align Left'),
              ),
              ElevatedButton.icon(
                onPressed: controller.selectedItemIds.isEmpty ? null : controller.alignCenterX,
                icon: const Icon(Icons.align_horizontal_center),
                label: const Text('Center X'),
              ),
              ElevatedButton.icon(
                onPressed: controller.selectedItemIds.isEmpty ? null : controller.alignRight,
                icon: const Icon(Icons.align_horizontal_right),
                label: const Text('Align Right'),
              ),
              ElevatedButton.icon(
                onPressed: controller.selectedItemIds.isEmpty ? null : controller.alignTop,
                icon: const Icon(Icons.align_vertical_top),
                label: const Text('Align Top'),
              ),
              ElevatedButton.icon(
                onPressed: controller.selectedItemIds.isEmpty ? null : controller.alignCenterY,
                icon: const Icon(Icons.align_vertical_center),
                label: const Text('Center Y'),
              ),
              ElevatedButton.icon(
                onPressed: controller.selectedItemIds.isEmpty ? null : controller.alignBottom,
                icon: const Icon(Icons.align_vertical_bottom),
                label: const Text('Align Bottom'),
              ),
            ],
          ),
          const Divider(height: 32),
          const Text(
            'Distribute Layers (Needs 3+ layers selected)',
            style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13),
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                child: ElevatedButton.icon(
                  onPressed: controller.selectedItemIds.length < 3 ? null : controller.distributeHorizontal,
                  icon: const Icon(Icons.more_horiz),
                  label: const Text('Distribute X'),
                ),
              ),
              SizedBox(width: gap),
              Expanded(
                child: ElevatedButton.icon(
                  onPressed: controller.selectedItemIds.length < 3 ? null : controller.distributeVertical,
                  icon: const Icon(Icons.more_vert),
                  label: const Text('Distribute Y'),
                ),
              ),
            ],
          ),
          SizedBox(height: gap),
          if (controller.selectedItemIds.isNotEmpty)
            OutlinedButton(
              onPressed: controller.clearSelection,
              child: const Text('Clear Selection'),
            ),
        ],
      ),
    );
  }

  // --- TAB 4: Asset Library Tab ---
  Widget _buildAssetsTab(BuildContext context) {
    final controller = widget.controller;

    return Padding(
      padding: const EdgeInsets.all(12.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          ElevatedButton.icon(
            onPressed: () async {
              final result = await FilePicker.platform.pickFiles(type: FileType.image);
              final path = result?.files.single.path;
              if (path != null) {
                await controller.addAssetToLibrary(path);
              }
            },
            icon: const Icon(Icons.add_photo_alternate_outlined),
            label: const Text('Import Media Asset'),
          ),
          const SizedBox(height: 12),
          if (controller.assets.isEmpty)
            const Expanded(
              child: EmptyState(
                icon: Icons.folder_open_outlined,
                title: 'Library is empty',
                message: 'Import assets to quickly place them on your canvas.',
              ),
            )
          else
            Expanded(
              child: GridView.builder(
                gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                  crossAxisCount: 2,
                  crossAxisSpacing: 8,
                  mainAxisSpacing: 8,
                  childAspectRatio: 0.82,
                ),
                itemCount: controller.assets.length,
                itemBuilder: (context, index) {
                  final asset = controller.assets[index];
                  final file = File(asset.path);

                  return Card(
                    clipBehavior: Clip.antiAlias,
                    child: Stack(
                      children: [
                        Positioned.fill(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.stretch,
                            children: [
                              Expanded(
                                child: file.existsSync()
                                    ? Image.file(file, fit: BoxFit.cover)
                                    : const Icon(Icons.broken_image_outlined, size: 36),
                              ),
                              Padding(
                                padding: const EdgeInsets.all(4.0),
                                child: Text(
                                  asset.name,
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                  style: const TextStyle(fontSize: 10, fontWeight: FontWeight.bold),
                                ),
                              ),
                            ],
                          ),
                        ),
                        // Overlay Quick Actions
                        Positioned(
                          top: 4,
                          right: 4,
                          child: CircleAvatar(
                            radius: 14,
                            backgroundColor: Colors.black54,
                            child: IconButton(
                              iconSize: 12,
                              icon: const Icon(Icons.add, color: Colors.white),
                              onPressed: () => controller.addAssetToCanvas(asset),
                            ),
                          ),
                        ),
                        Positioned(
                          bottom: 24,
                          right: 4,
                          child: CircleAvatar(
                            radius: 14,
                            backgroundColor: Colors.black54,
                            child: IconButton(
                              iconSize: 12,
                              icon: const Icon(Icons.delete, color: Colors.red),
                              onPressed: () => controller.removeAssetFromLibrary(asset.id),
                            ),
                          ),
                        ),
                      ],
                    ),
                  );
                },
              ),
            ),
        ],
      ),
    );
  }

  // --- TAB 5: Workspaces Tab ---
  Widget _buildWorkspacesTab(BuildContext context) {
    final controller = widget.controller;

    return Padding(
      padding: const EdgeInsets.all(12.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            children: [
              Expanded(
                child: TextField(
                  controller: _workspaceNameController,
                  decoration: const InputDecoration(
                    labelText: 'Workspace Name',
                    isDense: true,
                  ),
                ),
              ),
              const SizedBox(width: 8),
              ElevatedButton(
                onPressed: () async {
                  final name = _workspaceNameController.text.trim();
                  await controller.saveWorkspace(
                    name,
                    home: widget.homeController,
                    branding: widget.brandingController,
                    textOverlay: widget.textOverlayController,
                    templatesList: widget.templatesController.templates,
                  );
                  _workspaceNameController.clear();
                },
                child: const Text('Save Snapshot'),
              ),
            ],
          ),
          const SizedBox(height: 12),
          const Text(
            'Production Workspaces (Snapshots)',
            style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12),
          ),
          const SizedBox(height: 6),
          if (controller.workspaces.isEmpty)
            const Expanded(
              child: EmptyState(
                icon: Icons.history_edu_outlined,
                title: 'No workspaces saved',
                message: 'Save a snapshot of your canvas, folders, templates, assets, and folders.',
              ),
            )
          else
            Expanded(
              child: ListView.builder(
                itemCount: controller.workspaces.length,
                itemBuilder: (context, index) {
                  final ws = controller.workspaces[index];
                  return Card(
                    color: Theme.of(context).colorScheme.surfaceContainerLow,
                    child: ListTile(
                      dense: true,
                      leading: const Icon(Icons.workspace_premium_outlined, color: Colors.teal),
                      title: Text(ws.name, style: const TextStyle(fontWeight: FontWeight.bold)),
                      subtitle: Text(
                        'Templates: ${ws.templates.length} | Assets: ${ws.assets.length}\n${ws.createdAt.toLocal().toString().split('.')[0]}',
                        style: const TextStyle(fontSize: 10),
                      ),
                      trailing: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          IconButton(
                            icon: const Icon(Icons.folder_open_outlined, color: Colors.teal),
                            onPressed: () => controller.loadWorkspace(
                              ws,
                              home: widget.homeController,
                              branding: widget.brandingController,
                              textOverlay: widget.textOverlayController,
                              templatesCtrl: widget.templatesController,
                            ),
                          ),
                          IconButton(
                            icon: const Icon(Icons.delete_outline, color: Colors.red),
                            onPressed: () => controller.deleteWorkspace(ws),
                          ),
                        ],
                      ),
                    ),
                  );
                },
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildCleanImagePath(BuildContext context, String? imagePath) {
    final theme = Theme.of(context);
    if (imagePath == null) {
      return Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: theme.colorScheme.surfaceContainerHighest.withValues(alpha: 0.5),
          borderRadius: BorderRadius.circular(8),
        ),
        child: const Row(
          children: [
            Icon(Icons.image_not_supported_outlined, size: 20),
            SizedBox(width: 8),
            Text('No image selected'),
          ],
        ),
      );
    }
    final filename = p.basename(imagePath);
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: theme.colorScheme.surfaceContainerHighest.withValues(alpha: 0.3),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(
          color: theme.colorScheme.outlineVariant.withValues(alpha: 0.3),
        ),
      ),
      child: Row(
        children: [
          Icon(Icons.image_outlined, color: theme.colorScheme.primary, size: 22),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  filename,
                  style: const TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 13,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 2),
                Text(
                  imagePath,
                  style: TextStyle(
                    fontSize: 10,
                    color: theme.colorScheme.onSurfaceVariant.withValues(alpha: 0.7),
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTemplateSection(BuildContext context) {
    final controller = widget.templatesController;
    return SettingsSection(
      title: 'Reusable Project Templates',
      icon: Icons.dashboard_customize_outlined,
      children: [
        Row(
          children: [
            Expanded(
              child: TextField(
                controller: _templateNameController,
                decoration: const InputDecoration(
                  labelText: 'Save settings under template name',
                  hintText: 'My Preset',
                ),
              ),
            ),
            const SizedBox(width: 12),
            FilledButton.icon(
              onPressed: () async {
                await controller.saveCurrent(
                  name: _templateNameController.text,
                  home: widget.homeController,
                  branding: widget.brandingController,
                  textOverlay: widget.textOverlayController,
                  overlay: widget.controller,
                );
                _templateNameController.clear();
              },
              icon: const Icon(Icons.save_outlined),
              label: const Text('Save Current'),
            ),
          ],
        ),
        if (controller.message != null) Text(controller.message!),
        if (controller.templates.isEmpty)
          const SizedBox(
            height: 180,
            child: EmptyState(
              icon: Icons.inbox_outlined,
              title: 'No templates yet',
              message: 'No templates yet. Create overlays, then save them as a template.',
            ),
          )
        else
          for (final template in controller.templates)
            _TemplateTile(
              template: template,
              onApply: () => controller.loadTemplate(
                template: template,
                home: widget.homeController,
                branding: widget.brandingController,
                textOverlay: widget.textOverlayController,
                overlay: widget.controller,
              ),
              onRename: () => _renameTemplate(template),
              onDelete: () => _confirmDeleteTemplate(template),
            ),
      ],
    );
  }

  Future<void> _renameTemplate(ProjectTemplate template) async {
    final controller = TextEditingController(text: template.name);
    final name = await showDialog<String>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Rename template'),
        content: TextField(
          controller: controller,
          autofocus: true,
          decoration: const InputDecoration(labelText: 'Template name'),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(context, controller.text),
            child: const Text('Save'),
          ),
        ],
      ),
    );
    controller.dispose();
    if (name != null) {
      await widget.templatesController.renameTemplate(
        template: template,
        name: name,
      );
    }
  }

  Future<void> _confirmDeleteTemplate(ProjectTemplate template) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete template?'),
        content: Text('Delete "${template.name}"?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Delete'),
          ),
        ],
      ),
    );
    if (confirmed == true) {
      await widget.templatesController.deleteTemplate(template);
    }
  }

  String _itemTypeLabel(OverlayItem item) {
    return item.type == OverlayItemType.text ? 'Text' : 'Image';
  }
}

class _OverlayListTile extends StatelessWidget {
  const _OverlayListTile({
    required this.item,
    required this.index,
    required this.selected,
    required this.onTap,
    required this.onLockToggled,
    required this.onHiddenToggled,
    required this.onDuplicate,
    required this.onDelete,
    required this.onFolderChanged,
    super.key,
  });

  final OverlayItem item;
  final int index;
  final bool selected;
  final VoidCallback onTap;
  final VoidCallback onLockToggled;
  final VoidCallback onHiddenToggled;
  final VoidCallback onDuplicate;
  final VoidCallback onDelete;
  final ValueChanged<String?> onFolderChanged;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return Padding(
      padding: const EdgeInsets.only(bottom: 6.0),
      child: Material(
        color: selected
            ? colorScheme.primaryContainer.withValues(alpha: 0.18)
            : colorScheme.surfaceContainerLow,
        borderRadius: BorderRadius.circular(10),
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(10),
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(10),
              border: Border.all(
                color: selected ? colorScheme.primary : colorScheme.outlineVariant.withValues(alpha: 0.3),
                width: selected ? 2 : 1,
              ),
            ),
            child: Column(
              children: [
                Row(
                  children: [
                    ReorderableDragStartListener(
                      index: index,
                      child: MouseRegion(
                        cursor: SystemMouseCursors.grab,
                        child: Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 2.0),
                          child: Icon(
                            Icons.drag_indicator,
                            size: 18,
                            color: selected ? colorScheme.primary : colorScheme.onSurfaceVariant.withValues(alpha: 0.5),
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: 4),
                    _buildThumbnail(context),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              if (item.folder != null && item.folder!.isNotEmpty) ...[
                                Icon(Icons.folder_open, size: 12, color: colorScheme.primary),
                                const SizedBox(width: 2),
                                Text(
                                  '[${item.folder}] ',
                                  style: TextStyle(
                                    fontSize: 10,
                                    color: colorScheme.primary,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ],
                              Expanded(
                                child: Text(
                                  item.name.isEmpty
                                      ? (item.type == OverlayItemType.text ? 'Text Layer' : 'Image Layer')
                                      : item.name,
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                  style: TextStyle(
                                    fontWeight: selected ? FontWeight.bold : FontWeight.w600,
                                    fontSize: 12,
                                    color: selected ? colorScheme.primary : colorScheme.onSurface,
                                  ),
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 2),
                          Text(
                            _previewText,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: TextStyle(
                              fontSize: 10,
                              color: colorScheme.onSurfaceVariant.withValues(alpha: 0.7),
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(width: 4),
                    // Quick Action Buttons
                    IconButton(
                      icon: Icon(item.hidden ? Icons.visibility_off_outlined : Icons.visibility_outlined, size: 18),
                      padding: EdgeInsets.zero,
                      constraints: const BoxConstraints(),
                      color: item.hidden ? Colors.grey : colorScheme.primary,
                      onPressed: onHiddenToggled,
                    ),
                    const SizedBox(width: 6),
                    IconButton(
                      icon: Icon(item.locked ? Icons.lock : Icons.lock_open, size: 18),
                      padding: EdgeInsets.zero,
                      constraints: const BoxConstraints(),
                      color: item.locked ? Colors.red : Colors.grey,
                      onPressed: onLockToggled,
                    ),
                    const SizedBox(width: 6),
                    IconButton(
                      icon: const Icon(Icons.copy, size: 18),
                      padding: EdgeInsets.zero,
                      constraints: const BoxConstraints(),
                      onPressed: onDuplicate,
                    ),
                    const SizedBox(width: 6),
                    IconButton(
                      icon: const Icon(Icons.delete_outline, size: 18, color: Colors.red),
                      padding: EdgeInsets.zero,
                      constraints: const BoxConstraints(),
                      onPressed: onDelete,
                    ),
                  ],
                ),
                const SizedBox(height: 4),
                // Folder Selection Dropdown
                Row(
                  mainAxisAlignment: MainAxisAlignment.end,
                  children: [
                    const Text('Folder: ', style: TextStyle(fontSize: 10, color: Colors.grey)),
                    const SizedBox(width: 4),
                    SizedBox(
                      height: 24,
                      child: DropdownButton<String?>(
                        value: item.folder,
                        underline: const SizedBox(),
                        style: const TextStyle(fontSize: 10, color: Colors.black87),
                        hint: const Text('None', style: TextStyle(fontSize: 10)),
                        items: const [
                          DropdownMenuItem(value: null, child: Text('None', style: TextStyle(fontSize: 10))),
                          DropdownMenuItem(value: 'Branding', child: Text('Branding', style: TextStyle(fontSize: 10))),
                          DropdownMenuItem(value: 'Subtitles', child: Text('Subtitles', style: TextStyle(fontSize: 10))),
                          DropdownMenuItem(value: 'Watermarks', child: Text('Watermarks', style: TextStyle(fontSize: 10))),
                          DropdownMenuItem(value: 'CTA', child: Text('CTA', style: TextStyle(fontSize: 10))),
                        ],
                        onChanged: onFolderChanged,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildThumbnail(BuildContext context) {
    if (item.type == OverlayItemType.image && item.imagePath != null) {
      final file = File(item.imagePath!);
      if (file.existsSync()) {
        return Container(
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(6),
            border: Border.all(
              color: Theme.of(context).colorScheme.outlineVariant.withValues(alpha: 0.5),
            ),
          ),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(5),
            child: SizedBox(
              width: 30,
              height: 30,
              child: Image.file(file, fit: BoxFit.cover),
            ),
          ),
        );
      }
    }

    if (item.type == OverlayItemType.text && item.text.trim().isNotEmpty) {
      final color = _colorFromHex(item.colorHex);
      final rawText = item.text.trim();
      final previewString = rawText.substring(0, rawText.length.clamp(0, 2)).toUpperCase();
      return Container(
        width: 30,
        height: 30,
        decoration: BoxDecoration(
          color: Colors.black87,
          borderRadius: BorderRadius.circular(6),
        ),
        alignment: Alignment.center,
        child: Text(
          previewString,
          style: TextStyle(
            color: color,
            fontWeight: FontWeight.w900,
            fontSize: 11,
          ),
        ),
      );
    }

    return Container(
      width: 30,
      height: 30,
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surfaceContainerHighest,
        borderRadius: BorderRadius.circular(6),
        border: Border.all(
          color: Theme.of(context).colorScheme.outlineVariant.withValues(alpha: 0.3),
        ),
      ),
      child: Icon(
        item.type == OverlayItemType.text ? Icons.text_fields : Icons.image_outlined,
        size: 16,
        color: Theme.of(context).colorScheme.onSurfaceVariant,
      ),
    );
  }

  String get _previewText {
    if (item.type == OverlayItemType.text) {
      return item.text.trim().isEmpty ? 'Empty text' : item.text.trim();
    }
    return p.basename(item.imagePath ?? 'No image');
  }

  static Color _colorFromHex(String value) {
    final hex = value.replaceFirst('#', '').trim();
    if (hex.length != 6) return Colors.white;
    final parsed = int.tryParse('FF$hex', radix: 16);
    return parsed == null ? Colors.white : Color(parsed);
  }
}

class _TemplateTile extends StatelessWidget {
  const _TemplateTile({
    required this.template,
    required this.onApply,
    required this.onRename,
    required this.onDelete,
  });

  final ProjectTemplate template;
  final VoidCallback onApply;
  final VoidCallback onRename;
  final VoidCallback onDelete;

  @override
  Widget build(BuildContext context) {
    final textCount = template.overlaySettings.items.where((item) => item.type == OverlayItemType.text).length;
    final imageCount = template.overlaySettings.items.where((item) => item.type == OverlayItemType.image).length;
    final fontName = template.overlaySettings.defaultFontPath == null
        ? template.overlaySettings.defaultFontFamily
        : p.basename(template.overlaySettings.defaultFontPath!);
    final prefix = template.outputPrefix.trim().isEmpty ? 'soundswap' : template.outputPrefix.trim();

    return Card(
      margin: const EdgeInsets.only(bottom: 8),
      color: Theme.of(context).colorScheme.surfaceContainerLow,
      child: Padding(
        padding: const EdgeInsets.all(12.0),
        child: Row(
          children: [
            const Icon(Icons.dashboard_customize_outlined, size: 28, color: Colors.blue),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    template.name,
                    style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    [
                      '$textCount text overlays, $imageCount image overlays',
                      'Font: $fontName',
                      'Prefix: $prefix | Size: ${template.outputSize.label}',
                    ].join('\n'),
                    style: TextStyle(
                      fontSize: 11,
                      color: Theme.of(context).colorScheme.onSurfaceVariant.withValues(alpha: 0.8),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(width: 8),
            Wrap(
              spacing: 4,
              children: [
                OutlinedButton(
                  onPressed: onApply,
                  child: const Text('Apply'),
                ),
                IconButton(
                  tooltip: 'Rename',
                  onPressed: onRename,
                  icon: const Icon(Icons.edit, size: 20),
                ),
                IconButton(
                  tooltip: 'Delete',
                  onPressed: onDelete,
                  icon: const Icon(Icons.delete_outline, size: 20, color: Colors.red),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _TwoColumn extends StatelessWidget {
  const _TwoColumn({required this.left, required this.right});

  final Widget left;
  final Widget right;

  @override
  Widget build(BuildContext context) {
    final gap = AppResponsive.cardGap(context);
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Expanded(flex: 3, child: left),
        SizedBox(width: gap),
        Expanded(flex: 2, child: right),
      ],
    );
  }
}

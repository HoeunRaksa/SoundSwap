import 'package:flutter/material.dart';
import 'package:soundswap/core/responsive/app_responsive.dart';
import 'package:soundswap/features/overlay_tools/data/models/overlay_item.dart';
import 'package:soundswap/features/overlay_tools/presentation/state/overlay_tools_controller.dart';
import 'package:soundswap/features/templates/presentation/state/templates_controller.dart';
import 'package:soundswap/shared/widgets/feature_page.dart';
import 'package:soundswap/shared/widgets/overlay_preview_canvas.dart';
import 'package:soundswap/shared/widgets/empty_state.dart';
import '../widgets/overlay_layers_panel.dart';
import '../widgets/overlay_properties_panel.dart';
import '../widgets/overlay_templates_panel.dart';
import 'full_screen_editor_screen.dart';
import 'package:soundswap/features/home/presentation/state/home_controller.dart';
import 'package:soundswap/features/branding/presentation/state/branding_controller.dart';
import 'package:soundswap/features/text_overlay/presentation/state/text_overlay_controller.dart';
import 'package:soundswap/core/video/video_output_settings.dart';

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
  VideoOutputSize _previewSize = VideoOutputSize.vertical1080;
  bool _showGrid = false;
  bool _enableSnapping = true;
  double _zoomScale = 1.0;

  @override
  Widget build(BuildContext context) {
    final gap = AppResponsive.cardGap(context);

    return ListenableBuilder(
      listenable: widget.controller,
      builder: (context, _) {
        return ListenableBuilder(
          listenable: widget.templatesController,
          builder: (context, _) {
            
            final previewItems = [
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

            return FeaturePage(
              title: 'Overlay & Templates Studio',
              subtitle: 'Design overlays with layer folders, precise transforms, alignment tools, asset libraries, workspaces, and timeline animations.',
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
                        const SizedBox(
                          height: 24,
                          child: VerticalDivider(width: 1),
                        ),
                        const SizedBox(width: 8),
                        OutlinedButton.icon(
                          onPressed: () {
                            Navigator.of(context).push(
                              MaterialPageRoute(
                                builder: (context) => FullScreenEditorScreen(
                                  controller: widget.controller,
                                  templatesController: widget.templatesController,
                                  homeController: widget.homeController,
                                  brandingController: widget.brandingController,
                                  textOverlayController: widget.textOverlayController,
                                  outputSize: _previewSize,
                                ),
                              ),
                            );
                          },
                          icon: const Icon(Icons.fullscreen),
                          label: const Text('Full Screen Editor'),
                        ),
                        const Spacer(),
                      ],
                    ),
                  ),
                ),
                SizedBox(height: gap),

                // Main Workspace
                SizedBox(
                  height: 640,
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Preview Canvas
                      Expanded(
                        flex: 3,
                        child: Card(
                          child: Padding(
                            padding: const EdgeInsets.all(16.0),
                            child: Column(
                              children: [
                                Row(
                                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                  children: [
                                    const Text('Preview Canvas', style: TextStyle(fontWeight: FontWeight.bold)),
                                    Row(
                                      children: [
                                        const Text('Zoom:', style: TextStyle(fontSize: 12)),
                                        const SizedBox(width: 8),
                                        DropdownButton<double>(
                                          value: _zoomScale,
                                          isDense: true,
                                          underline: const SizedBox(),
                                          items: const [
                                            DropdownMenuItem(value: 0.25, child: Text('25%')),
                                            DropdownMenuItem(value: 0.5, child: Text('50%')),
                                            DropdownMenuItem(value: 1.0, child: Text('100%')),
                                            DropdownMenuItem(value: 2.0, child: Text('200%')),
                                          ],
                                          onChanged: (val) {
                                            if (val != null) setState(() => _zoomScale = val);
                                          },
                                        ),
                                      ],
                                    ),
                                  ],
                                ),
                                const Divider(),
                                Row(
                                  children: [
                                    Checkbox(
                                      value: _showGrid,
                                      onChanged: (val) => setState(() => _showGrid = val ?? false),
                                      visualDensity: VisualDensity.compact,
                                    ),
                                    const Text('Show Grid', style: TextStyle(fontSize: 12)),
                                    const SizedBox(width: 16),
                                    Checkbox(
                                      value: _enableSnapping,
                                      onChanged: (val) => setState(() => _enableSnapping = val ?? true),
                                      visualDensity: VisualDensity.compact,
                                    ),
                                    const Text('Enable Snapping', style: TextStyle(fontSize: 12)),
                                  ],
                                ),
                                SizedBox(height: gap),
                                Expanded(
                                  child: GestureDetector(
                                    onDoubleTap: () {
                                      Navigator.of(context).push(
                                        MaterialPageRoute(
                                          builder: (context) => FullScreenEditorScreen(
                                            controller: widget.controller,
                                            templatesController: widget.templatesController,
                                            homeController: widget.homeController,
                                            brandingController: widget.brandingController,
                                            textOverlayController: widget.textOverlayController,
                                            outputSize: _previewSize,
                                          ),
                                        ),
                                      );
                                    },
                                    child: RepaintBoundary(
                                      child: OverlayPreviewCanvas(
                                        outputSize: _previewSize,
                                        items: previewItems,
                                        selectedItemIds: widget.controller.selectedItemIds,
                                        showGrid: _showGrid,
                                        enableSnapping: _enableSnapping,
                                        zoomScale: _zoomScale,
                                        currentTime: widget.controller.currentTime,
                                        onSelected: widget.controller.selectItem,
                                        onPositionChanged: (id, pos) => widget.controller.moveItem(id, pos, saveToDisk: false),
                                        onWidthChanged: (id, w) => widget.controller.resizeItem(id, w, saveToDisk: false),
                                        onHeightReported: widget.controller.reportExactHeight,
                                        onMultiPositionChanged: (positions) {
                                          positions.forEach((id, pos) {
                                            widget.controller.moveItem(id, pos, saveToDisk: false);
                                          });
                                        },
                                        onSizeChanged: (id, w, h) {
                                          final match = widget.controller.settings.items.firstWhere((e) => e.id == id);
                                          widget.controller.updateItem(match.copyWith(width: w, customHeight: h), saveToDisk: false);
                                        },
                                        safeAreaPadding: widget.controller.settings.activeSafeArea,
                                        onDragEnd: widget.controller.saveSettingsToDisk,
                                      ),
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ),
                      SizedBox(width: gap),

                      // Tool Tabs
                      Expanded(
                        flex: 2,
                        child: Card(
                          child: DefaultTabController(
                            length: 5,
                            child: Column(
                              children: [
                                const TabBar(
                                  tabs: [
                                    Tab(icon: Icon(Icons.dashboard_customize), text: 'Templates'),
                                    Tab(icon: Icon(Icons.layers_outlined), text: 'Layers'),
                                    Tab(icon: Icon(Icons.transform), text: 'Transform'),
                                    Tab(icon: Icon(Icons.align_horizontal_center), text: 'Align'),
                                    Tab(icon: Icon(Icons.video_library), text: 'Assets'),
                                  ],
                                  labelStyle: TextStyle(fontSize: 11),
                                  indicatorSize: TabBarIndicatorSize.tab,
                                  isScrollable: true,
                                ),
                                Expanded(
                                  child: TabBarView(
                                    children: [
                                      OverlayTemplatesPanel(
                                        controller: widget.controller,
                                        templatesController: widget.templatesController,
                                        homeController: widget.homeController,
                                        brandingController: widget.brandingController,
                                        textOverlayController: widget.textOverlayController,
                                      ),
                                      OverlayLayersPanel(controller: widget.controller),
                                      OverlayPropertiesPanel(controller: widget.controller),
                                      _buildAlignTab(context),
                                      _buildAssetsTab(context),
                                    ],
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            );
          },
        );
      },
    );
  }

  Widget _buildAlignTab(BuildContext context) {
    final controller = widget.controller;
    return Padding(
      padding: const EdgeInsets.all(16.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text('Alignment Tools (${controller.selectedItemIds.length} layers selected)', style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13)),
          const SizedBox(height: 16),
          Wrap(
            spacing: 12,
            runSpacing: 12,
            children: [
              ElevatedButton.icon(onPressed: controller.selectedItemIds.isEmpty ? null : controller.alignLeft, icon: const Icon(Icons.align_horizontal_left), label: const Text('Left')),
              ElevatedButton.icon(onPressed: controller.selectedItemIds.isEmpty ? null : controller.alignCenterX, icon: const Icon(Icons.align_horizontal_center), label: const Text('Center H')),
              ElevatedButton.icon(onPressed: controller.selectedItemIds.isEmpty ? null : controller.alignRight, icon: const Icon(Icons.align_horizontal_right), label: const Text('Right')),
              ElevatedButton.icon(onPressed: controller.selectedItemIds.isEmpty ? null : controller.alignTop, icon: const Icon(Icons.align_vertical_top), label: const Text('Top')),
              ElevatedButton.icon(onPressed: controller.selectedItemIds.isEmpty ? null : controller.alignCenterY, icon: const Icon(Icons.align_vertical_center), label: const Text('Center V')),
              ElevatedButton.icon(onPressed: controller.selectedItemIds.isEmpty ? null : controller.alignBottom, icon: const Icon(Icons.align_vertical_bottom), label: const Text('Bottom')),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildAssetsTab(BuildContext context) {
    return const Center(child: Text('Assets Library (Coming Soon)'));
  }
}

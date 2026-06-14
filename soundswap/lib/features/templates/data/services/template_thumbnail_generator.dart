
import 'dart:io';
import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:path_provider/path_provider.dart';

import '../../../../shared/widgets/overlay_render_widget.dart';
import '../../../overlay_tools/data/models/overlay_item.dart';
import '../../../overlay_tools/utils/overlay_position_calculator.dart';
import '../../../overlay_tools/utils/template_render_data.dart';
import '../models/project_template.dart';

class TemplateThumbnailGenerator {
  static Future<String> generateThumbnail(
    ProjectTemplate template, {
    List<OverlayItem>? activeWorkspaceItems,
  }) async {
    final overlayItems = template.overlaySettings.items.isNotEmpty
        ? template.overlaySettings.items
        : (activeWorkspaceItems ?? []);

    final allItems = TemplateRenderData.buildItems(
      branding: template.useBranding ? template.branding : null,
      textOverlay: template.useTextOverlay ? template.textOverlay : null,
      overlaySettings: template.overlaySettings.copyWith(items: overlayItems),
    );

    debugPrint('overlay item count: ${allItems.length}');

    // Use full 1080x1920 canvas to ensure perfect text shaping and layout
    final logicalSize = const Size(1080, 1920); 

    // Pre-load images to ensure synchronous painting in the offline render tree
    final Map<String, ui.Image> loadedImages = {};
    for (final item in allItems.where((e) => !e.hidden)) {
      if (item.type == OverlayItemType.image && item.imagePath != null) {
        try {
          final file = File(item.imagePath!);
          if (file.existsSync()) {
            final bytes = await file.readAsBytes();
            final codec = await ui.instantiateImageCodec(bytes);
            final frame = await codec.getNextFrame();
            loadedImages[item.id] = frame.image;
            debugPrint('[TemplateThumbnailGenerator] Loaded image asset for item: ${item.id}');
          } else {
            debugPrint('[TemplateThumbnailGenerator] ERROR: Missing image path for thumbnail: ${item.imagePath}');
          }
        } catch (e) {
          debugPrint('[TemplateThumbnailGenerator] ERROR: Failed to load image ${item.imagePath}: $e');
        }
      }
    }

    final repaintBoundary = RenderRepaintBoundary();
    final buildOwner = BuildOwner(focusManager: FocusManager());
    final pipelineOwner = PipelineOwner();

    // Reconstruct the template UI
    final widget = Container(
      width: logicalSize.width,
      height: logicalSize.height,
      color: const Color(0xFF1E1E1E), // Soft dark gray background, not pitch black
      child: Stack(
        clipBehavior: Clip.none,
        children: [
          for (final item in allItems.where((e) => !e.hidden))
            _buildOverlayItem(item, logicalSize, loadedImages[item.id]),
        ],
      ),
    );

    final view = ui.PlatformDispatcher.instance.implicitView ?? ui.PlatformDispatcher.instance.views.first;

    final renderView = RenderView(
      view: view,
      child: RenderPositionedBox(alignment: Alignment.topLeft, child: repaintBoundary),
      configuration: ViewConfiguration(
        logicalConstraints: BoxConstraints.tight(logicalSize),
        devicePixelRatio: 1.0,
      ),
    );

    pipelineOwner.rootNode = renderView;
    renderView.prepareInitialFrame();

    final rootElement = RenderObjectToWidgetAdapter<RenderBox>(
      container: repaintBoundary,
      child: Directionality(
        textDirection: TextDirection.ltr,
        child: MediaQuery(
          data: const MediaQueryData(
            size: Size(1080, 1920),
            devicePixelRatio: 1.0,
            textScaler: TextScaler.noScaling,
          ),
          child: Material(
            type: MaterialType.transparency,
            child: UnconstrainedBox(
              alignment: Alignment.topLeft,
              child: widget,
            ),
          ),
        ),
      ),
    ).attachToRenderTree(buildOwner);

    buildOwner.buildScope(rootElement);
    buildOwner.finalizeTree();

    pipelineOwner.flushLayout();
    pipelineOwner.flushCompositingBits();
    pipelineOwner.flushPaint();

    // Capture at 0.25 scale to output a sharp 270x480 PNG
    final image = await repaintBoundary.toImage(pixelRatio: 0.25); 
    final byteData = await image.toByteData(format: ui.ImageByteFormat.png);

    final appDir = await getApplicationDocumentsDirectory();
    final cacheDir = Directory('${appDir.path}/template_thumbnails');
    if (!cacheDir.existsSync()) {
      cacheDir.createSync(recursive: true);
    }
    final fileName = 'thumb_${template.id}_v${template.version}.png';
    final file = File('${cacheDir.path}/$fileName');
    await file.writeAsBytes(byteData!.buffer.asUint8List());

    debugPrint('output file path: ${file.path}');
    debugPrint(file.existsSync() as String?);
    debugPrint(file.lengthSync() as String?);

    // Cleanup ui.Images
    for (final img in loadedImages.values) {
      img.dispose();
    }

    return file.path;
  }

  static Widget _buildOverlayItem(OverlayItem item, Size canvasSize, ui.Image? preloadedImage) {
    final pos = OverlayPositionCalculator.previewPosition(
      videoRect: Rect.fromLTWH(0, 0, canvasSize.width, canvasSize.height),
      xPercent: item.position.xPercent,
      yPercent: item.position.yPercent,
    );
    final width = canvasSize.width * item.width;

    Widget content;
    if (item.type == OverlayItemType.text) {
      const referenceHeight = 1920.0;
      final scale = canvasSize.height / referenceHeight;
      final fontSize = (item.fontSize * scale);
      final strokeWidth = (item.strokeWidth * scale);

      content = SizedBox(
        width: width,
        child: OverlayRenderWidget(
          text: item.text,
          fontFamily: item.fontFamily,
          bold: item.bold,
          italic: item.italic,
          fontSize: fontSize,
          colorHex: item.colorHex,
          textAlignment: item.textAlignment,
          shadow: item.shadow,
          backgroundBox: item.backgroundBox,
          lineHeight: item.lineHeight,
          letterSpacing: item.letterSpacing,
          strokeWidth: strokeWidth,
          strokeColorHex: item.strokeColorHex,
          backgroundBoxColorHex: item.backgroundBoxColorHex,
          shadowColorHex: item.shadowColorHex,
        ),
      );
    } else {
      // Image item using preloaded ui.Image for synchronous rendering!
      if (preloadedImage != null) {
        content = SizedBox(
          width: width,
          height: item.customHeight != null ? canvasSize.height * item.customHeight! : null,
          child: RawImage(
            image: preloadedImage,
            fit: BoxFit.contain,
          ),
        );
      } else {
        content = const SizedBox.shrink();
      }
    }

    return Positioned(
      left: pos.dx,
      top: pos.dy,
      child: Transform.rotate(
        angle: item.rotation * 3.141592653589793 / 180,
        child: Transform.scale(
          scaleX: item.scaleX,
          scaleY: item.scaleY,
          child: Opacity(
            opacity: item.opacity,
            child: content,
          ),
        ),
      ),
    );
  }
}

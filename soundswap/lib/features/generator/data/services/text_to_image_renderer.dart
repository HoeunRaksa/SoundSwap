import 'dart:io';
import 'dart:ui' as ui;
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:path_provider/path_provider.dart';
import 'package:soundswap/shared/widgets/overlay_render_widget.dart';

class TextToImageRenderer {
  /// Renders the shared OverlayRenderWidget into a transparent PNG and saves it to a temporary file.
  /// Returns the absolute path to the generated PNG.
  static Future<String> renderTextToPng({
    required String text,
    required double width,
    required String fontFamily,
    required bool bold,
    required bool italic,
    required double fontSize,
    required String colorHex,
    required String textAlignment,
    required bool shadow,
    required bool backgroundBox,
    double lineHeight = 1.2,
    double letterSpacing = 0.0,
    double strokeWidth = 0.0,
    required String strokeColorHex,
    required String backgroundBoxColorHex,
    required String shadowColorHex,
  }) async {
    debugPrint('PNG Renderer Applied Font - Family: $fontFamily, Bold: $bold, Italic: $italic, StrokeWidth: $strokeWidth');

    final widget = OverlayRenderWidget(
      text: text,
      fontFamily: fontFamily,
      bold: bold,
      italic: italic,
      fontSize: fontSize,
      colorHex: colorHex,
      textAlignment: textAlignment,
      shadow: shadow,
      backgroundBox: backgroundBox,
      lineHeight: lineHeight,
      letterSpacing: letterSpacing,
      strokeWidth: strokeWidth,
      strokeColorHex: strokeColorHex,
      backgroundBoxColorHex: backgroundBoxColorHex,
      shadowColorHex: shadowColorHex,
    );

    // Render widget to image off-screen
    final repaintBoundary = RenderRepaintBoundary();
    final buildOwner = BuildOwner(focusManager: FocusManager());
    final pipelineOwner = PipelineOwner();

    // Estimate height using TextPainter to provide constraints
    final color = _colorFromHex(colorHex);
    final textSpan = TextSpan(
      text: text,
      style: TextStyle(
        color: color,
        fontSize: fontSize,
        fontFamily: fontFamily,
        fontFamilyFallback: const ['Battambang', 'Hanuman', 'KhmerOS', 'Kantumruy', 'Noto Sans Khmer'],
        fontWeight: bold ? FontWeight.w700 : FontWeight.normal,
        fontStyle: italic ? FontStyle.italic : FontStyle.normal,
        height: lineHeight,
        letterSpacing: letterSpacing,
      ),
    );
    final textPainter = TextPainter(
      text: textSpan,
      textDirection: TextDirection.ltr,
      maxLines: 12,
    );
    final horizontalPadding = backgroundBox ? 8.0 : 0.0;
    final verticalPadding = backgroundBox ? 5.0 : 0.0;
    final layoutWidth = width - (horizontalPadding * 2);
    textPainter.layout(minWidth: layoutWidth, maxWidth: layoutWidth);
    final heightEstimate = textPainter.height + (verticalPadding * 2);

    final logicalSize = Size(width, heightEstimate + 10); // Add slight buffer

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
        child: UnconstrainedBox(
          alignment: Alignment.topLeft,
          child: SizedBox(
            width: width,
            child: widget,
          ),
        ),
      ),
    ).attachToRenderTree(buildOwner);

    buildOwner.buildScope(rootElement);
    buildOwner.finalizeTree();

    pipelineOwner.flushLayout();
    pipelineOwner.flushCompositingBits();
    pipelineOwner.flushPaint();

    final image = await repaintBoundary.toImage(pixelRatio: 1.0);
    final byteData = await image.toByteData(format: ui.ImageByteFormat.png);

    final tempDir = await getTemporaryDirectory();
    final fileName = 'text_overlay_${DateTime.now().microsecondsSinceEpoch}.png';
    final file = File('${tempDir.path}/$fileName');
    await file.writeAsBytes(byteData!.buffer.asUint8List());

    return file.path;
  }

  static Color _colorFromHex(String hexString) {
    final buffer = StringBuffer();
    if (hexString.length == 6 || hexString.length == 7) buffer.write('ff');
    buffer.write(hexString.replaceFirst('#', ''));
    final parsed = int.tryParse(buffer.toString(), radix: 16);
    return parsed == null ? Colors.white : Color(parsed);
  }
}

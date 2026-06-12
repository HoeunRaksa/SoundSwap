import 'dart:io';
import 'dart:ui' as ui;
import 'package:flutter/material.dart';
import 'package:path_provider/path_provider.dart';

class TextToImageRenderer {
  /// Renders text with complex styling (shadow, multiline wrapping, background box)
  /// into a transparent PNG and saves it to a temporary file.
  /// Returns the absolute path to the generated PNG.
  static Future<String> renderTextToPng({
    required String text,
    required double width,
    required String fontFamily,
    required String? fontPath,
    required double fontSize,
    required String colorHex,
    required String textAlignment,
    required bool shadow,
    required bool backgroundBox,
  }) async {
    final recorder = ui.PictureRecorder();
    final canvas = Canvas(recorder);

    final color = _colorFromHex(colorHex);
    final textAlign = switch (textAlignment) {
      'center' => TextAlign.center,
      'right' => TextAlign.right,
      _ => TextAlign.left,
    };

    final textSpan = TextSpan(
      text: text,
      style: TextStyle(
        color: color,
        fontSize: fontSize,
        fontFamily: (fontPath != null && fontPath.trim().isNotEmpty) ? null : fontFamily,
        fontWeight: FontWeight.w700,
        shadows: shadow
            ? const [
                Shadow(
                  blurRadius: 3,
                  offset: Offset(1, 1),
                  color: Colors.black87,
                ),
              ]
            : null,
      ),
    );

    final textPainter = TextPainter(
      text: textSpan,
      textDirection: TextDirection.ltr,
      textAlign: textAlign,
      maxLines: 12,
    );

    // Bounding width for text wrapping
    final horizontalPadding = backgroundBox ? 8.0 : 0.0;
    final verticalPadding = backgroundBox ? 5.0 : 0.0;
    final layoutWidth = width - (horizontalPadding * 2);

    textPainter.layout(minWidth: layoutWidth, maxWidth: layoutWidth);

    final rectWidth = width;
    final rectHeight = textPainter.height + (verticalPadding * 2);

    if (backgroundBox) {
      final bgPaint = Paint()..color = Colors.black.withValues(alpha: 0.48);
      canvas.drawRRect(
        RRect.fromRectAndRadius(
          Rect.fromLTWH(0, 0, rectWidth, rectHeight),
          const Radius.circular(4),
        ),
        bgPaint,
      );
    }

    textPainter.paint(canvas, Offset(horizontalPadding, verticalPadding));

    final picture = recorder.endRecording();
    final image = await picture.toImage(rectWidth.ceil(), rectHeight.ceil());
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
    return Color(int.parse(buffer.toString(), radix: 16));
  }
}

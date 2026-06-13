import 'package:flutter/material.dart';

class OverlayRenderWidget extends StatelessWidget {
  const OverlayRenderWidget({
    required this.text,
    required this.fontFamily,
    required this.bold,
    required this.italic,
    required this.fontSize,
    required this.colorHex,
    required this.textAlignment,
    required this.shadow,
    required this.backgroundBox,
    required this.lineHeight,
    required this.letterSpacing,
    this.strokeWidth = 0.0,
    this.strokeColorHex = '#000000',
    super.key,
  });

  final String text;
  final String fontFamily;
  final bool bold;
  final bool italic;
  final double fontSize;
  final String colorHex;
  final String textAlignment;
  final bool shadow;
  final bool backgroundBox;
  final double lineHeight;
  final double letterSpacing;
  final double strokeWidth;
  final String strokeColorHex;

  @override
  Widget build(BuildContext context) {
    final color = _colorFromHex(colorHex);
    final strokeColor = _colorFromHex(strokeColorHex);
    final textAlign = switch (textAlignment) {
      'center' => TextAlign.center,
      'right' => TextAlign.right,
      _ => TextAlign.left,
    };

    final hasStroke = strokeWidth > 0;

    final textWidget = hasStroke
        ? Stack(
            children: [
              // Stroke background text
              Text(
                text,
                maxLines: 12,
                overflow: TextOverflow.visible,
                textAlign: textAlign,
                style: TextStyle(
                  fontSize: fontSize,
                  fontFamily: fontFamily,
                  fontFamilyFallback: const ['Battambang', 'Hanuman', 'KhmerOS', 'Kantumruy', 'Noto Sans Khmer'],
                  fontWeight: bold ? FontWeight.w700 : FontWeight.normal,
                  fontStyle: italic ? FontStyle.italic : FontStyle.normal,
                  height: lineHeight,
                  letterSpacing: letterSpacing,
                  foreground: Paint()
                    ..style = PaintingStyle.stroke
                    ..strokeWidth = strokeWidth
                    ..color = strokeColor,
                ),
              ),
              // Filled text on top
              Text(
                text,
                maxLines: 12,
                overflow: TextOverflow.visible,
                textAlign: textAlign,
                style: TextStyle(
                  color: color,
                  fontSize: fontSize,
                  fontFamily: fontFamily,
                  fontFamilyFallback: const ['Battambang', 'Hanuman', 'KhmerOS', 'Kantumruy', 'Noto Sans Khmer'],
                  fontWeight: bold ? FontWeight.w700 : FontWeight.normal,
                  fontStyle: italic ? FontStyle.italic : FontStyle.normal,
                  height: lineHeight,
                  letterSpacing: letterSpacing,
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
              ),
            ],
          )
        : Text(
            text,
            maxLines: 12,
            overflow: TextOverflow.visible,
            textAlign: textAlign,
            style: TextStyle(
              color: color,
              fontSize: fontSize,
              fontFamily: fontFamily,
              fontFamilyFallback: const ['Battambang', 'Hanuman', 'KhmerOS', 'Kantumruy', 'Noto Sans Khmer'],
              fontWeight: bold ? FontWeight.w700 : FontWeight.normal,
              fontStyle: italic ? FontStyle.italic : FontStyle.normal,
              height: lineHeight,
              letterSpacing: letterSpacing,
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

    return DecoratedBox(
      decoration: BoxDecoration(
        color: backgroundBox ? Colors.black.withValues(alpha: 0.48) : Colors.transparent,
        borderRadius: BorderRadius.circular(4),
      ),
      child: Padding(
        padding: EdgeInsets.symmetric(
          horizontal: backgroundBox ? 8 : 0,
          vertical: backgroundBox ? 5 : 0,
        ),
        child: textWidget,
      ),
    );
  }

  Color _colorFromHex(String hexString) {
    final buffer = StringBuffer();
    if (hexString.length == 6 || hexString.length == 7) buffer.write('ff');
    buffer.write(hexString.replaceFirst('#', ''));
    final parsed = int.tryParse(buffer.toString(), radix: 16);
    return parsed == null ? Colors.white : Color(parsed);
  }
}

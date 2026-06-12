import 'package:flutter/material.dart';

class OverlayPositionCalculator {
  /// Calculates the exact pixel position for the Flutter preview canvas.
  static Offset previewPosition({
    required Rect videoRect,
    required double xPercent,
    required double yPercent,
  }) {
    return Offset(
      videoRect.left + videoRect.width * xPercent,
      videoRect.top + videoRect.height * yPercent,
    );
  }

  /// Calculates the exact absolute pixel position for FFmpeg export.
  static Offset exportPosition({
    required int outputWidth,
    required int outputHeight,
    required double xPercent,
    required double yPercent,
  }) {
    return Offset(
      outputWidth * xPercent,
      outputHeight * yPercent,
    );
  }

  /// Calculates the exact width in pixels for the preview canvas based on normalized percentage.
  static double previewWidth({
    required Rect videoRect,
    required double widthPercent,
  }) {
    return videoRect.width * widthPercent;
  }

  /// Calculates the exact width in pixels for FFmpeg export based on normalized percentage.
  static double exportWidth({
    required int outputWidth,
    required double widthPercent,
  }) {
    return outputWidth * widthPercent;
  }
}

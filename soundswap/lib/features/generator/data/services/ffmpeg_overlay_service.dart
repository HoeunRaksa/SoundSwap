import 'dart:convert';
import 'dart:io';

import 'package:soundswap/core/video/video_output_settings.dart';
import 'package:soundswap/features/branding/data/models/branding_settings.dart';
import 'package:soundswap/features/home/data/services/ffmpeg_service.dart';
import 'package:soundswap/features/overlay_tools/data/models/overlay_item.dart';
import 'package:soundswap/features/overlay_tools/data/models/overlay_settings.dart';
import 'package:soundswap/features/text_overlay/data/models/text_overlay_settings.dart';

class FfmpegOverlayService {
  FfmpegOverlayService({FfmpegService? ffmpegService})
    : _ffmpegService = ffmpegService ?? FfmpegService();

  final FfmpegService _ffmpegService;

  FfmpegOverlayPlan? prepareOverlay({
    required String inputPath,
    required String outputPath,
    required VideoOutputSize outputSize,
    required VideoFitMode fitMode,
    BrandingSettings? branding,
    TextOverlaySettings? textOverlay,
    OverlaySettings? overlaySettings,
  }) {
    final hasBranding = branding?.hasContent ?? false;
    final hasText = textOverlay?.hasContent ?? false;
    final hasOverlayItems = overlaySettings?.hasContent ?? false;
    final resizes = outputSize != VideoOutputSize.original;
    if (!hasBranding && !hasText && !hasOverlayItems && !resizes) {
      return null;
    }

    final arguments = <String>['-y', '-i', inputPath];
    var logoInputIndex = -1;
    if (branding?.hasLogo ?? false) {
      logoInputIndex = 1;
      arguments.addAll(['-i', branding!.logoPath!]);
    }
    final overlayImageInputIndexes = <String, int>{};
    for (final item in overlaySettings?.items ?? const <OverlayItem>[]) {
      if (item.type == OverlayItemType.image && item.imagePath != null) {
        overlayImageInputIndexes[item.id] = arguments
            .where((value) => value == '-i')
            .length;
        arguments.addAll(['-i', item.imagePath!]);
      }
    }

    final filterGraph = _buildFilterGraph(
      outputSize: outputSize,
      fitMode: fitMode,
      branding: branding,
      textOverlay: textOverlay,
      overlaySettings: overlaySettings,
      logoInputIndex: logoInputIndex,
      overlayImageInputIndexes: overlayImageInputIndexes,
    );

    arguments.addAll([
      '-filter_complex',
      filterGraph,
      '-map',
      '[vout]',
      '-map',
      '0:a?',
      '-c:v',
      'libx264',
      '-preset',
      'veryfast',
      '-crf',
      '18',
      '-c:a',
      'copy',
      '-movflags',
      '+faststart',
      outputPath,
    ]);

    return FfmpegOverlayPlan(
      arguments: arguments,
      command: _formatCommand(_ffmpegService.ffmpegPath, arguments),
      outputPath: outputPath,
    );
  }

  Future<ProcessRunOutput> runOverlay(FfmpegOverlayPlan plan) async {
    final result = await _runProcess(_ffmpegService.ffmpegPath, plan.arguments);
    if (result.exitCode != 0) {
      throw FfmpegFailure(
        command: plan.command,
        exitCode: result.exitCode,
        stderr: result.stderr,
        stdout: result.stdout,
      );
    }
    return result;
  }

  String _buildFilterGraph({
    required VideoOutputSize outputSize,
    required VideoFitMode fitMode,
    required BrandingSettings? branding,
    required TextOverlaySettings? textOverlay,
    required OverlaySettings? overlaySettings,
    required int logoInputIndex,
    required Map<String, int> overlayImageInputIndexes,
  }) {
    final filters = <String>[];
    var current = _baseVideoFilter(outputSize, fitMode, filters);
    var index = 0;

    if (branding?.hasLogo ?? false) {
      final logoWidth = _logoWidth(outputSize);
      final logoLabel = 'logo$index';
      filters.add('[$logoInputIndex:v]scale=$logoWidth:-1[$logoLabel]');
      final next = 'v${++index}';
      filters.add(
        '[$current][$logoLabel]overlay=x=main_w*${branding!.logoPosition.x.toStringAsFixed(5)}:y=main_h*${branding.logoPosition.y.toStringAsFixed(5)}[$next]',
      );
      current = next;
    }

    if (branding?.hasContactText ?? false) {
      final next = 'v${++index}';
      filters.add(
        '[$current]${_drawTextFilter(text: branding!.contactText, position: branding.textPosition, fontFamily: branding.fontFamily, fontPath: null, fontSize: branding.fontSize, colorHex: branding.textColor, shadow: true, backgroundBox: true)}[$next]',
      );
      current = next;
    }

    if (textOverlay != null) {
      for (final item in _textItems(textOverlay)) {
        final next = 'v${++index}';
        filters.add(
          '[$current]${_drawTextFilter(text: item.text, position: item.position, fontFamily: textOverlay.fontFamily, fontPath: null, fontSize: textOverlay.fontSize, colorHex: textOverlay.textColor, shadow: textOverlay.shadow, backgroundBox: textOverlay.backgroundBox)}[$next]',
        );
        current = next;
      }
    }

    if (overlaySettings != null) {
      for (final item in overlaySettings.items.where(
        (item) => item.hasContent,
      )) {
        if (item.type == OverlayItemType.image) {
          final inputIndex = overlayImageInputIndexes[item.id];
          if (inputIndex == null) continue;
          final overlayWidth = _overlayItemWidth(outputSize, item.width);
          final imageLabel = 'image${++index}';
          filters.add('[$inputIndex:v]scale=$overlayWidth:-1[$imageLabel]');
          final next = 'v${++index}';
          filters.add(
            '[$current][$imageLabel]overlay=x=main_w*${item.position.x.toStringAsFixed(5)}:y=main_h*${item.position.y.toStringAsFixed(5)}[$next]',
          );
          current = next;
          continue;
        }

        final next = 'v${++index}';
        filters.add(
          '[$current]${_drawTextFilter(text: item.text, position: item.position, fontFamily: item.fontFamily, fontPath: item.fontPath ?? overlaySettings.defaultFontPath, fontSize: item.fontSize, colorHex: item.colorHex, shadow: item.shadow, backgroundBox: item.backgroundBox)}[$next]',
        );
        current = next;
      }
    }

    filters.add('[$current]format=yuv420p[vout]');
    return filters.join(';');
  }

  String _baseVideoFilter(
    VideoOutputSize outputSize,
    VideoFitMode fitMode,
    List<String> filters,
  ) {
    final width = outputSize.width;
    final height = outputSize.height;
    if (width == null || height == null) {
      filters.add('[0:v]null[base]');
      return 'base';
    }

    final baseFilter = switch (fitMode) {
      VideoFitMode.keepOriginal =>
        'scale=$width:$height:force_original_aspect_ratio=decrease,pad=$width:$height:(ow-iw)/2:(oh-ih)/2:black',
      VideoFitMode.fitInsideBlurred =>
        'split[fg][bg];[bg]scale=$width:$height:force_original_aspect_ratio=increase,crop=$width:$height,gblur=sigma=28[blur];[fg]scale=$width:$height:force_original_aspect_ratio=decrease[fit];[blur][fit]overlay=(W-w)/2:(H-h)/2',
      VideoFitMode.fillCrop =>
        'scale=$width:$height:force_original_aspect_ratio=increase,crop=$width:$height',
      VideoFitMode.stretch => 'scale=$width:$height',
    };

    filters.add('[0:v]$baseFilter[base]');
    return 'base';
  }

  Iterable<({String text, NormalizedPosition position})> _textItems(
    TextOverlaySettings settings,
  ) sync* {
    if (settings.title.trim().isNotEmpty) {
      yield (text: settings.title, position: settings.titlePosition);
    }
    if (settings.subtitle.trim().isNotEmpty) {
      yield (text: settings.subtitle, position: settings.subtitlePosition);
    }
    if (settings.promotionText.trim().isNotEmpty) {
      yield (
        text: settings.promotionText,
        position: settings.promotionPosition,
      );
    }
    if (settings.priceText.trim().isNotEmpty) {
      yield (text: settings.priceText, position: settings.pricePosition);
    }
  }

  String _drawTextFilter({
    required String text,
    required NormalizedPosition position,
    required String fontFamily,
    required String? fontPath,
    required double fontSize,
    required String colorHex,
    required bool shadow,
    required bool backgroundBox,
  }) {
    final options = [
      'drawtext=text=\'${_escapeDrawText(text)}\'',
      if (fontPath != null && fontPath.trim().isNotEmpty)
        'fontfile=\'${_escapeDrawText(fontPath)}\''
      else
        'font=\'${_escapeDrawText(fontFamily)}\'',
      'fontsize=${fontSize.toStringAsFixed(0)}',
      'fontcolor=${_ffmpegColor(colorHex)}',
      'x=w*${position.x.toStringAsFixed(5)}',
      'y=h*${position.y.toStringAsFixed(5)}',
      if (shadow) 'shadowcolor=black@0.65:shadowx=2:shadowy=2',
      if (backgroundBox) 'box=1:boxcolor=black@0.42:boxborderw=16',
    ];
    return options.join(':');
  }

  int _logoWidth(VideoOutputSize outputSize) {
    return ((outputSize.width ?? 1080) * 0.18).round();
  }

  int _overlayItemWidth(VideoOutputSize outputSize, double width) {
    return ((outputSize.width ?? 1080) * width.clamp(0.08, 1)).round();
  }

  String _ffmpegColor(String value) {
    final normalized = value.replaceFirst('#', '').trim();
    return normalized.length == 6 ? '0x$normalized' : 'white';
  }

  String _escapeDrawText(String value) {
    return value
        .replaceAll('\\', r'\\')
        .replaceAll("'", r"\'")
        .replaceAll(':', r'\:')
        .replaceAll(',', r'\,')
        .replaceAll('\n', r'\n');
  }

  Future<ProcessRunOutput> _runProcess(
    String executable,
    List<String> arguments,
  ) async {
    late final Process process;
    try {
      process = await Process.start(executable, arguments);
    } on ProcessException catch (error) {
      throw FfmpegException(
        'Could not start $executable for overlay rendering.\n${error.message}',
      );
    }

    final stdoutBuffer = StringBuffer();
    final stderrBuffer = StringBuffer();
    final stdoutDone = process.stdout
        .transform(utf8.decoder)
        .forEach(stdoutBuffer.write);
    final stderrDone = process.stderr
        .transform(utf8.decoder)
        .forEach(stderrBuffer.write);
    final exitCode = await process.exitCode;

    await stdoutDone;
    await stderrDone;

    return ProcessRunOutput(
      exitCode: exitCode,
      stdout: stdoutBuffer.toString(),
      stderr: stderrBuffer.toString(),
    );
  }

  String _formatCommand(String executable, List<String> arguments) {
    return [executable, ...arguments.map(_quoteArgument)].join(' ');
  }

  String _quoteArgument(String argument) {
    if (!argument.contains(RegExp(r'[\s"]'))) {
      return argument;
    }
    return '"${argument.replaceAll('"', r'\"')}"';
  }
}

class FfmpegOverlayPlan {
  const FfmpegOverlayPlan({
    required this.arguments,
    required this.command,
    required this.outputPath,
  });

  final List<String> arguments;
  final String command;
  final String outputPath;
}

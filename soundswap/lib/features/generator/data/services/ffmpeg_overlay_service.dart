import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:soundswap/core/video/video_output_settings.dart';
import 'package:soundswap/features/branding/data/models/branding_settings.dart';
import 'package:soundswap/features/home/data/services/ffmpeg_service.dart';
import 'package:soundswap/features/overlay_tools/data/models/overlay_item.dart';
import 'package:soundswap/features/overlay_tools/data/models/overlay_settings.dart';
import 'package:soundswap/features/text_overlay/data/models/text_overlay_settings.dart';
import 'package:soundswap/features/effects/data/models/effects_settings.dart';

class FfmpegOverlayService {
  FfmpegOverlayService({FfmpegService? ffmpegService})
    : _ffmpegService = ffmpegService ?? FfmpegService();

  final FfmpegService _ffmpegService;

  Future<FfmpegOverlayPlan?> prepareOverlay({
    required String inputPath,
    required String outputPath,
    required VideoOutputSize outputSize,
    required VideoFitMode fitMode,
    BrandingSettings? branding,
    TextOverlaySettings? textOverlay,
    OverlaySettings? overlaySettings,
    EffectsSettings? effects,
  }) async {
    final hasBranding = branding?.hasContent ?? false;
    final hasText = textOverlay?.hasContent ?? false;
    final hasOverlayItems = overlaySettings?.hasContent ?? false;
    final resizes = outputSize != VideoOutputSize.original;
    final hasEffects = effects != null &&
        (effects.slightZoom ||
            effects.brightnessAdjustment ||
            effects.speedVariation);

    if (!hasBranding &&
        !hasText &&
        !hasOverlayItems &&
        !resizes &&
        !hasEffects) {
      return null;
    }

    int videoWidth = 1080;
    int videoHeight = 1920;
    try {
      final dims = await _ffmpegService.probeVideoDimensions(inputPath);
      videoWidth = dims.width;
      videoHeight = dims.height;
    } catch (_) {}

    final outW = outputSize.width ?? videoWidth;
    final outH = outputSize.height ?? videoHeight;

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
      outW: outW,
      outH: outH,
      outputSize: outputSize,
      fitMode: fitMode,
      branding: branding,
      textOverlay: textOverlay,
      overlaySettings: overlaySettings,
      logoInputIndex: logoInputIndex,
      overlayImageInputIndexes: overlayImageInputIndexes,
      effects: effects,
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
    required int outW,
    required int outH,
    required VideoOutputSize outputSize,
    required VideoFitMode fitMode,
    required BrandingSettings? branding,
    required TextOverlaySettings? textOverlay,
    required OverlaySettings? overlaySettings,
    required int logoInputIndex,
    required Map<String, int> overlayImageInputIndexes,
    EffectsSettings? effects,
  }) {
    final filters = <String>[];
    var current = _baseVideoFilter(outputSize, fitMode, filters);
    var index = 0;

    if (effects != null) {
      if (effects.slightZoom) {
        final next = 'v_zoom';
        filters.add('[$current]scale=iw*1.03:ih*1.03,crop=iw:ih[$next]');
        current = next;
      }
      if (effects.brightnessAdjustment) {
        final next = 'v_bright';
        filters.add('[$current]eq=brightness=0.04:saturation=1.05[$next]');
        current = next;
      }
      if (effects.speedVariation) {
        final next = 'v_speed';
        filters.add('[$current]setpts=PTS/1.02[$next]');
        current = next;
      }
    }

    if (branding?.hasLogo ?? false) {
      final logoWidth = _logoWidth(outW);
      final logoLabel = 'logo$index';
      filters.add('[$logoInputIndex:v]scale=$logoWidth:-1[$logoLabel]');
      final next = 'v${++index}';
      filters.add(
        '[$current][$logoLabel]overlay=x=main_w*${branding!.logoPosition.x.toStringAsFixed(5)}:y=main_h*${branding.logoPosition.y.toStringAsFixed(5)}:shortest=1[$next]',
      );
      current = next;
    }

    if (branding?.hasContactText ?? false) {
      final next = 'v${++index}';
      final scaledFontSize = branding!.fontSize * (outH / 1920.0);
      filters.add(
        '[$current]${_drawTextFilter(text: branding.contactText, position: branding.textPosition, fontFamily: branding.fontFamily, fontPath: null, fontSize: scaledFontSize, colorHex: branding.textColor, shadow: true, backgroundBox: true)}[$next]',
      );
      current = next;
    }

    if (textOverlay != null) {
      for (final item in _textItems(textOverlay)) {
        final next = 'v${++index}';
        final scaledFontSize = textOverlay.fontSize * (outH / 1920.0);
        filters.add(
          '[$current]${_drawTextFilter(text: item.text, position: item.position, fontFamily: textOverlay.fontFamily, fontPath: null, fontSize: scaledFontSize, colorHex: textOverlay.textColor, shadow: textOverlay.shadow, backgroundBox: textOverlay.backgroundBox)}[$next]',
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
          final overlayWidth = _overlayItemWidth(outW, item.width);
          final imageLabel = 'image${++index}';
          
          var scaleFilter = 'loop=loop=-1:size=1:start=0,scale=$overlayWidth:-1';
          if (item.animationEntrance == 'fade' || item.animationExit == 'fade') {
            final st = item.startTime;
            final ed = item.animationEntranceDuration;
            if (item.animationEntrance == 'fade') {
              scaleFilter = '$scaleFilter,fade=t=in:st=${st.toStringAsFixed(3)}:d=${ed.toStringAsFixed(3)}:alpha=1';
            }
            if (item.animationExit == 'fade' && item.endTime != null) {
              final et = item.endTime!;
              final exd = item.animationExitDuration;
              scaleFilter = '$scaleFilter,fade=t=out:st=${(et - exd).toStringAsFixed(3)}:d=${exd.toStringAsFixed(3)}:alpha=1';
            }
          }
          
          filters.add('[$inputIndex:v]$scaleFilter[$imageLabel]');
          
          final next = 'v${++index}';
          final xVal = _getPosXExpression(item, 'main_w', 'overlay_w');
          final yVal = _getPosYExpression(item, 'main_h', 'overlay_h');
          
          var overlayOpts = 'x=$xVal:y=$yVal:shortest=1';
          if (item.startTime > 0 || item.endTime != null) {
            overlayOpts = '$overlayOpts:enable=\'between(t,${item.startTime.toStringAsFixed(3)},${(item.endTime ?? 99999).toStringAsFixed(3)})\'';
          }
          
          filters.add('[$current][$imageLabel]overlay=$overlayOpts[$next]');
          current = next;
          continue;
        }

        final next = 'v${++index}';
        final scaledFontSize = item.fontSize * (outH / 1920.0);
        filters.add(
          '[$current]${_drawTextFilter(text: item.text, position: item.position, fontFamily: item.fontFamily, fontPath: item.fontPath ?? overlaySettings.defaultFontPath, fontSize: scaledFontSize, colorHex: item.colorHex, shadow: item.shadow, backgroundBox: item.backgroundBox, item: item)}[$next]',
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
    OverlayItem? item,
  }) {
    final xVal = item != null 
        ? _getPosXExpression(item, 'w', 'text_w') 
        : 'w*${position.x.toStringAsFixed(5)}';
    final yVal = item != null 
        ? _getPosYExpression(item, 'h', 'text_h') 
        : 'h*${position.y.toStringAsFixed(5)}';

    String colorStr = _ffmpegColor(colorHex);
    if (item != null && (item.animationEntrance == 'fade' || item.animationExit == 'fade')) {
      colorStr = '$colorStr@${_buildAlphaExpression(item)}';
    }

    final options = [
      'drawtext=text=\'${_escapeDrawText(text)}\'',
      if (fontPath != null && fontPath.trim().isNotEmpty)
        'fontfile=\'${_escapeDrawText(fontPath)}\''
      else
        'font=\'${_escapeDrawText(fontFamily)}\'',
      'fontsize=${fontSize.toStringAsFixed(0)}',
      'fontcolor=$colorStr',
      'x=$xVal',
      'y=$yVal',
      if (shadow) 'shadowcolor=black@0.65:shadowx=2:shadowy=2',
      if (backgroundBox) 'box=1:boxcolor=black@0.42:boxborderw=16',
      if (item != null && (item.startTime > 0 || item.endTime != null))
        'enable=\'between(t,${item.startTime.toStringAsFixed(3)},${(item.endTime ?? 99999).toStringAsFixed(3)})\'',
    ];
    return options.join(':');
  }

  String _buildAlphaExpression(OverlayItem item) {
    final st = item.startTime;
    final ed = item.animationEntranceDuration;
    final et = item.endTime;
    final exd = item.animationExitDuration;

    if (item.animationEntrance == 'fade' && item.animationExit == 'fade' && et != null) {
      return "if(lt(t,${st + ed}),(t-$st)/$ed,if(gt(t,${et - exd}),($et-t)/$exd,1))";
    } else if (item.animationEntrance == 'fade') {
      return "if(lt(t,${st + ed}),(t-$st)/$ed,1)";
    } else if (item.animationExit == 'fade' && et != null) {
      return "if(gt(t,${et - exd}),($et-t)/$exd,1)";
    }
    return "1";
  }

  String _getPosXExpression(OverlayItem item, String parentWVar, String selfWVar) {
    final st = item.startTime;
    final ed = item.animationEntranceDuration;
    final targetX = '$parentWVar*${item.position.x.toStringAsFixed(5)}';

    String expr = targetX;
    if (item.animationEntrance == 'slide_left') {
      expr = "if(lt(t,${st + ed}),-$selfWVar+($targetX+$selfWVar)*(t-$st)/$ed,$expr)";
    } else if (item.animationEntrance == 'slide_right') {
      expr = "if(lt(t,${st + ed}),$parentWVar+($targetX-$parentWVar)*(t-$st)/$ed,$expr)";
    }

    if (item.endTime != null) {
      final et = item.endTime!;
      final exd = item.animationExitDuration;
      if (item.animationExit == 'slide_left') {
        expr = "if(gt(t,${et - exd}),$targetX-($targetX+$selfWVar)*(t-($et-$exd))/$exd,$expr)";
      } else if (item.animationExit == 'slide_right') {
        expr = "if(gt(t,${et - exd}),$targetX+($parentWVar-$targetX)*(t-($et-$exd))/$exd,$expr)";
      }
    }
    return expr;
  }

  String _getPosYExpression(OverlayItem item, String parentHVar, String selfHVar) {
    final st = item.startTime;
    final ed = item.animationEntranceDuration;
    final targetY = '$parentHVar*${item.position.y.toStringAsFixed(5)}';

    String expr = targetY;
    if (item.animationEntrance == 'slide_down') {
      expr = "if(lt(t,${st + ed}),-$selfHVar+($targetY+$selfHVar)*(t-$st)/$ed,$expr)";
    } else if (item.animationEntrance == 'slide_up') {
      expr = "if(lt(t,${st + ed}),$parentHVar+($targetY-$parentHVar)*(t-$st)/$ed,$expr)";
    }

    if (item.endTime != null) {
      final et = item.endTime!;
      final exd = item.animationExitDuration;
      if (item.animationExit == 'slide_down') {
        expr = "if(gt(t,${et - exd}),$targetY-($targetY+$selfHVar)*(t-($et-$exd))/$exd,$expr)";
      } else if (item.animationExit == 'slide_up') {
        expr = "if(gt(t,${et - exd}),$targetY+($parentHVar-$targetY)*(t-($et-$exd))/$exd,$expr)";
      }
    }
    return expr;
  }

  int _logoWidth(int outW) {
    return (outW * 0.18).round();
  }

  int _overlayItemWidth(int outW, double width) {
    return (outW * width.clamp(0.01, 5.0)).round();
  }

  String _ffmpegColor(String value) {
    final normalized = value.replaceFirst('#', '').trim();
    return normalized.length == 6 ? '0x$normalized' : 'white';
  }

  String _escapeDrawText(String value) {
    final normalized = value.replaceAll('\\', '/');
    return normalized
        .replaceAll("'", r"\'")
        .replaceAll(':', r'\:')
        .replaceAll(',', r'\,')
        .replaceAll('\n', r'\n');
  }

  Future<ProcessRunOutput> _runProcess(
    String executable,
    List<String> arguments, {
    Duration inactivityTimeout = const Duration(seconds: 60),
  }) async {
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

    Timer? timer;
    bool timedOut = false;

    void resetTimer() {
      timer?.cancel();
      timer = Timer(inactivityTimeout, () {
        timedOut = true;
        process.kill();
      });
    }

    resetTimer();

    final stdoutCompleter = Completer<void>();
    process.stdout.transform(utf8.decoder).listen(
      (data) {
        stdoutBuffer.write(data);
        resetTimer();
      },
      onDone: () => stdoutCompleter.complete(),
      onError: (e) => stdoutCompleter.completeError(e),
    );

    final stderrCompleter = Completer<void>();
    process.stderr.transform(utf8.decoder).listen(
      (data) {
        stderrBuffer.write(data);
        resetTimer();
      },
      onDone: () => stderrCompleter.complete(),
      onError: (e) => stderrCompleter.completeError(e),
    );

    final exitCode = await process.exitCode;
    timer?.cancel();

    try {
      await stdoutCompleter.future;
      await stderrCompleter.future;
    } catch (_) {}

    if (timedOut) {
      throw const FfmpegException('Failed: FFmpeg timeout');
    }

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

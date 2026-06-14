import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:flutter/foundation.dart';

import 'package:soundswap/core/video/video_output_settings.dart';
import 'package:soundswap/features/branding/data/models/branding_settings.dart';
import 'package:soundswap/features/home/data/services/ffmpeg_service.dart';
import 'package:soundswap/features/overlay_tools/data/models/overlay_item.dart';
import 'package:soundswap/features/overlay_tools/data/models/overlay_settings.dart';
import 'package:soundswap/features/text_overlay/data/models/text_overlay_settings.dart';
import 'package:soundswap/features/effects/data/models/effects_settings.dart';
import 'package:soundswap/features/overlay_tools/utils/overlay_position_calculator.dart';
import 'package:soundswap/features/generator/data/services/text_to_image_renderer.dart';

import 'package:soundswap/features/overlay_tools/utils/template_render_data.dart';

class FfmpegOverlayService {
  FfmpegOverlayService({FfmpegService? ffmpegService})
    : _ffmpegService = ffmpegService ?? FfmpegService();

  final FfmpegService _ffmpegService;

  Process? _currentProcess;
  bool _isCancelled = false;

  void cancelCurrentProcess() {
    _isCancelled = true;
    _currentProcess?.kill();
  }
  
  void resetCancelFlag() {
    _isCancelled = false;
  }

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
    final tempFiles = <String>[];
    
    try {
      final allItems = TemplateRenderData.buildItems(
        branding: branding,
        textOverlay: textOverlay,
        overlaySettings: overlaySettings ?? const OverlaySettings(items: []),
      );

      final overlayImageInputIndexes = <String, int>{};
      for (final item in allItems) {
        if (!item.hasContent) continue;

        if (item.type == OverlayItemType.image && item.imagePath != null) {
          overlayImageInputIndexes[item.id] = arguments.where((value) => value == '-i').length;
          arguments.addAll(['-i', item.imagePath!]);
        } else if (item.type == OverlayItemType.text) {
          final textW = OverlayPositionCalculator.exportWidth(outputWidth: outW, widthPercent: item.width);
          final tempPng = await TextToImageRenderer.renderTextToPng(
            text: item.text,
            width: textW,
            fontFamily: item.fontFamily,
            bold: item.bold,
            italic: item.italic,
            fontSize: item.fontSize,
            colorHex: item.colorHex,
            textAlignment: item.textAlignment,
            shadow: item.shadow,
            backgroundBox: item.backgroundBox,
            lineHeight: item.lineHeight,
            letterSpacing: item.letterSpacing,
            strokeWidth: item.strokeWidth,
            strokeColorHex: item.strokeColorHex,
            backgroundBoxColorHex: item.backgroundBoxColorHex,
            shadowColorHex: item.shadowColorHex,
          );
          tempFiles.add(tempPng);
          overlayImageInputIndexes[item.id] = arguments.where((value) => value == '-i').length;
          arguments.addAll(['-i', tempPng]);
        }
      }

      final filterGraph = _buildFilterGraph(
        outW: outW,
        outH: outH,
        outputSize: outputSize,
        fitMode: fitMode,
        overlayItems: allItems,
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
        tempFiles: tempFiles,
      );
    } catch (e) {
      for (final path in tempFiles) {
        try {
          final file = File(path);
          if (file.existsSync()) file.deleteSync();
        } catch (_) {}
      }
      rethrow;
    }
  }

  Future<ProcessRunOutput> runOverlay(FfmpegOverlayPlan plan) async {
    try {
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
    } finally {
      for (final path in plan.tempFiles) {
        try {
          final file = File(path);
          if (file.existsSync()) file.deleteSync();
        } catch (_) {}
      }
    }
  }

  String _buildFilterGraph({
    required int outW,
    required int outH,
    required VideoOutputSize outputSize,
    required VideoFitMode fitMode,
    required List<OverlayItem> overlayItems,
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

    for (final item in overlayItems.where((item) => item.hasContent)) {
      final inputIndex = overlayImageInputIndexes[item.id];
      if (inputIndex == null) continue;
      
      final overlayWidth = _overlayItemWidth(outW, item.width);
      final imageLabel = 'item_${item.id.replaceAll("-", "")}$index';
      
      var scaleFilter = 'loop=loop=-1:size=1:start=0';
      scaleFilter += ',scale=$overlayWidth:-1';
      
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
      final xVal = _getPosXExpression(item, outW);
      final yVal = _getPosYExpression(item, outH);
      
      var overlayOpts = 'x=$xVal:y=$yVal:shortest=1';
      if (item.startTime > 0.001 || item.endTime != null) {
        final startStr = item.startTime.toStringAsFixed(3);
        final endStr = (item.endTime ?? 99999).toStringAsFixed(3);
        overlayOpts = '$overlayOpts:enable=\'between(t,$startStr,$endStr)\'';
      }

      debugPrint('--- OVERLAY TIMING DEBUG ---');
      debugPrint('Item ID: ${item.id}');
      debugPrint('Overlay Start: ${item.startTime}');
      debugPrint('Overlay End: ${item.endTime}');
      debugPrint('Entrance Transition: ${item.animationEntrance}');
      debugPrint('Exit Transition: ${item.animationExit}');
      debugPrint('Generated Enable Expression: $overlayOpts');
      debugPrint('----------------------------');
      
      filters.add('[$current][$imageLabel]overlay=$overlayOpts[$next]');
      current = next;
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



  String _getPosXExpression(OverlayItem item, int outW) {
    final st = item.startTime;
    final ed = item.animationEntranceDuration;
    final targetXExpr = OverlayPositionCalculator.exportPosition(
      outputWidth: outW,
      outputHeight: 0,
      xPercent: item.position.xPercent,
      yPercent: 0,
    ).dx.toStringAsFixed(2);

    String expr = targetXExpr;
    if (item.animationEntrance == 'slide_left') {
      expr = "if(lt(t,${st + ed}),-w+($targetXExpr+w)*(t-$st)/$ed,$expr)";
    } else if (item.animationEntrance == 'slide_right') {
      expr = "if(lt(t,${st + ed}),W+($targetXExpr-W)*(t-$st)/$ed,$expr)";
    }

    if (item.endTime != null) {
      final et = item.endTime!;
      final exd = item.animationExitDuration;
      if (item.animationExit == 'slide_left') {
        expr = "if(gt(t,${et - exd}),$targetXExpr-($targetXExpr+w)*(t-($et-$exd))/$exd,$expr)";
      } else if (item.animationExit == 'slide_right') {
        expr = "if(gt(t,${et - exd}),$targetXExpr+(W-$targetXExpr)*(t-($et-$exd))/$exd,$expr)";
      }
    }
    return expr;
  }

  String _getPosYExpression(OverlayItem item, int outH) {
    final st = item.startTime;
    final ed = item.animationEntranceDuration;
    final targetYExpr = OverlayPositionCalculator.exportPosition(
      outputWidth: 0,
      outputHeight: outH,
      xPercent: 0,
      yPercent: item.position.yPercent,
    ).dy.toStringAsFixed(2);

    String expr = targetYExpr;
    if (item.animationEntrance == 'slide_down') {
      expr = "if(lt(t,${st + ed}),-h+($targetYExpr+h)*(t-$st)/$ed,$expr)";
    } else if (item.animationEntrance == 'slide_up') {
      expr = "if(lt(t,${st + ed}),H+($targetYExpr-H)*(t-$st)/$ed,$expr)";
    }

    if (item.endTime != null) {
      final et = item.endTime!;
      final exd = item.animationExitDuration;
      if (item.animationExit == 'slide_down') {
        expr = "if(gt(t,${et - exd}),$targetYExpr-($targetYExpr+h)*(t-($et-$exd))/$exd,$expr)";
      } else if (item.animationExit == 'slide_up') {
        expr = "if(gt(t,${et - exd}),$targetYExpr+(H-$targetYExpr)*(t-($et-$exd))/$exd,$expr)";
      }
    }
    return expr;
  }



  int _overlayItemWidth(int outW, double width) {
    return (outW * width.clamp(0.01, 5.0)).round();
  }

  Future<ProcessRunOutput> _runProcess(
    String executable,
    List<String> arguments, {
    Duration inactivityTimeout = const Duration(seconds: 60),
  }) async {
    late final Process process;
    try {
      process = await Process.start(executable, arguments);
      _currentProcess = process;
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
    _currentProcess = null;
    timer?.cancel();

    try {
      await stdoutCompleter.future;
      await stderrCompleter.future;
    } catch (_) {}

    if (_isCancelled) {
      _isCancelled = false;
      throw const FfmpegCancelException();
    }

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
    this.tempFiles = const [],
  });

  final List<String> arguments;
  final String command;
  final String outputPath;
  final List<String> tempFiles;
}

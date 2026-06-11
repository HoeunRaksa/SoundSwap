import 'dart:async';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:path/path.dart' as p;
import 'package:soundswap/core/responsive/app_responsive.dart';
import 'package:soundswap/features/home/data/models/image_to_video_settings.dart';
import 'package:soundswap/features/home/data/models/media_file.dart';
import 'package:soundswap/features/home/presentation/widgets/folder_selector_card.dart';
import 'package:soundswap/features/long_video/data/models/long_video_plan.dart';
import 'package:soundswap/features/long_video/presentation/state/long_video_controller.dart';
import 'package:soundswap/shared/widgets/empty_state.dart';
import 'package:soundswap/shared/widgets/feature_page.dart';

import '../../../../core/video/video_output_settings.dart';

class LongVideoScreen extends StatefulWidget {
  const LongVideoScreen({required this.controller, super.key});

  final LongVideoController controller;

  @override
  State<LongVideoScreen> createState() => _LongVideoScreenState();
}

class _LongVideoScreenState extends State<LongVideoScreen> {
  late final TextEditingController _outputNameController;
  late final TextEditingController _targetController;
  late final TextEditingController _clipController;
  late final TextEditingController _numOutputsController;
  late final TextEditingController _imageDurationController;

  Timer? _outputNameDebounce;
  Timer? _targetDebounce;
  Timer? _clipDebounce;
  Timer? _numOutputsDebounce;
  Timer? _imageDurationDebounce;

  @override
  void initState() {
    super.initState();
    _outputNameController = TextEditingController(
      text: widget.controller.outputName,
    );
    _targetController = TextEditingController(
      text: widget.controller.targetMinutes.toStringAsFixed(0),
    );
    _clipController = TextEditingController(
      text: widget.controller.clipSeconds.toStringAsFixed(0),
    );
    _numOutputsController = TextEditingController(
      text: widget.controller.numOutputs.toString(),
    );
    _imageDurationController = TextEditingController(
      text: widget.controller.imageSettings.durationValue.toString(),
    );
  }

  @override
  void dispose() {
    _outputNameDebounce?.cancel();
    _targetDebounce?.cancel();
    _clipDebounce?.cancel();
    _numOutputsDebounce?.cancel();
    _imageDurationDebounce?.cancel();
    _outputNameController.dispose();
    _targetController.dispose();
    _clipController.dispose();
    _numOutputsController.dispose();
    _imageDurationController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: widget.controller,
      builder: (context, _) {
        return FeaturePage(
          title: 'Long Video Generator',
          subtitle:
              'Create long MP4 files by combining short videos, images, and audio with reliable duration control.',
          children: [
            ResponsiveLayout(
              small: Column(
                children: [
                  _settings(context),
                  SizedBox(height: AppResponsive.cardGap(context)),
                  _plan(context),
                ],
              ),
              medium: _TwoColumn(
                left: _settings(context),
                right: _plan(context),
              ),
              large: _TwoColumn(
                left: _settings(context),
                right: _plan(context),
              ),
            ),
            _progressSection(context),
          ],
        );
      },
    );
  }

  Widget _settings(BuildContext context) {
    final controller = widget.controller;
    final gap = AppResponsive.cardGap(context);
    final colorScheme = Theme.of(context).colorScheme;

    return SingleChildScrollView(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // 1. Folders Configuration
          _sectionCard(
            context,
            icon: Icons.folder_open_outlined,
            title: 'Workspace Directories',
            children: [
              _MultiFolderSelectorCard(
                title: 'Video folders',
                paths: controller.videoFolders,
                icon: Icons.video_library_outlined,
                onAdd: controller.pickVideoFolder,
                onRemove: controller.removeVideoFolder,
              ),
              SizedBox(height: gap),
              _MultiFolderSelectorCard(
                title: 'Audio folders',
                paths: controller.audioFolders,
                icon: Icons.library_music_outlined,
                onAdd: controller.pickAudioFolder,
                onRemove: controller.removeAudioFolder,
              ),
              SizedBox(height: gap),
              FolderSelectorCard(
                title: 'Output folder',
                path: controller.outputFolderPath,
                icon: Icons.folder_copy_outlined,
                onPressed: controller.pickOutputFolder,
              ),
            ],
          ),
          SizedBox(height: gap),

          // 2. Basic Settings
          _sectionCard(
            context,
            icon: Icons.tune,
            title: 'Basic Settings',
            children: [
              TextField(
                controller: _outputNameController,
                onChanged: (value) {
                  if (_outputNameDebounce?.isActive ?? false) _outputNameDebounce!.cancel();
                  _outputNameDebounce = Timer(const Duration(milliseconds: 300), () {
                    controller.setOutputName(value);
                  });
                },
                decoration: const InputDecoration(labelText: 'Output file name'),
              ),
              SizedBox(height: gap),
              TextField(
                controller: _numOutputsController,
                onChanged: (value) {
                  if (_numOutputsDebounce?.isActive ?? false) _numOutputsDebounce!.cancel();
                  _numOutputsDebounce = Timer(const Duration(milliseconds: 300), () {
                    controller.setNumOutputs(value);
                  });
                },
                keyboardType: TextInputType.number,
                decoration: const InputDecoration(
                  labelText: 'Number of videos to generate',
                  hintText: '1',
                  helperText: 'Creates output-1.mp4, output-2.mp4, etc.',
                ),
              ),
              SizedBox(height: gap),
              Row(
                children: [
                  Expanded(
                    child: TextField(
                      controller: _targetController,
                      onChanged: (value) {
                        if (_targetDebounce?.isActive ?? false) _targetDebounce!.cancel();
                        _targetDebounce = Timer(const Duration(milliseconds: 300), () {
                          controller.setTargetMinutes(value);
                        });
                      },
                      keyboardType: TextInputType.number,
                      decoration: const InputDecoration(
                        labelText: 'Target length (minutes)',
                      ),
                    ),
                  ),
                  SizedBox(width: gap),
                  Expanded(
                    child: TextField(
                      controller: _clipController,
                      onChanged: (value) {
                        if (_clipDebounce?.isActive ?? false) _clipDebounce!.cancel();
                        _clipDebounce = Timer(const Duration(milliseconds: 300), () {
                          controller.setClipSeconds(value);
                        });
                      },
                      keyboardType: TextInputType.number,
                      decoration: const InputDecoration(
                        labelText: 'Max clip length (seconds)',
                      ),
                    ),
                  ),
                ],
              ),
              SizedBox(height: gap),
              DropdownButtonFormField<LongVideoDurationMode>(
                key: ValueKey(controller.durationMode),
                initialValue: controller.durationMode,
                isExpanded: true,
                decoration: const InputDecoration(
                  labelText: 'Duration mode',
                  helperText: 'Controls how the final video length is determined',
                ),
                items: const [
                  DropdownMenuItem(
                    value: LongVideoDurationMode.exactTargetLength,
                    child: Text('Exact target length'),
                  ),
                  DropdownMenuItem(
                    value: LongVideoDurationMode.matchAudioLength,
                    child: Text('Match audio length'),
                  ),
                  DropdownMenuItem(
                    value: LongVideoDurationMode.matchVideoPlanLength,
                    child: Text('Match video plan length'),
                  ),
                  DropdownMenuItem(
                    value: LongVideoDurationMode.useShortest,
                    child: Text('Use shortest (video vs audio)'),
                  ),
                  DropdownMenuItem(
                    value: LongVideoDurationMode.useLongest,
                    child: Text('Use longest (video vs audio)'),
                  ),
                ],
                onChanged: (value) {
                  if (value != null) controller.setDurationMode(value);
                },
              ),
            ],
          ),
          SizedBox(height: gap),

          // 3. Image Integration Settings
          Card(
            clipBehavior: Clip.antiAlias,
            elevation: 0,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(AppResponsive.cardRadius(context)),
              side: BorderSide(color: colorScheme.outlineVariant.withValues(alpha: 0.7)),
            ),
            child: ExpansionTile(
              title: Text(
                'Image integration',
                style: TextStyle(
                  fontSize: AppResponsive.bodySize(context),
                  fontWeight: FontWeight.bold,
                  color: colorScheme.onSurface,
                ),
              ),
              leading: Icon(
                Icons.image_outlined,
                color: controller.useImages ? Colors.green.shade700 : colorScheme.primary,
              ),
              trailing: Switch(
                value: controller.useImages,
                onChanged: controller.setUseImages,
              ),
              children: [
                if (controller.useImages)
                  Padding(
                    padding: EdgeInsets.fromLTRB(gap, 0, gap, gap),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        _MultiFolderSelectorCard(
                          title: 'Image folders',
                          paths: controller.imageFolders,
                          icon: Icons.image_outlined,
                          onAdd: controller.pickImageFolder,
                          onRemove: controller.removeImageFolder,
                        ),
                        SizedBox(height: gap),
                        Row(
                          children: [
                            Expanded(
                              child: TextField(
                                controller: _imageDurationController,
                                onChanged: (value) {
                                  if (_imageDurationDebounce?.isActive ?? false) _imageDurationDebounce!.cancel();
                                  _imageDurationDebounce = Timer(const Duration(milliseconds: 300), () {
                                    controller.setImageDurationValue(value);
                                  });
                                },
                                keyboardType: TextInputType.number,
                                decoration: const InputDecoration(
                                  labelText: 'Image clip duration',
                                ),
                              ),
                            ),
                            SizedBox(width: gap),
                            Expanded(
                              child: DropdownButtonFormField<ImageDurationUnit>(
                                initialValue: controller.imageSettings.durationUnit,
                                isExpanded: true,
                                decoration: const InputDecoration(labelText: 'Unit'),
                                items: [
                                  for (final unit in ImageDurationUnit.values)
                                    DropdownMenuItem(value: unit, child: Text(unit.label)),
                                ],
                                onChanged: (value) {
                                  if (value != null) controller.setImageDurationUnit(value);
                                },
                              ),
                            ),
                          ],
                        ),
                        SizedBox(height: gap),
                        DropdownButtonFormField<ImageFitMode>(
                          initialValue: controller.imageSettings.fitMode,
                          isExpanded: true,
                          decoration: const InputDecoration(labelText: 'Image fit mode'),
                          items: [
                            for (final mode in ImageFitMode.values)
                              DropdownMenuItem(value: mode, child: Text(mode.label)),
                          ],
                          onChanged: (value) {
                            if (value != null) controller.setImageFitMode(value);
                          },
                        ),
                      ],
                    ),
                  )
                else
                  Padding(
                    padding: EdgeInsets.fromLTRB(gap, 0, gap, gap),
                    child: Text(
                      'Enable to mix imported images into the video timeline. Each image becomes a video clip of your chosen duration.',
                      style: TextStyle(
                        fontSize: AppResponsive.bodySize(context) - 2,
                        color: colorScheme.onSurfaceVariant,
                      ),
                    ),
                  ),
              ],
            ),
          ),
          SizedBox(height: gap),

          // Overlays & Templates Settings
          Card(
            clipBehavior: Clip.antiAlias,
            elevation: 0,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(AppResponsive.cardRadius(context)),
              side: BorderSide(color: colorScheme.outlineVariant.withValues(alpha: 0.7)),
            ),
            child: ExpansionTile(
              title: Text(
                'Overlays & Templates',
                style: TextStyle(
                  fontSize: AppResponsive.bodySize(context),
                  fontWeight: FontWeight.bold,
                  color: colorScheme.onSurface,
                ),
              ),
              leading: Icon(
                Icons.layers_outlined,
                color: (controller.useOverlays || controller.useTemplate)
                    ? Colors.green.shade700
                    : colorScheme.primary,
              ),
              initiallyExpanded: controller.useOverlays || controller.useTemplate,
              children: [
                Padding(
                  padding: EdgeInsets.fromLTRB(gap, 0, gap, gap),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      // Mode details banner
                      Container(
                        padding: const EdgeInsets.all(8),
                        decoration: BoxDecoration(
                          color: (controller.useOverlays || controller.useTemplate)
                              ? Colors.orange.withValues(alpha: 0.08)
                              : Colors.green.withValues(alpha: 0.08),
                          borderRadius: BorderRadius.circular(6),
                          border: Border.all(
                            color: (controller.useOverlays || controller.useTemplate)
                                ? Colors.orange.withValues(alpha: 0.4)
                                : Colors.green.withValues(alpha: 0.4),
                          ),
                        ),
                        child: Row(
                          children: [
                            Icon(
                              (controller.useOverlays || controller.useTemplate)
                                  ? Icons.warning_amber_rounded
                                  : Icons.flash_on,
                              size: 16,
                              color: (controller.useOverlays || controller.useTemplate)
                                  ? Colors.orange.shade700
                                  : Colors.green.shade700,
                            ),
                            const SizedBox(width: 8),
                            Expanded(
                              child: Text(
                                (controller.useOverlays || controller.useTemplate)
                                    ? 'Re-encode Mode because overlay/template is enabled.'
                                    : 'Fast Copy Mode (Fastest possible export mode)',
                                style: TextStyle(
                                  fontSize: 12,
                                  fontWeight: FontWeight.w600,
                                  color: (controller.useOverlays || controller.useTemplate)
                                      ? Colors.orange.shade800
                                      : Colors.green.shade800,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                      SizedBox(height: gap),
                      // Use Overlays row
                      CheckboxListTile(
                        title: const Text('Use Overlays'),
                        value: controller.useOverlays,
                        onChanged: (val) {
                          if (val != null) {
                            controller.setUseOverlays(val);
                            if (val) {
                              controller.setUseTemplate(false);
                            }
                          }
                        },
                        contentPadding: EdgeInsets.zero,
                        controlAffinity: ListTileControlAffinity.leading,
                      ),
                      if (controller.useOverlays) ...[
                        DropdownButtonFormField<String>(
                          initialValue: controller.selectedOverlayPreset,
                          isExpanded: true,
                          decoration: const InputDecoration(labelText: 'Overlay preset'),
                          items: const [
                            DropdownMenuItem(
                              value: 'current_overlays',
                              child: Text('Use current overlays'),
                            ),
                          ],
                          onChanged: (value) {
                            if (value != null) controller.setSelectedOverlayPreset(value);
                          },
                        ),
                        SizedBox(height: gap),
                      ],
                      // Use Template row
                      CheckboxListTile(
                        title: const Text('Use Template'),
                        value: controller.useTemplate,
                        onChanged: (val) {
                          if (val != null) {
                            controller.setUseTemplate(val);
                            if (val) {
                              controller.setUseOverlays(false);
                            }
                          }
                        },
                        contentPadding: EdgeInsets.zero,
                        controlAffinity: ListTileControlAffinity.leading,
                      ),
                      if (controller.useTemplate) ...[
                        DropdownButtonFormField<String>(
                          key: ValueKey(controller.selectedTemplateId),
                          initialValue: controller.selectedTemplateId,
                          isExpanded: true,
                          decoration: const InputDecoration(labelText: 'Template'),
                          hint: Text(
                            controller.templates.isEmpty ? 'No templates saved' : 'Select template',
                          ),
                          items: [
                            for (final t in controller.templates)
                              DropdownMenuItem(value: t.id, child: Text(t.name)),
                          ],
                          onChanged: (value) {
                            controller.setSelectedTemplateId(value);
                          },
                        ),
                      ],
                    ],
                  ),
                ),
              ],
            ),
          ),
          SizedBox(height: gap),

          // 4. Advanced Settings
          Card(
            clipBehavior: Clip.antiAlias,
            elevation: 0,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(AppResponsive.cardRadius(context)),
              side: BorderSide(color: colorScheme.outlineVariant.withValues(alpha: 0.7)),
            ),
            child: ExpansionTile(
              title: Text(
                'Advanced settings',
                style: TextStyle(
                  fontSize: AppResponsive.bodySize(context),
                  fontWeight: FontWeight.bold,
                  color: colorScheme.onSurface,
                ),
              ),
              leading: Icon(Icons.settings_suggest_outlined, color: colorScheme.primary),
              children: [
                Padding(
                  padding: EdgeInsets.fromLTRB(gap, 0, gap, gap),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      DropdownButtonFormField<VideoOutputSize>(
                        initialValue: controller.outputSize,
                        isExpanded: true,
                        decoration: const InputDecoration(labelText: 'Output size'),
                        items: [
                          for (final size in VideoOutputSize.values)
                            DropdownMenuItem(value: size, child: Text(size.label)),
                        ],
                        onChanged: (value) {
                          if (value != null) controller.setOutputSize(value);
                        },
                      ),
                      SizedBox(height: gap),
                      DropdownButtonFormField<VideoFitMode>(
                        initialValue: controller.fitMode,
                        isExpanded: true,
                        decoration: const InputDecoration(labelText: 'Fit mode'),
                        items: [
                          for (final mode in VideoFitMode.values)
                            DropdownMenuItem(value: mode, child: Text(mode.label)),
                        ],
                        onChanged: (value) {
                          if (value != null) controller.setFitMode(value);
                        },
                      ),
                      SizedBox(height: gap),
                      DropdownButtonFormField<LongVideoAudioMode>(
                        initialValue: controller.audioMode,
                        isExpanded: true,
                        decoration: const InputDecoration(labelText: 'Audio selection'),
                        items: const [
                          DropdownMenuItem(
                            value: LongVideoAudioMode.selectedFile,
                            child: Text('Use one selected audio file'),
                          ),
                          DropdownMenuItem(
                            value: LongVideoAudioMode.randomFromFolder,
                            child: Text('Pick random audio from folder'),
                          ),
                        ],
                        onChanged: (value) {
                          if (value != null) controller.setAudioMode(value);
                        },
                      ),
                      if (controller.audios.isNotEmpty) ...[
                        SizedBox(height: gap),
                        DropdownButtonFormField<String>(
                          initialValue: controller.selectedAudioPath,
                          isExpanded: true,
                          decoration: const InputDecoration(labelText: 'Selected audio file'),
                          items: [
                            for (final audio in controller.audios)
                              DropdownMenuItem(value: audio.path, child: Text(audio.name)),
                          ],
                          onChanged: controller.setSelectedAudio,
                        ),
                      ],
                      SizedBox(height: gap),
                      DropdownButtonFormField<LongVideoAudioBehavior>(
                        key: ValueKey(controller.audioBehavior),
                        initialValue: controller.audioBehavior,
                        isExpanded: true,
                        decoration: const InputDecoration(
                          labelText: 'Audio behavior',
                          helperText: 'What to do when audio is shorter than the video',
                        ),
                        items: const [
                          DropdownMenuItem(
                            value: LongVideoAudioBehavior.trimToFinalVideo,
                            child: Text('Trim audio to final video length'),
                          ),
                          DropdownMenuItem(
                            value: LongVideoAudioBehavior.loopToFinalVideo,
                            child: Text('Loop audio to fill video'),
                          ),
                          DropdownMenuItem(
                            value: LongVideoAudioBehavior.randomFillToFinalVideo,
                            child: Text('Fill with random audio tracks'),
                          ),
                          DropdownMenuItem(
                            value: LongVideoAudioBehavior.silenceWhenAudioEnds,
                            child: Text('Silence when audio ends'),
                          ),
                        ],
                        onChanged: (value) {
                          if (value != null) controller.setAudioBehavior(value);
                        },
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          SizedBox(height: gap * 1.5),

          // 5. Actions
          _buildActions(context),
          if (controller.message != null) ...[
            SizedBox(height: gap),
            Text(
              controller.message!,
              style: TextStyle(
                color: colorScheme.primary,
                fontWeight: FontWeight.bold,
              ),
            ),
          ],
          if (controller.errorMessage != null) ...[
            SizedBox(height: gap),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: colorScheme.errorContainer,
                borderRadius: BorderRadius.circular(8),
              ),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Icon(Icons.error_outline, color: colorScheme.error),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      controller.errorMessage!,
                      style: TextStyle(color: colorScheme.error, fontWeight: FontWeight.bold),
                    ),
                  ),
                ],
              ),
            ),
          ],
          SizedBox(height: gap),
        ],
      ),
    );
  }

  Widget _buildActions(BuildContext context) {
    final controller = widget.controller;
    final gap = AppResponsive.cardGap(context);

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 4.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            children: [
              Expanded(
                flex: 2,
                child: FilledButton.icon(
                  onPressed: controller.isPlanning || controller.isExporting
                      ? null
                      : controller.generatePlan,
                  icon: controller.isPlanning
                      ? const SizedBox(
                          width: 18,
                          height: 18,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        )
                      : const Icon(Icons.auto_awesome),
                  label: Text(controller.isPlanning ? 'Planning...' : 'Generate Plan'),
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                flex: 3,
                child: controller.isExporting
                    ? FilledButton.icon(
                        onPressed: controller.stopExport,
                        style: FilledButton.styleFrom(
                          backgroundColor: Colors.red.shade700,
                          foregroundColor: Colors.white,
                        ),
                        icon: const Icon(Icons.stop),
                        label: Text(
                          'Stop  (${controller.currentExportIndex}/${controller.numOutputs})',
                        ),
                      )
                    : FilledButton.icon(
                        onPressed: controller.canExport ? controller.startExport : null,
                        style: FilledButton.styleFrom(
                          backgroundColor: Colors.green.shade700,
                          foregroundColor: Colors.white,
                        ),
                        icon: const Icon(Icons.play_arrow),
                        label: Text(
                          controller.numOutputs > 1
                              ? 'Export ${controller.numOutputs} Videos'
                              : 'Start Export',
                        ),
                      ),
              ),
            ],
          ),
          SizedBox(height: gap / 2),
          OutlinedButton.icon(
            onPressed: controller.isExporting ? null : controller.clearPlan,
            icon: const Icon(Icons.clear),
            label: const Text('Clear Plan'),
          ),
        ],
      ),
    );
  }

  Widget _plan(BuildContext context) {
    final controller = widget.controller;
    final plan = controller.plan;
    final summary = controller.planSummary;

    if (plan == null) {
      return SettingsSection(
        title: 'Plan Preview',
        icon: Icons.view_list_outlined,
        children: [
          const SizedBox(
            height: 260,
            child: EmptyState(
              icon: Icons.playlist_add,
              title: 'No plan yet',
              message: 'Choose folders and click Generate Plan.',
            ),
          ),
        ],
      );
    }

    return SettingsSection(
      title: 'Plan Preview',
      icon: Icons.view_list_outlined,
      children: [
        // Summary card
        if (summary != null) _planSummaryCard(context, summary),
        const SizedBox(height: 12),
        Text('Output: ${p.basename(plan.outputPath)}',
            style: Theme.of(context).textTheme.bodySmall),
        const Divider(),
        Text('Video clips  (${plan.clips.length})',
            style: Theme.of(context).textTheme.titleSmall),
        SizedBox(
          height: 200,
          child: ListView.builder(
            itemCount: plan.clips.length,
            itemBuilder: (context, i) {
              final clip = plan.clips[i];
              final isImage = MediaFile(path: clip.videoPath).isImage;
              return ListTile(
                dense: true,
                leading: Icon(
                  isImage ? Icons.image_outlined : Icons.movie_outlined,
                  size: 18,
                ),
                title: Text(clip.name,
                    maxLines: 1, overflow: TextOverflow.ellipsis),
                subtitle: Text(
                  '${clip.clipDuration.toStringAsFixed(2)}s'
                  '${clip.clipDuration < clip.sourceDuration ? ' (trimmed from ${clip.sourceDuration.toStringAsFixed(1)}s)' : ''}',
                ),
                trailing: isImage
                    ? Container(
                        padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                        decoration: BoxDecoration(
                          color: Colors.purple.withValues(alpha: 0.15),
                          borderRadius: BorderRadius.circular(4),
                        ),
                        child: const Text('IMG',
                            style: TextStyle(fontSize: 10, color: Colors.purple)),
                      )
                    : null,
              );
            },
          ),
        ),
        const Divider(),
        Text('Audio segments  (${plan.audioSegments.length})',
            style: Theme.of(context).textTheme.titleSmall),
        SizedBox(
          height: 140,
          child: ListView.builder(
            itemCount: plan.audioSegments.length,
            itemBuilder: (context, i) {
              final audio = plan.audioSegments[i];
              return ListTile(
                dense: true,
                leading: const Icon(Icons.audiotrack_outlined, size: 18),
                title: Text(p.basename(audio.audioPath),
                    maxLines: 1, overflow: TextOverflow.ellipsis),
                subtitle: Text(
                  '${audio.segmentDuration.toStringAsFixed(2)}s'
                  '${audio.segmentDuration < audio.sourceDuration ? ' (trimmed)' : ''}',
                ),
              );
            },
          ),
        ),
      ],
    );
  }

  Widget _planSummaryCard(BuildContext context, LongVideoPlanSummary summary) {
    final colorScheme = Theme.of(context).colorScheme;

    return Container(
      decoration: BoxDecoration(
        color: summary.hasMismatch
            ? Colors.orange.withValues(alpha: 0.08)
            : colorScheme.primaryContainer.withValues(alpha: 0.3),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(
          color: summary.hasMismatch
              ? Colors.orange.withValues(alpha: 0.5)
              : colorScheme.primaryContainer,
        ),
      ),
      padding: const EdgeInsets.all(14),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(
                summary.hasMismatch
                    ? Icons.warning_amber_rounded
                    : Icons.check_circle_outline,
                color: summary.hasMismatch ? Colors.orange.shade700 : Colors.green.shade700,
                size: 18,
              ),
              const SizedBox(width: 8),
              Text(
                summary.hasMismatch ? 'Plan Summary — Mismatch Detected' : 'Plan Summary',
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 13,
                  color: summary.hasMismatch ? Colors.orange.shade800 : colorScheme.onSurface,
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          _summaryRow(context, 'Target length', summary.targetLabel),
          _summaryRow(context, 'Planned video length', summary.plannedVideoLabel),
          _summaryRow(context, 'Planned audio length', summary.plannedAudioLabel),
          _summaryRow(context, 'Estimated final duration', summary.estimatedLabel,
              highlight: summary.hasMismatch),
          _summaryRow(context, 'Video clips', '${summary.numVideoClips}'),
          _summaryRow(context, 'Image clips', '${summary.numImageClips}'),
          _summaryRow(context, 'Total clips', '${summary.totalClips}'),
          if (summary.hasMismatch) ...[
            const SizedBox(height: 8),
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: Colors.orange.withValues(alpha: 0.12),
                borderRadius: BorderRadius.circular(6),
              ),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Icon(Icons.info_outline, size: 14, color: Colors.orange),
                  const SizedBox(width: 6),
                  Expanded(
                    child: Text(
                      '⚠ ${summary.mismatchSeconds.toStringAsFixed(1)}s mismatch detected. '
                      'This may happen if there are not enough unique clips to reach the '
                      'target length. Consider adding more video files to the folder.',
                      style: const TextStyle(fontSize: 11, color: Colors.orange),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _summaryRow(BuildContext context, String label, String value,
      {bool highlight = false}) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 2),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label,
              style: TextStyle(
                  fontSize: 12, color: Theme.of(context).colorScheme.onSurfaceVariant)),
          Text(
            value,
            style: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.bold,
              color: highlight ? Colors.orange.shade700 : null,
            ),
          ),
        ],
      ),
    );
  }

  Widget _progressSection(BuildContext context) {
    final controller = widget.controller;
    final gap = AppResponsive.cardGap(context);
    final colorScheme = Theme.of(context).colorScheme;

    return SettingsSection(
      title: 'Export Progress',
      icon: Icons.terminal_outlined,
      children: [
        if (controller.isExporting) ...[
          Row(
            children: [
              const SizedBox(
                width: 16,
                height: 16,
                child: CircularProgressIndicator(strokeWidth: 2),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Text(
                  'Video ${controller.currentExportIndex} of ${controller.numOutputs}'
                  '${controller.currentClipLabel.isNotEmpty ? '  •  ${controller.currentClipLabel}' : ''}',
                  style: const TextStyle(fontWeight: FontWeight.w600),
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ],
          ),
          SizedBox(height: gap / 2),
          LinearProgressIndicator(
            value: controller.numOutputs > 0
                ? controller.currentExportIndex / controller.numOutputs
                : null,
          ),
          SizedBox(height: gap / 2),
        ],
        if (controller.successCount > 0 || controller.failedCount > 0) ...[
          Row(
            children: [
              if (controller.successCount > 0)
                _statBadge('✓ ${controller.successCount} succeeded', Colors.green.shade700),
              if (controller.successCount > 0 && controller.failedCount > 0)
                const SizedBox(width: 8),
              if (controller.failedCount > 0)
                _statBadge('✗ ${controller.failedCount} failed', colorScheme.error),
            ],
          ),
          SizedBox(height: gap / 2),
        ],
        if (controller.logs.isEmpty && !controller.isExporting)
          const Text('Export progress will appear here.',
              style: TextStyle(color: Colors.grey))
        else
          for (final log in controller.logs.reversed.take(20).toList().reversed)
            Padding(
              padding: const EdgeInsets.only(bottom: 2),
              child: Text(
                log,
                style: TextStyle(
                  fontSize: AppResponsive.bodySize(context) - 1,
                  color: log.contains('FAILED')
                      ? colorScheme.error
                      : (log.contains('completed') || log.contains('succeeded'))
                          ? Colors.green.shade700
                          : null,
                ),
              ),
            ),
      ],
    );
  }

  Widget _statBadge(String text, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: color.withValues(alpha: 0.4)),
      ),
      child: Text(
        text,
        style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: color),
      ),
    );
  }

  Widget _sectionCard(
    BuildContext context, {
    required IconData icon,
    required String title,
    required List<Widget> children,
  }) {
    final gap = AppResponsive.cardGap(context);
    final colorScheme = Theme.of(context).colorScheme;

    return Card(
      clipBehavior: Clip.antiAlias,
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(AppResponsive.cardRadius(context)),
        side: BorderSide(color: colorScheme.outlineVariant.withValues(alpha: 0.7)),
      ),
      child: Padding(
        padding: EdgeInsets.all(gap),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Row(
              children: [
                Icon(icon, color: colorScheme.primary),
                const SizedBox(width: 8),
                Text(
                  title,
                  style: TextStyle(
                    fontSize: AppResponsive.bodySize(context),
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
            SizedBox(height: gap),
            ...children,
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
        Expanded(child: left),
        SizedBox(width: gap),
        Expanded(child: right),
      ],
    );
  }
}

class _MultiFolderSelectorCard extends StatelessWidget {
  const _MultiFolderSelectorCard({
    required this.title,
    required this.paths,
    required this.icon,
    required this.onAdd,
    required this.onRemove,
  });

  final String title;
  final List<String> paths;
  final IconData icon;
  final VoidCallback onAdd;
  final void Function(String) onRemove;

  @override
  Widget build(BuildContext context) {
    return Card(
      elevation: 0,
      margin: EdgeInsets.zero,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(AppResponsive.cardRadius(context)),
        side: BorderSide(
          color: Theme.of(context).colorScheme.outlineVariant,
        ),
      ),
      child: Padding(
        padding: const EdgeInsets.all(12.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Row(
              children: [
                Icon(icon, size: 20),
                const SizedBox(width: 8),
                Text(
                  title,
                  style: const TextStyle(fontWeight: FontWeight.bold),
                ),
                const Spacer(),
                OutlinedButton.icon(
                  onPressed: onAdd,
                  icon: const Icon(Icons.add, size: 16),
                  label: const Text('Add'),
                  style: OutlinedButton.styleFrom(
                    visualDensity: VisualDensity.compact,
                  ),
                ),
              ],
            ),
            if (paths.isNotEmpty) const SizedBox(height: 12),
            if (paths.isNotEmpty)
              Wrap(
                spacing: 8.0,
                runSpacing: 8.0,
                children: paths.map((p) {
                  return InputChip(
                    label: Text(
                      _folderName(p),
                      style: const TextStyle(fontSize: 12),
                    ),
                    onDeleted: () => onRemove(p),
                    tooltip: p,
                    deleteIcon: const Icon(Icons.close, size: 14),
                  );
                }).toList(),
              ),
          ],
        ),
      ),
    );
  }

  String _folderName(String path) {
    final segments = path.split(Platform.isWindows ? '\\' : '/');
    return segments.isNotEmpty ? segments.last : path;
  }
}
import 'package:flutter/material.dart';
import 'package:path/path.dart' as p;
import 'package:soundswap/core/responsive/app_responsive.dart';

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
  }

  @override
  void dispose() {
    _outputNameController.dispose();
    _targetController.dispose();
    _clipController.dispose();
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
          'Create one long MP4 by randomly combining short videos and audio.',
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
            _logs(context),
          ],
        );
      },
    );
  }

  Widget _settings(BuildContext context) {
    final controller = widget.controller;
    final gap = AppResponsive.cardGap(context);
    return SettingsSection(
      title: 'Generator settings',
      icon: Icons.video_stable_outlined,
      children: [
        FolderSelectorCard(
          title: 'Video folder',
          path: controller.videoFolderPath,
          icon: Icons.video_library_outlined,
          onPressed: controller.pickVideoFolder,
        ),
        FolderSelectorCard(
          title: 'Audio folder',
          path: controller.audioFolderPath,
          icon: Icons.library_music_outlined,
          onPressed: controller.pickAudioFolder,
        ),
        FolderSelectorCard(
          title: 'Output folder',
          path: controller.outputFolderPath,
          icon: Icons.folder_copy_outlined,
          onPressed: controller.pickOutputFolder,
        ),
        TextField(
          controller: _outputNameController,
          onChanged: controller.setOutputName,
          decoration: const InputDecoration(labelText: 'Output name'),
        ),
        Row(
          children: [
            Expanded(
              child: TextField(
                controller: _targetController,
                onChanged: controller.setTargetMinutes,
                keyboardType: TextInputType.number,
                decoration: const InputDecoration(
                  labelText: 'Target length (minutes)',
                ),
              ),
            ),
            SizedBox(width: gap / 2),
            Expanded(
              child: TextField(
                controller: _clipController,
                onChanged: controller.setClipSeconds,
                keyboardType: TextInputType.number,
                decoration: const InputDecoration(
                  labelText: 'Clip length (seconds)',
                ),
              ),
            ),
          ],
        ),
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
        DropdownButtonFormField<LongVideoAudioMode>(
          initialValue: controller.audioMode,
          isExpanded: true,
          decoration: const InputDecoration(labelText: 'Audio mode'),
          items: const [
            DropdownMenuItem(
              value: LongVideoAudioMode.selectedFile,
              child: Text('Use one selected audio file'),
            ),
            DropdownMenuItem(
              value: LongVideoAudioMode.randomFromFolder,
              child: Text('Pick random audio files from folder'),
            ),
          ],
          onChanged: (value) {
            if (value != null) controller.setAudioMode(value);
          },
        ),
        if (controller.audios.isNotEmpty)
          DropdownButtonFormField<String>(
            initialValue: controller.selectedAudioPath,
            isExpanded: true,
            decoration: const InputDecoration(labelText: 'Selected audio'),
            items: [
              for (final audio in controller.audios)
                DropdownMenuItem(value: audio.path, child: Text(audio.name)),
            ],
            onChanged: controller.setSelectedAudio,
          ),
        Wrap(
          spacing: gap / 2,
          runSpacing: gap / 2,
          children: [
            FilledButton.icon(
              onPressed: controller.isPlanning || controller.isExporting
                  ? null
                  : controller.generatePlan,
              icon: const Icon(Icons.auto_awesome),
              label: const Text('Generate Plan'),
            ),
            OutlinedButton.icon(
              onPressed:
              controller.plan == null ||
                  controller.isPlanning ||
                  controller.isExporting
                  ? null
                  : controller.startExport,
              icon: const Icon(Icons.play_arrow),
              label: const Text('Start Export'),
            ),
            OutlinedButton.icon(
              onPressed: controller.isExporting ? null : controller.clearPlan,
              icon: const Icon(Icons.clear),
              label: const Text('Clear Plan'),
            ),
          ],
        ),
        if (controller.message != null) Text(controller.message!),
        if (controller.errorMessage != null)
          Text(
            controller.errorMessage!,
            style: TextStyle(color: Theme.of(context).colorScheme.error),
          ),
      ],
    );
  }

  Widget _plan(BuildContext context) {
    final plan = widget.controller.plan;
    if (plan == null) {
      return const SettingsSection(
        title: 'Generated plan',
        icon: Icons.view_list_outlined,
        children: [
          SizedBox(
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
      title: 'Generated plan',
      icon: Icons.view_list_outlined,
      children: [
        Text(
          'Output: ${plan.outputPath}\nEstimated duration: ${plan.estimatedDuration.toStringAsFixed(1)} seconds',
        ),
        const Divider(),
        Text('Selected clips', style: Theme.of(context).textTheme.titleSmall),
        SizedBox(
          height: 220,
          child: ListView(
            children: [
              for (final clip in plan.clips)
                ListTile(
                  dense: true,
                  leading: const Icon(Icons.movie_outlined),
                  title: Text(clip.name),
                  subtitle: Text(
                    '${clip.clipDuration.toStringAsFixed(1)}s from ${clip.sourceDuration.toStringAsFixed(1)}s',
                  ),
                ),
            ],
          ),
        ),
        const Divider(),
        Text('Selected audio', style: Theme.of(context).textTheme.titleSmall),
        SizedBox(
          height: 160,
          child: ListView(
            children: [
              for (final audio in plan.audioSegments)
                ListTile(
                  dense: true,
                  leading: const Icon(Icons.audiotrack_outlined),
                  title: Text(p.basename(audio.audioPath)),
                  subtitle: Text(
                    '${audio.segmentDuration.toStringAsFixed(1)}s',
                  ),
                ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _logs(BuildContext context) {
    final controller = widget.controller;
    return SettingsSection(
      title: 'Progress',
      icon: Icons.terminal_outlined,
      children: [
        if (controller.logs.isEmpty)
          const Text('Export progress will appear here.')
        else
          for (final log in controller.logs.take(12))
            Text(
              log,
              style: TextStyle(fontSize: AppResponsive.bodySize(context) - 1),
            ),
      ],
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
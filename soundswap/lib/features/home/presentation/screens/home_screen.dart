import 'dart:io';

import 'package:flutter/material.dart';
import 'package:soundswap/core/constants/app_constants.dart';
import 'package:soundswap/core/responsive/app_responsive.dart';
import 'package:soundswap/features/home/presentation/state/home_controller.dart';
import 'package:soundswap/features/home/presentation/widgets/folder_selector_card.dart';
import 'package:soundswap/features/home/presentation/widgets/metric_card.dart';
import 'package:soundswap/features/home/presentation/widgets/progress_panel.dart';
import 'package:soundswap/features/home/presentation/widgets/queue_table.dart';
import 'package:soundswap/shared/widgets/empty_state.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  late final HomeController _controller;

  @override
  void initState() {
    super.initState();
    _controller = HomeController();
    _controller.initializeOutputFolder();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (!Platform.isWindows) {
      return const Scaffold(
        body: EmptyState(
          icon: Icons.desktop_windows,
          title: 'Windows only',
          message: 'SoundSwap is built for Flutter Windows desktop.',
        ),
      );
    }

    return ListenableBuilder(
      listenable: _controller,
      builder: (context, _) {
        final compact = AppResponsive.isCompact(context);
        final padding = AppResponsive.pagePadding(context);

        return Scaffold(
          appBar: AppBar(
            title: const Text(AppConstants.appName),
            actions: [
              Padding(
                padding: const EdgeInsets.only(right: 16),
                child: Chip(
                  avatar: const Icon(Icons.terminal, size: 18),
                  label: const Text('FFmpeg CLI'),
                ),
              ),
            ],
          ),
          body: SafeArea(
            child: Padding(
              padding: EdgeInsets.all(padding),
              child: compact
                  ? _CompactLayout(controller: _controller)
                  : _WideLayout(controller: _controller),
            ),
          ),
        );
      },
    );
  }
}

class _WideLayout extends StatelessWidget {
  const _WideLayout({required this.controller});

  final HomeController controller;

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SizedBox(width: 390, child: _ControlsPanel(controller: controller)),
        const SizedBox(width: 24),
        Expanded(child: _QueuePanel(controller: controller)),
      ],
    );
  }
}

class _CompactLayout extends StatelessWidget {
  const _CompactLayout({required this.controller});

  final HomeController controller;

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      child: Column(
        children: [
          _ControlsPanel(controller: controller),
          const SizedBox(height: 20),
          SizedBox(height: 520, child: _QueuePanel(controller: controller)),
        ],
      ),
    );
  }
}

class _ControlsPanel extends StatelessWidget {
  const _ControlsPanel({required this.controller});

  final HomeController controller;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Text(
          'Batch audio replacement',
          style: Theme.of(context).textTheme.headlineMedium,
        ),
        const SizedBox(height: 8),
        Text(
          'Randomly choose audio and timing for each video, then export MP4 files with the original video stream preserved.',
          style: Theme.of(context).textTheme.bodyMedium?.copyWith(
            color: Theme.of(context).colorScheme.onSurfaceVariant,
          ),
        ),
        const SizedBox(height: 20),
        FolderSelectorCard(
          title: 'Video folder',
          path: controller.videoFolderPath,
          icon: Icons.movie_creation_outlined,
          onPressed: controller.pickVideoFolder,
        ),
        const SizedBox(height: 12),
        FolderSelectorCard(
          title: 'Audio folder',
          path: controller.audioFolderPath,
          icon: Icons.library_music_outlined,
          onPressed: controller.pickAudioFolder,
        ),
        const SizedBox(height: 12),
        FolderSelectorCard(
          title: 'Output folder',
          path: controller.outputFolderPath,
          icon: Icons.drive_folder_upload_outlined,
          onPressed: controller.pickOutputFolder,
        ),
        const SizedBox(height: 18),
        ProgressPanel(controller: controller),
        const SizedBox(height: 18),
        Row(
          children: [
            Expanded(
              child: MetricCard(
                label: 'Videos',
                value: '${controller.videos.length}',
                icon: Icons.video_file,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: MetricCard(
                label: 'Audio',
                value: '${controller.audios.length}',
                icon: Icons.audio_file,
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),
        Row(
          children: [
            Expanded(
              child: MetricCard(
                label: 'Success',
                value: '${controller.successCount}',
                icon: Icons.check_circle_outline,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: MetricCard(
                label: 'Failed',
                value: '${controller.failedCount}',
                icon: Icons.error_outline,
              ),
            ),
          ],
        ),
      ],
    );
  }
}

class _QueuePanel extends StatelessWidget {
  const _QueuePanel({required this.controller});

  final HomeController controller;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Expanded(
              child: Text(
                'Queue',
                style: Theme.of(context).textTheme.headlineSmall,
              ),
            ),
            Text(
              '${controller.jobs.length} files',
              style: Theme.of(context).textTheme.labelLarge?.copyWith(
                color: Theme.of(context).colorScheme.onSurfaceVariant,
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),
        Expanded(child: QueueTable(jobs: controller.jobs)),
      ],
    );
  }
}

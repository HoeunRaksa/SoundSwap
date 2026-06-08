import 'dart:io';

import 'package:flutter/material.dart';
import 'package:soundswap/core/constants/app_constants.dart';
import 'package:soundswap/core/responsive/app_responsive.dart';
import 'package:soundswap/features/home/presentation/state/home_controller.dart';
import 'package:soundswap/features/home/presentation/widgets/debug_console_panel.dart';
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
        return Scaffold(
          appBar: AppBar(
            title: Text(
              AppConstants.appName,
              style: TextStyle(fontSize: AppResponsive.titleSize(context)),
            ),
            actions: [
              Padding(
                padding: EdgeInsets.only(
                  right: AppResponsive.horizontalPadding(context),
                ),
                child: Chip(
                  avatar: Icon(
                    Icons.terminal,
                    size: AppResponsive.iconSize(context),
                  ),
                  label: Text(
                    'FFmpeg CLI',
                    style: TextStyle(fontSize: AppResponsive.bodySize(context)),
                  ),
                ),
              ),
            ],
          ),
          body: SafeArea(
            child: ResponsivePadding(
              child: ResponsiveCenter(
                child: ResponsiveLayout(
                  small: _SmallLayout(controller: _controller),
                  medium: _MediumLayout(controller: _controller),
                  large: _LargeLayout(controller: _controller),
                ),
              ),
            ),
          ),
        );
      },
    );
  }
}

class _SmallLayout extends StatelessWidget {
  const _SmallLayout({required this.controller});

  final HomeController controller;

  @override
  Widget build(BuildContext context) {
    final gap = AppResponsive.cardGap(context);

    return SingleChildScrollView(
      child: Column(
        children: [
          _ControlsPanel(controller: controller),
          SizedBox(height: gap),
          SizedBox(
            height: AppResponsive.queuePanelHeight(context),
            child: _QueuePanel(controller: controller),
          ),
          SizedBox(height: gap),
          SizedBox(
            height: AppResponsive.debugPanelHeight(context),
            child: DebugConsolePanel(controller: controller),
          ),
        ],
      ),
    );
  }
}

class _MediumLayout extends StatelessWidget {
  const _MediumLayout({required this.controller});

  final HomeController controller;

  @override
  Widget build(BuildContext context) {
    final gap = AppResponsive.cardGap(context);

    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SizedBox(
          width: AppResponsive.sidebarWidth(context),
          child: SingleChildScrollView(
            child: _ControlsPanel(controller: controller),
          ),
        ),
        SizedBox(width: gap),
        Expanded(
          child: LayoutBuilder(
            builder: (context, constraints) {
              final debugHeight = AppResponsive.debugPanelHeight(context);
              final minHeight = 250.0 + debugHeight + gap;
              if (constraints.maxHeight < minHeight) {
                return SingleChildScrollView(
                  child: Column(
                    children: [
                      SizedBox(
                        height: 350.0,
                        child: _QueuePanel(controller: controller),
                      ),
                      SizedBox(height: gap),
                      SizedBox(
                        height: debugHeight,
                        child: DebugConsolePanel(controller: controller),
                      ),
                    ],
                  ),
                );
              }
              return Column(
                children: [
                  Expanded(child: _QueuePanel(controller: controller)),
                  SizedBox(height: gap),
                  SizedBox(
                    height: debugHeight,
                    child: DebugConsolePanel(controller: controller),
                  ),
                ],
              );
            },
          ),
        ),
      ],
    );
  }
}

class _LargeLayout extends StatelessWidget {
  const _LargeLayout({required this.controller});

  final HomeController controller;

  @override
  Widget build(BuildContext context) {
    final gap = AppResponsive.cardGap(context);

    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SizedBox(
          width: AppResponsive.sidebarWidth(context),
          child: SingleChildScrollView(
            child: _ControlsPanel(controller: controller),
          ),
        ),
        SizedBox(width: gap),
        Expanded(
          child: LayoutBuilder(
            builder: (context, constraints) {
              final debugHeight = AppResponsive.debugPanelHeight(context);
              final minHeight = 250.0 + debugHeight + gap;
              if (constraints.maxHeight < minHeight) {
                return SingleChildScrollView(
                  child: Column(
                    children: [
                      SizedBox(
                        height: 350.0,
                        child: _QueuePanel(controller: controller),
                      ),
                      SizedBox(height: gap),
                      SizedBox(
                        height: debugHeight,
                        child: DebugConsolePanel(controller: controller),
                      ),
                    ],
                  ),
                );
              }
              return Column(
                children: [
                  Expanded(child: _QueuePanel(controller: controller)),
                  SizedBox(height: gap),
                  SizedBox(
                    height: debugHeight,
                    child: DebugConsolePanel(controller: controller),
                  ),
                ],
              );
            },
          ),
        ),
      ],
    );
  }
}

class _ControlsPanel extends StatelessWidget {
  const _ControlsPanel({required this.controller});

  final HomeController controller;

  @override
  Widget build(BuildContext context) {
    final gap = AppResponsive.cardGap(context);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Text(
          'Batch audio replacement',
          style: Theme.of(context).textTheme.headlineMedium?.copyWith(
            fontSize: AppResponsive.titleSize(context),
          ),
        ),
        SizedBox(height: gap / 2),
        Text(
          'Randomly choose audio and timing for each video, then export MP4 files with the original video stream preserved.',
          style: Theme.of(context).textTheme.bodyMedium?.copyWith(
            color: Theme.of(context).colorScheme.onSurfaceVariant,
            fontSize: AppResponsive.bodySize(context),
          ),
        ),
        SizedBox(height: gap),
        FolderSelectorCard(
          title: 'Video folder',
          path: controller.videoFolderPath,
          icon: Icons.movie_creation_outlined,
          onPressed: controller.pickVideoFolder,
        ),
        SizedBox(height: gap),
        FolderSelectorCard(
          title: 'Audio folder',
          path: controller.audioFolderPath,
          icon: Icons.library_music_outlined,
          onPressed: controller.pickAudioFolder,
        ),
        SizedBox(height: gap),
        FolderSelectorCard(
          title: 'Output folder',
          path: controller.outputFolderPath,
          icon: Icons.drive_folder_upload_outlined,
          onPressed: controller.pickOutputFolder,
        ),
        SizedBox(height: gap),
        ProgressPanel(controller: controller),
        SizedBox(height: gap),
        _MetricsGrid(controller: controller),
      ],
    );
  }
}

class _MetricsGrid extends StatelessWidget {
  const _MetricsGrid({required this.controller});

  final HomeController controller;

  @override
  Widget build(BuildContext context) {
    final gap = AppResponsive.cardGap(context);
    final metrics = [
      MetricCard(
        label: 'Videos',
        value: '${controller.videos.length}',
        icon: Icons.video_file,
      ),
      MetricCard(
        label: 'Audio',
        value: '${controller.audios.length}',
        icon: Icons.audio_file,
      ),
      MetricCard(
        label: 'Success',
        value: '${controller.successCount}',
        icon: Icons.check_circle_outline,
      ),
      MetricCard(
        label: 'Failed',
        value: '${controller.failedCount}',
        icon: Icons.error_outline,
      ),
    ];

    return GridView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: AppResponsive.isSmall(context) ? 1 : 2,
        crossAxisSpacing: gap,
        mainAxisSpacing: gap,
        childAspectRatio: AppResponsive.metricAspectRatio(context),
      ),
      itemCount: metrics.length,
      itemBuilder: (context, index) => metrics[index],
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
                style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                  fontSize: AppResponsive.titleSize(context) - 4,
                ),
              ),
            ),
            Text(
              '${controller.jobs.length} files',
              style: Theme.of(context).textTheme.labelLarge?.copyWith(
                color: Theme.of(context).colorScheme.onSurfaceVariant,
                fontSize: AppResponsive.bodySize(context),
              ),
            ),
          ],
        ),
        SizedBox(height: AppResponsive.cardGap(context)),
        Expanded(child: QueueTable(jobs: controller.jobs)),
      ],
    );
  }
}

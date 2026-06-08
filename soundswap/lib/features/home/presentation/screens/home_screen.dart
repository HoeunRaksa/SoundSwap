import 'dart:io';

import 'package:flutter/material.dart';
import 'package:soundswap/core/responsive/app_responsive.dart';
import 'package:soundswap/features/home/presentation/state/home_controller.dart';
import 'package:soundswap/features/home/presentation/widgets/folder_selector_card.dart';
import 'package:soundswap/features/home/presentation/widgets/metric_card.dart';
import 'package:soundswap/features/home/presentation/widgets/progress_panel.dart';
import 'package:soundswap/features/home/presentation/widgets/queue_table.dart';
import 'package:soundswap/shared/widgets/empty_state.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({this.controller, super.key});

  final HomeController? controller;

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  late final HomeController _controller;
  late final bool _ownsController;

  @override
  void initState() {
    super.initState();
    _controller = widget.controller ?? HomeController();
    _ownsController = widget.controller == null;
    if (_ownsController) {
      _controller.initializeOutputFolder();
    }
  }

  @override
  void dispose() {
    if (_ownsController) {
      _controller.dispose();
    }
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
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          _ControlsPanel(controller: controller, showFooter: false),
          SizedBox(height: gap),
          const Divider(),
          SizedBox(height: gap),
          Text(
            'Batch audio replacement',
            style: Theme.of(context).textTheme.headlineMedium?.copyWith(
              fontSize: AppResponsive.titleSize(context),
              fontWeight: FontWeight.bold,
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
          ProgressPanel(controller: controller),
          SizedBox(height: gap),
          SizedBox(
            height: AppResponsive.queuePanelHeight(context),
            child: _QueuePanel(controller: controller),
          ),
          SizedBox(height: gap * 2),
          Center(
            child: Text(
              'Copyright by Hoeun Raksa',
              style: Theme.of(context).textTheme.labelMedium?.copyWith(
                color: Theme.of(
                  context,
                ).colorScheme.onSurfaceVariant.withValues(alpha: 0.6),
                fontSize: AppResponsive.bodySize(context) - 2,
              ),
            ),
          ),
          SizedBox(height: gap),
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
            child: _ControlsPanel(controller: controller, showFooter: true),
          ),
        ),
        SizedBox(width: gap),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Batch audio replacement',
                style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                  fontSize: AppResponsive.titleSize(context),
                  fontWeight: FontWeight.bold,
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
              ProgressPanel(controller: controller),
              SizedBox(height: gap),
              Expanded(child: _QueuePanel(controller: controller)),
            ],
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
            child: _ControlsPanel(controller: controller, showFooter: true),
          ),
        ),
        SizedBox(width: gap),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Batch audio replacement',
                style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                  fontSize: AppResponsive.titleSize(context),
                  fontWeight: FontWeight.bold,
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
              ProgressPanel(controller: controller),
              SizedBox(height: gap),
              Expanded(child: _QueuePanel(controller: controller)),
            ],
          ),
        ),
      ],
    );
  }
}

class _ControlsPanel extends StatefulWidget {
  const _ControlsPanel({required this.controller, this.showFooter = true});

  final HomeController controller;
  final bool showFooter;

  @override
  State<_ControlsPanel> createState() => _ControlsPanelState();
}

class _ControlsPanelState extends State<_ControlsPanel> {
  late final TextEditingController _prefixController;

  @override
  void initState() {
    super.initState();
    _prefixController = TextEditingController(
      text: widget.controller.outputNamePrefix,
    );
  }

  @override
  void dispose() {
    _prefixController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final gap = AppResponsive.cardGap(context);
    final colorScheme = Theme.of(context).colorScheme;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Row(
          children: [
            Icon(
              Icons.swap_horizontal_circle_outlined,
              size: AppResponsive.titleSize(context) + 4,
              color: colorScheme.primary,
            ),
            const SizedBox(width: 8),
            Text(
              'SoundSwap',
              style: TextStyle(
                fontSize: AppResponsive.titleSize(context) + 2,
                fontWeight: FontWeight.bold,
                color: colorScheme.onSurface,
                letterSpacing: -0.5,
              ),
            ),
          ],
        ),
        SizedBox(height: gap / 4),
        Text(
          'Automated Audio Replacement',
          style: Theme.of(context).textTheme.labelSmall?.copyWith(
            color: colorScheme.secondary,
            fontWeight: FontWeight.w600,
            fontSize: AppResponsive.bodySize(context) - 2,
          ),
        ),
        SizedBox(height: gap),
        FolderSelectorCard(
          title: 'Video folder',
          path: widget.controller.videoFolderPath,
          icon: Icons.movie_creation_outlined,
          onPressed: widget.controller.pickVideoFolder,
        ),
        SizedBox(height: gap),
        FolderSelectorCard(
          title: 'Audio folder',
          path: widget.controller.audioFolderPath,
          icon: Icons.library_music_outlined,
          onPressed: widget.controller.pickAudioFolder,
        ),
        SizedBox(height: gap),
        FolderSelectorCard(
          title: 'Output folder',
          path: widget.controller.outputFolderPath,
          icon: Icons.drive_folder_upload_outlined,
          onPressed: widget.controller.pickOutputFolder,
        ),
        SizedBox(height: gap),
        TextField(
          controller: _prefixController,
          onChanged: widget.controller.setOutputNamePrefix,
          style: TextStyle(fontSize: AppResponsive.bodySize(context)),
          decoration: InputDecoration(
            labelText: 'Output Name Prefix',
            hintText: 'e.g. mydaily (defaults to soundswap)',
            prefixIcon: Icon(
              Icons.edit_note,
              size: AppResponsive.iconSize(context),
            ),
          ),
        ),
        SizedBox(height: gap),
        Row(
          children: [
            Expanded(
              child: SizedBox(
                height: AppResponsive.buttonHeight(context) + 8,
                child: FilledButton.icon(
                  onPressed: widget.controller.canStart
                      ? widget.controller.startProcessing
                      : null,
                  icon: widget.controller.isProcessing
                      ? SizedBox(
                          width: AppResponsive.iconSize(context) - 4,
                          height: AppResponsive.iconSize(context) - 4,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            color: colorScheme.onPrimary,
                          ),
                        )
                      : Icon(
                          Icons.play_arrow_rounded,
                          size: AppResponsive.iconSize(context) + 2,
                        ),
                  label: Text(
                    widget.controller.isProcessing ? 'Running' : 'Start Batch',
                    style: TextStyle(
                      fontSize: AppResponsive.bodySize(context),
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ),
            ),
            SizedBox(width: gap / 2),
            SizedBox(
              height: AppResponsive.buttonHeight(context) + 8,
              child: OutlinedButton.icon(
                onPressed:
                    widget.controller.isProcessing ||
                        widget.controller.isScanning
                    ? null
                    : widget.controller.scanAndBuildQueue,
                icon: Icon(
                  Icons.refresh_rounded,
                  size: AppResponsive.iconSize(context),
                ),
                label: Text(
                  'Rescan',
                  style: TextStyle(fontSize: AppResponsive.bodySize(context)),
                ),
              ),
            ),
          ],
        ),
        SizedBox(height: gap * 1.5),
        _MetricsGrid(controller: widget.controller),
        if (widget.showFooter) ...[
          Padding(
            padding: EdgeInsets.only(top: gap * 3, bottom: gap),
            child: Center(
              child: Text(
                'Copyright by Hoeun Raksa',
                style: Theme.of(context).textTheme.labelMedium?.copyWith(
                  color: colorScheme.onSurfaceVariant.withValues(alpha: 0.6),
                  fontSize: AppResponsive.bodySize(context) - 2,
                ),
              ),
            ),
          ),
        ],
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
                  fontWeight: FontWeight.bold,
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

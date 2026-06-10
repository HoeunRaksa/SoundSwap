import 'dart:io';

import 'package:flutter/material.dart';
import 'package:path/path.dart' as p;
import 'package:soundswap/core/responsive/app_responsive.dart';
import 'package:soundswap/core/video/video_output_settings.dart';
import 'package:soundswap/features/home/data/models/batch_profile.dart';
import 'package:soundswap/features/home/presentation/state/home_controller.dart';
import 'package:soundswap/features/home/presentation/widgets/folder_selector_card.dart';
import 'package:soundswap/features/home/presentation/widgets/metric_card.dart';
import 'package:soundswap/features/home/presentation/widgets/progress_panel.dart';
import 'package:soundswap/features/home/presentation/widgets/queue_table.dart';
import 'package:soundswap/features/overlay_tools/data/models/overlay_preset.dart';
import 'package:soundswap/features/overlay_tools/presentation/state/overlay_tools_controller.dart';
import 'package:soundswap/features/templates/data/models/project_template.dart';
import 'package:soundswap/features/templates/presentation/state/templates_controller.dart';
import 'package:soundswap/shared/services/folder_picker_service.dart';
import 'package:soundswap/shared/widgets/empty_state.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({
    this.controller,
    this.overlayController,
    this.templatesController,
    super.key,
  });

  final HomeController? controller;
  final OverlayToolsController? overlayController;
  final TemplatesController? templatesController;

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
      _controller.initialize();
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
                  small: _SmallLayout(
                    controller: _controller,
                    overlayController: widget.overlayController,
                    templatesController: widget.templatesController,
                  ),
                  medium: _MediumLayout(
                    controller: _controller,
                    overlayController: widget.overlayController,
                    templatesController: widget.templatesController,
                  ),
                  large: _LargeLayout(
                    controller: _controller,
                    overlayController: widget.overlayController,
                    templatesController: widget.templatesController,
                  ),
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
  const _SmallLayout({
    required this.controller,
    required this.overlayController,
    required this.templatesController,
  });

  final HomeController controller;
  final OverlayToolsController? overlayController;
  final TemplatesController? templatesController;

  @override
  Widget build(BuildContext context) {
    final gap = AppResponsive.cardGap(context);

    return SingleChildScrollView(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          _ControlsPanel(
            controller: controller,
            overlayController: overlayController,
            templatesController: templatesController,
            showFooter: false,
          ),
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
  const _MediumLayout({
    required this.controller,
    required this.overlayController,
    required this.templatesController,
  });

  final HomeController controller;
  final OverlayToolsController? overlayController;
  final TemplatesController? templatesController;

  @override
  Widget build(BuildContext context) {
    final gap = AppResponsive.cardGap(context);

    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SizedBox(
          width: AppResponsive.sidebarWidth(context),
          child: SingleChildScrollView(
            child: _ControlsPanel(
              controller: controller,
              overlayController: overlayController,
              templatesController: templatesController,
              showFooter: true,
            ),
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
  const _LargeLayout({
    required this.controller,
    required this.overlayController,
    required this.templatesController,
  });

  final HomeController controller;
  final OverlayToolsController? overlayController;
  final TemplatesController? templatesController;

  @override
  Widget build(BuildContext context) {
    final gap = AppResponsive.cardGap(context);

    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SizedBox(
          width: AppResponsive.sidebarWidth(context),
          child: SingleChildScrollView(
            child: _ControlsPanel(
              controller: controller,
              overlayController: overlayController,
              templatesController: templatesController,
              showFooter: true,
            ),
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
  const _ControlsPanel({
    required this.controller,
    required this.overlayController,
    required this.templatesController,
    this.showFooter = true,
  });

  final HomeController controller;
  final OverlayToolsController? overlayController;
  final TemplatesController? templatesController;
  final bool showFooter;

  @override
  State<_ControlsPanel> createState() => _ControlsPanelState();
}

class _ControlsPanelState extends State<_ControlsPanel> {
  late final TextEditingController _prefixController;
  final _dialogFolderPicker = FolderPickerService();
  final _prefixFocus = FocusNode();

  @override
  void initState() {
    super.initState();
    _prefixController = TextEditingController(
      text: widget.controller.outputNamePrefix,
    );
    widget.controller.addListener(_syncPrefixController);
  }

  @override
  void dispose() {
    widget.controller.removeListener(_syncPrefixController);
    _prefixController.dispose();
    _prefixFocus.dispose();
    super.dispose();
  }

  void _syncPrefixController() {
    if (_prefixFocus.hasFocus) return;
    final prefix = widget.controller.outputNamePrefix;
    if (_prefixController.text != prefix) {
      _prefixController.text = prefix;
    }
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
                letterSpacing: 0,
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
        _BatchProfilesPanel(
          controller: widget.controller,
          onCreate: () => _editBatchProfileDetails(),
          onStart: widget.controller.startBatchProfile,
          onStop: widget.controller.stopProcessing,
          onEdit: (profile) => _editBatchProfileDetails(profile: profile),
          onDelete: _confirmDeleteBatchProfile,
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
          focusNode: _prefixFocus,
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
        if (widget.overlayController != null &&
            widget.templatesController != null) ...[
          SizedBox(height: gap),
          _GeneratorOptionsPanel(
            controller: widget.controller,
            overlayController: widget.overlayController!,
            templatesController: widget.templatesController!,
          ),
        ],
        SizedBox(height: gap),
        SizedBox(
          height: AppResponsive.buttonHeight(context) + 8,
          child: OutlinedButton.icon(
            onPressed: widget.controller.canGenerateQueue
                ? widget.controller.generateQueue
                : null,
            icon: Icon(
              Icons.playlist_add_check,
              size: AppResponsive.iconSize(context),
            ),
            label: Text(
              'Generate Queue',
              style: TextStyle(fontSize: AppResponsive.bodySize(context)),
            ),
          ),
        ),
        SizedBox(height: gap / 2),
        SizedBox(
          height: AppResponsive.buttonHeight(context) + 8,
          child: FilledButton.icon(
            onPressed: widget.controller.canStart
                ? () => _confirmStartBatch(context)
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

  Future<void> _confirmStartBatch(BuildContext context) async {
    final removeOldResults = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Start Batch'),
        content: Text(
          'Result folder:\n${widget.controller.outputFolderPath ?? 'Not selected'}\n\nChoose how to handle existing numbered results.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          OutlinedButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Remove old results and start fresh'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Keep old results and continue numbering'),
          ),
        ],
      ),
    );
    if (removeOldResults == null) return;
    await widget.controller.startProcessing(removeOldResults: removeOldResults);
  }

  Future<void> _editBatchProfileDetails({BatchProfile? profile}) async {
    final nameController = TextEditingController(
      text: profile?.name ?? widget.controller.outputNamePrefix,
    );
    final prefixController = TextEditingController(
      text: profile?.outputPrefix ?? widget.controller.outputNamePrefix,
    );
    var videoFolder =
        profile?.videoFolderPath ?? widget.controller.videoFolderPath ?? '';
    var audioFolder =
        profile?.audioFolderPath ?? widget.controller.audioFolderPath ?? '';
    var outputFolder =
        profile?.outputFolderPath ?? widget.controller.outputFolderPath ?? '';
    final result =
        await showDialog<
          ({
            String name,
            String videoFolder,
            String audioFolder,
            String outputFolder,
            String prefix,
          })
        >(
          context: context,
          builder: (context) => StatefulBuilder(
            builder: (context, setDialogState) {
              final gap = AppResponsive.cardGap(context);
              return AlertDialog(
                title: Text(
                  profile == null ? 'Add batch profile' : 'Edit batch profile',
                ),
                content: SizedBox(
                  width: AppResponsive.isSmall(context) ? 520 : 680,
                  child: SingleChildScrollView(
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        TextField(
                          controller: nameController,
                          autofocus: true,
                          decoration: const InputDecoration(
                            labelText: 'Profile name',
                            hintText: 'Daily Cats, Furniture Page, PVC Ceiling',
                          ),
                        ),
                        SizedBox(height: gap),
                        _BatchProfileFolderPicker(
                          label: 'Video folder',
                          path: videoFolder,
                          icon: Icons.video_library_outlined,
                          onBrowse: () async {
                            final path = await _dialogFolderPicker.pickFolder(
                              dialogTitle: 'Select video folder',
                            );
                            if (path == null || !context.mounted) return;
                            setDialogState(() => videoFolder = path);
                          },
                        ),
                        SizedBox(height: gap),
                        _BatchProfileFolderPicker(
                          label: 'Audio folder',
                          path: audioFolder,
                          icon: Icons.library_music_outlined,
                          onBrowse: () async {
                            final path = await _dialogFolderPicker.pickFolder(
                              dialogTitle: 'Select audio folder',
                            );
                            if (path == null || !context.mounted) return;
                            setDialogState(() => audioFolder = path);
                          },
                        ),
                        SizedBox(height: gap),
                        _BatchProfileFolderPicker(
                          label: 'Output folder',
                          path: outputFolder,
                          icon: Icons.folder_copy_outlined,
                          onBrowse: () async {
                            final path = await _dialogFolderPicker.pickFolder(
                              dialogTitle: 'Select output folder',
                            );
                            if (path == null || !context.mounted) return;
                            setDialogState(() => outputFolder = path);
                          },
                        ),
                        SizedBox(height: gap),
                        TextField(
                          controller: prefixController,
                          decoration: const InputDecoration(
                            labelText: 'Output prefix',
                            hintText: 'mydaily',
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
                actionsPadding: EdgeInsets.fromLTRB(gap, 0, gap, gap),
                actions: [
                  TextButton(
                    onPressed: () => Navigator.pop(context),
                    child: const Text('Cancel'),
                  ),
                  FilledButton.icon(
                    onPressed: () => Navigator.pop(context, (
                      name: nameController.text,
                      videoFolder: videoFolder,
                      audioFolder: audioFolder,
                      outputFolder: outputFolder,
                      prefix: prefixController.text,
                    )),
                    icon: const Icon(Icons.save_outlined),
                    label: const Text('Save'),
                  ),
                ],
              );
            },
          ),
        );
    nameController.dispose();
    prefixController.dispose();
    if (result == null) return;
    if (profile == null) {
      await widget.controller.createBatchProfile(
        name: result.name,
        videoFolderPath: result.videoFolder,
        audioFolderPath: result.audioFolder,
        outputFolderPath: result.outputFolder,
        outputPrefix: result.prefix,
      );
    } else {
      await widget.controller.updateBatchProfileDetails(
        profile: profile,
        name: result.name,
        videoFolderPath: result.videoFolder,
        audioFolderPath: result.audioFolder,
        outputFolderPath: result.outputFolder,
        outputPrefix: result.prefix,
      );
    }
  }

  Future<void> _confirmDeleteBatchProfile(BatchProfile profile) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete batch profile?'),
        content: Text('Delete "${profile.name}"?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Delete'),
          ),
        ],
      ),
    );
    if (confirmed == true) {
      await widget.controller.deleteBatchProfile(profile);
    }
  }
}

class _BatchProfilesPanel extends StatelessWidget {
  const _BatchProfilesPanel({
    required this.controller,
    required this.onCreate,
    required this.onStart,
    required this.onStop,
    required this.onEdit,
    required this.onDelete,
  });

  final HomeController controller;
  final VoidCallback onCreate;
  final Future<void> Function(BatchProfile profile) onStart;
  final VoidCallback onStop;
  final Future<void> Function(BatchProfile profile) onEdit;
  final Future<void> Function(BatchProfile profile) onDelete;

  @override
  Widget build(BuildContext context) {
    final gap = AppResponsive.cardGap(context);
    final colorScheme = Theme.of(context).colorScheme;

    return Card(
      color: Colors.white,
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(AppResponsive.cardRadius(context)),
        side: BorderSide(color: colorScheme.outlineVariant),
      ),
      child: Padding(
        padding: EdgeInsets.all(gap * 0.9),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Row(
              children: [
                Icon(
                  Icons.history_toggle_off,
                  color: colorScheme.primary,
                  size: AppResponsive.iconSize(context),
                ),
                SizedBox(width: gap / 2),
                Expanded(
                  child: Text(
                    'Recent Batch Profiles',
                    style: Theme.of(context).textTheme.titleMedium?.copyWith(
                      fontSize: AppResponsive.bodySize(context) + 2,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                ),
                OutlinedButton.icon(
                  onPressed: onCreate,
                  icon: const Icon(Icons.add),
                  label: const Text('Add'),
                ),
              ],
            ),
            SizedBox(height: gap / 4),
            Text(
              'Start a saved profile to generate and process only that queue.',
              style: TextStyle(
                color: colorScheme.onSurfaceVariant,
                fontSize: AppResponsive.bodySize(context) - 2,
              ),
            ),
            if (controller.batchProfileMessage != null) ...[
              SizedBox(height: gap / 2),
              Text(
                controller.batchProfileMessage!,
                style: TextStyle(fontSize: AppResponsive.bodySize(context)),
              ),
            ],
            if (controller.batchProfiles.isEmpty) ...[
              SizedBox(height: gap / 2),
              Text(
                'Profiles are saved automatically after a successful batch.',
                style: TextStyle(
                  color: colorScheme.onSurfaceVariant,
                  fontSize: AppResponsive.bodySize(context),
                ),
              ),
            ] else ...[
              SizedBox(height: gap / 2),
              Wrap(
                spacing: gap,
                runSpacing: gap,
                children: [
                  for (final profile in controller.batchProfiles.take(8))
                    _BatchProfileServiceCard(
                      profile: profile,
                      status: controller.statusForProfile(profile),
                      selected: profile.id == controller.selectedBatchProfileId,
                      onStart: () => onStart(profile),
                      onStop: onStop,
                      onEdit: () => onEdit(profile),
                      onDelete: () => onDelete(profile),
                    ),
                ],
              ),
            ],
          ],
        ),
      ),
    );
  }
}

class _BatchProfileFolderPicker extends StatelessWidget {
  const _BatchProfileFolderPicker({
    required this.label,
    required this.path,
    required this.icon,
    required this.onBrowse,
  });

  final String label;
  final String path;
  final IconData icon;
  final VoidCallback onBrowse;

  @override
  Widget build(BuildContext context) {
    final gap = AppResponsive.cardGap(context);
    final colorScheme = Theme.of(context).colorScheme;
    final hasPath = path.trim().isNotEmpty;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Text(
          label,
          style: Theme.of(context).textTheme.labelLarge?.copyWith(
            color: colorScheme.onSurface,
            fontSize: AppResponsive.bodySize(context) - 1,
            fontWeight: FontWeight.w700,
          ),
        ),
        const SizedBox(height: 6),
        Container(
          padding: EdgeInsets.all(gap * 0.7),
          decoration: BoxDecoration(
            color: colorScheme.surfaceContainerHighest.withValues(alpha: 0.55),
            borderRadius: BorderRadius.circular(
              AppResponsive.cardRadius(context),
            ),
            border: Border.all(
              color: hasPath
                  ? Colors.blue.shade600.withValues(alpha: 0.28)
                  : colorScheme.outlineVariant,
            ),
          ),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Icon(
                icon,
                color: hasPath
                    ? Colors.blue.shade700
                    : colorScheme.onSurfaceVariant,
                size: AppResponsive.iconSize(context),
              ),
              SizedBox(width: gap / 2),
              Expanded(
                child: SelectableText(
                  hasPath ? path : 'No folder selected',
                  style: TextStyle(
                    color: hasPath
                        ? colorScheme.onSurface
                        : colorScheme.onSurfaceVariant,
                    fontSize: AppResponsive.bodySize(context) - 1,
                  ),
                ),
              ),
              SizedBox(width: gap / 2),
              OutlinedButton.icon(
                onPressed: onBrowse,
                icon: const Icon(Icons.folder_open_outlined),
                label: const Text('Browse'),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

class _BatchProfileServiceCard extends StatelessWidget {
  const _BatchProfileServiceCard({
    required this.profile,
    required this.status,
    required this.selected,
    required this.onStart,
    required this.onStop,
    required this.onEdit,
    required this.onDelete,
  });

  final BatchProfile profile;
  final BatchProfileRunStatus status;
  final bool selected;
  final VoidCallback onStart;
  final VoidCallback onStop;
  final VoidCallback onEdit;
  final VoidCallback onDelete;

  @override
  Widget build(BuildContext context) {
    final gap = AppResponsive.cardGap(context);
    final color = _statusColor(context);
    final width = AppResponsive.isSmall(context) ? double.infinity : 292.0;
    final prefix = profile.outputPrefix.trim().isEmpty
        ? 'soundswap'
        : profile.outputPrefix.trim();
    return SizedBox(
      width: width,
      child: Card(
        elevation: selected ? 2 : 0,
        color: Colors.white,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(
            AppResponsive.cardRadius(context),
          ),
          side: BorderSide(
            color: selected ? color : color.withValues(alpha: 0.25),
            width: selected ? 1.4 : 1,
          ),
        ),
        child: Padding(
          padding: EdgeInsets.all(gap * 0.75),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Row(
                children: [
                  Container(
                    width: 10,
                    height: 10,
                    decoration: BoxDecoration(
                      color: color,
                      shape: BoxShape.circle,
                    ),
                  ),
                  SizedBox(width: gap / 2),
                  Expanded(
                    child: Text(
                      profile.name,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        fontSize: AppResponsive.bodySize(context) + 1,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                  ),
                  _ServiceStatusChip(label: status.name, color: color),
                ],
              ),
              SizedBox(height: gap * 0.65),
              _ServiceMetaLine(
                icon: Icons.video_library_outlined,
                title: 'Video',
                value: _folderName(profile.videoFolderPath),
                tooltip: profile.videoFolderPath ?? 'Not selected',
              ),
              _ServiceMetaLine(
                icon: Icons.library_music_outlined,
                title: 'Audio',
                value: _folderName(profile.audioFolderPath),
                tooltip: profile.audioFolderPath ?? 'Not selected',
              ),
              _ServiceMetaLine(
                icon: Icons.folder_copy_outlined,
                title: 'Output',
                value: _folderName(profile.outputFolderPath),
                tooltip: profile.outputFolderPath ?? 'Not selected',
              ),
              Text(
                'Prefix: $prefix',
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(
                  color: Theme.of(context).colorScheme.onSurfaceVariant,
                  fontSize: AppResponsive.bodySize(context) - 2,
                  fontWeight: FontWeight.w600,
                ),
              ),
              SizedBox(height: gap * 0.7),
              FilledButton.icon(
                onPressed: status == BatchProfileRunStatus.running
                    ? null
                    : onStart,
                style: FilledButton.styleFrom(
                  backgroundColor: Colors.green.shade700,
                  foregroundColor: Colors.white,
                  visualDensity: VisualDensity.compact,
                  padding: const EdgeInsets.symmetric(vertical: 10),
                ),
                icon: const Icon(Icons.play_arrow_rounded),
                label: const Text('Start Profile'),
              ),
              SizedBox(height: gap / 2),
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton.icon(
                      onPressed: status == BatchProfileRunStatus.running
                          ? onStop
                          : null,
                      style: OutlinedButton.styleFrom(
                        foregroundColor: Colors.orange.shade800,
                        visualDensity: VisualDensity.compact,
                      ),
                      icon: const Icon(Icons.stop_circle_outlined),
                      label: const Text('Stop'),
                    ),
                  ),
                  const SizedBox(width: 6),
                  Expanded(
                    child: OutlinedButton.icon(
                      onPressed: onEdit,
                      style: OutlinedButton.styleFrom(
                        foregroundColor: Colors.blue.shade700,
                        visualDensity: VisualDensity.compact,
                      ),
                      icon: const Icon(Icons.edit_outlined),
                      label: const Text('Edit'),
                    ),
                  ),
                  IconButton(
                    tooltip: 'Delete',
                    onPressed: onDelete,
                    visualDensity: VisualDensity.compact,
                    icon: Icon(
                      Icons.delete_outline,
                      color: Theme.of(context).colorScheme.error,
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Color _statusColor(BuildContext context) {
    return switch (status) {
      BatchProfileRunStatus.stopped => Colors.blueGrey,
      BatchProfileRunStatus.queued => Colors.blue.shade700,
      BatchProfileRunStatus.running => Colors.green.shade700,
      BatchProfileRunStatus.done => Colors.orange.shade700,
    };
  }

  String _folderName(String? path) {
    if (path == null || path.trim().isEmpty) return 'Not selected';
    return p.basename(path);
  }
}

class _ServiceMetaLine extends StatelessWidget {
  const _ServiceMetaLine({
    required this.icon,
    required this.title,
    required this.value,
    required this.tooltip,
  });

  final IconData icon;
  final String title;
  final String value;
  final String tooltip;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 5),
      child: Row(
        children: [
          Icon(
            icon,
            size: AppResponsive.iconSize(context) - 7,
            color: Theme.of(context).colorScheme.onSurfaceVariant,
          ),
          const SizedBox(width: 5),
          SizedBox(
            width: 46,
            child: Text(
              title,
              style: TextStyle(
                color: Theme.of(context).colorScheme.onSurfaceVariant,
                fontSize: AppResponsive.bodySize(context) - 3,
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
          Expanded(
            child: Tooltip(
              message: tooltip,
              child: Text(
                value,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(
                  fontSize: AppResponsive.bodySize(context) - 2,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _ServiceStatusChip extends StatelessWidget {
  const _ServiceStatusChip({required this.label, required this.color});

  final String label;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 3),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.14),
        borderRadius: BorderRadius.circular(999),
      ),
      child: Text(
        label,
        style: TextStyle(
          color: color,
          fontSize: AppResponsive.bodySize(context) - 4,
          fontWeight: FontWeight.w800,
        ),
      ),
    );
  }
}

class _GeneratorOptionsPanel extends StatelessWidget {
  const _GeneratorOptionsPanel({
    required this.controller,
    required this.overlayController,
    required this.templatesController,
  });

  final HomeController controller;
  final OverlayToolsController overlayController;
  final TemplatesController templatesController;

  @override
  Widget build(BuildContext context) {
    final gap = AppResponsive.cardGap(context);
    final colorScheme = Theme.of(context).colorScheme;

    return ListenableBuilder(
      listenable: Listenable.merge([
        controller,
        overlayController,
        templatesController,
      ]),
      builder: (context, _) {
        return Card(
          child: Padding(
            padding: EdgeInsets.all(gap),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Row(
                  children: [
                    Icon(
                      Icons.auto_awesome_motion,
                      color: colorScheme.primary,
                      size: AppResponsive.iconSize(context),
                    ),
                    SizedBox(width: gap * 0.6),
                    Expanded(
                      child: Text(
                        'Generator options',
                        style: Theme.of(context).textTheme.titleMedium?.copyWith(
                          fontSize: AppResponsive.bodySize(context) + 2,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ),
                  ],
                ),

                SizedBox(height: gap),

                CheckboxListTile(
                  contentPadding: EdgeInsets.symmetric(
                    horizontal: gap * 0.2,
                  ),
                  visualDensity: const VisualDensity(
                    horizontal: -1,
                    vertical: -1,
                  ),
                  title: const Text('Use Overlays'),
                  value: controller.useOverlay,
                  onChanged: (value) {
                    final enabled = value ?? false;
                    if (enabled) {
                      controller.setOverlaySettings(overlayController.settings);
                    }
                    controller.setUseOverlay(enabled);
                  },
                ),

                SizedBox(height: gap * 0.6),

                _OverlayPresetDropdown(
                  enabled: controller.useOverlay,
                  controller: controller,
                  overlayController: overlayController,
                ),

                SizedBox(height: gap),

                CheckboxListTile(
                  contentPadding: EdgeInsets.symmetric(
                    horizontal: gap * 0.2,
                  ),
                  visualDensity: const VisualDensity(
                    horizontal: -1,
                    vertical: -1,
                  ),
                  title: const Text('Use Template'),
                  value: controller.useTemplate,
                  onChanged: (value) =>
                      controller.setUseTemplate(value ?? false),
                ),

                SizedBox(height: gap * 0.6),

                _TemplateDropdown(
                  enabled: controller.useTemplate,
                  controller: controller,
                  templatesController: templatesController,
                  overlayController: overlayController,
                ),

                SizedBox(height: gap),

                DropdownButtonFormField<VideoOutputSize>(
                  key: ValueKey(controller.outputSize),
                  initialValue: controller.outputSize,
                  isExpanded: true,
                  decoration: const InputDecoration(
                    labelText: 'Output size',
                  ),
                  items: [
                    for (final size in VideoOutputSize.values)
                      DropdownMenuItem(
                        value: size,
                        child: Text(size.label),
                      ),
                  ],
                  onChanged: (value) {
                    if (value != null) controller.setOutputSize(value);
                  },
                ),

                SizedBox(height: gap),

                DropdownButtonFormField<VideoFitMode>(
                  key: ValueKey(controller.fitMode),
                  initialValue: controller.fitMode,
                  isExpanded: true,
                  decoration: const InputDecoration(
                    labelText: 'Fit mode',
                  ),
                  items: [
                    for (final mode in VideoFitMode.values)
                      DropdownMenuItem(
                        value: mode,
                        child: Text(mode.label),
                      ),
                  ],
                  onChanged: (value) {
                    if (value != null) controller.setFitMode(value);
                  },
                ),

                if (controller.upscaleWarning != null) ...[
                  SizedBox(height: gap),
                  Container(
                    padding: EdgeInsets.all(gap * 0.7),
                    decoration: BoxDecoration(
                      color: colorScheme.tertiaryContainer.withValues(alpha: 0.3),
                      borderRadius: BorderRadius.circular(
                        AppResponsive.cardRadius(context),
                      ),
                    ),
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Icon(
                          Icons.info_outline,
                          color: colorScheme.tertiary,
                          size: AppResponsive.iconSize(context) * 0.9,
                        ),
                        SizedBox(width: gap * 0.5),
                        Expanded(
                          child: Text(
                            controller.upscaleWarning!,
                            style: TextStyle(
                              color: colorScheme.tertiary,
                              fontSize: AppResponsive.bodySize(context) - 1,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ],
            ),
          ),
        );
      },
    );
  }
}

class _OverlayPresetDropdown extends StatelessWidget {
  const _OverlayPresetDropdown({
    required this.enabled,
    required this.controller,
    required this.overlayController,
  });

  final bool enabled;
  final HomeController controller;
  final OverlayToolsController overlayController;

  @override
  Widget build(BuildContext context) {
    final selectedId = _selectedOverlayPresetId();
    return DropdownButtonFormField<String>(
      key: ValueKey('overlay-$selectedId-${overlayController.presets.length}'),
      initialValue: selectedId,
      isExpanded: true,
      decoration: const InputDecoration(labelText: 'Overlay preset'),
      items: [
        for (final preset in overlayController.presets)
          DropdownMenuItem(value: preset.id, child: Text(preset.name)),
      ],
      hint: Text(
        overlayController.presets.isEmpty ? 'Use current overlays' : 'Select',
      ),
      onChanged: enabled
          ? (id) {
              final preset = _presetById(id);
              if (preset == null) {
                controller.setOverlaySettings(overlayController.settings);
              } else {
                controller.setOverlayPreset(preset);
              }
            }
          : null,
    );
  }

  String? _selectedOverlayPresetId() {
    for (final preset in overlayController.presets) {
      if (preset.id == controller.selectedOverlayPresetId) return preset.id;
    }
    return null;
  }

  OverlayPreset? _presetById(String? id) {
    for (final preset in overlayController.presets) {
      if (preset.id == id) return preset;
    }
    return null;
  }
}

class _TemplateDropdown extends StatelessWidget {
  const _TemplateDropdown({
    required this.enabled,
    required this.controller,
    required this.templatesController,
    required this.overlayController,
  });

  final bool enabled;
  final HomeController controller;
  final TemplatesController templatesController;
  final OverlayToolsController overlayController;

  @override
  Widget build(BuildContext context) {
    final selectedId = _selectedTemplateId();
    return DropdownButtonFormField<String>(
      key: ValueKey(
        'template-$selectedId-${templatesController.templates.length}',
      ),
      initialValue: selectedId,
      isExpanded: true,
      decoration: const InputDecoration(labelText: 'Template'),
      items: [
        for (final template in templatesController.templates)
          DropdownMenuItem(value: template.id, child: Text(template.name)),
      ],
      hint: Text(
        templatesController.templates.isEmpty ? 'No templates saved' : 'Select',
      ),
      onChanged: enabled
          ? (id) async {
              final template = _templateById(id);
              await controller.setTemplate(template);
              if (template != null) {
                await overlayController.applySettings(template.overlaySettings);
              }
            }
          : null,
    );
  }

  String? _selectedTemplateId() {
    for (final template in templatesController.templates) {
      if (template.id == controller.selectedTemplateId) return template.id;
    }
    return null;
  }

  ProjectTemplate? _templateById(String? id) {
    for (final template in templatesController.templates) {
      if (template.id == id) return template;
    }
    return null;
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
    final gap = AppResponsive.cardGap(context);
    final table = QueueTable(
      jobs: controller.jobs,
      selectedVideoPaths: controller.selectedQueueVideoPaths,
      onSelectionChanged: controller.isProcessing
          ? null
          : controller.toggleQueuedVideoSelection,
      onRemoveVideo: controller.isProcessing
          ? null
          : controller.removeQueuedVideo,
    );

    return LayoutBuilder(
      builder: (context, constraints) {
        if (constraints.maxHeight.isFinite && constraints.maxHeight < 120) {
          return table;
        }

        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Expanded(
                  child: Text(
                    controller.selectedBatchQueue == null
                        ? 'Queue'
                        : 'Queue - ${controller.selectedBatchQueue!.displayName}',
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
            if (controller.batchQueues.isNotEmpty) ...[
              SizedBox(height: gap / 2),
              SingleChildScrollView(
                scrollDirection: Axis.horizontal,
                child: Row(
                  children: [
                    for (final queue in controller.batchQueues)
                      Padding(
                        padding: EdgeInsets.only(right: gap / 2),
                        child: ChoiceChip(
                          selected: queue.id == controller.selectedBatchQueueId,
                          label: Text(
                            '${queue.displayName} (${queue.jobs.length})',
                          ),
                          onSelected: (_) =>
                              controller.selectBatchQueue(queue.id),
                        ),
                      ),
                  ],
                ),
              ),
            ],
            if (controller.jobs.isNotEmpty) ...[
              SizedBox(height: gap / 2),
              Wrap(
                spacing: gap / 2,
                runSpacing: gap / 2,
                children: [
                  OutlinedButton.icon(
                    onPressed:
                        controller.selectedQueueVideoPaths.isEmpty ||
                            controller.isProcessing
                        ? null
                        : controller.removeSelectedQueuedVideos,
                    icon: const Icon(Icons.remove_done),
                    label: const Text('Remove selected videos'),
                  ),
                  OutlinedButton.icon(
                    onPressed: controller.isProcessing
                        ? null
                        : controller.clearQueue,
                    icon: const Icon(Icons.clear_all),
                    label: const Text('Clear queue'),
                  ),
                ],
              ),
            ],
            SizedBox(height: gap),
            Expanded(child: table),
          ],
        );
      },
    );
  }
}

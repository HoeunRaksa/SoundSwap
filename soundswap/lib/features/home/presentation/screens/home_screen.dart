import 'dart:async';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:path/path.dart' as p;
import 'package:soundswap/core/responsive/app_responsive.dart';
import 'package:soundswap/core/video/duration_mode.dart';
import 'package:soundswap/core/video/video_output_settings.dart';
import 'package:soundswap/features/home/data/models/audio_settings.dart';
import 'package:soundswap/features/home/data/models/batch_profile.dart';
import 'package:soundswap/features/home/data/models/image_to_video_settings.dart';
import 'package:soundswap/features/home/presentation/screens/project_edit_screen.dart';
import 'package:soundswap/features/home/presentation/state/home_controller.dart';
import 'package:soundswap/features/home/presentation/widgets/folder_selector_card.dart';
import 'package:soundswap/features/home/presentation/widgets/metric_card.dart';
import 'package:soundswap/features/home/presentation/widgets/progress_panel.dart';
import 'package:soundswap/features/home/presentation/widgets/queue_table.dart';
import 'package:soundswap/features/overlay_tools/data/models/overlay_preset.dart';

import 'package:soundswap/features/overlay_tools/presentation/state/overlay_tools_controller.dart';

import 'package:soundswap/features/templates/data/models/project_template.dart';
import 'package:soundswap/features/templates/data/services/template_validator.dart';
import 'package:soundswap/features/templates/presentation/state/templates_controller.dart';
import 'package:soundswap/features/templates/presentation/widgets/missing_assets_dialog.dart';
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
            'Batch Audio Processor',
            style: Theme.of(context).textTheme.headlineMedium?.copyWith(
              fontSize: AppResponsive.titleSize(context),
              fontWeight: FontWeight.bold,
            ),
          ),
          SizedBox(height: gap / 2),
          Text(
            'Randomly select audio and timing for each video, then export MP4 files with the original video stream preserved.',
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
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        SizedBox(
          width: AppResponsive.sidebarWidth(context),
          child: ScrollConfiguration(
            behavior: _NoScrollbarBehavior(),
            child: SingleChildScrollView(
              padding: EdgeInsets.only(bottom: gap * 2),
              child: _ControlsPanel(
                controller: controller,
                overlayController: overlayController,
                templatesController: templatesController,
                showFooter: false,
              ),
            ),
          ),
        ),
        SizedBox(width: gap),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Batch Audio Processor',
                style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                  fontSize: AppResponsive.titleSize(context),
                  fontWeight: FontWeight.bold,
                ),
              ),
              SizedBox(height: gap / 2),
              Text(
                'Randomly select audio and timing for each video, then export MP4 files with the original video stream preserved.',
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
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        SizedBox(
          width: AppResponsive.sidebarWidth(context),
          // Hide the scrollbar — the left panel scrolls silently
          child: ScrollConfiguration(
            behavior: _NoScrollbarBehavior(),
            child: SingleChildScrollView(
              padding: EdgeInsets.only(bottom: gap * 2),
              child: _ControlsPanel(
                controller: controller,
                overlayController: overlayController,
                templatesController: templatesController,
                showFooter: false,
              ),
            ),
          ),
        ),
        SizedBox(width: gap),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Batch Audio Processor',
                style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                  fontSize: AppResponsive.titleSize(context),
                  fontWeight: FontWeight.bold,
                ),
              ),
              SizedBox(height: gap / 2),
              Text(
                'Randomly select audio and timing for each video, then export MP4 files with the original video stream preserved.',
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
  Timer? _debounceTimer;

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
    _debounceTimer?.cancel();
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
          onCreate: () => _createBatchProfileDialog(),
          onStart: widget.controller.startBatchProfile,
          onStop: widget.controller.stopProcessing,
          onEdit: (profile) => Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => ProjectEditScreen(
                profile: profile,
                homeController: widget.controller,
              ),
            ),
          ),
          onDelete: _confirmDeleteBatchProfile,
        ),
        SizedBox(height: gap),
        _MultiFolderSelectorCard(
          title: 'Video folders',
          paths: widget.controller.videoFolders,
          icon: Icons.movie_creation_outlined,
          onAdd: widget.controller.pickVideoFolder,
          onRemove: widget.controller.removeVideoFolder,
        ),
        SizedBox(height: gap),
        _MultiFolderSelectorCard(
          title: 'Audio folders',
          paths: widget.controller.audioFolders,
          icon: Icons.library_music_outlined,
          onAdd: widget.controller.pickAudioFolder,
          onRemove: widget.controller.removeAudioFolder,
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
          onChanged: (value) {
            if (_debounceTimer?.isActive ?? false) _debounceTimer!.cancel();
            _debounceTimer = Timer(const Duration(milliseconds: 300), () {
              widget.controller.setOutputNamePrefix(value);
            });
          },
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
          Card(
            clipBehavior: Clip.antiAlias,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(AppResponsive.cardRadius(context)),
              side: BorderSide(color: colorScheme.outlineVariant),
            ),
            elevation: 0,
            child: ExpansionTile(
              title: Text(
                'Advanced settings',
                style: TextStyle(
                  fontSize: AppResponsive.bodySize(context),
                  fontWeight: FontWeight.bold,
                  color: colorScheme.onSurface,
                ),
              ),
              leading: Icon(
                Icons.settings_suggest_outlined,
                color: colorScheme.primary,
                size: AppResponsive.iconSize(context),
              ),
              children: [
                Padding(
                  padding: EdgeInsets.fromLTRB(gap, 0, gap, gap),
                  child: _GeneratorOptionsPanel(
                    controller: widget.controller,
                    overlayController: widget.overlayController!,
                    templatesController: widget.templatesController!,
                  ),
                ),
              ],
            ),
          ),
        ],
        SizedBox(height: gap),
        SizedBox(
          height: AppResponsive.buttonHeight(context) + 8,
          child: _AnimatedOutlinedButton(
            onPressed: widget.controller.canGenerateQueue
                ? widget.controller.generateQueue
                : null,
            icon: Icons.playlist_add_check,
            label: 'Prepare Queue',
            bodySize: AppResponsive.bodySize(context),
            iconSize: AppResponsive.iconSize(context),
          ),
        ),
        SizedBox(height: gap / 2),
        SizedBox(
          height: AppResponsive.buttonHeight(context) + 8,
          child: widget.controller.isProcessing
              ? _AnimatedStopButton(
                  onPressed: widget.controller.stopRequested
                      ? null
                      : widget.controller.stopProcessing,
                  bodySize: AppResponsive.bodySize(context),
                  iconSize: AppResponsive.iconSize(context),
                )
              : _AnimatedFilledButton(
                  onPressed: widget.controller.canStart
                      ? () => _confirmStartBatch(context)
                      : null,
                  isRunning: false,
                  bodySize: AppResponsive.bodySize(context),
                  iconSize: AppResponsive.iconSize(context),
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
    final ctrl = widget.controller;
    final gap = AppResponsive.cardGap(context);
    final colorScheme = Theme.of(context).colorScheme;

    final videoCount = ctrl.videos.length;
    final imageCount = ctrl.detectedImageCount;
    final audioCount = ctrl.audios.length;
    final outputSizeLabel = ctrl.outputSize.label;

    final removeOldResults = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Row(
          children: [
            Icon(Icons.preview_outlined, color: colorScheme.primary),
            const SizedBox(width: 10),
            const Text('Export Preview'),
          ],
        ),
        content: SizedBox(
          width: 520,
          child: SingleChildScrollView(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              mainAxisSize: MainAxisSize.min,
              children: [
                _ExportSummaryRow(
                  icon: Icons.video_library_outlined,
                  label: 'Media',
                  value:
                      '$videoCount files${imageCount > 0 ? ' ($imageCount images)' : ''}',
                ),
                _ExportSummaryRow(
                  icon: Icons.library_music_outlined,
                  label: 'Audio',
                  value: '$audioCount tracks',
                ),
                _ExportSummaryRow(
                  icon: Icons.style,
                  label: 'Template',
                  value: ctrl.useTemplate
                      ? (ctrl.selectedTemplateId ?? 'Current settings')
                      : 'None',
                ),
                _ExportSummaryRow(
                  icon: Icons.folder_copy_outlined,
                  label: 'Output Folder',
                  value: ctrl.outputFolderPath ?? 'Not selected',
                ),
                _ExportSummaryRow(
                  icon: Icons.aspect_ratio,
                  label: 'Output Size',
                  value: outputSizeLabel,
                ),
                _ExportSummaryRow(
                  icon: Icons.audiotrack,
                  label: 'Audio Mode',
                  value: ctrl.audioSettings.mode.label,
                ),
                _ExportSummaryRow(
                  icon: Icons.volume_up,
                  label: 'New Audio Vol',
                  value: '${ctrl.audioSettings.newAudioVolume}%',
                ),
                if (ctrl.audioSettings.mode == AudioMode.mixOriginalAndNew)
                  _ExportSummaryRow(
                    icon: Icons.volume_down,
                    label: 'Original Vol',
                    value: '${ctrl.audioSettings.originalAudioVolume}%',
                  ),
                _ExportSummaryRow(
                  icon: Icons.timer_outlined,
                  label: 'Duration Mode',
                  value: ctrl.durationMode.label,
                ),
                if (ctrl.useOverlay)
                  const _ExportSummaryRow(
                    icon: Icons.layers,
                    label: 'Overlays',
                    value: 'Enabled',
                  ),
                if (imageCount > 0) ...[
                  _ExportSummaryRow(
                    icon: Icons.image,
                    label: 'Image Duration',
                    value:
                        '${ctrl.imageToVideoSettings.durationValue} ${ctrl.imageToVideoSettings.durationUnit.label}',
                  ),
                  _ExportSummaryRow(
                    icon: Icons.crop,
                    label: 'Image Fit',
                    value: ctrl.imageToVideoSettings.fitMode.label,
                  ),
                ],
                SizedBox(height: gap),
                Text(
                  'Choose how to handle existing numbered results:',
                  style: TextStyle(
                    fontSize: AppResponsive.bodySize(context) - 1,
                    color: colorScheme.onSurfaceVariant,
                  ),
                ),
              ],
            ),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () {
              debugPrint('Export Preview action selected: cancel');
              Navigator.pop(context);
            },
            child: const Text('Cancel'),
          ),
          OutlinedButton(
            onPressed: () {
              debugPrint('Export Preview action selected: remove_old_start_fresh');
              Navigator.pop(context, true);
            },
            child: const Text('Remove old & start fresh'),
          ),
          FilledButton(
            onPressed: () {
              debugPrint('Export Preview action selected: keep_old_continue');
              Navigator.pop(context, false);
            },
            child: const Text('Keep old & continue'),
          ),
        ],
      ),
    );
    if (removeOldResults == null) return;
    await widget.controller.startProcessing(
      removeOldResults: removeOldResults,
      onMissingAssetsDetected: (missingAssets) async {
        final Map<String, ProjectTemplate> initialTemplates = {};
        for (final job in widget.controller.jobs) {
          if (job.template != null) {
            initialTemplates[job.template!.id] = job.template!;
          }
        }
        
        return await showDialog<TemplateValidationResult>(
          context: context,
          barrierDismissible: false,
          builder: (context) => MissingAssetsDialog(
            initialMissingAssets: missingAssets,
            initialTemplates: initialTemplates,
          ),
        );
      },
    );
  }

  Future<void> _createBatchProfileDialog() async {
    final nameController = TextEditingController(
      text: widget.controller.outputNamePrefix,
    );
    final prefixController = TextEditingController(
      text: widget.controller.outputNamePrefix,
    );
    var videoFolders = List<String>.from(widget.controller.videoFolders);
    var audioFolders = List<String>.from(widget.controller.audioFolders);
    var outputFolder = widget.controller.outputFolderPath ?? '';
    final result =
        await showDialog<
          ({
            String name,
            List<String> videoFolders,
            List<String> audioFolders,
            String outputFolder,
            String prefix,
          })
        >(
          context: context,
          builder: (context) => StatefulBuilder(
            builder: (context, setDialogState) {
              final gap = AppResponsive.cardGap(context);
              return AlertDialog(
                title: const Text('Add batch profile'),
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
                        _BatchProfileMultiFolderPicker(
                          label: 'Video folders',
                          paths: videoFolders,
                          icon: Icons.video_library_outlined,
                          onAdd: () async {
                            final path = await _dialogFolderPicker.pickFolder(
                              dialogTitle: 'Select video folder',
                            );
                            if (path == null || !context.mounted) return;
                            setDialogState(() {
                              if (!videoFolders.contains(path)) videoFolders.add(path);
                            });
                          },
                          onRemove: (path) {
                            setDialogState(() => videoFolders.remove(path));
                          },
                        ),
                        SizedBox(height: gap),
                        _BatchProfileMultiFolderPicker(
                          label: 'Audio folders',
                          paths: audioFolders,
                          icon: Icons.library_music_outlined,
                          onAdd: () async {
                            final path = await _dialogFolderPicker.pickFolder(
                              dialogTitle: 'Select audio folder',
                            );
                            if (path == null || !context.mounted) return;
                            setDialogState(() {
                              if (!audioFolders.contains(path)) audioFolders.add(path);
                            });
                          },
                          onRemove: (path) {
                            setDialogState(() => audioFolders.remove(path));
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
                      videoFolders: videoFolders,
                      audioFolders: audioFolders,
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
    await widget.controller.createBatchProfile(
      name: result.name,
      videoFolders: result.videoFolders,
      audioFolders: result.audioFolders,
      outputFolderPath: result.outputFolder,
      outputPrefix: result.prefix,
    );
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
      color: colorScheme.surfaceContainerLow,
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
                    'Projects',
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
    final colorScheme = Theme.of(context).colorScheme;
    return SizedBox(
      width: width,
      child: Card(
        elevation: selected ? 2 : 0,
        color: colorScheme.surfaceContainerLow,
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
                value: profile.videoFolders.isEmpty 
                    ? 'None' 
                    : profile.videoFolders.length == 1 
                        ? _folderName(profile.videoFolders.first) 
                        : '${profile.videoFolders.length} folders',
                tooltip: profile.videoFolders.join('\n'),
              ),
              _ServiceMetaLine(
                icon: Icons.library_music_outlined,
                title: 'Audio',
                value: profile.audioFolders.isEmpty 
                    ? 'None' 
                    : profile.audioFolders.length == 1 
                        ? _folderName(profile.audioFolders.first) 
                        : '${profile.audioFolders.length} folders',
                tooltip: profile.audioFolders.join('\n'),
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
        return Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [

                CheckboxListTile(
                  contentPadding: EdgeInsets.symmetric(
                    horizontal: gap * 0.2,
                  ),
                  visualDensity: const VisualDensity(
                    horizontal: -1,
                    vertical: -1,
                  ),
                  title: const Text('Join images into videos'),
                  subtitle: const Text('OFF = videos only, ON = images can become video clips.'),
                  value: controller.joinImages,
                  onChanged: (value) => controller.setJoinImages(value ?? false),
                ),

                SizedBox(height: gap * 0.6),

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

                SizedBox(height: gap),
                const Divider(),
                SizedBox(height: gap * 0.5),
                Text(
                  'Audio Settings',
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: AppResponsive.bodySize(context) - 1,
                    color: colorScheme.onSurface,
                  ),
                ),
                SizedBox(height: gap * 0.5),

                DropdownButtonFormField<AudioMode>(
                  key: ValueKey(controller.audioSettings.mode),
                  initialValue: controller.audioSettings.mode,
                  isExpanded: true,
                  decoration: const InputDecoration(
                    labelText: 'Audio mode',
                  ),
                  items: [
                    for (final mode in AudioMode.values)
                      DropdownMenuItem(
                        value: mode,
                        child: Text(mode.label),
                      ),
                  ],
                  onChanged: (value) {
                    if (value != null) {
                      if (value == AudioMode.mixOriginalAndNew && controller.audioSettings.mode != AudioMode.mixOriginalAndNew) {
                        controller.setAudioSettings(
                          controller.audioSettings.copyWith(
                            mode: value,
                            originalAudioVolume: 100,
                            newAudioVolume: 25,
                          ),
                        );
                      } else if (value == AudioMode.replaceOriginal && controller.audioSettings.mode != AudioMode.replaceOriginal) {
                        controller.setAudioSettings(
                          controller.audioSettings.copyWith(
                            mode: value,
                            originalAudioVolume: 0,
                            newAudioVolume: 100,
                          ),
                        );
                      } else {
                        controller.setAudioSettings(
                          controller.audioSettings.copyWith(mode: value),
                        );
                      }
                    }
                  },
                ),

                if (controller.audioSettings.mode == AudioMode.mixOriginalAndNew) ...[
                  SizedBox(height: gap * 0.5),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        'Original Audio Volume',
                        style: TextStyle(fontSize: AppResponsive.bodySize(context) - 2),
                      ),
                      Text(
                        '${controller.audioSettings.originalAudioVolume}%',
                        style: TextStyle(
                          fontSize: AppResponsive.bodySize(context) - 2,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                  Slider(
                    value: controller.audioSettings.originalAudioVolume.toDouble(),
                    min: 0,
                    max: 100,
                    divisions: 100,
                    onChanged: (value) {
                      controller.setAudioSettings(
                        controller.audioSettings.copyWith(
                          originalAudioVolume: value.round(),
                        ),
                      );
                    },
                  ),
                ],

                if (controller.audioSettings.mode != AudioMode.keepOriginalOnly) ...[
                  SizedBox(height: gap * 0.5),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        'New Audio Volume',
                        style: TextStyle(fontSize: AppResponsive.bodySize(context) - 2),
                      ),
                      Text(
                        '${controller.audioSettings.newAudioVolume}%',
                        style: TextStyle(
                          fontSize: AppResponsive.bodySize(context) - 2,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                  Slider(
                    value: controller.audioSettings.newAudioVolume.toDouble(),
                    min: 0,
                    max: 300,
                    divisions: 300,
                    onChanged: (value) {
                      controller.setAudioSettings(
                        controller.audioSettings.copyWith(
                          newAudioVolume: value.round(),
                        ),
                      );
                    },
                  ),
                ],

                SizedBox(height: gap),
                const Divider(),
                SizedBox(height: gap * 0.5),
                Text(
                  'Duration Settings',
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: AppResponsive.bodySize(context) - 1,
                    color: colorScheme.onSurface,
                  ),
                ),
                SizedBox(height: gap * 0.5),

                DropdownButtonFormField<DurationMode>(
                  key: ValueKey(controller.durationMode),
                  initialValue: controller.durationMode,
                  isExpanded: true,
                  decoration: const InputDecoration(
                    labelText: 'Duration mode',
                  ),
                  items: [
                    for (final mode in DurationMode.values)
                      DropdownMenuItem(
                        value: mode,
                        child: Text(mode.label),
                      ),
                  ],
                  onChanged: (value) {
                    if (value != null) {
                      controller.setDurationMode(value);
                    }
                  },
                ),

                if (controller.detectedImageCount > 0) ...[
                  SizedBox(height: gap),
                  const Divider(),
                  SizedBox(height: gap * 0.5),
                  Text(
                    'Image to Video Settings',
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: AppResponsive.bodySize(context) - 1,
                      color: colorScheme.onSurface,
                    ),
                  ),
                  SizedBox(height: gap * 0.5),
                  Row(
                    children: [
                      Expanded(
                        child: TextFormField(
                          key: ValueKey(controller.imageToVideoSettings.durationValue),
                          initialValue: controller.imageToVideoSettings.durationValue.toString(),
                          keyboardType: TextInputType.number,
                          decoration: const InputDecoration(
                            labelText: 'Duration',
                          ),
                          onChanged: (val) {
                            final intValue = int.tryParse(val) ?? 10;
                            controller.setImageToVideoSettings(
                              controller.imageToVideoSettings.copyWith(
                                durationValue: intValue,
                              ),
                            );
                          },
                        ),
                      ),
                      SizedBox(width: gap / 2),
                      Expanded(
                        child: DropdownButtonFormField<ImageDurationUnit>(
                          key: ValueKey(controller.imageToVideoSettings.durationUnit),
                          initialValue: controller.imageToVideoSettings.durationUnit,
                          decoration: const InputDecoration(
                            labelText: 'Unit',
                          ),
                          items: [
                            for (final unit in ImageDurationUnit.values)
                              DropdownMenuItem(
                                value: unit,
                                child: Text(unit.label),
                              ),
                          ],
                          onChanged: (val) {
                            if (val != null) {
                              controller.setImageToVideoSettings(
                                controller.imageToVideoSettings.copyWith(
                                  durationUnit: val,
                                ),
                              );
                            }
                          },
                        ),
                      ),
                    ],
                  ),
                  SizedBox(height: gap),
                  DropdownButtonFormField<ImageFitMode>(
                    key: ValueKey(controller.imageToVideoSettings.fitMode),
                    initialValue: controller.imageToVideoSettings.fitMode,
                    decoration: const InputDecoration(
                      labelText: 'Image fit mode',
                    ),
                    items: [
                      for (final mode in ImageFitMode.values)
                        DropdownMenuItem(
                          value: mode,
                          child: Text(mode.label),
                        ),
                    ],
                    onChanged: (val) {
                      if (val != null) {
                        controller.setImageToVideoSettings(
                          controller.imageToVideoSettings.copyWith(
                            fitMode: val,
                          ),
                        );
                      }
                    },
                  ),
                ],

                SizedBox(height: gap),
                const Divider(),
                SizedBox(height: gap * 0.5),
                Text(
                  'Retry Settings',
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: AppResponsive.bodySize(context) - 1,
                    color: colorScheme.onSurface,
                  ),
                ),
                SizedBox(height: gap * 0.5),

                DropdownButtonFormField<int>(
                  key: ValueKey(controller.maxRetries),
                  initialValue: controller.maxRetries,
                  isExpanded: true,
                  decoration: const InputDecoration(
                    labelText: 'Max Retry Count',
                  ),
                  items: [
                    for (var r = 0; r <= 10; r++)
                      DropdownMenuItem(
                        value: r,
                        child: Text(r == 0 ? 'No Retries (0)' : '$r retries'),
                      ),
                  ],
                  onChanged: (value) {
                    if (value != null) {
                      controller.setMaxRetries(value);
                    }
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

    controller.setAvailableTemplates(templatesController.templates);

    final count = controller.selectedTemplateIds.length;




    String label = 'Select templates';
    if (count > 1) {
      label = '$count templates selected';
    } else if (count == 1) {
      final tid = controller.selectedTemplateIds.first;
      label = _templateById(tid)?.name ?? 'Select templates';
    } else if (templatesController.templates.isEmpty) {
      label = 'No templates saved';
    }

    return InputDecorator(
      decoration: const InputDecoration(labelText: 'Templates', contentPadding: EdgeInsets.symmetric(horizontal: 12, vertical: 8)),
      child: InkWell(
        onTap: enabled && templatesController.templates.isNotEmpty ? () => _showTemplateDialog(context) : null,
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Expanded(child: Text(label, overflow: TextOverflow.ellipsis)),
            const Icon(Icons.arrow_drop_down),
          ],
        ),
      ),
    );
  }

  ProjectTemplate? _templateById(String id) {
    try {
      return templatesController.templates.firstWhere((t) => t.id == id);
    } catch (_) {
      return null;
    }
  }

  void _showTemplateDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text('Select Templates'),
          content: SizedBox(
            width: 400,
            child: StatefulBuilder(
              builder: (context, setState) {
                return ListView(
                  shrinkWrap: true,
                  children: [
                    for (final t in templatesController.templates)
                      CheckboxListTile(
                        title: Text(t.name),
                        value: controller.selectedTemplateIds.contains(t.id),
                        onChanged: (val) {
                          controller.toggleTemplateSelection(t.id);

                          if (controller.selectedTemplateIds.length == 1) {
                            final loaded = _templateById(controller.selectedTemplateIds.first);
                            if (loaded != null) {
                              controller.setTemplate(loaded);
                              overlayController.applySettings(loaded.overlaySettings);
                            }
                          }

                          setState(() {});
                        },
                      ),
                  ],
                );
              },
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Done'),
            ),
          ],
        );
      },
    );
  }
}

class _MetricsGrid extends StatelessWidget {
  const _MetricsGrid({required this.controller});

  final HomeController controller;

  @override
  Widget build(BuildContext context) {
    final gap = AppResponsive.cardGap(context);
    final totalFinished = controller.successCount + controller.failedCount;
    final successRate = totalFinished > 0
        ? '${(controller.successCount / totalFinished * 100).toStringAsFixed(1)}%'
        : '0.0%';

    final metrics = [
      MetricCard(
        label: 'Total Videos',
        value: '${controller.jobs.length}',
        icon: Icons.video_file,
      ),
      MetricCard(
        label: 'Success',
        value: '${controller.successCount}',
        icon: Icons.check_circle_outline,
        iconColor: Colors.green.shade700,
      ),
      MetricCard(
        label: 'Failed',
        value: '${controller.failedCount}',
        icon: Icons.error_outline,
        iconColor: Theme.of(context).colorScheme.error,
      ),
      MetricCard(
        label: 'Skipped',
        value: '${controller.skippedCount}',
        icon: Icons.next_plan_outlined,
        iconColor: Colors.grey.shade600,
      ),
      MetricCard(
        label: 'Audio Files',
        value: '${controller.audios.length}',
        icon: Icons.audio_file,
      ),
      MetricCard(
        label: 'Success Rate',
        value: successRate,
        icon: Icons.percent,
      ),
    ];

    return GridView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: AppResponsive.isSmall(context)
            ? 2
            : AppResponsive.isMedium(context)
                ? 2
                : 3,
        crossAxisSpacing: gap,
        mainAxisSpacing: gap,
        mainAxisExtent: 80,
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
      onToggleSkip: controller.isProcessing
          ? null
          : controller.toggleJobSkip,
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
                    label: const Text('Remove selected'),
                  ),
                  OutlinedButton.icon(
                    onPressed:
                        controller.selectedQueueVideoPaths.isEmpty ||
                            controller.isProcessing
                        ? null
                        : controller.skipSelectedJobs,
                    icon: const Icon(Icons.next_plan_outlined),
                    label: const Text('Skip selected'),
                  ),
                  OutlinedButton.icon(
                    onPressed:
                        controller.selectedQueueVideoPaths.isEmpty ||
                            controller.isProcessing
                        ? null
                        : controller.unskipSelectedJobs,
                    icon: const Icon(Icons.play_circle_outline),
                    label: const Text('Unskip selected'),
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

class _ExportSummaryRow extends StatelessWidget {
  const _ExportSummaryRow({
    required this.icon,
    required this.label,
    required this.value,
  });

  final IconData icon;
  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final gap = AppResponsive.cardGap(context);

    return Padding(
      padding: EdgeInsets.symmetric(vertical: gap / 4),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(
            icon,
            size: AppResponsive.iconSize(context) - 4,
            color: colorScheme.onSurfaceVariant,
          ),
          SizedBox(width: gap / 2),
          SizedBox(
            width: 140,
            child: Text(
              label,
              style: TextStyle(
                fontWeight: FontWeight.bold,
                fontSize: AppResponsive.bodySize(context) - 1,
                color: colorScheme.onSurface,
              ),
            ),
          ),
          Expanded(
            child: Text(
              value,
              style: TextStyle(
                fontSize: AppResponsive.bodySize(context) - 1,
                color: colorScheme.onSurfaceVariant,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// ── Layout helpers ────────────────────────────────────────────────────────────────────

/// A [ScrollBehavior] that hides the scrollbar thumb entirely.
/// Used on the left controls panel so the scrollbar doesn’t appear
/// in the middle of the home layout.
class _NoScrollbarBehavior extends ScrollBehavior {
  @override
  Widget buildScrollbar(
    BuildContext context,
    Widget child,
    ScrollableDetails details,
  ) =>
      child; // no scrollbar
}

// ── Animated action buttons ─────────────────────────────────────────────────────

/// Outlined button with a subtle hover scale animation.
class _AnimatedOutlinedButton extends StatefulWidget {
  const _AnimatedOutlinedButton({
    required this.onPressed,
    required this.icon,
    required this.label,
    required this.bodySize,
    required this.iconSize,
  });

  final VoidCallback? onPressed;
  final IconData icon;
  final String label;
  final double bodySize;
  final double iconSize;

  @override
  State<_AnimatedOutlinedButton> createState() =>
      _AnimatedOutlinedButtonState();
}

class _AnimatedOutlinedButtonState extends State<_AnimatedOutlinedButton> {
  bool _hovered = false;

  @override
  Widget build(BuildContext context) {
    return MouseRegion(
      onEnter: (_) => setState(() => _hovered = true),
      onExit: (_) => setState(() => _hovered = false),
      child: AnimatedScale(
        scale: _hovered && widget.onPressed != null ? 1.015 : 1.0,
        duration: const Duration(milliseconds: 120),
        curve: Curves.easeOut,
        child: SizedBox(
          width: double.infinity,
          child: OutlinedButton.icon(
            onPressed: widget.onPressed,
            icon: Icon(widget.icon, size: widget.iconSize),
            label: Text(
              widget.label,
              style: TextStyle(fontSize: widget.bodySize),
            ),
          ),
        ),
      ),
    );
  }
}

/// Filled primary button with scale + glow animation on hover.
/// Shows a spinner + ‘Running’ when [isRunning] is true.
class _AnimatedFilledButton extends StatefulWidget {
  const _AnimatedFilledButton({
    required this.onPressed,
    required this.isRunning,
    required this.bodySize,
    required this.iconSize,
  });

  final VoidCallback? onPressed;
  final bool isRunning;
  final double bodySize;
  final double iconSize;

  @override
  State<_AnimatedFilledButton> createState() => _AnimatedFilledButtonState();
}

class _AnimatedFilledButtonState extends State<_AnimatedFilledButton> {
  bool _hovered = false;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final canPress = widget.onPressed != null;

    return MouseRegion(
      onEnter: (_) => setState(() => _hovered = true),
      onExit: (_) => setState(() => _hovered = false),
      child: AnimatedScale(
        scale: _hovered && canPress ? 1.015 : 1.0,
        duration: const Duration(milliseconds: 120),
        curve: Curves.easeOut,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 180),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(10),
            boxShadow: (_hovered && canPress)
                ? [
                    BoxShadow(
                      color: colorScheme.primary.withValues(alpha: 0.35),
                      blurRadius: 14,
                      offset: const Offset(0, 4),
                    ),
                  ]
                : [],
          ),
          child: SizedBox(
            width: double.infinity,
            child: FilledButton.icon(
              onPressed: widget.onPressed,
              icon: widget.isRunning
                  ? SizedBox(
                      width: widget.iconSize - 4,
                      height: widget.iconSize - 4,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        color: colorScheme.onPrimary,
                      ),
                    )
                  : Icon(
                      Icons.play_arrow_rounded,
                      size: widget.iconSize + 2,
                    ),
              label: Text(
                widget.isRunning ? 'Running…' : 'Start Processing',
                style: TextStyle(
                  fontSize: widget.bodySize,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _AnimatedStopButton extends StatefulWidget {
  const _AnimatedStopButton({
    required this.onPressed,
    required this.bodySize,
    required this.iconSize,
  });

  final VoidCallback? onPressed;
  final double bodySize;
  final double iconSize;

  @override
  State<_AnimatedStopButton> createState() => _AnimatedStopButtonState();
}

class _AnimatedStopButtonState extends State<_AnimatedStopButton> {
  bool _hovered = false;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final canPress = widget.onPressed != null;

    return MouseRegion(
      onEnter: (_) => setState(() => _hovered = true),
      onExit: (_) => setState(() => _hovered = false),
      child: AnimatedScale(
        scale: _hovered && canPress ? 1.015 : 1.0,
        duration: const Duration(milliseconds: 120),
        curve: Curves.easeOut,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 180),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(10),
            boxShadow: (_hovered && canPress)
                ? [
                    BoxShadow(
                      color: colorScheme.error.withValues(alpha: 0.35),
                      blurRadius: 14,
                      offset: const Offset(0, 4),
                    ),
                  ]
                : [],
          ),
          child: SizedBox(
            width: double.infinity,
            child: FilledButton.icon(
              onPressed: widget.onPressed,
              style: FilledButton.styleFrom(
                backgroundColor: colorScheme.error,
                foregroundColor: colorScheme.onError,
              ),
              icon: canPress
                  ? Icon(
                      Icons.stop_rounded,
                      size: widget.iconSize + 2,
                    )
                  : SizedBox(
                      width: widget.iconSize - 4,
                      height: widget.iconSize - 4,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        color: colorScheme.onError,
                      ),
                    ),
              label: Text(
                canPress ? 'Stop Batch' : 'Stopping...',
                style: TextStyle(
                  fontSize: widget.bodySize,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ),
        ),
      ),
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

class _BatchProfileMultiFolderPicker extends StatelessWidget {
  const _BatchProfileMultiFolderPicker({
    required this.label,
    required this.paths,
    required this.icon,
    required this.onAdd,
    required this.onRemove,
  });

  final String label;
  final List<String> paths;
  final IconData icon;
  final VoidCallback onAdd;
  final void Function(String) onRemove;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Row(
          children: [
            Icon(icon, size: 18),
            const SizedBox(width: 8),
            Text(
              label,
              style: const TextStyle(fontWeight: FontWeight.bold),
            ),
            const Spacer(),
            OutlinedButton.icon(
              onPressed: onAdd,
              icon: const Icon(Icons.add, size: 16),
              label: const Text('Add Folder'),
              style: OutlinedButton.styleFrom(
                visualDensity: VisualDensity.compact,
              ),
            ),
          ],
        ),
        if (paths.isNotEmpty) const SizedBox(height: 8),
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
    );
  }

  String _folderName(String path) {
    final segments = path.split(Platform.isWindows ? '\\' : '/');
    return segments.isNotEmpty ? segments.last : path;
  }
}

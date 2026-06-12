import 'dart:io';
import 'package:flutter/material.dart';
import 'package:path/path.dart' as p;
import 'package:soundswap/core/responsive/app_responsive.dart';
import 'package:soundswap/core/video/video_output_settings.dart';
import 'package:soundswap/features/folder_watcher/data/models/folder_watcher_profile.dart';
import 'package:soundswap/features/folder_watcher/data/models/watch_processing_item.dart';
import 'package:soundswap/features/folder_watcher/presentation/state/folder_watcher_controller.dart';
import 'package:soundswap/features/home/data/models/batch_profile.dart';
import 'package:soundswap/features/home/presentation/state/home_controller.dart';
import 'package:soundswap/features/result_history/presentation/state/result_history_controller.dart';
import 'package:soundswap/features/templates/data/models/project_template.dart';
import 'package:soundswap/features/templates/presentation/state/templates_controller.dart';
import 'package:soundswap/shared/services/folder_picker_service.dart';
import 'package:soundswap/shared/services/output_naming_service.dart';
import 'package:soundswap/shared/widgets/empty_state.dart';
import 'package:soundswap/shared/widgets/feature_page.dart';

class FolderWatcherScreen extends StatelessWidget {
  const FolderWatcherScreen({
    required this.controller,
    required this.historyController,
    required this.templatesController,
    required this.homeController,
    super.key,
  });

  final FolderWatcherController controller;
  final ResultHistoryController historyController;
  final TemplatesController templatesController;
  final HomeController homeController;

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: Listenable.merge([
        controller,
        templatesController,
        homeController,
      ]),
      builder: (context, _) {
        return FeaturePage(
          title: 'Folder Watcher',
          subtitle:
              'Create watcher profiles that auto-process new videos into separate result folders.',
          children: [
            SettingsSection(
              title: 'Watcher profiles',
              icon: Icons.visibility_outlined,
              children: [
                FilledButton.icon(
                  onPressed: () => _createProfile(context),
                  icon: const Icon(Icons.add),
                  label: const Text('Create watcher profile'),
                ),
                if (controller.errorMessage != null)
                  Text(
                    controller.errorMessage!,
                    style: TextStyle(
                      color: Theme.of(context).colorScheme.error,
                    ),
                  ),
                if (controller.profiles.isEmpty)
                  const SizedBox(
                    height: 180,
                    child: EmptyState(
                      icon: Icons.visibility_off_outlined,
                      title: 'No watcher profiles',
                      message:
                          'Create a profile with video, audio, and result folders to start automatic processing.',
                    ),
                  )
                else
                  for (final profile in controller.profiles)
                    _ProfileCard(
                      profile: profile,
                      controller: controller,
                      historyController: historyController,
                      templatesController: templatesController,
                      onDuplicate: (path) =>
                          _confirmProcessAgain(context, path),
                      onPermissionError: (folder) =>
                          _showPermissionError(context, folder),
                      onEdit: () => _editProfile(context, profile),
                      onDuplicateProfile: () =>
                          controller.duplicateProfile(profile.id),
                      onEditPrefix: () => _editPrefix(context, profile),
                      onDelete: () => _confirmDeleteProfile(context, profile),
                    ),
              ],
            ),
            SettingsSection(
              title: 'Processing queue',
              icon: Icons.pending_actions_outlined,
              children: [
                if (controller.processingQueue.isEmpty)
                  const SizedBox(
                    height: 160,
                    child: EmptyState(
                      icon: Icons.hourglass_empty,
                      title: 'No queued videos',
                      message: 'Detected videos will process automatically.',
                    ),
                  )
                else
                  for (final item in controller.processingQueue)
                    _QueueTile(item: item),
              ],
            ),
            SettingsSection(
              title: 'Latest detected videos',
              icon: Icons.movie_filter_outlined,
              children: [
                if (controller.detectedVideos.isEmpty)
                  const SizedBox(
                    height: 160,
                    child: EmptyState(
                      icon: Icons.video_file_outlined,
                      title: 'No new videos',
                      message: 'Detected files will appear here.',
                    ),
                  )
                else
                  for (final video in controller.detectedVideos.take(8))
                    ListTile(
                      contentPadding: EdgeInsets.zero,
                      leading: const Icon(Icons.video_file),
                      title: Text(p.basename(video)),
                      subtitle: Text(video),
                    ),
              ],
            ),
            SettingsSection(
              title: 'Latest completed result',
              icon: Icons.check_circle_outline,
              children: [
                if (controller.latestCompletedResult == null)
                  Text(
                    'No completed result yet.',
                    style: TextStyle(fontSize: AppResponsive.bodySize(context)),
                  )
                else
                  ListTile(
                    contentPadding: EdgeInsets.zero,
                    title: Text(
                      p.basename(controller.latestCompletedResult!.outputPath),
                    ),
                    subtitle: Text(
                      '${controller.latestCompletedResult!.status.name} - ${controller.latestCompletedResult!.resultFolderPath}',
                    ),
                  ),
              ],
            ),
          ],
        );
      },
    );
  }

  Future<void> _createProfile(BuildContext context) async {
    final nameController = TextEditingController(text: 'New watcher');
    String? selectedBatchProfileId;

    final result = await showDialog<({String name, BatchProfile? importProfile})>(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setDialogState) {
          final gap = AppResponsive.cardGap(context);
          return AlertDialog(
            title: const Text('Create watcher profile'),
            content: SizedBox(
              width: 450,
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  TextField(
                    controller: nameController,
                    autofocus: true,
                    decoration: const InputDecoration(
                      labelText: 'Profile name',
                      hintText: 'e.g. Auto Watcher PVC',
                    ),
                  ),
                  SizedBox(height: gap),
                  DropdownButtonFormField<String>(
                    initialValue: selectedBatchProfileId,
                    isExpanded: true,
                    decoration: const InputDecoration(
                      labelText: 'Import settings from Batch Profile',
                    ),
                    items: [
                      const DropdownMenuItem<String>(
                        value: null,
                        child: Text('None (Start empty)'),
                      ),
                      for (final profile in homeController.batchProfiles)
                        DropdownMenuItem(
                          value: profile.id,
                          child: Text(profile.name),
                        ),
                    ],
                    onChanged: (val) {
                      setDialogState(() {
                        selectedBatchProfileId = val;
                      });
                    },
                  ),
                ],
              ),
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context),
                child: const Text('Cancel'),
              ),
              FilledButton(
                onPressed: () {
                  final name = nameController.text.trim();
                  final importProfile = selectedBatchProfileId == null
                      ? null
                      : homeController.batchProfiles.firstWhere((p) => p.id == selectedBatchProfileId);
                  Navigator.pop(context, (
                    name: name.isEmpty ? 'Watcher profile' : name,
                    importProfile: importProfile,
                  ));
                },
                child: const Text('Create'),
              ),
            ],
          );
        },
      ),
    );

    nameController.dispose();
    if (result != null) {
      await controller.createProfile(
        result.name,
        importBatchProfile: result.importProfile,
      );
    }
  }

  Future<void> _editProfile(
    BuildContext context,
    FolderWatcherProfile profile,
  ) async {
    final result = await showDialog<FolderWatcherProfile>(
      context: context,
      builder: (context) => _EditProfileDialog(
        profile: profile,
        templatesController: templatesController,
      ),
    );

    if (result != null) {
      await controller.saveProfile(result);
    }
  }

  Future<void> _editPrefix(
    BuildContext context,
    FolderWatcherProfile profile,
  ) async {
    final prefixController = TextEditingController(text: profile.outputPrefix);
    final prefix = await showDialog<String>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Output name prefix'),
        content: TextField(
          controller: prefixController,
          autofocus: true,
          decoration: const InputDecoration(
            labelText: 'Prefix',
            hintText: OutputNamingService.defaultPrefix,
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(context, prefixController.text),
            child: const Text('Save'),
          ),
        ],
      ),
    );
    prefixController.dispose();
    if (prefix != null) await controller.setProfilePrefix(profile.id, prefix);
  }

  Future<void> _confirmDeleteProfile(
    BuildContext context,
    FolderWatcherProfile profile,
  ) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete watcher profile?'),
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
    if (confirmed == true) await controller.deleteProfile(profile.id);
  }

  Future<bool> _confirmProcessAgain(BuildContext context, String path) async {
    return await showDialog<bool>(
          context: context,
          builder: (context) => AlertDialog(
            title: const Text('Process again?'),
            content: const Text('You used this video already. Process again?'),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context, false),
                child: const Text('Cancel'),
              ),
              FilledButton(
                onPressed: () => Navigator.pop(context, true),
                child: const Text('Process Again'),
              ),
            ],
          ),
        ) ??
        false;
  }

  Future<void> _showPermissionError(BuildContext context, String folder) async {
    final selectAgain = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Folder access failed'),
        content: Text(
          'Windows could not access this folder:\n$folder\n\nPlease select the folder again.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Select Again'),
          ),
        ],
      ),
    );
    if (selectAgain != true) return;
    for (final profile in controller.profiles) {
      if (profile.videoFolders.contains(folder)) {
        await controller.pickProfileVideoFolder(profile.id);
        return;
      }
      if (profile.audioFolders.contains(folder)) {
        await controller.pickProfileAudioFolder(profile.id);
        return;
      }
      if (profile.resultFolderPath == folder) {
        await controller.pickProfileResultFolder(profile.id);
        return;
      }
    }
  }
}



class _ProfileCard extends StatelessWidget {
  const _ProfileCard({
    required this.profile,
    required this.controller,
    required this.historyController,
    required this.templatesController,
    required this.onDuplicate,
    required this.onPermissionError,
    required this.onEdit,
    required this.onDuplicateProfile,
    required this.onEditPrefix,
    required this.onDelete,
  });

  final FolderWatcherProfile profile;
  final FolderWatcherController controller;
  final ResultHistoryController historyController;
  final TemplatesController templatesController;
  final DuplicateConfirmCallback onDuplicate;
  final PermissionErrorCallback onPermissionError;
  final VoidCallback onEdit;
  final VoidCallback onDuplicateProfile;
  final VoidCallback onEditPrefix;
  final VoidCallback onDelete;

  @override
  Widget build(BuildContext context) {
    final gap = AppResponsive.cardGap(context);
    final watching = controller.isProfileWatching(profile.id);
    final statusColor = watching ? Colors.green.shade700 : Colors.blueGrey;
    final prefix = profile.outputPrefix.trim().isEmpty
        ? OutputNamingService.defaultPrefix
        : profile.outputPrefix.trim();
    final template = _templateById(profile.templateId);

    return Card(
      color: watching
          ? Colors.green.withValues(alpha: 0.04)
          : Theme.of(context).colorScheme.surface,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(AppResponsive.cardRadius(context)),
        side: BorderSide(
          color: statusColor.withValues(alpha: watching ? 0.7 : 0.2),
        ),
      ),
      child: Padding(
        padding: EdgeInsets.all(gap),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        profile.name,
                        style: TextStyle(
                          fontSize: AppResponsive.bodySize(context) + 2,
                          fontWeight: FontWeight.bold,
                          color: Theme.of(context).colorScheme.onSurface,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Row(
                        children: [
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                            decoration: BoxDecoration(
                              color: Theme.of(context).colorScheme.primaryContainer,
                              borderRadius: BorderRadius.circular(4),
                            ),
                            child: Text(
                              'Template: ${template?.name ?? "None"}',
                              style: TextStyle(
                                fontSize: AppResponsive.bodySize(context) - 4,
                                color: Theme.of(context).colorScheme.onPrimaryContainer,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                          const SizedBox(width: 8),
                          Text(
                            'Prefix: $prefix',
                            style: TextStyle(
                              fontSize: AppResponsive.bodySize(context) - 3,
                              color: Theme.of(context).colorScheme.onSurfaceVariant,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
                Switch(
                  value: watching,
                  activeThumbColor: Colors.green.shade700,
                  onChanged: (val) {
                    if (val) {
                      controller.startWatching(
                        profileId: profile.id,
                        historyController: historyController,
                        onDuplicate: onDuplicate,
                        onPermissionError: onPermissionError,
                      );
                    } else {
                      controller.stopWatching(profile.id);
                    }
                  },
                ),
                const SizedBox(width: 8),
                _WatcherStatusChip(
                  label: watching ? 'running' : 'stopped',
                  color: statusColor,
                ),
              ],
            ),
            const SizedBox(height: 8),
            // Flow Arrow Folder Summary
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 4.0),
              child: Row(
                children: [
                  Icon(Icons.video_library_outlined, size: 14, color: Theme.of(context).colorScheme.onSurfaceVariant),
                  const SizedBox(width: 4),
                  Expanded(
                    child: Text(
                      profile.videoFolders.isNotEmpty ? p.basename(profile.videoFolders.first) : 'No Videos',
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(fontSize: AppResponsive.bodySize(context) - 2),
                    ),
                  ),
                  const Text('  ➔  '),
                  Icon(Icons.folder_copy_outlined, size: 14, color: Theme.of(context).colorScheme.onSurfaceVariant),
                  const SizedBox(width: 4),
                  Expanded(
                    child: Text(
                      profile.resultFolderPath != null ? p.basename(profile.resultFolderPath!) : 'No Results',
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(fontSize: AppResponsive.bodySize(context) - 2),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 8),
            Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                OutlinedButton.icon(
                  onPressed: onEdit,
                  icon: const Icon(Icons.edit_outlined, size: 14),
                  label: const Text('Edit Settings'),
                  style: OutlinedButton.styleFrom(
                    visualDensity: VisualDensity.compact,
                  ),
                ),
                const SizedBox(width: 8),
                IconButton(
                  tooltip: 'Duplicate profile',
                  onPressed: onDuplicateProfile,
                  visualDensity: VisualDensity.compact,
                  icon: const Icon(Icons.copy, size: 18),
                ),
                IconButton(
                  tooltip: 'Delete',
                  onPressed: onDelete,
                  visualDensity: VisualDensity.compact,
                  icon: Icon(
                    Icons.delete_outline,
                    size: 18,
                    color: Theme.of(context).colorScheme.error,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  ProjectTemplate? _templateById(String? id) {
    for (final template in templatesController.templates) {
      if (template.id == id) return template;
    }
    return null;
  }
}

class _WatcherStatusChip extends StatelessWidget {
  const _WatcherStatusChip({required this.label, required this.color});

  final String label;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
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



class _QueueTile extends StatelessWidget {
  const _QueueTile({required this.item});

  final WatchProcessingItem item;

  @override
  Widget build(BuildContext context) {
    return ListTile(
      contentPadding: EdgeInsets.zero,
      leading: Icon(_icon),
      title: Text(p.basename(item.videoPath)),
      subtitle: Text(
        [
          if (item.audioPath != null) 'Audio: ${p.basename(item.audioPath!)}',
          if (item.outputPath != null)
            'Output: ${p.basename(item.outputPath!)}',
          if (item.errorMessage != null) item.errorMessage!,
        ].join('\n'),
      ),
      trailing: Text(item.status.name),
    );
  }

  IconData get _icon {
    return switch (item.status) {
      WatchProcessingStatus.queued => Icons.schedule,
      WatchProcessingStatus.waiting => Icons.hourglass_bottom,
      WatchProcessingStatus.processing => Icons.autorenew,
      WatchProcessingStatus.success => Icons.check_circle,
      WatchProcessingStatus.failed => Icons.error,
    };
  }
}

class _EditProfileDialog extends StatefulWidget {
  const _EditProfileDialog({
    required this.profile,
    required this.templatesController,
  });

  final FolderWatcherProfile profile;
  final TemplatesController templatesController;

  @override
  State<_EditProfileDialog> createState() => _EditProfileDialogState();
}

class _EditProfileDialogState extends State<_EditProfileDialog> {
  final _folderPickerService = FolderPickerService();
  late final TextEditingController _nameController;
  late final TextEditingController _prefixController;

  List<String> _videoFolders = [];
  List<String> _audioFolders = [];
  String? _resultFolderPath;
  late String? _templateId;
  late bool _useOverlay;
  late VideoOutputSize _outputSize;
  late VideoFitMode _fitMode;

  @override
  void initState() {
    super.initState();
    final p = widget.profile;
    _nameController = TextEditingController(text: p.name);
    _prefixController = TextEditingController(text: p.outputPrefix);
    _videoFolders = List.of(p.videoFolders);
    _audioFolders = List.of(p.audioFolders);
    _resultFolderPath = p.resultFolderPath;
    _templateId = widget.templatesController.templates
            .any((t) => t.id == p.templateId)
        ? p.templateId
        : null;
    _useOverlay = p.useOverlay;
    _outputSize = p.outputSize;
    _fitMode = p.fitMode;
  }

  @override
  void dispose() {
    _nameController.dispose();
    _prefixController.dispose();
    super.dispose();
  }

  Future<void> _addVideoFolder() async {
    final path = await _folderPickerService.pickFolder(
      dialogTitle: 'Select source video folder',
    );
    if (path != null && !_videoFolders.contains(path)) {
      setState(() => _videoFolders.add(path));
    }
  }

  void _removeVideoFolder(String path) {
    setState(() => _videoFolders.remove(path));
  }

  Future<void> _addAudioFolder() async {
    final path = await _folderPickerService.pickFolder(
      dialogTitle: 'Select source audio folder',
    );
    if (path != null && !_audioFolders.contains(path)) {
      setState(() => _audioFolders.add(path));
    }
  }

  void _removeAudioFolder(String path) {
    setState(() => _audioFolders.remove(path));
  }

  Future<void> _pickResultFolder() async {
    final path = await _folderPickerService.pickFolder(
      dialogTitle: 'Select result folder',
    );
    if (path != null) {
      setState(() => _resultFolderPath = path);
    }
  }

  void _applyTemplate(ProjectTemplate template) {
    setState(() {
      _templateId = template.id;
      _videoFolders = template.videoFolders.isNotEmpty ? List.of(template.videoFolders) : [];
      _audioFolders = template.audioFolders.isNotEmpty ? List.of(template.audioFolders) : [];
      _resultFolderPath = template.outputFolder;
      _prefixController.text = template.outputPrefix;
      _useOverlay = template.useOverlay;
      _outputSize = template.outputSize;
      _fitMode = template.fitMode;
    });
  }

  @override
  Widget build(BuildContext context) {
    final gap = AppResponsive.cardGap(context);

    final templateItems = [
      const DropdownMenuItem<String>(
        value: null,
        child: Text('None'),
      ),
      for (final template in widget.templatesController.templates)
        DropdownMenuItem(
          value: template.id,
          child: Text(template.name),
        ),
    ];

    final fields = <Widget>[
      TextField(
        controller: _nameController,
        autofocus: true,
        decoration: const InputDecoration(labelText: 'Profile name'),
      ),
      _MultiFolderEditRow(
        label: 'Source video folders',
        paths: _videoFolders,
        onAdd: _addVideoFolder,
        onRemove: _removeVideoFolder,
      ),
      _MultiFolderEditRow(
        label: 'Source audio folders',
        paths: _audioFolders,
        onAdd: _addAudioFolder,
        onRemove: _removeAudioFolder,
      ),
      _FolderEditRow(
        label: 'Result folder',
        path: _resultFolderPath,
        onPressed: _pickResultFolder,
      ),
      TextField(
        controller: _prefixController,
        decoration: const InputDecoration(
          labelText: 'Output prefix',
          hintText: OutputNamingService.defaultPrefix,
        ),
      ),
      DropdownButtonFormField<String>(
        initialValue: _templateId,
        isExpanded: true,
        decoration: const InputDecoration(labelText: 'Apply template'),
        items: templateItems,
        hint: const Text('Select template'),
        onChanged: (id) {
          if (id == null) {
            setState(() => _templateId = null);
          } else {
            final t = widget.templatesController.templates
                .firstWhere((element) => element.id == id);
            _applyTemplate(t);
          }
        },
      ),
      SwitchListTile(
        contentPadding: EdgeInsets.zero,
        title: const Text('Overlay tools on/off'),
        value: _useOverlay,
        onChanged: (val) => setState(() => _useOverlay = val),
      ),
      DropdownButtonFormField<VideoOutputSize>(
        initialValue: _outputSize,
        isExpanded: true,
        decoration: const InputDecoration(labelText: 'Output size'),
        items: [
          for (final size in VideoOutputSize.values)
            DropdownMenuItem(value: size, child: Text(size.label)),
        ],
        onChanged: (value) {
          if (value != null) setState(() => _outputSize = value);
        },
      ),
      DropdownButtonFormField<VideoFitMode>(
        initialValue: _fitMode,
        isExpanded: true,
        decoration: const InputDecoration(labelText: 'Fit mode'),
        items: [
          for (final mode in VideoFitMode.values)
            DropdownMenuItem(value: mode, child: Text(mode.label)),
        ],
        onChanged: (value) {
          if (value != null) setState(() => _fitMode = value);
        },
      ),
    ];

    return AlertDialog(
      title: const Text('Edit Watcher Profile'),
      contentPadding: EdgeInsets.fromLTRB(gap * 1.5, gap, gap * 1.5, gap / 2),
      actionsPadding: EdgeInsets.fromLTRB(gap, gap / 2, gap, gap),
      content: SizedBox(
        width: 500,
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              for (var i = 0; i < fields.length; i++) ...[
                fields[i],
                if (i < fields.length - 1) SizedBox(height: gap),
              ],
            ],
          ),
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text('Cancel'),
        ),
        FilledButton(
          onPressed: () {
            final updated = widget.profile.copyWith(
              name: _nameController.text.trim().isEmpty
                  ? 'Watcher profile'
                  : _nameController.text.trim(),
              videoFolders: _videoFolders,
              audioFolders: _audioFolders,
              resultFolderPath: _resultFolderPath,
              outputPrefix: _prefixController.text,
              templateId: _templateId,
              useOverlay: _useOverlay,
              outputSize: _outputSize,
              fitMode: _fitMode,
            );
            Navigator.pop(context, updated);
          },
          child: const Text('Save'),
        ),
      ],
    );
  }
}

class _FolderEditRow extends StatelessWidget {
  const _FolderEditRow({
    required this.label,
    required this.path,
    required this.onPressed,
  });

  final String label;
  final String? path;
  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4.0),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label,
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: AppResponsive.bodySize(context) - 1,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  path ?? 'Not selected',
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    fontSize: AppResponsive.bodySize(context) - 2,
                    color: theme.colorScheme.onSurfaceVariant
                        .withValues(alpha: 0.8),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 8),
          OutlinedButton(
            onPressed: onPressed,
            style: OutlinedButton.styleFrom(
              visualDensity: VisualDensity.compact,
            ),
            child: const Text('Select'),
          ),
        ],
      ),
    );
  }
}

class _MultiFolderEditRow extends StatelessWidget {
  const _MultiFolderEditRow({
    required this.label,
    required this.paths,
    required this.onAdd,
    required this.onRemove,
  });

  final String label;
  final List<String> paths;
  final VoidCallback onAdd;
  final void Function(String) onRemove;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  label,
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: AppResponsive.bodySize(context) - 1,
                  ),
                ),
              ),
              OutlinedButton.icon(
                onPressed: onAdd,
                icon: const Icon(Icons.add, size: 14),
                label: const Text('Add'),
                style: OutlinedButton.styleFrom(
                  visualDensity: VisualDensity.compact,
                ),
              ),
            ],
          ),
          if (paths.isEmpty)
            Padding(
              padding: const EdgeInsets.only(top: 4.0),
              child: Text(
                'Not selected',
                style: TextStyle(
                  fontSize: AppResponsive.bodySize(context) - 2,
                  color: theme.colorScheme.onSurfaceVariant.withValues(alpha: 0.8),
                ),
              ),
            )
          else
            Padding(
              padding: const EdgeInsets.only(top: 8.0),
              child: Wrap(
                spacing: 8.0,
                runSpacing: 8.0,
                children: paths.map((path) {
                  return InputChip(
                    label: Text(
                      _folderName(path),
                      style: const TextStyle(fontSize: 12),
                    ),
                    onDeleted: () => onRemove(path),
                    tooltip: path,
                    deleteIcon: const Icon(Icons.close, size: 14),
                  );
                }).toList(),
              ),
            ),
        ],
      ),
    );
  }

  String _folderName(String path) {
    final segments = path.split(Platform.isWindows ? '\\' : '/');
    return segments.isNotEmpty ? segments.last : path;
  }
}

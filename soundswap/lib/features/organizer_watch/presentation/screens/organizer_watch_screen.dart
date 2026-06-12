import 'package:flutter/material.dart';
import 'package:path/path.dart' as p;
import 'package:soundswap/core/responsive/app_responsive.dart';
import 'package:soundswap/features/folder_organizer/data/models/organizer_options.dart';
import 'package:soundswap/features/folder_watcher/data/models/watch_processing_item.dart';
import 'package:soundswap/features/organizer_watch/data/models/organizer_watch_profile.dart';
import 'package:soundswap/features/organizer_watch/presentation/state/organizer_watch_controller.dart';
import 'package:soundswap/features/result_history/presentation/state/result_history_controller.dart';
import 'package:soundswap/shared/services/folder_picker_service.dart';
import 'package:soundswap/shared/widgets/empty_state.dart';

class OrganizerWatchScreen extends StatefulWidget {
  const OrganizerWatchScreen({
    super.key,
    required this.controller,
    required this.historyController,
  });

  final OrganizerWatchController controller;
  final ResultHistoryController historyController;

  @override
  State<OrganizerWatchScreen> createState() => _OrganizerWatchScreenState();
}

class _OrganizerWatchScreenState extends State<OrganizerWatchScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      widget.controller.load();
    });
  }

  Future<void> _onPermissionError(String path) async {
    if (!mounted) return;
    final selectAgain = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Access Denied'),
        content: Text(
          'SoundSwap needs permission to access this folder:\n$path\n\nPlease select the folder again to grant permission.',
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
    // Just prompt edit
  }

  @override
  Widget build(BuildContext context) {
    final gap = AppResponsive.cardGap(context);

    return ListenableBuilder(
      listenable: Listenable.merge([widget.controller, widget.historyController]),
      builder: (context, _) {
        final controller = widget.controller;
        final historyController = widget.historyController;
        return ListView(
          padding: EdgeInsets.all(gap),
          children: [
            Row(
              children: [
                Expanded(
                  child: Text(
                    'Organizer Watch Profiles',
                    style: Theme.of(context).textTheme.headlineSmall,
                  ),
                ),
                FilledButton.icon(
                  onPressed: () => _createProfile(context, controller),
                  icon: const Icon(Icons.add),
                  label: const Text('New Profile'),
                ),
              ],
            ),
            if (controller.errorMessage != null)
              Padding(
                padding: const EdgeInsets.only(top: 16.0),
                child: Material(
                  color: Theme.of(context).colorScheme.errorContainer,
                  borderRadius: BorderRadius.circular(8),
                  child: Padding(
                    padding: const EdgeInsets.all(12.0),
                    child: Row(
                      children: [
                        Icon(Icons.error_outline,
                            color: Theme.of(context).colorScheme.error),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            controller.errorMessage!,
                            style: TextStyle(
                              color: Theme.of(context).colorScheme.onErrorContainer,
                            ),
                          ),
                        ),
                        IconButton(
                          icon: const Icon(Icons.close),
                          onPressed: () {
                            controller.clearError();
                          },
                          color: Theme.of(context).colorScheme.error,
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            SizedBox(height: gap),
            if (controller.profiles.isEmpty)
              const EmptyState(
                icon: Icons.auto_awesome_motion,
                title: 'No Organizer Profiles',
                message: 'Create a profile to automatically organize files dropping into a folder.',
              )
            else
              for (final profile in controller.profiles)
                _ProfileCard(
                  profile: profile,
                  controller: controller,
                  historyController: historyController,
                  onPermissionError: _onPermissionError,
                  onEdit: () => _editProfile(context, controller, profile),
                  onDuplicateProfile: () => controller.duplicateProfile(profile.id),
                  onDelete: () => _confirmDelete(context, controller, profile),
                ),
            SizedBox(height: gap),
            Card(
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(AppResponsive.cardRadius(context)),
              ),
              child: Padding(
                padding: EdgeInsets.all(gap),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Row(
                      children: [
                        const Icon(Icons.list_alt),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            'Processing Queue',
                            style: Theme.of(context).textTheme.titleMedium?.copyWith(
                                  fontWeight: FontWeight.bold,
                                ),
                          ),
                        ),
                        if (controller.queue.isNotEmpty)
                          TextButton.icon(
                            onPressed: controller.clearQueue,
                            icon: const Icon(Icons.clear_all, size: 16),
                            label: const Text('Clear Queue'),
                          ),
                      ],
                    ),
                    const SizedBox(height: 16),
                    if (controller.queue.isEmpty)
                      Text(
                        'Queue is empty. Waiting for media files...',
                        style: TextStyle(fontSize: AppResponsive.bodySize(context)),
                      )
                    else
                      for (final item in controller.queue.take(15))
                        _QueueTile(item: item),
                  ],
                ),
              ),
            ),
          ],
        );
      },
    );
  }

  Future<void> _createProfile(
    BuildContext context,
    OrganizerWatchController controller,
  ) async {
    final nameController = TextEditingController(text: 'New Organizer Watcher');
    final result = await showDialog<String>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Create Profile'),
        content: TextField(
          controller: nameController,
          autofocus: true,
          decoration: const InputDecoration(labelText: 'Profile name'),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(context, nameController.text.trim()),
            child: const Text('Create'),
          ),
        ],
      ),
    );
    nameController.dispose();
    if (result != null && result.isNotEmpty) {
      await controller.createProfile(result);
    }
  }

  Future<void> _editProfile(
    BuildContext context,
    OrganizerWatchController controller,
    OrganizerWatchProfile profile,
  ) async {
    final result = await showDialog<OrganizerWatchProfile>(
      context: context,
      builder: (context) => _EditProfileDialog(profile: profile),
    );
    if (result != null) {
      await controller.saveProfile(result);
    }
  }

  Future<void> _confirmDelete(
    BuildContext context,
    OrganizerWatchController controller,
    OrganizerWatchProfile profile,
  ) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete profile?'),
        content: Text('Are you sure you want to delete "${profile.name}"?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(context, true),
            style: FilledButton.styleFrom(
              backgroundColor: Theme.of(context).colorScheme.error,
              foregroundColor: Theme.of(context).colorScheme.onError,
            ),
            child: const Text('Delete'),
          ),
        ],
      ),
    );
    if (confirmed == true) {
      await controller.deleteProfile(profile.id);
    }
  }
}

class _ProfileCard extends StatelessWidget {
  const _ProfileCard({
    required this.profile,
    required this.controller,
    required this.historyController,
    required this.onPermissionError,
    required this.onEdit,
    required this.onDuplicateProfile,
    required this.onDelete,
  });

  final OrganizerWatchProfile profile;
  final OrganizerWatchController controller;
  final ResultHistoryController historyController;
  final PermissionErrorCallback onPermissionError;
  final VoidCallback onEdit;
  final VoidCallback onDuplicateProfile;
  final VoidCallback onDelete;

  @override
  Widget build(BuildContext context) {
    final gap = AppResponsive.cardGap(context);
    final watching = controller.isProfileWatching(profile.id);
    final statusColor = watching ? Colors.green.shade700 : Colors.blueGrey;

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
      margin: EdgeInsets.only(bottom: gap),
      child: Padding(
        padding: EdgeInsets.all(gap),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Row(
              children: [
                Expanded(
                  child: Text(
                    profile.name,
                    style: TextStyle(
                      fontSize: AppResponsive.bodySize(context) + 2,
                      fontWeight: FontWeight.bold,
                      color: Theme.of(context).colorScheme.onSurface,
                    ),
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
                        onPermissionError: onPermissionError,
                      );
                    } else {
                      controller.stopWatching(profile.id);
                    }
                  },
                ),
                const SizedBox(width: 8),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: statusColor.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: statusColor.withValues(alpha: 0.3)),
                  ),
                  child: Text(
                    watching ? 'running' : 'stopped',
                    style: TextStyle(
                      color: statusColor,
                      fontSize: 12,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            Row(
              children: [
                const Icon(Icons.login, size: 14),
                const SizedBox(width: 4),
                Expanded(
                  child: Text(
                    profile.sourceFolderPath ?? 'No source folder',
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(fontSize: AppResponsive.bodySize(context) - 2),
                  ),
                ),
                const Text('  ➔  '),
                const Icon(Icons.folder_copy_outlined, size: 14),
                const SizedBox(width: 4),
                Expanded(
                  child: Text(
                    profile.destinationFolderPath ?? 'No destination folder',
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(fontSize: AppResponsive.bodySize(context) - 2),
                  ),
                ),
              ],
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
                  icon: const Icon(Icons.delete_outline, size: 18),
                  color: Theme.of(context).colorScheme.error,
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _EditProfileDialog extends StatefulWidget {
  const _EditProfileDialog({required this.profile});

  final OrganizerWatchProfile profile;

  @override
  State<_EditProfileDialog> createState() => _EditProfileDialogState();
}

class _EditProfileDialogState extends State<_EditProfileDialog> {
  final _folderPickerService = FolderPickerService();
  late final TextEditingController _nameController;

  String? _sourceFolderPath;
  String? _destinationFolderPath;
  late OrganizerOptions _options;

  @override
  void initState() {
    super.initState();
    final p = widget.profile;
    _nameController = TextEditingController(text: p.name);
    _sourceFolderPath = p.sourceFolderPath;
    _destinationFolderPath = p.destinationFolderPath;
    _options = p.options;
  }

  @override
  void dispose() {
    _nameController.dispose();
    super.dispose();
  }

  Future<void> _pickSourceFolder() async {
    final path = await _folderPickerService.pickFolder(
      dialogTitle: 'Select source folder',
    );
    if (path != null) {
      setState(() => _sourceFolderPath = path);
    }
  }

  Future<void> _pickDestFolder() async {
    final path = await _folderPickerService.pickFolder(
      dialogTitle: 'Select destination folder',
    );
    if (path != null) {
      setState(() => _destinationFolderPath = path);
    }
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('Edit Organizer Watch Profile'),
      content: SizedBox(
        width: 500,
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              TextField(
                controller: _nameController,
                decoration: const InputDecoration(labelText: 'Profile name'),
              ),
              const SizedBox(height: 16),
              _FolderEditRow(
                label: 'Source Folder (Incoming Media)',
                path: _sourceFolderPath,
                onPressed: _pickSourceFolder,
              ),
              const SizedBox(height: 16),
              _FolderEditRow(
                label: 'Destination Folder (Organized output)',
                path: _destinationFolderPath,
                onPressed: _pickDestFolder,
              ),
              const SizedBox(height: 16),
              const Divider(),
              const SizedBox(height: 8),
              SwitchListTile(
                title: const Text('Prefer visual orientation'),
                subtitle: const Text('Detect vertical content inside horizontal video frames.'),
                value: _options.preferVisualOrientation,
                onChanged: (val) {
                  setState(() {
                    _options = _options.copyWith(preferVisualOrientation: val);
                  });
                },
              ),
              SwitchListTile(
                title: const Text('Convert HEIC to PNG'),
                subtitle: const Text('Convert HEIC/HEIF images to universally supported PNG.'),
                value: _options.convertHeicToPng,
                onChanged: (val) {
                  setState(() {
                    _options = _options.copyWith(convertHeicToPng: val);
                  });
                },
              ),
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
              name: _nameController.text.trim().isEmpty ? 'Profile' : _nameController.text.trim(),
              sourceFolderPath: _sourceFolderPath,
              destinationFolderPath: _destinationFolderPath,
              options: _options,
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
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13),
        ),
        const SizedBox(height: 4),
        Row(
          children: [
            Expanded(
              child: Text(
                path ?? 'Not selected',
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(fontSize: 12),
              ),
            ),
            const SizedBox(width: 8),
            OutlinedButton(
              onPressed: onPressed,
              style: OutlinedButton.styleFrom(visualDensity: VisualDensity.compact),
              child: const Text('Select'),
            ),
          ],
        ),
      ],
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
          if (item.outputPath != null) 'Output: ${p.basename(item.outputPath!)}',
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

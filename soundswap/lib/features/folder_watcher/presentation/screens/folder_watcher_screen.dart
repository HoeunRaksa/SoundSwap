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
              title: 'Start from batch profile',
              icon: Icons.folder_special_outlined,
              children: [
                if (homeController.batchProfiles.isEmpty)
                  const SizedBox(
                    height: 130,
                    child: EmptyState(
                      icon: Icons.folder_off_outlined,
                      title: 'No batch profiles',
                      message:
                          'Run a successful Home batch or add a batch profile on Home first.',
                    ),
                  )
                else
                  _BatchProfileWatcherStarter(
                    controller: controller,
                    historyController: historyController,
                    profiles: homeController.batchProfiles,
                    onDuplicate: (path) => _confirmProcessAgain(context, path),
                    onPermissionError: (folder) =>
                        _showPermissionError(context, folder),
                  ),
              ],
            ),
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
    final name = await showDialog<String>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Create watcher profile'),
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
            onPressed: () => Navigator.pop(context, nameController.text),
            child: const Text('Create'),
          ),
        ],
      ),
    );
    nameController.dispose();
    if (name != null) await controller.createProfile(name);
  }

  Future<void> _editProfile(
      BuildContext context,
      FolderWatcherProfile profile,
      ) async {
    final nameController = TextEditingController(text: profile.name);
    final prefixController = TextEditingController(text: profile.outputPrefix);
    final gap = AppResponsive.cardGap(context);

    final result = await showDialog<({String name, String prefix})>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Edit watcher profile'),
        contentPadding: EdgeInsets.fromLTRB(gap * 1.5, gap, gap * 1.5, gap / 2),
        actionsPadding: EdgeInsets.fromLTRB(gap, gap / 2, gap, gap),
        content: SizedBox(
          width: 420,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: nameController,
                autofocus: true,
                decoration: const InputDecoration(labelText: 'Profile name'),
              ),
              SizedBox(height: gap),
              TextField(
                controller: prefixController,
                decoration: const InputDecoration(
                  labelText: 'Output prefix',
                  hintText: OutputNamingService.defaultPrefix,
                ),
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
            onPressed: () => Navigator.pop(context, (
            name: nameController.text,
            prefix: prefixController.text,
            )),
            child: const Text('Save'),
          ),
        ],
      ),
    );

    nameController.dispose();
    prefixController.dispose();

    if (result != null) {
      await controller.updateProfileDetails(
        profileId: profile.id,
        name: result.name,
        outputPrefix: result.prefix,
      );
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
      if (profile.videoFolderPath == folder) {
        await controller.pickProfileVideoFolder(profile.id);
        return;
      }
      if (profile.audioFolderPath == folder) {
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

class _BatchProfileWatcherStarter extends StatelessWidget {
  const _BatchProfileWatcherStarter({
    required this.controller,
    required this.historyController,
    required this.profiles,
    required this.onDuplicate,
    required this.onPermissionError,
  });

  final FolderWatcherController controller;
  final ResultHistoryController historyController;
  final List<BatchProfile> profiles;
  final DuplicateConfirmCallback onDuplicate;
  final PermissionErrorCallback onPermissionError;

  @override
  Widget build(BuildContext context) {
    final selected = _selectedProfile;
    final prefix = selected == null
        ? OutputNamingService.defaultPrefix
        : selected.outputPrefix.trim().isEmpty
        ? OutputNamingService.defaultPrefix
        : selected.outputPrefix.trim();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        DropdownButtonFormField<String>(
          initialValue: selected?.id,
          isExpanded: true,
          decoration: const InputDecoration(labelText: 'Batch profile'),
          items: [
            for (final profile in profiles)
              DropdownMenuItem(value: profile.id, child: Text(profile.name)),
          ],
          hint: const Text('Select batch profile'),
          onChanged: controller.setSelectedBatchProfile,
        ),
        if (selected != null) ...[
          Text(
            [
              'Video: ${selected.videoFolderPath ?? 'Not selected'}',
              'Audio: ${selected.audioFolderPath ?? 'Not selected'}',
              'Result: ${selected.outputFolderPath ?? 'Not selected'}',
              'Prefix: $prefix',
            ].join('\n'),
            style: TextStyle(fontSize: AppResponsive.bodySize(context) - 1),
          ),
          SizedBox(height: AppResponsive.cardGap(context) / 2),
        ],
        FilledButton.icon(
          onPressed: selected == null
              ? null
              : () => controller.startBatchProfileWatch(
                  batchProfile: selected,
                  historyController: historyController,
                  onDuplicate: onDuplicate,
                  onPermissionError: onPermissionError,
                ),
          icon: const Icon(Icons.play_arrow),
          label: const Text('Start Watch'),
        ),
      ],
    );
  }

  BatchProfile? get _selectedProfile {
    for (final profile in profiles) {
      if (profile.id == controller.selectedBatchProfileId) return profile;
    }
    return null;
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

    return Card(
      color: watching
          ? Colors.green.withValues(alpha: 0.06)
          : Theme.of(context).colorScheme.surface,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(AppResponsive.cardRadius(context)),
        side: BorderSide(
          color: statusColor.withValues(alpha: watching ? 0.8 : 0.25),
        ),
      ),
      child: Padding(
        padding: EdgeInsets.all(gap),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Row(
              children: [
                Icon(
                  watching ? Icons.radio_button_checked : Icons.visibility,
                  color: statusColor,
                ),
                SizedBox(width: gap / 2),
                Expanded(
                  child: Text(
                    profile.name,
                    style: TextStyle(
                      fontSize: AppResponsive.bodySize(context) + 2,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                ),
                _WatcherStatusChip(
                  label: watching ? 'running' : 'stopped',
                  color: statusColor,
                ),
              ],
            ),
            _FolderRow(
              label: 'Source video folder',
              path: profile.videoFolderPath,
              onPressed: () => controller.pickProfileVideoFolder(profile.id),
            ),
            _FolderRow(
              label: 'Source audio folder',
              path: profile.audioFolderPath,
              onPressed: () => controller.pickProfileAudioFolder(profile.id),
            ),
            _FolderRow(
              label: 'Result folder',
              path: profile.resultFolderPath,
              onPressed: () => controller.pickProfileResultFolder(profile.id),
            ),
            ListTile(
              contentPadding: EdgeInsets.zero,
              leading: const Icon(Icons.drive_file_rename_outline),
              title: const Text('Output prefix'),
              subtitle: Text('$prefix-1.mp4, $prefix-2.mp4 ...'),
              trailing: OutlinedButton(
                onPressed: onEditPrefix,
                child: const Text('Edit'),
              ),
            ),
            DropdownButtonFormField<String>(
              initialValue: _selectedTemplateId(),
              isExpanded: true,
              decoration: const InputDecoration(labelText: 'Apply template'),
              items: [
                for (final template in templatesController.templates)
                  DropdownMenuItem(
                    value: template.id,
                    child: Text(template.name),
                  ),
              ],
              hint: Text(
                templatesController.templates.isEmpty
                    ? 'No templates saved'
                    : 'Select template',
              ),
              onChanged: (templateId) {
                final template = _templateById(templateId);
                if (template != null) {
                  controller.applyTemplateToProfile(
                    profileId: profile.id,
                    template: template,
                  );
                }
              },
            ),
            Text(
              [
                'Overlays: ${profile.useOverlay ? '${profile.overlaySettings.items.length} items' : 'Off'}',
                'Size: ${profile.outputSize.label}',
                'Fit: ${profile.fitMode.label}',
              ].join('  |  '),
              style: TextStyle(fontSize: AppResponsive.bodySize(context) - 1),
            ),
            SizedBox(height: gap / 2),
            Wrap(
              spacing: gap / 2,
              runSpacing: gap / 2,
              children: [
                FilledButton(
                  onPressed: watching
                      ? null
                      : () => controller.startWatching(
                          profileId: profile.id,
                          historyController: historyController,
                          onDuplicate: onDuplicate,
                          onPermissionError: onPermissionError,
                        ),
                  style: FilledButton.styleFrom(
                    backgroundColor: Colors.green.shade700,
                    foregroundColor: Colors.white,
                    visualDensity: VisualDensity.compact,
                  ),
                  child: const Text('Start Watch'),
                ),
                OutlinedButton(
                  onPressed: watching
                      ? () => controller.stopWatching(profile.id)
                      : null,
                  style: OutlinedButton.styleFrom(
                    foregroundColor: Colors.orange.shade800,
                    visualDensity: VisualDensity.compact,
                  ),
                  child: const Text('Stop Watch'),
                ),
                OutlinedButton(
                  onPressed: onEdit,
                  style: OutlinedButton.styleFrom(
                    foregroundColor: Colors.blue.shade700,
                    visualDensity: VisualDensity.compact,
                  ),
                  child: const Text('Edit'),
                ),
                IconButton(
                  tooltip: 'Duplicate profile',
                  onPressed: onDuplicateProfile,
                  visualDensity: VisualDensity.compact,
                  icon: const Icon(Icons.copy),
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
    );
  }

  String? _selectedTemplateId() {
    for (final template in templatesController.templates) {
      if (template.id == profile.templateId) return template.id;
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

class _FolderRow extends StatelessWidget {
  const _FolderRow({
    required this.label,
    required this.path,
    required this.onPressed,
  });

  final String label;
  final String? path;
  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    return ListTile(
      contentPadding: EdgeInsets.zero,
      leading: const Icon(Icons.folder_open),
      title: Text(label),
      subtitle: Text(
        path ?? 'Not selected',
        maxLines: 2,
        overflow: TextOverflow.ellipsis,
      ),
      trailing: OutlinedButton(
        onPressed: onPressed,
        child: const Text('Select'),
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

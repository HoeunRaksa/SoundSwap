import 'package:flutter/material.dart';
import 'package:path/path.dart' as p;
import 'package:soundswap/core/responsive/app_responsive.dart';
import 'package:soundswap/features/folder_watcher/data/models/watch_processing_item.dart';
import 'package:soundswap/features/folder_watcher/presentation/state/folder_watcher_controller.dart';
import 'package:soundswap/features/result_history/presentation/state/result_history_controller.dart';
import 'package:soundswap/shared/widgets/empty_state.dart';
import 'package:soundswap/shared/widgets/feature_page.dart';

class FolderWatcherScreen extends StatelessWidget {
  const FolderWatcherScreen({
    required this.controller,
    required this.historyController,
    super.key,
  });

  final FolderWatcherController controller;
  final ResultHistoryController historyController;

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: controller,
      builder: (context, _) {
        return FeaturePage(
          title: 'Folder Watcher',
          subtitle:
              'Automatically process new videos after copying finishes. Source files are never deleted.',
          children: [
            SettingsSection(
              title: 'Auto processing folders',
              icon: Icons.folder_copy_outlined,
              children: [
                _FolderRow(
                  label: 'Source video folder',
                  path: controller.videoFolderPath,
                  onPressed: controller.pickVideoFolder,
                ),
                _FolderRow(
                  label: 'Source audio folder',
                  path: controller.audioFolderPath,
                  onPressed: controller.pickAudioFolder,
                ),
                _FolderRow(
                  label: 'Result folder',
                  path: controller.resultFolderPath,
                  onPressed: controller.pickResultFolder,
                ),
                Row(
                  children: [
                    Icon(
                      controller.isWatching
                          ? Icons.radio_button_checked
                          : Icons.radio_button_unchecked,
                      color: controller.isWatching
                          ? Colors.green
                          : Theme.of(context).colorScheme.outline,
                    ),
                    SizedBox(width: AppResponsive.cardGap(context) / 2),
                    Text(
                      controller.isWatching ? 'Watching' : 'Stopped',
                      style: TextStyle(
                        fontSize: AppResponsive.bodySize(context),
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ],
                ),
                FilledButton.icon(
                  onPressed: controller.isWatching
                      ? controller.stopWatching
                      : () => controller.startWatching(
                          historyController: historyController,
                          onDuplicate: (path) =>
                              _confirmProcessAgain(context, path),
                          onPermissionError: (folder) =>
                              _showPermissionError(context, folder),
                        ),
                  icon: Icon(
                    controller.isWatching ? Icons.stop : Icons.play_arrow,
                  ),
                  label: Text(
                    controller.isWatching ? 'Stop Watching' : 'Start Watching',
                  ),
                ),
                if (controller.errorMessage != null)
                  Text(
                    controller.errorMessage!,
                    style: TextStyle(
                      color: Theme.of(context).colorScheme.error,
                    ),
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
    if (folder == controller.videoFolderPath) {
      await controller.pickVideoFolder();
    } else if (folder == controller.audioFolderPath) {
      await controller.pickAudioFolder();
    } else if (folder == controller.resultFolderPath) {
      await controller.pickResultFolder();
    }
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
    return Row(
      children: [
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                label,
                style: TextStyle(
                  fontSize: AppResponsive.bodySize(context),
                  fontWeight: FontWeight.w700,
                ),
              ),
              Text(
                path ?? 'Not selected',
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(
                  color: Theme.of(context).colorScheme.onSurfaceVariant,
                  fontSize: AppResponsive.bodySize(context) - 1,
                ),
              ),
            ],
          ),
        ),
        OutlinedButton.icon(
          onPressed: onPressed,
          icon: const Icon(Icons.folder_open),
          label: const Text('Select'),
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

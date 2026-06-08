import 'package:flutter/material.dart';
import 'package:path/path.dart' as p;
import 'package:soundswap/core/responsive/app_responsive.dart';
import 'package:soundswap/features/folder_watcher/presentation/state/folder_watcher_controller.dart';
import 'package:soundswap/shared/widgets/empty_state.dart';
import 'package:soundswap/shared/widgets/feature_page.dart';

class FolderWatcherScreen extends StatelessWidget {
  const FolderWatcherScreen({required this.controller, super.key});

  final FolderWatcherController controller;

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: controller,
      builder: (context, _) {
        return FeaturePage(
          title: 'Folder Watcher',
          subtitle:
              'Watch a folder for new videos. New files are listed only; auto-processing stays off.',
          children: [
            SettingsSection(
              title: 'Watch folder',
              icon: Icons.visibility_outlined,
              children: [
                OutlinedButton.icon(
                  onPressed: controller.pickWatchFolder,
                  icon: const Icon(Icons.folder_open),
                  label: const Text('Select Watch Folder'),
                ),
                Text(
                  controller.watchFolder ?? 'No folder selected',
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(fontSize: AppResponsive.bodySize(context)),
                ),
                FilledButton.icon(
                  onPressed: controller.watchFolder == null
                      ? null
                      : controller.isWatching
                      ? controller.stopWatching
                      : controller.startWatching,
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
              title: 'Detected videos',
              icon: Icons.movie_filter_outlined,
              children: [
                if (controller.detectedVideos.isEmpty)
                  const SizedBox(
                    height: 180,
                    child: EmptyState(
                      icon: Icons.video_file_outlined,
                      title: 'No new videos',
                      message: 'Detected files will appear here.',
                    ),
                  )
                else
                  for (final video in controller.detectedVideos)
                    ListTile(
                      contentPadding: EdgeInsets.zero,
                      leading: const Icon(Icons.video_file),
                      title: Text(p.basename(video)),
                      subtitle: Text(video),
                    ),
              ],
            ),
          ],
        );
      },
    );
  }
}

import 'package:flutter/material.dart';
import 'package:path/path.dart' as p;
import 'package:soundswap/core/responsive/app_responsive.dart';
import 'package:soundswap/features/folder_watcher/presentation/state/folder_watcher_controller.dart';
import 'package:soundswap/features/result_history/data/models/result_history_record.dart';
import 'package:soundswap/features/result_history/presentation/state/result_history_controller.dart';
import 'package:soundswap/shared/widgets/empty_state.dart';
import 'package:soundswap/shared/widgets/feature_page.dart';

class ResultHistoryScreen extends StatelessWidget {
  const ResultHistoryScreen({
    required this.controller,
    required this.folderWatcherController,
    super.key,
  });

  final ResultHistoryController controller;
  final FolderWatcherController folderWatcherController;

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: controller,
      builder: (context, _) {
        return FeaturePage(
          title: 'Result History',
          subtitle:
              'Review completed watcher jobs and safely manage result files.',
          children: [
            SettingsSection(
              title: 'Actions',
              icon: Icons.manage_search,
              children: [
                Wrap(
                  spacing: AppResponsive.cardGap(context),
                  runSpacing: AppResponsive.cardGap(context) / 2,
                  children: [
                    OutlinedButton.icon(
                      onPressed: controller.records.isEmpty
                          ? null
                          : () => _confirmRemoveDuplicates(context),
                      icon: const Icon(Icons.filter_none),
                      label: const Text('Remove Duplicate Results'),
                    ),
                    FilledButton.icon(
                      onPressed:
                          folderWatcherController.resultFolderPath == null
                          ? null
                          : () => _confirmClearAll(context),
                      icon: const Icon(Icons.delete_sweep_outlined),
                      label: const Text('Clear All Results'),
                    ),
                  ],
                ),
                if (controller.message != null) Text(controller.message!),
              ],
            ),
            SettingsSection(
              title: 'Records',
              icon: Icons.history,
              children: [
                if (controller.records.isEmpty)
                  const SizedBox(
                    height: 220,
                    child: EmptyState(
                      icon: Icons.history_toggle_off,
                      title: 'No result history',
                      message: 'Auto-processed results will appear here.',
                    ),
                  )
                else
                  _HistoryTable(controller: controller),
              ],
            ),
          ],
        );
      },
    );
  }

  Future<void> _confirmClearAll(BuildContext context) async {
    final folder = folderWatcherController.resultFolderPath;
    if (folder == null) return;
    if (_isProtectedSourceFolder(folder)) {
      await showDialog<void>(
        context: context,
        builder: (context) => AlertDialog(
          title: const Text('Choose a separate result folder'),
          content: const Text(
            'The result folder is the same as a source folder. Select a separate result folder before clearing results.',
          ),
          actions: [
            FilledButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('OK'),
            ),
          ],
        ),
      );
      return;
    }
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Clear all results?'),
        content: Text(
          'Are you sure to remove all your videos in result: ${p.basename(folder)}?',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Clear'),
          ),
        ],
      ),
    );
    if (confirmed == true) {
      await controller.clearResultFolder(folder);
    }
  }

  bool _isProtectedSourceFolder(String folder) {
    return _foldersMatch(folder, folderWatcherController.videoFolderPath) ||
        _foldersMatch(folder, folderWatcherController.audioFolderPath);
  }

  bool _foldersMatch(String folder, String? otherFolder) {
    if (otherFolder == null) return false;
    return p.equals(p.normalize(folder), p.normalize(otherFolder));
  }

  Future<void> _confirmRemoveDuplicates(BuildContext context) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Remove duplicate results?'),
        content: const Text(
          'Duplicate records with the same original video, audio, and output folder will be removed. Duplicate result files will also be deleted.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Remove'),
          ),
        ],
      ),
    );
    if (confirmed == true) {
      await controller.removeDuplicateResults(deleteFiles: true);
    }
  }
}

class _HistoryTable extends StatelessWidget {
  const _HistoryTable({required this.controller});

  final ResultHistoryController controller;

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: DataTable(
        columnSpacing: AppResponsive.cardGap(context),
        columns: const [
          DataColumn(label: Text('Original video')),
          DataColumn(label: Text('Audio used')),
          DataColumn(label: Text('Result file')),
          DataColumn(label: Text('Result folder')),
          DataColumn(label: Text('Status')),
          DataColumn(label: Text('Date/time')),
          DataColumn(label: Text('Actions')),
        ],
        rows: [
          for (final record in controller.records)
            DataRow(
              cells: [
                DataCell(_CellText(p.basename(record.originalVideoPath))),
                DataCell(_CellText(p.basename(record.audioPath))),
                DataCell(_CellText(p.basename(record.outputPath))),
                DataCell(_CellText(record.resultFolderPath)),
                DataCell(_StatusText(record.status)),
                DataCell(_CellText(record.createdAt.toLocal().toString())),
                DataCell(
                  _RecordActions(controller: controller, record: record),
                ),
              ],
            ),
        ],
      ),
    );
  }
}

class _RecordActions extends StatelessWidget {
  const _RecordActions({required this.controller, required this.record});

  final ResultHistoryController controller;
  final ResultHistoryRecord record;

  @override
  Widget build(BuildContext context) {
    return Wrap(
      spacing: AppResponsive.cardGap(context) / 2,
      children: [
        TextButton(
          onPressed: () => controller.openResultFolder(record),
          child: const Text('Open Result Folder'),
        ),
        TextButton(
          onPressed: () => controller.removeRecord(record),
          child: const Text('Remove Record'),
        ),
        TextButton(
          onPressed: () => _confirmDeleteFile(context),
          child: const Text('Delete Result File'),
        ),
      ],
    );
  }

  Future<void> _confirmDeleteFile(BuildContext context) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete result file?'),
        content: Text('Delete ${p.basename(record.outputPath)}?'),
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
      await controller.deleteResultFile(record);
    }
  }
}

class _StatusText extends StatelessWidget {
  const _StatusText(this.status);

  final ResultHistoryStatus status;

  @override
  Widget build(BuildContext context) {
    final color = status == ResultHistoryStatus.success
        ? Colors.green
        : Theme.of(context).colorScheme.error;
    return Text(status.name, style: TextStyle(color: color));
  }
}

class _CellText extends StatelessWidget {
  const _CellText(this.value);

  final String value;

  @override
  Widget build(BuildContext context) {
    return Tooltip(
      message: value,
      child: SizedBox(
        width: AppResponsive.isSmall(context) ? 160 : 220,
        child: Text(value, maxLines: 2, overflow: TextOverflow.ellipsis),
      ),
    );
  }
}

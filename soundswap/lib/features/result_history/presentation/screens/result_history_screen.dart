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
        final uniqueResultFolders = controller.resultFolders
            .map((folder) => _normalizeFolderPath(folder))
            .where((folder) => folder.isNotEmpty)
            .toSet()
            .toList();

        final selectedResultFolder = controller.resultFolderFilter == null
            ? 'all'
            : _normalizeFolderPath(controller.resultFolderFilter!);

        final safeSelectedResultFolder =
            selectedResultFolder == 'all' ||
                uniqueResultFolders.contains(selectedResultFolder)
            ? selectedResultFolder
            : 'all';

        return FeaturePage(
          title: 'Result History',
          subtitle:
              'Review manual and auto results, filter by folder, and safely manage result files.',
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
                          : () => _confirmRemoveHistory(context, null),
                      icon: const Icon(Icons.clear_all),
                      label: const Text('Remove All History'),
                    ),
                    OutlinedButton.icon(
                      onPressed: controller.records.isEmpty
                          ? null
                          : () => _confirmRemoveHistory(
                              context,
                              ResultProcessType.auto,
                            ),
                      icon: const Icon(Icons.visibility_outlined),
                      label: const Text('Remove Auto History'),
                    ),
                    OutlinedButton.icon(
                      onPressed: controller.records.isEmpty
                          ? null
                          : () => _confirmRemoveHistory(
                              context,
                              ResultProcessType.manual,
                            ),
                      icon: const Icon(Icons.touch_app_outlined),
                      label: const Text('Remove Manual History'),
                    ),
                    OutlinedButton.icon(
                      onPressed: controller.resultFolderFilter == null
                          ? null
                          : () => _confirmClearFolderHistory(context),
                      icon: const Icon(Icons.folder_delete_outlined),
                      label: const Text('Clear history for selected folder'),
                    ),
                    OutlinedButton.icon(
                      onPressed: controller.resultFolderFilter == null
                          ? null
                          : () => _confirmRemoveFilesForFolder(context),
                      icon: const Icon(Icons.delete_outline),
                      label: const Text('Remove files from selected folder'),
                    ),
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
                DropdownButtonFormField<String>(
                  initialValue: controller.processFilter?.name ?? 'all',
                  decoration: const InputDecoration(labelText: 'Process type'),
                  items: const [
                    DropdownMenuItem(value: 'all', child: Text('All')),
                    DropdownMenuItem(
                      value: 'auto',
                      child: Text('Auto processed by app'),
                    ),
                    DropdownMenuItem(
                      value: 'manual',
                      child: Text('Manual batch from Home'),
                    ),
                  ],
                  onChanged: (value) {
                    controller.setProcessFilter(switch (value) {
                      'auto' => ResultProcessType.auto,
                      'manual' => ResultProcessType.manual,
                      _ => null,
                    });
                  },
                ),
                DropdownButtonFormField<String>(
                  initialValue: safeSelectedResultFolder,
                  isExpanded: true,
                  decoration: const InputDecoration(labelText: 'Result folder'),
                  items: [
                    const DropdownMenuItem(
                      value: 'all',
                      child: Text('All result folders'),
                    ),
                    for (final folder in uniqueResultFolders)
                      DropdownMenuItem(value: folder, child: Text(folder)),
                  ],
                  onChanged: (value) {
                    controller.setResultFolderFilter(
                      value == null || value == 'all' ? null : value,
                    );
                  },
                ),
                if (controller.records.isEmpty)
                  const SizedBox(
                    height: 220,
                    child: EmptyState(
                      icon: Icons.history_toggle_off,
                      title: 'No result history',
                      message: 'Manual and auto processed results appear here.',
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

  static String _normalizeFolderPath(String folder) {
    return p.normalize(folder.trim());
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

  Future<void> _confirmClearFolderHistory(BuildContext context) async {
    final folder = controller.resultFolderFilter;
    if (folder == null) return;
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Clear selected folder history?'),
        content: Text(
          'Remove history records for this folder?\n$folder\n\nResult files are not deleted.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Clear History'),
          ),
        ],
      ),
    );
    if (confirmed == true) {
      await controller.removeHistoryForFolder(folder);
    }
  }

  Future<void> _confirmRemoveFilesForFolder(BuildContext context) async {
    final folder = controller.resultFolderFilter;
    if (folder == null) return;
    if (_isProtectedSourceFolder(folder)) {
      await showDialog<void>(
        context: context,
        builder: (context) => AlertDialog(
          title: const Text('Choose a separate result folder'),
          content: const Text(
            'The selected result folder is the same as a source folder. Source folders are never cleaned.',
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
        title: const Text('Remove files from selected folder?'),
        content: Text(
          'Delete recorded result files inside this folder?\n$folder\n\nHistory records stay visible.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Delete Files'),
          ),
        ],
      ),
    );
    if (confirmed == true) {
      await controller.removeFilesForFolder(folder);
    }
  }

  bool _isProtectedSourceFolder(String folder) {
    return _foldersMatch(folder, folderWatcherController.videoFolderPath) ||
        _foldersMatch(folder, folderWatcherController.audioFolderPath);
  }

  bool _foldersMatch(String folder, String? otherFolder) {
    if (otherFolder == null) return false;
    return p.equals(
      _normalizeFolderPath(folder),
      _normalizeFolderPath(otherFolder),
    );
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

  Future<void> _confirmRemoveHistory(
    BuildContext context,
    ResultProcessType? filter,
  ) async {
    final label = switch (filter) {
      ResultProcessType.auto => 'auto processed',
      ResultProcessType.manual => 'manual batch',
      null => 'all',
    };
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Remove history records?'),
        content: Text(
          'Remove $label history records? Result files are not deleted.',
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
      await controller.removeHistoryByFilter(filter);
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
          DataColumn(label: Text('Process')),
          DataColumn(label: Text('Prefix')),
          DataColumn(label: Text('Total videos')),
          DataColumn(label: Text('Status')),
          DataColumn(label: Text('Date/time')),
          DataColumn(label: Text('Actions')),
        ],
        rows: [
          for (final record in controller.filteredRecords)
            DataRow(
              cells: [
                DataCell(_CellText(p.basename(record.originalVideoPath))),
                DataCell(_CellText(p.basename(record.audioPath))),
                DataCell(_CellText(p.basename(record.outputPath))),
                DataCell(_CellText(record.resultFolderPath)),
                DataCell(_CellText(_processLabel(record.processType))),
                DataCell(
                  _CellText(
                    record.outputPrefix.trim().isEmpty
                        ? 'soundswap'
                        : record.outputPrefix,
                  ),
                ),
                DataCell(_CellText('${record.totalVideos}')),
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

  String _processLabel(ResultProcessType type) {
    return switch (type) {
      ResultProcessType.auto => 'Auto',
      ResultProcessType.manual => 'Manual',
    };
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

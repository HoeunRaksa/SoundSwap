import 'dart:async';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:path/path.dart' as p;
import 'package:soundswap/core/responsive/app_responsive.dart';
import 'package:soundswap/features/folder_watcher/presentation/state/folder_watcher_controller.dart';
import 'package:soundswap/features/result_history/data/models/result_history_record.dart';
import 'package:soundswap/features/result_history/presentation/state/result_history_controller.dart';
import 'package:soundswap/shared/widgets/empty_state.dart';
import 'package:soundswap/shared/widgets/feature_page.dart';

class ResultHistoryScreen extends StatefulWidget {
  const ResultHistoryScreen({
    required this.controller,
    required this.folderWatcherController,
    this.onStartBatch,
    this.onOpenResultFolder,
    super.key,
  });

  final ResultHistoryController controller;
  final FolderWatcherController folderWatcherController;
  final VoidCallback? onStartBatch;
  final Future<void> Function()? onOpenResultFolder;

  @override
  State<ResultHistoryScreen> createState() => _ResultHistoryScreenState();
}

class _ResultHistoryScreenState extends State<ResultHistoryScreen> {
  late final TextEditingController _searchController;
  Timer? _searchDebounce;
  int _currentPage = 0;
  int _pageSize = 15;

  ResultProcessType? _lastProcessFilter;
  String? _lastResultFolderFilter;
  ResultDateFilter? _lastDateFilter;
  String? _lastSearchQuery;

  @override
  void initState() {
    super.initState();
    _searchController = TextEditingController(text: widget.controller.searchQuery ?? '');
  }

  @override
  void dispose() {
    _searchDebounce?.cancel();
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final gap = AppResponsive.cardGap(context);

    return ListenableBuilder(
      listenable: widget.controller,
      builder: (context, _) {
        final uniqueResultFolders = widget.controller.resultFolders
            .map((folder) => _normalizeFolderPath(folder))
            .where((folder) => folder.isNotEmpty)
            .toSet()
            .toList();

        final selectedResultFolder = widget.controller.resultFolderFilter == null
            ? 'all'
            : _normalizeFolderPath(widget.controller.resultFolderFilter!);

        final safeSelectedResultFolder =
            selectedResultFolder == 'all' ||
                uniqueResultFolders.contains(selectedResultFolder)
            ? selectedResultFolder
            : 'all';

        final folderToClear = widget.controller.resultFolderFilter ?? widget.folderWatcherController.resultFolderPath;

        return FeaturePage(
          title: 'Result History',
          subtitle:
              'Review manual, auto, and long video results, search by name, and safely manage result files.',
          children: [
            SettingsSection(
              title: 'Actions',
              icon: Icons.manage_search,
              children: [
                Row(
                  children: [
                    FilledButton.icon(
                      onPressed: () => widget.controller.load(),
                      icon: const Icon(Icons.refresh),
                      label: const Text('Refresh'),
                    ),
                    const SizedBox(width: 12),
                    OutlinedButton.icon(
                      onPressed: folderToClear == null ? null : () => _confirmClearResults(context),
                      icon: const Icon(Icons.delete_sweep_outlined),
                      label: const Text('Clear Results'),
                    ),
                    const Spacer(),
                    PopupMenuButton<String>(
                      tooltip: 'Show advanced actions',
                      icon: const Icon(Icons.more_vert),
                      onSelected: (value) {
                        switch (value) {
                          case 'remove_all':
                            _confirmRemoveHistory(context, null);
                            break;
                          case 'remove_auto':
                            _confirmRemoveHistory(context, ResultProcessType.auto);
                            break;
                          case 'remove_manual':
                            _confirmRemoveHistory(context, ResultProcessType.manual);
                            break;
                          case 'remove_long_video':
                            _confirmRemoveHistory(context, ResultProcessType.longVideo);
                            break;
                          case 'clear_folder_history':
                            _confirmClearFolderHistory(context);
                            break;
                          case 'remove_duplicates':
                            _confirmRemoveDuplicates(context);
                            break;
                          case 'remove_folder_files':
                            _confirmRemoveFilesForFolder(context);
                            break;
                        }
                      },
                      itemBuilder: (context) => [
                        const PopupMenuItem(
                          value: 'remove_all',
                          child: Row(
                            children: [
                              Icon(Icons.delete_sweep, size: 20),
                              SizedBox(width: 8),
                              Text('Remove all history'),
                            ],
                          ),
                        ),
                        const PopupMenuItem(
                          value: 'remove_auto',
                          child: Row(
                            children: [
                              Icon(Icons.auto_mode_outlined, size: 20),
                              SizedBox(width: 8),
                              Text('Remove auto history'),
                            ],
                          ),
                        ),
                        const PopupMenuItem(
                          value: 'remove_manual',
                          child: Row(
                            children: [
                              Icon(Icons.touch_app_outlined, size: 20),
                              SizedBox(width: 8),
                              Text('Remove manual history'),
                            ],
                          ),
                        ),
                        const PopupMenuItem(
                          value: 'remove_long_video',
                          child: Row(
                            children: [
                              Icon(Icons.video_stable_outlined, size: 20),
                              SizedBox(width: 8),
                              Text('Remove long video history'),
                            ],
                          ),
                        ),
                        PopupMenuItem(
                          value: 'clear_folder_history',
                          enabled: widget.controller.resultFolderFilter != null,
                          child: Row(
                            children: [
                              Icon(
                                Icons.folder_off,
                                size: 20,
                                color: widget.controller.resultFolderFilter != null ? null : Colors.grey,
                              ),
                              SizedBox(width: 8),
                              Text('Clear selected folder history'),
                            ],
                          ),
                        ),
                        const PopupMenuItem(
                          value: 'remove_duplicates',
                          child: Row(
                            children: [
                              Icon(Icons.copy_all_outlined, size: 20),
                              SizedBox(width: 8),
                              Text('Remove duplicate results'),
                            ],
                          ),
                        ),
                        PopupMenuItem(
                          value: 'remove_folder_files',
                          enabled: widget.controller.resultFolderFilter != null,
                          child: Row(
                            children: [
                              Icon(
                                Icons.delete_forever,
                                size: 20,
                                color: widget.controller.resultFolderFilter != null ? Colors.red : Colors.grey,
                              ),
                              SizedBox(width: 8),
                              Text(
                                'Remove files from selected folder',
                                style: TextStyle(
                                  color: widget.controller.resultFolderFilter != null ? Colors.red : Colors.grey,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
                if (widget.controller.message != null) ...[
                  const SizedBox(height: 8),
                  Text(
                    widget.controller.message!,
                    style: TextStyle(
                      color: Theme.of(context).colorScheme.primary,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ],
              ],
            ),
            SettingsSection(
              title: 'Records',
              icon: Icons.history,
              children: [
                Wrap(
                  spacing: gap,
                  runSpacing: gap,
                  children: [
                    SizedBox(
                      width: 250,
                      child: TextField(
                        controller: _searchController,
                        decoration: InputDecoration(
                          labelText: 'Search output name',
                          prefixIcon: const Icon(Icons.search),
                          suffixIcon: _searchController.text.isNotEmpty
                              ? IconButton(
                                  icon: const Icon(Icons.clear),
                                  onPressed: () {
                                    _searchDebounce?.cancel();
                                    _searchController.clear();
                                    widget.controller.setSearchQuery(null);
                                  },
                                )
                              : null,
                          border: const OutlineInputBorder(),
                        ),
                        onChanged: (value) {
                          if (_searchDebounce?.isActive ?? false) _searchDebounce!.cancel();
                          _searchDebounce = Timer(const Duration(milliseconds: 300), () {
                            widget.controller.setSearchQuery(value);
                          });
                        },
                      ),
                    ),
                    SizedBox(
                      width: 180,
                      child: DropdownButtonFormField<String>(
                        initialValue: widget.controller.processFilter?.name ?? 'all',
                        decoration: const InputDecoration(
                          labelText: 'Process type',
                          border: OutlineInputBorder(),
                        ),
                        items: const [
                          DropdownMenuItem(value: 'all', child: Text('All')),
                          DropdownMenuItem(
                            value: 'auto',
                            child: Text('Auto (Watcher)'),
                          ),
                          DropdownMenuItem(
                            value: 'manual',
                            child: Text('Manual (Batch)'),
                          ),
                          DropdownMenuItem(
                            value: 'longVideo',
                            child: Text('Long Video'),
                          ),
                        ],
                        onChanged: (value) {
                          widget.controller.setProcessFilter(switch (value) {
                            'auto' => ResultProcessType.auto,
                            'manual' => ResultProcessType.manual,
                            'longVideo' => ResultProcessType.longVideo,
                            _ => null,
                          });
                        },
                      ),
                    ),
                    SizedBox(
                      width: 180,
                      child: DropdownButtonFormField<ResultDateFilter>(
                        initialValue: widget.controller.dateFilter,
                        decoration: const InputDecoration(
                          labelText: 'Date range',
                          border: OutlineInputBorder(),
                        ),
                        items: const [
                          DropdownMenuItem(
                            value: ResultDateFilter.allTime,
                            child: Text('All time'),
                          ),
                          DropdownMenuItem(
                            value: ResultDateFilter.today,
                            child: Text('Today'),
                          ),
                          DropdownMenuItem(
                            value: ResultDateFilter.last7Days,
                            child: Text('Last 7 days'),
                          ),
                          DropdownMenuItem(
                            value: ResultDateFilter.last30Days,
                            child: Text('Last 30 days'),
                          ),
                        ],
                        onChanged: (value) {
                          if (value != null) {
                            widget.controller.setDateFilter(value);
                          }
                        },
                      ),
                    ),
                    SizedBox(
                      width: 280,
                      child: DropdownButtonFormField<String>(
                        initialValue: safeSelectedResultFolder,
                        isExpanded: true,
                        decoration: const InputDecoration(
                          labelText: 'Result folder',
                          border: OutlineInputBorder(),
                        ),
                        items: [
                          const DropdownMenuItem(
                            value: 'all',
                            child: Text('All result folders'),
                          ),
                          for (final folder in uniqueResultFolders)
                            DropdownMenuItem(value: folder, child: Text(folder)),
                        ],
                        onChanged: (value) {
                          widget.controller.setResultFolderFilter(
                            value == null || value == 'all' ? null : value,
                          );
                        },
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                if (widget.controller.records.isEmpty)
                  Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const SizedBox(height: 32),
                      const EmptyState(
                        icon: Icons.history_toggle_off,
                        title: 'No Result History',
                        message: 'Exported videos and watcher results will show up here.',
                      ),
                      const SizedBox(height: 16),
                      Wrap(
                        spacing: gap,
                        runSpacing: gap / 2,
                        children: [
                          if (widget.onOpenResultFolder != null)
                            OutlinedButton.icon(
                              onPressed: widget.onOpenResultFolder,
                              icon: const Icon(Icons.folder_open),
                              label: const Text('Open Result Folder'),
                            ),
                          if (widget.onStartBatch != null)
                            FilledButton.icon(
                              onPressed: widget.onStartBatch,
                              icon: const Icon(Icons.play_arrow),
                              label: const Text('Start Batch'),
                            ),
                        ],
                      ),
                      const SizedBox(height: 32),
                    ],
                  )
                else ...[
                  Builder(
                    builder: (context) {
                      final filtered = widget.controller.filteredRecords;
                      final totalRecords = filtered.length;

                      // Reset page to 0 if filters changed
                      if (widget.controller.processFilter != _lastProcessFilter ||
                          widget.controller.resultFolderFilter != _lastResultFolderFilter ||
                          widget.controller.dateFilter != _lastDateFilter ||
                          widget.controller.searchQuery != _lastSearchQuery) {
                        _currentPage = 0;
                        _lastProcessFilter = widget.controller.processFilter;
                        _lastResultFolderFilter = widget.controller.resultFolderFilter;
                        _lastDateFilter = widget.controller.dateFilter;
                        _lastSearchQuery = widget.controller.searchQuery;
                      }

                      final maxPages = (totalRecords / _pageSize).ceil();
                      if (_currentPage >= maxPages && maxPages > 0) {
                        _currentPage = maxPages - 1;
                      }
                      if (_currentPage < 0) {
                        _currentPage = 0;
                      }

                      final startIndex = _currentPage * _pageSize;
                      final endIndex = (startIndex + _pageSize).clamp(0, totalRecords);
                      final pageRecords = filtered.sublist(startIndex, endIndex);

                      if (pageRecords.isEmpty) {
                        return Padding(
                          padding: const EdgeInsets.symmetric(vertical: 32.0),
                          child: Center(
                            child: Text(
                              'No history records match the current filters.',
                              style: TextStyle(color: Theme.of(context).colorScheme.onSurfaceVariant),
                            ),
                          ),
                        );
                      }

                      return Column(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          ...pageRecords.map(
                            (record) => _RecordTile(
                              key: ValueKey(record.id),
                              record: record,
                              controller: widget.controller,
                            ),
                          ),
                          const SizedBox(height: 16),
                          const Divider(),
                          Padding(
                            padding: const EdgeInsets.symmetric(vertical: 8.0),
                            child: Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Text(
                                  'Showing ${startIndex + 1} to $endIndex of $totalRecords records',
                                  style: TextStyle(
                                    fontSize: AppResponsive.bodySize(context) - 2,
                                    color: Theme.of(context).colorScheme.onSurfaceVariant,
                                  ),
                                ),
                                Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    Text(
                                      'Show ',
                                      style: TextStyle(
                                        fontSize: AppResponsive.bodySize(context) - 2,
                                        color: Theme.of(context).colorScheme.onSurfaceVariant,
                                      ),
                                    ),
                                    DropdownButton<int>(
                                      value: _pageSize,
                                      items: [10, 15, 25, 50].map((val) {
                                        return DropdownMenuItem<int>(
                                          value: val,
                                          child: Text(
                                            '$val',
                                            style: TextStyle(
                                              fontSize: AppResponsive.bodySize(context) - 2,
                                              fontWeight: FontWeight.bold,
                                            ),
                                          ),
                                        );
                                      }).toList(),
                                      onChanged: (val) {
                                        if (val != null) {
                                          setState(() {
                                            _pageSize = val;
                                            _currentPage = 0;
                                          });
                                        }
                                      },
                                      underline: const SizedBox(),
                                      isDense: true,
                                    ),
                                    const SizedBox(width: 16),
                                    IconButton(
                                      icon: const Icon(Icons.chevron_left, size: 20),
                                      onPressed: _currentPage > 0
                                          ? () => setState(() => _currentPage--)
                                          : null,
                                      visualDensity: VisualDensity.compact,
                                    ),
                                    const SizedBox(width: 8),
                                    Text(
                                      'Page ${_currentPage + 1} of ${maxPages == 0 ? 1 : maxPages}',
                                      style: TextStyle(
                                        fontSize: AppResponsive.bodySize(context) - 2,
                                        fontWeight: FontWeight.bold,
                                        color: Theme.of(context).colorScheme.onSurface,
                                      ),
                                    ),
                                    const SizedBox(width: 8),
                                    IconButton(
                                      icon: const Icon(Icons.chevron_right, size: 20),
                                      onPressed: _currentPage < maxPages - 1
                                          ? () => setState(() => _currentPage++)
                                          : null,
                                      visualDensity: VisualDensity.compact,
                                    ),
                                  ],
                                ),
                              ],
                            ),
                          ),
                        ],
                      );
                    }
                  ),
                ],
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

  Future<bool> _showSimpleConfirmDialog(
    BuildContext context,
    String title,
    String content, {
    bool isDestructive = false,
  }) async {
    final result = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(title),
        content: Text(content),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(context, true),
            style: isDestructive
                ? FilledButton.styleFrom(
                    backgroundColor: Theme.of(context).colorScheme.error,
                    foregroundColor: Theme.of(context).colorScheme.onError,
                  )
                : null,
            child: Text(isDestructive ? 'Delete' : 'Confirm'),
          ),
        ],
      ),
    );
    return result == true;
  }

  Future<void> _confirmClearResults(BuildContext context) async {
    final folder = widget.controller.resultFolderFilter ?? widget.folderWatcherController.resultFolderPath;
    if (folder == null) return;

    if (_isProtectedSourceFolder(folder)) {
      await showDialog<void>(
        context: context,
        builder: (context) => AlertDialog(
          title: const Text('Protected Folder'),
          content: const Text(
            'The target folder is configured as a source folder (Video or Audio). Select a separate result folder before clearing results.',
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

    final messenger = ScaffoldMessenger.of(context);
    final option = await showDialog<String>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Clear Results'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('Choose how to clear results for the folder:'),
            const SizedBox(height: 8),
            Text(folder, style: const TextStyle(fontWeight: FontWeight.bold)),
            const SizedBox(height: 16),
            const Text(
              'WARNING: Choosing "Clear history and delete files" will permanently delete the output result files from your storage device. This action cannot be undone.',
              style: TextStyle(color: Colors.orange, fontWeight: FontWeight.bold),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          OutlinedButton(
            onPressed: () => Navigator.pop(context, 'history_only'),
            child: const Text('Clear history only'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(context, 'history_and_files'),
            style: FilledButton.styleFrom(
              backgroundColor: Theme.of(context).colorScheme.error,
              foregroundColor: Theme.of(context).colorScheme.onError,
            ),
            child: const Text('Clear history and delete files'),
          ),
        ],
      ),
    );
    if (option == 'history_only') {
      await widget.controller.clearFolderResults(folder, deleteFiles: false);
      if (widget.controller.message != null) {
        messenger.showSnackBar(
          SnackBar(content: Text(widget.controller.message!)),
        );
      }
    } else if (option == 'history_and_files') {
      await widget.controller.clearFolderResults(folder, deleteFiles: true);
      if (widget.controller.message != null) {
        messenger.showSnackBar(
          SnackBar(content: Text(widget.controller.message!)),
        );
      }
    }
  }

  Future<void> _confirmClearFolderHistory(BuildContext context) async {
    final folder = widget.controller.resultFolderFilter;
    if (folder == null) return;
    final confirmed = await _showSimpleConfirmDialog(
      context,
      'Clear selected folder history?',
      'Remove history records for this folder?\n$folder\n\nResult files are not deleted.',
    );
    if (confirmed) {
      await widget.controller.removeHistoryForFolder(folder);
    }
  }

  Future<void> _confirmRemoveFilesForFolder(BuildContext context) async {
    final folder = widget.controller.resultFolderFilter;
    if (folder == null) return;
    if (_isProtectedSourceFolder(folder)) {
      await showDialog<void>(
        context: context,
        builder: (context) => AlertDialog(
          title: const Text('Choose a separate result folder'),
          content: const Text(
            'The selected result folder is the same as a source folder. Source folders cannot be cleaned.',
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
    final confirmed = await _showSimpleConfirmDialog(
      context,
      'Remove files from selected folder?',
      'Delete recorded result files inside this folder?\n$folder\n\nHistory records stay visible. This action cannot be undone.',
      isDestructive: true,
    );
    if (confirmed) {
      await widget.controller.removeFilesForFolder(folder);
    }
  }

  bool _isProtectedSourceFolder(String folder) {
    return _foldersMatch(folder, widget.folderWatcherController.videoFolderPath) ||
        _foldersMatch(folder, widget.folderWatcherController.audioFolderPath);
  }

  bool _foldersMatch(String folder, String? otherFolder) {
    if (otherFolder == null) return false;
    return p.equals(
      _normalizeFolderPath(folder),
      _normalizeFolderPath(otherFolder),
    );
  }

  Future<void> _confirmRemoveDuplicates(BuildContext context) async {
    final confirmed = await _showSimpleConfirmDialog(
      context,
      'Remove duplicate results?',
      'Duplicate records with the same original video, audio, and output folder will be removed. Duplicate result files will also be deleted.',
    );
    if (confirmed) {
      await widget.controller.removeDuplicateResults(deleteFiles: true);
    }
  }

  Future<void> _confirmRemoveHistory(
    BuildContext context,
    ResultProcessType? filter,
  ) async {
    final label = switch (filter) {
      ResultProcessType.auto => 'auto processed',
      ResultProcessType.manual => 'manual batch',
      ResultProcessType.longVideo => 'long video',
      null => 'all',
    };
    final confirmed = await _showSimpleConfirmDialog(
      context,
      'Remove history records?',
      'Remove $label history records? Result files are not deleted.',
    );
    if (confirmed) {
      await widget.controller.removeHistoryByFilter(filter);
    }
  }
}

class _RecordTile extends StatefulWidget {
  const _RecordTile({required this.record, required this.controller, super.key});

  final ResultHistoryRecord record;
  final ResultHistoryController controller;

  @override
  State<_RecordTile> createState() => _RecordTileState();
}

class _RecordTileState extends State<_RecordTile> {
  bool _isExpanded = false;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final gap = AppResponsive.cardGap(context);

    final filename = widget.record.outputPath.isNotEmpty
        ? p.basename(widget.record.outputPath)
        : 'Unknown output';

    final isSuccess = widget.record.status == ResultHistoryStatus.success;

    return Card(
      margin: EdgeInsets.only(bottom: gap / 2),
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: () {
          setState(() {
            _isExpanded = !_isExpanded;
          });
        },
        child: Padding(
          padding: EdgeInsets.all(gap),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Row(
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  Icon(
                    isSuccess ? Icons.check_circle : Icons.cancel,
                    color: isSuccess ? Colors.green : colorScheme.error,
                    size: 22,
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          filename,
                          style: theme.textTheme.titleSmall?.copyWith(
                            fontWeight: FontWeight.bold,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                        if (!isSuccess) ...[
                          const SizedBox(height: 4),
                          Text(
                            'Video: ${p.basename(widget.record.originalVideoPath)}',
                            style: theme.textTheme.bodySmall?.copyWith(
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                          if (widget.record.errorMessage != null) ...[
                            const SizedBox(height: 2),
                            Text(
                              'Error: ${widget.record.errorMessage}',
                              style: theme.textTheme.bodySmall?.copyWith(
                                color: colorScheme.error,
                              ),
                              maxLines: 2,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ],
                          const SizedBox(height: 2),
                          Text(
                            'Retries: ${widget.record.retryCount}',
                            style: theme.textTheme.bodySmall?.copyWith(
                              color: colorScheme.onSurfaceVariant,
                            ),
                          ),
                        ],
                        const SizedBox(height: 4),
                        Row(
                          children: [
                            Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 6,
                                vertical: 2,
                              ),
                              decoration: BoxDecoration(
                                color: colorScheme.surfaceContainerHigh,
                                borderRadius: BorderRadius.circular(4),
                              ),
                              child: Text(
                                _processLabel(widget.record.processType),
                                style: theme.textTheme.bodySmall?.copyWith(
                                  fontSize: 10,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ),
                            const SizedBox(width: 8),
                            Expanded(
                              child: Text(
                                widget.record.createdAt.toLocal().toString().split('.').first,
                                style: theme.textTheme.bodySmall?.copyWith(
                                  color: colorScheme.onSurfaceVariant,
                                ),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                  Icon(
                    _isExpanded ? Icons.expand_less : Icons.expand_more,
                    color: colorScheme.onSurfaceVariant,
                  ),
                ],
              ),
              const SizedBox(height: 8),
              Row(
                children: [
                  Icon(
                    Icons.folder_open,
                    size: 14,
                    color: colorScheme.onSurfaceVariant,
                  ),
                  const SizedBox(width: 6),
                  Expanded(
                    child: Text(
                      widget.record.resultFolderPath,
                      style: theme.textTheme.bodySmall?.copyWith(
                        color: colorScheme.onSurfaceVariant,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  TextButton.icon(
                    onPressed: isSuccess && widget.record.outputPath.isNotEmpty
                        ? () => _openFile(widget.record.outputPath)
                        : null,
                    icon: const Icon(Icons.play_arrow, size: 16),
                    label: const Text('Open File'),
                    style: TextButton.styleFrom(
                      padding: const EdgeInsets.symmetric(horizontal: 8),
                      minimumSize: Size.zero,
                      tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                    ),
                  ),
                  const SizedBox(width: 12),
                  TextButton.icon(
                    onPressed: () => widget.controller.openResultFolder(widget.record),
                    icon: const Icon(Icons.folder, size: 16),
                    label: const Text('Open Folder'),
                    style: TextButton.styleFrom(
                      padding: const EdgeInsets.symmetric(horizontal: 8),
                      minimumSize: Size.zero,
                      tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                    ),
                  ),
                  const SizedBox(width: 12),
                  TextButton.icon(
                    onPressed: () => _confirmDeleteRecord(context),
                    icon: Icon(Icons.delete_outline, size: 16, color: colorScheme.error),
                    label: Text('Delete', style: TextStyle(color: colorScheme.error)),
                    style: TextButton.styleFrom(
                      padding: const EdgeInsets.symmetric(horizontal: 8),
                      minimumSize: Size.zero,
                      tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                    ),
                  ),
                ],
              ),
              if (_isExpanded)
                _ExpandedRecordDetails(
                  record: widget.record,
                  controller: widget.controller,
                ),
            ],
          ),
        ),
      ),
    );
  }

  String _processLabel(ResultProcessType type) {
    return switch (type) {
      ResultProcessType.auto => 'Auto',
      ResultProcessType.manual => 'Manual',
      ResultProcessType.longVideo => 'Long Video',
    };
  }

  Future<void> _openFile(String path) async {
    final file = File(path);
    if (file.existsSync()) {
      await Process.start('explorer.exe', [path]);
    }
  }

  Future<void> _confirmDeleteRecord(BuildContext context) async {
    final hasFile = widget.record.outputPath.isNotEmpty && File(widget.record.outputPath).existsSync();

    final option = await showDialog<String>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete record?'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('Choose how to delete this record for:'),
            const SizedBox(height: 8),
            Text(p.basename(widget.record.outputPath), style: const TextStyle(fontWeight: FontWeight.bold)),
            if (hasFile) ...[
              const SizedBox(height: 16),
              const Text(
                'WARNING: Deleting the output file from your storage device cannot be undone.',
                style: TextStyle(color: Colors.orange, fontWeight: FontWeight.bold),
              ),
            ],
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          OutlinedButton(
            onPressed: () => Navigator.pop(context, 'history_only'),
            child: const Text('Delete history only'),
          ),
          if (hasFile)
            FilledButton(
              onPressed: () => Navigator.pop(context, 'history_and_file'),
              style: FilledButton.styleFrom(
                backgroundColor: Theme.of(context).colorScheme.error,
                foregroundColor: Theme.of(context).colorScheme.onError,
              ),
              child: const Text('Delete file and history'),
            ),
        ],
      ),
    );

    if (option == 'history_only') {
      await widget.controller.removeRecord(widget.record);
    } else if (option == 'history_and_file') {
      await widget.controller.deleteResultFile(widget.record);
    }
  }
}

class _ExpandedRecordDetails extends StatefulWidget {
  const _ExpandedRecordDetails({required this.record, required this.controller});

  final ResultHistoryRecord record;
  final ResultHistoryController controller;

  @override
  State<_ExpandedRecordDetails> createState() => _ExpandedRecordDetailsState();
}

class _ExpandedRecordDetailsState extends State<_ExpandedRecordDetails> {
  bool _loading = true;
  bool _exists = false;
  int _fileSize = 0;

  @override
  void initState() {
    super.initState();
    _loadFileInfo();
  }

  Future<void> _loadFileInfo() async {
    if (widget.record.outputPath.isEmpty) {
      if (mounted) {
        setState(() {
          _loading = false;
          _exists = false;
        });
      }
      return;
    }

    try {
      final file = File(widget.record.outputPath);
      final exists = await file.exists();
      int size = 0;
      if (exists) {
        size = await file.length();
      }
      if (mounted) {
        setState(() {
          _exists = exists;
          _fileSize = size;
          _loading = false;
        });
      }
    } catch (_) {
      if (mounted) {
        setState(() {
          _exists = false;
          _loading = false;
        });
      }
    }
  }

  String _formatFileSize(int bytes) {
    if (bytes <= 0) return '0 B';
    const suffixes = ['B', 'KB', 'MB', 'GB'];
    var i = 0;
    double size = bytes.toDouble();
    while (size >= 1024 && i < suffixes.length - 1) {
      size /= 1024;
      i++;
    }
    return '${size.toStringAsFixed(1)} ${suffixes[i]}';
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final gap = AppResponsive.cardGap(context);

    if (_loading) {
      return Padding(
        padding: EdgeInsets.symmetric(vertical: gap / 2),
        child: const Center(
          child: SizedBox(
            width: 20,
            height: 20,
            child: CircularProgressIndicator(strokeWidth: 2),
          ),
        ),
      );
    }

    return Padding(
      padding: EdgeInsets.only(top: gap / 2),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Divider(),
          const SizedBox(height: 4),
          _buildDetailRow('Original Input:', widget.record.originalVideoPath),
          _buildDetailRow('Audio Source:', widget.record.audioPath),
          _buildDetailRow('Output File:', widget.record.outputPath),
          _buildDetailRow('Result Folder:', widget.record.resultFolderPath),
          _buildDetailRow('Prefix:', widget.record.outputPrefix.isEmpty ? '(none)' : widget.record.outputPrefix),
          _buildDetailRow('Clips Swapped:', '${widget.record.totalVideos}'),
          if (widget.record.status == ResultHistoryStatus.failed && widget.record.errorMessage != null)
            _buildDetailRow('Error Message:', widget.record.errorMessage!, isError: true),
          if (widget.record.status == ResultHistoryStatus.failed)
            _buildDetailRow('Retries:', '${widget.record.retryCount}'),

          const SizedBox(height: 8),
          Row(
            children: [
              Icon(
                _exists ? Icons.check_circle_outline : Icons.error_outline,
                size: 16,
                color: _exists ? Colors.green : colorScheme.error,
              ),
              const SizedBox(width: 8),
              Text(
                _exists
                  ? 'File exists on disk (${_formatFileSize(_fileSize)})'
                  : 'File not found on disk (may have been moved or deleted)',
                style: theme.textTheme.bodySmall?.copyWith(
                  color: _exists ? colorScheme.onSurfaceVariant : colorScheme.error,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildDetailRow(String label, String value, {bool isError = false}) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 2.0),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 120,
            child: Text(
              label,
              style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 12),
            ),
          ),
          Expanded(
            child: SelectableText(
              value,
              style: TextStyle(
                color: isError ? Colors.red : null,
                fontFamily: 'monospace',
                fontSize: 11,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

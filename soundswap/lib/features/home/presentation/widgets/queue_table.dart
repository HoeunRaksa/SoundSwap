import 'package:flutter/material.dart';
import 'package:soundswap/core/responsive/app_responsive.dart';
import 'package:soundswap/features/home/data/models/soundswap_job.dart';
import 'package:soundswap/shared/widgets/empty_state.dart';

class QueueTable extends StatelessWidget {
  const QueueTable({
    required this.jobs,
    this.selectedVideoPaths = const {},
    this.onSelectionChanged,
    this.onRemoveVideo,
    super.key,
  });

  final List<SoundSwapJob> jobs;
  final Set<String> selectedVideoPaths;
  final void Function(String videoPath, bool selected)? onSelectionChanged;
  final void Function(String videoPath)? onRemoveVideo;

  @override
  Widget build(BuildContext context) {
    if (jobs.isEmpty) {
      return const EmptyState(
        icon: Icons.video_library_outlined,
        title: 'No queue yet',
        message:
        'Choose video, audio, and output folders to prepare the batch.',
      );
    }

    final gap = AppResponsive.cardGap(context);
    final radius = AppResponsive.cardRadius(context);
    final colorScheme = Theme.of(context).colorScheme;

    return Card(
      elevation: 0,
      clipBehavior: Clip.antiAlias,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(radius),
        side: BorderSide(
          color: colorScheme.outlineVariant.withValues(alpha: 0.75),
        ),
      ),
      child: Container(
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(radius),
          color: colorScheme.surface,
        ),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(radius),
          child: SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: SingleChildScrollView(
              child: Theme(
                data: Theme.of(context).copyWith(
                  dividerColor: colorScheme.outlineVariant.withValues(
                    alpha: 0.55,
                  ),
                  checkboxTheme: CheckboxThemeData(
                    visualDensity: VisualDensity.compact,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(3),
                    ),
                  ),
                ),
                child: DataTable(
                  dataRowMinHeight: 30,
                  dataRowMaxHeight: 38,
                  headingRowHeight: 34,
                  horizontalMargin: gap * 0.55,
                  checkboxHorizontalMargin: gap * 0.28,
                  columnSpacing: gap * 0.8,
                  headingRowColor: WidgetStatePropertyAll(
                    colorScheme.surfaceContainerHighest.withValues(alpha: 0.55),
                  ),
                  headingTextStyle: Theme.of(context).textTheme.labelSmall
                      ?.copyWith(
                    fontSize: AppResponsive.bodySize(context) - 3,
                    fontWeight: FontWeight.w800,
                    color: colorScheme.onSurface,
                    letterSpacing: 0.1,
                  ),
                  dataTextStyle: Theme.of(context).textTheme.bodySmall
                      ?.copyWith(
                    fontSize: AppResponsive.bodySize(context) - 3,
                    color: colorScheme.onSurface,
                    height: 1.15,
                  ),
                  columns: const [
                    DataColumn(label: Text('Video')),
                    DataColumn(label: Text('Audio')),
                    DataColumn(label: Text('Output')),
                    DataColumn(label: Text('Status')),
                    DataColumn(label: Text('Retries')),
                    DataColumn(label: Text('Actions')),
                  ],
                  rows: [
                    for (final job in jobs)
                      DataRow(
                        color: WidgetStateProperty.resolveWith((states) {
                          if (states.contains(WidgetState.selected)) {
                            return colorScheme.primaryContainer.withValues(
                              alpha: 0.22,
                            );
                          }
                          return null;
                        }),
                        selected: selectedVideoPaths.contains(job.video.path),
                        onSelectChanged: onSelectionChanged == null
                            ? null
                            : (selected) => onSelectionChanged!(
                          job.video.path,
                          selected ?? false,
                        ),
                        cells: [
                          DataCell(_FileCell(text: job.video.name)),
                          DataCell(_FileCell(text: job.audio.name)),
                          DataCell(
                            Tooltip(
                              message: job.errorMessage ?? job.outputPath,
                              child: _FileCell(text: job.outputName),
                            ),
                          ),
                          DataCell(_StatusChip(status: job.status)),
                          DataCell(
                            Center(
                              child: Text(
                                '${job.retryCount}',
                                style: TextStyle(
                                  fontSize:
                                  AppResponsive.bodySize(context) - 3,
                                  fontWeight: FontWeight.w600,
                                  color: colorScheme.onSurfaceVariant,
                                ),
                              ),
                            ),
                          ),
                          DataCell(
                            IconButton(
                              constraints: const BoxConstraints.tightFor(
                                width: 28,
                                height: 28,
                              ),
                              padding: EdgeInsets.zero,
                              visualDensity: VisualDensity.compact,
                              tooltip: 'Remove',
                              style: IconButton.styleFrom(
                                foregroundColor: colorScheme.error,
                                disabledForegroundColor:
                                colorScheme.onSurfaceVariant.withValues(
                                  alpha: 0.35,
                                ),
                              ),
                              onPressed: onRemoveVideo == null
                                  ? null
                                  : () => onRemoveVideo!(job.video.path),
                              icon: const Icon(
                                Icons.remove_circle_outline,
                                size: 18,
                              ),
                            ),
                          ),
                        ],
                      ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _FileCell extends StatelessWidget {
  const _FileCell({required this.text});

  final String text;

  @override
  Widget build(BuildContext context) {
    final width = AppResponsive.isSmall(context)
        ? 140.0
        : AppResponsive.isMedium(context)
        ? 165.0
        : 215.0;

    final colorScheme = Theme.of(context).colorScheme;

    return SizedBox(
      width: width,
      child: Text(
        text,
        maxLines: 2,
        overflow: TextOverflow.ellipsis,
        style: TextStyle(
          fontSize: AppResponsive.bodySize(context) - 3,
          height: 1.18,
          fontWeight: FontWeight.w500,
          color: colorScheme.onSurface.withValues(alpha: 0.9),
        ),
      ),
    );
  }
}

class _StatusChip extends StatelessWidget {
  const _StatusChip({required this.status});

  final SoundSwapStatus status;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final (:label, :icon, :color) = switch (status) {
      SoundSwapStatus.queued => (
      label: 'Queued',
      icon: Icons.schedule,
      color: colorScheme.secondary,
      ),
      SoundSwapStatus.processing => (
      label: 'Processing',
      icon: Icons.autorenew,
      color: colorScheme.primary,
      ),
      SoundSwapStatus.success => (
      label: 'Success',
      icon: Icons.check_circle,
      color: Colors.green,
      ),
      SoundSwapStatus.failed => (
      label: 'Failed',
      icon: Icons.error,
      color: colorScheme.error,
      ),
    };

    return Container(
      padding: EdgeInsets.symmetric(
        horizontal: AppResponsive.cardGap(context) * 0.4,
        vertical: AppResponsive.cardGap(context) * 0.14,
      ),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.13),
        borderRadius: BorderRadius.circular(
          AppResponsive.cardRadius(context) * 0.75,
        ),
        border: Border.all(
          color: color.withValues(alpha: 0.16),
        ),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            icon,
            size: AppResponsive.iconSize(context) - 10,
            color: color,
          ),
          SizedBox(width: AppResponsive.cardGap(context) * 0.28),
          Text(
            label,
            style: TextStyle(
              color: color,
              fontSize: AppResponsive.bodySize(context) - 4,
              fontWeight: FontWeight.w800,
              height: 1,
            ),
          ),
        ],
      ),
    );
  }
}
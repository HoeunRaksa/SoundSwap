import 'package:flutter/material.dart';
import 'package:soundswap/core/responsive/app_responsive.dart';
import 'package:soundswap/features/home/data/models/soundswap_job.dart';
import 'package:soundswap/shared/widgets/empty_state.dart';

class QueueTable extends StatelessWidget {
  const QueueTable({required this.jobs, super.key});

  final List<SoundSwapJob> jobs;

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

    return Card(
      child: ClipRRect(
        borderRadius: BorderRadius.circular(AppResponsive.cardRadius(context)),
        child: SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          child: SingleChildScrollView(
            child: DataTable(
              columnSpacing: AppResponsive.cardGap(context),
              columns: const [
                DataColumn(label: Text('Video')),
                DataColumn(label: Text('Audio')),
                DataColumn(label: Text('Output')),
                DataColumn(label: Text('Status')),
                DataColumn(label: Text('Retries')),
              ],
              rows: [
                for (final job in jobs)
                  DataRow(
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
                              fontSize: AppResponsive.bodySize(context),
                              fontWeight: FontWeight.w500,
                            ),
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
    );
  }
}

class _FileCell extends StatelessWidget {
  const _FileCell({required this.text});

  final String text;

  @override
  Widget build(BuildContext context) {
    final width = AppResponsive.isSmall(context)
        ? 180.0
        : AppResponsive.isMedium(context)
        ? 220.0
        : 280.0;

    return SizedBox(
      width: width,
      child: Text(
        text,
        maxLines: 2,
        overflow: TextOverflow.ellipsis,
        style: TextStyle(fontSize: AppResponsive.bodySize(context)),
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
        horizontal: AppResponsive.cardGap(context) * 0.7,
        vertical: AppResponsive.cardGap(context) * 0.4,
      ),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(AppResponsive.cardRadius(context)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: AppResponsive.iconSize(context) - 4, color: color),
          SizedBox(width: AppResponsive.cardGap(context) / 2),
          Text(
            label,
            style: TextStyle(
              color: color,
              fontSize: AppResponsive.bodySize(context) - 1,
            ),
          ),
        ],
      ),
    );
  }
}

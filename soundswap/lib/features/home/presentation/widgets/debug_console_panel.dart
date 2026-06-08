import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:soundswap/features/home/presentation/state/home_controller.dart';

class DebugConsolePanel extends StatelessWidget {
  const DebugConsolePanel({required this.controller, super.key});

  final HomeController controller;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Row(
              children: [
                Expanded(
                  child: Text(
                    'Debug Console',
                    style: Theme.of(context).textTheme.titleLarge,
                  ),
                ),
                OutlinedButton.icon(
                  onPressed: controller.errorReport.isEmpty
                      ? null
                      : () => Clipboard.setData(
                          ClipboardData(text: controller.errorReport),
                        ),
                  icon: const Icon(Icons.copy),
                  label: const Text('Copy Error'),
                ),
                const SizedBox(width: 8),
                OutlinedButton.icon(
                  onPressed: controller.exportLog,
                  icon: const Icon(Icons.save_alt),
                  label: const Text('Export Log'),
                ),
              ],
            ),
            const SizedBox(height: 12),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [
                _DebugChip(
                  label: 'Video',
                  value: controller.currentVideoName ?? 'None',
                ),
                _DebugChip(
                  label: 'Audio',
                  value: controller.currentAudioName ?? 'None',
                ),
                _DebugChip(label: 'Retry', value: '${controller.retryCount}'),
                _DebugChip(label: 'Log', value: controller.logFilePath),
              ],
            ),
            const SizedBox(height: 12),
            Text(
              'FFmpeg command',
              style: Theme.of(context).textTheme.labelLarge,
            ),
            const SizedBox(height: 6),
            Container(
              constraints: const BoxConstraints(minHeight: 56),
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: colorScheme.surfaceContainerHighest,
                borderRadius: BorderRadius.circular(8),
              ),
              child: SelectableText(
                controller.currentFfmpegCommand ?? 'No command has run yet.',
                style: Theme.of(context).textTheme.bodySmall,
              ),
            ),
            const SizedBox(height: 12),
            Expanded(
              child: Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: Colors.black,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: SingleChildScrollView(
                  reverse: true,
                  child: SelectableText(
                    controller.debugLogs.isEmpty
                        ? 'Debug output will appear here.'
                        : controller.debugLogs.join('\n'),
                    style: const TextStyle(
                      color: Colors.white,
                      fontFamily: 'Consolas',
                      fontSize: 12,
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _DebugChip extends StatelessWidget {
  const _DebugChip({required this.label, required this.value});

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Tooltip(
      message: value,
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 280),
        child: Chip(
          label: Text(
            '$label: $value',
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
        ),
      ),
    );
  }
}

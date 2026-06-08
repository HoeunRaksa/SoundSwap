import 'package:flutter/material.dart';
import 'package:soundswap/features/home/presentation/state/home_controller.dart';
import 'package:soundswap/shared/services/ffmpeg_setup_service.dart';

class FfmpegSettingsPanel extends StatelessWidget {
  const FfmpegSettingsPanel({required this.controller, super.key});

  final HomeController controller;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final ready = controller.isFfmpegReady;

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Row(
              children: [
                Icon(
                  ready ? Icons.check_circle : Icons.build_circle_outlined,
                  color: ready ? Colors.green : colorScheme.primary,
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Text(
                    'Settings / FFmpeg',
                    style: Theme.of(context).textTheme.titleMedium,
                  ),
                ),
                if (!ready)
                  FilledButton.icon(
                    onPressed: controller.isInstallingFfmpeg
                        ? null
                        : controller.installFfmpeg,
                    icon: controller.isInstallingFfmpeg
                        ? const SizedBox(
                            width: 18,
                            height: 18,
                            child: CircularProgressIndicator(strokeWidth: 2),
                          )
                        : const Icon(Icons.download),
                    label: const Text('Install FFmpeg'),
                  ),
              ],
            ),
            const SizedBox(height: 12),
            Text(
              controller.ffmpegSetupMessage,
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                color: ready ? Colors.green : colorScheme.onSurfaceVariant,
              ),
            ),
            if (controller.isInstallingFfmpeg) ...[
              const SizedBox(height: 12),
              LinearProgressIndicator(value: controller.ffmpegSetupProgress),
            ],
            const SizedBox(height: 12),
            _SetupStepRow(
              label: 'Downloading',
              active: controller.ffmpegSetupStep == FfmpegSetupStep.downloading,
              done: _isAfter(
                controller.ffmpegSetupStep,
                FfmpegSetupStep.downloading,
              ),
            ),
            _SetupStepRow(
              label: 'Extracting',
              active: controller.ffmpegSetupStep == FfmpegSetupStep.extracting,
              done: _isAfter(
                controller.ffmpegSetupStep,
                FfmpegSetupStep.extracting,
              ),
            ),
            _SetupStepRow(
              label: 'Validating',
              active: controller.ffmpegSetupStep == FfmpegSetupStep.validating,
              done: _isAfter(
                controller.ffmpegSetupStep,
                FfmpegSetupStep.validating,
              ),
            ),
            _SetupStepRow(
              label: 'Ready',
              active: controller.ffmpegSetupStep == FfmpegSetupStep.ready,
              done: ready,
            ),
            if (controller.ffmpegPath != null) ...[
              const SizedBox(height: 10),
              _PathText(label: 'ffmpeg.exe', value: controller.ffmpegPath!),
            ],
            if (controller.ffprobePath != null) ...[
              const SizedBox(height: 6),
              _PathText(label: 'ffprobe.exe', value: controller.ffprobePath!),
            ],
          ],
        ),
      ),
    );
  }

  bool _isAfter(FfmpegSetupStep current, FfmpegSetupStep step) {
    const order = [
      FfmpegSetupStep.idle,
      FfmpegSetupStep.downloading,
      FfmpegSetupStep.extracting,
      FfmpegSetupStep.validating,
      FfmpegSetupStep.ready,
    ];
    return order.indexOf(current) > order.indexOf(step);
  }
}

class _SetupStepRow extends StatelessWidget {
  const _SetupStepRow({
    required this.label,
    required this.active,
    required this.done,
  });

  final String label;
  final bool active;
  final bool done;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 3),
      child: Row(
        children: [
          Icon(
            done
                ? Icons.check_circle
                : active
                ? Icons.radio_button_checked
                : Icons.radio_button_unchecked,
            size: 18,
            color: done
                ? Colors.green
                : active
                ? colorScheme.primary
                : colorScheme.outline,
          ),
          const SizedBox(width: 8),
          Text(label),
        ],
      ),
    );
  }
}

class _PathText extends StatelessWidget {
  const _PathText({required this.label, required this.value});

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Tooltip(
      message: value,
      child: Text(
        '$label: $value',
        maxLines: 1,
        overflow: TextOverflow.ellipsis,
        style: Theme.of(context).textTheme.bodySmall,
      ),
    );
  }
}

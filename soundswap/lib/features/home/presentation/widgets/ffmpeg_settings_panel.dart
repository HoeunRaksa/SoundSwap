import 'package:flutter/material.dart';
import 'package:soundswap/core/responsive/app_responsive.dart';
import 'package:soundswap/features/home/presentation/state/home_controller.dart';
import 'package:soundswap/shared/services/ffmpeg_setup_service.dart';

class FfmpegSettingsPanel extends StatelessWidget {
  const FfmpegSettingsPanel({required this.controller, super.key});

  final HomeController controller;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final ready = controller.isFfmpegReady;
    final gap = AppResponsive.cardGap(context);

    return Card(
      child: Padding(
        padding: EdgeInsets.all(gap),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Wrap(
              spacing: gap,
              runSpacing: gap,
              crossAxisAlignment: WrapCrossAlignment.center,
              children: [
                Icon(
                  ready ? Icons.check_circle : Icons.build_circle_outlined,
                  size: AppResponsive.iconSize(context),
                  color: ready ? Colors.green : colorScheme.primary,
                ),
                SizedBox(
                  width: AppResponsive.isSmall(context) ? double.infinity : 170,
                  child: Text(
                    'Settings / FFmpeg',
                    style: Theme.of(context).textTheme.titleMedium?.copyWith(
                      fontSize: AppResponsive.bodySize(context) + 2,
                    ),
                  ),
                ),
                if (!ready)
                  SizedBox(
                    height: AppResponsive.buttonHeight(context),
                    child: FilledButton.icon(
                      onPressed: controller.isInstallingFfmpeg
                          ? null
                          : controller.installFfmpeg,
                      icon: controller.isInstallingFfmpeg
                          ? SizedBox(
                              width: AppResponsive.iconSize(context),
                              height: AppResponsive.iconSize(context),
                              child: const CircularProgressIndicator(
                                strokeWidth: 2,
                              ),
                            )
                          : Icon(
                              Icons.download,
                              size: AppResponsive.iconSize(context),
                            ),
                      label: Text(
                        'Install FFmpeg',
                        style: TextStyle(
                          fontSize: AppResponsive.bodySize(context),
                        ),
                      ),
                    ),
                  ),
              ],
            ),
            SizedBox(height: gap),
            Text(
              controller.ffmpegSetupMessage,
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                color: ready ? Colors.green : colorScheme.onSurfaceVariant,
                fontSize: AppResponsive.bodySize(context),
              ),
            ),
            if (controller.isInstallingFfmpeg) ...[
              SizedBox(height: gap),
              LinearProgressIndicator(value: controller.ffmpegSetupProgress),
            ],
            SizedBox(height: gap),
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
              SizedBox(height: gap / 2),
              _PathText(label: 'ffmpeg.exe', value: controller.ffmpegPath!),
            ],
            if (controller.ffprobePath != null) ...[
              SizedBox(height: gap / 3),
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
      padding: EdgeInsets.symmetric(
        vertical: AppResponsive.cardGap(context) / 5,
      ),
      child: Row(
        children: [
          Icon(
            done
                ? Icons.check_circle
                : active
                ? Icons.radio_button_checked
                : Icons.radio_button_unchecked,
            size: AppResponsive.iconSize(context) - 4,
            color: done
                ? Colors.green
                : active
                ? colorScheme.primary
                : colorScheme.outline,
          ),
          SizedBox(width: AppResponsive.cardGap(context) / 2),
          Text(
            label,
            style: TextStyle(fontSize: AppResponsive.bodySize(context)),
          ),
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
        style: Theme.of(context).textTheme.bodySmall?.copyWith(
          fontSize: AppResponsive.bodySize(context) - 1,
        ),
      ),
    );
  }
}

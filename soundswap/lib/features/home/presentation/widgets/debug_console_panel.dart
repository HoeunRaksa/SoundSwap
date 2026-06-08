import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:soundswap/core/responsive/app_responsive.dart';
import 'package:soundswap/features/home/presentation/state/home_controller.dart';

class DebugConsolePanel extends StatelessWidget {
  const DebugConsolePanel({required this.controller, super.key});

  final HomeController controller;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final gap = AppResponsive.cardGap(context);

    return Card(
      child: Padding(
        padding: EdgeInsets.all(gap),
        child: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Wrap(
                spacing: gap,
                runSpacing: gap,
                crossAxisAlignment: WrapCrossAlignment.center,
                children: [
                  SizedBox(
                    width: AppResponsive.isSmall(context)
                        ? double.infinity
                        : 220,
                    child: Text(
                      'Debug Console',
                      style: Theme.of(context).textTheme.titleLarge?.copyWith(
                        fontSize: AppResponsive.titleSize(context) - 6,
                      ),
                    ),
                  ),
                  SizedBox(
                    height: AppResponsive.buttonHeight(context),
                    child: OutlinedButton.icon(
                      onPressed: controller.errorReport.isEmpty
                          ? null
                          : () => Clipboard.setData(
                              ClipboardData(text: controller.errorReport),
                            ),
                      icon: Icon(
                        Icons.copy,
                        size: AppResponsive.iconSize(context),
                      ),
                      label: Text(
                        'Copy Error',
                        style: TextStyle(
                          fontSize: AppResponsive.bodySize(context),
                        ),
                      ),
                    ),
                  ),
                  SizedBox(
                    height: AppResponsive.buttonHeight(context),
                    child: OutlinedButton.icon(
                      onPressed: controller.exportLog,
                      icon: Icon(
                        Icons.save_alt,
                        size: AppResponsive.iconSize(context),
                      ),
                      label: Text(
                        'Export Log',
                        style: TextStyle(
                          fontSize: AppResponsive.bodySize(context),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
              SizedBox(height: gap),
              Wrap(
                spacing: gap / 2,
                runSpacing: gap / 2,
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
              SizedBox(height: gap),
              Text(
                'FFmpeg command',
                style: Theme.of(context).textTheme.labelLarge?.copyWith(
                  fontSize: AppResponsive.bodySize(context),
                ),
              ),
              SizedBox(height: gap / 2),
              Container(
                constraints: const BoxConstraints(minHeight: 56),
                padding: EdgeInsets.all(gap / 2),
                decoration: BoxDecoration(
                  color: colorScheme.surfaceContainerHighest,
                  borderRadius: BorderRadius.circular(
                    AppResponsive.cardRadius(context),
                  ),
                ),
                child: SelectableText(
                  controller.currentFfmpegCommand ?? 'No command has run yet.',
                  style: Theme.of(context).textTheme.bodySmall,
                ),
              ),
              SizedBox(height: gap),
              SizedBox(
                height: AppResponsive.debugLogHeight(context),
                child: Container(
                  padding: EdgeInsets.all(gap / 2),
                  decoration: BoxDecoration(
                    color: Colors.black,
                    borderRadius: BorderRadius.circular(
                      AppResponsive.cardRadius(context),
                    ),
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
        constraints: BoxConstraints(
          maxWidth: AppResponsive.isSmall(context) ? 220 : 280,
        ),
        child: Chip(
          label: Text(
            '$label: $value',
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: TextStyle(fontSize: AppResponsive.bodySize(context) - 1),
          ),
        ),
      ),
    );
  }
}

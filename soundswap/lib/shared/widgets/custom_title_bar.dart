import 'dart:async';
import 'package:flutter/material.dart';
import 'package:window_manager/window_manager.dart';
import 'package:soundswap/features/home/presentation/state/home_controller.dart';
import 'package:soundswap/features/folder_watcher/presentation/state/folder_watcher_controller.dart';

class CustomTitleBar extends StatefulWidget {
  const CustomTitleBar({
    required this.homeController,
    required this.folderWatcherController,
    super.key,
  });

  final HomeController homeController;
  final FolderWatcherController folderWatcherController;

  @override
  State<CustomTitleBar> createState() => _CustomTitleBarState();
}

class _CustomTitleBarState extends State<CustomTitleBar> with WindowListener {
  bool _isMaximized = false;

  @override
  void initState() {
    super.initState();
    windowManager.addListener(this);
    _checkMaximizedState();
  }

  @override
  void dispose() {
    windowManager.removeListener(this);
    super.dispose();
  }

  Future<void> _checkMaximizedState() async {
    final max = await windowManager.isMaximized();
    if (mounted) {
      setState(() {
        _isMaximized = max;
      });
    }
  }

  @override
  void onWindowMaximize() {
    if (mounted) setState(() => _isMaximized = true);
  }

  @override
  void onWindowUnmaximize() {
    if (mounted) setState(() => _isMaximized = false);
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return Container(
      height: 40,
      color: colorScheme.surfaceContainerLow,
      child: Column(
        children: [
          Expanded(
            child: Row(
              children: [
                // 1. Branding (SoundSwap Logo + Title)
                Padding(
                  padding: const EdgeInsets.only(left: 12.0),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Container(
                        width: 20,
                        height: 20,
                        decoration: BoxDecoration(
                          color: colorScheme.primary,
                          borderRadius: BorderRadius.circular(5),
                        ),
                        child: Icon(
                          Icons.swap_horizontal_circle,
                          size: 13,
                          color: colorScheme.onPrimary,
                        ),
                      ),
                      const SizedBox(width: 8),
                      Text(
                        'SoundSwap',
                        style: TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w800,
                          letterSpacing: -0.2,
                          color: colorScheme.onSurface,
                        ),
                      ),
                      const SizedBox(width: 6),
                      Text(
                        'Video Suite',
                        style: TextStyle(
                          fontSize: 9,
                          fontWeight: FontWeight.w500,
                          color: colorScheme.onSurfaceVariant.withValues(alpha: 0.55),
                        ),
                      ),
                    ],
                  ),
                ),

                const SizedBox(width: 16),

                // 2. Middle Area (Draggable Window Area + Status Badges)
                Expanded(
                  child: GestureDetector(
                    behavior: HitTestBehavior.translucent,
                    onDoubleTap: () async {
                      final max = await windowManager.isMaximized();
                      if (max) {
                        await windowManager.unmaximize();
                      } else {
                        await windowManager.maximize();
                      }
                    },
                    child: DragToMoveArea(
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          ListenableBuilder(
                            listenable: Listenable.merge([
                              widget.homeController,
                              widget.folderWatcherController,
                            ]),
                            builder: (context, _) {
                              return Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  // Project Name
                                  _buildProjectBadge(context),
                                  const SizedBox(width: 10),
                                  // Processing / Watcher Status
                                  _buildStatusBadge(context),
                                ],
                              );
                            },
                          ),
                        ],
                      ),
                    ),
                  ),
                ),

                // 3. Window Controls (Minimize, Maximize/Restore, Close)
                Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    _TitleBarButton(
                      icon: const Icon(Icons.remove, size: 16),
                      onPressed: () => windowManager.minimize(),
                      hoverColor: colorScheme.onSurface.withValues(alpha: 0.06),
                    ),
                    _TitleBarButton(
                      icon: _isMaximized
                          ? const Icon(Icons.filter_none, size: 11)
                          : const Icon(Icons.crop_square, size: 14),
                      onPressed: () async {
                        final max = await windowManager.isMaximized();
                        if (max) {
                          await windowManager.unmaximize();
                        } else {
                          await windowManager.maximize();
                        }
                      },
                      hoverColor: colorScheme.onSurface.withValues(alpha: 0.06),
                    ),
                    _TitleBarButton(
                      icon: const Icon(Icons.close, size: 16),
                      onPressed: () => windowManager.close(),
                      hoverColor: const Color(0xFFE81123),
                      hoverIconColor: Colors.white,
                    ),
                  ],
                ),
              ],
            ),
          ),
          Container(
            height: 1,
            color: colorScheme.outlineVariant.withValues(alpha: 0.4),
          ),
        ],
      ),
    );
  }

  Widget _buildProjectBadge(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final home = widget.homeController;

    String projectName = 'Default Project';
    if (home.selectedBatchProfileId != null) {
      final matches = home.batchProfiles.where((p) => p.id == home.selectedBatchProfileId);
      if (matches.isNotEmpty) {
        projectName = matches.first.name;
      }
    } else if (home.selectedTemplateId != null) {
      projectName = 'Template Active';
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        color: colorScheme.surfaceContainerHighest.withValues(alpha: 0.5),
        borderRadius: BorderRadius.circular(4),
        border: Border.all(
          color: colorScheme.outlineVariant.withValues(alpha: 0.3),
        ),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            Icons.folder_open,
            size: 11,
            color: colorScheme.onSurfaceVariant.withValues(alpha: 0.7),
          ),
          const SizedBox(width: 5),
          Text(
            projectName,
            style: TextStyle(
              fontSize: 10,
              fontWeight: FontWeight.w600,
              color: colorScheme.onSurfaceVariant,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStatusBadge(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final home = widget.homeController;
    final watcher = widget.folderWatcherController;

    IconData icon;
    String text;
    Color color;

    if (home.isProcessing) {
      icon = Icons.autorenew;
      text = 'Processing: ${home.successCount + home.failedCount}/${home.jobs.length}';
      color = colorScheme.primary;
    } else if (watcher.isWatching) {
      icon = Icons.visibility;
      text = 'Watcher Active';
      color = Colors.green;
    } else if (home.isScanning) {
      icon = Icons.search;
      text = 'Scanning Folders';
      color = colorScheme.secondary;
    } else {
      icon = Icons.radio_button_checked;
      text = 'Idle';
      color = colorScheme.onSurfaceVariant.withValues(alpha: 0.5);
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(4),
        border: Border.all(
          color: color.withValues(alpha: 0.18),
        ),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Small pulsing or colored dot
          home.isProcessing
              ? const SizedBox(
                  width: 10,
                  height: 10,
                  child: CircularProgressIndicator(
                    strokeWidth: 1.5,
                    valueColor: AlwaysStoppedAnimation(Colors.amber),
                  ),
                )
              : Icon(
                  icon,
                  size: 11,
                  color: color,
                ),
          const SizedBox(width: 5),
          Text(
            text,
            style: TextStyle(
              fontSize: 10,
              fontWeight: FontWeight.w700,
              color: color,
            ),
          ),
        ],
      ),
    );
  }
}

class _TitleBarButton extends StatefulWidget {
  const _TitleBarButton({
    required this.icon,
    required this.onPressed,
    this.hoverColor,
    this.hoverIconColor,
  });

  final Widget icon;
  final VoidCallback onPressed;
  final Color? hoverColor;
  final Color? hoverIconColor;

  @override
  State<_TitleBarButton> createState() => _TitleBarButtonState();
}

class _TitleBarButtonState extends State<_TitleBarButton> {
  bool _isHovered = false;

  @override
  Widget build(BuildContext context) {
    final defaultIconColor = Theme.of(context).colorScheme.onSurfaceVariant;
    return MouseRegion(
      onEnter: (_) => setState(() => _isHovered = true),
      onExit: (_) => setState(() => _isHovered = false),
      child: GestureDetector(
        onTap: widget.onPressed,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 100),
          width: 46,
          height: 39,
          color: _isHovered
              ? (widget.hoverColor ?? Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.08))
              : Colors.transparent,
          child: Center(
            child: IconTheme(
              data: IconThemeData(
                color: _isHovered
                    ? (widget.hoverIconColor ?? Theme.of(context).colorScheme.onSurface)
                    : defaultIconColor,
                size: 15,
              ),
              child: widget.icon,
            ),
          ),
        ),
      ),
    );
  }
}

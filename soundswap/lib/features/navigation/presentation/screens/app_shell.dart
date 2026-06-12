import 'dart:io';
import 'package:soundswap/app.dart';
import 'package:flutter/material.dart';
import 'package:soundswap/core/responsive/app_responsive.dart';
import 'package:soundswap/features/branding/presentation/state/branding_controller.dart';
import 'package:soundswap/features/effects/presentation/screens/effects_screen.dart';
import 'package:soundswap/features/effects/presentation/state/effects_controller.dart';
import 'package:soundswap/features/folder_watcher/presentation/screens/folder_watcher_screen.dart';
import 'package:soundswap/features/folder_watcher/presentation/state/folder_watcher_controller.dart';
import 'package:soundswap/features/home/presentation/screens/home_screen.dart';
import 'package:soundswap/features/home/presentation/state/home_controller.dart';
import 'package:soundswap/features/long_video/presentation/screens/long_video_screen.dart';
import 'package:soundswap/features/long_video/presentation/state/long_video_controller.dart';
import 'package:soundswap/features/overlay_tools/presentation/screens/overlay_tools_screen.dart';
import 'package:soundswap/features/overlay_tools/presentation/state/overlay_tools_controller.dart';
import 'package:soundswap/features/product_import/presentation/screens/product_import_screen.dart';
import 'package:soundswap/features/product_import/presentation/state/product_import_controller.dart';
import 'package:soundswap/features/result_history/presentation/screens/result_history_screen.dart';
import 'package:soundswap/features/result_history/presentation/state/result_history_controller.dart';
import 'package:soundswap/features/templates/presentation/state/templates_controller.dart';
import 'package:soundswap/features/text_overlay/presentation/state/text_overlay_controller.dart';
import 'package:soundswap/features/folder_organizer/presentation/screens/folder_organizer_screen.dart';
import 'package:soundswap/features/folder_organizer/presentation/state/folder_organizer_controller.dart';
import 'package:soundswap/features/organizer_watch/presentation/screens/organizer_watch_screen.dart';
import 'package:soundswap/features/organizer_watch/presentation/state/organizer_watch_controller.dart';
import 'package:soundswap/shared/widgets/custom_title_bar.dart';

class AppShell extends StatefulWidget {
  const AppShell({super.key});

  @override
  State<AppShell> createState() => _AppShellState();
}

class _AppShellState extends State<AppShell> {
  late final HomeController _homeController;
  late final BrandingController _brandingController;
  late final TextOverlayController _textOverlayController;
  late final OverlayToolsController _overlayController;
  late final TemplatesController _templatesController;
  late final FolderWatcherController _folderWatcherController;
  late final ResultHistoryController _resultHistoryController;
  late final EffectsController _effectsController;
  late final ProductImportController _productImportController;
  late final LongVideoController _longVideoController;
  late final FolderOrganizerController _folderOrganizerController;
  late final OrganizerWatchController _organizerWatchController;

  var _selectedIndex = 0;

  // ── Flat list of items — index is authoritative for selection ──────────
  late final List<_NavigationItem> _items = [
    // Processing group (index 0–3)
    _NavigationItem(
      label: 'Home',
      icon: Icons.home_outlined,
      selectedIcon: Icons.home,
      group: _NavGroup.processing,
      child: HomeScreen(
        controller: _homeController,
        overlayController: _overlayController,
        templatesController: _templatesController,
      ),
    ),
    _NavigationItem(
      label: 'Folder Watcher',
      icon: Icons.visibility_outlined,
      selectedIcon: Icons.visibility,
      group: _NavGroup.processing,
      child: FolderWatcherScreen(
        controller: _folderWatcherController,
        historyController: _resultHistoryController,
        templatesController: _templatesController,
        homeController: _homeController,
      ),
    ),
    _NavigationItem(
      label: 'Long Video',
      icon: Icons.video_stable_outlined,
      selectedIcon: Icons.video_stable,
      group: _NavGroup.processing,
      child: LongVideoScreen(controller: _longVideoController),
    ),
    // Editing group (index 3–4)
    _NavigationItem(
      label: 'Overlays & Templates',
      icon: Icons.layers_outlined,
      selectedIcon: Icons.layers,
      group: _NavGroup.editing,
      child: OverlayToolsScreen(
        controller: _overlayController,
        templatesController: _templatesController,
        homeController: _homeController,
        brandingController: _brandingController,
        textOverlayController: _textOverlayController,
      ),
    ),
    _NavigationItem(
      label: 'Effects',
      icon: Icons.auto_fix_high_outlined,
      selectedIcon: Icons.auto_fix_high,
      group: _NavGroup.editing,
      child: EffectsScreen(controller: _effectsController),
    ),
    // Management group (index 5–6)
    _NavigationItem(
      label: 'Result History',
      icon: Icons.history_outlined,
      selectedIcon: Icons.history,
      group: _NavGroup.management,
      child: ResultHistoryScreen(
        controller: _resultHistoryController,
        folderWatcherController: _folderWatcherController,
        onStartBatch: () => setState(() => _selectedIndex = 0),
        onOpenResultFolder: () async {
          final paths = [
            _homeController.outputFolderPath,
            _folderWatcherController.resultFolderPath,
            _longVideoController.outputFolderPath,
          ].where((p) => p != null && p.isNotEmpty).cast<String>().toList();

          if (paths.isNotEmpty) {
            final folder = Directory(paths.first);
            if (folder.existsSync()) {
              await Process.start('explorer.exe', [folder.path]);
            }
          }
        },
      ),
    ),
    _NavigationItem(
      label: 'Product Import',
      icon: Icons.upload_file_outlined,
      selectedIcon: Icons.table_chart,
      group: _NavGroup.management,
      child: ProductImportScreen(controller: _productImportController),
    ),
    _NavigationItem(
      label: 'Folder Organizer',
      icon: Icons.folder_copy_outlined,
      selectedIcon: Icons.folder_copy,
      group: _NavGroup.tools,
      child: FolderOrganizerScreen(controller: _folderOrganizerController),
    ),
    _NavigationItem(
      label: 'Organizer Watch',
      icon: Icons.auto_awesome_motion_outlined,
      selectedIcon: Icons.auto_awesome_motion,
      group: _NavGroup.tools,
      child: OrganizerWatchScreen(
        controller: _organizerWatchController,
        historyController: _resultHistoryController,
      ),
    ),
  ];

  @override
  void initState() {
    super.initState();
    _resultHistoryController = ResultHistoryController();
    _effectsController = EffectsController();
    _homeController = HomeController(
      resultHistoryController: _resultHistoryController,
      effectsController: _effectsController,
    );
    _brandingController = BrandingController();
    _textOverlayController = TextOverlayController();
    _overlayController = OverlayToolsController();
    _templatesController = TemplatesController();
    _folderWatcherController = FolderWatcherController();
    _productImportController = ProductImportController();
    _longVideoController = LongVideoController(
      resultHistoryController: _resultHistoryController,
      homeController: _homeController,
      templatesController: _templatesController,
    );
    _folderOrganizerController = FolderOrganizerController();
    _organizerWatchController = OrganizerWatchController();
    
    _homeController.initialize();
    _brandingController.load();
    _textOverlayController.load();
    _overlayController.load();
    _templatesController.load();
    _folderWatcherController.load().then((_) {
      for (final profile in _folderWatcherController.profiles) {
        if (profile.isActive) {
          _folderWatcherController.startWatching(
            profileId: profile.id,
            historyController: _resultHistoryController,
          );
        }
      }
    });
    _resultHistoryController.load();
    _effectsController.load();
    _productImportController.load();
    _folderOrganizerController.load();
    _organizerWatchController.load().then((_) {
      for (final profile in _organizerWatchController.profiles) {
        if (profile.isActive) {
          _organizerWatchController.startWatching(
            profileId: profile.id,
            historyController: _resultHistoryController,
          );
        }
      }
    });
  }

  @override
  void dispose() {
    _homeController.dispose();
    _brandingController.dispose();
    _textOverlayController.dispose();
    _overlayController.dispose();
    _templatesController.dispose();
    _folderWatcherController.dispose();
    _resultHistoryController.dispose();
    _effectsController.dispose();
    _productImportController.dispose();
    _longVideoController.dispose();
    _folderOrganizerController.dispose();
    _organizerWatchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (AppResponsive.isSmall(context)) {
      return Scaffold(
        body: Column(
          children: [
            CustomTitleBar(
              homeController: _homeController,
              folderWatcherController: _folderWatcherController,
            ),
            Expanded(
              child: IndexedStack(
                index: _selectedIndex,
                children: [for (final item in _items) item.child],
              ),
            ),
          ],
        ),
        bottomNavigationBar: NavigationBar(
          selectedIndex: _selectedIndex,
          onDestinationSelected: (index) =>
              setState(() => _selectedIndex = index),
          destinations: [
            for (final item in _items)
              NavigationDestination(
                icon: Icon(item.icon),
                selectedIcon: Icon(item.selectedIcon),
                label: item.label,
              ),
          ],
        ),
      );
    }

    return Scaffold(
      body: Column(
        children: [
          CustomTitleBar(
            homeController: _homeController,
            folderWatcherController: _folderWatcherController,
          ),
          Expanded(
            child: Row(
              children: [
                _Sidebar(
                  items: _items,
                  selectedIndex: _selectedIndex,
                  onChanged: (index) => setState(() => _selectedIndex = index),
                ),
                // Vertical divider
                VerticalDivider(
                  width: 1,
                  thickness: 1,
                  color: Theme.of(context).colorScheme.outlineVariant,
                ),
                Expanded(
                  child: IndexedStack(
                    index: _selectedIndex,
                    children: [for (final item in _items) item.child],
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

// ── Navigation groups ─────────────────────────────────────────────────────

enum _NavGroup {
  processing,
  editing,
  management,
  tools,
}

extension _NavGroupLabel on _NavGroup {
  String get label => switch (this) {
        _NavGroup.processing => 'Processing',
        _NavGroup.editing => 'Editing',
        _NavGroup.management => 'Management',
        _NavGroup.tools => 'Tools',
      };
}

// ── Sidebar ───────────────────────────────────────────────────────────────

class _Sidebar extends StatelessWidget {
  const _Sidebar({
    required this.items,
    required this.selectedIndex,
    required this.onChanged,
  });

  final List<_NavigationItem> items;
  final int selectedIndex;
  final ValueChanged<int> onChanged;

  @override
  Widget build(BuildContext context) {
    final gap = AppResponsive.cardGap(context);
    final colorScheme = Theme.of(context).colorScheme;
    final sidebarWidth = AppResponsive.isMedium(context) ? 220.0 : 244.0;

    // Group items by NavGroup
    final groups = _NavGroup.values;

    return SizedBox(
      width: sidebarWidth,
      child: Container(
        color: colorScheme.surfaceContainerLow,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // ── App logo / wordmark ────────────────────────────────────
            Padding(
              padding: EdgeInsets.fromLTRB(gap, gap, gap, gap * 0.75),
              child: Row(
                children: [
                  Container(
                    width: 32,
                    height: 32,
                    decoration: BoxDecoration(
                      color: colorScheme.primary,
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Icon(
                      Icons.swap_horizontal_circle,
                      size: 20,
                      color: colorScheme.onPrimary,
                    ),
                  ),
                  SizedBox(width: gap / 2),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'SoundSwap',
                          style: TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.w800,
                            letterSpacing: -0.3,
                            color: colorScheme.onSurface,
                          ),
                        ),
                        Text(
                          'Video Production Suite',
                          style: TextStyle(
                            fontSize: 10,
                            color: colorScheme.onSurfaceVariant,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),

            Divider(height: 1, color: colorScheme.outlineVariant),
            SizedBox(height: gap * 0.5),

            // ── Nav groups ─────────────────────────────────────────────
            Expanded(
              child: ListView(
                padding: EdgeInsets.symmetric(
                    horizontal: gap * 0.6, vertical: gap * 0.25),
                children: [
                  for (final group in groups) ...[
                    // Group label
                    Padding(
                      padding: EdgeInsets.fromLTRB(
                          gap * 0.5, gap * 0.5, gap * 0.5, gap * 0.25),
                      child: Text(
                        group.label.toUpperCase(),
                        style: TextStyle(
                          fontSize: 10,
                          fontWeight: FontWeight.w700,
                          color: colorScheme.onSurfaceVariant
                              .withValues(alpha: 0.6),
                          letterSpacing: 0.8,
                        ),
                      ),
                    ),
                    // Items in group
                    for (var i = 0; i < items.length; i++)
                      if (items[i].group == group)
                        _SidebarButton(
                          item: items[i],
                          selected: i == selectedIndex,
                          onPressed: () => onChanged(i),
                        ),
                    SizedBox(height: gap * 0.25),
                  ],
                ],
              ),
            ),

            // ── Footer ─────────────────────────────────────────────────
            Divider(height: 1, color: colorScheme.outlineVariant),
            Padding(
              padding: EdgeInsets.symmetric(
                  horizontal: gap * 0.75, vertical: gap * 0.5),
              child: Row(
                children: [
                  Expanded(
                    child: Text(
                      '© Hoeun Raksa',
                      style: TextStyle(
                        fontSize: 10,
                        color:
                            colorScheme.onSurfaceVariant.withValues(alpha: 0.5),
                      ),
                    ),
                  ),
                  // Theme toggle
                  ValueListenableBuilder<ThemeMode>(
                    valueListenable: SoundSwapApp.themeNotifier,
                    builder: (context, mode, _) {
                      final isDark = mode == ThemeMode.dark ||
                          (mode == ThemeMode.system &&
                              MediaQuery.platformBrightnessOf(context) ==
                                  Brightness.dark);
                      return Tooltip(
                        message: isDark
                            ? 'Switch to light mode'
                            : 'Switch to dark mode',
                        child: InkWell(
                          onTap: () {
                            SoundSwapApp.themeNotifier.value =
                                isDark ? ThemeMode.light : ThemeMode.dark;
                          },
                          borderRadius: BorderRadius.circular(6),
                          child: Padding(
                            padding: const EdgeInsets.all(4),
                            child: Icon(
                              isDark
                                  ? Icons.light_mode_outlined
                                  : Icons.dark_mode_outlined,
                              size: 15,
                              color: colorScheme.onSurfaceVariant
                                  .withValues(alpha: 0.7),
                            ),
                          ),
                        ),
                      );
                    },
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ── Sidebar button ────────────────────────────────────────────────────────

class _SidebarButton extends StatelessWidget {
  const _SidebarButton({
    required this.item,
    required this.selected,
    required this.onPressed,
  });

  final _NavigationItem item;
  final bool selected;
  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final gap = AppResponsive.cardGap(context);

    return Padding(
      padding: EdgeInsets.only(bottom: 2),
      child: Material(
        color: selected
            ? colorScheme.primaryContainer
            : Colors.transparent,
        borderRadius: BorderRadius.circular(8),
        child: InkWell(
          onTap: onPressed,
          borderRadius: BorderRadius.circular(8),
          hoverColor: colorScheme.onSurface.withValues(alpha: 0.06),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
            child: Row(
              children: [
                Icon(
                  selected ? item.selectedIcon : item.icon,
                  color: selected
                      ? colorScheme.onPrimaryContainer
                      : colorScheme.onSurfaceVariant,
                  size: 18,
                ),
                SizedBox(width: gap * 0.6),
                Expanded(
                  child: Text(
                    item.label,
                    style: TextStyle(
                      color: selected
                          ? colorScheme.onPrimaryContainer
                          : colorScheme.onSurface,
                      fontSize: 13,
                      fontWeight:
                          selected ? FontWeight.w700 : FontWeight.w500,
                      letterSpacing: -0.1,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

// ── Data class ────────────────────────────────────────────────────────────

class _NavigationItem {
  const _NavigationItem({
    required this.label,
    required this.icon,
    required this.selectedIcon,
    required this.child,
    required this.group,
  });

  final String label;
  final IconData icon;
  final IconData selectedIcon;
  final Widget child;
  final _NavGroup group;
}

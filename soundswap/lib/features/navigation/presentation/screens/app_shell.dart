import 'package:flutter/material.dart';
import 'package:soundswap/core/responsive/app_responsive.dart';
import 'package:soundswap/features/branding/presentation/screens/branding_tools_screen.dart';
import 'package:soundswap/features/branding/presentation/state/branding_controller.dart';
import 'package:soundswap/features/effects/presentation/screens/effects_screen.dart';
import 'package:soundswap/features/effects/presentation/state/effects_controller.dart';
import 'package:soundswap/features/folder_watcher/presentation/screens/folder_watcher_screen.dart';
import 'package:soundswap/features/folder_watcher/presentation/state/folder_watcher_controller.dart';
import 'package:soundswap/features/home/presentation/screens/home_screen.dart';
import 'package:soundswap/features/home/presentation/state/home_controller.dart';
import 'package:soundswap/features/product_import/presentation/screens/product_import_screen.dart';
import 'package:soundswap/features/product_import/presentation/state/product_import_controller.dart';
import 'package:soundswap/features/templates/presentation/screens/templates_screen.dart';
import 'package:soundswap/features/templates/presentation/state/templates_controller.dart';
import 'package:soundswap/features/text_overlay/presentation/screens/text_overlay_screen.dart';
import 'package:soundswap/features/text_overlay/presentation/state/text_overlay_controller.dart';

class AppShell extends StatefulWidget {
  const AppShell({super.key});

  @override
  State<AppShell> createState() => _AppShellState();
}

class _AppShellState extends State<AppShell> {
  final _homeController = HomeController();
  final _brandingController = BrandingController();
  final _textOverlayController = TextOverlayController();
  final _templatesController = TemplatesController();
  final _folderWatcherController = FolderWatcherController();
  final _effectsController = EffectsController();
  final _productImportController = ProductImportController();
  var _selectedIndex = 0;

  late final List<_NavigationItem> _items = [
    _NavigationItem(
      label: 'Home',
      icon: Icons.home_outlined,
      selectedIcon: Icons.home,
      child: HomeScreen(controller: _homeController),
    ),
    _NavigationItem(
      label: 'Branding Tools',
      icon: Icons.workspace_premium_outlined,
      selectedIcon: Icons.workspace_premium,
      child: BrandingToolsScreen(controller: _brandingController),
    ),
    _NavigationItem(
      label: 'Text Overlay',
      icon: Icons.text_fields,
      selectedIcon: Icons.title,
      child: TextOverlayScreen(controller: _textOverlayController),
    ),
    _NavigationItem(
      label: 'Templates',
      icon: Icons.dashboard_customize_outlined,
      selectedIcon: Icons.dashboard_customize,
      child: TemplatesScreen(
        controller: _templatesController,
        homeController: _homeController,
        brandingController: _brandingController,
        textOverlayController: _textOverlayController,
      ),
    ),
    _NavigationItem(
      label: 'Folder Watcher',
      icon: Icons.visibility_outlined,
      selectedIcon: Icons.visibility,
      child: FolderWatcherScreen(controller: _folderWatcherController),
    ),
    _NavigationItem(
      label: 'Effects',
      icon: Icons.tune,
      selectedIcon: Icons.tune,
      child: EffectsScreen(controller: _effectsController),
    ),
    _NavigationItem(
      label: 'Product Import',
      icon: Icons.upload_file_outlined,
      selectedIcon: Icons.table_chart,
      child: ProductImportScreen(controller: _productImportController),
    ),
  ];

  @override
  void initState() {
    super.initState();
    _homeController.initializeOutputFolder();
    _brandingController.load();
    _textOverlayController.load();
    _templatesController.load();
    _effectsController.load();
    _productImportController.load();
  }

  @override
  void dispose() {
    _homeController.dispose();
    _brandingController.dispose();
    _textOverlayController.dispose();
    _templatesController.dispose();
    _folderWatcherController.dispose();
    _effectsController.dispose();
    _productImportController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (AppResponsive.isSmall(context)) {
      return Scaffold(
        body: SafeArea(child: _items[_selectedIndex].child),
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
      body: SafeArea(
        child: Row(
          children: [
            _Sidebar(
              items: _items,
              selectedIndex: _selectedIndex,
              onChanged: (index) => setState(() => _selectedIndex = index),
            ),
            Expanded(child: _items[_selectedIndex].child),
          ],
        ),
      ),
    );
  }
}

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

    return Container(
      width: AppResponsive.isMedium(context) ? 230 : 260,
      padding: EdgeInsets.all(gap),
      decoration: BoxDecoration(
        color: colorScheme.surfaceContainerLow,
        border: Border(right: BorderSide(color: colorScheme.outlineVariant)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(
                Icons.swap_horizontal_circle_outlined,
                size: AppResponsive.iconSize(context) + 8,
                color: colorScheme.primary,
              ),
              SizedBox(width: gap / 2),
              Expanded(
                child: Text(
                  'SoundSwap',
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    fontSize: AppResponsive.titleSize(context) - 4,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ],
          ),
          SizedBox(height: gap * 1.5),
          for (var i = 0; i < items.length; i++)
            _SidebarButton(
              item: items[i],
              selected: i == selectedIndex,
              onPressed: () => onChanged(i),
            ),
          const Spacer(),
          Text(
            'Copyright by Hoeun Raksa',
            style: Theme.of(context).textTheme.labelSmall?.copyWith(
              color: colorScheme.onSurfaceVariant.withValues(alpha: 0.65),
            ),
          ),
        ],
      ),
    );
  }
}

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
      padding: EdgeInsets.only(bottom: gap / 3),
      child: Material(
        color: selected ? colorScheme.primaryContainer : Colors.transparent,
        borderRadius: BorderRadius.circular(AppResponsive.cardRadius(context)),
        child: InkWell(
          onTap: onPressed,
          borderRadius: BorderRadius.circular(
            AppResponsive.cardRadius(context),
          ),
          child: Padding(
            padding: EdgeInsets.symmetric(
              horizontal: gap * 0.7,
              vertical: gap * 0.6,
            ),
            child: Row(
              children: [
                Icon(
                  selected ? item.selectedIcon : item.icon,
                  color: selected
                      ? colorScheme.onPrimaryContainer
                      : colorScheme.onSurfaceVariant,
                  size: AppResponsive.iconSize(context),
                ),
                SizedBox(width: gap / 2),
                Expanded(
                  child: Text(
                    item.label,
                    style: TextStyle(
                      color: selected
                          ? colorScheme.onPrimaryContainer
                          : colorScheme.onSurface,
                      fontSize: AppResponsive.bodySize(context),
                      fontWeight: selected ? FontWeight.w700 : FontWeight.w500,
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

class _NavigationItem {
  const _NavigationItem({
    required this.label,
    required this.icon,
    required this.selectedIcon,
    required this.child,
  });

  final String label;
  final IconData icon;
  final IconData selectedIcon;
  final Widget child;
}

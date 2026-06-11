import 'package:flutter/material.dart';
import 'package:soundswap/core/theme/app_theme.dart';
import 'package:soundswap/features/navigation/presentation/screens/app_shell.dart';

class SoundSwapApp extends StatefulWidget {
  const SoundSwapApp({super.key});

  // Global notifier so any widget can toggle the theme.
  static final themeNotifier = ValueNotifier<ThemeMode>(ThemeMode.dark);

  @override
  State<SoundSwapApp> createState() => _SoundSwapAppState();
}

class _SoundSwapAppState extends State<SoundSwapApp> {
  @override
  void initState() {
    super.initState();
    SoundSwapApp.themeNotifier.addListener(_onThemeChanged);
  }

  @override
  void dispose() {
    SoundSwapApp.themeNotifier.removeListener(_onThemeChanged);
    super.dispose();
  }

  void _onThemeChanged() => setState(() {});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'SoundSwap',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.light(),
      darkTheme: AppTheme.dark(),
      themeMode: SoundSwapApp.themeNotifier.value,
      home: const AppShell(),
    );
  }
}

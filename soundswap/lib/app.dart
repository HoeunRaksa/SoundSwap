import 'package:flutter/material.dart';
import 'package:soundswap/core/theme/app_theme.dart';
import 'package:soundswap/features/navigation/presentation/screens/app_shell.dart';

class SoundSwapApp extends StatelessWidget {
  const SoundSwapApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'SoundSwap',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.light(),
      darkTheme: AppTheme.dark(),
      themeMode: ThemeMode.system,
      home: const AppShell(),
    );
  }
}

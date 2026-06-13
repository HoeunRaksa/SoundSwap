import 'package:flutter/material.dart';
import 'package:soundswap/app.dart';
import 'package:soundswap/features/fonts/data/services/font_service.dart';
import 'package:window_manager/window_manager.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await windowManager.ensureInitialized();
  
  await FontService().installBundledFonts();
  await FontService().loadImportedFonts();
  await FontService().discoverWindowsFonts();

  WindowOptions windowOptions = const WindowOptions(
    size: Size(1280, 800),
    minimumSize: Size(960, 600),
    center: true,
    backgroundColor: Colors.transparent,
    skipTaskbar: false,
    titleBarStyle: TitleBarStyle.hidden,
  );
  windowManager.waitUntilReadyToShow(windowOptions, () async {
    await windowManager.show();
    await windowManager.focus();
  });

  runApp(const SoundSwapApp());
}

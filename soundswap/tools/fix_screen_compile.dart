import 'dart:io';

void main() {
  String content = File('lib/features/overlay_tools/presentation/screens/overlay_tools_screen.dart').readAsStringSync();

  content = content.replaceFirst(
    "import 'package:soundswap/features/overlay_tools/data/models/video_output_size.dart';",
    "import 'package:soundswap/core/video/video_output_settings.dart';"
  );

  content = content.replaceAll('backgroundColorHex: item.backgroundColorHex,', '');

  File('lib/features/overlay_tools/presentation/screens/overlay_tools_screen.dart').writeAsStringSync(content);
  print('Fixed remaining compile errors.');
}

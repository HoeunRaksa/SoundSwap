import 'dart:io';

void main() {
  String content = File('lib/features/overlay_tools/presentation/screens/overlay_tools_screen.dart').readAsStringSync();

  String imports = '''
import 'package:soundswap/features/home/presentation/state/home_controller.dart';
import 'package:soundswap/features/branding/presentation/state/branding_controller.dart';
import 'package:soundswap/features/text_overlay/presentation/state/text_overlay_controller.dart';
import 'package:soundswap/features/overlay_tools/data/models/video_output_size.dart';
''';

  content = content.replaceFirst("import 'package:soundswap/core/responsive/app_responsive.dart';", imports + "import 'package:soundswap/core/responsive/app_responsive.dart';");

  String oldConstructor = '''
class OverlayToolsScreen extends StatefulWidget {
  const OverlayToolsScreen({
    required this.controller,
    required this.templatesController,
    super.key,
  });

  final OverlayToolsController controller;
  final TemplatesController templatesController;
''';

  String newConstructor = '''
class OverlayToolsScreen extends StatefulWidget {
  const OverlayToolsScreen({
    required this.controller,
    required this.templatesController,
    required this.homeController,
    required this.brandingController,
    required this.textOverlayController,
    super.key,
  });

  final OverlayToolsController controller;
  final TemplatesController templatesController;
  final HomeController homeController;
  final BrandingController brandingController;
  final TextOverlayController textOverlayController;
''';

  content = content.replaceFirst(oldConstructor, newConstructor);

  File('lib/features/overlay_tools/presentation/screens/overlay_tools_screen.dart').writeAsStringSync(content);
  print('Fixed constructor and imports.');
}

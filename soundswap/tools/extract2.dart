import 'dart:io';

void main() {
  final content = File('lib/features/overlay_tools/presentation/screens/overlay_tools_screen.dart').readAsStringSync();
  
  final tileStart = content.indexOf('class _OverlayListTile extends StatelessWidget {');
  final templateTileStart = content.indexOf('class _TemplateTile extends StatelessWidget {');
  
  final tileCode = content.substring(tileStart, templateTileStart);
  File('tile_raw.txt').writeAsStringSync(tileCode);
  print('Extracted tile successfully.');
}

import 'dart:io';

void main() {
  String layersFile = File('lib/features/overlay_tools/presentation/widgets/overlay_layers_panel.dart').readAsStringSync();
  
  if (!layersFile.contains("import 'dart:io';")) {
    layersFile = "import 'dart:io';\n" + layersFile;
  }
  if (!layersFile.contains("import 'package:path/path.dart' as p;")) {
    layersFile = "import 'package:path/path.dart' as p;\n" + layersFile;
  }

  File('lib/features/overlay_tools/presentation/widgets/overlay_layers_panel.dart').writeAsStringSync(layersFile);

  String propFile = File('lib/features/overlay_tools/presentation/widgets/overlay_properties_panel.dart').readAsStringSync();
  
  if (!propFile.contains("import 'dart:io';")) {
    propFile = "import 'dart:io';\n" + propFile;
  }
  if (!propFile.contains("import 'package:path/path.dart' as p;")) {
    propFile = "import 'package:path/path.dart' as p;\n" + propFile;
  }
  if (!propFile.contains("import 'package:file_picker/file_picker.dart';")) {
    propFile = "import 'package:file_picker/file_picker.dart';\n" + propFile;
  }

  String cleanImagePath = '''
  Widget _buildCleanImagePath(BuildContext context, String? imagePath) {
    final theme = Theme.of(context);
    if (imagePath == null) {
      return Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: theme.colorScheme.surfaceContainerHighest.withValues(alpha: 0.5),
          borderRadius: BorderRadius.circular(8),
        ),
        child: const Row(
          children: [
            Icon(Icons.image_not_supported_outlined, size: 20),
            SizedBox(width: 8),
            Text('No image selected'),
          ],
        ),
      );
    }
    final filename = p.basename(imagePath);
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: theme.colorScheme.surfaceContainerHighest.withValues(alpha: 0.3),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(
          color: theme.colorScheme.outlineVariant.withValues(alpha: 0.3),
        ),
      ),
      child: Row(
        children: [
          Icon(Icons.image_outlined, color: theme.colorScheme.primary, size: 22),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  filename,
                  style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 2),
                Text(
                  imagePath,
                  style: TextStyle(
                    fontSize: 10,
                    color: theme.colorScheme.onSurfaceVariant.withValues(alpha: 0.7),
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
''';
  if (!propFile.contains('_buildCleanImagePath')) {
    propFile = propFile.replaceAll('}\n\nclass _TwoColumn', cleanImagePath + '\n}\n\nclass _TwoColumn');
  }

  File('lib/features/overlay_tools/presentation/widgets/overlay_properties_panel.dart').writeAsStringSync(propFile);
  print('Fixed panels.');
}

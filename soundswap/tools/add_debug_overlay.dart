import 'dart:io';

void main() {
  String content = File('lib/features/overlay_tools/presentation/screens/full_screen_editor_screen.dart').readAsStringSync();

  String oldReturn = '''
            return InteractiveViewer(
              constrained: false, // allow panning if larger than viewport
              minScale: 1.0, // zoom is handled by our computedScale, so InteractiveViewer zoom is locked
              maxScale: 1.0, 
              child: Container(
                width: scrollableWidth,
                height: scrollableHeight,
                alignment: Alignment.center,
                child: SizedBox(
                  width: canvasWidth,
                  height: canvasHeight,
''';

  String newReturn = '''
            return Stack(
              children: [
                InteractiveViewer(
                  constrained: false, // allow panning if larger than viewport
                  minScale: 1.0, // zoom is handled by our computedScale, so InteractiveViewer zoom is locked
                  maxScale: 1.0, 
                  child: Container(
                    width: scrollableWidth,
                    height: scrollableHeight,
                    alignment: Alignment.center,
                    child: SizedBox(
                      width: canvasWidth,
                      height: canvasHeight,
''';

  content = content.replaceFirst(oldReturn, newReturn);

  String oldEnd = '''
                  ),
                ),
              ),
            );
          },
        ),
''';

  String newEnd = '''
                  ),
                ),
              ),
                Positioned(
                  top: 16,
                  left: 16,
                  child: Container(
                    padding: const EdgeInsets.all(8),
                    color: Colors.black87,
                    child: Text(
                      'Available Center Area:\\n\${availableWidth.toStringAsFixed(0)} x \${availableHeight.toStringAsFixed(0)}\\n\\nCanvas:\\n\${canvasWidth.toStringAsFixed(0)} x \${canvasHeight.toStringAsFixed(0)}\\nScale: \${(computedScale * 100).toStringAsFixed(0)}%',
                      style: const TextStyle(color: Colors.yellowAccent, fontSize: 14),
                    ),
                  ),
                ),
              ],
            );
          },
        ),
''';

  content = content.replaceFirst(oldEnd, newEnd);

  File('lib/features/overlay_tools/presentation/screens/full_screen_editor_screen.dart').writeAsStringSync(content);
  print('Patched full_screen_editor_screen.dart with debug text');
}

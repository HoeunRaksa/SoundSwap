import 'dart:io';

void main() {
  String content = File('lib/features/overlay_tools/presentation/screens/overlay_tools_screen.dart').readAsStringSync();

  String segmentStr = '''
                        SegmentedButton<VideoOutputSize>(
                          segments: const [
                            ButtonSegment(value: VideoOutputSize.vertical1080, icon: Icon(Icons.smartphone), label: Text('9:16')),
                            ButtonSegment(value: VideoOutputSize.horizontal1080, icon: Icon(Icons.desktop_windows), label: Text('16:9')),
                            ButtonSegment(value: VideoOutputSize.square1080, icon: Icon(Icons.crop_square), label: Text('1:1')),
                          ],
                          selected: {_previewSize},
                          onSelectionChanged: (set) => setState(() => _previewSize = set.first),
                          style: SegmentedButton.styleFrom(visualDensity: VisualDensity.compact),
                        ),
''';

  content = content.replaceFirst(segmentStr, '');

  File('lib/features/overlay_tools/presentation/screens/overlay_tools_screen.dart').writeAsStringSync(content);
  print('Removed SegmentedButton');
}

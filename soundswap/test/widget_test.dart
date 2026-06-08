import 'package:flutter_test/flutter_test.dart';
import 'package:soundswap/app.dart';

void main() {
  testWidgets('renders SoundSwap shell', (WidgetTester tester) async {
    await tester.pumpWidget(const SoundSwapApp());

    expect(find.text('SoundSwap'), findsOneWidget);
    expect(find.text('FFmpeg CLI'), findsOneWidget);
  });
}

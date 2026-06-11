import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:soundswap/app.dart';

void main() {
  testWidgets('renders SoundSwap shell', (WidgetTester tester) async {
    // Set desktop window size
    tester.view.physicalSize = const Size(1200, 1000);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    await tester.pumpWidget(const SoundSwapApp());

    expect(find.text('SoundSwap'), findsWidgets);
    expect(find.text('Home'), findsOneWidget);
    expect(find.text('Overlays & Templates'), findsOneWidget);
    expect(find.text('Folder Organizer'), findsOneWidget);
  });
}

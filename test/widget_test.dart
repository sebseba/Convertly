// This is a basic Flutter widget test.
//
// To perform an interaction with a widget in your test, use the WidgetTester
// utility in the flutter_test package. For example, you can send tap and scroll
// gestures. You can also use WidgetTester to find child widgets in the widget
// tree, read text, and verify that the values of widget properties are correct.

import 'package:convertly_mobile_app/main.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  testWidgets('Convertly app smoke test', (WidgetTester tester) async {
    // Build our app and trigger a frame.
    await tester.pumpWidget(const ConvertlyApp());

    // Verify that the app title is displayed
    expect(find.text('Convertly'), findsOneWidget);

    // Verify that the converter page is loaded by checking for category dropdown
    expect(find.text('Kategori'), findsOneWidget);

    // Verify that the default category (Uzunluk) is selected
    expect(find.text('Uzunluk'), findsOneWidget);
  });
}

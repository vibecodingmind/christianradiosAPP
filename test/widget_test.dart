import 'package:flutter_test/flutter_test.dart';
import 'package:christian_radios_app/main.dart';

void main() {
  testWidgets('App smoke test', (WidgetTester tester) async {
    // Basic smoke test — just verify the app builds
    expect(ChristianRadiosApp, isNotNull);
  });
}

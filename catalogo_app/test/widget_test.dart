import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:catalogo_app/main.dart';

void main() {
  setUpAll(() async {
    await dotenv.load();
  });

  testWidgets('App smoke test', (WidgetTester tester) async {
    SharedPreferences.setMockInitialValues({});
    final prefs = await SharedPreferences.getInstance();

    await tester.pumpWidget(CatalogoApp(prefs: prefs));
    await tester.pumpAndSettle();

    expect(find.byType(CatalogoApp), findsOneWidget);
  });
}
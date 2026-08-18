import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';

import 'package:catalogo_app/main.dart';

void main() {
  setUpAll(() async {
    await dotenv.load();
  });

  testWidgets('App smoke test', (WidgetTester tester) async {
    await tester.pumpWidget(const CatalogoApp());
    await tester.pumpAndSettle();

    expect(find.byType(CatalogoApp), findsOneWidget);
  });
}
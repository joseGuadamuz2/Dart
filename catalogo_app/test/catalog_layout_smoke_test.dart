import 'package:flutter/material.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';

import 'package:catalogo_app/core/api/api_client.dart';
import 'package:catalogo_app/core/theme/app_colors.dart';
import 'package:catalogo_app/features/catalog/public_catalog_screen.dart';
import 'package:catalogo_app/shared/widgets/whatsapp_button.dart';

Widget _wrap(Widget child, Size size) {
  return MultiProvider(
    providers: [Provider<ApiClient>.value(value: ApiClient())],
    child: MediaQuery(
      data: MediaQueryData(size: size),
      child: MaterialApp(home: Scaffold(body: child)),
    ),
  );
}

void _setViewport(WidgetTester tester, Size size) {
  tester.view.physicalSize = size;
  tester.view.devicePixelRatio = 1.0;
  addTearDown(tester.view.reset);
}

Future<void> _pumpFrames(WidgetTester tester, int frames) async {
  for (var i = 0; i < frames; i++) {
    await tester.pump(const Duration(milliseconds: 100));
  }
}

class _CardReplica extends StatelessWidget {
  const _CardReplica();

  @override
  Widget build(BuildContext context) {
    return MouseRegion(
      child: AnimatedScale(
        scale: 1,
        duration: const Duration(milliseconds: 150),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 150),
          decoration: BoxDecoration(
            color: AppColors.surface,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: AppColors.border),
          ),
          clipBehavior: Clip.antiAlias,
          child: InkWell(
            onTap: () {},
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Expanded(
                  child: Stack(
                    fit: StackFit.expand,
                    children: [
                      ColoredBox(
                        color: AppColors.surfaceMuted,
                        child: Container(),
                      ),
                      Positioned(
                        top: 10,
                        left: 10,
                        child: Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 7, vertical: 3),
                          decoration: BoxDecoration(
                            color: AppColors.discountBadge,
                            borderRadius: BorderRadius.circular(6),
                          ),
                          child: const Text("-10%",
                              style: TextStyle(color: Colors.white)),
                        ),
                      ),
                      Positioned(
                        top: 8,
                        right: 8,
                        child: Material(
                          color: Colors.white,
                          shape: const CircleBorder(),
                          child: InkWell(
                            onTap: () {},
                            customBorder: const CircleBorder(),
                            child: const SizedBox(width: 30, height: 30),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.fromLTRB(12, 10, 12, 12),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: const [
                          Text("Producto de prueba con nombre largo",
                              maxLines: 2),
                          SizedBox(height: 3),
                          Text("Categoria", maxLines: 1),
                        ],
                      ),
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            crossAxisAlignment: CrossAxisAlignment.baseline,
                            textBaseline: TextBaseline.alphabetic,
                            children: const [
                              Flexible(child: Text(r"$10.000")),
                              SizedBox(width: 7),
                              Flexible(child: Text(r"$12.000")),
                            ],
                          ),
                          const SizedBox(height: 10),
                          const WhatsappButton(
                            label: "Consultar por WhatsApp",
                            link: "https://wa.me/12345678",
                            compact: true,
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

Widget _gridReplica() {
  return CustomScrollView(
    slivers: [
      SliverPadding(
        padding: const EdgeInsets.all(16),
        sliver: SliverGrid(
          gridDelegate: const SliverGridDelegateWithMaxCrossAxisExtent(
            maxCrossAxisExtent: 240,
            mainAxisSpacing: 14,
            crossAxisSpacing: 14,
            childAspectRatio: 0.60,
          ),
          delegate: SliverChildBuilderDelegate(
            (context, index) => const _CardReplica(),
            childCount: 6,
          ),
        ),
      ),
    ],
  );
}

void main() {
  setUpAll(() {
    dotenv.testLoad(
      fileInput: "API_URL=http://localhost:3000\n"
          "PUBLIC_CATALOG_URL=http://localhost:3000",
    );
  });

  testWidgets(
    "skeleton del catalogo (espera inicial) sin excepciones - viewport web",
    (tester) async {
      _setViewport(tester, const Size(1200, 800));
      await tester.pumpWidget(_wrap(const PublicCatalogScreen(companyId: "x"),
          const Size(1200, 800)));
      await _pumpFrames(tester, 15);
      expect(tester.takeException(), isNull);
    },
  );

  testWidgets(
    "grilla de cards replica sin excepciones - viewport web ancho",
    (tester) async {
      _setViewport(tester, const Size(1200, 800));
      await tester.pumpWidget(_wrap(_gridReplica(), const Size(1200, 800)));
      await _pumpFrames(tester, 20);

      final gesture = await tester.startGesture(tester.getCenter(find.byType(InkWell).first));
      await gesture.moveBy(const Offset(1, 0));
      await tester.pump();
      await gesture.up();
      await tester.pump();

      expect(tester.takeException(), isNull);
    },
  );

  testWidgets(
    "grilla de cards replica sin excepciones - viewport movil",
    (tester) async {
      _setViewport(tester, const Size(390, 844));
      await tester.pumpWidget(_wrap(_gridReplica(), const Size(390, 844)));
      await _pumpFrames(tester, 20);
      expect(tester.takeException(), isNull);
    },
  );
}

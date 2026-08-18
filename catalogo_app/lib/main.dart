import 'package:flutter/material.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'core/api/api_client.dart';
import 'core/auth/auth_provider.dart';
import 'core/auth/auth_service.dart';
import 'core/cache/cache_service.dart';
import 'core/constants/app_strings.dart';
import 'core/router/app_router.dart';
import 'core/theme/app_theme.dart';
import 'features/categories/category_provider.dart';
import 'features/categories/category_service.dart';
import 'features/companies/company_provider.dart';
import 'features/companies/company_service.dart';
import 'features/products/product_provider.dart';
import 'features/products/product_service.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await dotenv.load(fileName: ".env");
  final prefs = await SharedPreferences.getInstance();
  runApp(CatalogoApp(prefs: prefs));
}

class CatalogoApp extends StatelessWidget {
  final SharedPreferences prefs;

  const CatalogoApp({super.key, required this.prefs});

  @override
  Widget build(BuildContext context) {
    final apiClient = ApiClient();
    final cacheService = CacheService(prefs);
    final authProvider = AuthProvider(AuthService(apiClient))..checkAuth();
    apiClient.onUnauthorized = authProvider.logout;

    return MultiProvider(
      providers: [
        Provider.value(value: apiClient),
        Provider.value(value: cacheService),
        ChangeNotifierProvider.value(value: authProvider),
        ChangeNotifierProvider(
          create: (_) =>
              CompanyProvider(CompanyService(apiClient), cacheService),
        ),
        ChangeNotifierProvider(
          create: (_) =>
              CategoryProvider(CategoryService(apiClient), cacheService),
        ),
        ChangeNotifierProvider(
          create: (_) => ProductProvider(ProductService(apiClient)),
        ),
      ],
      child: Builder(
        builder: (context) {
          final router = createRouter(context.watch<AuthProvider>());
          return MaterialApp.router(
            title: AppStrings.appTitle,
            debugShowCheckedModeBanner: false,
            theme: AppTheme.light,
            routerConfig: router,
          );
        },
      ),
    );
  }
}
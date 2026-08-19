import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'core/api/api_client.dart';
import 'core/auth/auth_provider.dart';
import 'core/auth/auth_service.dart';
import 'core/cache/cache_service.dart';
import 'core/constants/app_strings.dart';
import 'core/router/app_router.dart';
import 'core/theme/app_colors.dart';
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

class CatalogoApp extends StatefulWidget {
  final SharedPreferences prefs;

  const CatalogoApp({super.key, required this.prefs});

  @override
  State<CatalogoApp> createState() => _CatalogoAppState();
}

class _CatalogoAppState extends State<CatalogoApp> {
  final _messengerKey = GlobalKey<ScaffoldMessengerState>();
  late final ApiClient _apiClient;
  late final CacheService _cacheService;
  late final AuthProvider _authProvider;
  late final GoRouter _router;

  @override
  void initState() {
    super.initState();
    _apiClient = ApiClient();
    _cacheService = CacheService(widget.prefs);
    _authProvider = AuthProvider(AuthService(_apiClient));
    _apiClient.onUnauthorized = _authProvider.logout;
    _apiClient.onError = _showGlobalError;
    _router = createRouter(_authProvider);
    _authProvider.checkAuth();
  }

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        Provider.value(value: _apiClient),
        Provider.value(value: _cacheService),
        ChangeNotifierProvider.value(value: _authProvider),
        ChangeNotifierProvider(
          create: (_) =>
              CompanyProvider(CompanyService(_apiClient), _cacheService),
        ),
        ChangeNotifierProvider(
          create: (_) =>
              CategoryProvider(CategoryService(_apiClient), _cacheService),
        ),
        ChangeNotifierProvider(
          create: (_) => ProductProvider(ProductService(_apiClient)),
        ),
      ],
      child: MaterialApp.router(
        title: AppStrings.appTitle,
        debugShowCheckedModeBanner: false,
        theme: AppTheme.light,
        scaffoldMessengerKey: _messengerKey,
        routerConfig: _router,
      ),
    );
  }

  void _showGlobalError(DioException error, String message) {
    final response = error.response;
    final isConnectivity =
        response == null || error.type == DioExceptionType.connectionError;
    final isServerError = response != null && response.statusCode != null && response.statusCode! >= 500;
    if (!isConnectivity && !isServerError) return;
    _messengerKey.currentState
      ?..hideCurrentSnackBar()
      ..showSnackBar(
        SnackBar(
          backgroundColor: AppColors.danger,
          content: Text(message),
        ),
      );
  }
}
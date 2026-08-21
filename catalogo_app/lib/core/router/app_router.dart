import 'package:go_router/go_router.dart';

import '../auth/auth_provider.dart';
import '../models/category.dart';
import '../models/company.dart';
import '../../features/admin/admin_companies_screen.dart';
import '../../features/admin/admin_licenses_screen.dart';
import '../../features/admin/admin_users_screen.dart';
import '../../features/auth/login_screen.dart';
import '../../features/catalog/public_catalog_screen.dart';
import '../../features/catalog/public_product_detail_screen.dart';
import '../../features/categories/category_form_screen.dart';
import '../../features/categories/category_list_screen.dart';
import '../../features/companies/company_form_screen.dart';
import '../../features/companies/company_list_screen.dart';
import '../../features/home/home_screen.dart';
import '../../features/products/product_detail_screen.dart';
import '../../features/products/product_form_screen.dart';
import '../../features/products/product_list_screen.dart';
import '../../features/products/product_model.dart';

GoRouter createRouter(AuthProvider authProvider) {
  return GoRouter(
    initialLocation: "/login",
    refreshListenable: authProvider,
    redirect: (context, state) {
      final isLoggedIn = authProvider.isAuthenticated;
      final isPublicRoute =
          state.matchedLocation.startsWith('/public-catalog');
      final isLoggingIn = state.matchedLocation == "/login";

      if (!isLoggedIn && !isLoggingIn && !isPublicRoute) return "/login";
      if (isLoggedIn && isLoggingIn) return "/home";
      return null;
    },
    routes: [
      GoRoute(
        path: "/login",
        builder: (context, state) => const LoginScreen(),
      ),
      GoRoute(
        path: "/home",
        builder: (context, state) => const HomeScreen(),
      ),
      GoRoute(
        path: "/products",
        builder: (context, state) => const ProductListScreen(),
      ),
      GoRoute(
        path: "/products/new",
        builder: (context, state) =>
            ProductFormScreen(companyId: state.extra as String?),
      ),
      GoRoute(
        path: "/products/:id",
        builder: (context, state) =>
            ProductDetailScreen(product: state.extra as Product),
      ),
      GoRoute(
        path: "/products/:id/edit",
        builder: (context, state) =>
            ProductFormScreen(product: state.extra as Product?),
      ),
      GoRoute(
        path: "/companies",
        builder: (context, state) => const CompanyListScreen(),
      ),
      GoRoute(
        path: "/companies/:id/products",
        builder: (context, state) => ProductListScreen(
          initialCompanyId: state.pathParameters["id"],
        ),
      ),
      GoRoute(
        path: "/companies/:id/categories",
        builder: (context, state) => CategoryListScreen(
          initialCompanyId: state.pathParameters["id"],
        ),
      ),
      GoRoute(
        path: "/companies/new",
        builder: (context, state) => const CompanyFormScreen(),
      ),
      GoRoute(
        path: "/companies/:id/edit",
        builder: (context, state) =>
            CompanyFormScreen(company: state.extra as Company?),
      ),
      GoRoute(
        path: "/categories",
        builder: (context, state) => const CategoryListScreen(),
      ),
      GoRoute(
        path: "/categories/new",
        builder: (context, state) =>
            CategoryFormScreen(companyId: state.extra as String?),
      ),
      GoRoute(
        path: "/categories/:id/edit",
        builder: (context, state) =>
            CategoryFormScreen(category: state.extra as Category?),
      ),
      GoRoute(
        path: "/public-catalog/:companyId",
        builder: (context, state) => PublicCatalogScreen(
          companyId: state.pathParameters["companyId"]!,
          companyName: state.extra as String?,
        ),
      ),
      GoRoute(
        path: "/public-catalog/:companyId/products/:productId",
        builder: (context, state) => PublicProductDetailScreen(
          companyId: state.pathParameters["companyId"]!,
          productId: state.pathParameters["productId"]!,
          companyName: state.extra as String?,
        ),
      ),
      GoRoute(
        path: "/admin/companies",
        builder: (context, state) => const AdminCompaniesScreen(),
      ),
      GoRoute(
        path: "/admin/users",
        builder: (context, state) => const AdminUsersScreen(),
      ),
      GoRoute(
        path: "/admin/licenses",
        builder: (context, state) => const AdminLicensesScreen(),
      ),
    ],
  );
}
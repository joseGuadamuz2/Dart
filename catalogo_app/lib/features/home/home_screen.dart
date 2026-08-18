import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import 'package:share_plus/share_plus.dart';

import '../../core/api/api_client.dart';
import '../../core/auth/auth_provider.dart';
import '../../core/constants/app_strings.dart';
import '../../core/models/company.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_text_styles.dart';
import '../../shared/widgets/app_dialog.dart';
import '../../shared/widgets/app_empty_state.dart';
import '../../shared/widgets/app_error_view.dart';
import '../../shared/widgets/app_loading.dart';
import '../companies/company_provider.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<CompanyProvider>().load();
    });
  }

  Future<void> _shareCatalog(Company company) async {
    await Share.share(
      AppStrings.shareCatalogText
          .replaceFirst("{name}", company.name)
          .replaceFirst("{url}", ApiClient.catalogUrl(company.id)),
    );
  }

  Future<void> _copyLink(Company company) async {
    final messenger = ScaffoldMessenger.of(context);
    await Clipboard.setData(
        ClipboardData(text: ApiClient.catalogUrl(company.id)));
    messenger
      ..hideCurrentSnackBar()
      ..showSnackBar(const SnackBar(content: Text(AppStrings.linkCopied)));
  }

  Future<void> _deleteCompany(Company company) async {
    final provider = context.read<CompanyProvider>();
    final confirmed = await confirmAction(
      context,
      title: AppStrings.deleteCompanyTitle,
      message: AppStrings.deleteCompanyMessage,
    );
    if (!confirmed) return;
    await provider.delete(company.id);
  }

  Future<void> _onMenuSelected(Company company, String value) async {
    switch (value) {
      case "catalog":
        await context.push("/public-catalog/${company.id}", extra: company.name);
      case "share":
        await _shareCatalog(company);
      case "copy":
        await _copyLink(company);
      case "edit":
        final provider = context.read<CompanyProvider>();
        await context.push("/companies/${company.id}/edit", extra: company);
        if (context.mounted) provider.refresh();
      case "delete":
        await _deleteCompany(company);
    }
  }

  @override
  Widget build(BuildContext context) {
    final user = context.watch<AuthProvider>().user;
    final isAdmin = user?.isAdmin ?? false;
    final provider = context.watch<CompanyProvider>();
    final companies = provider.companies;

    return Scaffold(
      appBar: AppBar(
        title: const Text(AppStrings.appTitle),
        actions: [
          IconButton(
            icon: const Icon(Icons.logout),
            tooltip: AppStrings.logout,
            onPressed: () => context.read<AuthProvider>().logout(),
          ),
        ],
      ),
      body: RefreshIndicator(
        onRefresh: () => context.read<CompanyProvider>().refresh(),
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            if (user != null) _buildGreeting(user.fullName, user.email, user.role),
            const SizedBox(height: 20),
            if (isAdmin) ...[
              _buildAdminSection(context),
              const SizedBox(height: 20),
            ],
            _buildCompaniesSection(provider, companies),
          ],
        ),
      ),
    );
  }

  Widget _buildGreeting(String name, String email, String role) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            AppColors.primaryGradientTop,
            AppColors.primaryGradientBottom,
          ],
        ),
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: AppColors.shadow,
            blurRadius: 16,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      child: Row(
        children: [
          CircleAvatar(
            radius: 28,
            backgroundColor: Colors.white.withValues(alpha: 0.25),
            child: Text(
              name.isNotEmpty ? name[0].toUpperCase() : "?",
              style: const TextStyle(
                fontSize: 22,
                fontWeight: FontWeight.bold,
                color: Colors.white,
              ),
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  AppStrings.greeting.replaceFirst("{name}", name),
                  style: const TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.w700,
                    color: Colors.white,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  email,
                  style: const TextStyle(
                    fontSize: 13,
                    color: Colors.white70,
                  ),
                ),
              ],
            ),
          ),
          if (role.isNotEmpty)
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
              decoration: BoxDecoration(
                color: Colors.white.withValues(alpha: 0.2),
                borderRadius: BorderRadius.circular(20),
              ),
              child: Text(
                role,
                style: const TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                  color: Colors.white,
                ),
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildAdminSection(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(AppStrings.adminSection,
            style: Theme.of(context).textTheme.titleMedium),
        const SizedBox(height: 12),
        Row(
          children: [
            Expanded(
              child: _adminTile(context, Icons.business, AppStrings.adminCompanies,
                  "/admin/companies"),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: _adminTile(context, Icons.group, AppStrings.adminUsers,
                  "/admin/users"),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: _adminTile(context, Icons.verified_user,
                  AppStrings.adminLicenses, "/admin/licenses"),
            ),
          ],
        ),
      ],
    );
  }

  Widget _adminTile(BuildContext context, IconData icon, String title,
      String route) {
    return InkWell(
      borderRadius: BorderRadius.circular(16),
      onTap: () => context.push(route),
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 20, horizontal: 8),
        decoration: BoxDecoration(
          color: AppColors.surface,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: AppColors.border),
        ),
        child: Column(
          children: [
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: AppColors.primaryContainer,
                shape: BoxShape.circle,
              ),
              child: Icon(icon, color: AppColors.primary, size: 22),
            ),
            const SizedBox(height: 10),
            Text(
              title,
              textAlign: TextAlign.center,
              style: const TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w600,
                color: AppColors.textPrimary,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildCompaniesSection(CompanyProvider provider, List<Company> companies) {
    if (provider.isLoading && companies.isEmpty) {
      return const Padding(
        padding: EdgeInsets.symmetric(vertical: 32),
        child: AppLoading(),
      );
    }
    if (companies.isEmpty) {
      if (provider.error != null) {
        return AppErrorView(
          message: provider.error!,
          onRetry: () => context.read<CompanyProvider>().refresh(),
        );
      }
      return const AppEmptyState(
        icon: Icons.store,
        title: AppStrings.noCompanies,
        message: AppStrings.noCompaniesHint,
      );
    }
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(vertical: 8),
          child: Text(AppStrings.sectionCompanies,
              style: Theme.of(context).textTheme.titleMedium),
        ),
        for (final company in companies) ...[
          _buildCompanyCard(context, company),
          const SizedBox(height: 12),
        ],
        _menuTile(
          context,
          AppStrings.manageMyCompanies,
          Icons.manage_accounts,
          "/companies",
        ),
      ],
    );
  }

  Widget _buildCompanyCard(BuildContext context, Company company) {
    return Container(
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.border),
      ),
      child: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(16),
            child: Row(
              children: [
                Container(
                  width: 48,
                  height: 48,
                  decoration: BoxDecoration(
                    color: AppColors.primaryContainer,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: const Icon(Icons.storefront,
                      color: AppColors.primary, size: 24),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(company.name,
                          style: AppTextStyles.heading,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis),
                      const SizedBox(height: 2),
                      Text(
                        "${AppStrings.whatsAppPrefix}${company.whatsappNumber}",
                        style: AppTextStyles.caption,
                      ),
                    ],
                  ),
                ),
                IconButton(
                  icon: const Icon(Icons.share),
                  tooltip: AppStrings.shareCatalog,
                  onPressed: () => _shareCatalog(company),
                ),
                PopupMenuButton<String>(
                  tooltip: "Configuración",
                  onSelected: (value) => _onMenuSelected(company, value),
                  itemBuilder: (context) => const [
                    PopupMenuItem(
                      value: "catalog",
                      child: Text(AppStrings.viewPublicCatalog),
                    ),
                    PopupMenuItem(
                      value: "share",
                      child: Text(AppStrings.shareCatalog),
                    ),
                    PopupMenuItem(
                      value: "copy",
                      child: Text(AppStrings.copyLink),
                    ),
                    PopupMenuItem(
                      value: "edit",
                      child: Text(AppStrings.configureCompany),
                    ),
                    PopupMenuItem(
                      value: "delete",
                      child: Text(AppStrings.delete),
                    ),
                  ],
                ),
              ],
            ),
          ),
          const Divider(height: 1),
          Padding(
            padding: const EdgeInsets.symmetric(vertical: 4),
            child: Row(
              children: [
                Expanded(
                  child: _quickAction(context, Icons.public,
                      AppStrings.viewPublicCatalog,
                      () => context.push(
                            "/public-catalog/${company.id}",
                            extra: company.name,
                          )),
                ),
                Expanded(
                  child: _quickAction(context, Icons.shopping_bag,
                      AppStrings.productsTitle,
                      () => context.push(
                            "/companies/${company.id}/products",
                          )),
                ),
                Expanded(
                  child: _quickAction(context, Icons.category,
                      AppStrings.categoriesTitle,
                      () => context.push(
                            "/companies/${company.id}/categories",
                          )),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _quickAction(
      BuildContext context, IconData icon, String label, VoidCallback onTap) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(10),
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 10),
        child: Column(
          children: [
            Icon(icon, size: 20, color: AppColors.primary),
            const SizedBox(height: 4),
            Text(
              label,
              style: const TextStyle(
                fontSize: 11,
                fontWeight: FontWeight.w500,
                color: AppColors.textSecondary,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _menuTile(BuildContext context, String title, IconData icon,
      String route) {
    return InkWell(
      borderRadius: BorderRadius.circular(16),
      onTap: () async {
        final provider = context.read<CompanyProvider>();
        await context.push(route);
        if (context.mounted) provider.refresh();
      },
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        decoration: BoxDecoration(
          color: AppColors.surface,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: AppColors.border),
        ),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: AppColors.surfaceMuted,
                borderRadius: BorderRadius.circular(10),
              ),
              child: Icon(icon, size: 20, color: AppColors.primary),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Text(title,
                  style: const TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                    color: AppColors.textPrimary,
                  )),
            ),
            const Icon(Icons.chevron_right, color: AppColors.textMuted),
          ],
        ),
      ),
    );
  }
}
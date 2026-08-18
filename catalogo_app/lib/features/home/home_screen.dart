import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import 'package:share_plus/share_plus.dart';

import '../../core/api/api_client.dart';
import '../../core/auth/auth_provider.dart';
import '../../core/models/company.dart';
import '../companies/company_service.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  late Future<List<Company>> _companiesFuture;

  @override
  void initState() {
    super.initState();
    _companiesFuture = CompanyService(ApiClient()).findMyCompanies();
  }

  void _reload() {
    setState(() {
      _companiesFuture = CompanyService(ApiClient()).findMyCompanies();
    });
  }

  Future<void> _shareCatalog(Company company) async {
    await Share.share(
      "Mira el catálogo de ${company.name}: ${ApiClient.catalogUrl(company.id)}",
    );
  }

  Future<void> _copyLink(Company company) async {
    await Clipboard.setData(
      ClipboardData(text: ApiClient.catalogUrl(company.id)),
    );
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Enlace copiado")),
      );
    }
  }

  Future<void> _onMenuSelected(Company company, String value) async {
    if (value == "catalog") {
      await context.push("/public-catalog/${company.id}", extra: company.name);
    } else if (value == "share") {
      await _shareCatalog(company);
    } else if (value == "copy") {
      await _copyLink(company);
    } else if (value == "edit") {
      await context.push("/companies/${company.id}/edit", extra: company);
      _reload();
    } else if (value == "delete") {
      await CompanyService(ApiClient()).delete(company.id);
      _reload();
    }
  }

  @override
  Widget build(BuildContext context) {
    final user = context.watch<AuthProvider>().user;
    final isAdmin = user?.isAdmin ?? false;

    return Scaffold(
      appBar: AppBar(
        title: const Text("Catálogo SaaS"),
        actions: [
          IconButton(
            icon: const Icon(Icons.logout),
            tooltip: "Cerrar sesión",
            onPressed: () => context.read<AuthProvider>().logout(),
          ),
        ],
      ),
      body: RefreshIndicator(
        onRefresh: () async {
          _reload();
          await _companiesFuture;
        },
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            if (user != null)
              Card(
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        "Hola, ${user.fullName}",
                        style: const TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        "${user.email} · ${user.role}",
                        style: const TextStyle(color: Colors.grey),
                      ),
                    ],
                  ),
                ),
              ),
            const SizedBox(height: 16),
            if (isAdmin) _menuTile(context, "Empresas", Icons.business,
                "/admin/companies"),
            if (isAdmin)
              _menuTile(context, "Usuarios", Icons.group, "/admin/users"),
            if (isAdmin)
              _menuTile(context, "Licencias", Icons.verified_user,
                  "/admin/licenses"),
            if (isAdmin) const SizedBox(height: 16),
            FutureBuilder<List<Company>>(
              future: _companiesFuture,
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Center(child: CircularProgressIndicator());
                }
                if (snapshot.hasError) {
                  return Center(child: Text("Error: ${snapshot.error}"));
                }
                final companies = snapshot.data ?? [];
                if (companies.isEmpty) {
                  return const Center(child: Text("No tienes empresas creadas"));
                }
                return Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Padding(
                      padding: EdgeInsets.symmetric(vertical: 8),
                      child: Text(
                        "Empresa",
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                    for (final company in companies)
                      Card(
                        clipBehavior: Clip.antiAlias,
                        child: ExpansionTile(
                          controlAffinity: ListTileControlAffinity.leading,
                          leading: const Icon(Icons.expand_more),
                          title: Row(
                            children: [
                              const Icon(Icons.store),
                              const SizedBox(width: 8),
                              Expanded(child: Text(company.name)),
                            ],
                          ),
                          subtitle: Text(
                            "WhatsApp: ${company.whatsappNumber}",
                          ),
                          trailing: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              IconButton(
                                icon: const Icon(Icons.share),
                                tooltip: "Compartir catálogo",
                                onPressed: () => _shareCatalog(company),
                              ),
                              PopupMenuButton<String>(
                                tooltip: "Configuración",
                                onSelected: (value) =>
                                    _onMenuSelected(company, value),
                                itemBuilder: (context) => const [
                                  PopupMenuItem(
                                    value: "catalog",
                                    child: Text("Ver catálogo público"),
                                  ),
                                  PopupMenuItem(
                                    value: "share",
                                    child: Text("Compartir catálogo"),
                                  ),
                                  PopupMenuItem(
                                    value: "copy",
                                    child: Text("Copiar enlace"),
                                  ),
                                  PopupMenuItem(
                                    value: "edit",
                                    child: Text("Configurar empresa"),
                                  ),
                                  PopupMenuItem(
                                    value: "delete",
                                    child: Text("Eliminar"),
                                  ),
                                ],
                              ),
                            ],
                          ),
                          childrenPadding: const EdgeInsets.only(bottom: 8),
                          children: [
                            ListTile(
                              leading: const Icon(Icons.public),
                              title: const Text("Ver catálogo público"),
                              trailing: const Icon(Icons.chevron_right),
                              onTap: () => context.push(
                                "/public-catalog/${company.id}",
                                extra: company.name,
                              ),
                            ),
                            ListTile(
                              leading: const Icon(Icons.shopping_bag),
                              title: const Text("Productos"),
                              trailing: const Icon(Icons.chevron_right),
                              onTap: () => context.push(
                                "/companies/${company.id}/products",
                              ),
                            ),
                            ListTile(
                              leading: const Icon(Icons.category),
                              title: const Text("Categorías"),
                              trailing: const Icon(Icons.chevron_right),
                              onTap: () => context.push(
                                "/companies/${company.id}/categories",
                              ),
                            ),
                          ],
                        ),
                      ),
                    const SizedBox(height: 8),
                    _menuTile(
                      context,
                      "Gestionar mis empresas",
                      Icons.manage_accounts,
                      "/companies",
                    ),
                  ],
                );
              },
            ),
          ],
        ),
      ),
    );
  }

  Widget _menuTile(BuildContext context, String title, IconData icon,
      String route) {
    return Card(
      child: ListTile(
        leading: Icon(icon),
        title: Text(title),
        trailing: const Icon(Icons.chevron_right),
        onTap: () async {
          await context.push(route);
          _reload();
        },
      ),
    );
  }
}

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import 'package:share_plus/share_plus.dart';

import '../../core/auth/auth_provider.dart';
import '../../core/api/api_client.dart';
import '../../core/models/company.dart';
import 'company_service.dart';

class CompanyListScreen extends StatefulWidget {
  const CompanyListScreen({super.key});

  @override
  State<CompanyListScreen> createState() => _CompanyListScreenState();
}

class _CompanyListScreenState extends State<CompanyListScreen> {
  late Future<List<Company>> _future;

  @override
  void initState() {
    super.initState();
    _future = CompanyService(ApiClient()).findMyCompanies();
  }

  void _reload() {
    setState(() {
      _future = CompanyService(ApiClient()).findMyCompanies();
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Mis empresas"),
        actions: [
          IconButton(icon: const Icon(Icons.logout), onPressed: () {
            context.read<AuthProvider>().logout();
          }),
        ],
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () async {
          await context.push("/companies/new");
          _reload();
        },
        child: const Icon(Icons.add),
      ),
      body: FutureBuilder<List<Company>>(
        future: _future,
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
          return ListView.separated(
            itemCount: companies.length,
            separatorBuilder: (_, _) => const Divider(height: 1),
            itemBuilder: (context, index) {
              final c = companies[index];
              return ListTile(
                leading: const Icon(Icons.store),
                title: Text(c.name),
                subtitle: Text("WhatsApp: ${c.whatsappNumber}"),
                isThreeLine: false,
                trailing: PopupMenuButton<String>(
                  onSelected: (value) async {
                    if (value == "edit") {
                      await context.push("/companies/${c.id}/edit", extra: c);
                      _reload();
                    } else if (value == "catalog") {
                      await context.push(
                        "/public-catalog/${c.id}",
                        extra: c.name,
                      );
                    } else if (value == "share") {
                      await Share.share(
                        "Mira el catálogo de ${c.name}: ${ApiClient.catalogUrl(c.id)}",
                      );
                    } else if (value == "copy") {
                      await Clipboard.setData(
                        ClipboardData(text: ApiClient.catalogUrl(c.id)),
                      );
                      if (context.mounted) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(content: Text("Enlace copiado")),
                        );
                      }
                    } else if (value == "delete") {
                      await CompanyService(ApiClient()).delete(c.id);
                      _reload();
                    }
                  },
                  itemBuilder: (context) => [
                    const PopupMenuItem(
                      value: "edit",
                      child: Text("Editar"),
                    ),
                    const PopupMenuItem(
                      value: "catalog",
                      child: Text("Ver catálogo"),
                    ),
                    const PopupMenuItem(
                      value: "share",
                      child: Text("Compartir catálogo"),
                    ),
                    const PopupMenuItem(
                      value: "copy",
                      child: Text("Copiar enlace"),
                    ),
                    const PopupMenuItem(
                      value: "delete",
                      child: Text("Eliminar"),
                    ),
                  ],
                ),
              );
            },
          );
        },
      ),
    );
  }
}
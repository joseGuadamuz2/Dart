import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../core/api/api_client.dart';
import '../../core/auth/auth_provider.dart';
import 'admin_service.dart';

class AdminLicensesScreen extends StatefulWidget {
  const AdminLicensesScreen({super.key});

  @override
  State<AdminLicensesScreen> createState() => _AdminLicensesScreenState();
}

class _AdminLicensesScreenState extends State<AdminLicensesScreen> {
  late Future<List<Map<String, dynamic>>> _future;

  @override
  void initState() {
    super.initState();
    _future = AdminService(ApiClient()).listLicenses();
  }

  void _reload() {
    setState(() {
      _future = AdminService(ApiClient()).listLicenses();
    });
  }

  Future<void> _createLicense() async {
    final nameCtrl = TextEditingController();
    final companiesCtrl = TextEditingController();
    final productsCtrl = TextEditingController();
    final result = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text("Crear licencia"),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: nameCtrl,
              decoration: const InputDecoration(labelText: "Nombre"),
            ),
            TextField(
              controller: companiesCtrl,
              decoration: const InputDecoration(labelText: "Máx. empresas"),
              keyboardType: TextInputType.number,
            ),
            TextField(
              controller: productsCtrl,
              decoration: const InputDecoration(labelText: "Máx. productos"),
              keyboardType: TextInputType.number,
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext),
            child: const Text("Cancelar"),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(dialogContext, true),
            child: const Text("Crear"),
          ),
        ],
      ),
    );
    if (result == true) {
      await AdminService(ApiClient()).createLicense({
        "name": nameCtrl.text.trim(),
        "maxCompanies": int.tryParse(companiesCtrl.text.trim()) ?? 1,
        "maxProducts": int.tryParse(productsCtrl.text.trim()) ?? 1,
      });
      _reload();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Licencias"),
        actions: [
          IconButton(
            icon: const Icon(Icons.logout),
            onPressed: () => context.read<AuthProvider>().logout(),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: _createLicense,
        child: const Icon(Icons.add),
      ),
      body: FutureBuilder<List<Map<String, dynamic>>>(
        future: _future,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }
          if (snapshot.hasError) {
            return Center(child: Text("Error: ${snapshot.error}"));
          }
          final licenses = snapshot.data ?? [];
          return ListView.separated(
            itemCount: licenses.length,
            separatorBuilder: (_, _) => const Divider(height: 1),
            itemBuilder: (context, index) {
              final l = licenses[index];
              return ListTile(
                leading: const Icon(Icons.verified_user),
                title: Text(l["name"] ?? ""),
                subtitle: Text(
                  "Empresas: ${l["maxCompanies"]} · Productos: ${l["maxProducts"]}",
                ),
              );
            },
          );
        },
      ),
    );
  }
}
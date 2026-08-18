import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../core/api/api_client.dart';
import '../../core/auth/auth_provider.dart';
import 'admin_service.dart';

class AdminUsersScreen extends StatefulWidget {
  const AdminUsersScreen({super.key});

  @override
  State<AdminUsersScreen> createState() => _AdminUsersScreenState();
}

class _AdminUsersScreenState extends State<AdminUsersScreen> {
  late Future<List<Map<String, dynamic>>> _future;

  @override
  void initState() {
    super.initState();
    _future = AdminService(ApiClient()).listUsers();
  }

  void _reload() {
    setState(() {
      _future = AdminService(ApiClient()).listUsers();
    });
  }

  Future<void> _createUser() async {
    final result = await showDialog<UserFormData>(
      context: context,
      builder: (_) => const _CreateUserDialog(),
    );
    if (result != null) {
      await AdminService(ApiClient()).createUser(result.toJson());
      _reload();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Usuarios"),
        actions: [
          IconButton(
            icon: const Icon(Icons.logout),
            onPressed: () => context.read<AuthProvider>().logout(),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: _createUser,
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
          final users = snapshot.data ?? [];
          return ListView.separated(
            itemCount: users.length,
            separatorBuilder: (_, _) => const Divider(height: 1),
            itemBuilder: (context, index) {
              final u = users[index];
              return ListTile(
                leading: const Icon(Icons.person),
                title: Text(
                  "${u["firstName"]} ${u["lastName"]}",
                ),
                subtitle: Text("${u["email"]} · ${u["role"]}"),
              );
            },
          );
        },
      ),
    );
  }
}

class UserFormData {
  final String email;
  final String password;
  final String firstName;
  final String lastName;
  final String birthDate;
  final String role;
  final String tenantId;

  UserFormData({
    required this.email,
    required this.password,
    required this.firstName,
    required this.lastName,
    required this.birthDate,
    required this.role,
    required this.tenantId,
  });

  Map<String, dynamic> toJson() => {
        "email": email,
        "password": password,
        "firstName": firstName,
        "lastName": lastName,
        "birthDate": birthDate,
        "role": role,
        "tenantId": tenantId,
      };
}

class _CreateUserDialog extends StatefulWidget {
  const _CreateUserDialog();

  @override
  State<_CreateUserDialog> createState() => _CreateUserDialogState();
}

class _CreateUserDialogState extends State<_CreateUserDialog> {
  final _formKey = GlobalKey<FormState>();
  final _email = TextEditingController();
  final _password = TextEditingController();
  final _firstName = TextEditingController();
  final _lastName = TextEditingController();
  final _tenantId = TextEditingController();
  String _role = "OWNER";

  @override
  void dispose() {
    _email.dispose();
    _password.dispose();
    _firstName.dispose();
    _lastName.dispose();
    _tenantId.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text("Crear usuario"),
      content: SingleChildScrollView(
        child: Form(
          key: _formKey,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextFormField(
                controller: _email,
                decoration: const InputDecoration(labelText: "Email"),
                validator: (v) =>
                    v == null || v.trim().isEmpty ? "Requerido" : null,
              ),
              TextFormField(
                controller: _password,
                decoration: const InputDecoration(labelText: "Contraseña"),
                obscureText: true,
              ),
              TextFormField(
                controller: _firstName,
                decoration: const InputDecoration(labelText: "Nombre"),
              ),
              TextFormField(
                controller: _lastName,
                decoration: const InputDecoration(labelText: "Apellido"),
              ),
              TextFormField(
                controller: _tenantId,
                decoration: const InputDecoration(labelText: "Tenant ID"),
              ),
              DropdownButtonFormField<String>(
                initialValue: _role,
                decoration: const InputDecoration(labelText: "Rol"),
                items: const [
                  DropdownMenuItem(value: "OWNER", child: Text("OWNER")),
                  DropdownMenuItem(value: "ADMIN", child: Text("ADMIN")),
                ],
                onChanged: (v) => setState(() => _role = v!),
              ),
            ],
          ),
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text("Cancelar"),
        ),
        ElevatedButton(
          onPressed: () {
            if (!_formKey.currentState!.validate()) return;
            Navigator.pop(
              context,
              UserFormData(
                email: _email.text.trim(),
                password: _password.text.trim(),
                firstName: _firstName.text.trim(),
                lastName: _lastName.text.trim(),
                birthDate: DateTime.now().toIso8601String(),
                role: _role,
                tenantId: _tenantId.text.trim(),
              ),
            );
          },
          child: const Text("Crear"),
        ),
      ],
    );
  }
}
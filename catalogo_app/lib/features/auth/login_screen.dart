import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../core/auth/auth_provider.dart';
import '../../core/constants/app_strings.dart';
import '../../core/theme/app_text_styles.dart';
import '../../shared/widgets/app_button.dart';
import '../../shared/widgets/app_text_field.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  bool _isLoading = false;

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  Future<void> _handleLogin(AuthProvider authProvider) async {
    setState(() => _isLoading = true);
    await authProvider.login(
      _emailController.text.trim(),
      _passwordController.text.trim(),
    );
    if (mounted) setState(() => _isLoading = false);
  }

  @override
  Widget build(BuildContext context) {
    final authProvider = context.watch<AuthProvider>();

    return Scaffold(
      body: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 400),
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Text(
                  AppStrings.loginTitle,
                  style: AppTextStyles.title,
                ),
                const SizedBox(height: 32),
                AppTextField(
                  controller: _emailController,
                  label: AppStrings.emailLabel,
                ),
                const SizedBox(height: 16),
                AppTextField(
                  controller: _passwordController,
                  label: AppStrings.passwordLabel,
                  obscureText: true,
                ),
                const SizedBox(height: 24),
                if (authProvider.error != null)
                  Padding(
                    padding: const EdgeInsets.only(bottom: 16),
                    child: Text(
                      authProvider.error!,
                      style: AppTextStyles.error,
                    ),
                  ),
                AppButton(
                  label: AppStrings.signIn,
                  isLoading: _isLoading,
                  onPressed: () => _handleLogin(authProvider),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
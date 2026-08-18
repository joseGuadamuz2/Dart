import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../core/auth/auth_provider.dart';
import '../../core/constants/app_constants.dart';
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
  bool _rememberUser = false;

  @override
  void initState() {
    super.initState();
    _loadRememberedEmail();
  }

  Future<void> _loadRememberedEmail() async {
    final prefs = await SharedPreferences.getInstance();
    final email = prefs.getString(CacheKeys.rememberedEmail);
    if (!mounted || email == null || email.isEmpty) return;
    setState(() {
      _emailController.text = email;
      _rememberUser = true;
    });
  }

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  Future<void> _handleLogin(AuthProvider authProvider) async {
    final email = _emailController.text.trim();
    final prefs = await SharedPreferences.getInstance();
    if (_rememberUser) {
      await prefs.setString(CacheKeys.rememberedEmail, email);
    } else {
      await prefs.remove(CacheKeys.rememberedEmail);
    }
    setState(() => _isLoading = true);
    await authProvider.login(
      email,
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
                const SizedBox(height: 8),
                Align(
                  alignment: Alignment.centerLeft,
                  child: CheckboxListTile(
                    value: _rememberUser,
                    onChanged: (value) =>
                        setState(() => _rememberUser = value ?? false),
                    title: const Text(AppStrings.rememberUser),
                    dense: true,
                    controlAffinity: ListTileControlAffinity.leading,
                    contentPadding: EdgeInsets.zero,
                  ),
                ),
                const SizedBox(height: 16),
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
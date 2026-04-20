import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../controllers/auth_controller.dart';
import 'register_screen.dart';

/// Login screen shown when no active session exists.
class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final _loginController = TextEditingController();
  final _passwordController = TextEditingController();
  final _formKey = GlobalKey<FormState>();
  final _isLoading = false.obs;

  @override
  Widget build(BuildContext context) {
    final authController = Get.find<AuthController>();
    return Scaffold(
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(20),
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 420),
              child: Form(
                key: _formKey,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    ClipRRect(
                      borderRadius: BorderRadius.circular(16),
                      child: Image.asset(
                        'assets/icons/TradeHub-logo.png',
                        height: 120,
                        fit: BoxFit.cover,
                      ),
                    ),
                    const SizedBox(height: 16),
                    const Text(
                      'TradeHub',
                      textAlign: TextAlign.center,
                      style: TextStyle(fontSize: 30, fontWeight: FontWeight.bold),
                    ),
                    const SizedBox(height: 6),
                    const Text(
                      'Sign in to your account',
                      textAlign: TextAlign.center,
                      style: TextStyle(color: Colors.black54),
                    ),
                    const SizedBox(height: 20),
                    TextFormField(
                      controller: _loginController,
                      decoration: const InputDecoration(
                        labelText: 'Username or email',
                      ),
                      validator: (value) {
                        if (value == null || value.trim().isEmpty) {
                          return 'Login is required';
                        }
                        return null;
                      },
                    ),
                    const SizedBox(height: 12),
                    TextFormField(
                      controller: _passwordController,
                      obscureText: true,
                      decoration: const InputDecoration(labelText: 'Password'),
                      validator: (value) {
                        if (value == null || value.length < 4) {
                          return 'Password must be at least 4 characters';
                        }
                        return null;
                      },
                    ),
                    const SizedBox(height: 16),
                    Obx(
                      () => FilledButton(
                        onPressed: _isLoading.value
                            ? null
                            : () async {
                                if (!_formKey.currentState!.validate()) return;
                                _isLoading.value = true;
                                final ok = await authController.login(
                                  login: _loginController.text,
                                  password: _passwordController.text,
                                );
                                _isLoading.value = false;
                                if (!ok) {
                                  Get.snackbar(
                                    'Login Error',
                                    'Username/email or password is incorrect',
                                  );
                                  return;
                                }
                              },
                        child: Text(_isLoading.value ? 'Signing in...' : 'Sign In'),
                      ),
                    ),
                    const SizedBox(height: 10),
                    TextButton(
                      onPressed: () => Get.to(() => const RegisterScreen()),
                      child: const Text('No account yet? Create one'),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

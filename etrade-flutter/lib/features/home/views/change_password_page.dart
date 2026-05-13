import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../../../theme/tradehub_theme.dart';
import '../controllers/home_controller.dart';

class ChangePasswordPage extends StatefulWidget {
  const ChangePasswordPage({required this.controller, super.key});

  final HomeController controller;

  @override
  State<ChangePasswordPage> createState() => _ChangePasswordPageState();
}

class _ChangePasswordPageState extends State<ChangePasswordPage> {
  final _oldController = TextEditingController();
  final _newController = TextEditingController();
  final _confirmController = TextEditingController();
  bool _busy = false;

  @override
  void dispose() {
    _oldController.dispose();
    _newController.dispose();
    _confirmController.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (_busy) return;
    setState(() => _busy = true);
    final error = await widget.controller.changePassword(
      oldPassword: _oldController.text.trim(),
      newPassword: _newController.text.trim(),
      confirmPassword: _confirmController.text.trim(),
    );
    if (!mounted) return;
    setState(() => _busy = false);
    if (error == null) {
      Get.snackbar('Password', 'Your password has been updated.');
      _oldController.clear();
      _newController.clear();
      _confirmController.clear();
      return;
    }
    Get.snackbar('Password', error);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: TradeHubColors.bg,
      appBar: AppBar(
        title: const Text('Change Password'),
        backgroundColor: TradeHubColors.bg,
        foregroundColor: TradeHubColors.textPrimary,
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          const Text(
            'Enter your current password, then set and confirm your new password.',
            style: TextStyle(color: TradeHubColors.textMuted),
          ),
          const SizedBox(height: 14),
          TextField(
            controller: _oldController,
            obscureText: true,
            decoration: const InputDecoration(labelText: 'Current password'),
          ),
          const SizedBox(height: 10),
          TextField(
            controller: _newController,
            obscureText: true,
            decoration: const InputDecoration(labelText: 'New password'),
          ),
          const SizedBox(height: 10),
          TextField(
            controller: _confirmController,
            obscureText: true,
            decoration: const InputDecoration(labelText: 'Confirm new password'),
          ),
          const SizedBox(height: 16),
          SizedBox(
            height: 44,
            child: FilledButton(
              onPressed: _busy ? null : _submit,
              child: Text(_busy ? 'Updating...' : 'Change password'),
            ),
          ),
        ],
      ),
    );
  }
}


import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:get/get.dart';

import '../controllers/auth_controller.dart';

/// Register screen for creating first local account.
class RegisterScreen extends StatefulWidget {
  const RegisterScreen({super.key});

  @override
  State<RegisterScreen> createState() => _RegisterScreenState();
}

class _RegisterScreenState extends State<RegisterScreen> {
  final _usernameController = TextEditingController();
  final _nameController = TextEditingController();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _phoneController = TextEditingController();
  final _formKey = GlobalKey<FormState>();
  final _isLoading = false.obs;
  String? _selectedGender;
  static const _selectedPhoneCode = '+90';
  int? _selectedBirthYear;
  int? _selectedBirthMonth;
  int? _selectedBirthDay;

  @override
  Widget build(BuildContext context) {
    final authController = Get.find<AuthController>();
    InputDecoration modernInput({
      required String label,
      IconData? icon,
      Widget? customPrefix,
    }) {
      return InputDecoration(
        labelText: label,
        prefixIcon: customPrefix ?? (icon == null ? null : Icon(icon)),
        filled: true,
        fillColor: Colors.grey.shade50,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: const BorderSide(color: Colors.black12),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: const BorderSide(color: Colors.black12),
        ),
      );
    }

    return Scaffold(
      appBar: AppBar(title: const Text('Create Account')),
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
                        height: 180,
                        fit: BoxFit.cover,
                      ),
                    ),
                    const SizedBox(height: 16),
                    TextFormField(
                      controller: _usernameController,
                      decoration: modernInput(
                        label: 'Username',
                        icon: Icons.person_outline_rounded,
                      ),
                      validator: (value) {
                        if (value == null || value.trim().isEmpty) {
                          return 'Username is required';
                        }
                        return null;
                      },
                    ),
                    const SizedBox(height: 12),
                    TextFormField(
                      controller: _nameController,
                      decoration: modernInput(
                        label: 'Full name',
                        icon: Icons.badge_outlined,
                      ),
                      validator: (value) {
                        if (value == null || value.trim().isEmpty) {
                          return 'Full name is required';
                        }
                        return null;
                      },
                    ),
                    const SizedBox(height: 12),
                    TextFormField(
                      controller: _emailController,
                      decoration: modernInput(
                        label: 'Email',
                        icon: Icons.alternate_email_rounded,
                      ),
                      validator: (value) {
                        if (value == null || value.trim().isEmpty) {
                          return 'Email is required';
                        }
                        return null;
                      },
                    ),
                    const SizedBox(height: 12),
                    TextFormField(
                      controller: _passwordController,
                      obscureText: true,
                      decoration: modernInput(
                        label: 'Password',
                        icon: Icons.lock_outline_rounded,
                      ),
                      validator: (value) {
                        if (value == null || value.length < 4) {
                          return 'Password must be at least 4 characters';
                        }
                        return null;
                      },
                    ),
                    const SizedBox(height: 12),
                    DropdownButtonFormField<String>(
                      initialValue: _selectedGender,
                      decoration: modernInput(
                        label: 'Gender',
                        icon: Icons.wc_outlined,
                      ),
                      items: const [
                        DropdownMenuItem(value: 'Male', child: Text('Male')),
                        DropdownMenuItem(value: 'Female', child: Text('Female')),
                        DropdownMenuItem(value: 'Other', child: Text('Other')),
                      ],
                      onChanged: (value) {
                        setState(() {
                          _selectedGender = value;
                        });
                      },
                      validator: (value) {
                        if (value == null || value.isEmpty) {
                          return 'Gender is required';
                        }
                        return null;
                      },
                    ),
                    const SizedBox(height: 12),
                    const Text('Birth Date'),
                    const SizedBox(height: 8),
                    Row(
                      children: [
                        Expanded(
                          child: DropdownButtonFormField<int>(
                            initialValue: _selectedBirthYear,
                            decoration: modernInput(
                              label: 'Year',
                              icon: Icons.calendar_today_outlined,
                            ),
                            items: List.generate(80, (index) {
                              final year = DateTime.now().year - index;
                              return DropdownMenuItem(
                                value: year,
                                child: Text(year.toString()),
                              );
                            }),
                            onChanged: (value) {
                              setState(() {
                                _selectedBirthYear = value;
                              });
                            },
                            validator: (value) =>
                                value == null ? 'Year' : null,
                          ),
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: DropdownButtonFormField<int>(
                            initialValue: _selectedBirthMonth,
                            decoration: modernInput(
                              label: 'Month',
                              icon: Icons.event_note_outlined,
                            ),
                            items: List.generate(12, (index) {
                              final month = index + 1;
                              return DropdownMenuItem(
                                value: month,
                                child: Text(month.toString().padLeft(2, '0')),
                              );
                            }),
                            onChanged: (value) {
                              setState(() {
                                _selectedBirthMonth = value;
                              });
                            },
                            validator: (value) =>
                                value == null ? 'Month' : null,
                          ),
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: DropdownButtonFormField<int>(
                            initialValue: _selectedBirthDay,
                            decoration: modernInput(
                              label: 'Day',
                              icon: Icons.today_outlined,
                            ),
                            items: List.generate(31, (index) {
                              final day = index + 1;
                              return DropdownMenuItem(
                                value: day,
                                child: Text(day.toString().padLeft(2, '0')),
                              );
                            }),
                            onChanged: (value) {
                              setState(() {
                                _selectedBirthDay = value;
                              });
                            },
                            validator: (value) =>
                                value == null ? 'Day' : null,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    TextFormField(
                      controller: _phoneController,
                      keyboardType: TextInputType.phone,
                      inputFormatters: [
                        FilteringTextInputFormatter.digitsOnly,
                        LengthLimitingTextInputFormatter(10),
                      ],
                      decoration: InputDecoration(
                        labelText: 'Phone Number (TR)',
                        filled: true,
                        fillColor: Colors.grey.shade50,
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(14),
                          borderSide: const BorderSide(color: Colors.black12),
                        ),
                        enabledBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(14),
                          borderSide: const BorderSide(color: Colors.black12),
                        ),
                        prefixIcon: const Padding(
                          padding: EdgeInsets.symmetric(horizontal: 12),
                          child: Center(
                            widthFactor: 1,
                            child: Text(
                              '🇹🇷 +90',
                              style: TextStyle(fontSize: 14),
                            ),
                          ),
                        ),
                      ),
                      validator: (value) {
                        if (value == null || value.trim().isEmpty) {
                          return 'Phone number is required';
                        }
                        if (value.trim().length != 10) {
                          return 'Enter 10 digits (5XXXXXXXXX)';
                        }
                        return null;
                      },
                    ),
                    const SizedBox(height: 16),
                    Obx(
                      () => FilledButton.icon(
                        onPressed: _isLoading.value
                            ? null
                            : () async {
                                if (!_formKey.currentState!.validate()) return;
                                final birthYear =
                                    _selectedBirthYear?.toString() ?? '';
                                final birthMonth = (_selectedBirthMonth ?? 0)
                                    .toString()
                                    .padLeft(2, '0');
                                final birthDay = (_selectedBirthDay ?? 0)
                                    .toString()
                                    .padLeft(2, '0');
                                _isLoading.value = true;
                                final ok = await authController.register(
                                  username: _usernameController.text,
                                  name: _nameController.text,
                                  email: _emailController.text,
                                  password: _passwordController.text,
                                  gender: _selectedGender ?? '',
                                  birthdate: '$birthYear-$birthMonth-$birthDay',
                                  phone:
                                      '$_selectedPhoneCode${_phoneController.text.trim()}',
                                );
                                _isLoading.value = false;
                                if (!ok) {
                                  Get.snackbar(
                                    'Registration Error',
                                    'Registration failed. Please check your info.',
                                  );
                                  return;
                                }
                                Get.back();
                              },
                        style: FilledButton.styleFrom(
                          minimumSize: const Size.fromHeight(50),
                          backgroundColor: const Color(0xFF4F46E5),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(14),
                          ),
                        ),
                        icon: const Icon(Icons.person_add_alt_1_rounded),
                        label: Text(_isLoading.value ? 'Creating...' : 'Create Account'),
                      ),
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

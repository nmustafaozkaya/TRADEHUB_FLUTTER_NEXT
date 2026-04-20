import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../controllers/auth_controller.dart';

class _CountryCodeOption {
  const _CountryCodeOption({
    required this.flag,
    required this.code,
    required this.country,
  });

  final String flag;
  final String code;
  final String country;
}

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
  String _selectedPhoneCode = '+90';
  int? _selectedBirthYear;
  int? _selectedBirthMonth;
  int? _selectedBirthDay;

  static const _phoneOptions = <_CountryCodeOption>[
    _CountryCodeOption(flag: '🇹🇷', code: '+90', country: 'Turkiye'),
    _CountryCodeOption(flag: '🇺🇸', code: '+1', country: 'United States'),
    _CountryCodeOption(flag: '🇬🇧', code: '+44', country: 'United Kingdom'),
    _CountryCodeOption(flag: '🇩🇪', code: '+49', country: 'Germany'),
    _CountryCodeOption(flag: '🇫🇷', code: '+33', country: 'France'),
    _CountryCodeOption(flag: '🇮🇹', code: '+39', country: 'Italy'),
    _CountryCodeOption(flag: '🇪🇸', code: '+34', country: 'Spain'),
    _CountryCodeOption(flag: '🇳🇱', code: '+31', country: 'Netherlands'),
    _CountryCodeOption(flag: '🇸🇦', code: '+966', country: 'Saudi Arabia'),
    _CountryCodeOption(flag: '🇦🇪', code: '+971', country: 'UAE'),
  ];

  @override
  Widget build(BuildContext context) {
    final authController = Get.find<AuthController>();

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
                        height: 120,
                        fit: BoxFit.cover,
                      ),
                    ),
                    const SizedBox(height: 16),
                    TextFormField(
                      controller: _usernameController,
                      decoration: const InputDecoration(labelText: 'Username'),
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
                      decoration: const InputDecoration(labelText: 'Full name'),
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
                      decoration: const InputDecoration(labelText: 'Email'),
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
                      decoration: const InputDecoration(labelText: 'Password'),
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
                      decoration: const InputDecoration(labelText: 'Gender'),
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
                            decoration: const InputDecoration(labelText: 'Year'),
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
                            decoration: const InputDecoration(labelText: 'Month'),
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
                            decoration: const InputDecoration(labelText: 'Day'),
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
                      decoration: InputDecoration(
                        labelText: 'Phone Number',
                        prefixIcon: Container(
                          margin: const EdgeInsets.only(left: 8, right: 8),
                          width: 155,
                          child: DropdownButtonFormField<String>(
                            isExpanded: true,
                            initialValue: _selectedPhoneCode,
                            decoration: const InputDecoration(
                              border: InputBorder.none,
                              contentPadding: EdgeInsets.symmetric(horizontal: 8),
                            ),
                            dropdownColor: Colors.white,
                            style: const TextStyle(
                              color: Colors.black87,
                              fontSize: 13,
                            ),
                            items: _phoneOptions
                                .map(
                                  (item) => DropdownMenuItem(
                                    value: item.code,
                                    child: Text(
                                      '${item.flag} ${item.code}',
                                      overflow: TextOverflow.ellipsis,
                                    ),
                                  ),
                                )
                                .toList(),
                            onChanged: (value) {
                              if (value == null) return;
                              setState(() {
                                _selectedPhoneCode = value;
                              });
                            },
                          ),
                        ),
                      ),
                      validator: (value) {
                        if (value == null || value.trim().isEmpty) {
                          return 'Phone number is required';
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
                        child: Text(_isLoading.value ? 'Creating...' : 'Create Account'),
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

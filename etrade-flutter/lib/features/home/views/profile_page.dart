import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../../auth/controllers/auth_controller.dart';
import '../../../theme/tradehub_theme.dart';
import '../controllers/home_controller.dart';

/// Profile form: loads from [HomeController.profile] and auth fallbacks, saves via [HomeController.saveProfile].
/// Gender is chosen from a list; birthdate uses the system date picker (stored as yyyy-MM-dd).
class ProfilePage extends StatefulWidget {
  const ProfilePage({required this.controller, super.key});

  final HomeController controller;

  @override
  State<ProfilePage> createState() => _ProfilePageState();
}

class _ProfilePageState extends State<ProfilePage> {
  static const _genders = ['Male', 'Female', 'Other'];

  late final TextEditingController _nameController;
  late final TextEditingController _emailController;
  late final TextEditingController _phoneController;
  late String _gender;
  DateTime? _birthDate;

  @override
  void initState() {
    super.initState();
    final auth = Get.find<AuthController>();
    final p = widget.controller.profile.value;
    _nameController = TextEditingController(
      text: p.fullName.isNotEmpty ? p.fullName : auth.userName.value,
    );
    _emailController = TextEditingController(
      text: p.email.isNotEmpty ? p.email : auth.userEmail.value,
    );
    _phoneController = TextEditingController(
      text: p.phone.isNotEmpty ? p.phone : auth.userPhone.value,
    );
    _gender = _normalizeGender(
      p.gender.isNotEmpty ? p.gender : auth.userGender.value,
    );
    _birthDate = _parseBirthdate(
      p.birthdate.isNotEmpty ? p.birthdate : auth.userBirthdate.value,
    );
  }

  @override
  void dispose() {
    _nameController.dispose();
    _emailController.dispose();
    _phoneController.dispose();
    super.dispose();
  }

  String _normalizeGender(String raw) {
    final t = raw.trim().toLowerCase();
    if (t == 'male' || t == 'm' || t == 'erkek') return 'Male';
    if (t == 'female' || t == 'f' || t == 'kadın' || t == 'kadin') {
      return 'Female';
    }
    if (t == 'other' || t == 'o' || t == 'diğer' || t == 'diger') {
      return 'Other';
    }
    if (_genders.contains(raw.trim())) return raw.trim();
    return 'Other';
  }

  DateTime? _parseBirthdate(String raw) {
    final t = raw.trim();
    if (t.isEmpty) return null;
    try {
      return DateTime.parse(t.split(RegExp(r'[T\s]')).first);
    } catch (_) {
      final parts = t.split(RegExp(r'[-/.]'));
      if (parts.length == 3) {
        final y = int.tryParse(parts[0]);
        final mo = int.tryParse(parts[1]);
        final d = int.tryParse(parts[2]);
        if (y != null && mo != null && d != null) {
          try {
            return DateTime(y, mo, d);
          } catch (_) {}
        }
      }
    }
    return null;
  }

  String _birthdateApiString() {
    if (_birthDate == null) return '';
    final d = _birthDate!;
    final y = d.year.toString().padLeft(4, '0');
    final m = d.month.toString().padLeft(2, '0');
    final day = d.day.toString().padLeft(2, '0');
    return '$y-$m-$day';
  }

  String _birthdateDisplay() {
    if (_birthDate == null) return 'Tap to choose date';
    final d = _birthDate!;
    const months = [
      'Jan',
      'Feb',
      'Mar',
      'Apr',
      'May',
      'Jun',
      'Jul',
      'Aug',
      'Sep',
      'Oct',
      'Nov',
      'Dec',
    ];
    return '${months[d.month - 1]} ${d.day}, ${d.year}';
  }

  InputDecoration _modernInput({
    required String label,
    required IconData icon,
  }) {
    return InputDecoration(
      labelText: label,
      prefixIcon: Icon(icon, color: TradeHubColors.textMuted),
      filled: true,
      fillColor: TradeHubColors.surface2,
      labelStyle: const TextStyle(color: TradeHubColors.textMuted),
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(14),
        borderSide: BorderSide(color: Colors.white.withValues(alpha: 0.12)),
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(14),
        borderSide: BorderSide(color: Colors.white.withValues(alpha: 0.12)),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(14),
        borderSide: const BorderSide(color: TradeHubColors.accent, width: 1.5),
      ),
    );
  }

  Future<void> _pickBirthdate() async {
    final now = DateTime.now();
    final initial = _birthDate ?? DateTime(now.year - 25, now.month, now.day);
    final picked = await showDatePicker(
      context: context,
      initialDate: initial.isAfter(now) ? now : initial,
      firstDate: DateTime(1900),
      lastDate: now,
      builder: (ctx, child) {
        return Theme(
          data: Theme.of(ctx).copyWith(
            colorScheme: const ColorScheme.dark(
              primary: TradeHubColors.primary,
              surface: TradeHubColors.surface2,
            ),
          ),
          child: child!,
        );
      },
    );
    if (picked != null) setState(() => _birthDate = picked);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: TradeHubColors.bg,
      appBar: AppBar(
        title: const Text('Profile'),
        backgroundColor: TradeHubColors.bg,
        foregroundColor: TradeHubColors.textPrimary,
      ),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: ListView(
          children: [
            TextField(
              controller: _nameController,
              style: const TextStyle(color: TradeHubColors.textPrimary),
              decoration: _modernInput(
                label: 'Full name',
                icon: Icons.person_outline,
              ),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: _emailController,
              style: const TextStyle(color: TradeHubColors.textPrimary),
              decoration: _modernInput(
                label: 'Email',
                icon: Icons.alternate_email_rounded,
              ),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: _phoneController,
              keyboardType: TextInputType.phone,
              style: const TextStyle(color: TradeHubColors.textPrimary),
              decoration: _modernInput(
                label: 'Phone',
                icon: Icons.phone_outlined,
              ),
            ),
            const SizedBox(height: 12),
            Align(
              alignment: Alignment.centerLeft,
              child: Text(
                'Gender',
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                  color: TradeHubColors.textMuted.withValues(alpha: 0.95),
                ),
              ),
            ),
            const SizedBox(height: 8),
            SegmentedButton<String>(
              segments: _genders
                  .map(
                    (g) => ButtonSegment<String>(
                      value: g,
                      label: Padding(
                        padding: const EdgeInsets.symmetric(vertical: 10),
                        child: Text(g, style: const TextStyle(fontSize: 13)),
                      ),
                    ),
                  )
                  .toList(),
              selected: {_gender},
              onSelectionChanged: (next) {
                if (next.isNotEmpty) setState(() => _gender = next.first);
              },
              style: ButtonStyle(
                visualDensity: VisualDensity.compact,
                foregroundColor: WidgetStateProperty.resolveWith((states) {
                  if (states.contains(WidgetState.selected)) {
                    return TradeHubColors.bg;
                  }
                  return TradeHubColors.textPrimary;
                }),
                backgroundColor: WidgetStateProperty.resolveWith((states) {
                  if (states.contains(WidgetState.selected)) {
                    return TradeHubColors.primary;
                  }
                  return TradeHubColors.surface2;
                }),
                side: WidgetStateProperty.all(
                  BorderSide(color: Colors.white.withValues(alpha: 0.12)),
                ),
              ),
            ),
            const SizedBox(height: 12),
            Material(
              color: TradeHubColors.surface2,
              borderRadius: BorderRadius.circular(14),
              child: InkWell(
                onTap: _pickBirthdate,
                borderRadius: BorderRadius.circular(14),
                child: InputDecorator(
                  decoration: _modernInput(
                    label: 'Birthday',
                    icon: Icons.cake_outlined,
                  ),
                  child: Text(
                    _birthdateDisplay(),
                    style: TextStyle(
                      color: _birthDate == null
                          ? TradeHubColors.textMuted
                          : TradeHubColors.textPrimary,
                      fontSize: 16,
                    ),
                  ),
                ),
              ),
            ),
            const SizedBox(height: 18),
            Obx(
              () => ElevatedButton(
                onPressed: widget.controller.isSavingProfile.value
                    ? null
                    : () => widget.controller.saveProfile(
                        widget.controller.profile.value.copyWith(
                          fullName: _nameController.text,
                          email: _emailController.text,
                          phone: _phoneController.text,
                          gender: _gender,
                          birthdate: _birthdateApiString(),
                        ),
                      ),
                style: ElevatedButton.styleFrom(
                  backgroundColor: TradeHubColors.primaryDeep,
                  foregroundColor: Colors.white,
                  minimumSize: const Size.fromHeight(48),
                ),
                child: Text(
                  widget.controller.isSavingProfile.value
                      ? 'Saving...'
                      : 'Save Profile',
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

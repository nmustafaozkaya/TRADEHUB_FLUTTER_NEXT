import 'dart:convert';

import 'package:get/get.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';

/// Handles register/login state and session persistence.
class AuthController extends GetxController {
  static const _sessionKey = 'is_logged_in';
  static const _userIdKey = 'user_id';
  static const _usernameKey = 'user_username';
  static const _nameKey = 'user_name';
  static const _emailKey = 'user_email';
  static const _genderKey = 'user_gender';
  static const _birthdateKey = 'user_birthdate';
  static const _phoneKey = 'user_phone';
  static const _baseUrl = 'http://10.0.2.2:3000';

  final isLoggedIn = false.obs;
  final isReady = false.obs;
  final userId = 0.obs;
  final userName = ''.obs;
  final username = ''.obs;
  final userEmail = ''.obs;
  final userGender = ''.obs;
  final userBirthdate = ''.obs;
  final userPhone = ''.obs;

  @override
  void onInit() {
    super.onInit();
    loadSession();
  }

  Future<void> loadSession() async {
    final prefs = await SharedPreferences.getInstance();
    isLoggedIn.value = prefs.getBool(_sessionKey) ?? false;
    userId.value = prefs.getInt(_userIdKey) ?? 0;
    userName.value = prefs.getString(_nameKey) ?? '';
    username.value = prefs.getString(_usernameKey) ?? '';
    userEmail.value = prefs.getString(_emailKey) ?? '';
    userGender.value = prefs.getString(_genderKey) ?? '';
    userBirthdate.value = prefs.getString(_birthdateKey) ?? '';
    userPhone.value = prefs.getString(_phoneKey) ?? '';
    isReady.value = true;
  }

  Future<bool> register({
    required String username,
    required String name,
    required String email,
    required String password,
    required String gender,
    required String birthdate,
    required String phone,
  }) async {
    final response = await http.post(
      Uri.parse('$_baseUrl/api/auth/register'),
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode({
        'username': username.trim(),
        'password': password,
        'nameSurname': name.trim(),
        'email': email.trim(),
        'gender': gender.trim(),
        'birthdate': birthdate.trim(),
        'telnr1': phone.trim(),
      }),
    );
    if (response.statusCode < 200 || response.statusCode >= 300) {
      return false;
    }
    final map = jsonDecode(response.body) as Map<String, dynamic>;
    final user = map['user'] as Map<String, dynamic>? ?? <String, dynamic>{};
    final userIdValue = (user['id'] as num?)?.toInt() ?? 0;

    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_sessionKey, true);
    await prefs.setInt(_userIdKey, userIdValue);
    await prefs.setString(_nameKey, name.trim());
    await prefs.setString(_usernameKey, username.trim());
    await prefs.setString(_emailKey, email.trim());
    await prefs.setString(_genderKey, gender.trim());
    await prefs.setString(_birthdateKey, birthdate.trim());
    await prefs.setString(_phoneKey, phone.trim());

    userId.value = userIdValue;
    userName.value = name.trim();
    this.username.value = username.trim();
    userEmail.value = email.trim();
    userGender.value = gender.trim();
    userBirthdate.value = birthdate.trim();
    userPhone.value = phone.trim();
    isLoggedIn.value = true;
    return true;
  }

  Future<bool> login({
    required String login,
    required String password,
  }) async {
    final response = await http.post(
      Uri.parse('$_baseUrl/api/auth/login'),
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode({
        'login': login.trim(),
        'password': password,
      }),
    );
    if (response.statusCode < 200 || response.statusCode >= 300) {
      return false;
    }

    final map = jsonDecode(response.body) as Map<String, dynamic>;
    final user = map['user'] as Map<String, dynamic>? ?? <String, dynamic>{};
    final usernameValue = (user['username'] ?? '').toString();
    final userIdValue = (user['id'] as num?)?.toInt() ?? 0;
    final nameValue = (user['nameSurname'] ?? '').toString();
    final emailValue = (user['email'] ?? '').toString();
    final genderValue = (user['gender'] ?? '').toString();
    final birthdateValue = (user['birthdate'] ?? '').toString();
    final phoneValue = (user['telnr1'] ?? user['phone'] ?? '').toString();

    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_sessionKey, true);
    await prefs.setInt(_userIdKey, userIdValue);
    await prefs.setString(_usernameKey, usernameValue);
    await prefs.setString(_nameKey, nameValue);
    await prefs.setString(_emailKey, emailValue);
    await prefs.setString(_genderKey, genderValue);
    await prefs.setString(_birthdateKey, birthdateValue);
    await prefs.setString(_phoneKey, phoneValue);
    userId.value = userIdValue;
    username.value = usernameValue;
    userName.value = nameValue;
    userEmail.value = emailValue;
    userGender.value = genderValue;
    userBirthdate.value = birthdateValue;
    userPhone.value = phoneValue;
    isLoggedIn.value = true;
    return true;
  }

  Future<void> logout() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_sessionKey, false);
    await prefs.remove(_userIdKey);
    await prefs.remove(_usernameKey);
    await prefs.remove(_nameKey);
    await prefs.remove(_emailKey);
    await prefs.remove(_genderKey);
    await prefs.remove(_birthdateKey);
    await prefs.remove(_phoneKey);
    userId.value = 0;
    username.value = '';
    userName.value = '';
    userEmail.value = '';
    userGender.value = '';
    userBirthdate.value = '';
    userPhone.value = '';
    isLoggedIn.value = false;
  }
}

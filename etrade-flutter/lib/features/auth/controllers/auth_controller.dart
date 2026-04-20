import 'dart:convert';

import 'package:get/get.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';

/// Handles register/login state and session persistence.
class AuthController extends GetxController {
  static const _sessionKey = 'is_logged_in';
  static const _usernameKey = 'user_username';
  static const _nameKey = 'user_name';
  static const _baseUrl = 'http://10.0.2.2:3000';

  final isLoggedIn = false.obs;
  final isReady = false.obs;
  final userName = ''.obs;
  final username = ''.obs;

  @override
  void onInit() {
    super.onInit();
    loadSession();
  }

  Future<void> loadSession() async {
    final prefs = await SharedPreferences.getInstance();
    isLoggedIn.value = prefs.getBool(_sessionKey) ?? false;
    userName.value = prefs.getString(_nameKey) ?? '';
    username.value = prefs.getString(_usernameKey) ?? '';
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

    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_sessionKey, true);
    await prefs.setString(_nameKey, name.trim());
    await prefs.setString(_usernameKey, username.trim());

    userName.value = name.trim();
    this.username.value = username.trim();
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
    final nameValue = (user['nameSurname'] ?? '').toString();

    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_sessionKey, true);
    await prefs.setString(_usernameKey, usernameValue);
    await prefs.setString(_nameKey, nameValue);
    username.value = usernameValue;
    userName.value = nameValue;
    isLoggedIn.value = true;
    return true;
  }

  Future<void> logout() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_sessionKey, false);
    await prefs.remove(_usernameKey);
    await prefs.remove(_nameKey);
    username.value = '';
    userName.value = '';
    isLoggedIn.value = false;
  }
}

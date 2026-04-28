import 'dart:convert';

import 'package:http/http.dart' as http;

import '../models/account_models.dart';

/// Account API bridge for mobile app modules.
class AccountApiService {
  AccountApiService({http.Client? client}) : _client = client ?? http.Client();

  final http.Client _client;
  static const _baseUrl = 'http://10.0.2.2:3000';
  Map<String, String> _headers({int? userId, String? username, bool json = true}) {
    final headers = <String, String>{};
    if (json) headers['Content-Type'] = 'application/json';
    if (userId != null && userId > 0) headers['x-user-id'] = '$userId';
    if (username != null && username.trim().isNotEmpty) {
      headers['x-username'] = username.trim();
    }
    return headers;
  }

  Future<bool> updateProfile(UserProfile profile, {int? userId, String? username}) async {
    try {
      final response = await _client.put(
        Uri.parse('$_baseUrl/api/account/profile'),
        headers: _headers(userId: userId, username: username),
        body: jsonEncode({
          'nameSurname': profile.fullName,
          'email': profile.email,
          'gender': profile.gender,
          'birthdate': profile.birthdate,
          'phone': profile.phone,
        }),
      );
      return response.statusCode >= 200 && response.statusCode < 300;
    } catch (_) {
      return false;
    }
  }

  Future<List<UserOrderItem>> fetchOrders({int? userId, String? username}) async {
    try {
      final response = await _client.get(
        Uri.parse('$_baseUrl/api/account/orders'),
        headers: _headers(userId: userId, username: username, json: false),
      );
      if (response.statusCode < 200 || response.statusCode >= 300) return [];
      final map = jsonDecode(response.body) as Map<String, dynamic>;
      final list = (map['orders'] as List<dynamic>? ?? <dynamic>[]);
      return list.map((raw) {
        final json = raw as Map<String, dynamic>;
        return UserOrderItem(
          id: (json['ID'] as num?)?.toInt() ?? 0,
          totalPrice: (json['TotalPrice'] as num?)?.toDouble() ?? 0,
          statusText: (json['statusLabel'] ?? json['Status'] ?? 'Unknown').toString(),
          dateLabel: (json['Date'] ?? '-').toString(),
        );
      }).toList();
    } catch (_) {
      return [];
    }
  }

  Future<List<UserAddress>> fetchAddresses({int? userId, String? username}) async {
    try {
      final response = await _client.get(
        Uri.parse('$_baseUrl/api/account/addresses'),
        headers: _headers(userId: userId, username: username, json: false),
      );
      if (response.statusCode < 200 || response.statusCode >= 300) return [];
      final map = jsonDecode(response.body) as Map<String, dynamic>;
      final list = (map['addresses'] as List<dynamic>? ?? <dynamic>[]);
      return list.map((raw) {
        final json = raw as Map<String, dynamic>;
        return UserAddress(
          id: (json['id'] as num?)?.toInt() ?? 0,
          title: (json['title'] ?? 'Address').toString(),
          addressText: (json['addressText'] ?? '').toString(),
        );
      }).toList();
    } catch (_) {
      return [];
    }
  }

  Future<bool> createAddress(String addressText, {int? userId, String? username}) async {
    try {
      final response = await _client.post(
        Uri.parse('$_baseUrl/api/account/addresses'),
        headers: _headers(userId: userId, username: username),
        body: jsonEncode({
          'countryId': 1,
          'cityId': 1,
          'townId': 1,
          'districtId': 1,
          'postalCode': '',
          'addressText': addressText,
        }),
      );
      return response.statusCode >= 200 && response.statusCode < 300;
    } catch (_) {
      return false;
    }
  }

  Future<bool> deleteAddress(int addressId, {int? userId, String? username}) async {
    try {
      final response = await _client.delete(
        Uri.parse('$_baseUrl/api/account/addresses?id=$addressId'),
        headers: _headers(userId: userId, username: username, json: false),
      );
      return response.statusCode >= 200 && response.statusCode < 300;
    } catch (_) {
      return false;
    }
  }

  Future<List<SavedCardItem>> fetchCards({int? userId, String? username}) async {
    try {
      final response = await _client.get(
        Uri.parse('$_baseUrl/api/account/cards'),
        headers: _headers(userId: userId, username: username, json: false),
      );
      if (response.statusCode < 200 || response.statusCode >= 300) return [];
      final map = jsonDecode(response.body) as Map<String, dynamic>;
      final list = (map['cards'] as List<dynamic>? ?? <dynamic>[]);
      return list.map((raw) {
        final json = raw as Map<String, dynamic>;
        return SavedCardItem(
          id: (json['id'] as num?)?.toInt() ?? 0,
          brand: (json['brand'] ?? 'Card').toString(),
          last4: (json['last4'] ?? '0000').toString(),
          cardHolder: (json['cardHolder'] ?? 'Card holder').toString(),
          expMonth: (json['expMonth'] as num?)?.toInt() ?? 1,
          expYear: (json['expYear'] as num?)?.toInt() ?? DateTime.now().year,
        );
      }).toList();
    } catch (_) {
      return [];
    }
  }

  Future<bool> createCard({
    required String cardNumber,
    required String cardHolder,
    required int expMonth,
    required int expYear,
    int? userId,
    String? username,
  }) async {
    try {
      final response = await _client.post(
        Uri.parse('$_baseUrl/api/account/cards'),
        headers: _headers(userId: userId, username: username),
        body: jsonEncode({
          'cardNumber': cardNumber,
          'cardHolder': cardHolder,
          'expMonth': expMonth,
          'expYear': expYear,
        }),
      );
      return response.statusCode >= 200 && response.statusCode < 300;
    } catch (_) {
      return false;
    }
  }

  Future<bool> deleteCard(int cardId, {int? userId, String? username}) async {
    try {
      final response = await _client.delete(
        Uri.parse('$_baseUrl/api/account/cards?id=$cardId'),
        headers: _headers(userId: userId, username: username, json: false),
      );
      return response.statusCode >= 200 && response.statusCode < 300;
    } catch (_) {
      return false;
    }
  }

  Future<List<int>> fetchFavoriteIds({int? userId, String? username}) async {
    try {
      final response = await _client.get(
        Uri.parse('$_baseUrl/api/favorites'),
        headers: _headers(userId: userId, username: username, json: false),
      );
      if (response.statusCode < 200 || response.statusCode >= 300) return [];
      final map = jsonDecode(response.body) as Map<String, dynamic>;
      final idsRaw = (map['ids'] as List<dynamic>? ?? <dynamic>[]);
      return idsRaw
          .map((e) => (e as num?)?.toInt() ?? 0)
          .where((id) => id > 0)
          .toList();
    } catch (_) {
      return [];
    }
  }

  Future<List<int>> toggleFavorite({
    required int itemId,
    int? userId,
    String? username,
  }) async {
    try {
      final response = await _client.post(
        Uri.parse('$_baseUrl/api/favorites/toggle'),
        headers: _headers(userId: userId, username: username),
        body: jsonEncode({'itemId': itemId}),
      );
      if (response.statusCode < 200 || response.statusCode >= 300) return [];
      final map = jsonDecode(response.body) as Map<String, dynamic>;
      final idsRaw = (map['ids'] as List<dynamic>? ?? <dynamic>[]);
      return idsRaw
          .map((e) => (e as num?)?.toInt() ?? 0)
          .where((id) => id > 0)
          .toList();
    } catch (_) {
      return [];
    }
  }
}

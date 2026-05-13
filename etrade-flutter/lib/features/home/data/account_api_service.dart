import 'dart:async';
import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;

import '../../../core/order_status.dart';
import '../models/account_models.dart';

/// Account API bridge for mobile app modules.
class AccountApiService {
  AccountApiService({http.Client? client}) : _client = client ?? http.Client();

  final http.Client _client;
  static const _baseUrl = 'http://10.0.2.2:3000';
  Map<String, String> _headers({
    int? userId,
    String? username,
    bool json = true,
  }) {
    final headers = <String, String>{};
    if (json) headers['Content-Type'] = 'application/json';
    if (userId != null && userId > 0) headers['x-user-id'] = '$userId';
    if (username != null && username.trim().isNotEmpty) {
      headers['x-username'] = username.trim();
    }
    return headers;
  }

  Future<bool> updateProfile(
    UserProfile profile, {
    int? userId,
    String? username,
  }) async {
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

  Future<List<UserOrderItem>?> fetchOrders({
    int? userId,
    String? username,
  }) async {
    try {
      final response = await _client.get(
        Uri.parse('$_baseUrl/api/account/orders'),
        headers: _headers(userId: userId, username: username, json: false),
      );
      debugPrint('ORDERS STATUS: ${response.statusCode}');
      debugPrint('ORDERS BODY: ${response.body}');
      if (response.statusCode < 200 || response.statusCode >= 300) {
        return null;
      }
      
      final map = jsonDecode(response.body) as Map<String, dynamic>;
      final list = (map['orders'] as List<dynamic>? ?? <dynamic>[]);
      return list.map((raw) {
        final json = raw as Map<String, dynamic>;
        final st = (json['status'] as num?)?.toInt();
        return UserOrderItem(
          id: (json['id'] as num?)?.toInt() ?? 0,
          totalPrice: (json['totalPrice'] as num?)?.toDouble() ?? 0,
          statusText: OrderStatus.displayLabel(
            status: st,
            statusText: (json['statusLabel'] ?? json['statusText'])?.toString(),
          ),
          dateLabel: (json['date'] ?? '-').toString(),
          status: st,
          cargoCompany: json['cargoCompany']?.toString(),
          trackingNo: json['trackingNo']?.toString(),
          addressText: json['addressText']?.toString(),
          
        );
        
        
      }).toList();
    } catch (_) {
      return null;
    }
  }
Future<UserOrderDetail?> fetchOrderDetail(
  int orderId, {
  int? userId,
  String? username,
}) async {
  try {
    // ── Ekle ──
    final url = '$_baseUrl/api/account/orders/$orderId';
    debugPrint('ORDER DETAIL URL: $url');
    debugPrint('ORDER DETAIL HEADERS: ${_headers(userId: userId, username: username, json: false)}');
    // ──────────
    final response = await _client.get(
      Uri.parse('$_baseUrl/api/account/orders/$orderId'),
      headers: _headers(userId: userId, username: username, json: false),
    );
    debugPrint('ORDER DETAIL STATUS: ${response.statusCode}');
    debugPrint('ORDER DETAIL BODY: ${response.body}');
    // geri kalanı aynı...
    // ─────────────────────────
    if (response.statusCode < 200 || response.statusCode >= 300) return null;
    final map = jsonDecode(response.body) as Map<String, dynamic>;
    final orderJson = map['order'] as Map<String, dynamic>?;
    if (orderJson == null) return null;
    final lines = (map['lines'] as List<dynamic>? ?? <dynamic>[]);
    return UserOrderDetail.fromJson(orderJson, lines);
  } catch (e, stack) {
    debugPrint('ORDER DETAIL ERROR: $e');
    debugPrint('ORDER DETAIL STACK: $stack');
    return null;
  }
}

  /// Marks order completed after customer confirms receipt (same as web `ConfirmDeliveryButton`).
  Future<bool> confirmOrderDelivery(
    int orderId, {
    int? userId,
    String? username,
  }) async {
    try {
      final response = await _client.post(
        Uri.parse('$_baseUrl/api/account/orders/$orderId/confirm-delivery'),
        headers: _headers(userId: userId, username: username, json: false),
      );
      if (response.statusCode < 200 || response.statusCode >= 300) return false;
      final map = jsonDecode(response.body) as Map<String, dynamic>?;
      return map != null && map['ok'] == true;
    } catch (_) {
      return false;
    }
  }

  /// Creates review for item if user has successful purchase.
  Future<bool> createItemReview({
    required int itemId,
    required int rating,
    required String comment,
    int? userId,
    String? username,
  }) async {
    try {
      final response = await _client.post(
        Uri.parse('$_baseUrl/api/items/$itemId/reviews'),
        headers: _headers(userId: userId, username: username),
        body: jsonEncode({
          'rating': rating,
          'comment': comment,
        }),
      ).timeout(const Duration(seconds: 12));
      if (response.statusCode < 200 || response.statusCode >= 300) return false;
      final map = jsonDecode(response.body) as Map<String, dynamic>?;
      return map != null && map['ok'] == true;
    } on TimeoutException {
      return false;
    } catch (_) {
      return false;
    }
  }

  Future<List<UserAddress>> fetchAddresses({
    int? userId,
    String? username,
  }) async {
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

  Future<List<UserReviewItem>> fetchReviews({
    int? userId,
    String? username,
  }) async {
    try {
      final response = await _client.get(
        Uri.parse('$_baseUrl/api/account/reviews'),
        headers: _headers(userId: userId, username: username, json: false),
      );
      if (response.statusCode < 200 || response.statusCode >= 300) return [];
      final map = jsonDecode(response.body) as Map<String, dynamic>;
      final list = (map['reviews'] as List<dynamic>? ?? <dynamic>[]);
      return list
          .map((raw) => UserReviewItem.fromJson(raw as Map<String, dynamic>))
          .toList();
    } catch (_) {
      return [];
    }
  }

  Future<String?> changePassword({
    required String oldPassword,
    required String newPassword,
    required String confirmPassword,
    int? userId,
    String? username,
  }) async {
    try {
      final response = await _client
          .post(
            Uri.parse('$_baseUrl/api/account/password'),
            headers: _headers(userId: userId, username: username),
            body: jsonEncode({
              'oldPassword': oldPassword,
              'newPassword': newPassword,
              'confirmPassword': confirmPassword,
            }),
          )
          .timeout(const Duration(seconds: 12));
      final map = jsonDecode(response.body) as Map<String, dynamic>?;
      if (response.statusCode >= 200 && response.statusCode < 300 && map?['ok'] == true) {
        return null;
      }
      return (map?['error'] ?? 'Could not update password.').toString();
    } on TimeoutException {
      return 'Request timed out. Please try again.';
    } catch (_) {
      return 'Could not update password.';
    }
  }

  Future<int?> createOrder({
  required int addressId,
  required String paymentMethod,
  required List<Map<String, dynamic>> lines,
  int? userId,
  String? username,
}) async {
  try {
    final response = await _client.post(
      Uri.parse('$_baseUrl/api/account/orders'),
      headers: _headers(userId: userId, username: username),
      body: jsonEncode({
        'addressId': addressId,
        'paymentMethod': paymentMethod,
        'lines': lines,
      }),
    );
    if (response.statusCode < 200 || response.statusCode >= 300) return null;
    final map = jsonDecode(response.body) as Map<String, dynamic>;
    return (map['orderId'] as num?)?.toInt();
  } catch (_) {
    return null;
  }
}

  Future<bool> createAddress(
    String addressText, {
    int? userId,
    String? username,
  }) async {
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

  Future<bool> deleteAddress(
    int addressId, {
    int? userId,
    String? username,
  }) async {
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

  Future<List<SavedCardItem>> fetchCards({
    int? userId,
    String? username,
  }) async {
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

import 'dart:convert';
import 'dart:async';

import 'package:http/http.dart' as http;

import '../models/product_item.dart';

/// Fetches product data from remote API.
class ProductApiService {
  ProductApiService({http.Client? client}) : _client = client ?? http.Client();

  final http.Client _client;
  // Replace this with your running web backend URL.
  // Android emulator: http://10.0.2.2:3000
  // iOS simulator: http://localhost:3000
  static const _apiBaseUrl = 'http://10.0.2.2:3000';
  static const Duration _requestTimeout = Duration(seconds: 12);

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

  /// Gets products from the same `/api/items` route as the web shop (optional [category] = `SHOP_CATEGORIES` label).
  Future<List<ProductItem>> fetchProducts({String? category}) async {
    final params = <String, String>{
      'page': '1',
      'pageSize': '10000',
    };
    final c = category?.trim();
    if (c != null && c.isNotEmpty && c.toLowerCase() != 'all') {
      params['category'] = c;
    }
    final uri = Uri.parse('$_apiBaseUrl/api/items').replace(queryParameters: params);
    final response = await _client.get(uri).timeout(_requestTimeout);
    if (response.statusCode != 200) {
      throw Exception('Could not load products (HTTP ${response.statusCode}).');
    }

    final body = jsonDecode(response.body) as Map<String, dynamic>;
    final jsonList = (body['items'] as List<dynamic>? ?? <dynamic>[]);
    return jsonList.map((item) {
      final parsed = ProductItem.fromJson(item as Map<String, dynamic>);
      if (parsed.imageUrl.isNotEmpty) return parsed;

      // Fallback to generated product image endpoint from web app.
      final fallback =
          '$_apiBaseUrl/img/item/${parsed.id}.svg?name=${Uri.encodeComponent(parsed.name)}';
      return ProductItem(
        id: parsed.id,
        name: parsed.name,
        price: parsed.price,
        oldPrice: parsed.oldPrice,
        discountLabel: parsed.discountLabel,
        rating: parsed.rating,
        totalReviews: parsed.totalReviews,
        category: parsed.category,
        imageUrl: fallback,
      );
    }).toList();
  }

  /// Reads average rating + recent reviews for product detail.
  Future<ProductReviewBundle> fetchItemReviews({
    required int itemId,
    int limit = 6,
  }) async {
    final id = itemId > 0 ? itemId : 0;
    if (id == 0) return ProductReviewBundle.empty();
    final uri = Uri.parse('$_apiBaseUrl/api/items/$id/reviews')
        .replace(queryParameters: {'limit': '$limit'});
    final response = await _client.get(uri);
    if (response.statusCode != 200) {
      return ProductReviewBundle.empty();
    }
    final body = jsonDecode(response.body) as Map<String, dynamic>;
    return ProductReviewBundle.fromJson(body);
  }

  Future<bool> submitItemReview({
    required int itemId,
    required int rating,
    required String comment,
    int? userId,
    String? username,
  }) async {
    final id = itemId > 0 ? itemId : 0;
    if (id == 0) return false;
    try {
      final response = await _client
          .post(
            Uri.parse('$_apiBaseUrl/api/items/$id/reviews'),
            headers: _headers(userId: userId, username: username),
            body: jsonEncode({
              'rating': rating,
              'comment': comment.trim(),
            }),
          )
          .timeout(_requestTimeout);
      if (response.statusCode < 200 || response.statusCode >= 300) return false;
      final map = jsonDecode(response.body) as Map<String, dynamic>?;
      return map != null && map['ok'] == true;
    } catch (_) {
      return false;
    }
  }
}

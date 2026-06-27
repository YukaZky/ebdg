import 'dart:convert';

import 'package:http/http.dart' as http;
import 'api_service.dart';
import 'cart_badge_service.dart';

class CartApiService {
  static String? lastError;

  static String _messageFromBody(String body, {String fallback = 'Gagal menambahkan produk.'}) {
    try {
      final decoded = jsonDecode(body);
      if (decoded is Map) {
        final message = decoded['message']?.toString();
        if (message != null && message.isNotEmpty) return message;
        final errors = decoded['errors'];
        if (errors is Map && errors.isNotEmpty) {
          final first = errors.values.first;
          if (first is List && first.isNotEmpty) return first.first.toString();
          return first.toString();
        }
      }
    } catch (_) {}
    return fallback;
  }

  static Future<bool> addSelectedProductToCart({
    required int productId,
    required int quantity,
    int? variationId,
  }) async {
    lastError = null;
    if (ApiService.token == null) {
      lastError = 'Silakan login dulu.';
      return false;
    }

    final body = <String, dynamic>{
      'product_id': productId,
      'quantity': quantity,
    };

    if (variationId != null) {
      body['variation_id'] = variationId;
    }

    final response = await http.post(
      Uri.parse('${ApiService.baseUrl}/cart/add'),
      headers: {
        'Content-Type': 'application/json',
        'Accept': 'application/json',
        'Authorization': 'Bearer ${ApiService.token}',
      },
      body: jsonEncode(body),
    );

    final success = response.statusCode == 200 || response.statusCode == 201;
    if (success) {
      await CartBadgeService.refresh();
    } else {
      lastError = _messageFromBody(response.body, fallback: 'Gagal menambahkan produk. Kode: ${response.statusCode}');
    }
    return success;
  }
}

import 'dart:convert';

import 'package:http/http.dart' as http;
import 'api_service.dart';
import 'cart_badge_service.dart';

class CartApiService {
  static Future<bool> addSelectedProductToCart({
    required int productId,
    required int quantity,
    int? variationId,
  }) async {
    if (ApiService.token == null) return false;

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
    }
    return success;
  }
}

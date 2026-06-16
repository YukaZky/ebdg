import 'dart:convert';

import 'package:http/http.dart' as http;
import 'api_service.dart';

class CheckoutApiService {
  static Future<Map<String, dynamic>?> checkout({
    required String address,
    required String phone,
    required String provinceName,
    required String cityName,
    required String courier,
    required double shippingCost,
    required List<Map<String, dynamic>> cartItems,
  }) async {
    if (ApiService.token == null) return null;

    final formattedItems = cartItems.map((item) {
      final product = item['product'] ?? {};
      return {
        'product_id': item['product_id'] ?? product['id'],
        'quantity': item['quantity'],
        'variation_id': item['variation_id'],
        'variation_name': item['variation_name'],
        'price': item['price'] ?? product['regular_price'],
        'selected_image': item['selected_image'] ?? product['image'],
        'weight': item['weight'] ?? product['weight'],
      };
    }).toList();

    final response = await http.post(
      Uri.parse('${ApiService.baseUrl}/checkout'),
      headers: {
        'Content-Type': 'application/json',
        'Accept': 'application/json',
        'Authorization': 'Bearer ${ApiService.token}',
      },
      body: jsonEncode({
        'address': address,
        'phone': phone,
        'province_name': provinceName,
        'city_name': cityName,
        'courier': courier,
        'shipping_cost': shippingCost,
        'items': formattedItems,
      }),
    );

    if (response.statusCode == 200) {
      return jsonDecode(response.body);
    }

    return null;
  }
}

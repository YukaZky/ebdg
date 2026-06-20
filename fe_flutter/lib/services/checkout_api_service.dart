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
    // Tambahan parameter untuk Core API
    required String paymentType, 
    String? bankCode,
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
        'payment_type': paymentType, // Kirim tipe pembayaran
        'bank_code': bankCode,       // Kirim kode bank jika ada
      }),
    );

    if (response.statusCode == 200 || response.statusCode == 201) {
      return jsonDecode(response.body);
    }

    return null;
  }

  // Fungsi baru untuk mengecek status dari Midtrans via Laravel
  static Future<Map<String, dynamic>?> checkOrderStatus(String orderId) async {
    if (ApiService.token == null) return null;

    final response = await http.get(
      Uri.parse('${ApiService.baseUrl}/order/$orderId/status'),
      headers: {
        'Accept': 'application/json',
        'Authorization': 'Bearer ${ApiService.token}',
      },
    );

    if (response.statusCode == 200) {
      return jsonDecode(response.body);
    }
    return null;
  }
}
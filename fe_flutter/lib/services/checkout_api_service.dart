import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import 'api_service.dart';

class CheckoutApiService {
  static String get baseUrl => ApiService.baseUrl;

  static int _toInt(dynamic value, {int fallback = 0}) {
    if (value == null) return fallback;
    if (value is int) return value;
    if (value is double) return value.toInt();
    return int.tryParse(value.toString()) ??
        double.tryParse(value.toString())?.toInt() ??
        fallback;
  }

  static double _toDouble(dynamic value, {double fallback = 0}) {
    if (value == null) return fallback;
    if (value is num) return value.toDouble();
    return double.tryParse(value.toString()) ?? fallback;
  }

  static Map<String, dynamic> _asMap(dynamic value) {
    if (value is Map<String, dynamic>) return value;
    if (value is Map) return Map<String, dynamic>.from(value);
    return <String, dynamic>{};
  }

  static Map<String, dynamic> _formatCheckoutItem(Map<String, dynamic> item) {
    final product = _asMap(item['product']);

    final productId = item['product_id'] ?? item['id_product'] ?? product['id'];
    final quantity = _toInt(item['quantity'] ?? item['qty'], fallback: 1);
    final price = _toDouble(
      item['price'] ??
          item['active_price'] ??
          item['sale_price'] ??
          item['regular_price'] ??
          product['active_price'] ??
          product['sale_price'] ??
          product['regular_price'],
    );

    return {
      'cart_item_id': item['cart_item_id'] ?? item['id'],
      'product_id': _toInt(productId),
      'quantity': quantity,
      'price': price.toInt(),
      'variation_id': item['variation_id'] ?? product['variation_id'],
      'variation_name': item['variation_name'] ?? product['selected_variation_name'],
      'selected_image': item['selected_image'] ?? product['image'],
      'weight': item['weight'] ?? product['weight'],
    };
  }

  static Future<Map<String, String>?> _authHeaders({bool jsonBody = false}) async {
    final prefs = await SharedPreferences.getInstance();
    final token = prefs.getString('token') ??
        prefs.getString('auth_token') ??
        prefs.getString('access_token') ??
        ApiService.token;

    if (token == null) {
      debugPrint('❌ [CHECKOUT API] Token otorisasi kosong.');
      return null;
    }

    return {
      if (jsonBody) 'Content-Type': 'application/json',
      'Accept': 'application/json',
      'Authorization': 'Bearer $token',
    };
  }

  static Future<Map<String, dynamic>?> _postJson(
    String endpoint,
    Map<String, dynamic> payload,
  ) async {
    final headers = await _authHeaders(jsonBody: true);
    if (headers == null) return null;

    final urlNoSlash = Uri.parse('$baseUrl$endpoint');
    final urlWithSlash = Uri.parse('$baseUrl$endpoint/');

    try {
      debugPrint('📡 [CHECKOUT API] POST $urlNoSlash');
      debugPrint('📦 [CHECKOUT API] Payload: ${json.encode(payload)}');

      var response = await http.post(
        urlNoSlash,
        headers: headers,
        body: json.encode(payload),
      );

      if (response.statusCode == 405 || response.statusCode == 301 || response.statusCode == 302) {
        response = await http.post(
          urlWithSlash,
          headers: headers,
          body: json.encode(payload),
        );
      }

      debugPrint('📥 [CHECKOUT API] Status: ${response.statusCode}');
      debugPrint('📥 [CHECKOUT API] Body: ${response.body}');

      if (response.statusCode >= 200 && response.statusCode < 300) {
        return json.decode(response.body) as Map<String, dynamic>;
      }
      return null;
    } catch (e, stacktrace) {
      debugPrint('❌ [CHECKOUT API] POST gagal: $e');
      debugPrint('$stacktrace');
      return null;
    }
  }

  static Future<Map<String, dynamic>?> _getJson(String endpoint) async {
    final headers = await _authHeaders();
    if (headers == null) return null;

    final urlNoSlash = Uri.parse('$baseUrl$endpoint');
    final urlWithSlash = Uri.parse('$baseUrl$endpoint/');

    try {
      var response = await http.get(urlNoSlash, headers: headers);

      if (response.statusCode == 405 || response.statusCode == 301 || response.statusCode == 302) {
        response = await http.get(urlWithSlash, headers: headers);
      }

      if (response.statusCode >= 200 && response.statusCode < 300) {
        return json.decode(response.body) as Map<String, dynamic>;
      }
      debugPrint('❌ [CHECKOUT API] GET gagal. Status: ${response.statusCode}, Body: ${response.body}');
      return null;
    } catch (e) {
      debugPrint('❌ [CHECKOUT API] GET exception: $e');
      return null;
    }
  }

  static Map<String, dynamic> _shippingPayload({
    String? orderId,
    required String address,
    required String phone,
    required String provinceName,
    required String cityName,
    required String courier,
    required double shippingCost,
    required List<Map<String, dynamic>> cartItems,
  }) {
    final payload = <String, dynamic>{
      'address': address,
      'phone': phone,
      'province_name': provinceName,
      'city_name': cityName,
      'courier': courier,
      'shipping_cost': shippingCost.toInt(),
      'items': cartItems.map(_formatCheckoutItem).toList(),
    };

    if (orderId != null && orderId.isNotEmpty) {
      payload['order_id'] = orderId;
    }

    return payload;
  }

  /// Tahap baru: finalisasi order setelah alamat, kurir, dan ongkir valid.
  /// Endpoint ini belum membuat VA/QRIS, hanya membuat Order, OrderItem,
  /// Transaction placeholder, dan mengosongkan cart item yang di-checkout.
  static Future<Map<String, dynamic>?> finalizeOrder({
    String? orderId,
    required String address,
    required String phone,
    required String provinceName,
    required String cityName,
    required String courier,
    required double shippingCost,
    required List<Map<String, dynamic>> cartItems,
  }) async {
    return _postJson(
      '/checkout/finalize',
      _shippingPayload(
        orderId: orderId,
        address: address,
        phone: phone,
        provinceName: provinceName,
        cityName: cityName,
        courier: courier,
        shippingCost: shippingCost,
        cartItems: cartItems,
      ),
    );
  }

  /// Tahap baru: setelah user memilih metode pembayaran, backend charge Midtrans
  /// memakai order_id yang sudah final sehingga VA/QRIS langsung dikembalikan.
  static Future<Map<String, dynamic>?> setPaymentMethod({
    required String orderId,
    required String paymentType,
    String? bankCode,
  }) async {
    return _postJson('/orders/$orderId/payment-method', {
      'payment_type': paymentType,
      'bank': bankCode,
    });
  }

  static Future<Map<String, dynamic>?> resetPayment(String orderId) async {
    return _postJson('/orders/$orderId/reset-payment', {});
  }

  static Future<Map<String, dynamic>?> getOrder(String orderId) async {
    return _getJson('/orders/$orderId');
  }

  /// Endpoint lama tetap disediakan untuk kompatibilitas: langsung finalisasi order
  /// dan charge Midtrans dalam satu request.
  static Future<Map<String, dynamic>?> checkout({
    required String address,
    required String phone,
    required String provinceName,
    required String cityName,
    required String courier,
    required double shippingCost,
    required List<Map<String, dynamic>> cartItems,
    required String paymentType,
    String? bankCode,
  }) async {
    final payload = _shippingPayload(
      address: address,
      phone: phone,
      provinceName: provinceName,
      cityName: cityName,
      courier: courier,
      shippingCost: shippingCost,
      cartItems: cartItems,
    );

    payload['payment_type'] = paymentType;
    payload['bank'] = bankCode;

    return _postJson('/checkout', payload);
  }

  static Future<Map<String, dynamic>?> checkOrderStatus(String orderId) async {
    return _getJson('/order/$orderId/status');
  }
}

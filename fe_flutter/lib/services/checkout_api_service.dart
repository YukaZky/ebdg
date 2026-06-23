import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import 'api_service.dart';

class CheckoutApiService {
  static String get baseUrl => ApiService.baseUrl;
  static const _orderKey = 'active_checkout_order_id';
  static const _itemsKey = 'active_checkout_items_signature';

  static int _toInt(dynamic value, {int fallback = 0}) {
    if (value == null) return fallback;
    if (value is int) return value;
    if (value is double) return value.toInt();
    return int.tryParse(value.toString()) ?? double.tryParse(value.toString())?.toInt() ?? fallback;
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
    final price = _toDouble(item['price'] ?? item['active_price'] ?? item['sale_price'] ?? item['regular_price'] ?? product['active_price'] ?? product['sale_price'] ?? product['regular_price']);

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

  static String _signature(List<Map<String, dynamic>> cartItems) {
    final items = cartItems.map(_formatCheckoutItem).map((item) => {
      'cart_item_id': item['cart_item_id'],
      'product_id': item['product_id'],
      'quantity': item['quantity'],
      'variation_id': item['variation_id'],
    }).toList()
      ..sort((a, b) => '${a['cart_item_id']}:${a['product_id']}:${a['variation_id']}'.compareTo('${b['cart_item_id']}:${b['product_id']}:${b['variation_id']}'));
    return json.encode(items);
  }

  static Future<String?> _cachedOrderId(List<Map<String, dynamic>> cartItems) async {
    final prefs = await SharedPreferences.getInstance();
    if (prefs.getString(_itemsKey) != _signature(cartItems)) return null;
    final id = prefs.getString(_orderKey);
    return id == null || id.isEmpty ? null : id;
  }

  static Future<void> _saveOrderId(String id, List<Map<String, dynamic>> cartItems) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_orderKey, id);
    await prefs.setString(_itemsKey, _signature(cartItems));
  }

  static Future<void> _clearOrderId() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_orderKey);
    await prefs.remove(_itemsKey);
  }

  static Future<Map<String, String>?> _authHeaders({bool jsonBody = false}) async {
    final prefs = await SharedPreferences.getInstance();
    final token = prefs.getString('token') ?? prefs.getString('auth_token') ?? prefs.getString('access_token') ?? ApiService.token;
    if (token == null) return null;
    return {
      if (jsonBody) 'Content-Type': 'application/json',
      'Accept': 'application/json',
      'Authorization': 'Bearer $token',
    };
  }

  static Future<Map<String, dynamic>?> _postJson(String endpoint, Map<String, dynamic> payload) async {
    final headers = await _authHeaders(jsonBody: true);
    if (headers == null) return null;
    final urlNoSlash = Uri.parse('$baseUrl$endpoint');
    final urlWithSlash = Uri.parse('$baseUrl$endpoint/');
    try {
      var response = await http.post(urlNoSlash, headers: headers, body: json.encode(payload));
      if (response.statusCode == 405 || response.statusCode == 301 || response.statusCode == 302) {
        response = await http.post(urlWithSlash, headers: headers, body: json.encode(payload));
      }
      if (response.statusCode >= 200 && response.statusCode < 300) {
        return json.decode(response.body) as Map<String, dynamic>;
      }
      debugPrint('Checkout POST gagal ${response.statusCode}: ${response.body}');
      return null;
    } catch (e) {
      debugPrint('Checkout POST exception: $e');
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
      return null;
    } catch (_) {
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
    if (orderId != null && orderId.isNotEmpty) payload['order_id'] = orderId;
    return payload;
  }

  static Future<Map<String, dynamic>?> finalizeOrder({
    String? orderId,
    required String address,
    required String phone,
    required String provinceName,
    required String cityName,
    required String courier,
    required double shippingCost,
    required List<Map<String, dynamic>> cartItems,
  }) {
    return _postJson('/checkout/finalize', _shippingPayload(orderId: orderId, address: address, phone: phone, provinceName: provinceName, cityName: cityName, courier: courier, shippingCost: shippingCost, cartItems: cartItems));
  }

  static Future<Map<String, dynamic>?> setPaymentMethod({required String orderId, required String paymentType, String? bankCode}) {
    return _postJson('/orders/$orderId/payment-method', {'payment_type': paymentType, 'bank': bankCode});
  }

  static Future<Map<String, dynamic>?> resetPayment(String orderId) {
    return _postJson('/orders/$orderId/reset-payment', {});
  }

  static Future<Map<String, dynamic>?> getOrder(String orderId) {
    return _getJson('/orders/$orderId');
  }

  static Future<Map<String, dynamic>?> checkout({
    String? orderId,
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
    var reusableOrderId = orderId ?? await _cachedOrderId(cartItems);
    if (reusableOrderId != null && reusableOrderId.isNotEmpty) {
      final status = await checkOrderStatus(reusableOrderId);
      final transactionStatus = status?['transaction_status']?.toString();
      final alreadyPaid = transactionStatus == 'approved' || transactionStatus == 'settlement' || transactionStatus == 'capture';
      if (alreadyPaid) {
        await _clearOrderId();
        reusableOrderId = null;
      } else {
        await resetPayment(reusableOrderId);
      }
    }

    final payload = _shippingPayload(orderId: reusableOrderId, address: address, phone: phone, provinceName: provinceName, cityName: cityName, courier: courier, shippingCost: shippingCost, cartItems: cartItems);
    payload['payment_type'] = paymentType;
    payload['bank'] = bankCode;

    final response = await _postJson('/checkout', payload);
    final responseOrderId = response?['order']?['id']?.toString();
    if (response != null && response['success'] == true && responseOrderId != null) {
      await _saveOrderId(responseOrderId, cartItems);
    }
    return response;
  }

  static Future<Map<String, dynamic>?> checkOrderStatus(String orderId) {
    return _getJson('/order/$orderId/status');
  }
}

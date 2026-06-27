import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import 'api_service.dart';

class CheckoutApiService {
  static String get baseUrl => ApiService.baseUrl;
  static const _orderKey = 'active_checkout_order_id';
  static const _signatureKey = 'active_checkout_signature';

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

  static String _cleanPaymentType(dynamic value) {
    final raw = value?.toString().trim().toLowerCase() ?? '';
    if (raw.contains('bank')) return 'bank_transfer';
    if (raw.contains('qris')) return 'qris';
    if (raw.contains('gopay')) return 'gopay';
    return raw;
  }

  static String? _cleanBankCode(dynamic value, String paymentType) {
    if (paymentType != 'bank_transfer') return null;
    final raw = value?.toString().trim().toLowerCase() ?? '';
    if (raw.isEmpty || raw == 'null') return null;
    if (raw.contains('bca')) return 'bca';
    if (raw.contains('bni')) return 'bni';
    if (raw.contains('bri')) return 'bri';
    if (raw.contains('permata')) return 'permata';
    return raw;
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
      item['price'] ?? item['active_price'] ?? item['sale_price'] ?? item['regular_price'] ?? product['active_price'] ?? product['sale_price'] ?? product['regular_price'],
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

  static List<Map<String, dynamic>> _signatureItems(List<Map<String, dynamic>> cartItems) {
    final items = cartItems.map(_formatCheckoutItem).map((item) {
      return {
        'cart_item_id': item['cart_item_id'],
        'product_id': item['product_id'],
        'quantity': item['quantity'],
        'price': item['price'],
        'variation_id': item['variation_id'],
      };
    }).toList();

    items.sort((a, b) => '${a['cart_item_id']}:${a['product_id']}:${a['variation_id']}'
        .compareTo('${b['cart_item_id']}:${b['product_id']}:${b['variation_id']}'));
    return items;
  }

  static String _checkoutSignature({
    required String address,
    required String phone,
    required String provinceName,
    required String cityName,
    required String courier,
    required double shippingCost,
    required List<Map<String, dynamic>> cartItems,
    required String paymentType,
    String? bankCode,
    int? couponTakeId,
  }) {
    final cleanPaymentType = _cleanPaymentType(paymentType);
    final cleanBankCode = _cleanBankCode(bankCode, cleanPaymentType);
    final payload = {
      'address': address.trim(),
      'phone': phone.trim(),
      'province_name': provinceName.trim(),
      'city_name': cityName.trim(),
      'courier': courier.trim(),
      'shipping_cost': shippingCost.toInt(),
      'payment_type': cleanPaymentType,
      'bank': cleanBankCode,
      'coupon_take_id': couponTakeId,
      'items': _signatureItems(cartItems),
    };
    return json.encode(payload);
  }

  static Future<String?> _cachedOrderId() async {
    final prefs = await SharedPreferences.getInstance();
    final id = prefs.getString(_orderKey);
    return id == null || id.isEmpty ? null : id;
  }

  static Future<String?> _cachedSignature() async {
    final prefs = await SharedPreferences.getInstance();
    final signature = prefs.getString(_signatureKey);
    return signature == null || signature.isEmpty ? null : signature;
  }

  static Future<void> _saveOrderId(String id, String signature) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_orderKey, id);
    await prefs.setString(_signatureKey, signature);
  }

  static Future<void> _clearOrderId() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_orderKey);
    await prefs.remove(_signatureKey);
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
      try {
        return json.decode(response.body) as Map<String, dynamic>;
      } catch (_) {
        return {'success': false, 'message': 'Checkout gagal. Kode: ${response.statusCode}'};
      }
    } catch (e) {
      debugPrint('Checkout POST exception: $e');
      return {'success': false, 'message': 'Checkout exception: $e'};
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
    String? checkoutSignature,
    int? couponTakeId,
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
    if (checkoutSignature != null && checkoutSignature.isNotEmpty) payload['checkout_signature'] = checkoutSignature;
    if (couponTakeId != null && couponTakeId > 0) payload['coupon_take_id'] = couponTakeId;
    return payload;
  }

  static Map<String, dynamic> _decodePaymentDetails(dynamic value) {
    if (value is Map<String, dynamic>) return value;
    if (value is Map) return Map<String, dynamic>.from(value);
    if (value is String && value.trim().isNotEmpty) {
      try {
        final decoded = json.decode(value);
        if (decoded is Map<String, dynamic>) return decoded;
        if (decoded is Map) return Map<String, dynamic>.from(decoded);
      } catch (_) {}
    }
    return <String, dynamic>{};
  }

  static bool _isPaymentInfoActive(Map<String, dynamic> paymentInfo) {
    final expiry = paymentInfo['expiry_time']?.toString();
    if (expiry == null || expiry.isEmpty || expiry == 'null') return true;
    try {
      return DateTime.parse(expiry).isAfter(DateTime.now());
    } catch (_) {
      return true;
    }
  }

  static Future<Map<String, dynamic>?> _activePaymentResponse(String orderId, String signature) async {
    final status = await checkOrderStatus(orderId);
    if (status == null || status['success'] != true) return null;
    final transactionStatus = status['transaction_status']?.toString();
    if (transactionStatus == 'approved' || transactionStatus == 'settlement' || transactionStatus == 'capture') {
      await _clearOrderId();
      return null;
    }
    final paymentInfo = _asMap(status['payment_info']);
    if (paymentInfo.isEmpty || !_isPaymentInfoActive(paymentInfo)) return null;
    final orderResponse = await getOrder(orderId);
    final order = _asMap(orderResponse?['order']);
    final transaction = _asMap(order['transaction']);
    final details = _decodePaymentDetails(transaction['payment_details']);
    if (details['checkout_signature']?.toString() != signature) return null;
    return {
      'success': true,
      'message': 'Instruksi pembayaran aktif digunakan kembali.',
      'reused_payment': true,
      'payment_info': paymentInfo,
      'midtrans_response': details['midtrans_response'],
      'order': order,
    };
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
    int? couponTakeId,
  }) {
    return _postJson('/checkout/finalize', _shippingPayload(orderId: orderId, address: address, phone: phone, provinceName: provinceName, cityName: cityName, courier: courier, shippingCost: shippingCost, cartItems: cartItems, couponTakeId: couponTakeId));
  }

  static Future<Map<String, dynamic>?> setPaymentMethod({
    required String orderId,
    required String paymentType,
    String? bankCode,
  }) {
    final cleanPaymentType = _cleanPaymentType(paymentType);
    final payload = <String, dynamic>{'payment_type': cleanPaymentType};
    final cleanBankCode = _cleanBankCode(bankCode, cleanPaymentType);
    if (cleanBankCode != null) payload['bank'] = cleanBankCode;
    return _postJson('/orders/$orderId/payment-method', payload);
  }

  static Future<Map<String, dynamic>?> resetPayment(String orderId) {
    return _postJson('/orders/$orderId/reset-payment', {});
  }

  static Future<Map<String, dynamic>?> completeCheckout(String orderId) {
    return _postJson('/orders/$orderId/complete-checkout', {});
  }

  static Future<Map<String, dynamic>?> cancelOrder(String orderId) async {
    final response = await _postJson('/orders/$orderId/cancel', {});
    if (response != null && response['success'] == true) await _clearOrderId();
    return response;
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
    int? couponTakeId,
  }) async {
    final cleanPaymentType = _cleanPaymentType(paymentType);
    final cleanBankCode = _cleanBankCode(bankCode, cleanPaymentType);
    final signature = _checkoutSignature(address: address, phone: phone, provinceName: provinceName, cityName: cityName, courier: courier, shippingCost: shippingCost, cartItems: cartItems, paymentType: cleanPaymentType, bankCode: cleanBankCode, couponTakeId: couponTakeId);
    final cachedOrderId = await _cachedOrderId();
    final cachedSignature = await _cachedSignature();
    var reusableOrderId = orderId ?? cachedOrderId;

    if (reusableOrderId != null && reusableOrderId.isNotEmpty) {
      if (cachedSignature == signature) {
        final existingPayment = await _activePaymentResponse(reusableOrderId, signature);
        if (existingPayment != null) return existingPayment;
      }
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

    final payload = _shippingPayload(orderId: reusableOrderId, address: address, phone: phone, provinceName: provinceName, cityName: cityName, courier: courier, shippingCost: shippingCost, cartItems: cartItems, checkoutSignature: signature, couponTakeId: couponTakeId);
    payload['payment_type'] = cleanPaymentType;
    if (cleanBankCode != null) payload['bank'] = cleanBankCode;

    final response = await _postJson('/checkout', payload);
    final responseOrderId = response?['order']?['id']?.toString();
    if (response != null && response['success'] == true && responseOrderId != null) {
      await _saveOrderId(responseOrderId, signature);
    }
    return response;
  }

  static Future<Map<String, dynamic>?> checkOrderStatus(String orderId) {
    return _getJson('/order/$orderId/status');
  }
}

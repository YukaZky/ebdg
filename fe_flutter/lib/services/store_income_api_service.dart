import 'dart:convert';

import 'package:http/http.dart' as http;
import 'package:image_picker/image_picker.dart';

import 'api_service.dart';

class StoreIncomeApiService {
  static String? lastError;

  static Map<String, String> get _headers => {
        'Accept': 'application/json',
        'Content-Type': 'application/json',
        'Cache-Control': 'no-cache',
        if (ApiService.token != null)
          'Authorization': 'Bearer ${ApiService.token}',
      };

  static Map<String, String> get authenticatedImageHeaders => {
        'Accept': 'image/*',
        if (ApiService.token != null)
          'Authorization': 'Bearer ${ApiService.token}',
      };

  static String _message(String body, {String fallback = 'Terjadi kesalahan.'}) {
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

  static Future<Map<String, dynamic>?> sellerIncome() async {
    final response = await http.get(
      Uri.parse('${ApiService.baseUrl}/marketplace/income'),
      headers: _headers,
    );
    if (response.statusCode == 200) {
      final decoded = jsonDecode(response.body);
      if (decoded is Map && decoded['data'] is Map) {
        return Map<String, dynamic>.from(decoded['data']);
      }
    }
    lastError = _message(response.body, fallback: 'Gagal memuat pendapatan toko.');
    return null;
  }

  static Future<Map<String, dynamic>?> sellerIncomeByDate(String date) async {
    final response = await http.get(
      Uri.parse('${ApiService.baseUrl}/marketplace/income/$date'),
      headers: _headers,
    );
    if (response.statusCode == 200) {
      final decoded = jsonDecode(response.body);
      if (decoded is Map && decoded['data'] is Map) {
        return Map<String, dynamic>.from(decoded['data']);
      }
    }
    lastError = _message(response.body, fallback: 'Gagal memuat detail pendapatan.');
    return null;
  }

  static Future<List<dynamic>> sellerPayouts() async {
    final response = await http.get(
      Uri.parse('${ApiService.baseUrl}/marketplace/payouts'),
      headers: _headers,
    );
    if (response.statusCode == 200) {
      final decoded = jsonDecode(response.body);
      return decoded['data'] is List ? decoded['data'] : [];
    }
    lastError = _message(response.body, fallback: 'Gagal memuat riwayat pencairan.');
    return [];
  }

  static Future<Map<String, dynamic>?> sellerPayoutDetail(int payoutId) async {
    lastError = null;
    final response = await http.get(
      Uri.parse('${ApiService.baseUrl}/marketplace/payouts/$payoutId'),
      headers: _headers,
    );
    if (response.statusCode == 200) {
      final decoded = jsonDecode(response.body);
      if (decoded is Map && decoded['data'] is Map) {
        return Map<String, dynamic>.from(decoded['data']);
      }
    }
    lastError = _message(
      response.body,
      fallback: 'Gagal memuat detail pencairan.',
    );
    return null;
  }

  static Future<Map<String, dynamic>> bankAccounts() async {
    final response = await http.get(
      Uri.parse('${ApiService.baseUrl}/marketplace/bank-accounts'),
      headers: _headers,
    );
    if (response.statusCode == 200) {
      final decoded = jsonDecode(response.body);
      return {
        'accounts': decoded['data'] is List ? decoded['data'] : [],
        'providers': decoded['providers'] is List ? decoded['providers'] : [],
      };
    }
    lastError = _message(response.body, fallback: 'Gagal memuat rekening toko.');
    return {'accounts': <dynamic>[], 'providers': <dynamic>[]};
  }

  static Future<bool> saveBankAccounts(List<Map<String, dynamic>> accounts) async {
    lastError = null;
    final response = await http.put(
      Uri.parse('${ApiService.baseUrl}/marketplace/bank-accounts'),
      headers: _headers,
      body: jsonEncode({'accounts': accounts}),
    );
    if (response.statusCode == 200) return true;
    lastError = _message(response.body, fallback: 'Gagal menyimpan rekening toko.');
    return false;
  }

  static Future<List<dynamic>?> superAdminStores() async {
    lastError = null;
    final response = await http.get(
      Uri.parse('${ApiService.baseUrl}/admin/store-payouts'),
      headers: _headers,
    );
    if (response.statusCode == 200) {
      final decoded = jsonDecode(response.body);
      return decoded['data'] is List ? decoded['data'] : [];
    }
    lastError = _message(response.body, fallback: 'Akses pencairan tidak tersedia.');
    return null;
  }

  static Future<bool> canAccessSuperAdminPayouts() async {
    final data = await superAdminStores();
    return data != null;
  }

  static Future<Map<String, dynamic>?> superAdminSellerDetail(int sellerId) async {
    lastError = null;
    final response = await http.get(
      Uri.parse('${ApiService.baseUrl}/admin/store-payouts/$sellerId'),
      headers: _headers,
    );
    if (response.statusCode == 200) {
      final decoded = jsonDecode(response.body);
      if (decoded is Map && decoded['data'] is Map) {
        return Map<String, dynamic>.from(decoded['data']);
      }
    }
    lastError = _message(response.body, fallback: 'Gagal memuat detail saldo toko.');
    return null;
  }

  static Future<bool> processPayout({
    required int sellerId,
    required List<int> orderIds,
    required int bankAccountId,
    required XFile proofPhoto,
    String? description,
  }) async {
    lastError = null;
    final request = http.MultipartRequest(
      'POST',
      Uri.parse('${ApiService.baseUrl}/admin/store-payouts/$sellerId/pay'),
    );

    request.headers['Accept'] = 'application/json';
    if (ApiService.token != null) {
      request.headers['Authorization'] = 'Bearer ${ApiService.token}';
    }

    for (int i = 0; i < orderIds.length; i++) {
      request.fields['order_ids[$i]'] = orderIds[i].toString();
    }

    request.fields['bank_account_id'] = bankAccountId.toString();
    request.fields['description'] = description?.trim() ?? '';

    final bytes = await proofPhoto.readAsBytes();
    request.files.add(http.MultipartFile.fromBytes(
      'proof_photo',
      bytes,
      filename: proofPhoto.name.isEmpty ? 'bukti_pencairan.jpg' : proofPhoto.name,
    ));

    final streamed = await request.send();
    final body = await streamed.stream.bytesToString();
    if (streamed.statusCode == 200 || streamed.statusCode == 201) return true;

    lastError = _message(body, fallback: 'Gagal memproses pencairan.');
    return false;
  }
}

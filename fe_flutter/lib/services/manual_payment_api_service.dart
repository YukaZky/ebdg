import 'dart:convert';

import 'package:http/http.dart' as http;
import 'package:image_picker/image_picker.dart';

import 'api_service.dart';

class ManualPaymentApiService {
  static String? lastError;

  static Map<String, String> get _headers => {
    'Accept': 'application/json',
    'Content-Type': 'application/json',
    'Cache-Control': 'no-cache',
    if (ApiService.token != null) 'Authorization': 'Bearer ${ApiService.token}',
  };

  static Map<String, String> get authenticatedImageHeaders => {
    'Accept': 'image/*',
    'Cache-Control': 'no-cache',
    if (ApiService.token != null) 'Authorization': 'Bearer ${ApiService.token}',
  };

  static String _message(
    String body, {
    String fallback = 'Terjadi kesalahan.',
  }) {
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

  static Map<String, dynamic>? _decodeMap(String body) {
    try {
      final decoded = jsonDecode(body);
      if (decoded is Map<String, dynamic>) return decoded;
      if (decoded is Map) return Map<String, dynamic>.from(decoded);
    } catch (_) {}
    return null;
  }

  static Future<Map<String, dynamic>?> submitProof({
    required int orderId,
    required String senderName,
    required String senderBank,
    required String senderAccountNumber,
    required double transferredAmount,
    required XFile proof,
    String? note,
  }) async {
    lastError = null;
    final request = http.MultipartRequest(
      'POST',
      Uri.parse('${ApiService.baseUrl}/orders/$orderId/payment-proof'),
    );
    request.headers['Accept'] = 'application/json';
    if (ApiService.token != null) {
      request.headers['Authorization'] = 'Bearer ${ApiService.token}';
    }
    request.fields.addAll({
      'sender_name': senderName.trim(),
      'sender_bank': senderBank.trim(),
      'sender_account_number': senderAccountNumber.trim(),
      'transferred_amount': transferredAmount.toStringAsFixed(2),
      'note': note?.trim() ?? '',
    });
    request.files.add(
      http.MultipartFile.fromBytes(
        'proof',
        await proof.readAsBytes(),
        filename: proof.name.isEmpty ? 'bukti_pembayaran.jpg' : proof.name,
      ),
    );

    try {
      final streamed = await request.send();
      final body = await streamed.stream.bytesToString();
      final decoded = _decodeMap(body);
      if (streamed.statusCode >= 200 && streamed.statusCode < 300) {
        return decoded;
      }
      lastError = _message(body, fallback: 'Bukti pembayaran gagal dikirim.');
      return decoded ?? {'success': false, 'message': lastError};
    } catch (error) {
      lastError = 'Tidak dapat mengirim bukti pembayaran: $error';
      return {'success': false, 'message': lastError};
    }
  }

  static Future<Map<String, dynamic>?> adminPayments({
    String status = 'all',
    String? search,
    int page = 1,
  }) async {
    lastError = null;
    final query = <String, String>{
      'status': status,
      'page': '$page',
      'per_page': '50',
      if (search != null && search.trim().isNotEmpty) 'search': search.trim(),
    };
    final uri = Uri.parse('${ApiService.baseUrl}/admin/manual-payments')
        .replace(queryParameters: query);
    try {
      final response = await http.get(uri, headers: _headers);
      final decoded = _decodeMap(response.body);
      if (response.statusCode == 200) return decoded;
      lastError = _message(
        response.body,
        fallback: 'Gagal memuat pembayaran user.',
      );
    } catch (error) {
      lastError = 'Gagal memuat pembayaran user: $error';
    }
    return null;
  }

  static Future<Map<String, dynamic>?> adminPaymentDetail(int orderId) async {
    lastError = null;
    try {
      final response = await http.get(
        Uri.parse('${ApiService.baseUrl}/admin/manual-payments/$orderId'),
        headers: _headers,
      );
      final decoded = _decodeMap(response.body);
      if (response.statusCode == 200 && decoded?['data'] is Map) {
        return Map<String, dynamic>.from(decoded!['data']);
      }
      lastError = _message(
        response.body,
        fallback: 'Gagal memuat detail pembayaran.',
      );
    } catch (error) {
      lastError = 'Gagal memuat detail pembayaran: $error';
    }
    return null;
  }

  static Future<List<Map<String, dynamic>>?> accounts() async {
    lastError = null;
    try {
      final response = await http.get(
        Uri.parse('${ApiService.baseUrl}/admin/manual-payment-accounts'),
        headers: _headers,
      );
      final decoded = _decodeMap(response.body);
      if (response.statusCode == 200 && decoded?['data'] is List) {
        return (decoded!['data'] as List)
            .whereType<Map>()
            .map((item) => Map<String, dynamic>.from(item))
            .toList();
      }
      lastError = _message(
        response.body,
        fallback: 'Gagal memuat rekening/VA tujuan.',
      );
    } catch (error) {
      lastError = 'Gagal memuat rekening/VA tujuan: $error';
    }
    return null;
  }

  static Future<bool> createAccount(Map<String, dynamic> payload) async {
    return _accountRequest(
      Uri.parse('${ApiService.baseUrl}/admin/manual-payment-accounts'),
      payload,
      method: 'POST',
    );
  }

  static Future<bool> updateAccount(
    int id,
    Map<String, dynamic> payload,
  ) async {
    return _accountRequest(
      Uri.parse('${ApiService.baseUrl}/admin/manual-payment-accounts/$id'),
      payload,
      method: 'PUT',
    );
  }

  static Future<bool> setPrimaryAccount(int id) async {
    return _accountRequest(
      Uri.parse(
        '${ApiService.baseUrl}/admin/manual-payment-accounts/$id/primary',
      ),
      const {},
      method: 'POST',
    );
  }

  static Future<bool> _accountRequest(
    Uri uri,
    Map<String, dynamic> payload, {
    required String method,
  }) async {
    lastError = null;
    try {
      final response = method == 'PUT'
          ? await http.put(uri, headers: _headers, body: jsonEncode(payload))
          : await http.post(uri, headers: _headers, body: jsonEncode(payload));
      if (response.statusCode >= 200 && response.statusCode < 300) return true;
      lastError = _message(
        response.body,
        fallback: 'Rekening/VA tujuan gagal disimpan.',
      );
    } catch (error) {
      lastError = 'Rekening/VA tujuan gagal disimpan: $error';
    }
    return false;
  }

  static Future<bool> approve(int orderId) =>
      _paymentAction(orderId, 'approve', const {});

  static Future<bool> reject(
    int orderId,
    String reason, {
    bool extendDeadline = true,
  }) => _paymentAction(orderId, 'reject', {
    'reason': reason,
    'extend_deadline': extendDeadline,
  });

  static Future<bool> cancel(int orderId, String reason) =>
      _paymentAction(orderId, 'cancel', {'reason': reason});

  static Future<bool> _paymentAction(
    int orderId,
    String action,
    Map<String, dynamic> payload,
  ) async {
    lastError = null;
    try {
      final response = await http.post(
        Uri.parse(
          '${ApiService.baseUrl}/admin/manual-payments/$orderId/$action',
        ),
        headers: _headers,
        body: jsonEncode(payload),
      );
      if (response.statusCode >= 200 && response.statusCode < 300) return true;
      lastError = _message(
        response.body,
        fallback: 'Tindakan pembayaran gagal diproses.',
      );
    } catch (error) {
      lastError = 'Tindakan pembayaran gagal diproses: $error';
    }
    return false;
  }
}

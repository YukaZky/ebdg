import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:image_picker/image_picker.dart';
import 'api_service.dart';

class MarketplaceApiService {
  static Map<String, String> get _headers => {
        'Accept': 'application/json',
        'Content-Type': 'application/json',
        if (ApiService.token != null) 'Authorization': 'Bearer ' + ApiService.token!,
      };

  static Map<String, dynamic>? _decodeMap(http.Response response) {
    try {
      final decoded = jsonDecode(response.body);
      if (decoded is Map<String, dynamic>) return decoded;
      if (decoded is Map) return Map<String, dynamic>.from(decoded);
    } catch (_) {}
    return null;
  }

  static Future<Map<String, dynamic>?> myStore() async {
    final response = await http.get(Uri.parse('${ApiService.baseUrl}/marketplace/my-store'), headers: _headers);
    if (response.statusCode == 200) return jsonDecode(response.body)['data'];
    return null;
  }

  static Future<Map<String, dynamic>?> saveStore(Map<String, dynamic> data, {XFile? logo, XFile? banner}) async {
    final request = http.MultipartRequest('POST', Uri.parse('${ApiService.baseUrl}/marketplace/my-store'));
    request.headers['Accept'] = 'application/json';
    if (ApiService.token != null) request.headers['Authorization'] = 'Bearer ' + ApiService.token!;

    data.forEach((key, value) {
      request.fields[key] = value?.toString() ?? '';
    });

    if (logo != null) {
      final bytes = await logo.readAsBytes();
      request.files.add(http.MultipartFile.fromBytes('logo', bytes, filename: logo.name.isEmpty ? 'store_logo.jpg' : logo.name));
    }

    if (banner != null) {
      final bytes = await banner.readAsBytes();
      request.files.add(http.MultipartFile.fromBytes('banner', bytes, filename: banner.name.isEmpty ? 'store_banner.jpg' : banner.name));
    }

    final response = await request.send();
    final body = await response.stream.bytesToString();
    if (response.statusCode == 200 || response.statusCode == 201) return jsonDecode(body)['data'];
    return null;
  }

  static Future<Map<String, dynamic>?> storeDetail(String slug) async {
    final response = await http.get(Uri.parse('${ApiService.baseUrl}/stores/$slug'), headers: {'Accept': 'application/json'});
    if (response.statusCode == 200) return jsonDecode(response.body)['data'];
    return null;
  }

  static Future<List<dynamic>> sellerOrders() async {
    final response = await http.get(Uri.parse('${ApiService.baseUrl}/marketplace/seller-orders'), headers: _headers);
    if (response.statusCode == 200) return jsonDecode(response.body)['data'] ?? [];
    return [];
  }

  static Future<bool> updateOrderStatus(int orderId, String status) async {
    final response = await http.put(
      Uri.parse('${ApiService.baseUrl}/marketplace/seller-orders/$orderId/status'),
      headers: _headers,
      body: jsonEncode({'status': status}),
    );
    return response.statusCode == 200;
  }

  static Future<Map<String, dynamic>?> sellerBalance() async {
    final response = await http.get(
      Uri.parse('${ApiService.baseUrl}/marketplace/seller-balance'),
      headers: _headers,
    );
    if (response.statusCode == 200) return jsonDecode(response.body)['data'];
    return null;
  }

  static Future<Map<String, dynamic>?> saveSellerBankAccount({
    required String bankName,
    required String bankAccountNumber,
    required String bankAccountName,
  }) async {
    final response = await http.post(
      Uri.parse('${ApiService.baseUrl}/marketplace/seller-bank-account'),
      headers: _headers,
      body: jsonEncode({
        'bank_name': bankName,
        'bank_account_number': bankAccountNumber,
        'bank_account_name': bankAccountName,
      }),
    );
    final decoded = _decodeMap(response);
    if ((response.statusCode == 200 || response.statusCode == 201) && decoded != null) return decoded['data'];
    return null;
  }

  static Future<Map<String, dynamic>?> requestWithdrawal({
    required double amount,
    String? bankName,
    String? bankAccountNumber,
    String? bankAccountName,
  }) async {
    final payload = <String, dynamic>{'amount': amount};
    if (bankName != null && bankName.trim().isNotEmpty) payload['bank_name'] = bankName.trim();
    if (bankAccountNumber != null && bankAccountNumber.trim().isNotEmpty) payload['bank_account_number'] = bankAccountNumber.trim();
    if (bankAccountName != null && bankAccountName.trim().isNotEmpty) payload['bank_account_name'] = bankAccountName.trim();

    final response = await http.post(
      Uri.parse('${ApiService.baseUrl}/marketplace/seller-withdrawals'),
      headers: _headers,
      body: jsonEncode(payload),
    );

    final decoded = _decodeMap(response);
    if (decoded != null) {
      decoded['http_status'] = response.statusCode;
      return decoded;
    }

    return {
      'success': false,
      'http_status': response.statusCode,
      'message': 'Gagal terhubung ke server. Status: ${response.statusCode}',
    };
  }

  static Future<List<dynamic>> productReviews(int productId) async {
    final response = await http.get(Uri.parse('${ApiService.baseUrl}/products/$productId/reviews'), headers: {'Accept': 'application/json'});
    if (response.statusCode == 200) return jsonDecode(response.body)['data'] ?? [];
    return [];
  }

  static Future<bool> addReview({required int productId, int? orderId, required int rating, String? review}) async {
    final response = await http.post(
      Uri.parse('${ApiService.baseUrl}/marketplace/reviews'),
      headers: _headers,
      body: jsonEncode({'product_id': productId, 'order_id': orderId, 'rating': rating, 'review': review}),
    );
    return response.statusCode == 200 || response.statusCode == 201;
  }

  static Future<List<dynamic>> conversations({String? role}) async {
    final cleanRole = role?.trim();
    final uri = Uri.parse('${ApiService.baseUrl}/marketplace/chats').replace(
      queryParameters: cleanRole == null || cleanRole.isEmpty ? null : {'role': cleanRole},
    );
    final response = await http.get(uri, headers: _headers);
    if (response.statusCode == 200) return jsonDecode(response.body)['data'] ?? [];
    return [];
  }

  static Future<Map<String, dynamic>?> startConversation({required int sellerId, int? productId}) async {
    final response = await http.post(
      Uri.parse('${ApiService.baseUrl}/marketplace/chats/start'),
      headers: _headers,
      body: jsonEncode({'seller_id': sellerId, 'product_id': productId}),
    );
    if (response.statusCode == 200 || response.statusCode == 201) return jsonDecode(response.body)['data'];
    return null;
  }

  static Future<List<dynamic>> messages(int conversationId) async {
    final response = await http.get(Uri.parse('${ApiService.baseUrl}/marketplace/chats/$conversationId/messages'), headers: _headers);
    if (response.statusCode == 200) return jsonDecode(response.body)['data'] ?? [];
    return [];
  }

  static Future<bool> sendMessage(int conversationId, String message) async {
    final response = await http.post(
      Uri.parse('${ApiService.baseUrl}/marketplace/chats/$conversationId/messages'),
      headers: _headers,
      body: jsonEncode({'message': message}),
    );
    return response.statusCode == 200 || response.statusCode == 201;
  }
}

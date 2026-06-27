import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:image_picker/image_picker.dart';
import 'api_service.dart';

class MarketplaceApiService {
  static String? lastError;

  static Map<String, String> get _headers => {
        'Accept': 'application/json',
        'Content-Type': 'application/json',
        if (ApiService.token != null) 'Authorization': 'Bearer ${ApiService.token}',
      };

  static String _messageFromBody(String body, {String fallback = 'Terjadi kesalahan.'}) {
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

  static Future<Map<String, dynamic>?> myStore() async {
    final response = await http.get(Uri.parse('${ApiService.baseUrl}/marketplace/my-store'), headers: _headers);
    if (response.statusCode == 200) return jsonDecode(response.body)['data'];
    return null;
  }

  static Future<Map<String, dynamic>?> saveStore(Map<String, dynamic> data, {XFile? logo, XFile? banner}) async {
    final request = http.MultipartRequest('POST', Uri.parse('${ApiService.baseUrl}/marketplace/my-store'));
    request.headers['Accept'] = 'application/json';
    if (ApiService.token != null) request.headers['Authorization'] = 'Bearer ${ApiService.token}';

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

  static Future<List<dynamic>> sellerCoupons() async {
    final response = await http.get(Uri.parse('${ApiService.baseUrl}/marketplace/coupons'), headers: _headers);
    if (response.statusCode == 200) return jsonDecode(response.body)['data'] ?? [];
    return [];
  }

  static Future<List<dynamic>> claimedCoupons() async {
    final response = await http.get(Uri.parse('${ApiService.baseUrl}/marketplace/coupons/claimed'), headers: _headers);
    if (response.statusCode == 200) return jsonDecode(response.body)['data'] ?? [];
    return [];
  }

  static Future<Map<String, dynamic>?> couponDetail(int id) async {
    final response = await http.get(Uri.parse('${ApiService.baseUrl}/marketplace/coupons/$id'), headers: _headers);
    if (response.statusCode == 200) return jsonDecode(response.body)['data'];
    return null;
  }

  static Future<Map<String, dynamic>?> saveCoupon(Map<String, dynamic> data, {int? id}) async {
    lastError = null;
    final uri = id == null ? Uri.parse('${ApiService.baseUrl}/marketplace/coupons') : Uri.parse('${ApiService.baseUrl}/marketplace/coupons/$id');
    final response = id == null
        ? await http.post(uri, headers: _headers, body: jsonEncode(data))
        : await http.put(uri, headers: _headers, body: jsonEncode(data));
    if (response.statusCode == 200 || response.statusCode == 201) return jsonDecode(response.body)['data'];
    lastError = _messageFromBody(response.body, fallback: 'Gagal menyimpan kupon. Kode: ${response.statusCode}');
    return null;
  }

  static Future<bool> deleteCoupon(int id) async {
    final response = await http.delete(Uri.parse('${ApiService.baseUrl}/marketplace/coupons/$id'), headers: _headers);
    return response.statusCode == 200;
  }

  static Future<List<dynamic>> storeCoupons(String slug) async {
    final authResponse = await http.get(Uri.parse('${ApiService.baseUrl}/marketplace/stores/$slug/coupons'), headers: _headers);
    if (authResponse.statusCode == 200) return jsonDecode(authResponse.body)['data'] ?? [];

    final publicResponse = await http.get(Uri.parse('${ApiService.baseUrl}/stores/$slug/coupons'), headers: {'Accept': 'application/json'});
    if (publicResponse.statusCode == 200) return jsonDecode(publicResponse.body)['data'] ?? [];
    return [];
  }

  static Future<Map<String, dynamic>?> takeCoupon(int id) async {
    lastError = null;
    final response = await http.post(Uri.parse('${ApiService.baseUrl}/marketplace/coupons/$id/take'), headers: _headers);
    if (response.statusCode == 200 || response.statusCode == 201) return jsonDecode(response.body)['coupon'] ?? jsonDecode(response.body)['data'];
    lastError = _messageFromBody(response.body, fallback: 'Gagal mengambil kupon. Kode: ${response.statusCode}');
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
    final uri = Uri.parse('${ApiService.baseUrl}/marketplace/chats').replace(queryParameters: cleanRole == null || cleanRole.isEmpty ? null : {'role': cleanRole});
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

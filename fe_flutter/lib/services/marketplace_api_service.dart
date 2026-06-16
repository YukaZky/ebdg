import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:image_picker/image_picker.dart';
import 'api_service.dart';

class MarketplaceApiService {
  static Map<String, String> get _headers => {
        'Accept': 'application/json',
        'Content-Type': 'application/json',
        if (ApiService.token != null) 'Authorization': 'Bearer ${ApiService.token}',
      };

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

  static Future<List<dynamic>> conversations() async {
    final response = await http.get(Uri.parse('${ApiService.baseUrl}/marketplace/chats'), headers: _headers);
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

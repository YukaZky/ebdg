import 'dart:convert';
import 'package:http/http.dart' as http;
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

  static Future<Map<String, dynamic>?> saveStore(Map<String, dynamic> data) async {
    final response = await http.post(Uri.parse('${ApiService.baseUrl}/marketplace/my-store'), headers: _headers, body: jsonEncode(data));
    if (response.statusCode == 200 || response.statusCode == 201) return jsonDecode(response.body)['data'];
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

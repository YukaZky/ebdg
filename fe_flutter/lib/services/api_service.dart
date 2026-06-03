import 'dart:convert';
import 'package:http/http.dart' as http;
import '../models/product_model.dart';

class ApiService {
  // Ganti dengan domain production Anda atau IP 10.0.2.2 jika menggunakan emulator Android lokal
  static const String baseUrl = "http://127.0.0.1:8000/api";
  static String? _token;

  // Fungsi Login
  static Future<bool> login(String email, String password) async {
    final response = await http.post(
      Uri.parse("$baseUrl/login"),
      headers: {"Content-Type": "application/json"},
      body: jsonEncode({"email": email, "password": password}),
    );

    if (response.statusCode == 200) {
      final data = jsonDecode(response.body);
      _token = data['access_token'];
      return true;
    }
    return false;
  }

  // Fungsi Mengambil Daftar Produk
  static Future<List<Product>> getProducts() async {
    final response = await http.get(Uri.parse("$baseUrl/products"));

    if (response.statusCode == 200) {
      final Map<String, dynamic> responseData = jsonDecode(response.body);
      final List<dynamic> productsJson = responseData['data'];
      return productsJson.map((json) => Product.fromJson(json)).toList();
    } else {
      throw Exception("Gagal memuat produk");
    }
  }
  // ... (kode fungsi getProducts & login sebelumnya)

  // Ambil Token yang tersimpan
  static String? get token => _token;

  // Fungsi Mengambil Detail Produk
  static Future<Product?> getProductDetails(String slug) async {
    final response = await http.get(Uri.parse("$baseUrl/products/$slug"));
    if (response.statusCode == 200) {
      final Map<String, dynamic> data = jsonDecode(response.body);
      return Product.fromJson(data['data']);
    }
    return null;
  }

  // Fungsi Tambah ke Keranjang
  static Future<bool> addToCart(int productId, int quantity) async {
    if (_token == null) return false;

    final response = await http.post(
      Uri.parse("$baseUrl/cart/add"),
      headers: {
        "Content-Type": "application/json",
        "Authorization": "Bearer $_token"
      },
      body: jsonEncode({
        "product_id": productId,
        "quantity": quantity
      }),
    );

    return response.statusCode == 200;
  }

  // Fungsi Ambil Keranjang
  static Future<Map<String, dynamic>> getCart() async {
    if (_token == null) throw Exception("Belum login");

    final response = await http.get(
      Uri.parse("$baseUrl/cart"),
      headers: {
        "Accept": "application/json",
        "Authorization": "Bearer $_token"
      },
    );

    if (response.statusCode == 200) {
      return jsonDecode(response.body);
    } else {
      throw Exception("Gagal memuat keranjang");
    }
  }
  // Fungsi Checkout
  static Future<String?> checkout(String address, String phone) async {
    if (_token == null) throw Exception("Belum login");

    final response = await http.post(
      Uri.parse("$baseUrl/checkout"),
      headers: {
        "Content-Type": "application/json",
        "Authorization": "Bearer $_token"
      },
      body: jsonEncode({
        "address": address,
        "phone": phone
      }),
    );

    if (response.statusCode == 200) {
      final data = jsonDecode(response.body);
      return data['payment_url']; // Mengembalikan URL pembayaran Midtrans
    } else {
      return null;
    }
  }
  // Fungsi Mengambil Riwayat Pesanan
  static Future<List<dynamic>> getOrders() async {
    if (_token == null) throw Exception("Belum login");

    final response = await http.get(
      Uri.parse("$baseUrl/orders"),
      headers: {
        "Accept": "application/json",
        "Authorization": "Bearer $_token"
      },
    );

    if (response.statusCode == 200) {
      final Map<String, dynamic> data = jsonDecode(response.body);
      return data['data'];
    } else {
      throw Exception("Gagal memuat riwayat pesanan");
    }
  }
}
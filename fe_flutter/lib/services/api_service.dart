import 'dart:convert';
import 'package:http/http.dart' as http;
import '../models/product_model.dart';

class ApiService {
  static const String baseUrl = "http://127.0.0.1:8000/api";
  static String? _token;

  static String? get token => _token;

  // ==========================================
  // FUNGSI AUTENTIKASI
  // ==========================================
  static Future<bool> login(String email, String password) async {
    try {
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
    } catch (e) {
      print("Error Login: $e");
      return false;
    }
  }

  static Future<bool> register(String name, String email, String password, String passwordConfirmation) async {
    final response = await http.post(
      Uri.parse("$baseUrl/register"),
      headers: {"Content-Type": "application/json"},
      body: jsonEncode({
        "name": name,
        "email": email,
        "password": password,
        "password_confirmation": passwordConfirmation
      }),
    );

    if (response.statusCode == 201 || response.statusCode == 200) {
      return true;
    }
    return false;
  }

  // ==========================================
  // FUNGSI PRODUK
  // ==========================================
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

  static Future<Product?> getProductDetails(String slug) async {
    final response = await http.get(Uri.parse("$baseUrl/products/$slug"));
    if (response.statusCode == 200) {
      final Map<String, dynamic> data = jsonDecode(response.body);
      return Product.fromJson(data['data']);
    }
    return null;
  }

  // ==========================================
  // FUNGSI KERANJANG
  // ==========================================
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

  static Future<bool> removeFromCart(int id) async {
    if (_token == null) return false;

    final response = await http.delete(
      Uri.parse("$baseUrl/cart/remove/$id"),
      headers: {
        "Accept": "application/json",
        "Authorization": "Bearer $_token"
      },
    );

    return response.statusCode == 200;
  }

  // ==========================================
  // FUNGSI RIWAYAT PESANAN
  // ==========================================
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

  static Future<Map<String, dynamic>?> getUserProfile() async {
    if (_token == null) return null;

    final response = await http.get(
      Uri.parse("$baseUrl/user-profile"),
      headers: {
        "Accept": "application/json",
        "Authorization": "Bearer $_token"
      },
    );

    if (response.statusCode == 200) {
      return jsonDecode(response.body);
    }
    return null;
  }

  static Future<bool> logout() async {
    if (_token == null) return false;

    final response = await http.post(
      Uri.parse("$baseUrl/logout"),
      headers: {
        "Accept": "application/json",
        "Authorization": "Bearer $_token"
      },
    );

    if (response.statusCode == 200) {
      _token = null; 
      return true;
    }
    return false;
  }

  // ==========================================
  // FUNGSI WISHLIST
  // ==========================================
  static Future<List<Product>> getWishlist() async {
    if (_token == null) return [];
    
    final response = await http.get(
      Uri.parse("$baseUrl/wishlist"),
      headers: {
        "Accept": "application/json",
        "Authorization": "Bearer $_token"
      },
    );

    if (response.statusCode == 200) {
      final Map<String, dynamic> data = jsonDecode(response.body);
      List<dynamic> wishlistData = data['data'] ?? [];
      
      return wishlistData.map((item) => Product.fromJson(item['product'])).toList();
    } else {
      return [];
    }
  }

  static Future<bool> addToWishlist(int productId) async {
    if (_token == null) return false;

    final response = await http.post(
      Uri.parse("$baseUrl/wishlist/add"),
      headers: {
        "Content-Type": "application/json",
        "Accept": "application/json",
        "Authorization": "Bearer $_token"
      },
      body: jsonEncode({"product_id": productId}),
    );

    return response.statusCode == 200 || response.statusCode == 201;
  }

  static Future<bool> removeFromWishlist(int productId) async {
    if (_token == null) return false;

    final response = await http.delete(
      Uri.parse("$baseUrl/wishlist/remove/$productId"),
      headers: {
        "Accept": "application/json",
        "Authorization": "Bearer $_token"
      },
    );

    return response.statusCode == 200;
  }

  // ==========================================
  // FUNGSI RAJAONGKIR
  // ==========================================
  static Future<List<dynamic>> getProvinces() async {
    if (_token == null) return [];
    
    final response = await http.get(
      Uri.parse("$baseUrl/rajaongkir/provinces"),
      headers: {"Authorization": "Bearer $_token"}
    );
    return response.statusCode == 200 ? jsonDecode(response.body) : [];
  }

  static Future<List<dynamic>> getCities(String provinceId) async {
    if (_token == null) return [];

    final response = await http.get(
      Uri.parse("$baseUrl/rajaongkir/cities/$provinceId"),
      headers: {"Authorization": "Bearer $_token"}
    );
    return response.statusCode == 200 ? jsonDecode(response.body) : [];
  }

  static Future<List<dynamic>> checkCost(String destinationCityId, int weight, String courier) async {
    if (_token == null) return [];

    final response = await http.post(
      Uri.parse("$baseUrl/rajaongkir/cost"),
      headers: {
        "Content-Type": "application/json", 
        "Authorization": "Bearer $_token"
      },
      body: jsonEncode({
        "destination": destinationCityId,
        "weight": weight,
        "courier": courier,
      }),
    );
    return response.statusCode == 200 ? jsonDecode(response.body) : [];
  }

  static Future<String?> checkout(String address, String phone, String provinceName, String cityName, String courier, double shippingCost) async {
    if (_token == null) throw Exception("Belum login");

    final response = await http.post(
      Uri.parse("$baseUrl/checkout"),
      headers: {
        "Content-Type": "application/json", 
        "Authorization": "Bearer $_token"
      },
      body: jsonEncode({
        "address": address, 
        "phone": phone,
        "province_name": provinceName, 
        "city_name": cityName,
        "courier": courier, 
        "shipping_cost": shippingCost
      }),
    );
    
    if (response.statusCode == 200) {
       return jsonDecode(response.body)['payment_url'];
    } else {
       print("Gagal Checkout: ${response.body}");
       return null;
    }
  }

  // ==========================================
  // FUNGSI ADMIN PANEL (TOKO SAYA)
  // ==========================================

  // Ambil Data Statistik Dashboard Admin
  static Future<Map<String, dynamic>?> getAdminDashboardStats() async {
    if (_token == null) return null;
    try {
      final response = await http.get(
        Uri.parse("$baseUrl/admin/dashboard"),
        headers: {
          "Accept": "application/json",
          "Authorization": "Bearer $_token"
        },
      );
      if (response.statusCode == 200) return jsonDecode(response.body);
    } catch (e) {
      print("Admin Error: $e");
    }
    return null;
  }

  // Ambil Semua Produk Admin
  static Future<List<dynamic>> getAdminProducts() async {
    if (_token == null) return [];
    final response = await http.get(Uri.parse("$baseUrl/admin/products"), headers: {"Authorization": "Bearer $_token"});
    if (response.statusCode == 200) return jsonDecode(response.body)['data'] ?? [];
    return [];
  }

  // Tambah Produk Baru
  static Future<bool> addAdminProduct(Map<String, dynamic> productData) async {
    if (_token == null) return false;
    final response = await http.post(
      Uri.parse("$baseUrl/admin/products/store"),
      headers: {"Content-Type": "application/json", "Authorization": "Bearer $_token"},
      body: jsonEncode(productData),
    );
    return response.statusCode == 201;
  }

  // Hapus Produk
  static Future<bool> deleteAdminProduct(int id) async {
    if (_token == null) return false;
    final response = await http.delete(Uri.parse("$baseUrl/admin/products/delete/$id"), headers: {"Authorization": "Bearer $_token"});
    return response.statusCode == 200;
  }

  // Ambil Semua Pesanan Masuk
  static Future<List<dynamic>> getAdminOrders() async {
    if (_token == null) return [];
    final response = await http.get(Uri.parse("$baseUrl/admin/orders"), headers: {"Authorization": "Bearer $_token"});
    if (response.statusCode == 200) return jsonDecode(response.body)['data'] ?? [];
    return [];
  }

  // Update Status Pesanan (ordered, delivered, canceled)
  static Future<bool> updateAdminOrderStatus(int orderId, String status) async {
    if (_token == null) return false;
    final response = await http.put(
      Uri.parse("$baseUrl/admin/orders/update-status/$orderId"),
      headers: {"Content-Type": "application/json", "Authorization": "Bearer $_token"},
      body: jsonEncode({"status": status}),
    );
    return response.statusCode == 200;
  }

  // Ambil Kupon Diskon
  static Future<List<dynamic>> getAdminCoupons() async {
    if (_token == null) return [];
    final response = await http.get(Uri.parse("$baseUrl/admin/coupons"), headers: {"Authorization": "Bearer $_token"});
    return response.statusCode == 200 ? jsonDecode(response.body)['data'] : [];
  }

  // Ambil Pesan Masuk (Kontak)
  static Future<List<dynamic>> getAdminContacts() async {
    if (_token == null) return [];
    final response = await http.get(Uri.parse("$baseUrl/admin/contacts"), headers: {"Authorization": "Bearer $_token"});
    return response.statusCode == 200 ? jsonDecode(response.body)['data'] : [];
  }

  // Update Produk (Edit)
  static Future<bool> updateAdminProduct(int id, Map<String, dynamic> productData) async {
    if (_token == null) return false;
    final response = await http.put(
      Uri.parse("$baseUrl/admin/products/update/$id"),
      headers: {"Content-Type": "application/json", "Authorization": "Bearer $_token"},
      body: jsonEncode(productData),
    );
    return response.statusCode == 200;
  }

  // Ambil Kategori untuk Dropdown
  static Future<List<dynamic>> getAdminCategories() async {
    if (_token == null) return [];
    final response = await http.get(Uri.parse("$baseUrl/admin/categories"), headers: {"Authorization": "Bearer $_token"});
    return response.statusCode == 200 ? jsonDecode(response.body)['data'] ?? [] : [];
  }

  // Ambil Brand untuk Dropdown
  static Future<List<dynamic>> getAdminBrands() async {
    if (_token == null) return [];
    final response = await http.get(Uri.parse("$baseUrl/admin/brands"), headers: {"Authorization": "Bearer $_token"});
    return response.statusCode == 200 ? jsonDecode(response.body)['data'] ?? [] : [];
  }
}
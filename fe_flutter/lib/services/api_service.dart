// ignore_for_file: avoid_print

import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:image_picker/image_picker.dart';
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

  static Future<bool> register(String name, String email, String password,
      String passwordConfirmation) async {
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
      body: jsonEncode({"product_id": productId, "quantity": quantity}),
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

  static Future<Map<String, dynamic>?> updateUserProfile({
    required String name,
    required String email,
    String? phone,
    String? currentPassword,
    String? password,
    String? passwordConfirmation,
  }) async {
    if (_token == null) return null;

    final body = <String, dynamic>{
      'name': name,
      'email': email,
      'phone': phone ?? '',
    };

    if (password != null && password.isNotEmpty) {
      body['current_password'] = currentPassword ?? '';
      body['password'] = password;
      body['password_confirmation'] = passwordConfirmation ?? '';
    }

    final response = await http.put(
      Uri.parse("$baseUrl/user-profile"),
      headers: {
        "Content-Type": "application/json",
        "Accept": "application/json",
        "Authorization": "Bearer $_token"
      },
      body: jsonEncode(body),
    );

    if (response.statusCode == 200) {
      final data = jsonDecode(response.body);
      return data['data'];
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

      return wishlistData
          .map((item) => Product.fromJson(item['product']))
          .toList();
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
  // FUNGSI BUKU ALAMAT PENGGUNA
  // ==========================================

  static Future<List<dynamic>> getUserAddresses() async {
    if (_token == null) return [];
    try {
      final response = await http.get(
        Uri.parse("$baseUrl/user/addresses"),
        headers: {"Accept": "application/json", "Authorization": "Bearer $_token"},
      );
      if (response.statusCode == 200) {
        return jsonDecode(response.body)['data'] ?? [];
      }
    } catch (e) {
      print("Error get addresses: $e");
    }
    return [];
  }

  static Future<bool> saveUserAddress(Map<String, dynamic> addressData) async {
    if (_token == null) return false;
    try {
      final response = await http.post(
        Uri.parse("$baseUrl/user/addresses"),
        headers: {"Content-Type": "application/json", "Accept": "application/json", "Authorization": "Bearer $_token"},
        body: jsonEncode(addressData),
      );
      return response.statusCode == 200 || response.statusCode == 201;
    } catch (e) {
      return false;
    }
  }

  static Future<bool> setMainAddress(int id) async {
    if (_token == null) return false;
    try {
      final response = await http.put(
        Uri.parse("$baseUrl/user/addresses/$id/set-main"),
        headers: {"Accept": "application/json", "Authorization": "Bearer $_token"},
      );
      return response.statusCode == 200;
    } catch (e) {
      return false;
    }
  }

  static Future<bool> deleteUserAddress(int id) async {
    if (_token == null) return false;
    try {
      final response = await http.delete(
        Uri.parse("$baseUrl/user/addresses/$id"),
        headers: {"Accept": "application/json", "Authorization": "Bearer $_token"},
      );
      return response.statusCode == 200;
    } catch (e) {
      return false;
    }
  }

  // ==========================================
  // FUNGSI RAJAONGKIR
  // ==========================================
  static Future<List<dynamic>> getProvinces() async {
    if (_token == null) return [];

    final response = await http.get(Uri.parse("$baseUrl/rajaongkir/provinces"),
        headers: {
          "Accept": "application/json",
          "Authorization": "Bearer $_token"
        });
    return response.statusCode == 200 ? jsonDecode(response.body) : [];
  }

  static Future<List<dynamic>> getCities(String provinceId) async {
    if (_token == null) return [];

    final response = await http
        .get(Uri.parse("$baseUrl/rajaongkir/cities/$provinceId"), headers: {
      "Accept": "application/json",
      "Authorization": "Bearer $_token"
    });
    return response.statusCode == 200 ? jsonDecode(response.body) : [];
  }

  static Future<List<dynamic>> getSubdistricts(String cityId) async {
    if (_token == null) return [];
    try {
      final response = await http.get(
        Uri.parse("$baseUrl/rajaongkir/subdistricts/$cityId"),
        headers: {
          "Accept": "application/json",
          "Authorization": "Bearer $_token"
        }
      );
      if (response.statusCode == 200) {
        var data = jsonDecode(response.body);
        if (data is Map && data.containsKey('data')) return data['data'];
        if (data is List) return data;
        return data;
      }
    } catch (e) {
      print("Error get subdistricts: $e");
    }
    return [];
  }

  static Future<List<dynamic>> checkCost(
      String destinationCityId, int weight, String courier) async {
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

  static Future<Map<String, dynamic>?> checkout(
      String address,
      String phone,
      String provinceName,
      String cityName,
      String courier,
      double shippingCost,
      List<Map<String, dynamic>> cartItems) async {
    if (_token == null) throw Exception("Belum login");

    List<Map<String, dynamic>> formattedItems = cartItems.map((item) {
      return {
        "product_id": item['product']['id'],
        "quantity": item['quantity'],
        "options": item['isChecked'] ?? null 
      };
    }).toList();

    try {
      final response = await http.post(
        Uri.parse("$baseUrl/checkout"),
        headers: {
          "Content-Type": "application/json",
          "Accept": "application/json",
          "Authorization": "Bearer $_token"
        },
        body: jsonEncode({
          "address": address,
          "phone": phone,
          "province_name": provinceName,
          "city_name": cityName,
          "courier": courier,
          "shipping_cost": shippingCost,
          "items": formattedItems 
        }),
      );

      if (response.statusCode == 200) {
        return jsonDecode(response.body);
      } else {
        print("Gagal Checkout: ${response.body}");
        return null;
      }
    } catch (e) {
      print("Error Checkout: $e");
      return null;
    }
  }
  
  // ==========================================
  // FUNGSI ADMIN PANEL (TOKO SAYA)
  // ==========================================

  static Future<Map<String, dynamic>?> getAdminDashboardStats() async {
    if (_token == null) return null;
    final response = await http.get(Uri.parse("$baseUrl/admin/dashboard"), headers: {
      "Accept": "application/json", "Authorization": "Bearer $_token"
    });
    return response.statusCode == 200 ? jsonDecode(response.body) : null;
  }

  static Future<List<dynamic>> getAdminProducts() async {
    if (_token == null) return [];
    final response = await http.get(Uri.parse("$baseUrl/admin/products"), headers: {"Accept": "application/json", "Authorization": "Bearer $_token"});
    if (response.statusCode == 200) return jsonDecode(response.body)['data'];
    return [];
  }

  static Future<bool> deleteAdminProduct(int id) async {
    if (_token == null) return false;
    final response = await http.delete(Uri.parse("$baseUrl/admin/products/delete/$id"), headers: {"Accept": "application/json", "Authorization": "Bearer $_token"});
    return response.statusCode == 200;
  }

  static Future<List<dynamic>> getAdminCategories() async {
    if (_token == null) return [];
    final response = await http.get(Uri.parse("$baseUrl/admin/categories"), headers: {"Accept": "application/json", "Authorization": "Bearer $_token"});
    if (response.statusCode == 200) return jsonDecode(response.body)['data'];
    return [];
  }

  static Future<List<dynamic>> getAdminBrands() async {
    if (_token == null) return [];
    final response = await http.get(Uri.parse("$baseUrl/admin/brands"), headers: {"Accept": "application/json", "Authorization": "Bearer $_token"});
    if (response.statusCode == 200) return jsonDecode(response.body)['data'];
    return [];
  }

  static Future<bool> saveAdminProduct(Map<String, dynamic> data, {XFile? image, List<XFile>? variationImages}) async {
    if (_token == null) return false;
    var request = http.MultipartRequest('POST', Uri.parse(data['id'] != null ? "$baseUrl/admin/products/update/${data['id']}" : "$baseUrl/admin/products/store"));
    if (data['id'] != null) request.fields['_method'] = 'PUT';
    request.headers['Authorization'] = "Bearer $_token";

    data.forEach((key, value) {
      if (value != null && key != 'id') {
        if (value is List) {
          for (var i = 0; i < value.length; i++) {
            request.fields['${key}[$i]'] = value[i].toString();
          }
        } else {
          request.fields[key] = value.toString();
        }
      }
    });

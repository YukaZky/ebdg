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

  static Future<Map<String, dynamic>?> getAdminStoreLocation() async {
    if (_token == null) return null;
    try {
      final response = await http.get(
        Uri.parse("$baseUrl/admin/store-location"),
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

  static Future<bool> saveAdminStoreLocation(Map<String, dynamic> addressData) async {
    if (_token == null) return false;
    try {
      final response = await http.post(
        Uri.parse("$baseUrl/admin/store-location"),
        headers: {
          "Content-Type": "application/json",
          "Accept": "application/json",
          "Authorization": "Bearer $_token"
        },
        body: jsonEncode(addressData),
      );
      return response.statusCode == 200 || response.statusCode == 201;
    } catch (e) {
      print("Admin Error: $e");
      return false;
    }
  }

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

  static Future<List<dynamic>> getAdminProducts() async {
    if (_token == null) return [];
    final response = await http.get(Uri.parse("$baseUrl/admin/products"),
        headers: {"Authorization": "Bearer $_token"});
    if (response.statusCode == 200) {
      return jsonDecode(response.body)['data'] ?? [];
    }
    return [];
  }

  static Future<bool> saveAdminProduct(Map<String, String> fields,
      {XFile? mainImage, 
       List<XFile>? galleryImages, 
       List<String>? keptGalleryImageIds, 
       int? productId,
       List<String>? variationNames,
       List<XFile?>? variationImages,
       List<String>? variationIds,
       List<String>? variationRegularPrices,
       List<String>? variationSalePrices,
       List<String>? variationWeights,
       List<String>? variationQuantities,
      }) async {
    if (_token == null) return false;

    var uri = productId == null
        ? Uri.parse("$baseUrl/admin/products/store")
        : Uri.parse("$baseUrl/admin/products/update/$productId");

    var request = http.MultipartRequest('POST', uri);

    request.headers.addAll({
      "Authorization": "Bearer $_token",
      "Accept": "application/json",
    });

    if (productId != null) {
      request.fields['_method'] = 'PUT';
    }

    request.fields.addAll(fields);

    if (keptGalleryImageIds != null && keptGalleryImageIds.isNotEmpty) {
      for (int i = 0; i < keptGalleryImageIds.length; i++) {
        request.fields['kept_gallery_ids[$i]'] = keptGalleryImageIds[i];
      }
    } else if (productId != null) {
      request.fields['kept_gallery_ids_empty'] = '1';
    }

    if (mainImage != null) {
      request.files.add(http.MultipartFile.fromBytes(
        'image',
        await mainImage.readAsBytes(),
        filename: mainImage.name,
      ));
    }

    if (galleryImages != null && galleryImages.isNotEmpty) {
      for (var file in galleryImages) {
        request.files.add(http.MultipartFile.fromBytes(
          'images[]',
          await file.readAsBytes(),
          filename: file.name,
        ));
      }
    }

    if (variationNames != null && variationNames.isNotEmpty) {
      for (int i = 0; i < variationNames.length; i++) {
        request.fields['variation_names[$i]'] = variationNames[i];
        
        if (variationIds != null && i < variationIds.length) {
          request.fields['variation_ids[$i]'] = variationIds[i];
        }
        
        if (variationRegularPrices != null && i < variationRegularPrices.length) {
          request.fields['variation_regular_prices[$i]'] = variationRegularPrices[i].isEmpty ? '0' : variationRegularPrices[i];
        }
        
        if (variationSalePrices != null && i < variationSalePrices.length) {
          request.fields['variation_sale_prices[$i]'] = variationSalePrices[i]; 
        }
        
        if (variationWeights != null && i < variationWeights.length) {
          request.fields['variation_weights[$i]'] = variationWeights[i].isEmpty ? '0' : variationWeights[i];
        }
        
        if (variationQuantities != null && i < variationQuantities.length) {
          request.fields['variation_quantities[$i]'] = variationQuantities[i].isEmpty ? '0' : variationQuantities[i];
        }

        if (variationImages != null && i < variationImages.length && variationImages[i] != null) {
          request.files.add(http.MultipartFile.fromBytes(
            'variation_images[$i]',
            await variationImages[i]!.readAsBytes(),
            filename: variationImages[i]!.name,
          ));
        }
      }
    }

    try {
      final response = await request.send();
      if (response.statusCode == 200 || response.statusCode == 201) {
        return true;
      } else {
        final respStr = await response.stream.bytesToString();
        print("Error API saveAdminProduct [${response.statusCode}]: $respStr");
        return false;
      }
    } catch (e) {
      print("Exception API saveAdminProduct: $e");
      return false;
    }
  }

  static Future<bool> deleteAdminProduct(int id) async {
    if (_token == null) return false;
    final response = await http.delete(
        Uri.parse("$baseUrl/admin/products/delete/$id"),
        headers: {"Authorization": "Bearer $_token"});
    return response.statusCode == 200;
  }

  static Future<List<dynamic>> getAdminCategories() async {
    if (_token == null) return [];
    final response = await http.get(Uri.parse("$baseUrl/admin/categories"),
        headers: {"Authorization": "Bearer $_token"});
    return response.statusCode == 200
        ? jsonDecode(response.body)['data'] ?? []
        : [];
  }

  static Future<List<dynamic>> getAdminBrands() async {
    if (_token == null) return [];
    final response = await http.get(Uri.parse("$baseUrl/admin/brands"),
        headers: {"Authorization": "Bearer $_token"});
    return response.statusCode == 200
        ? jsonDecode(response.body)['data'] ?? []
        : [];
  }

  static Future<List<dynamic>> getAdminOrders() async {
    if (_token == null) return [];
    final response = await http.get(Uri.parse("$baseUrl/admin/orders"),
        headers: {"Authorization": "Bearer $_token"});
    if (response.statusCode == 200) {
      return jsonDecode(response.body)['data'] ?? [];
    }
    return [];
  }

  static Future<bool> updateAdminOrderStatus(int orderId, String status) async {
    if (_token == null) return false;
    final response = await http.put(
      Uri.parse("$baseUrl/admin/orders/update-status/$orderId"),
      headers: {
        "Content-Type": "application/json",
        "Authorization": "Bearer $_token"
      },
      body: jsonEncode({"status": status}),
    );
    return response.statusCode == 200;
  }

  static Future<List<dynamic>> getAdminCoupons() async {
    if (_token == null) return [];
    final response = await http.get(Uri.parse("$baseUrl/admin/coupons"),
        headers: {"Authorization": "Bearer $_token"});
    return response.statusCode == 200 ? jsonDecode(response.body)['data'] : [];
  }

  static Future<List<dynamic>> getAdminContacts() async {
    if (_token == null) return [];
    final response = await http.get(Uri.parse("$baseUrl/admin/contacts"),
        headers: {"Authorization": "Bearer $_token"});
    return response.statusCode == 200 ? jsonDecode(response.body)['data'] : [];
  }

  static Future<bool> saveAdminCategory(Map<String, String> fields,
      {XFile? image, int? categoryId}) async {
    if (_token == null) return false;

    var uri = categoryId == null
        ? Uri.parse("$baseUrl/admin/categories/store")
        : Uri.parse("$baseUrl/admin/categories/update/$categoryId");

    var request = http.MultipartRequest('POST', uri);
    request.headers.addAll(
        {"Authorization": "Bearer $_token", "Accept": "application/json"});

    if (categoryId != null) request.fields['_method'] = 'PUT';
    request.fields.addAll(fields);

    if (image != null) {
      request.files.add(http.MultipartFile.fromBytes(
        'image',
        await image.readAsBytes(),
        filename: image.name,
      ));
    }

    final response = await request.send();
    return response.statusCode == 200 || response.statusCode == 201;
  }

  static Future<bool> deleteAdminCategory(int id) async {
    if (_token == null) return false;
    final response = await http.delete(
        Uri.parse("$baseUrl/admin/categories/delete/$id"),
        headers: {"Authorization": "Bearer $_token"});
    return response.statusCode == 200;
  }

  static Future<bool> saveAdminBrand(Map<String, String> fields,
      {XFile? image, int? brandId}) async {
    if (_token == null) return false;

    var uri = brandId == null
        ? Uri.parse("$baseUrl/admin/brands/store")
        : Uri.parse("$baseUrl/admin/brands/update/$brandId");

    var request = http.MultipartRequest('POST', uri);
    request.headers.addAll(
        {"Authorization": "Bearer $_token", "Accept": "application/json"});

    if (brandId != null) request.fields['_method'] = 'PUT';
    request.fields.addAll(fields);

    if (image != null) {
      request.files.add(http.MultipartFile.fromBytes(
        'image',
        await image.readAsBytes(),
        filename: image.name,
      ));
    }

    final response = await request.send();
    return response.statusCode == 200 || response.statusCode == 201;
  }

  static Future<bool> deleteAdminBrand(int id) async {
    if (_token == null) return false;
    final response = await http.delete(
        Uri.parse("$baseUrl/admin/brands/delete/$id"),
        headers: {"Authorization": "Bearer $_token"});
    return response.statusCode == 200;
  }
}
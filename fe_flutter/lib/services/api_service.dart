// ignore_for_file: avoid_print

import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:image_picker/image_picker.dart';
import '../models/product_model.dart';
import '../models/payment_method_model.dart';

class ApiService {
  static const String baseUrl = "https://plug-unlined-smugness.ngrok-free.dev/api";
  static String? _token;

  static String? get token => _token;

  static Map<String, String> get _authHeaders => {
        "Accept": "application/json",
        if (_token != null) "Authorization": "Bearer $_token",
      };

  static Map<String, String> get _jsonHeaders => {
        "Content-Type": "application/json",
        "Accept": "application/json",
        if (_token != null) "Authorization": "Bearer $_token",
      };

  static Future<bool> login(String email, String password) async {
    try {
      final response = await http.post(
        Uri.parse("$baseUrl/login"),
        headers: _jsonHeaders,
        body: jsonEncode({"email": email, "password": password}),
      );
      print("=== RESPONSE BODY ===");
      print(response.body);
      print("=====================");
      
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
    try {
      final response = await http.post(
        Uri.parse("$baseUrl/register"),
        headers: _jsonHeaders,
        body: jsonEncode({
          "name": name,
          "email": email,
          "password": password,
          "password_confirmation": passwordConfirmation,
        }),
      );
      return response.statusCode == 201 || response.statusCode == 200;
    } catch (e) {
      return false;
    }
  }

  static Future<List<Product>> getProducts() async {
    try {
      print("=== DEBUG 1: Mulai request ke API getProducts ===");
      print("=== DEBUG 1: URL Target: $baseUrl/products ===");

      final response = await http.get(
        Uri.parse("$baseUrl/products"),
        headers: {"Accept": "application/json"},
      );

      print("=== RESPONSE BODY ===");
      print(response.body);
      print("=====================");

      print(
          "=== DEBUG 2: Request selesai. Status Code: ${response.statusCode} ===");
      // print("=== DEBUG 2.1: Response Body: ${response.body}"); // Hapus tanda komentar (//) di awal baris ini jika Anda ingin melihat mentahan teks JSON-nya.

      if (response.statusCode == 200) {
        print("=== DEBUG 3: Status 200 OK. Memulai decode JSON ===");
        final Map<String, dynamic> responseData = jsonDecode(response.body);

        print("=== DEBUG 4: Mengambil isi dari key 'data' ===");
        final List<dynamic> productsJson = responseData['data'] ?? [];

        print(
            "=== DEBUG 5: Sukses mengambil List. Jumlah produk di JSON: ${productsJson.length} ===");
        print("=== DEBUG 6: Memulai proses mapping JSON ke Model Flutter ===");

        // Memecah proses mapping agar kita tahu jika ada error spesifik pada salah satu produk
        final List<Product> result = productsJson.map((json) {
          try {
            return Product.fromJson(Map<String, dynamic>.from(json));
          } catch (e) {
            print("=== ERROR PARSING PADA ITEM: $json ===");
            print("=== PENYEBAB ERROR PARSING: $e ===");
            rethrow; // Lempar ulang errornya agar masuk ke blok catch utama
          }
        }).toList();

        print(
            "=== DEBUG 7: SUKSES TOTAL! Berhasil mengubah ${result.length} produk ke dalam Model. Siap dikirim ke UI. ===");
        return result;
      } else {
        print(
            "=== DEBUG ERROR: Server menolak dengan status ${response.statusCode} ===");
        throw Exception("Gagal memuat produk");
      }
    } catch (e, stacktrace) {
      // Menangkap SEMUA jenis error (Internet mati, URL salah, Error Model, dll)
      print("=== DEBUG CATCH ERROR: Proses getProducts TERHENTI! ===");
      print("=== PESAN ERROR: $e ===");
      print("=== LOKASI ERROR (Stacktrace): $stacktrace ===");
      throw Exception("Gagal memuat produk: $e");
    }
  }

  static Future<Product?> getProductDetails(String slug) async {
    final response = await http.get(
      Uri.parse("$baseUrl/products/$slug"),
      headers: {"Accept": "application/json"},
    );
    if (response.statusCode == 200) {
      final Map<String, dynamic> data = jsonDecode(response.body);
      return Product.fromJson(Map<String, dynamic>.from(data['data']));
    }
    return null;
  }

  static Future<bool> addToCart(int productId, int quantity) async {
    if (_token == null) return false;
    final response = await http.post(
      Uri.parse("$baseUrl/cart/add"),
      headers: _jsonHeaders,
      body: jsonEncode({"product_id": productId, "quantity": quantity}),
    );
    return response.statusCode == 200 || response.statusCode == 201;
  }

  static Future<Map<String, dynamic>> getCart() async {
    if (_token == null) throw Exception("Belum login");
    final response =
        await http.get(Uri.parse("$baseUrl/cart"), headers: _authHeaders);
    if (response.statusCode == 200) return jsonDecode(response.body);
    throw Exception("Gagal memuat keranjang");
  }

  static Future<bool> removeFromCart(int id) async {
    if (_token == null) return false;
    final response = await http.delete(Uri.parse("$baseUrl/cart/remove/$id"),
        headers: _authHeaders);
    return response.statusCode == 200;
  }

  static Future<List<dynamic>> getOrders() async {
    if (_token == null) throw Exception("Belum login");
    final response =
        await http.get(Uri.parse("$baseUrl/orders"), headers: _authHeaders);
    if (response.statusCode == 200)
      return jsonDecode(response.body)['data'] ?? [];
    throw Exception("Gagal memuat riwayat pesanan");
  }

  static Future<Map<String, dynamic>?> getUserProfile() async {
    if (_token == null) return null;
    final response = await http.get(Uri.parse("$baseUrl/user-profile"),
        headers: _authHeaders);
    if (response.statusCode == 200) return jsonDecode(response.body);
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

    final response = await http.put(Uri.parse("$baseUrl/user-profile"),
        headers: _jsonHeaders, body: jsonEncode(body));
    if (response.statusCode == 200) return jsonDecode(response.body)['data'];
    return null;
  }

  static Future<bool> logout() async {
    if (_token == null) return false;
    final response =
        await http.post(Uri.parse("$baseUrl/logout"), headers: _authHeaders);
    if (response.statusCode == 200) {
      _token = null;
      return true;
    }
    return false;
  }

  static Future<List<Product>> getWishlist() async {
    if (_token == null) return [];
    final response =
        await http.get(Uri.parse("$baseUrl/wishlist"), headers: _authHeaders);
    if (response.statusCode == 200) {
      final data = jsonDecode(response.body);
      final List<dynamic> wishlistData = data['data'] ?? [];
      return wishlistData
          .map((item) =>
              Product.fromJson(Map<String, dynamic>.from(item['product'])))
          .toList();
    }
    return [];
  }

  static Future<bool> addToWishlist(int productId) async {
    if (_token == null) return false;
    final response = await http.post(
      Uri.parse("$baseUrl/wishlist/add"),
      headers: _jsonHeaders,
      body: jsonEncode({"product_id": productId}),
    );
    return response.statusCode == 200 || response.statusCode == 201;
  }

  static Future<bool> removeFromWishlist(int productId) async {
    if (_token == null) return false;
    final response = await http.delete(
        Uri.parse("$baseUrl/wishlist/remove/$productId"),
        headers: _authHeaders);
    return response.statusCode == 200;
  }

  static Future<List<dynamic>> getUserAddresses() async {
    if (_token == null) return [];
    try {
      final response = await http.get(Uri.parse("$baseUrl/user/addresses"),
          headers: _authHeaders);
      if (response.statusCode == 200)
        return jsonDecode(response.body)['data'] ?? [];
    } catch (e) {
      print("Error get addresses: $e");
    }
    return [];
  }

  static Future<bool> saveUserAddress(Map<String, dynamic> addressData) async {
    if (_token == null) return false;
    try {
      final response = await http.post(Uri.parse("$baseUrl/user/addresses"),
          headers: _jsonHeaders, body: jsonEncode(addressData));
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
          headers: _authHeaders);
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
          headers: _authHeaders);
      return response.statusCode == 200;
    } catch (e) {
      return false;
    }
  }

  static Future<List<dynamic>> getProvinces() async {
    if (_token == null) return [];
    final response = await http.get(Uri.parse("$baseUrl/rajaongkir/provinces"),
        headers: _authHeaders);
    return response.statusCode == 200 ? jsonDecode(response.body) : [];
  }

  static Future<List<dynamic>> getCities(String provinceId) async {
    if (_token == null) return [];
    final response = await http.get(
        Uri.parse("$baseUrl/rajaongkir/cities/$provinceId"),
        headers: _authHeaders);
    return response.statusCode == 200 ? jsonDecode(response.body) : [];
  }

  static Future<List<dynamic>> getSubdistricts(String cityId) async {
    if (_token == null) return [];
    try {
      final response = await http.get(
          Uri.parse("$baseUrl/rajaongkir/subdistricts/$cityId"),
          headers: _authHeaders);
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
      headers: _jsonHeaders,
      body: jsonEncode({
        "destination": destinationCityId,
        "weight": weight,
        "courier": courier
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
    List<Map<String, dynamic>> cartItems,
  ) async {
    if (_token == null) throw Exception("Belum login");
    final formattedItems = cartItems.map((item) {
      return {
        "product_id": item['product']['id'],
        "quantity": item['quantity'],
        "options": item['isChecked'] ?? null,
      };
    }).toList();

    try {
      final response = await http.post(
        Uri.parse("$baseUrl/checkout"),
        headers: _jsonHeaders,
        body: jsonEncode({
          "address": address,
          "phone": phone,
          "province_name": provinceName,
          "city_name": cityName,
          "courier": courier,
          "shipping_cost": shippingCost,
          "items": formattedItems,
        }),
      );
      return response.statusCode == 200 ? jsonDecode(response.body) : null;
    } catch (e) {
      print("Error Checkout: $e");
      return null;
    }
  }

  static Future<Map<String, dynamic>?> getAdminStoreLocation() async {
    if (_token == null) return null;
    try {
      final response = await http.get(
          Uri.parse("$baseUrl/admin/store-location"),
          headers: _authHeaders);
      if (response.statusCode == 200) return jsonDecode(response.body);
    } catch (e) {
      print("Admin Error: $e");
    }
    return null;
  }

  static Future<bool> saveAdminStoreLocation(
      Map<String, dynamic> addressData) async {
    if (_token == null) return false;
    try {
      final response = await http.post(
          Uri.parse("$baseUrl/admin/store-location"),
          headers: _jsonHeaders,
          body: jsonEncode(addressData));
      return response.statusCode == 200 || response.statusCode == 201;
    } catch (e) {
      print("Admin Error: $e");
      return false;
    }
  }

  static Future<Map<String, dynamic>?> getAdminDashboardStats() async {
    if (_token == null) return null;
    try {
      final response = await http.get(Uri.parse("$baseUrl/admin/dashboard"),
          headers: _authHeaders);
      if (response.statusCode == 200) return jsonDecode(response.body);
    } catch (e) {
      print("Admin Error: $e");
    }
    return null;
  }

  static Future<List<dynamic>> getAdminProducts() async {
    if (_token == null) return [];
    final response = await http.get(Uri.parse("$baseUrl/admin/products"),
        headers: _authHeaders);
    if (response.statusCode == 200)
      return jsonDecode(response.body)['data'] ?? [];
    return [];
  }

  static Future<bool> saveAdminProduct(
    Map<String, String> fields, {
    XFile? mainImage,
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

    final uri = productId == null
        ? Uri.parse("$baseUrl/admin/products/store")
        : Uri.parse("$baseUrl/admin/products/update/$productId");
    final request = http.MultipartRequest('POST', uri);
    request.headers.addAll(
        {"Authorization": "Bearer $_token", "Accept": "application/json"});
    if (productId != null) request.fields['_method'] = 'PUT';
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
          'image', await mainImage.readAsBytes(),
          filename: mainImage.name));
    }

    if (galleryImages != null) {
      for (final file in galleryImages) {
        request.files.add(http.MultipartFile.fromBytes(
            'images[]', await file.readAsBytes(),
            filename: file.name));
      }
    }

    if (variationNames != null) {
      for (int i = 0; i < variationNames.length; i++) {
        request.fields['variation_names[$i]'] = variationNames[i];
        if (variationIds != null && i < variationIds.length)
          request.fields['variation_ids[$i]'] = variationIds[i];
        if (variationRegularPrices != null && i < variationRegularPrices.length)
          request.fields['variation_regular_prices[$i]'] =
              variationRegularPrices[i].isEmpty
                  ? '0'
                  : variationRegularPrices[i];
        if (variationSalePrices != null && i < variationSalePrices.length)
          request.fields['variation_sale_prices[$i]'] = variationSalePrices[i];
        if (variationWeights != null && i < variationWeights.length)
          request.fields['variation_weights[$i]'] =
              variationWeights[i].isEmpty ? '0' : variationWeights[i];
        if (variationQuantities != null && i < variationQuantities.length)
          request.fields['variation_quantities[$i]'] =
              variationQuantities[i].isEmpty ? '0' : variationQuantities[i];
        if (variationImages != null &&
            i < variationImages.length &&
            variationImages[i] != null) {
          request.files.add(http.MultipartFile.fromBytes(
              'variation_images[$i]', await variationImages[i]!.readAsBytes(),
              filename: variationImages[i]!.name));
        }
      }
    }

    try {
      final response = await request.send();
      if (response.statusCode == 200 || response.statusCode == 201) return true;
      print("Error saveAdminProduct: ${await response.stream.bytesToString()}");
      return false;
    } catch (e) {
      print("Exception saveAdminProduct: $e");
      return false;
    }
  }

  static Future<bool> deleteAdminProduct(int id) async {
    if (_token == null) return false;
    final response = await http.delete(
        Uri.parse("$baseUrl/admin/products/delete/$id"),
        headers: _authHeaders);
    return response.statusCode == 200;
  }

  static Future<List<dynamic>> getAdminCategories() async {
    if (_token == null) return [];
    final response = await http.get(Uri.parse("$baseUrl/admin/categories"),
        headers: _authHeaders);
    return response.statusCode == 200
        ? jsonDecode(response.body)['data'] ?? []
        : [];
  }

  static Future<List<dynamic>> getAdminBrands() async {
    if (_token == null) return [];
    final response = await http.get(Uri.parse("$baseUrl/admin/brands"),
        headers: _authHeaders);
    return response.statusCode == 200
        ? jsonDecode(response.body)['data'] ?? []
        : [];
  }

  static Future<List<dynamic>> getAdminOrders() async {
    if (_token == null) return [];
    final response = await http.get(Uri.parse("$baseUrl/admin/orders"),
        headers: _authHeaders);
    return response.statusCode == 200
        ? jsonDecode(response.body)['data'] ?? []
        : [];
  }

  static Future<bool> updateAdminOrderStatus(int orderId, String status) async {
    if (_token == null) return false;
    final response = await http.put(
        Uri.parse("$baseUrl/admin/orders/update-status/$orderId"),
        headers: _jsonHeaders,
        body: jsonEncode({"status": status}));
    return response.statusCode == 200;
  }

  static Future<List<dynamic>> getAdminCoupons() async {
    if (_token == null) return [];
    final response = await http.get(Uri.parse("$baseUrl/admin/coupons"),
        headers: _authHeaders);
    return response.statusCode == 200
        ? jsonDecode(response.body)['data'] ?? []
        : [];
  }

  static Future<List<dynamic>> getAdminContacts() async {
    if (_token == null) return [];
    final response = await http.get(Uri.parse("$baseUrl/admin/contacts"),
        headers: _authHeaders);
    return response.statusCode == 200
        ? jsonDecode(response.body)['data'] ?? []
        : [];
  }

  static Future<bool> saveAdminCategory(Map<String, String> fields,
      {XFile? image, int? categoryId}) async {
    if (_token == null) return false;
    final uri = categoryId == null
        ? Uri.parse("$baseUrl/admin/categories/store")
        : Uri.parse("$baseUrl/admin/categories/update/$categoryId");
    final request = http.MultipartRequest('POST', uri);
    request.headers.addAll(
        {"Authorization": "Bearer $_token", "Accept": "application/json"});
    if (categoryId != null) request.fields['_method'] = 'PUT';
    request.fields.addAll(fields);
    if (image != null)
      request.files.add(http.MultipartFile.fromBytes(
          'image', await image.readAsBytes(),
          filename: image.name));
    final response = await request.send();
    return response.statusCode == 200 || response.statusCode == 201;
  }

  static Future<bool> deleteAdminCategory(int id) async {
    if (_token == null) return false;
    final response = await http.delete(
        Uri.parse("$baseUrl/admin/categories/delete/$id"),
        headers: _authHeaders);
    return response.statusCode == 200;
  }

  static Future<bool> saveAdminBrand(Map<String, String> fields,
      {XFile? image, int? brandId}) async {
    if (_token == null) return false;
    final uri = brandId == null
        ? Uri.parse("$baseUrl/admin/brands/store")
        : Uri.parse("$baseUrl/admin/brands/update/$brandId");
    final request = http.MultipartRequest('POST', uri);
    request.headers.addAll(
        {"Authorization": "Bearer $_token", "Accept": "application/json"});
    if (brandId != null) request.fields['_method'] = 'PUT';
    request.fields.addAll(fields);
    if (image != null)
      request.files.add(http.MultipartFile.fromBytes(
          'image', await image.readAsBytes(),
          filename: image.name));
    final response = await request.send();
    return response.statusCode == 200 || response.statusCode == 201;
  }

  static Future<bool> deleteAdminBrand(int id) async {
    if (_token == null) return false;
    final response = await http.delete(
        Uri.parse("$baseUrl/admin/brands/delete/$id"),
        headers: _authHeaders);
    return response.statusCode == 200;
  }

  Future<List<PaymentMethodModel>> getPaymentMethods() async {
    try {
      final response = await http.get(Uri.parse('$baseUrl/payment-methods'));

      if (response.statusCode == 200) {
        final Map<String, dynamic> responseData = json.decode(response.body);
        if (responseData['success'] == true) {
          List<dynamic> data = responseData['data'];
          return data.map((json) => PaymentMethodModel.fromJson(json)).toList();
        }
      }
      throw Exception('Gagal memuat metode pembayaran');
    } catch (e) {
      throw Exception('Error jaringan: $e');
    }
  }
}

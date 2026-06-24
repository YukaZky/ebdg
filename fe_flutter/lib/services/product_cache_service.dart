import 'dart:async';
import 'dart:convert';

import 'package:http/http.dart' as http;

import '../models/product_model.dart';
import 'api_service.dart';

class ProductCacheService {
  static const Duration _cacheDuration = Duration(minutes: 5);
  static const Duration _requestTimeout = Duration(seconds: 14);
  static const Duration _retryDelay = Duration(milliseconds: 320);

  static List<Product> _cachedProducts = [];
  static DateTime? _lastFetchAt;
  static Future<List<Product>>? _inFlightRequest;
  static Future<void> _queueTail = Future<void>.value();

  static bool get hasCache => _cachedProducts.isNotEmpty;
  static List<Product> get cachedProducts => List<Product>.unmodifiable(_cachedProducts);

  static bool get _cacheStillFresh {
    final lastFetchAt = _lastFetchAt;
    return lastFetchAt != null && DateTime.now().difference(lastFetchAt) < _cacheDuration;
  }

  static Future<List<Product>> getProducts({bool forceRefresh = false}) {
    if (!forceRefresh && _cacheStillFresh && _cachedProducts.isNotEmpty) {
      return Future.value(List<Product>.from(_cachedProducts));
    }

    final runningRequest = _inFlightRequest;
    if (runningRequest != null && !forceRefresh) {
      return runningRequest;
    }

    late final Future<List<Product>> request;
    request = _enqueue<List<Product>>(() async {
      if (!forceRefresh && _cacheStillFresh && _cachedProducts.isNotEmpty) {
        return List<Product>.from(_cachedProducts);
      }

      final products = await _loadWithRetry();
      _cachedProducts = List<Product>.from(products);
      _lastFetchAt = DateTime.now();
      return List<Product>.from(_cachedProducts);
    }).catchError((Object error) {
      if (_cachedProducts.isNotEmpty) {
        return List<Product>.from(_cachedProducts);
      }
      throw Exception(_friendlyErrorMessage(error));
    }).whenComplete(() {
      if (identical(_inFlightRequest, request)) {
        _inFlightRequest = null;
      }
    });

    _inFlightRequest = request;
    return request;
  }

  static Future<List<Product>> refreshProducts() => getProducts(forceRefresh: true);

  static Future<T> _enqueue<T>(Future<T> Function() task) {
    final completer = Completer<T>();

    _queueTail = _queueTail.catchError((_) {}).then((_) async {
      try {
        completer.complete(await task());
      } catch (error, stackTrace) {
        completer.completeError(error, stackTrace);
      }
    });

    return completer.future;
  }

  static Future<List<Product>> _loadWithRetry() async {
    Object? lastError;

    for (var attempt = 0; attempt < 2; attempt++) {
      try {
        return await _fetchProductsLean().timeout(_requestTimeout);
      } catch (error) {
        lastError = error;
        if (attempt == 0) {
          await Future.delayed(_retryDelay);
        }
      }
    }

    throw lastError ?? Exception('Gagal memuat produk');
  }

  static Future<List<Product>> _fetchProductsLean() async {
    final response = await http.get(
      Uri.parse('${ApiService.baseUrl}/products'),
      headers: const {'Accept': 'application/json'},
    );

    if (response.statusCode != 200) {
      throw Exception('Server menolak permintaan produk (${response.statusCode}).');
    }

    final decoded = jsonDecode(response.body);
    final List<dynamic> productsJson = decoded is Map<String, dynamic> ? decoded['data'] ?? [] : [];

    return productsJson
        .map((item) => Product.fromJson(Map<String, dynamic>.from(item)))
        .toList(growable: false);
  }

  static String _friendlyErrorMessage(Object error) {
    final message = error.toString().toLowerCase();
    if (message.contains('handshake') ||
        message.contains('socket') ||
        message.contains('connection') ||
        message.contains('timed out') ||
        message.contains('timeout')) {
      return 'Koneksi sedang tidak stabil. Data terakhir tetap dipertahankan, tarik ke bawah untuk memuat ulang.';
    }
    return 'Gagal memuat produk. Coba lagi beberapa saat.';
  }
}

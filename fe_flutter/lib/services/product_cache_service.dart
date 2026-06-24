import 'dart:async';

import '../models/product_model.dart';
import 'api_service.dart';

class ProductCacheService {
  static const Duration _cacheDuration = Duration(minutes: 5);
  static const Duration _requestTimeout = Duration(seconds: 18);

  static List<Product> _cachedProducts = [];
  static DateTime? _lastFetchAt;
  static Future<List<Product>>? _inFlightRequest;

  static bool get hasCache => _cachedProducts.isNotEmpty;
  static List<Product> get cachedProducts => List<Product>.unmodifiable(_cachedProducts);

  static Future<List<Product>> getProducts({bool forceRefresh = false}) {
    final now = DateTime.now();
    final cacheStillFresh = _lastFetchAt != null && now.difference(_lastFetchAt!) < _cacheDuration;

    if (!forceRefresh && cacheStillFresh && _cachedProducts.isNotEmpty) {
      return Future.value(List<Product>.from(_cachedProducts));
    }

    final runningRequest = _inFlightRequest;
    if (runningRequest != null) {
      return runningRequest;
    }

    late final Future<List<Product>> request;
    request = _loadWithRetry()
        .then((products) {
          _cachedProducts = List<Product>.from(products);
          _lastFetchAt = DateTime.now();
          return List<Product>.from(_cachedProducts);
        })
        .catchError((Object error) {
          if (_cachedProducts.isNotEmpty) {
            return List<Product>.from(_cachedProducts);
          }
          throw Exception(_friendlyErrorMessage(error));
        })
        .whenComplete(() {
          if (identical(_inFlightRequest, request)) {
            _inFlightRequest = null;
          }
        });

    _inFlightRequest = request;
    return request;
  }

  static Future<List<Product>> refreshProducts() => getProducts(forceRefresh: true);

  static Future<List<Product>> _loadWithRetry() async {
    Object? lastError;

    for (var attempt = 0; attempt < 2; attempt++) {
      try {
        return await ApiService.getProducts().timeout(_requestTimeout);
      } catch (error) {
        lastError = error;
        if (attempt == 0) {
          await Future.delayed(const Duration(milliseconds: 350));
        }
      }
    }

    throw lastError ?? Exception('Gagal memuat produk');
  }

  static String _friendlyErrorMessage(Object error) {
    final message = error.toString().toLowerCase();
    if (message.contains('handshake') ||
        message.contains('socket') ||
        message.contains('connection') ||
        message.contains('timed out') ||
        message.contains('timeout')) {
      return 'Koneksi sedang tidak stabil. Coba tarik ke bawah untuk memuat ulang.';
    }
    return 'Gagal memuat produk. Coba lagi beberapa saat.';
  }
}

import 'dart:async';

import 'package:app_links/app_links.dart';
import 'package:flutter/material.dart';

import '../config/app_link_config.dart';
import '../screens/marketplace/store_detail_screen.dart';
import '../screens/product_detail_screen.dart';
import 'api_service.dart';

class DeepLinkService {
  DeepLinkService._();

  static final DeepLinkService instance = DeepLinkService._();

  final AppLinks _appLinks = AppLinks();
  StreamSubscription<Uri>? _subscription;
  GlobalKey<NavigatorState>? _navigatorKey;
  Uri? _pendingUri;
  bool _ready = false;
  bool _navigating = false;
  String? _lastHandledKey;
  DateTime? _lastHandledAt;

  bool get hasPendingLink => _pendingUri != null;

  Future<void> init(GlobalKey<NavigatorState> navigatorKey) async {
    _navigatorKey = navigatorKey;

    try {
      final initial = await _appLinks.getInitialAppLink();
      if (initial != null && _isSupported(initial)) {
        _pendingUri = initial;
      }
    } catch (_) {}

    _subscription ??= _appLinks.uriLinkStream.listen(
      _receive,
      onError: (_) {},
    );
  }

  void _receive(Uri uri) {
    if (!_isSupported(uri)) return;
    _pendingUri = uri;
    if (_ready) {
      unawaited(_openPending(replace: false));
    }
  }

  Future<bool> openPendingFromSplash() async {
    if (_pendingUri == null) return false;
    final handled = await _openPending(replace: true);
    if (handled) _ready = true;
    return handled;
  }

  void markReady() {
    _ready = true;
    if (_pendingUri != null) {
      unawaited(_openPending(replace: false));
    }
  }

  Future<bool> _openPending({required bool replace}) async {
    if (_navigating) return false;
    final uri = _pendingUri;
    if (uri == null) return false;

    final target = _parse(uri);
    if (target == null) {
      _pendingUri = null;
      return false;
    }

    final key = '${target.type}:${target.slug}';
    final now = DateTime.now();
    if (_lastHandledKey == key &&
        _lastHandledAt != null &&
        now.difference(_lastHandledAt!).inSeconds < 2) {
      _pendingUri = null;
      return true;
    }

    final navigator = _navigatorKey?.currentState;
    if (navigator == null) return false;

    _navigating = true;
    try {
      Route<dynamic>? route;

      if (target.type == 'product') {
        final product = await ApiService.getProductDetails(target.slug);
        if (product == null) {
          _showMessage('Produk yang dibagikan tidak ditemukan atau sudah tidak tersedia.');
          _pendingUri = null;
          return false;
        }
        route = MaterialPageRoute(
          builder: (_) => ProductDetailScreen(product: product),
        );
      } else if (target.type == 'store') {
        route = MaterialPageRoute(
          builder: (_) => StoreDetailScreen(slug: target.slug),
        );
      }

      if (route == null) {
        _pendingUri = null;
        return false;
      }

      _pendingUri = null;
      _lastHandledKey = key;
      _lastHandledAt = now;

      if (replace) {
        await navigator.pushReplacement(route);
      } else {
        await navigator.push(route);
      }
      return true;
    } catch (_) {
      _showMessage('Link tidak dapat dibuka. Silakan coba lagi.');
      return false;
    } finally {
      _navigating = false;
    }
  }

  _DeepLinkTarget? _parse(Uri uri) {
    if (uri.scheme.toLowerCase() == AppLinkConfig.customScheme) {
      final type = uri.host.toLowerCase();
      if ((type == 'product' || type == 'store') && uri.pathSegments.isNotEmpty) {
        final slug = Uri.decodeComponent(uri.pathSegments.first).trim();
        if (slug.isNotEmpty) return _DeepLinkTarget(type, slug);
      }
      return null;
    }

    if ((uri.scheme == 'https' || uri.scheme == 'http') &&
        AppLinkConfig.isShareHost(uri.host)) {
      final segments = uri.pathSegments.where((item) => item.trim().isNotEmpty).toList();
      if (segments.length >= 3 && segments[0] == 'open') {
        final type = segments[1].toLowerCase();
        final slug = Uri.decodeComponent(segments[2]).trim();
        if ((type == 'product' || type == 'store') && slug.isNotEmpty) {
          return _DeepLinkTarget(type, slug);
        }
      }
    }

    return null;
  }

  bool _isSupported(Uri uri) => _parse(uri) != null;

  void _showMessage(String message) {
    final context = _navigatorKey?.currentContext;
    if (context == null) return;
    ScaffoldMessenger.maybeOf(context)?.showSnackBar(
      SnackBar(content: Text(message)),
    );
  }

  Future<void> dispose() async {
    await _subscription?.cancel();
    _subscription = null;
  }
}

class _DeepLinkTarget {
  final String type;
  final String slug;

  const _DeepLinkTarget(this.type, this.slug);
}

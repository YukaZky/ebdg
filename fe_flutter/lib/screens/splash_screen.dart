import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import '../services/api_service.dart';
import '../services/deep_link_service.dart';
import 'app_opening_popup_screen.dart';
import 'main_screen.dart';

class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen> {
  static const Duration _minimumSplashDuration = Duration(milliseconds: 700);

  @override
  void initState() {
    super.initState();
    _bootstrap();
  }

  Future<Map<String, dynamic>?> _loadOpeningPopup() async {
    try {
      final response = await http
          .get(
            Uri.parse('${ApiService.baseUrl}/startup-ad'),
            headers: const {
              'Accept': 'application/json',
              'Cache-Control': 'no-cache',
            },
          )
          .timeout(const Duration(seconds: 8));

      if (response.statusCode != 200) return null;

      final decoded = jsonDecode(response.body);
      final data = decoded is Map ? decoded['data'] : null;
      if (data is! Map) return null;

      final imageUrl = data['image_url']?.toString().trim() ?? '';
      if (imageUrl.isEmpty || imageUrl == 'null') return null;

      return Map<String, dynamic>.from(data);
    } catch (_) {
      return null;
    }
  }

  Future<void> _waitMinimumSplash(DateTime startedAt) async {
    final elapsed = DateTime.now().difference(startedAt);
    final remaining = _minimumSplashDuration - elapsed;
    if (remaining > Duration.zero) {
      await Future.delayed(remaining);
    }
  }

  Future<void> _bootstrap() async {
    final startedAt = DateTime.now();
    await ApiService.restoreSession();

    if (DeepLinkService.instance.hasPendingLink) {
      await _waitMinimumSplash(startedAt);
      if (!mounted) return;
      final handled = await DeepLinkService.instance.openPendingFromSplash();
      if (handled) return;
    }

    final openingPopup = await _loadOpeningPopup();
    await _waitMinimumSplash(startedAt);

    if (!mounted) return;

    // Link bisa masuk saat startup-ad sedang dimuat. Prioritaskan link tersebut
    // sebelum membuka halaman utama / popup.
    if (DeepLinkService.instance.hasPendingLink) {
      final handled = await DeepLinkService.instance.openPendingFromSplash();
      if (handled) return;
    }

    Navigator.pushReplacement(
      context,
      MaterialPageRoute(
        builder: (context) => openingPopup == null
            ? const MainScreen()
            : AppOpeningPopupScreen(popupData: openingPopup),
      ),
    );

    WidgetsBinding.instance.addPostFrameCallback((_) {
      DeepLinkService.instance.markReady();
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        child: LayoutBuilder(
          builder: (context, constraints) {
            final shortestSide = constraints.biggest.shortestSide;

            final logoSize =
                (shortestSide * 0.62).clamp(190.0, 380.0).toDouble();

            return Center(
              child: Image.asset(
                'assets/logoapk.png',
                width: logoSize,
                fit: BoxFit.contain,
              ),
            );
          },
        ),
      ),
    );
  }
}

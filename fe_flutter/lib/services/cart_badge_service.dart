import 'package:flutter/material.dart';
import 'api_service.dart';

class CartBadgeService {
  static final ValueNotifier<int> count = ValueNotifier<int>(0);

  static Future<void> refresh() async {
    if (ApiService.token == null) {
      count.value = 0;
      return;
    }

    try {
      final cart = await ApiService.getCart();
      final items = cart['data'];

      if (items is List) {
        int total = 0;
        for (final item in items) {
          total += int.tryParse((item['quantity'] ?? 1).toString()) ?? 1;
        }
        count.value = total;
      } else {
        count.value = 0;
      }
    } catch (_) {
      count.value = 0;
    }
  }

  static void clear() {
    count.value = 0;
  }
}

import 'package:flutter_test/flutter_test.dart';
import 'package:fe_flutter/services/cart_badge_service.dart';

void main() {
  test('cart change increments revision so persistent cart screens reload', () async {
    final before = CartBadgeService.revision.value;

    await CartBadgeService.notifyCartChanged();

    expect(CartBadgeService.revision.value, before + 1);
  });
}

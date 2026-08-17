import 'package:flutter/material.dart';
import 'package:share_plus/share_plus.dart';

import '../config/app_link_config.dart';

class ShareLinkService {
  ShareLinkService._();

  static Future<void> shareProduct({
    required BuildContext context,
    required String productName,
    required String slug,
  }) async {
    final uri = AppLinkConfig.productShareUri(slug);
    await _share(
      context: context,
      subject: 'Lihat $productName di GeoDesaConnect',
      text: 'Lihat $productName di GeoDesaConnect\n\n$uri',
    );
  }

  static Future<void> shareStore({
    required BuildContext context,
    required String storeName,
    required String slug,
  }) async {
    final uri = AppLinkConfig.storeShareUri(slug);
    await _share(
      context: context,
      subject: 'Lihat $storeName di GeoDesaConnect',
      text: 'Lihat toko $storeName di GeoDesaConnect\n\n$uri',
    );
  }

  static Future<void> _share({
    required BuildContext context,
    required String subject,
    required String text,
  }) async {
    final renderBox = context.findRenderObject() as RenderBox?;
    final origin = renderBox == null
        ? null
        : renderBox.localToGlobal(Offset.zero) & renderBox.size;

    await Share.share(
      text,
      subject: subject,
      sharePositionOrigin: origin,
    );
  }
}

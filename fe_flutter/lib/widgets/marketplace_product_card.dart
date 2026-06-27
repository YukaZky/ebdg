import 'package:flutter/material.dart';
import '../models/product_model.dart';
import '../screens/product_detail_screen.dart';
import '../services/api_service.dart';

class MarketplaceProductCard extends StatelessWidget {
  final Product product;

  const MarketplaceProductCard({Key? key, required this.product}) : super(key: key);

  String _imageUrl(String? image) {
    final value = image?.trim() ?? '';
    if (value.isEmpty || value == 'null') return '';

    if (value.startsWith('http://') || value.startsWith('https://')) {
      return value;
    }

    final base = ApiService.baseUrl.replaceFirst(RegExp(r'/api/?$'), '');
    final cleanValue = value.startsWith('/') ? value.substring(1) : value;

    if (cleanValue.startsWith('uploads/') || cleanValue.startsWith('storage/')) {
      return '$base/$cleanValue';
    }

    return '$base/uploads/products/$cleanValue';
  }

  bool get _hasPromo {
    return product.salePrice != null && product.salePrice! > 0 && product.salePrice! < product.price;
  }

  double get _activePrice => _hasPromo ? product.salePrice! : product.price;

  int get _discountPercent {
    if (!_hasPromo || product.price <= 0) return 0;
    final percent = ((product.price - product.salePrice!) / product.price * 100).round();
    return percent.clamp(1, 99).toInt();
  }

  String get _sellerCity {
    final store = product.store;
    final values = [
      store?['city_name'],
      store?['city'],
      store?['cityName'],
      store?['regency_name'],
      store?['regency'],
      store?['location'],
    ];

    for (final item in values) {
      final value = item?.toString().trim() ?? '';
      if (value.isNotEmpty && value != 'null') return value;
    }

    return 'Lokasi toko';
  }

  Widget _discountRibbon() {
    if (!_hasPromo) return const SizedBox.shrink();

    return Positioned(
      top: 12,
      right: -24,
      child: Transform.rotate(
        angle: 0.70,
        child: Container(
          width: 92,
          padding: const EdgeInsets.symmetric(vertical: 4),
          decoration: BoxDecoration(
            color: const Color(0xFFFF8A00),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.10),
                blurRadius: 8,
                offset: const Offset(0, 3),
              ),
            ],
          ),
          child: Text(
            '-$_discountPercent%',
            textAlign: TextAlign.center,
            style: const TextStyle(
              color: Colors.white,
              fontWeight: FontWeight.w800,
              fontSize: 11,
              letterSpacing: 0.2,
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildPrice() {
    return Text(
      'Rp ${_activePrice.toStringAsFixed(0)}',
      maxLines: 1,
      overflow: TextOverflow.ellipsis,
      style: const TextStyle(
        color: Color(0xFFE65100),
        fontWeight: FontWeight.w800,
        fontSize: 14,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final imageUrl = _imageUrl(product.image);
    final isAvailable = product.stockStatus == 'instock' && product.quantity > 0;

    return GestureDetector(
      onTap: () {
        Navigator.push(
          context,
          MaterialPageRoute(builder: (context) => ProductDetailScreen(product: product)),
        );
      },
      child: Container(
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          boxShadow: [
            BoxShadow(
              color: Colors.grey.withOpacity(0.1),
              blurRadius: 10,
              spreadRadius: 1,
              offset: const Offset(0, 5),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(
              child: ClipRRect(
                borderRadius: const BorderRadius.vertical(top: Radius.circular(16)),
                child: Stack(
                  children: [
                    Container(
                      width: double.infinity,
                      height: double.infinity,
                      color: Colors.white,
                      child: imageUrl.isNotEmpty
                          ? Image.network(
                              imageUrl,
                              fit: BoxFit.cover,
                              errorBuilder: (context, error, stackTrace) => const Icon(Icons.image_not_supported, size: 50, color: Colors.grey),
                            )
                          : const Icon(Icons.image, size: 50, color: Colors.grey),
                    ),
                    _discountRibbon(),
                  ],
                ),
              ),
            ),
            Padding(
              padding: const EdgeInsets.all(12),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    product.name,
                    style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 6),
                  _buildPrice(),
                  const SizedBox(height: 6),
                  Row(
                    children: [
                      Icon(
                        isAvailable ? Icons.location_on_outlined : Icons.remove_shopping_cart_outlined,
                        size: isAvailable ? 13 : 14,
                        color: isAvailable ? Colors.grey.shade500 : Colors.red,
                      ),
                      const SizedBox(width: 4),
                      Expanded(
                        child: Text(
                          isAvailable ? _sellerCity : 'Habis',
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: TextStyle(
                            fontSize: 12,
                            fontWeight: isAvailable ? FontWeight.w400 : FontWeight.w600,
                            color: isAvailable ? Colors.grey.shade600 : Colors.red,
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

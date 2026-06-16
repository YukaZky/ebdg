import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../models/product_model.dart';
import '../../services/api_service.dart';
import '../../services/marketplace_api_service.dart';
import '../../widgets/marketplace_product_card.dart';

class StoreDetailScreen extends StatefulWidget {
  final String slug;

  const StoreDetailScreen({Key? key, required this.slug}) : super(key: key);

  @override
  State<StoreDetailScreen> createState() => _StoreDetailScreenState();
}

class _StoreDetailScreenState extends State<StoreDetailScreen> {
  Map<String, dynamic>? store;
  Map<String, dynamic>? storeAddress;
  List<Product> products = [];
  List<dynamic> reviews = [];
  Map<String, String> categoryImages = {};
  String selectedCategory = 'Semua';
  bool loading = true;

  @override
  void initState() {
    super.initState();
    loadStore();
  }

  Future<void> loadStore() async {
    final data = await MarketplaceApiService.storeDetail(widget.slug);
    if (!mounted) return;
    if (data != null) {
      final rawProducts = data['products'] as List? ?? [];
      final imageMap = <String, String>{};

      for (final item in rawProducts) {
        if (item is Map && item['category'] is Map) {
          final category = Map<String, dynamic>.from(item['category']);
          final name = category['name']?.toString() ?? '';
          final image = category['image']?.toString() ?? '';
          if (name.isNotEmpty && image.isNotEmpty) imageMap[name] = image;
        }
      }

      setState(() {
        store = Map<String, dynamic>.from(data['store'] ?? {});
        storeAddress = data['store_address'] is Map ? Map<String, dynamic>.from(data['store_address']) : null;
        products = rawProducts.map((item) => Product.fromJson(Map<String, dynamic>.from(item))).toList();
        reviews = data['reviews'] as List? ?? [];
        categoryImages = imageMap;
        loading = false;
      });
    } else {
      setState(() => loading = false);
    }
  }

  String _mediaUrl(dynamic image, {String folder = 'stores'}) {
    final value = image?.toString().trim() ?? '';
    if (value.isEmpty || value == 'null') return '';
    if (value.startsWith('http://') || value.startsWith('https://')) return value;

    final base = ApiService.baseUrl.replaceFirst(RegExp(r'/api/?$'), '');
    final clean = value.startsWith('/') ? value.substring(1) : value;
    if (clean.startsWith('uploads/') || clean.startsWith('storage/')) return '$base/$clean';
    return '$base/uploads/$folder/$clean';
  }

  Future<void> _openUrl(String url) async {
    final value = url.trim();
    if (value.isEmpty || value == 'null') return;
    final uri = Uri.tryParse(value.startsWith('http') ? value : 'https://$value');
    if (uri == null) return;
    await launchUrl(uri, mode: LaunchMode.externalApplication);
  }

  String _usernameFromLink(dynamic value) {
    var text = value?.toString().trim() ?? '';
    if (text.isEmpty || text == 'null') return '';

    try {
      final uri = Uri.parse(text.startsWith('http') ? text : 'https://$text');
      final segments = uri.pathSegments.where((segment) => segment.trim().isNotEmpty).toList();
      if (segments.isNotEmpty) text = segments.last;
    } catch (_) {
      text = text.split('/').where((item) => item.trim().isNotEmpty).last;
    }

    text = text.replaceAll('@', '').split('?').first.trim();
    return text.isEmpty ? '' : '@$text';
  }

  double? get _latitude => double.tryParse(storeAddress?['latitude']?.toString() ?? '');
  double? get _longitude => double.tryParse(storeAddress?['longitude']?.toString() ?? '');

  String get _mapsUrl {
    if (_latitude != null && _longitude != null) {
      return 'https://www.google.com/maps/search/?api=1&query=$_latitude,$_longitude';
    }
    return store?['maps_url']?.toString() ?? '';
  }

  String get _staticMapUrl {
    if (_latitude == null || _longitude == null) return '';
    return 'https://staticmap.openstreetmap.de/staticmap.php?center=$_latitude,$_longitude&zoom=15&size=640x260&markers=$_latitude,$_longitude,red-pushpin';
  }

  List<String> get categories {
    final set = <String>{};
    for (final product in products) {
      final name = product.categoryName;
      if (name != null && name.isNotEmpty) set.add(name);
    }
    return set.toList();
  }

  int _categoryCount(String category) {
    if (category == 'Semua') return products.length;
    return products.where((product) => product.categoryName == category).length;
  }

  String _categoryImage(String category) {
    final categoryImage = categoryImages[category];
    if (categoryImage != null && categoryImage.isNotEmpty) return _mediaUrl(categoryImage, folder: 'categories');

    final list = category == 'Semua' ? products : products.where((product) => product.categoryName == category).toList();
    if (list.isEmpty) return '';
    final firstWithImage = list.firstWhere((product) => (product.image ?? '').isNotEmpty, orElse: () => list.first);
    return _mediaUrl(firstWithImage.image, folder: 'products');
  }

  List<Product> get filteredProducts {
    if (selectedCategory == 'Semua') return products;
    return products.where((product) => product.categoryName == selectedCategory).toList();
  }

  double get ratingAverage {
    final value = store?['rating_average'];
    return double.tryParse(value?.toString() ?? '0') ?? 0;
  }

  Widget _stars(double rating, {double size = 16}) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: List.generate(5, (index) => Icon(index < rating.round() ? Icons.star : Icons.star_border, color: Colors.amber, size: size)),
    );
  }

  Widget _logoAvatar({double radius = 34}) {
    final logoUrl = _mediaUrl(store?['logo'], folder: 'stores');
    return CircleAvatar(
      radius: radius,
      backgroundColor: Colors.white,
      child: ClipOval(
        child: SizedBox(
          width: radius * 2,
          height: radius * 2,
          child: logoUrl.isNotEmpty
              ? Image.network(logoUrl, fit: BoxFit.cover, errorBuilder: (_, __, ___) => Icon(Icons.storefront, color: Colors.deepOrange, size: radius))
              : Icon(Icons.storefront, color: Colors.deepOrange, size: radius),
        ),
      ),
    );
  }

  Widget _infoRow(IconData icon, String label, dynamic value, {bool link = false, String? displayText}) {
    final raw = value?.toString().trim() ?? '';
    final shown = displayText ?? raw;
    if (raw.isEmpty || raw == 'null' || shown.isEmpty || shown == 'null') return const SizedBox.shrink();

    return InkWell(
      onTap: link ? () => _openUrl(raw) : null,
      borderRadius: BorderRadius.circular(10),
      child: Padding(
        padding: const EdgeInsets.only(bottom: 10),
        child: Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Icon(icon, size: 18, color: Colors.deepOrange),
          const SizedBox(width: 8),
          Expanded(child: Text('$label: $shown', style: TextStyle(height: 1.35, color: link ? Colors.deepOrange : Colors.black87, fontWeight: link ? FontWeight.w600 : FontWeight.normal))),
          if (link) const Icon(Icons.open_in_new, size: 16, color: Colors.deepOrange),
        ]),
      ),
    );
  }

  Widget _mapPreview() {
    final url = _staticMapUrl;
    if (url.isEmpty && _mapsUrl.trim().isEmpty) return const SizedBox.shrink();

    return InkWell(
      onTap: () => _openUrl(_mapsUrl),
      borderRadius: BorderRadius.circular(16),
      child: Container(
        margin: const EdgeInsets.only(bottom: 14),
        clipBehavior: Clip.antiAlias,
        decoration: BoxDecoration(borderRadius: BorderRadius.circular(16), border: Border.all(color: Colors.deepOrange.withOpacity(0.18))),
        child: Stack(children: [
          if (url.isNotEmpty)
            Image.network(
              url,
              width: double.infinity,
              height: 150,
              fit: BoxFit.cover,
              errorBuilder: (_, __, ___) => _mapFallback(),
            )
          else
            _mapFallback(),
          Positioned(
            right: 10,
            top: 10,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 6),
              decoration: BoxDecoration(color: Colors.white.withOpacity(0.92), borderRadius: BorderRadius.circular(999)),
              child: const Row(mainAxisSize: MainAxisSize.min, children: [
                Text('Buka Maps', style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: Colors.deepOrange)),
                SizedBox(width: 4),
                Icon(Icons.open_in_new, size: 13, color: Colors.deepOrange),
              ]),
            ),
          ),
        ]),
      ),
    );
  }

  Widget _mapFallback() {
    return Container(
      width: double.infinity,
      height: 150,
      color: const Color(0xFFFFF3E0),
      child: const Center(child: Icon(Icons.map, size: 46, color: Colors.deepOrange)),
    );
  }

  Widget _header() {
    final name = store?['name']?.toString() ?? 'Toko';
    final city = store?['city_name']?.toString() ?? '';
    final province = store?['province_name']?.toString() ?? '';

    return Container(
      padding: const EdgeInsets.all(18),
      decoration: const BoxDecoration(
        gradient: LinearGradient(colors: [Color(0xFF0C2442), Color(0xFFE65100)], begin: Alignment.topLeft, end: Alignment.bottomRight),
        borderRadius: BorderRadius.vertical(bottom: Radius.circular(24)),
      ),
      child: SafeArea(
        bottom: false,
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Row(children: [
            _logoAvatar(radius: 34),
            const SizedBox(width: 14),
            Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Text(name, style: const TextStyle(color: Colors.white, fontSize: 22, fontWeight: FontWeight.bold), maxLines: 1, overflow: TextOverflow.ellipsis),
              const SizedBox(height: 4),
              Text([city, province].where((e) => e.isNotEmpty && e != 'null').join(', '), style: const TextStyle(color: Colors.white70)),
              const SizedBox(height: 8),
              Row(children: [_stars(ratingAverage), const SizedBox(width: 6), Text('${ratingAverage.toStringAsFixed(1)} (${store?['rating_count'] ?? 0} ulasan)', style: const TextStyle(color: Colors.white))]),
            ])),
          ]),
          const SizedBox(height: 16),
          Text(store?['description']?.toString() ?? 'Belum ada deskripsi toko.', style: const TextStyle(color: Colors.white, height: 1.4)),
        ]),
      ),
    );
  }

  Widget _storeInfo() {
    return Container(
      margin: const EdgeInsets.all(16),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(18)),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        const Text('Informasi Toko', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
        const SizedBox(height: 12),
        _mapPreview(),
        _infoRow(Icons.phone, 'HP', store?['phone']),
        _infoRow(Icons.location_on, 'Alamat', store?['address']),
        _infoRow(Icons.map, 'Google Maps', _mapsUrl, link: true, displayText: 'Lihat lokasi toko'),
        _infoRow(Icons.camera_alt, 'Instagram', store?['instagram'], link: true, displayText: _usernameFromLink(store?['instagram'])),
        _infoRow(Icons.music_note, 'TikTok', store?['tiktok'], link: true, displayText: _usernameFromLink(store?['tiktok'])),
        _infoRow(Icons.facebook, 'Facebook', store?['facebook'], link: true, displayText: _usernameFromLink(store?['facebook'])),
        _infoRow(Icons.public, 'Website', store?['website'], link: true, displayText: _usernameFromLink(store?['website'])),
      ]),
    );
  }

  Widget _categoryCard(String category) {
    final selected = selectedCategory == category;
    final image = _categoryImage(category);
    final count = _categoryCount(category);

    return InkWell(
      onTap: () => setState(() => selectedCategory = category),
      borderRadius: BorderRadius.circular(16),
      child: Container(
        width: 118,
        margin: const EdgeInsets.only(right: 10),
        padding: const EdgeInsets.all(10),
        decoration: BoxDecoration(
          color: selected ? Colors.deepOrange.shade50 : Colors.white,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: selected ? Colors.deepOrange : Colors.grey.shade200, width: selected ? 1.4 : 1),
        ),
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Container(
            height: 64,
            width: double.infinity,
            clipBehavior: Clip.antiAlias,
            decoration: BoxDecoration(color: Colors.grey.shade100, borderRadius: BorderRadius.circular(12)),
            child: image.isNotEmpty
                ? Image.network(image, fit: BoxFit.cover, errorBuilder: (_, __, ___) => const Icon(Icons.category, color: Colors.deepOrange))
                : const Icon(Icons.category, color: Colors.deepOrange),
          ),
          const SizedBox(height: 8),
          Text(category, maxLines: 1, overflow: TextOverflow.ellipsis, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13)),
          const SizedBox(height: 2),
          Text('$count produk', style: TextStyle(color: Colors.grey.shade600, fontSize: 11)),
        ]),
      ),
    );
  }

  Widget _categorySection() {
    return Container(
      margin: const EdgeInsets.fromLTRB(16, 0, 16, 16),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(18)),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        const Text('Filter Produk', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
        const SizedBox(height: 12),
        Align(
          alignment: Alignment.centerLeft,
          child: ChoiceChip(
            label: Text('Semua Produk (${products.length})'),
            selected: selectedCategory == 'Semua',
            selectedColor: Colors.deepOrange.shade100,
            onSelected: (_) => setState(() => selectedCategory = 'Semua'),
          ),
        ),
        const SizedBox(height: 16),
        const Text('Kategori Produk', style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold)),
        const SizedBox(height: 10),
        if (categories.isEmpty)
          Text('Belum ada kategori produk.', style: TextStyle(color: Colors.grey.shade600))
        else
          SingleChildScrollView(scrollDirection: Axis.horizontal, child: Row(children: categories.map(_categoryCard).toList())),
      ]),
    );
  }

  Widget _productSection() {
    final items = filteredProducts;
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Text(selectedCategory == 'Semua' ? 'Semua Produk Toko' : 'Produk $selectedCategory', style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
        const SizedBox(height: 12),
        if (items.isEmpty)
          const Padding(padding: EdgeInsets.all(24), child: Center(child: Text('Belum ada produk di kategori ini.')))
        else
          GridView.builder(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(crossAxisCount: 2, childAspectRatio: 0.72, crossAxisSpacing: 12, mainAxisSpacing: 12),
            itemCount: items.length,
            itemBuilder: (context, index) => MarketplaceProductCard(product: items[index]),
          ),
      ]),
    );
  }

  Widget _reviewsSection() {
    return Container(
      margin: const EdgeInsets.all(16),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(18)),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        const Text('Ulasan Toko', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
        const SizedBox(height: 12),
        if (reviews.isEmpty)
          const Text('Belum ada ulasan untuk toko ini.')
        else
          ...reviews.take(5).map((review) {
            final user = review['user'] ?? {};
            final product = review['product'] ?? {};
            final rating = double.tryParse(review['rating']?.toString() ?? '0') ?? 0;
            return Container(
              margin: const EdgeInsets.only(bottom: 12),
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(color: const Color(0xFFF8F8F8), borderRadius: BorderRadius.circular(12)),
              child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                Row(children: [Expanded(child: Text(user['name']?.toString() ?? 'Pembeli', style: const TextStyle(fontWeight: FontWeight.bold))), _stars(rating, size: 14)]),
                const SizedBox(height: 4),
                Text(product['name']?.toString() ?? '', style: TextStyle(color: Colors.grey.shade700, fontSize: 12)),
                const SizedBox(height: 6),
                Text(review['review']?.toString() ?? '-'),
              ]),
            );
          }),
      ]),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF6F7FB),
      appBar: AppBar(title: const Text('Detail Toko'), backgroundColor: Colors.white, foregroundColor: Colors.black87),
      body: loading
          ? const Center(child: CircularProgressIndicator())
          : store == null
              ? const Center(child: Text('Toko tidak ditemukan.'))
              : RefreshIndicator(
                  onRefresh: loadStore,
                  child: ListView(children: [_header(), _storeInfo(), _categorySection(), _productSection(), _reviewsSection(), const SizedBox(height: 20)]),
                ),
    );
  }
}

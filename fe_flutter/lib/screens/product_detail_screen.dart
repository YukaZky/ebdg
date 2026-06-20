import 'package:flutter/material.dart';
import '../models/product_model.dart';
import '../services/api_service.dart';
import '../services/cart_api_service.dart';
import '../services/marketplace_api_service.dart';
import '../widgets/marketplace_product_card.dart';
import 'marketplace/store_detail_screen.dart';

class ProductDetailScreen extends StatefulWidget {
  final Product product;
  const ProductDetailScreen({Key? key, required this.product}) : super(key: key);

  @override
  State<ProductDetailScreen> createState() => _ProductDetailScreenState();
}

class _SlideItem {
  final String image;
  final ProductVariation? variation;
  _SlideItem(this.image, this.variation);
}

class _ProductDetailScreenState extends State<ProductDetailScreen> {
  final PageController _pageController = PageController();
  late Product _product;
  ProductVariation? _variation;
  int _page = 0;
  int _qty = 1;
  bool _saving = false;
  bool _loadingReviews = true;
  bool _loadingRecommendations = true;
  List<dynamic> _productReviews = [];
  List<Product> _recommendations = [];

  @override
  void initState() {
    super.initState();
    _product = widget.product;
    _refreshProductDetail();
    _loadProductReviews();
    _loadRecommendations();
  }

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  Future<void> _refreshProductDetail() async {
    final latest = await ApiService.getProductDetails(widget.product.slug);
    if (!mounted || latest == null) return;

    setState(() {
      _product = latest;
      if (_variation != null) {
        final matched = latest.variations?.where((item) => item.id == _variation!.id).toList() ?? [];
        _variation = matched.isNotEmpty ? matched.first : null;
      }
      _page = 0;
      _qty = 1;
    });
  }

  Future<void> _loadProductReviews() async {
    final data = await MarketplaceApiService.productReviews(_product.id);
    if (!mounted) return;
    setState(() {
      _productReviews = data;
      _loadingReviews = false;
    });
  }

  Future<void> _loadRecommendations() async {
    try {
      final products = await ApiService.getProducts();
      if (!mounted) return;

      final sameCategory = products
          .where((item) => item.id != _product.id && _product.categoryId != null && item.categoryId == _product.categoryId)
          .toList();
      final others = products.where((item) => item.id != _product.id && !sameCategory.any((same) => same.id == item.id)).toList();

      setState(() {
        _recommendations = [...sameCategory, ...others].take(8).toList();
        _loadingRecommendations = false;
      });
    } catch (_) {
      if (!mounted) return;
      setState(() => _loadingRecommendations = false);
    }
  }

  String _url(String? image) {
    final value = image?.trim() ?? '';
    if (value.isEmpty || value == 'null') return '';
    if (value.startsWith('http')) return value;
    final base = ApiService.baseUrl.replaceFirst(RegExp(r'/api/?$'), '');
    final clean = value.startsWith('/') ? value.substring(1) : value;
    if (clean.startsWith('uploads/') || clean.startsWith('storage/')) return '$base/$clean';
    return '$base/uploads/products/$clean';
  }

  String _storeMediaUrl(dynamic image) {
    final value = image?.toString().trim() ?? '';
    if (value.isEmpty || value == 'null') return '';
    if (value.startsWith('http://') || value.startsWith('https://')) return value;

    final base = ApiService.baseUrl.replaceFirst(RegExp(r'/api/?$'), '');
    final clean = value.startsWith('/') ? value.substring(1) : value;
    if (clean.startsWith('uploads/') || clean.startsWith('storage/')) return '$base/$clean';
    return '$base/uploads/stores/$clean';
  }

  String _galleryImage(dynamic data) {
    if (data is Map && data['image'] != null) return data['image'].toString();
    return data?.toString() ?? '';
  }

  List<_SlideItem> get _slides {
    final list = <_SlideItem>[];
    final used = <String>{};

    void add(String? image, ProductVariation? variation) {
      final value = image?.trim() ?? '';
      if (value.isEmpty || value == 'null') return;
      final key = '${variation?.id ?? 0}-$value';
      if (used.add(key)) list.add(_SlideItem(value, variation));
    }

    add(_product.image, null);
    for (final item in _product.galleryImages) {
      add(_galleryImage(item), null);
    }
    for (final item in _product.variations ?? <ProductVariation>[]) {
      add(item.image, item);
    }
    return list;
  }

  Map<String, dynamic>? get _store => _product.store;
  bool get _hasStore => _store != null && (_store!['slug']?.toString().isNotEmpty ?? false);

  double get _regularPrice => _variation?.regularPrice ?? _product.price;
  double? get _salePrice => _variation?.salePrice ?? _product.salePrice;
  bool get _hasPromo => _salePrice != null && _salePrice! > 0 && _salePrice! < _regularPrice;
  double get _activePrice => _hasPromo ? _salePrice! : _regularPrice;
  int get _stock => _variation?.quantity ?? _product.quantity;
  int get _weight => _variation?.weight ?? _product.weight;
  bool get _hasVariation => _product.variations != null && _product.variations!.isNotEmpty;
  bool get _emptyStock => _stock <= 0 || _product.stockStatus != 'instock';

  void _syncSlide(int index) {
    final item = _slides[index];
    setState(() {
      _page = index;
      _variation = item.variation;
      _qty = 1;
    });
  }

  void _goSlide(int target) {
    final items = _slides;
    if (target < 0 || target >= items.length) return;
    _pageController.animateToPage(target, duration: const Duration(milliseconds: 240), curve: Curves.easeOut);
  }

  void _chooseVariation(ProductVariation? value) {
    setState(() {
      _variation = value;
      _qty = 1;
    });
    if (value?.image == null) return;
    final index = _slides.indexWhere((item) => item.variation?.id == value!.id);
    if (index >= 0) _goSlide(index);
  }

  Future<void> _addCart() async {
    if (ApiService.token == null) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Silakan login dulu.')));
      return;
    }
    if (_hasVariation && _variation == null) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Pilih variasi produk dulu.')));
      return;
    }
    setState(() => _saving = true);
    final ok = await CartApiService.addSelectedProductToCart(productId: _product.id, quantity: _qty, variationId: _variation?.id);
    if (!mounted) return;
    setState(() => _saving = false);
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(ok ? 'Produk masuk keranjang.' : 'Gagal menambahkan produk.')));
    if (ok) Navigator.pop(context);
  }

  Widget _priceView() {
    return Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      if (_hasPromo) Text('Rp ${_regularPrice.toStringAsFixed(0)}', style: TextStyle(fontSize: 14, color: Colors.grey.shade600, decoration: TextDecoration.lineThrough)),
      Text('Rp ${_activePrice.toStringAsFixed(0)}', style: const TextStyle(fontSize: 24, fontWeight: FontWeight.w800, color: Color(0xFFE65100))),
    ]);
  }

  Widget _imageArea() {
    final items = _slides;
    if (items.isEmpty) return Container(height: 300, color: Colors.white, child: const Center(child: Icon(Icons.image, size: 90, color: Colors.grey)));
    return Container(
      color: Colors.white,
      child: Column(children: [
        SizedBox(
          height: 300,
          child: Stack(children: [
            PageView.builder(
              controller: _pageController,
              itemCount: items.length,
              onPageChanged: _syncSlide,
              itemBuilder: (context, index) => Image.network(_url(items[index].image), fit: BoxFit.contain, errorBuilder: (_, __, ___) => const Icon(Icons.image_not_supported, size: 90, color: Colors.grey)),
            ),
            if (items.length > 1) ...[
              Positioned(left: 10, top: 120, child: _slideButton(Icons.chevron_left, () => _goSlide(_page - 1))),
              Positioned(right: 10, top: 120, child: _slideButton(Icons.chevron_right, () => _goSlide(_page + 1))),
              Positioned(
                right: 14,
                bottom: 18,
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                  decoration: BoxDecoration(color: Colors.black.withOpacity(0.55), borderRadius: BorderRadius.circular(999)),
                  child: const Row(mainAxisSize: MainAxisSize.min, children: [Text('Geser gambar', style: TextStyle(color: Colors.white, fontSize: 11)), SizedBox(width: 4), Icon(Icons.swipe, color: Colors.white, size: 14)]),
                ),
              ),
            ],
          ]),
        ),
        if (items.length > 1)
          Padding(
            padding: const EdgeInsets.only(bottom: 12),
            child: Row(mainAxisAlignment: MainAxisAlignment.center, children: List.generate(items.length, (index) => AnimatedContainer(duration: const Duration(milliseconds: 180), width: _page == index ? 18 : 8, height: 8, margin: const EdgeInsets.symmetric(horizontal: 3), decoration: BoxDecoration(color: _page == index ? Colors.deepOrange : Colors.grey.shade300, borderRadius: BorderRadius.circular(99))))),
          ),
      ]),
    );
  }

  Widget _slideButton(IconData icon, VoidCallback onTap) {
    return Material(color: Colors.white.withOpacity(0.85), shape: const CircleBorder(), child: InkWell(customBorder: const CircleBorder(), onTap: onTap, child: Padding(padding: const EdgeInsets.all(7), child: Icon(icon, size: 25, color: Colors.black87))));
  }

  List<ProductVariation> get _allVariations => _product.variations ?? <ProductVariation>[];

  Widget _variationChip(ProductVariation item) {
    final selected = _variation?.id == item.id;
    return ChoiceChip(label: Text(item.name, overflow: TextOverflow.ellipsis), selected: selected, selectedColor: Colors.deepOrange, labelStyle: TextStyle(color: selected ? Colors.white : Colors.black87, fontWeight: selected ? FontWeight.bold : FontWeight.w500), onSelected: (value) => _chooseVariation(value ? item : null));
  }

  Widget _variationArea() {
    final variations = _allVariations;
    final visibleVariations = variations.length > 3 ? variations.take(3).toList() : variations;
    return Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      Row(children: [
        const Expanded(child: Text('Pilih Variasi Produk:', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold))),
        if (variations.length > 3) TextButton.icon(onPressed: _showVariationPopup, icon: const Icon(Icons.keyboard_arrow_right), label: const Text('Lainnya')),
      ]),
      const SizedBox(height: 12),
      Wrap(spacing: 8, runSpacing: 8, children: visibleVariations.map(_variationChip).toList()),
    ]);
  }

  void _showVariationPopup() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(18))),
      builder: (context) {
        return SafeArea(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(18, 18, 18, 24),
            child: Column(mainAxisSize: MainAxisSize.min, crossAxisAlignment: CrossAxisAlignment.start, children: [
              Row(children: [const Expanded(child: Text('Semua Variasi Produk', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold))), IconButton(onPressed: () => Navigator.pop(context), icon: const Icon(Icons.close))]),
              const SizedBox(height: 10),
              ConstrainedBox(
                constraints: const BoxConstraints(maxHeight: 320),
                child: SingleChildScrollView(
                  child: Wrap(spacing: 8, runSpacing: 8, children: _allVariations.map((item) {
                    final selected = _variation?.id == item.id;
                    return ChoiceChip(label: Text(item.name), selected: selected, selectedColor: Colors.deepOrange, labelStyle: TextStyle(color: selected ? Colors.white : Colors.black87, fontWeight: selected ? FontWeight.bold : FontWeight.w500), onSelected: (value) { Navigator.pop(context); _chooseVariation(value ? item : null); });
                  }).toList()),
                ),
              ),
            ]),
          ),
        );
      },
    );
  }

  Widget _ratingStars(double rating, {double size = 15}) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: List.generate(5, (index) {
        final starValue = index + 1;
        return Icon(rating >= starValue ? Icons.star : Icons.star_border, color: Colors.amber, size: size);
      }),
    );
  }

  Widget _storeAvatar(String logoUrl) {
    return Container(
      width: 58,
      height: 58,
      clipBehavior: Clip.antiAlias,
      decoration: BoxDecoration(color: const Color(0xFFFFF3E0), shape: BoxShape.circle, border: Border.all(color: Colors.deepOrange.withOpacity(0.25), width: 1.4)),
      child: logoUrl.isNotEmpty
          ? Image.network(logoUrl, fit: BoxFit.cover, errorBuilder: (_, __, ___) => const Icon(Icons.storefront, color: Colors.deepOrange, size: 30))
          : const Icon(Icons.storefront, color: Colors.deepOrange, size: 30),
    );
  }

  Widget _storeSection() {
    final store = _store;
    if (store == null) return const SizedBox.shrink();

    final name = store['name']?.toString() ?? 'Toko';
    final city = store['city_name']?.toString() ?? '';
    final province = store['province_name']?.toString() ?? '';
    final location = [city, province].where((item) => item.isNotEmpty && item != 'null').join(', ');
    final rating = double.tryParse(store['rating_average']?.toString() ?? '0') ?? 0;
    final ratingCount = store['rating_count']?.toString() ?? '0';
    final logoUrl = _storeMediaUrl(store['logo']);

    return Container(
      color: Colors.white,
      margin: const EdgeInsets.only(top: 12),
      padding: const EdgeInsets.all(18),
      child: Row(children: [
        _storeAvatar(logoUrl),
        const SizedBox(width: 12),
        Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Text(name, style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold), maxLines: 1, overflow: TextOverflow.ellipsis),
          const SizedBox(height: 4),
          Text(location.isEmpty ? 'Toko resmi penjual produk ini' : location, style: TextStyle(color: Colors.grey.shade700, fontSize: 12), maxLines: 1, overflow: TextOverflow.ellipsis),
          const SizedBox(height: 6),
          Row(children: [_ratingStars(rating), const SizedBox(width: 6), Text('${rating.toStringAsFixed(1)} ($ratingCount ulasan)', style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600))]),
        ])),
        if (_hasStore)
          OutlinedButton(
            onPressed: () => Navigator.push(context, MaterialPageRoute(builder: (_) => StoreDetailScreen(slug: store['slug'].toString()))),
            style: OutlinedButton.styleFrom(
              foregroundColor: Colors.deepOrange,
              side: const BorderSide(color: Colors.deepOrange, width: 1),
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 7),
              minimumSize: const Size(0, 34),
              tapTargetSize: MaterialTapTargetSize.shrinkWrap,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
            ),
            child: const Text('Lihat Toko', style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600)),
          ),
      ]),
    );
  }

  Widget _descriptionSection() {
    return Container(
      color: Colors.white,
      margin: const EdgeInsets.only(top: 12),
      padding: const EdgeInsets.all(20),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        const Text('Deskripsi Produk', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
        const SizedBox(height: 8),
        Text(_product.description ?? 'Tidak ada deskripsi tersedia.'),
      ]),
    );
  }

  Widget _reviewSummary() {
    final store = _store;
    final rating = double.tryParse(store?['rating_average']?.toString() ?? '0') ?? 0;
    final count = store?['rating_count']?.toString() ?? '0';
    return Container(
      color: Colors.white,
      margin: const EdgeInsets.only(top: 12),
      padding: const EdgeInsets.all(20),
      child: Row(children: [
        const Icon(Icons.reviews, color: Colors.deepOrange),
        const SizedBox(width: 10),
        Expanded(child: Text('Rating toko: ${rating.toStringAsFixed(1)} dari $count ulasan', style: const TextStyle(fontWeight: FontWeight.w600))),
        _ratingStars(rating),
      ]),
    );
  }

  Widget _verifiedReviewsSection() {
    return Container(
      color: Colors.white,
      margin: const EdgeInsets.only(top: 12),
      padding: const EdgeInsets.all(20),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Row(children: [
          const Expanded(child: Text('Ulasan Pembeli', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold))),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 5),
            decoration: BoxDecoration(color: Colors.green.shade50, borderRadius: BorderRadius.circular(999), border: Border.all(color: Colors.green.shade200)),
            child: const Row(mainAxisSize: MainAxisSize.min, children: [
              Icon(Icons.verified, color: Colors.green, size: 14),
              SizedBox(width: 4),
              Text('Terima produk', style: TextStyle(color: Colors.green, fontSize: 11, fontWeight: FontWeight.bold)),
            ]),
          ),
        ]),
        const SizedBox(height: 12),
        if (_loadingReviews)
          const Center(child: Padding(padding: EdgeInsets.all(18), child: CircularProgressIndicator()))
        else if (_productReviews.isEmpty)
          Text('Belum ada testimoni dari pembeli yang sudah menerima produk ini.', style: TextStyle(color: Colors.grey.shade700, height: 1.4))
        else
          ..._productReviews.take(5).map((review) {
            final user = review['user'] is Map ? review['user'] : {};
            final name = user['name']?.toString() ?? 'Pembeli';
            final rating = double.tryParse(review['rating']?.toString() ?? '0') ?? 0;
            final text = review['review']?.toString() ?? '';

            return Container(
              margin: const EdgeInsets.only(bottom: 12),
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(color: const Color(0xFFF8FAFC), borderRadius: BorderRadius.circular(14), border: Border.all(color: Colors.grey.shade200)),
              child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                Row(children: [
                  CircleAvatar(radius: 18, backgroundColor: Colors.deepOrange.shade50, child: Text(name.isNotEmpty ? name[0].toUpperCase() : 'P', style: const TextStyle(color: Colors.deepOrange, fontWeight: FontWeight.bold))),
                  const SizedBox(width: 10),
                  Expanded(child: Text(name, style: const TextStyle(fontWeight: FontWeight.bold))),
                  _ratingStars(rating, size: 14),
                ]),
                const SizedBox(height: 8),
                Text(text.isEmpty ? 'Pembeli tidak menulis komentar.' : text, style: const TextStyle(height: 1.4)),
              ]),
            );
          }),
      ]),
    );
  }

  Widget _recommendationSection() {
    return Container(
      color: Colors.white,
      margin: const EdgeInsets.only(top: 12),
      padding: const EdgeInsets.fromLTRB(20, 20, 20, 24),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        const Text('Mungkin Kamu Suka', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
        const SizedBox(height: 12),
        if (_loadingRecommendations)
          const Center(child: Padding(padding: EdgeInsets.all(18), child: CircularProgressIndicator()))
        else if (_recommendations.isEmpty)
          Text('Belum ada rekomendasi produk lain.', style: TextStyle(color: Colors.grey.shade700))
        else
          GridView.builder(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(crossAxisCount: 2, childAspectRatio: 0.72, crossAxisSpacing: 12, mainAxisSpacing: 12),
            itemCount: _recommendations.length,
            itemBuilder: (context, index) => MarketplaceProductCard(product: _recommendations[index]),
          ),
      ]),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey.shade50,
      appBar: AppBar(title: const Text('Detail Produk'), backgroundColor: Colors.white, foregroundColor: Colors.black87),
      body: ListView(children: [
        _imageArea(),
        const SizedBox(height: 16),
        Container(
          color: Colors.white,
          padding: const EdgeInsets.all(20),
          child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Text(_product.name, style: const TextStyle(fontSize: 22, fontWeight: FontWeight.bold)),
            const SizedBox(height: 10),
            _priceView(),
            const SizedBox(height: 12),
            Text(_emptyStock ? 'Stok habis' : 'Tersedia: $_stock'),
            if (_weight > 0) Text('Berat: $_weight gram'),
            const Divider(height: 32),
            if (_hasVariation) ...[_variationArea(), const Divider(height: 32)],
          ]),
        ),
        _storeSection(),
        _reviewSummary(),
        _descriptionSection(),
        _verifiedReviewsSection(),
        _recommendationSection(),
      ]),
      bottomNavigationBar: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Row(children: [
            IconButton(onPressed: _qty > 1 ? () => setState(() => _qty--) : null, icon: const Icon(Icons.remove)),
            Text('$_qty', style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
            IconButton(onPressed: _qty < _stock ? () => setState(() => _qty++) : null, icon: const Icon(Icons.add)),
            const SizedBox(width: 12),
            Expanded(child: ElevatedButton.icon(onPressed: (_saving || _emptyStock) ? null : _addCart, icon: _saving ? const SizedBox(width: 18, height: 18, child: CircularProgressIndicator(strokeWidth: 2)) : const Icon(Icons.shopping_cart), label: Text(_saving ? 'Menambahkan...' : 'Tambah ke Keranjang'))),
          ]),
        ),
      ),
    );
  }
}

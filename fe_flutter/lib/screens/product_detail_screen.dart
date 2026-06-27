import 'package:flutter/material.dart';
import '../models/product_model.dart';
import '../services/api_service.dart';
import '../services/cart_api_service.dart';
import '../services/marketplace_api_service.dart';
import '../widgets/marketplace_product_card.dart';
import 'cart_screen.dart';
import 'marketplace/chat_room_screen.dart';
import 'marketplace/store_detail_screen.dart';

class ProductDetailScreen extends StatefulWidget {
  final Product product;
  const ProductDetailScreen({Key? key, required this.product}) : super(key: key);

  @override
  State<ProductDetailScreen> createState() => _ProductDetailScreenState();
}

class _ProductDetailScreenState extends State<ProductDetailScreen> {
  static const Color _primary = Color(0xFF0C2442);
  static const Color _bubble = Color(0xFFF8FBFF);
  static const Color _bubbleBorder = Color(0xFFD8E7F8);
  static const Color _muted = Color(0xFF64748B);

  late Product _product;
  ProductVariation? _variation;
  bool _saving = false;
  bool _startingChat = false;
  bool _loadingReviews = true;
  bool _loadingRecommendations = true;
  List<dynamic> _productReviews = [];
  List<Product> _recommendations = [];
  double _productRatingAverage = 0;
  int _productRatingCount = 0;

  @override
  void initState() {
    super.initState();
    _product = widget.product;
    _refreshProductDetail();
    _loadProductReviews();
    _loadRecommendations();
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
    });
  }

  Future<void> _loadProductReviews() async {
    setState(() => _loadingReviews = true);
    final summary = await MarketplaceApiService.productReviewSummary(_product.id);
    if (!mounted) return;
    setState(() {
      _productReviews = summary['data'] as List? ?? [];
      _productRatingAverage = double.tryParse(summary['average']?.toString() ?? '0') ?? 0;
      _productRatingCount = int.tryParse(summary['count']?.toString() ?? '0') ?? 0;
      _loadingReviews = false;
    });
  }

  Future<void> _loadRecommendations() async {
    try {
      final products = await ApiService.getProducts();
      if (!mounted) return;
      final sameCategory = products.where((item) => item.id != _product.id && _product.categoryId != null && item.categoryId == _product.categoryId).toList();
      final others = products.where((item) => item.id != _product.id && !sameCategory.any((same) => same.id == item.id)).toList();
      setState(() {
        _recommendations = [...sameCategory, ...others].take(8).toList();
        _loadingRecommendations = false;
      });
    } catch (_) {
      if (mounted) setState(() => _loadingRecommendations = false);
    }
  }

  String _url(String? image, {String folder = 'products'}) {
    final value = image?.trim() ?? '';
    if (value.isEmpty || value == 'null') return '';
    if (value.startsWith('http')) return value;
    final base = ApiService.baseUrl.replaceFirst(RegExp(r'/api/?$'), '');
    final clean = value.startsWith('/') ? value.substring(1) : value;
    if (clean.startsWith('uploads/') || clean.startsWith('storage/')) return '$base/$clean';
    return '$base/uploads/$folder/$clean';
  }

  String _galleryImage(dynamic data) {
    if (data is Map && data['image'] != null) return data['image'].toString();
    return data?.toString() ?? '';
  }

  DateTime? _date(dynamic value) {
    final raw = value?.toString() ?? '';
    if (raw.isEmpty || raw == 'null') return null;
    return DateTime.tryParse(raw.replaceFirst(' ', 'T'))?.toLocal();
  }

  String _timeText(dynamic value) {
    final date = _date(value);
    if (date == null) return '-';
    final hour = date.hour.toString().padLeft(2, '0');
    final minute = date.minute.toString().padLeft(2, '0');
    const months = ['Jan', 'Feb', 'Mar', 'Apr', 'Mei', 'Jun', 'Jul', 'Agu', 'Sep', 'Okt', 'Nov', 'Des'];
    return '${date.day} ${months[date.month - 1]} ${date.year} • $hour:$minute';
  }

  List<String> get _images {
    final result = <String>[];
    void add(String? value) {
      final clean = value?.trim() ?? '';
      if (clean.isNotEmpty && clean != 'null' && !result.contains(clean)) result.add(clean);
    }
    add(_variation?.image);
    add(_product.image);
    for (final item in _product.galleryImages) add(_galleryImage(item));
    for (final item in _product.variations ?? <ProductVariation>[]) add(item.image);
    return result;
  }

  Map<String, dynamic>? get _store => _product.store;
  bool get _hasStore => _store != null && (_store!['slug']?.toString().isNotEmpty ?? false);
  String get _storeName => _store?['name']?.toString() ?? 'Penjual';
  int? get _sellerId => _product.userId ?? int.tryParse(_store?['user_id']?.toString() ?? '');
  List<ProductVariation> get _allVariations => _product.variations ?? <ProductVariation>[];
  bool get _hasVariation => _allVariations.isNotEmpty;

  double _regularPriceFor(ProductVariation? variation) => variation?.regularPrice ?? _product.price;
  double? _salePriceFor(ProductVariation? variation) => variation?.salePrice ?? _product.salePrice;
  bool _hasPromoFor(ProductVariation? variation) {
    final regular = _regularPriceFor(variation);
    final sale = _salePriceFor(variation);
    return sale != null && sale > 0 && sale < regular;
  }

  double _activePriceFor(ProductVariation? variation) => _hasPromoFor(variation) ? _salePriceFor(variation)! : _regularPriceFor(variation);
  int _stockFor(ProductVariation? variation) => variation?.quantity ?? _product.quantity;
  int _weightFor(ProductVariation? variation) => variation?.weight ?? _product.weight;
  bool _outOfStockFor(ProductVariation? variation) => _product.stockStatus != 'instock' || _stockFor(variation) <= 0;
  bool get _cartUnavailable => _product.stockStatus != 'instock' || (!_hasVariation ? _product.quantity <= 0 : _allVariations.every((item) => item.quantity <= 0));
  String _formatPrice(double value) => 'Rp ${value.toStringAsFixed(0)}';

  Widget _stars(double rating, {double size = 16}) => Row(mainAxisSize: MainAxisSize.min, children: List.generate(5, (index) => Icon(index < rating.round() ? Icons.star_rounded : Icons.star_border_rounded, color: Colors.amber, size: size)));

  Future<void> _openSellerChat() async {
    if (_startingChat) return;
    if (ApiService.token == null) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Silakan login dulu untuk chat penjual.')));
      return;
    }
    final sellerId = _sellerId;
    if (sellerId == null || sellerId <= 0) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Data penjual belum tersedia.')));
      return;
    }
    setState(() => _startingChat = true);
    final conversation = await MarketplaceApiService.startConversation(sellerId: sellerId, productId: _product.id);
    if (!mounted) return;
    setState(() => _startingChat = false);
    final conversationId = int.tryParse(conversation?['id']?.toString() ?? '') ?? 0;
    if (conversationId <= 0) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Gagal membuka chat penjual.')));
      return;
    }
    Navigator.push(context, MaterialPageRoute(builder: (_) => ChatRoomScreen(conversationId: conversationId, title: _storeName)));
  }

  Future<void> _submitCart(ProductVariation? variation, int quantity, {bool openCartAfterAdd = false}) async {
    if (ApiService.token == null) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Silakan login dulu.')));
      return;
    }
    if (_hasVariation && variation == null) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Pilih varian produk dulu.')));
      return;
    }
    if (_outOfStockFor(variation)) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Stok produk tidak tersedia.')));
      return;
    }
    final safeQuantity = quantity.clamp(1, _stockFor(variation)).toInt();
    setState(() => _saving = true);
    final ok = await CartApiService.addSelectedProductToCart(productId: _product.id, quantity: safeQuantity, variationId: variation?.id);
    if (!mounted) return;
    setState(() {
      _saving = false;
      _variation = variation;
    });
    if (ok) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(openCartAfterAdd ? 'Produk masuk keranjang. Membuka keranjang...' : 'Produk masuk keranjang.')));
      if (openCartAfterAdd) Navigator.push(context, MaterialPageRoute(builder: (_) => const CartScreen()));
    } else {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(CartApiService.lastError ?? 'Gagal menambahkan produk.')));
      _refreshProductDetail();
    }
  }

  void _showAddCartSheet({bool openCartAfterAdd = false}) {
    if (_cartUnavailable) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Stok produk tidak tersedia.')));
      return;
    }
    ProductVariation? selected = _variation;
    int quantity = 1;
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(22))),
      builder: (sheetContext) => StatefulBuilder(builder: (context, setSheetState) {
        final maxStock = _hasVariation && selected == null ? 0 : _stockFor(selected);
        final missingVariant = _hasVariation && selected == null;
        final outOfStock = !missingVariant && _outOfStockFor(selected);
        return SafeArea(child: Padding(padding: const EdgeInsets.fromLTRB(18, 14, 18, 18), child: Column(mainAxisSize: MainAxisSize.min, crossAxisAlignment: CrossAxisAlignment.start, children: [
          Center(child: Container(width: 42, height: 4, decoration: BoxDecoration(color: Colors.grey.shade300, borderRadius: BorderRadius.circular(99)))),
          const SizedBox(height: 16),
          Text(_product.name, maxLines: 2, overflow: TextOverflow.ellipsis, style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
          const SizedBox(height: 8),
          Text(_formatPrice(_activePriceFor(selected)), style: const TextStyle(fontSize: 21, color: Colors.deepOrange, fontWeight: FontWeight.w900)),
          const SizedBox(height: 8),
          Text(missingVariant ? 'Pilih varian dulu' : outOfStock ? 'Stok habis' : 'Stok: $maxStock', style: TextStyle(color: outOfStock ? Colors.red : Colors.grey.shade700, fontWeight: FontWeight.w700)),
          if (_hasVariation) ...[const SizedBox(height: 16), const Text('Pilih Varian', style: TextStyle(fontWeight: FontWeight.bold)), const SizedBox(height: 8), Wrap(spacing: 8, runSpacing: 8, children: _allVariations.map((item) { final available = item.quantity > 0 && _product.stockStatus == 'instock'; return ChoiceChip(label: Text(available ? item.name : '${item.name} (habis)'), selected: selected?.id == item.id, onSelected: available ? (_) => setSheetState(() { selected = item; quantity = 1; }) : null); }).toList())],
          const SizedBox(height: 16),
          Row(children: [const Expanded(child: Text('Jumlah', style: TextStyle(fontWeight: FontWeight.bold))), IconButton(onPressed: quantity > 1 ? () => setSheetState(() => quantity--) : null, icon: const Icon(Icons.remove)), Text('$quantity', style: const TextStyle(fontWeight: FontWeight.w900)), IconButton(onPressed: !missingVariant && !outOfStock && quantity < maxStock ? () => setSheetState(() => quantity++) : null, icon: const Icon(Icons.add))]),
          const SizedBox(height: 12),
          SizedBox(width: double.infinity, child: ElevatedButton.icon(onPressed: !missingVariant && !outOfStock && !_saving ? () { Navigator.pop(sheetContext); _submitCart(selected, quantity, openCartAfterAdd: openCartAfterAdd); } : null, icon: Icon(openCartAfterAdd ? Icons.shopping_bag_rounded : Icons.shopping_cart), label: Text(openCartAfterAdd ? 'Pesan Sekarang' : 'Masukkan Keranjang'))),
        ])));
      }),
    );
  }

  Future<void> _showProductReviewSheet() async {
    if (ApiService.token == null) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Silakan login dulu untuk memberi ulasan.')));
      return;
    }
    int rating = 5;
    bool submitting = false;
    String? errorMessage;
    final controller = TextEditingController();
    final saved = await showModalBottomSheet<bool>(
      context: context,
      isScrollControlled: true,
      isDismissible: false,
      enableDrag: false,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(22))),
      builder: (sheetContext) => StatefulBuilder(builder: (context, setSheetState) {
        return Padding(padding: EdgeInsets.fromLTRB(18, 16, 18, 18 + MediaQuery.of(sheetContext).viewInsets.bottom), child: Column(mainAxisSize: MainAxisSize.min, crossAxisAlignment: CrossAxisAlignment.start, children: [
          Row(children: [const Expanded(child: Text('Beri Ulasan Produk', style: TextStyle(fontSize: 18, fontWeight: FontWeight.w900, color: _primary))), IconButton(onPressed: submitting ? null : () => Navigator.of(sheetContext).pop(false), icon: const Icon(Icons.close_rounded))]),
          Text(_product.name, maxLines: 2, overflow: TextOverflow.ellipsis, style: const TextStyle(color: _muted, fontWeight: FontWeight.w700)),
          const SizedBox(height: 12),
          Row(children: List.generate(5, (index) => IconButton(onPressed: submitting ? null : () => setSheetState(() => rating = index + 1), icon: Icon(index < rating ? Icons.star_rounded : Icons.star_border_rounded, color: Colors.amber, size: 34)))),
          TextField(controller: controller, enabled: !submitting, maxLines: 4, decoration: const InputDecoration(labelText: 'Komentar', hintText: 'Tulis pengalaman kamu tentang produk ini', border: OutlineInputBorder())),
          if (errorMessage != null) ...[const SizedBox(height: 10), Text(errorMessage!, style: const TextStyle(color: Colors.red, fontSize: 12, fontWeight: FontWeight.w700))],
          const SizedBox(height: 14),
          SizedBox(width: double.infinity, child: ElevatedButton.icon(onPressed: submitting ? null : () async { setSheetState(() { submitting = true; errorMessage = null; }); final ok = await MarketplaceApiService.addProductReview(productId: _product.id, rating: rating, review: controller.text.trim()); if (!mounted) return; if (ok) { Navigator.of(sheetContext).pop(true); return; } setSheetState(() { submitting = false; errorMessage = MarketplaceApiService.lastError ?? 'Gagal menyimpan ulasan produk.'; }); }, icon: submitting ? const SizedBox(width: 17, height: 17, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white)) : const Icon(Icons.star_rounded), label: Text(submitting ? 'MENYIMPAN...' : 'KIRIM ULASAN'))),
        ]));
      }),
    );
    controller.dispose();
    if (!mounted) return;
    if (saved == true) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Ulasan produk berhasil disimpan.')));
      _loadProductReviews();
    }
  }

  Widget _imageArea() {
    final images = _images;
    if (images.isEmpty) return Container(height: 300, color: Colors.white, child: const Center(child: Icon(Icons.image, size: 90, color: Colors.grey)));
    return Container(height: 310, color: Colors.white, child: PageView.builder(itemCount: images.length, itemBuilder: (context, index) => Image.network(_url(images[index]), fit: BoxFit.contain, errorBuilder: (_, __, ___) => const Icon(Icons.image_not_supported, size: 90, color: Colors.grey))));
  }

  Widget _priceView() => Column(crossAxisAlignment: CrossAxisAlignment.start, children: [if (_hasPromoFor(_variation)) Text(_formatPrice(_regularPriceFor(_variation)), style: TextStyle(fontSize: 14, color: Colors.grey.shade600, decoration: TextDecoration.lineThrough)), Text(_formatPrice(_activePriceFor(_variation)), style: const TextStyle(fontSize: 24, fontWeight: FontWeight.w900, color: Color(0xFFE65100)))]);

  Widget _storeSection() {
    final store = _store;
    if (store == null) return const SizedBox.shrink();
    final rating = double.tryParse(store['rating_average']?.toString() ?? '0') ?? 0;
    final count = store['rating_count']?.toString() ?? '0';
    final logo = _url(store['logo']?.toString(), folder: 'stores');
    return Container(color: Colors.white, margin: const EdgeInsets.only(top: 12), padding: const EdgeInsets.all(18), child: Row(children: [CircleAvatar(radius: 28, backgroundColor: const Color(0xFFFFF3E0), backgroundImage: logo.isNotEmpty ? NetworkImage(logo) : null, child: logo.isEmpty ? const Icon(Icons.storefront, color: Colors.deepOrange) : null), const SizedBox(width: 12), Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [Text(_storeName, style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold)), const SizedBox(height: 5), Row(children: [_stars(rating), const SizedBox(width: 6), Text('${rating.toStringAsFixed(1)} ($count ulasan)', style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600))])])), if (_hasStore) TextButton(onPressed: () => Navigator.push(context, MaterialPageRoute(builder: (_) => StoreDetailScreen(slug: store['slug'].toString()))), child: const Text('Lihat Toko'))]));
  }

  Widget _reviewBubble(dynamic rawReview) {
    final review = rawReview is Map ? Map<String, dynamic>.from(rawReview) : <String, dynamic>{};
    final user = review['user'] is Map ? Map<String, dynamic>.from(review['user']) : <String, dynamic>{};
    final name = user['name']?.toString() ?? 'Pengulas';
    final rating = double.tryParse(review['rating']?.toString() ?? '0') ?? 0;
    final text = review['review']?.toString() ?? '';
    return Container(margin: const EdgeInsets.only(bottom: 12), padding: const EdgeInsets.all(13), decoration: BoxDecoration(color: _bubble, borderRadius: BorderRadius.circular(18), border: Border.all(color: _bubbleBorder), boxShadow: [BoxShadow(color: _primary.withOpacity(.035), blurRadius: 10, offset: const Offset(0, 5))]), child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [Row(children: [CircleAvatar(radius: 17, backgroundColor: _primary.withOpacity(.10), child: Text(name.isNotEmpty ? name[0].toUpperCase() : 'P', style: const TextStyle(color: _primary, fontWeight: FontWeight.w900))), const SizedBox(width: 9), Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [Row(children: [Flexible(child: Text(name, maxLines: 1, overflow: TextOverflow.ellipsis, style: const TextStyle(color: _primary, fontWeight: FontWeight.w900))), const SizedBox(width: 7), Text(_timeText(review['created_at']), style: const TextStyle(color: _muted, fontSize: 10.5, fontWeight: FontWeight.w700))]), const SizedBox(height: 3), _stars(rating, size: 14)]))]), const SizedBox(height: 9), Text(text.isEmpty ? 'Pengulas tidak menulis komentar.' : text, style: const TextStyle(fontSize: 13, height: 1.45, color: Color(0xFF1F2937), fontWeight: FontWeight.w500))]));
  }

  Widget _reviewSection() => Container(color: Colors.white, margin: const EdgeInsets.only(top: 12), padding: const EdgeInsets.all(20), child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Row(children: [const Expanded(child: Text('Ulasan Produk', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: _primary))), TextButton.icon(onPressed: _showProductReviewSheet, icon: const Icon(Icons.star_border_rounded, size: 18), label: const Text('Beri Ulasan'))]),
        const SizedBox(height: 8),
        Row(children: [_stars(_productRatingAverage), const SizedBox(width: 8), Text('${_productRatingAverage.toStringAsFixed(1)} ($_productRatingCount ulasan)', style: const TextStyle(fontWeight: FontWeight.w800, color: _primary))]),
        const SizedBox(height: 12),
        if (_loadingReviews) const Center(child: Padding(padding: EdgeInsets.all(18), child: CircularProgressIndicator())) else if (_productReviews.isEmpty) const Text('Belum ada ulasan produk.', style: TextStyle(color: _muted)) else ..._productReviews.take(8).map(_reviewBubble),
      ]));

  Widget _recommendationSection() => Container(color: Colors.white, margin: const EdgeInsets.only(top: 12), padding: const EdgeInsets.fromLTRB(20, 20, 20, 24), child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [const Text('Mungkin Kamu Suka', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)), const SizedBox(height: 12), if (_loadingRecommendations) const Center(child: Padding(padding: EdgeInsets.all(18), child: CircularProgressIndicator())) else if (_recommendations.isEmpty) Text('Belum ada rekomendasi produk lain.', style: TextStyle(color: Colors.grey.shade700)) else GridView.builder(shrinkWrap: true, physics: const NeverScrollableScrollPhysics(), gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(crossAxisCount: 2, childAspectRatio: 0.72, crossAxisSpacing: 12, mainAxisSpacing: 12), itemCount: _recommendations.length, itemBuilder: (context, index) => MarketplaceProductCard(product: _recommendations[index]))]));

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey.shade50,
      appBar: AppBar(title: const Text('Detail Produk'), backgroundColor: Colors.white, foregroundColor: Colors.black87, actions: [IconButton(tooltip: 'Chat Penjual', onPressed: _startingChat ? null : _openSellerChat, icon: _startingChat ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2)) : const Icon(Icons.chat_bubble_outline))]),
      body: ListView(children: [
        _imageArea(),
        const SizedBox(height: 16),
        Container(color: Colors.white, padding: const EdgeInsets.all(20), child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [Text(_product.name, style: const TextStyle(fontSize: 22, fontWeight: FontWeight.bold)), const SizedBox(height: 10), _priceView(), const SizedBox(height: 10), Row(children: [_stars(_productRatingAverage), const SizedBox(width: 6), Text('${_productRatingAverage.toStringAsFixed(1)} ($_productRatingCount ulasan)', style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w700))]), const SizedBox(height: 12), Text(_cartUnavailable ? 'Stok habis' : _hasVariation && _variation == null ? 'Varian tersedia: ${_allVariations.length}' : 'Tersedia: ${_stockFor(_variation)}'), if (_weightFor(_variation) > 0) Text('Berat: ${_weightFor(_variation)} gram') ])),
        _storeSection(),
        Container(color: Colors.white, margin: const EdgeInsets.only(top: 12), padding: const EdgeInsets.all(20), child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [const Text('Deskripsi Produk', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)), const SizedBox(height: 8), Text(_product.description ?? 'Tidak ada deskripsi tersedia.')])),
        _recommendationSection(),
        _reviewSection(),
      ]),
      bottomNavigationBar: SafeArea(child: Padding(padding: const EdgeInsets.all(16), child: Row(children: [SizedBox(width: 48, height: 48, child: OutlinedButton(onPressed: _startingChat ? null : _openSellerChat, style: OutlinedButton.styleFrom(padding: EdgeInsets.zero, foregroundColor: Colors.green.shade700, side: BorderSide(color: Colors.green.shade600), shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12))), child: _startingChat ? const SizedBox(width: 18, height: 18, child: CircularProgressIndicator(strokeWidth: 2)) : const Icon(Icons.chat_bubble_outline))), const SizedBox(width: 8), Expanded(child: OutlinedButton.icon(onPressed: (_saving || _cartUnavailable) ? null : () => _showAddCartSheet(), icon: const Icon(Icons.shopping_cart, size: 18), label: const Text('Keranjang'), style: OutlinedButton.styleFrom(padding: const EdgeInsets.symmetric(vertical: 14), shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12))))), const SizedBox(width: 8), Expanded(child: ElevatedButton.icon(onPressed: (_saving || _cartUnavailable) ? null : () => _showAddCartSheet(openCartAfterAdd: true), icon: _saving ? const SizedBox(width: 18, height: 18, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white)) : const Icon(Icons.shopping_bag_rounded, size: 18), label: Text(_saving ? 'Proses...' : 'Pesan Sekarang'), style: ElevatedButton.styleFrom(padding: const EdgeInsets.symmetric(vertical: 14), shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)))))]))),
    );
  }
}

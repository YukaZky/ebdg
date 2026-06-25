import 'package:flutter/material.dart';
import '../models/product_model.dart';
import '../services/api_service.dart';
import '../services/cart_api_service.dart';
import '../services/marketplace_api_service.dart';
import '../widgets/marketplace_product_card.dart';
import 'marketplace/chat_room_screen.dart';
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
  bool _startingChat = false;
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
  String get _storeName => _store?['name']?.toString() ?? 'Penjual';
  int? get _sellerId => _product.userId ?? int.tryParse(_store?['user_id']?.toString() ?? '');

  List<ProductVariation> get _allVariations => _product.variations ?? <ProductVariation>[];
  bool get _hasVariation => _allVariations.isNotEmpty;

  double _regularPriceFor(ProductVariation? variation) => variation?.regularPrice ?? _product.price;
  double? _salePriceFor(ProductVariation? variation) => variation?.salePrice ?? _product.salePrice;
  bool _hasPromoFor(ProductVariation? variation) {
    final regularPrice = _regularPriceFor(variation);
    final salePrice = _salePriceFor(variation);
    return salePrice != null && salePrice > 0 && salePrice < regularPrice;
  }

  double _activePriceFor(ProductVariation? variation) {
    final salePrice = _salePriceFor(variation);
    return _hasPromoFor(variation) ? salePrice! : _regularPriceFor(variation);
  }

  int _stockFor(ProductVariation? variation) => variation?.quantity ?? _product.quantity;
  int _weightFor(ProductVariation? variation) => variation?.weight ?? _product.weight;
  bool _outOfStockFor(ProductVariation? variation) => _product.stockStatus != 'instock' || _stockFor(variation) <= 0;

  double get _regularPrice => _regularPriceFor(_variation);
  double? get _salePrice => _salePriceFor(_variation);
  bool get _hasPromo => _hasPromoFor(_variation);
  double get _activePrice => _activePriceFor(_variation);
  int get _stock => _stockFor(_variation);
  int get _weight => _weightFor(_variation);
  bool get _emptyStock => _outOfStockFor(_variation);
  bool get _cartUnavailable {
    if (_product.stockStatus != 'instock') return true;
    if (!_hasVariation) return _product.quantity <= 0;
    return _allVariations.every((item) => item.quantity <= 0);
  }

  String _formatPrice(double value) => 'Rp ${value.toStringAsFixed(0)}';

  String _imageForSelection(ProductVariation? variation) {
    final variantImage = variation?.image?.trim() ?? '';
    if (variantImage.isNotEmpty && variantImage != 'null') return variantImage;
    return _product.image ?? '';
  }

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

    Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => ChatRoomScreen(conversationId: conversationId, title: _storeName)),
    );
  }

  Future<void> _submitCartFromSheet({
    required BuildContext sheetContext,
    required ProductVariation? variation,
    required int quantity,
    required void Function(bool value) setSubmitting,
  }) async {
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

    final maxStock = _stockFor(variation);
    final safeQuantity = quantity.clamp(1, maxStock).toInt();

    setSubmitting(true);
    setState(() => _saving = true);
    final ok = await CartApiService.addSelectedProductToCart(productId: _product.id, quantity: safeQuantity, variationId: variation?.id);
    if (!mounted) return;

    setState(() {
      _saving = false;
      _variation = variation;
      _qty = safeQuantity;
    });

    if (ok) {
      if (Navigator.canPop(sheetContext)) Navigator.pop(sheetContext);
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Produk masuk keranjang.')));
    } else {
      setSubmitting(false);
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Gagal menambahkan produk.')));
    }
  }

  Widget _priceView() {
    return Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      if (_hasPromo) Text(_formatPrice(_regularPrice), style: TextStyle(fontSize: 14, color: Colors.grey.shade600, decoration: TextDecoration.lineThrough)),
      Text(_formatPrice(_activePrice), style: const TextStyle(fontSize: 24, fontWeight: FontWeight.w800, color: Color(0xFFE65100))),
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

  Widget _variantInfoRow() {
    if (!_hasVariation) return const SizedBox.shrink();
    final selected = _variation?.name;
    return Row(children: [
      const Icon(Icons.tune, color: Colors.deepOrange, size: 18),
      const SizedBox(width: 8),
      Expanded(
        child: Text(
          selected == null ? '${_allVariations.length} varian tersedia. Pilih saat tambah ke keranjang.' : 'Varian dipilih: $selected',
          style: TextStyle(color: Colors.grey.shade800, fontWeight: FontWeight.w600),
        ),
      ),
    ]);
  }

  void _showAddCartSheet() {
    if (_cartUnavailable) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Stok produk tidak tersedia.')));
      return;
    }

    ProductVariation? selectedVariation = _variation;
    int quantity = _qty;
    if (_hasVariation && selectedVariation != null && _outOfStockFor(selectedVariation)) {
      selectedVariation = null;
      quantity = 1;
    }
    if (!_hasVariation) {
      quantity = quantity.clamp(1, _product.quantity).toInt();
    }
    bool submitting = false;

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(22))),
      builder: (sheetContext) {
        return StatefulBuilder(builder: (context, setModalState) {
          final maxStock = _hasVariation && selectedVariation == null ? 0 : _stockFor(selectedVariation);
          final missingVariant = _hasVariation && selectedVariation == null;
          final selectedOutOfStock = !missingVariant && _outOfStockFor(selectedVariation);
          final canMinus = !submitting && quantity > 1;
          final canPlus = !submitting && !missingVariant && !selectedOutOfStock && quantity < maxStock;
          final canSubmit = !submitting && !missingVariant && !selectedOutOfStock && quantity >= 1;
          final selectedRegularPrice = _regularPriceFor(selectedVariation);
          final selectedActivePrice = _activePriceFor(selectedVariation);
          final selectedHasPromo = _hasPromoFor(selectedVariation);
          final selectedWeight = _weightFor(selectedVariation);
          final productImage = _url(_imageForSelection(selectedVariation));

          void updateSubmitting(bool value) {
            setModalState(() => submitting = value);
          }

          return SafeArea(
            child: Padding(
              padding: EdgeInsets.fromLTRB(18, 12, 18, 18 + MediaQuery.of(sheetContext).viewInsets.bottom),
              child: Column(mainAxisSize: MainAxisSize.min, crossAxisAlignment: CrossAxisAlignment.start, children: [
                Center(
                  child: Container(
                    width: 42,
                    height: 4,
                    decoration: BoxDecoration(color: Colors.grey.shade300, borderRadius: BorderRadius.circular(99)),
                  ),
                ),
                const SizedBox(height: 16),
                Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
                  Container(
                    width: 86,
                    height: 86,
                    clipBehavior: Clip.antiAlias,
                    decoration: BoxDecoration(color: Colors.grey.shade100, borderRadius: BorderRadius.circular(14), border: Border.all(color: Colors.grey.shade200)),
                    child: productImage.isEmpty
                        ? const Icon(Icons.image, color: Colors.grey, size: 36)
                        : Image.network(productImage, fit: BoxFit.cover, errorBuilder: (_, __, ___) => const Icon(Icons.image_not_supported, color: Colors.grey, size: 36)),
                  ),
                  const SizedBox(width: 12),
                  Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                    Text(_product.name, maxLines: 2, overflow: TextOverflow.ellipsis, style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                    const SizedBox(height: 6),
                    if (selectedHasPromo) Text(_formatPrice(selectedRegularPrice), style: TextStyle(fontSize: 12, color: Colors.grey.shade600, decoration: TextDecoration.lineThrough)),
                    Text(_formatPrice(selectedActivePrice), style: const TextStyle(fontSize: 20, color: Colors.deepOrange, fontWeight: FontWeight.w800)),
                    const SizedBox(height: 4),
                    Text(
                      missingVariant ? 'Pilih varian untuk melihat stok' : selectedOutOfStock ? 'Stok habis' : 'Stok: $maxStock',
                      style: TextStyle(color: selectedOutOfStock ? Colors.red : Colors.grey.shade700, fontWeight: FontWeight.w600),
                    ),
                    if (selectedWeight > 0) Text('Berat: $selectedWeight gram', style: TextStyle(color: Colors.grey.shade600, fontSize: 12)),
                  ])),
                  IconButton(onPressed: submitting ? null : () => Navigator.pop(sheetContext), icon: const Icon(Icons.close)),
                ]),
                if (_hasVariation) ...[
                  const SizedBox(height: 20),
                  const Text('Pilih Varian', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                  const SizedBox(height: 10),
                  ConstrainedBox(
                    constraints: const BoxConstraints(maxHeight: 230),
                    child: SingleChildScrollView(
                      child: Wrap(spacing: 8, runSpacing: 8, children: _allVariations.map((item) {
                        final selected = selectedVariation?.id == item.id;
                        final available = item.quantity > 0 && _product.stockStatus == 'instock';
                        return ChoiceChip(
                          label: Text(available ? item.name : '${item.name} (habis)', overflow: TextOverflow.ellipsis),
                          selected: selected,
                          selectedColor: Colors.deepOrange,
                          disabledColor: Colors.grey.shade100,
                          labelStyle: TextStyle(
                            color: selected ? Colors.white : available ? Colors.black87 : Colors.grey.shade500,
                            fontWeight: selected ? FontWeight.bold : FontWeight.w600,
                          ),
                          onSelected: available && !submitting
                              ? (_) {
                                  setModalState(() {
                                    selectedVariation = item;
                                    quantity = 1;
                                  });
                                  _chooseVariation(item);
                                }
                              : null,
                        );
                      }).toList()),
                    ),
                  ),
                ],
                const SizedBox(height: 20),
                Row(children: [
                  const Expanded(child: Text('Jumlah', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold))),
                  Container(
                    decoration: BoxDecoration(border: Border.all(color: Colors.grey.shade300), borderRadius: BorderRadius.circular(12)),
                    child: Row(mainAxisSize: MainAxisSize.min, children: [
                      IconButton(
                        visualDensity: VisualDensity.compact,
                        onPressed: canMinus ? () => setModalState(() => quantity--) : null,
                        icon: const Icon(Icons.remove),
                      ),
                      SizedBox(width: 34, child: Text('$quantity', textAlign: TextAlign.center, style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold))),
                      IconButton(
                        visualDensity: VisualDensity.compact,
                        onPressed: canPlus ? () => setModalState(() => quantity++) : null,
                        icon: const Icon(Icons.add),
                      ),
                    ]),
                  ),
                ]),
                const SizedBox(height: 6),
                Text(
                  missingVariant ? 'Jumlah bisa diatur setelah varian dipilih.' : 'Maksimal $maxStock produk.',
                  style: TextStyle(color: Colors.grey.shade600, fontSize: 12),
                ),
                const SizedBox(height: 18),
                SizedBox(
                  width: double.infinity,
                  height: 48,
                  child: ElevatedButton.icon(
                    onPressed: canSubmit
                        ? () => _submitCartFromSheet(
                              sheetContext: sheetContext,
                              variation: selectedVariation,
                              quantity: quantity,
                              setSubmitting: updateSubmitting,
                            )
                        : null,
                    icon: submitting ? const SizedBox(width: 18, height: 18, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white)) : const Icon(Icons.shopping_cart),
                    label: Text(submitting ? 'Menambahkan...' : missingVariant ? 'Pilih Varian Dulu' : 'Masukkan Keranjang'),
                  ),
                ),
              ]),
            ),
          );
        });
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
        Column(mainAxisSize: MainAxisSize.min, children: [
          OutlinedButton.icon(
            onPressed: _startingChat ? null : _openSellerChat,
            icon: _startingChat ? const SizedBox(width: 14, height: 14, child: CircularProgressIndicator(strokeWidth: 2)) : const Icon(Icons.chat_bubble_outline, size: 16),
            label: const Text('Chat', style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600)),
            style: OutlinedButton.styleFrom(
              foregroundColor: Colors.green.shade700,
              side: BorderSide(color: Colors.green.shade600, width: 1),
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 7),
              minimumSize: const Size(0, 34),
              tapTargetSize: MaterialTapTargetSize.shrinkWrap,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
            ),
          ),
          if (_hasStore) ...[
            const SizedBox(height: 8),
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
          ],
        ]),
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
      appBar: AppBar(
        title: const Text('Detail Produk'),
        backgroundColor: Colors.white,
        foregroundColor: Colors.black87,
        actions: [
          IconButton(
            tooltip: 'Chat Penjual',
            onPressed: _startingChat ? null : _openSellerChat,
            icon: _startingChat ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2)) : const Icon(Icons.chat_bubble_outline),
          ),
        ],
      ),
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
            Text(_cartUnavailable ? 'Stok habis' : _hasVariation && _variation == null ? 'Varian tersedia: ${_allVariations.length}' : 'Tersedia: $_stock'),
            if (_weight > 0) Text('Berat: $_weight gram'),
            if (_hasVariation) ...[
              const SizedBox(height: 12),
              _variantInfoRow(),
            ],
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
            SizedBox(
              width: 52,
              height: 48,
              child: OutlinedButton(
                onPressed: _startingChat ? null : _openSellerChat,
                style: OutlinedButton.styleFrom(
                  padding: EdgeInsets.zero,
                  foregroundColor: Colors.green.shade700,
                  side: BorderSide(color: Colors.green.shade600),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                ),
                child: _startingChat ? const SizedBox(width: 18, height: 18, child: CircularProgressIndicator(strokeWidth: 2)) : const Icon(Icons.chat_bubble_outline),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: ElevatedButton.icon(
                onPressed: (_saving || _cartUnavailable) ? null : _showAddCartSheet,
                icon: _saving ? const SizedBox(width: 18, height: 18, child: CircularProgressIndicator(strokeWidth: 2)) : const Icon(Icons.shopping_cart),
                label: Text(_saving ? 'Menambahkan...' : 'Masukkan Keranjang'),
              ),
            ),
          ]),
        ),
      ),
    );
  }
}

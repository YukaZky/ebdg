import 'package:flutter/material.dart';
import '../models/product_model.dart';
import '../services/api_service.dart';
import '../services/cart_api_service.dart';

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
  ProductVariation? _variation;
  int _page = 0;
  int _qty = 1;
  bool _saving = false;

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
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

    add(widget.product.image, null);
    for (final item in widget.product.galleryImages) {
      add(_galleryImage(item), null);
    }
    for (final item in widget.product.variations ?? <ProductVariation>[]) {
      add(item.image, item);
    }
    return list;
  }

  double get _regularPrice => _variation?.regularPrice ?? widget.product.price;
  double? get _salePrice => _variation?.salePrice ?? widget.product.salePrice;
  bool get _hasPromo => _salePrice != null && _salePrice! > 0 && _salePrice! < _regularPrice;
  double get _activePrice => _hasPromo ? _salePrice! : _regularPrice;
  int get _stock => _variation?.quantity ?? widget.product.quantity;
  int get _weight => _variation?.weight ?? widget.product.weight;
  bool get _hasVariation => widget.product.variations != null && widget.product.variations!.isNotEmpty;
  bool get _emptyStock => _stock <= 0 || widget.product.stockStatus != 'instock';

  void _syncSlide(int index) {
    final items = _slides;
    final item = items[index];
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
    final ok = await CartApiService.addSelectedProductToCart(productId: widget.product.id, quantity: _qty, variationId: _variation?.id);
    if (!mounted) return;
    setState(() => _saving = false);
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(ok ? 'Produk masuk keranjang.' : 'Gagal menambahkan produk.')));
    if (ok) Navigator.pop(context);
  }

  Widget _priceView() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (_hasPromo)
          Text(
            'Rp ${_regularPrice.toStringAsFixed(0)}',
            style: TextStyle(fontSize: 14, color: Colors.grey.shade600, decoration: TextDecoration.lineThrough),
          ),
        Text(
          'Rp ${_activePrice.toStringAsFixed(0)}',
          style: const TextStyle(fontSize: 24, fontWeight: FontWeight.w800, color: Color(0xFFE65100)),
        ),
      ],
    );
  }

  Widget _imageArea() {
    final items = _slides;
    if (items.isEmpty) {
      return Container(height: 300, color: Colors.white, child: const Center(child: Icon(Icons.image, size: 90, color: Colors.grey)));
    }
    return Container(
      color: Colors.white,
      child: Column(
        children: [
          SizedBox(
            height: 300,
            child: Stack(
              children: [
                PageView.builder(
                  controller: _pageController,
                  itemCount: items.length,
                  onPageChanged: _syncSlide,
                  itemBuilder: (context, index) => Image.network(_url(items[index].image), fit: BoxFit.contain, errorBuilder: (_, __, ___) => const Icon(Icons.image_not_supported, size: 90, color: Colors.grey)),
                ),
                if (items.length > 1) ...[
                  Positioned(
                    left: 10,
                    top: 120,
                    child: _slideButton(Icons.chevron_left, () => _goSlide(_page - 1)),
                  ),
                  Positioned(
                    right: 10,
                    top: 120,
                    child: _slideButton(Icons.chevron_right, () => _goSlide(_page + 1)),
                  ),
                  Positioned(
                    right: 14,
                    bottom: 18,
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                      decoration: BoxDecoration(color: Colors.black.withOpacity(0.55), borderRadius: BorderRadius.circular(999)),
                      child: const Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Text('Geser gambar', style: TextStyle(color: Colors.white, fontSize: 11)),
                          SizedBox(width: 4),
                          Icon(Icons.swipe, color: Colors.white, size: 14),
                        ],
                      ),
                    ),
                  ),
                ],
              ],
            ),
          ),
          if (items.length > 1)
            Padding(
              padding: const EdgeInsets.only(bottom: 12),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: List.generate(items.length, (index) => AnimatedContainer(
                      duration: const Duration(milliseconds: 180),
                      width: _page == index ? 18 : 8,
                      height: 8,
                      margin: const EdgeInsets.symmetric(horizontal: 3),
                      decoration: BoxDecoration(color: _page == index ? Colors.deepOrange : Colors.grey.shade300, borderRadius: BorderRadius.circular(99)),
                    )),
              ),
            ),
        ],
      ),
    );
  }

  Widget _slideButton(IconData icon, VoidCallback onTap) {
    return Material(
      color: Colors.white.withOpacity(0.85),
      shape: const CircleBorder(),
      child: InkWell(
        customBorder: const CircleBorder(),
        onTap: onTap,
        child: Padding(padding: const EdgeInsets.all(7), child: Icon(icon, size: 25, color: Colors.black87)),
      ),
    );
  }

  List<ProductVariation> get _allVariations => widget.product.variations ?? <ProductVariation>[];

  Widget _variationChip(ProductVariation item) {
    final selected = _variation?.id == item.id;
    return ChoiceChip(
      label: Text(item.name, overflow: TextOverflow.ellipsis),
      selected: selected,
      selectedColor: Colors.deepOrange,
      labelStyle: TextStyle(color: selected ? Colors.white : Colors.black87, fontWeight: selected ? FontWeight.bold : FontWeight.w500),
      onSelected: (value) => _chooseVariation(value ? item : null),
    );
  }

  Widget _variationArea() {
    final variations = _allVariations;
    final visibleVariations = variations.length > 3 ? variations.take(3).toList() : variations;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            const Expanded(child: Text('Pilih Variasi Produk:', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold))),
            if (variations.length > 3)
              TextButton.icon(
                onPressed: _showVariationPopup,
                icon: const Icon(Icons.keyboard_arrow_right),
                label: const Text('Lainnya'),
              ),
          ],
        ),
        const SizedBox(height: 12),
        Wrap(spacing: 8, runSpacing: 8, children: visibleVariations.map(_variationChip).toList()),
      ],
    );
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
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    const Expanded(child: Text('Semua Variasi Produk', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold))),
                    IconButton(onPressed: () => Navigator.pop(context), icon: const Icon(Icons.close)),
                  ],
                ),
                const SizedBox(height: 10),
                ConstrainedBox(
                  constraints: const BoxConstraints(maxHeight: 320),
                  child: SingleChildScrollView(
                    child: Wrap(spacing: 8, runSpacing: 8, children: _allVariations.map((item) {
                      final selected = _variation?.id == item.id;
                      return ChoiceChip(
                        label: Text(item.name),
                        selected: selected,
                        selectedColor: Colors.deepOrange,
                        labelStyle: TextStyle(color: selected ? Colors.white : Colors.black87, fontWeight: selected ? FontWeight.bold : FontWeight.w500),
                        onSelected: (value) {
                          Navigator.pop(context);
                          _chooseVariation(value ? item : null);
                        },
                      );
                    }).toList()),
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey.shade50,
      appBar: AppBar(title: const Text('Detail Produk'), backgroundColor: Colors.white, foregroundColor: Colors.black87),
      body: ListView(
        children: [
          _imageArea(),
          const SizedBox(height: 16),
          Container(
            color: Colors.white,
            padding: const EdgeInsets.all(20),
            child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Text(widget.product.name, style: const TextStyle(fontSize: 22, fontWeight: FontWeight.bold)),
              const SizedBox(height: 10),
              _priceView(),
              const SizedBox(height: 12),
              Text(_emptyStock ? 'Stok habis' : 'Tersedia: $_stock'),
              if (_weight > 0) Text('Berat: $_weight gram'),
              const Divider(height: 32),
              if (_hasVariation) ...[
                _variationArea(),
                const Divider(height: 32),
              ],
              const Text('Deskripsi Produk', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
              const SizedBox(height: 8),
              Text(widget.product.description ?? 'Tidak ada deskripsi tersedia.'),
            ]),
          ),
        ],
      ),
      bottomNavigationBar: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Row(children: [
            IconButton(onPressed: _qty > 1 ? () => setState(() => _qty--) : null, icon: const Icon(Icons.remove)),
            Text('$_qty', style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
            IconButton(onPressed: _qty < _stock ? () => setState(() => _qty++) : null, icon: const Icon(Icons.add)),
            const SizedBox(width: 12),
            Expanded(
              child: ElevatedButton.icon(
                onPressed: (_saving || _emptyStock) ? null : _addCart,
                icon: _saving ? const SizedBox(width: 18, height: 18, child: CircularProgressIndicator(strokeWidth: 2)) : const Icon(Icons.shopping_cart),
                label: Text(_saving ? 'Menambahkan...' : 'Tambah ke Keranjang'),
              ),
            ),
          ]),
        ),
      ),
    );
  }
}

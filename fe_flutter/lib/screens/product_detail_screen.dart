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

  double get _price => _variation == null ? (widget.product.salePrice ?? widget.product.price) : (_variation!.salePrice ?? _variation!.regularPrice);
  int get _stock => _variation?.quantity ?? widget.product.quantity;
  int get _weight => _variation?.weight ?? widget.product.weight;
  bool get _hasVariation => widget.product.variations != null && widget.product.variations!.isNotEmpty;
  bool get _emptyStock => _stock <= 0 || widget.product.stockStatus != 'instock';

  void _chooseVariation(ProductVariation? value) {
    setState(() {
      _variation = value;
      _qty = 1;
    });
    if (value?.image == null) return;
    final index = _slides.indexWhere((item) => item.variation?.id == value!.id);
    if (index >= 0) {
      _pageController.animateToPage(index, duration: const Duration(milliseconds: 250), curve: Curves.easeOut);
    }
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
            child: PageView.builder(
              controller: _pageController,
              itemCount: items.length,
              onPageChanged: (index) {
                setState(() {
                  _page = index;
                  if (items[index].variation != null) {
                    _variation = items[index].variation;
                    _qty = 1;
                  }
                });
              },
              itemBuilder: (context, index) => Image.network(_url(items[index].image), fit: BoxFit.contain, errorBuilder: (_, __, ___) => const Icon(Icons.image_not_supported, size: 90, color: Colors.grey)),
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
              Text('Rp ${_price.toStringAsFixed(0)}', style: const TextStyle(fontSize: 24, fontWeight: FontWeight.w800, color: Color(0xFFE65100))),
              const SizedBox(height: 12),
              Text(_emptyStock ? 'Stok habis' : 'Tersedia: $_stock'),
              if (_weight > 0) Text('Berat: $_weight gram'),
              const Divider(height: 32),
              if (_hasVariation) ...[
                const Text('Pilih Variasi Produk:', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                const SizedBox(height: 12),
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: widget.product.variations!.map((item) => ChoiceChip(
                        label: Text(item.name),
                        selected: _variation?.id == item.id,
                        onSelected: (value) => _chooseVariation(value ? item : null),
                      )).toList(),
                ),
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

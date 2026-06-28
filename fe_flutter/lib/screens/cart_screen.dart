import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../services/api_service.dart';
import '../services/cart_badge_service.dart';
import 'checkout_screen.dart';

class CartScreen extends StatefulWidget {
  const CartScreen({Key? key}) : super(key: key);

  @override
  State<CartScreen> createState() => _CartScreenState();
}

class _CartScreenState extends State<CartScreen> {
  static const Color _primary = Color(0xFF0C2442);
  static const Color _accent = Color(0xFFF39C12);
  static const Color _purple = Color(0xFF6C4DFF);
  static const Color _surface = Color(0xFFF7F8FC);
  static const Color _muted = Color(0xFF64748B);

  List<Map<String, dynamic>> _cartItems = [];
  bool _isLoading = true;
  int _loadVersion = 0;

  @override
  void initState() {
    super.initState();
    CartBadgeService.revision.addListener(_handleCartChanged);
    _loadCart();
  }

  @override
  void dispose() {
    CartBadgeService.revision.removeListener(_handleCartChanged);
    super.dispose();
  }

  void _handleCartChanged() {
    if (mounted) _loadCart();
  }

  void _syncBadgeFromLocal() {
    int total = 0;
    for (final item in _cartItems) {
      total += int.tryParse((item['quantity'] ?? 1).toString()) ?? 1;
    }
    CartBadgeService.count.value = total;
  }

  Future<void> _loadCart() async {
    final loadVersion = ++_loadVersion;
    try {
      final cartData = await ApiService.getCart();
      final rawItems = (cartData['data'] as List? ?? []);
      if (!mounted || loadVersion != _loadVersion) return;

      setState(() {
        _cartItems = rawItems.map((item) {
          final mutableItem = Map<String, dynamic>.from(item);
          final product = Map<String, dynamic>.from(mutableItem['product'] ?? {});

          product['regular_price'] = mutableItem['price'] ?? product['regular_price'];
          product['image'] = mutableItem['selected_image'] ?? product['image'];
          product['weight'] = mutableItem['weight'] ?? product['weight'];
          product['selected_variation_name'] = mutableItem['variation_name'];

          mutableItem['product'] = product;
          mutableItem['isChecked'] = true;
          return mutableItem;
        }).toList();
        _isLoading = false;
      });
      _syncBadgeFromLocal();
    } catch (_) {
      if (!mounted || loadVersion != _loadVersion) return;
      setState(() => _isLoading = false);
      CartBadgeService.clear();
    }
  }

  String formatCurrency(double price) {
    return NumberFormat.currency(locale: 'id_ID', symbol: 'Rp ', decimalDigits: 0).format(price);
  }

  String _assetUrl(dynamic image, {String folder = 'products'}) {
    final value = image?.toString().trim() ?? '';
    if (value.isEmpty || value == 'null') return '';
    if (value.startsWith('http://') || value.startsWith('https://')) return value;

    final base = ApiService.baseUrl.replaceFirst(RegExp(r'/api/?$'), '');
    final cleanValue = value.startsWith('/') ? value.substring(1) : value;
    if (cleanValue.startsWith('uploads/') || cleanValue.startsWith('storage/')) return '$base/$cleanValue';
    return '$base/uploads/$folder/$cleanValue';
  }

  String _imageUrl(dynamic image) => _assetUrl(image, folder: 'products');

  String _storeLogoUrl(Map<String, dynamic> item) {
    final product = item['product'] is Map ? Map<String, dynamic>.from(item['product']) : <String, dynamic>{};
    final store = product['store'] is Map ? Map<String, dynamic>.from(product['store']) : <String, dynamic>{};
    return _assetUrl(store['logo'], folder: 'stores');
  }

  String _cleanText(dynamic value) {
    final text = value?.toString().trim() ?? '';
    if (text.isEmpty || text == 'null') return '';
    return text;
  }

  int get _selectedCount => _cartItems.where((item) => item['isChecked'] == true).length;
  bool get _noneSelected => _selectedCount == 0;

  double get totalPrice {
    double total = 0;
    for (var item in _cartItems) {
      if (item['isChecked'] == true) {
        final price = double.tryParse((item['price'] ?? item['product']?['regular_price'] ?? 0).toString()) ?? 0;
        final qty = int.tryParse(item['quantity'].toString()) ?? 1;
        total += price * qty;
      }
    }
    return total;
  }

  double get totalWeight {
    double weight = 0;
    for (var item in _cartItems) {
      if (item['isChecked'] == true) {
        final itemWeight = double.tryParse((item['weight'] ?? item['product']?['weight'] ?? '0').toString()) ?? 0;
        final qty = int.tryParse(item['quantity'].toString()) ?? 1;
        weight += itemWeight * qty;
      }
    }
    return weight > 0 ? weight : 1000;
  }

  Map<String, List<int>> get _groupedStoreIndexes {
    final grouped = <String, List<int>>{};
    for (int i = 0; i < _cartItems.length; i++) {
      final key = _storeKey(_cartItems[i]);
      grouped.putIfAbsent(key, () => []).add(i);
    }
    return grouped;
  }

  String _storeKey(Map<String, dynamic> item) {
    final product = item['product'] is Map ? Map<String, dynamic>.from(item['product']) : <String, dynamic>{};
    final store = product['store'] is Map ? Map<String, dynamic>.from(product['store']) : <String, dynamic>{};
    final storeId = _cleanText(product['store_key']).isNotEmpty
        ? product['store_key']
        : (store['id'] ?? store['slug'] ?? product['user_id'] ?? item['product_id'] ?? 'unknown-store');
    return storeId.toString();
  }

  String _storeName(Map<String, dynamic> item) {
    final product = item['product'] is Map ? Map<String, dynamic>.from(item['product']) : <String, dynamic>{};
    final store = product['store'] is Map ? Map<String, dynamic>.from(product['store']) : <String, dynamic>{};
    final user = product['user'] is Map ? Map<String, dynamic>.from(product['user']) : <String, dynamic>{};

    final candidates = [product['store_name'], store['name'], product['seller_name'], user['name']];

    for (final candidate in candidates) {
      final value = _cleanText(candidate);
      if (value.isNotEmpty) {
        if (candidate == user['name'] || candidate == product['seller_name']) return '$value Store';
        return value;
      }
    }

    return 'Toko Penjual';
  }

  bool _isStoreChecked(List<int> indexes) {
    if (indexes.isEmpty) return false;
    return indexes.every((index) => _cartItems[index]['isChecked'] == true);
  }

  bool _isStorePartialChecked(List<int> indexes) {
    if (indexes.isEmpty) return false;
    final selected = indexes.where((index) => _cartItems[index]['isChecked'] == true).length;
    return selected > 0 && selected < indexes.length;
  }

  void _toggleStore(List<int> indexes, bool? value) {
    setState(() {
      for (final index in indexes) {
        _cartItems[index]['isChecked'] = value ?? false;
      }
    });
  }

  Future<void> _removeItem(int index) async {
    final id = _cartItems[index]['id'];
    setState(() => _cartItems.removeAt(index));
    _syncBadgeFromLocal();
    if (id != null) {
      final ok = await ApiService.removeFromCart(int.parse(id.toString()));
      if (!ok) await _loadCart();
    }
  }

  Future<void> _removeStoreItems(List<int> indexes, String storeName) async {
    if (indexes.isEmpty) return;

    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Hapus produk toko?', style: TextStyle(fontWeight: FontWeight.bold)),
        content: Text('Semua produk dari $storeName akan dihapus dari keranjang.'),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context, false), child: const Text('Batal')),
          TextButton(onPressed: () => Navigator.pop(context, true), child: const Text('Hapus Semua', style: TextStyle(color: Colors.red, fontWeight: FontWeight.bold))),
        ],
      ),
    );

    if (confirm != true) return;

    final ids = indexes
        .where((index) => index >= 0 && index < _cartItems.length)
        .map((index) => _cartItems[index]['id'])
        .where((id) => id != null)
        .map((id) => int.tryParse(id.toString()))
        .whereType<int>()
        .toList();

    final sortedIndexes = indexes.toList()..sort((a, b) => b.compareTo(a));
    setState(() {
      for (final index in sortedIndexes) {
        if (index >= 0 && index < _cartItems.length) {
          _cartItems.removeAt(index);
        }
      }
    });
    _syncBadgeFromLocal();

    var allOk = true;
    for (final id in ids) {
      final ok = await ApiService.removeFromCart(id);
      if (!ok) allOk = false;
    }

    if (!mounted) return;
    if (!allOk) {
      await _loadCart();
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Sebagian produk gagal dihapus. Keranjang dimuat ulang.')));
    } else {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Semua produk dari $storeName berhasil dihapus.')));
    }
  }

  void _updateQuantity(int index, int change) {
    setState(() {
      final currentQty = int.tryParse(_cartItems[index]['quantity'].toString()) ?? 1;
      final newQuantity = currentQty + change;
      if (newQuantity > 0) _cartItems[index]['quantity'] = newQuantity;
    });
    _syncBadgeFromLocal();
  }

  void _toggleCheckbox(int index, bool? value) {
    setState(() => _cartItems[index]['isChecked'] = value ?? false);
  }

  void _checkout() {
    if (_noneSelected) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Pilih produk yang ingin di-checkout dulu.')));
      return;
    }

    final itemsToCheckout = _cartItems.where((item) => item['isChecked'] == true).toList();
    final sellerIds = itemsToCheckout.map((item) {
      final product = item['product'] is Map ? item['product'] as Map : const {};
      return int.tryParse((product['user_id'] ?? item['seller_id'] ?? '').toString()) ?? 0;
    }).where((id) => id > 0).toSet();
    if (sellerIds.length != 1) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Pilih produk dari satu toko untuk satu proses checkout agar ongkir akurat.')));
      return;
    }
    Navigator.push(
      context,
      MaterialPageRoute(builder: (context) => CheckoutScreen(totalAmount: totalPrice, totalWeight: totalWeight, cartItems: itemsToCheckout)),
    );
  }

  Widget _productImage(String image) {
    if (image.isEmpty) return const Icon(Icons.image_outlined, color: _muted, size: 34);
    return Image.network(image, fit: BoxFit.cover, errorBuilder: (_, __, ___) => const Icon(Icons.image_not_supported, color: _muted));
  }

  Widget _circleAction(IconData icon, VoidCallback? onTap) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(999),
      child: Container(
        width: 42,
        height: 42,
        decoration: BoxDecoration(color: Colors.white.withOpacity(0.14), shape: BoxShape.circle, border: Border.all(color: Colors.white.withOpacity(0.12))),
        child: Icon(icon, color: Colors.white, size: 21),
      ),
    );
  }

  Widget _header() {
    return Container(
      decoration: const BoxDecoration(
        gradient: LinearGradient(colors: [_primary, Color(0xFF123A68)], begin: Alignment.topLeft, end: Alignment.bottomRight),
        borderRadius: BorderRadius.vertical(bottom: Radius.circular(30)),
      ),
      child: SafeArea(
        bottom: false,
        child: Padding(
          padding: const EdgeInsets.fromLTRB(18, 16, 18, 24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Navigator.canPop(context) ? _circleAction(Icons.arrow_back_rounded, () => Navigator.pop(context)) : _circleAction(Icons.shopping_cart_rounded, null),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 7),
                    decoration: BoxDecoration(color: Colors.white.withOpacity(0.14), borderRadius: BorderRadius.circular(99), border: Border.all(color: Colors.white.withOpacity(0.12))),
                    child: Text('$_selectedCount dipilih', style: const TextStyle(color: Colors.white, fontSize: 12, fontWeight: FontWeight.w800)),
                  ),
                ],
              ),
              const SizedBox(height: 18),
              const Text('Keranjang Belanja', style: TextStyle(color: Colors.white, fontSize: 22, fontWeight: FontWeight.w900)),
              const SizedBox(height: 6),
              Text(
                _cartItems.isEmpty ? 'Pilih produk favoritmu dan lanjutkan checkout.' : '${_cartItems.length} produk tersedia di keranjangmu.',
                style: TextStyle(color: Colors.white.withOpacity(0.78), fontSize: 13, height: 1.35),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _emptyState() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(28),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 86,
              height: 86,
              decoration: BoxDecoration(color: _purple.withOpacity(0.10), shape: BoxShape.circle),
              child: const Icon(Icons.shopping_bag_outlined, color: _primary, size: 42),
            ),
            const SizedBox(height: 16),
            const Text('Keranjang masih kosong', style: TextStyle(fontSize: 18, color: _primary, fontWeight: FontWeight.w900)),
            const SizedBox(height: 6),
            const Text('Tambahkan produk dari toko pilihan Anda sebelum checkout.', textAlign: TextAlign.center, style: TextStyle(fontSize: 13, color: _muted, height: 1.4)),
          ],
        ),
      ),
    );
  }

  Widget _storeLogo(String logoUrl) {
    return Container(
      width: 42,
      height: 42,
      clipBehavior: Clip.antiAlias,
      decoration: BoxDecoration(
        color: _purple.withOpacity(0.08),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: const Color(0xFFE2E8F0)),
      ),
      child: logoUrl.isNotEmpty
          ? Image.network(logoUrl, fit: BoxFit.cover, errorBuilder: (_, __, ___) => const Icon(Icons.storefront_rounded, color: _primary, size: 22))
          : const Icon(Icons.storefront_rounded, color: _primary, size: 22),
    );
  }

  Widget _storeBar({
    required List<int> indexes,
    required bool checked,
    required bool partial,
    required String storeName,
    required int selectedInStore,
    required String logoUrl,
  }) {
    return Container(
      margin: const EdgeInsets.fromLTRB(0, 0, 0, 10),
      padding: const EdgeInsets.fromLTRB(8, 10, 8, 10),
      decoration: BoxDecoration(color: _surface, borderRadius: BorderRadius.circular(18), border: Border.all(color: const Color(0xFFE5E7EB))),
      child: Row(
        children: [
          Checkbox(value: partial ? null : checked, tristate: true, activeColor: _accent, onChanged: (value) => _toggleStore(indexes, value ?? false)),
          InkWell(onTap: () => _toggleStore(indexes, !checked), borderRadius: BorderRadius.circular(14), child: _storeLogo(logoUrl)),
          const SizedBox(width: 12),
          Expanded(
            child: InkWell(
              onTap: () => _toggleStore(indexes, !checked),
              borderRadius: BorderRadius.circular(12),
              child: Column(crossAxisAlignment: CrossAxisAlignment.start, mainAxisSize: MainAxisSize.min, children: [
                Text(storeName, style: const TextStyle(color: Color(0xFF111827), fontWeight: FontWeight.w900, fontSize: 15), maxLines: 1, overflow: TextOverflow.ellipsis),
                const SizedBox(height: 3),
                Text('$selectedInStore/${indexes.length} produk dipilih', style: const TextStyle(color: _muted, fontSize: 12)),
              ]),
            ),
          ),
          IconButton(tooltip: 'Hapus semua produk toko ini', onPressed: () => _removeStoreItems(List<int>.from(indexes), storeName), icon: const Icon(Icons.delete_outline_rounded, color: Colors.redAccent, size: 22)),
        ],
      ),
    );
  }

  Widget _storeGroupBlock(MapEntry<String, List<int>> entry) {
    final indexes = entry.value;
    if (indexes.isEmpty) return const SizedBox.shrink();

    final firstItem = _cartItems[indexes.first];
    final checked = _isStoreChecked(indexes);
    final partial = _isStorePartialChecked(indexes);
    final storeName = _storeName(firstItem);
    final selectedInStore = indexes.where((index) => _cartItems[index]['isChecked'] == true).length;
    final logoUrl = _storeLogoUrl(firstItem);

    return Container(
      margin: const EdgeInsets.only(bottom: 14),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(22),
        border: Border.all(color: const Color(0xFFE2E8F0)),
        boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.04), blurRadius: 14, offset: const Offset(0, 6))],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          _storeBar(indexes: indexes, checked: checked, partial: partial, storeName: storeName, selectedInStore: selectedInStore, logoUrl: logoUrl),
          Column(mainAxisSize: MainAxisSize.min, children: indexes.map((index) => _cartItemTile(index, isLast: index == indexes.last)).toList()),
        ],
      ),
    );
  }

  Widget _cartItemTile(int index, {required bool isLast}) {
    final item = _cartItems[index];
    final product = item['product'] ?? {};
    final image = _imageUrl(item['selected_image'] ?? product['image']);
    final price = double.tryParse((item['price'] ?? product['regular_price'] ?? 0).toString()) ?? 0;
    final qty = int.tryParse(item['quantity'].toString()) ?? 1;
    final variationName = item['variation_name']?.toString() ?? '';

    return Container(
      padding: const EdgeInsets.symmetric(vertical: 12),
      decoration: BoxDecoration(border: isLast ? null : const Border(bottom: BorderSide(color: Color(0xFFF1F5F9)))),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(padding: const EdgeInsets.only(top: 14), child: Checkbox(value: item['isChecked'] == true, activeColor: _accent, onChanged: (value) => _toggleCheckbox(index, value))),
          const SizedBox(width: 4),
          Container(
            width: 74,
            height: 74,
            decoration: BoxDecoration(color: _surface, borderRadius: BorderRadius.circular(16), border: Border.all(color: const Color(0xFFE2E8F0))),
            clipBehavior: Clip.antiAlias,
            child: _productImage(image),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(product['name'] ?? 'Produk Tanpa Nama', style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 14, color: Color(0xFF111827)), maxLines: 2, overflow: TextOverflow.ellipsis),
                if (variationName.isNotEmpty) ...[
                  const SizedBox(height: 6),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    decoration: BoxDecoration(color: _purple.withOpacity(0.08), borderRadius: BorderRadius.circular(10)),
                    child: Text('Variasi: $variationName', style: const TextStyle(color: _muted, fontSize: 11, fontWeight: FontWeight.w600)),
                  ),
                ],
                const SizedBox(height: 8),
                Text(formatCurrency(price), style: const TextStyle(fontWeight: FontWeight.w900, color: _primary, fontSize: 14)),
                const SizedBox(height: 4),
                Text('Subtotal: ${formatCurrency(price * qty)}', style: const TextStyle(color: _muted, fontSize: 12)),
              ],
            ),
          ),
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              IconButton(icon: const Icon(Icons.delete_outline, color: _muted, size: 21), onPressed: () => _removeItem(index), padding: EdgeInsets.zero, constraints: const BoxConstraints()),
              const SizedBox(height: 16),
              Row(
                children: [
                  InkWell(onTap: () => _updateQuantity(index, -1), borderRadius: BorderRadius.circular(8), child: _qtyButton(Icons.remove)),
                  Padding(padding: const EdgeInsets.symmetric(horizontal: 10), child: Text('$qty', style: const TextStyle(fontWeight: FontWeight.w800, color: _primary))),
                  InkWell(onTap: () => _updateQuantity(index, 1), borderRadius: BorderRadius.circular(8), child: _qtyButton(Icons.add)),
                ],
              ),
            ],
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final storeGroups = _groupedStoreIndexes.entries.toList();

    return Scaffold(
      backgroundColor: _surface,
      body: RefreshIndicator(
        onRefresh: _loadCart,
        child: CustomScrollView(
          physics: const AlwaysScrollableScrollPhysics(parent: BouncingScrollPhysics()),
          slivers: [
            SliverToBoxAdapter(child: _header()),
            if (_isLoading)
              const SliverFillRemaining(hasScrollBody: false, child: Center(child: CircularProgressIndicator(color: _primary)))
            else if (_cartItems.isEmpty)
              SliverFillRemaining(hasScrollBody: false, child: _emptyState())
            else
              SliverPadding(
                padding: const EdgeInsets.fromLTRB(16, 14, 16, 20),
                sliver: SliverList(delegate: SliverChildBuilderDelegate((context, index) => _storeGroupBlock(storeGroups[index]), childCount: storeGroups.length)),
              ),
          ],
        ),
      ),
      bottomNavigationBar: _isLoading
          ? const SizedBox.shrink()
          : Container(
              padding: const EdgeInsets.fromLTRB(16, 12, 16, 16),
              decoration: BoxDecoration(color: Colors.white, boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.08), blurRadius: 16, offset: const Offset(0, -5))]),
              child: SafeArea(
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Column(
                      mainAxisSize: MainAxisSize.min,
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text('Total ($_selectedCount produk)', style: const TextStyle(color: _muted, fontSize: 13)),
                        const SizedBox(height: 3),
                        Text(formatCurrency(totalPrice), style: const TextStyle(fontWeight: FontWeight.w900, fontSize: 19, color: _primary)),
                      ],
                    ),
                    ElevatedButton(
                      onPressed: _cartItems.isEmpty || _noneSelected ? null : _checkout,
                      style: ElevatedButton.styleFrom(backgroundColor: _primary, disabledBackgroundColor: const Color(0xFFCBD5E1), foregroundColor: Colors.white, elevation: 0, padding: const EdgeInsets.symmetric(horizontal: 28, vertical: 14), shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14))),
                      child: const Text('Checkout', style: TextStyle(fontSize: 15, fontWeight: FontWeight.w900)),
                    ),
                  ],
                ),
              ),
            ),
    );
  }

  Widget _qtyButton(IconData icon) {
    return Container(
      padding: const EdgeInsets.all(6),
      decoration: BoxDecoration(color: _surface, border: Border.all(color: const Color(0xFFE2E8F0)), borderRadius: BorderRadius.circular(8)),
      child: Icon(icon, size: 14, color: _primary),
    );
  }
}

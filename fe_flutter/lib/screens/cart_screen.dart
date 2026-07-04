import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../services/api_service.dart';
import '../services/cart_api_service.dart';
import '../services/cart_badge_service.dart';
import 'checkout_screen.dart';

class CartScreen extends StatefulWidget {
  const CartScreen({Key? key}) : super(key: key);

  @override
  State<CartScreen> createState() => _CartScreenState();
}

class _CartScreenState extends State<CartScreen> with WidgetsBindingObserver {
  static const Color _primary = Color(0xFF0C2442);
  static const Color _accent = Color(0xFFF39C12);
  static const Color _surface = Color(0xFFF7F8FC);
  static const Color _muted = Color(0xFF64748B);

  List<Map<String, dynamic>> _cartItems = [];
  final Set<int> _updatingQuantityIds = {};
  bool _isLoading = true;
  int _loadVersion = 0;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    CartBadgeService.revision.addListener(_handleCartChanged);
    _loadCart();
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    CartBadgeService.revision.removeListener(_handleCartChanged);
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) _loadCart();
  }

  void _handleCartChanged() {
    if (mounted && _updatingQuantityIds.isEmpty) _loadCart();
  }

  Future<void> _loadCart() async {
    final loadVersion = ++_loadVersion;
    try {
      final cartData = await ApiService.getCart();
      final rawItems = cartData['data'] as List? ?? [];
      if (!mounted || loadVersion != _loadVersion) return;

      setState(() {
        _cartItems = rawItems.map((item) {
          final mutableItem = Map<String, dynamic>.from(item as Map);
          final product = Map<String, dynamic>.from(mutableItem['product'] ?? {});

          product['regular_price'] = mutableItem['price'] ?? product['regular_price'];
          product['image'] = mutableItem['selected_image'] ?? product['image'];
          product['weight'] = mutableItem['weight'] ?? product['weight'];
          product['selected_variation_name'] = mutableItem['variation_name'];

          mutableItem['product'] = product;
          mutableItem['isChecked'] = mutableItem['isChecked'] ?? true;
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

  Future<void> _manualRefresh() async {
    if (mounted) setState(() => _isLoading = true);
    await _loadCart();
  }

  void _syncBadgeFromLocal() {
    int total = 0;
    for (final item in _cartItems) {
      total += int.tryParse((item['quantity'] ?? 1).toString()) ?? 1;
    }
    CartBadgeService.count.value = total;
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

  String _cleanText(dynamic value) {
    final text = value?.toString().trim() ?? '';
    if (text.isEmpty || text == 'null') return '';
    return text;
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
      if (value.isNotEmpty) return candidate == user['name'] || candidate == product['seller_name'] ? '$value Store' : value;
    }
    return 'Toko Penjual';
  }

  Map<String, List<int>> get _groupedStoreIndexes {
    final grouped = <String, List<int>>{};
    for (int i = 0; i < _cartItems.length; i++) {
      grouped.putIfAbsent(_storeKey(_cartItems[i]), () => []).add(i);
    }
    return grouped;
  }

  int get _selectedCount => _cartItems.where((item) => item['isChecked'] == true).length;
  bool get _noneSelected => _selectedCount == 0;

  double get totalPrice {
    double total = 0;
    for (final item in _cartItems) {
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
    for (final item in _cartItems) {
      if (item['isChecked'] == true) {
        final itemWeight = double.tryParse((item['weight'] ?? item['product']?['weight'] ?? '0').toString()) ?? 0;
        final qty = int.tryParse(item['quantity'].toString()) ?? 1;
        weight += itemWeight * qty;
      }
    }
    return weight > 0 ? weight : 1000;
  }

  void _toggleCheckbox(int index, bool? value) {
    setState(() => _cartItems[index]['isChecked'] = value ?? false);
  }

  void _toggleStore(List<int> indexes, bool value) {
    setState(() {
      for (final index in indexes) {
        if (index >= 0 && index < _cartItems.length) _cartItems[index]['isChecked'] = value;
      }
    });
  }

  bool _isStoreChecked(List<int> indexes) {
    return indexes.isNotEmpty && indexes.every((index) => _cartItems[index]['isChecked'] == true);
  }

  Future<void> _removeItem(int index) async {
    if (index < 0 || index >= _cartItems.length) return;
    final removed = Map<String, dynamic>.from(_cartItems[index]);
    final id = int.tryParse(removed['id']?.toString() ?? '');

    setState(() => _cartItems.removeAt(index));
    _syncBadgeFromLocal();

    if (id == null) return;
    final ok = await ApiService.removeFromCart(id);
    if (!mounted) return;
    if (!ok) {
      setState(() => _cartItems.insert(index.clamp(0, _cartItems.length), removed));
      _syncBadgeFromLocal();
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Gagal menghapus produk.')));
    }
  }

  Future<void> _updateQuantity(int index, int change) async {
    if (index < 0 || index >= _cartItems.length) return;

    final item = _cartItems[index];
    final id = int.tryParse(item['id']?.toString() ?? '');
    final currentQty = int.tryParse(item['quantity']?.toString() ?? '1') ?? 1;
    final newQuantity = currentQty + change;

    if (id == null || newQuantity < 1 || _updatingQuantityIds.contains(id)) return;

    setState(() {
      item['quantity'] = newQuantity;
      _updatingQuantityIds.add(id);
    });
    _syncBadgeFromLocal();

    final ok = await CartApiService.updateCartItemQuantity(
      cartItemId: id,
      quantity: newQuantity,
      refreshBadge: false,
    );

    if (!mounted) return;
    setState(() => _updatingQuantityIds.remove(id));

    if (!ok) {
      setState(() => item['quantity'] = currentQty);
      _syncBadgeFromLocal();
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(CartApiService.lastError ?? 'Gagal memperbarui jumlah produk.')),
      );
      await _loadCart();
    }
  }

  void _checkout() {
    if (_noneSelected) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Pilih produk yang ingin di-checkout dulu.')));
      return;
    }

    final itemsToCheckout = _cartItems.where((item) => item['isChecked'] == true).toList();
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => CheckoutScreen(
          totalAmount: totalPrice,
          totalWeight: totalWeight,
          cartItems: itemsToCheckout,
        ),
      ),
    );
  }

  Widget _productImage(String image) {
    if (image.isEmpty) return const Icon(Icons.image_outlined, color: _muted, size: 34);
    return Image.network(image, fit: BoxFit.cover, errorBuilder: (_, __, ___) => const Icon(Icons.image_not_supported, color: _muted));
  }

  Widget _header() {
    return Container(
      padding: const EdgeInsets.fromLTRB(18, 52, 18, 24),
      decoration: const BoxDecoration(
        gradient: LinearGradient(colors: [_primary, Color(0xFF123A68)]),
        borderRadius: BorderRadius.vertical(bottom: Radius.circular(28)),
      ),
      child: Row(
        children: [
          IconButton(onPressed: () => Navigator.maybePop(context), icon: const Icon(Icons.arrow_back, color: Colors.white)),
          const SizedBox(width: 8),
          const Expanded(child: Text('Keranjang', style: TextStyle(color: Colors.white, fontSize: 24, fontWeight: FontWeight.w900))),
          IconButton(onPressed: _manualRefresh, icon: const Icon(Icons.refresh, color: Colors.white)),
        ],
      ),
    );
  }

  Widget _emptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.shopping_cart_outlined, size: 82, color: Colors.grey.shade300),
          const SizedBox(height: 16),
          const Text('Keranjang masih kosong', style: TextStyle(fontSize: 18, fontWeight: FontWeight.w900)),
          const SizedBox(height: 6),
          Text('Tambahkan produk dari beranda.', style: TextStyle(color: Colors.grey.shade600)),
        ],
      ),
    );
  }

  Widget _qtyButton(IconData icon, {bool disabled = false}) {
    return Container(
      padding: const EdgeInsets.all(6),
      decoration: BoxDecoration(
        color: disabled ? Colors.grey.shade100 : Colors.white,
        border: Border.all(color: const Color(0xFFE2E8F0)),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Icon(icon, size: 14, color: disabled ? Colors.grey : _primary),
    );
  }

  Widget _cartItemTile(int index, {required bool isLast}) {
    final item = _cartItems[index];
    final product = item['product'] is Map ? Map<String, dynamic>.from(item['product']) : <String, dynamic>{};
    final image = _imageUrl(item['selected_image'] ?? product['image']);
    final price = double.tryParse((item['price'] ?? product['regular_price'] ?? 0).toString()) ?? 0;
    final qty = int.tryParse(item['quantity'].toString()) ?? 1;
    final id = int.tryParse(item['id']?.toString() ?? '');
    final isUpdating = id != null && _updatingQuantityIds.contains(id);
    final variationName = item['variation_name']?.toString() ?? '';

    return Container(
      padding: const EdgeInsets.symmetric(vertical: 12),
      decoration: BoxDecoration(border: isLast ? null : const Border(bottom: BorderSide(color: Color(0xFFF1F5F9)))),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.only(top: 14),
            child: Checkbox(value: item['isChecked'] == true, activeColor: _accent, onChanged: (value) => _toggleCheckbox(index, value)),
          ),
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
                  Text('Variasi: $variationName', style: const TextStyle(color: _muted, fontSize: 11, fontWeight: FontWeight.w600)),
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
              IconButton(icon: const Icon(Icons.delete_outline, color: _muted, size: 21), onPressed: isUpdating ? null : () => _removeItem(index), padding: EdgeInsets.zero, constraints: const BoxConstraints()),
              const SizedBox(height: 16),
              Row(
                children: [
                  InkWell(onTap: isUpdating || qty <= 1 ? null : () => _updateQuantity(index, -1), borderRadius: BorderRadius.circular(8), child: _qtyButton(Icons.remove, disabled: isUpdating || qty <= 1)),
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 10),
                    child: isUpdating
                        ? const SizedBox(width: 16, height: 16, child: CircularProgressIndicator(strokeWidth: 2))
                        : Text('$qty', style: const TextStyle(fontWeight: FontWeight.w800, color: _primary)),
                  ),
                  InkWell(onTap: isUpdating ? null : () => _updateQuantity(index, 1), borderRadius: BorderRadius.circular(8), child: _qtyButton(Icons.add, disabled: isUpdating)),
                ],
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _storeGroupBlock(MapEntry<String, List<int>> entry) {
    final indexes = entry.value;
    if (indexes.isEmpty) return const SizedBox.shrink();
    final storeName = _storeName(_cartItems[indexes.first]);
    final checked = _isStoreChecked(indexes);

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
          Row(
            children: [
              Checkbox(value: checked, activeColor: _accent, onChanged: (value) => _toggleStore(indexes, value ?? false)),
              Expanded(child: Text(storeName, style: const TextStyle(color: Color(0xFF111827), fontWeight: FontWeight.w900, fontSize: 15), maxLines: 1, overflow: TextOverflow.ellipsis)),
            ],
          ),
          Column(children: indexes.map((index) => _cartItemTile(index, isLast: index == indexes.last)).toList()),
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
                      style: ElevatedButton.styleFrom(
                        backgroundColor: _primary,
                        disabledBackgroundColor: const Color(0xFFCBD5E1),
                        foregroundColor: Colors.white,
                        elevation: 0,
                        padding: const EdgeInsets.symmetric(horizontal: 28, vertical: 14),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                      ),
                      child: const Text('Checkout', style: TextStyle(fontSize: 15, fontWeight: FontWeight.w900)),
                    ),
                  ],
                ),
              ),
            ),
    );
  }
}

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
  List<Map<String, dynamic>> _cartItems = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadCart();
  }

  void _syncBadgeFromLocal() {
    int total = 0;
    for (final item in _cartItems) {
      total += int.tryParse((item['quantity'] ?? 1).toString()) ?? 1;
    }
    CartBadgeService.count.value = total;
  }

  Future<void> _loadCart() async {
    try {
      final cartData = await ApiService.getCart();
      final rawItems = (cartData['data'] as List? ?? []);

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
        title: const Text('Hapus produk toko?'),
        content: Text('Semua produk dari $storeName akan dihapus dari keranjang.'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context, false), child: const Text('Batal')),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red, foregroundColor: Colors.white),
            child: const Text('Hapus Semua'),
          ),
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
    Navigator.push(
      context,
      MaterialPageRoute(builder: (context) => CheckoutScreen(totalAmount: totalPrice, totalWeight: totalWeight, cartItems: itemsToCheckout)),
    );
  }

  Widget _productImage(String image) {
    if (image.isEmpty) return const Icon(Icons.image, color: Colors.grey, size: 40);
    return Image.network(image, fit: BoxFit.cover, errorBuilder: (_, __, ___) => const Icon(Icons.image_not_supported, color: Colors.grey));
  }

  Widget _storeLogo(String logoUrl) {
    return Container(
      width: 42,
      height: 42,
      clipBehavior: Clip.antiAlias,
      decoration: BoxDecoration(
        color: const Color(0xFFF1F5F9),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: const Color(0xFFE2E8F0)),
      ),
      child: logoUrl.isNotEmpty
          ? Image.network(logoUrl, fit: BoxFit.cover, errorBuilder: (_, __, ___) => const Icon(Icons.storefront_rounded, color: Color(0xFF64748B), size: 22))
          : const Icon(Icons.storefront_rounded, color: Color(0xFF64748B), size: 22),
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
    return Padding(
      padding: const EdgeInsets.fromLTRB(14, 12, 14, 0),
      child: Material(
        color: const Color(0xFFF8FAFC),
        borderRadius: BorderRadius.circular(14),
        elevation: 0,
        child: Container(
          width: double.infinity,
          padding: const EdgeInsets.fromLTRB(8, 10, 8, 10),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(14),
            border: Border.all(color: const Color(0xFFE5E7EB)),
          ),
          child: Row(
            children: [
              Checkbox(
                value: partial ? null : checked,
                tristate: true,
                activeColor: Colors.blue[700],
                onChanged: (value) => _toggleStore(indexes, value ?? false),
              ),
              InkWell(
                onTap: () => _toggleStore(indexes, !checked),
                borderRadius: BorderRadius.circular(12),
                child: _storeLogo(logoUrl),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: InkWell(
                  onTap: () => _toggleStore(indexes, !checked),
                  borderRadius: BorderRadius.circular(10),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        storeName,
                        style: const TextStyle(color: Color(0xFF111827), fontWeight: FontWeight.w800, fontSize: 15),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                      const SizedBox(height: 3),
                      Text('$selectedInStore/${indexes.length} produk dipilih', style: const TextStyle(color: Color(0xFF64748B), fontSize: 12)),
                    ],
                  ),
                ),
              ),
              IconButton(
                tooltip: 'Hapus semua produk toko ini',
                onPressed: () => _removeStoreItems(List<int>.from(indexes), storeName),
                icon: const Icon(Icons.delete_outline_rounded, color: Colors.redAccent, size: 22),
              ),
            ],
          ),
        ),
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

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        _storeBar(indexes: indexes, checked: checked, partial: partial, storeName: storeName, selectedInStore: selectedInStore, logoUrl: logoUrl),
        Container(
          margin: const EdgeInsets.fromLTRB(14, 8, 14, 10),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(14),
            border: Border.all(color: Colors.grey.shade200),
            boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.035), blurRadius: 10, offset: const Offset(0, 4))],
          ),
          child: Column(mainAxisSize: MainAxisSize.min, children: indexes.map((index) => _cartItemTile(index, isLast: index == indexes.last)).toList()),
        ),
      ],
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
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(border: isLast ? null : Border(bottom: BorderSide(color: Colors.grey.shade100))),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(padding: const EdgeInsets.only(top: 16), child: Checkbox(value: item['isChecked'], activeColor: Colors.blue[700], onChanged: (value) => _toggleCheckbox(index, value))),
          const SizedBox(width: 6),
          Container(
            width: 72,
            height: 72,
            decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(10), border: Border.all(color: Colors.grey.shade200)),
            clipBehavior: Clip.antiAlias,
            child: _productImage(image),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(product['name'] ?? 'Produk Tanpa Nama', style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 14), maxLines: 2, overflow: TextOverflow.ellipsis),
                if (variationName.isNotEmpty) ...[
                  const SizedBox(height: 4),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    decoration: BoxDecoration(color: Colors.grey.shade100, borderRadius: BorderRadius.circular(8)),
                    child: Text('Variasi: $variationName', style: TextStyle(color: Colors.grey[700], fontSize: 11, fontWeight: FontWeight.w500)),
                  ),
                ],
                const SizedBox(height: 8),
                Text(formatCurrency(price), style: TextStyle(fontWeight: FontWeight.bold, color: Colors.blue[700], fontSize: 14)),
                const SizedBox(height: 4),
                Text('Subtotal: ${formatCurrency(price * qty)}', style: TextStyle(color: Colors.grey[700], fontSize: 12)),
              ],
            ),
          ),
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              IconButton(icon: Icon(Icons.delete_outline, color: Colors.grey[500], size: 21), onPressed: () => _removeItem(index), padding: EdgeInsets.zero, constraints: const BoxConstraints()),
              const SizedBox(height: 16),
              Row(
                children: [
                  InkWell(onTap: () => _updateQuantity(index, -1), child: _qtyButton(Icons.remove)),
                  Padding(padding: const EdgeInsets.symmetric(horizontal: 10), child: Text('$qty', style: const TextStyle(fontWeight: FontWeight.w600))),
                  InkWell(onTap: () => _updateQuantity(index, 1), child: _qtyButton(Icons.add)),
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
      backgroundColor: Colors.grey[50],
      appBar: AppBar(
        title: const Text('Keranjang Belanja', style: TextStyle(color: Colors.black, fontWeight: FontWeight.bold)),
        backgroundColor: Colors.white,
        elevation: 0.5,
        iconTheme: const IconThemeData(color: Colors.black),
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _cartItems.isEmpty
              ? const Center(child: Text('Keranjang belanja Anda kosong.', style: TextStyle(fontSize: 16, color: Colors.grey)))
              : ListView.builder(
                  padding: const EdgeInsets.only(top: 4, bottom: 8),
                  itemCount: storeGroups.length,
                  itemBuilder: (context, index) => _storeGroupBlock(storeGroups[index]),
                ),
      bottomNavigationBar: _isLoading
          ? const SizedBox.shrink()
          : Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(color: Colors.white, boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 10, offset: const Offset(0, -5))]),
              child: SafeArea(
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Column(
                      mainAxisSize: MainAxisSize.min,
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text('Total ($_selectedCount produk)', style: TextStyle(color: Colors.grey[600], fontSize: 13)),
                        const SizedBox(height: 2),
                        Text(formatCurrency(totalPrice), style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18, color: Colors.blue[700])),
                      ],
                    ),
                    ElevatedButton(
                      onPressed: _cartItems.isEmpty || _noneSelected ? null : _checkout,
                      style: ElevatedButton.styleFrom(padding: const EdgeInsets.symmetric(horizontal: 28, vertical: 14), backgroundColor: Colors.blue[700], elevation: 0, shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8))),
                      child: const Text('Checkout', style: TextStyle(fontSize: 15, fontWeight: FontWeight.bold, color: Colors.white)),
                    ),
                  ],
                ),
              ),
            ),
    );
  }

  Widget _qtyButton(IconData icon) {
    return Container(
      padding: const EdgeInsets.all(4),
      decoration: BoxDecoration(border: Border.all(color: Colors.grey.shade300), borderRadius: BorderRadius.circular(4)),
      child: Icon(icon, size: 14),
    );
  }
}

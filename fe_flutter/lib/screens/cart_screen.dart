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
          mutableItem['isChecked'] = false;
          return mutableItem;
        }).toList();
        _isLoading = false;
      });
      _syncBadgeFromLocal();
    } catch (e) {
      setState(() => _isLoading = false);
      CartBadgeService.clear();
    }
  }

  String formatCurrency(double price) {
    return NumberFormat.currency(locale: 'id_ID', symbol: 'Rp ', decimalDigits: 0).format(price);
  }

  String _imageUrl(dynamic image) {
    final value = image?.toString().trim() ?? '';
    if (value.isEmpty || value == 'null') return '';
    if (value.startsWith('http://') || value.startsWith('https://')) return value;

    final base = ApiService.baseUrl.replaceFirst(RegExp(r'/api/?$'), '');
    final cleanValue = value.startsWith('/') ? value.substring(1) : value;
    if (cleanValue.startsWith('uploads/') || cleanValue.startsWith('storage/')) return '$base/$cleanValue';
    return '$base/uploads/products/$cleanValue';
  }

  bool get _noneSelected => !_cartItems.any((item) => item['isChecked'] == true);

  double get totalPrice {
    double total = 0;
    for (var item in _cartItems) {
      if (_noneSelected || item['isChecked'] == true) {
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
      if (_noneSelected || item['isChecked'] == true) {
        final itemWeight = double.tryParse((item['weight'] ?? item['product']?['weight'] ?? '0').toString()) ?? 0;
        final qty = int.tryParse(item['quantity'].toString()) ?? 1;
        weight += itemWeight * qty;
      }
    }
    return weight > 0 ? weight : 1000;
  }

  Future<void> _removeItem(int index) async {
    final id = _cartItems[index]['id'];
    setState(() => _cartItems.removeAt(index));
    _syncBadgeFromLocal();
    if (id != null) {
      final ok = await ApiService.removeFromCart(int.parse(id.toString()));
      if (!ok) {
        await _loadCart();
      }
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
    final itemsToCheckout = _cartItems.where((item) => _noneSelected || item['isChecked'] == true).toList();
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
    if (image.isEmpty) return const Icon(Icons.image, color: Colors.grey, size: 40);
    return Image.network(
      image,
      fit: BoxFit.cover,
      errorBuilder: (_, __, ___) => const Icon(Icons.image_not_supported, color: Colors.grey),
    );
  }

  @override
  Widget build(BuildContext context) {
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
                  padding: const EdgeInsets.symmetric(vertical: 8),
                  itemCount: _cartItems.length,
                  itemBuilder: (context, index) {
                    final item = _cartItems[index];
                    final product = item['product'] ?? {};
                    final image = _imageUrl(item['selected_image'] ?? product['image']);
                    final price = double.tryParse((item['price'] ?? product['regular_price'] ?? 0).toString()) ?? 0;
                    final qty = int.tryParse(item['quantity'].toString()) ?? 1;
                    final variationName = item['variation_name']?.toString() ?? '';

                    return Card(
                      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
                      elevation: 1,
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                      child: Padding(
                        padding: const EdgeInsets.all(12),
                        child: Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Padding(
                              padding: const EdgeInsets.only(top: 16),
                              child: Checkbox(value: item['isChecked'], activeColor: Colors.blue, onChanged: (value) => _toggleCheckbox(index, value)),
                            ),
                            const SizedBox(width: 8),
                            Container(
                              width: 70,
                              height: 70,
                              decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(8), border: Border.all(color: Colors.grey.shade200)),
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
                                    Text('Variasi: $variationName', style: TextStyle(color: Colors.grey[700], fontSize: 12, fontWeight: FontWeight.w500)),
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
                                IconButton(icon: Icon(Icons.delete, color: Colors.grey[400], size: 20), onPressed: () => _removeItem(index), padding: EdgeInsets.zero, constraints: const BoxConstraints()),
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
                      ),
                    );
                  },
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
                        Text('Total (${_noneSelected ? _cartItems.length : _cartItems.where((i) => i['isChecked'] == true).length} produk)', style: TextStyle(color: Colors.grey[600], fontSize: 13)),
                        const SizedBox(height: 2),
                        Text(formatCurrency(totalPrice), style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18, color: Colors.blue[700])),
                      ],
                    ),
                    ElevatedButton(
                      onPressed: _cartItems.isEmpty ? null : _checkout,
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

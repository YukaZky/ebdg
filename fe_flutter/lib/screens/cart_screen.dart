import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../services/api_service.dart';
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

  // Load data dari API
  Future<void> _loadCart() async {
    try {
      final cartData = await ApiService.getCart();
      setState(() {
        // Kita ubah list dari API menjadi list yang bisa dimodifikasi (mutable)
        // dan tambahkan properti 'isChecked' dengan nilai default false
        _cartItems = (cartData['data'] as List).map((item) {
          var mutableItem = Map<String, dynamic>.from(item);
          mutableItem['isChecked'] = false;
          return mutableItem;
        }).toList();
        
        _isLoading = false;
      });
    } catch (e) {
      setState(() => _isLoading = false);
    }
  }

  // Helper untuk format mata uang Rupiah
  String formatCurrency(double price) {
    return NumberFormat.currency(locale: 'id_ID', symbol: 'Rp ', decimalDigits: 0).format(price);
  }

  // Cek apakah tidak ada item sama sekali yang dicentang
  bool get _noneSelected => !_cartItems.any((item) => item['isChecked'] == true);

  // Hitung total harga sesuai item yang dicentang
  // Jika tidak ada yang dicentang, maka hitung total SEMUA item
  double get totalPrice {
    double total = 0;
    
    for (var item in _cartItems) {
      if (_noneSelected || item['isChecked'] == true) {
        final product = item['product'];
        double price = double.tryParse(product['regular_price'].toString()) ?? 0;
        int qty = int.tryParse(item['quantity'].toString()) ?? 1;
        total += price * qty;
      }
    }
    return total;
  }

  // Fungsi bersihkan seluruh keranjang (Lokal UI)
  void _clearCart() {
    // TODO: Tambahkan fungsi pemanggilan API untuk hapus semua keranjang di sini jika ada
    // await ApiService.clearCart();
    
    setState(() {
      _cartItems.clear();
    });
  }

  // Fungsi hapus satu item spesifik (Lokal UI)
  void _removeItem(int index) {
    // TODO: Tambahkan fungsi pemanggilan API untuk hapus item spesifik berdasarkan ID
    // await ApiService.removeCartItem(item['id']);

    setState(() {
      _cartItems.removeAt(index);
    });
  }

  // Fungsi ubah jumlah produk + atau - (Lokal UI)
  void _updateQuantity(int index, int change) {
    // TODO: Tambahkan pemanggilan API untuk update quantity
    // await ApiService.updateCartQuantity(item['id'], newQuantity);

    setState(() {
      int currentQty = int.tryParse(_cartItems[index]['quantity'].toString()) ?? 1;
      int newQuantity = currentQty + change;
      if (newQuantity > 0) {
        _cartItems[index]['quantity'] = newQuantity;
      }
    });
  }

  // Fungsi toggle checkbox
  void _toggleCheckbox(int index, bool? value) {
    setState(() {
      _cartItems[index]['isChecked'] = value ?? false;
    });
  }

  // Aksi tombol checkout
  void _checkout() {
    // Navigasi ke CheckoutScreen dengan membawa total yang dihitung
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => CheckoutScreen(totalAmount: totalPrice),
      ),
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
        actions: [
          // Tombol Bersihkan Keranjang
          IconButton(
            icon: const Icon(Icons.delete_outline, color: Colors.red),
            onPressed: () {
              if (_cartItems.isEmpty) return;
              showDialog(
                context: context,
                builder: (context) => AlertDialog(
                  title: const Text('Bersihkan Keranjang?'),
                  content: const Text('Apakah Anda yakin ingin menghapus semua item di keranjang?'),
                  actions: [
                    TextButton(
                      onPressed: () => Navigator.pop(context),
                      child: const Text('Batal'),
                    ),
                    TextButton(
                      onPressed: () {
                        _clearCart();
                        Navigator.pop(context);
                      },
                      child: const Text('Hapus Semua', style: TextStyle(color: Colors.red)),
                    ),
                  ],
                ),
              );
            },
            tooltip: 'Bersihkan Keranjang',
          ),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _cartItems.isEmpty
              ? const Center(
                  child: Text(
                    'Keranjang belanja Anda kosong.',
                    style: TextStyle(fontSize: 16, color: Colors.grey),
                  ),
                )
              : ListView.builder(
                  padding: const EdgeInsets.symmetric(vertical: 8),
                  itemCount: _cartItems.length,
                  itemBuilder: (context, index) {
                    final item = _cartItems[index];
                    final product = item['product'];
                    
                    return Card(
                      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
                      elevation: 1,
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                      child: Padding(
                        padding: const EdgeInsets.all(12.0),
                        child: Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            // Kotak Centang (Checkbox)
                            Padding(
                              padding: const EdgeInsets.only(top: 16.0),
                              child: SizedBox(
                                width: 24,
                                child: Checkbox(
                                  value: item['isChecked'],
                                  activeColor: Colors.blue,
                                  onChanged: (value) => _toggleCheckbox(index, value),
                                ),
                              ),
                            ),
                            const SizedBox(width: 8),
                            
                            // Gambar Produk Dinamis
                            Container(
                              width: 70,
                              height: 70,
                              decoration: BoxDecoration(
                                color: Colors.white,
                                borderRadius: BorderRadius.circular(8),
                                border: Border.all(color: Colors.grey.shade200),
                              ),
                              child: ClipRRect(
                                borderRadius: BorderRadius.circular(8),
                                child: product['image'] != null
                                    ? Image.network(
                                        "http://127.0.0.1:8000/uploads/products/${product['image']}",
                                        fit: BoxFit.cover,
                                        errorBuilder: (context, error, stackTrace) => const Icon(Icons.image_not_supported, color: Colors.grey),
                                      )
                                    : const Icon(Icons.image, color: Colors.grey, size: 40),
                              ),
                            ),
                            const SizedBox(width: 12),
                            
                            // Detail Produk
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    product['name'] ?? 'Produk Tanpa Nama',
                                    style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 14),
                                    maxLines: 2,
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                  const SizedBox(height: 8),
                                  Text(
                                    formatCurrency(double.tryParse(product['regular_price'].toString()) ?? 0),
                                    style: TextStyle(fontWeight: FontWeight.bold, color: Colors.blue[700], fontSize: 14),
                                  ),
                                ],
                              ),
                            ),
                            
                            // Aksi (Hapus dan Jumlah Item)
                            Column(
                              crossAxisAlignment: CrossAxisAlignment.end,
                              children: [
                                IconButton(
                                  icon: Icon(Icons.delete, color: Colors.grey[400], size: 20),
                                  onPressed: () => _removeItem(index),
                                  constraints: const BoxConstraints(),
                                  padding: EdgeInsets.zero,
                                ),
                                const SizedBox(height: 16),
                                Row(
                                  children: [
                                    InkWell(
                                      onTap: () => _updateQuantity(index, -1),
                                      child: Container(
                                        padding: const EdgeInsets.all(4),
                                        decoration: BoxDecoration(
                                          border: Border.all(color: Colors.grey.shade300),
                                          borderRadius: BorderRadius.circular(4),
                                        ),
                                        child: const Icon(Icons.remove, size: 14, color: Colors.black87),
                                      ),
                                    ),
                                    Padding(
                                      padding: const EdgeInsets.symmetric(horizontal: 10),
                                      child: Text(
                                        '${item['quantity']}',
                                        style: const TextStyle(fontWeight: FontWeight.w600),
                                      ),
                                    ),
                                    InkWell(
                                      onTap: () => _updateQuantity(index, 1),
                                      child: Container(
                                        padding: const EdgeInsets.all(4),
                                        decoration: BoxDecoration(
                                          border: Border.all(color: Colors.grey.shade300),
                                          borderRadius: BorderRadius.circular(4),
                                        ),
                                        child: const Icon(Icons.add, size: 14, color: Colors.black87),
                                      ),
                                    ),
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
      
      // Bagian Bawah (Total & Tombol Checkout)
      bottomNavigationBar: _isLoading ? const SizedBox.shrink() : Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.white,
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.05),
              spreadRadius: 1,
              blurRadius: 10,
              offset: const Offset(0, -5),
            ),
          ],
        ),
        child: SafeArea(
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Total (${_noneSelected ? _cartItems.length : _cartItems.where((i) => i['isChecked'] == true).length} produk)',
                    style: TextStyle(color: Colors.grey[600], fontSize: 13),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    formatCurrency(totalPrice),
                    style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18, color: Colors.blue[700]),
                  ),
                ],
              ),
              ElevatedButton(
                onPressed: _cartItems.isEmpty ? null : _checkout,
                style: ElevatedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(horizontal: 28, vertical: 14),
                  backgroundColor: Colors.blue[700],
                  elevation: 0,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                ),
                child: const Text(
                  'Checkout',
                  style: TextStyle(fontSize: 15, fontWeight: FontWeight.bold, color: Colors.white),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
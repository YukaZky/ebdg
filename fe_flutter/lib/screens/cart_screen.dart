import 'package:flutter/material.dart';
import '../services/api_service.dart';
import 'checkout_screen.dart';

class CartScreen extends StatefulWidget {
  const CartScreen({Key? key}) : super(key: key);

  @override
  State<CartScreen> createState() => _CartScreenState();
}

class _CartScreenState extends State<CartScreen> {
  List _cartItems = [];
  double _total = 0;
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadCart();
  }

  Future<void> _loadCart() async {
    try {
      final cartData = await ApiService.getCart();
      setState(() {
        _cartItems = cartData['data'];
        _total = double.parse(cartData['total'].toString());
        _isLoading = false;
      });
    } catch (e) {
      setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("Keranjang Belanja")),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _cartItems.isEmpty
              ? const Center(child: Text("Keranjang Anda Kosong"))
              : Column(
                  children: [
                    Expanded(
                      child: ListView.builder(
                        itemCount: _cartItems.length,
                        itemBuilder: (context, index) {
                          final item = _cartItems[index];
                          final product = item['product'];
                          return ListTile(
                            leading: product['image'] != null
                                ? Image.network(
                                    "http://127.0.0.1:8000/uploads/products/${product['image']}",
                                    width: 50,
                                    height: 50,
                                    fit: BoxFit.cover)
                                : const Icon(Icons.image, size: 50),
                            title: Text(product['name']),
                            subtitle: Text(
                                "Rp ${product['regular_price']} x ${item['quantity']}"),
                            trailing: Text(
                                "Rp ${double.parse(product['regular_price'].toString()) * item['quantity']}",
                                style: const TextStyle(
                                    fontWeight: FontWeight.bold)),
                          );
                        },
                      ),
                    ),
                    Container(
                      padding: const EdgeInsets.all(16),
                      color: Colors.white,
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const Text("Total Tagihan:",
                                  style: TextStyle(color: Colors.grey)),
                              Text("Rp ${_total.toStringAsFixed(0)}",
                                  style: const TextStyle(
                                      fontSize: 20,
                                      fontWeight: FontWeight.bold,
                                      color: Colors.green)),
                            ],
                          ),
                          ElevatedButton(
                            onPressed: () {
                              Navigator.push(
                                context,
                                MaterialPageRoute(
                                  builder: (context) =>
                                      CheckoutScreen(totalAmount: _total),
                                ),
                              );
                            },
                            child: const Text("CHECKOUT"),
                          )
                        ],
                      ),
                    )
                  ],
                ),
    );
  }
}

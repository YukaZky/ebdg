import 'package:flutter/material.dart';
import '../models/product_model.dart';
import '../services/api_service.dart';

class ProductDetailScreen extends StatefulWidget {
  final Product product;
  const ProductDetailScreen({Key? key, required this.product})
      : super(key: key);

  @override
  State<ProductDetailScreen> createState() => _ProductDetailScreenState();
}

class _ProductDetailScreenState extends State<ProductDetailScreen> {
  int _quantity = 1;
  bool _isAdding = false;

  void _addToCart() async {
    setState(() => _isAdding = true);
    bool success = await ApiService.addToCart(widget.product.id, _quantity);
    setState(() => _isAdding = false);

    if (success) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text("Berhasil dimasukkan ke keranjang"),
          backgroundColor: Colors.green,
          behavior: SnackBarBehavior.floating, // Tampilan modern
        ),
      );
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text("Gagal menambah keranjang"),
          backgroundColor: Colors.red,
          behavior: SnackBarBehavior.floating,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        title: const Text("Detail Produk"),
        elevation: 0,
      ),
      body: SafeArea(
        child: Column(
          children: [
            Expanded(
              child: SingleChildScrollView(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Gambar Header Besar
                    Container(
                      width: double.infinity,
                      height: 350,
                      color: Colors.grey.shade50,
                      child: widget.product.image != null
                          ? Image.network(
                              "http://127.0.0.1:8000/uploads/products/${widget.product.image}",
                              fit: BoxFit.contain,
                              cacheWidth:
                                  600, // Resolusi lebih besar sedikit untuk halaman detail
                              loadingBuilder:
                                  (context, child, loadingProgress) {
                                if (loadingProgress == null) return child;
                                return Center(
                                    child: CircularProgressIndicator(
                                        color: Colors.blue.shade200));
                              },
                              errorBuilder: (c, e, s) => const Icon(
                                  Icons.broken_image,
                                  size: 100,
                                  color: Colors.grey),
                            )
                          : const Icon(Icons.image,
                              size: 100, color: Colors.grey),
                    ),

                    // Detail Teks Area
                    Container(
                      transform: Matrix4.translationValues(0.0, -20.0, 0.0),
                      decoration: const BoxDecoration(
                        color: Colors.white,
                        borderRadius:
                            BorderRadius.vertical(top: Radius.circular(24)),
                      ),
                      padding: const EdgeInsets.all(20.0),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            widget.product.name,
                            style: const TextStyle(
                                fontSize: 24,
                                fontWeight: FontWeight.bold,
                                height: 1.2),
                          ),
                          const SizedBox(height: 12),
                          Text(
                            "Rp ${widget.product.price.toStringAsFixed(0)}",
                            style: const TextStyle(
                                fontSize: 22,
                                color: Color(0xFFE65100),
                                fontWeight: FontWeight.w900),
                          ),
                          const SizedBox(height: 24),
                          const Text(
                            "Deskripsi Produk",
                            style: TextStyle(
                                fontSize: 18, fontWeight: FontWeight.bold),
                          ),
                          const SizedBox(height: 12),
                          Text(
                            widget.product.shortDescription ??
                                "Tidak ada deskripsi tersedia untuk produk ini.",
                            style: const TextStyle(
                                fontSize: 15,
                                color: Colors.black87,
                                height: 1.5),
                          ),
                        ],
                      ),
                    )
                  ],
                ),
              ),
            ),

            // Sticky Bottom Bar
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
              decoration: BoxDecoration(
                color: Colors.white,
                boxShadow: [
                  BoxShadow(
                      color: Colors.grey.withOpacity(0.15),
                      blurRadius: 20,
                      offset: const Offset(0, -5))
                ],
              ),
              child: Row(
                children: [
                  // Box Kuantitas
                  Container(
                    decoration: BoxDecoration(
                      border: Border.all(color: Colors.grey.shade300),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Row(
                      children: [
                        IconButton(
                          icon: const Icon(Icons.remove, color: Colors.black87),
                          onPressed: () {
                            if (_quantity > 1) setState(() => _quantity--);
                          },
                        ),
                        Text("$_quantity",
                            style: const TextStyle(
                                fontSize: 18, fontWeight: FontWeight.bold)),
                        IconButton(
                          icon: const Icon(Icons.add, color: Colors.black87),
                          onPressed: () {
                            if (_quantity < widget.product.quantity)
                              setState(() => _quantity++);
                          },
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: 16),

                  // Tombol Keranjang
                  Expanded(
                    child: ElevatedButton(
                      onPressed: _isAdding ? null : _addToCart,
                      style: ElevatedButton.styleFrom(
                        backgroundColor:
                            const Color(0xFFE65100), // Warna oranye e-commerce
                        elevation: 0,
                      ),
                      child: _isAdding
                          ? const SizedBox(
                              height: 20,
                              width: 20,
                              child: CircularProgressIndicator(
                                  color: Colors.white, strokeWidth: 2))
                          : const Text("+ KERANJANG"),
                    ),
                  )
                ],
              ),
            )
          ],
        ),
      ),
    );
  }
}

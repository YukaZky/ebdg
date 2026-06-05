import 'package:flutter/material.dart';
import '../models/product_model.dart';
import '../services/api_service.dart';

class ProductDetailScreen extends StatefulWidget {
  final Product product;

  const ProductDetailScreen({Key? key, required this.product}) : super(key: key);

  @override
  State<ProductDetailScreen> createState() => _ProductDetailScreenState();
}

class _ProductDetailScreenState extends State<ProductDetailScreen> {
  int quantity = 1;
  bool isAddingToCart = false;
  
  // --- State untuk Wishlist ---
  bool isWishlisted = false;
  bool isWishlistLoading = false;

  @override
  void initState() {
    super.initState();
    _checkWishlistStatus();
  }

  // Fungsi untuk mengecek apakah produk ini sudah ada di wishlist user
  Future<void> _checkWishlistStatus() async {
    if (ApiService.token == null) return;
    
    try {
      final wishlist = await ApiService.getWishlist();
      if (mounted) {
        setState(() {
          // Mengecek jika ID produk yang sedang dilihat ada di dalam list id wishlist
          isWishlisted = wishlist.any((item) => item.id == widget.product.id);
        });
      }
    } catch (e) {
      print("Gagal memuat status wishlist: $e");
    }
  }

  // Fungsi untuk menambah / menghapus dari wishlist saat icon love diklik
  Future<void> _toggleWishlist() async {
    if (ApiService.token == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Silakan login di menu Akun untuk menggunakan Wishlist")),
      );
      return;
    }

    setState(() => isWishlistLoading = true);
    
    bool success;
    if (isWishlisted) {
      // Jika sudah ada di wishlist, maka hapus
      success = await ApiService.removeFromWishlist(widget.product.id);
      if (success) {
        setState(() => isWishlisted = false);
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text("Berhasil dihapus dari Wishlist")),
        );
      }
    } else {
      // Jika belum ada di wishlist, maka tambahkan
      success = await ApiService.addToWishlist(widget.product.id);
      if (success) {
        setState(() => isWishlisted = true);
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text("Berhasil ditambahkan ke Wishlist")),
        );
      }
    }
    
    setState(() => isWishlistLoading = false);
  }

  // Fungsi untuk memasukkan ke keranjang (Add to Cart)
  Future<void> _addToCart() async {
    if (ApiService.token == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Silakan login di menu Akun terlebih dahulu")),
      );
      return;
    }

    if (widget.product.stockStatus != 'instock') {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Maaf, stok produk sedang kosong")),
      );
      return;
    }

    setState(() => isAddingToCart = true);

    bool success = await ApiService.addToCart(widget.product.id, quantity);

    setState(() => isAddingToCart = false);

    if (success) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Produk berhasil ditambahkan ke keranjang!")),
      );
      Navigator.pop(context); // Kembali ke list setelah sukses menambah (opsional)
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Gagal menambahkan ke keranjang")),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey.shade50,
      appBar: AppBar(
        title: const Text("Detail Produk", style: TextStyle(color: Colors.black87, fontSize: 18)),
        backgroundColor: Colors.white,
        elevation: 0,
        iconTheme: const IconThemeData(color: Colors.black87),
        actions: [
          // --- TOMBOL WISHLIST (LOVE) DI POJOK KANAN ATAS ---
          isWishlistLoading 
              ? const Padding(
                  padding: EdgeInsets.symmetric(horizontal: 16.0),
                  child: Center(child: SizedBox(width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2))),
                )
              : IconButton(
                  icon: Icon(
                    isWishlisted ? Icons.favorite : Icons.favorite_border,
                    color: isWishlisted ? Colors.red : Colors.black87,
                    size: 28,
                  ),
                  onPressed: _toggleWishlist,
                ),
          const SizedBox(width: 8),
        ],
      ),
      body: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Gambar Produk
            Container(
              width: double.infinity,
              height: 300,
              color: Colors.white,
              child: widget.product.image != null
                  ? Image.network(
                      "http://127.0.0.1:8000/uploads/products/${widget.product.image}",
                      fit: BoxFit.contain,
                      errorBuilder: (context, error, stackTrace) =>
                          const Icon(Icons.image_not_supported, size: 100, color: Colors.grey),
                    )
                  : const Icon(Icons.image, size: 100, color: Colors.grey),
            ),
            const SizedBox(height: 16),
            
            // Detail Informasi
            Container(
              color: Colors.white,
              padding: const EdgeInsets.all(20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Expanded(
                        child: Text(
                          widget.product.name,
                          style: const TextStyle(fontSize: 22, fontWeight: FontWeight.bold),
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  Text(
                    "Rp ${widget.product.price.toStringAsFixed(0)}",
                    style: const TextStyle(fontSize: 24, fontWeight: FontWeight.w800, color: Color(0xFFE65100)),
                  ),
                  const SizedBox(height: 12),
                  Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                        decoration: BoxDecoration(
                          color: widget.product.stockStatus == 'instock' ? Colors.green.shade100 : Colors.red.shade100,
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Text(
                          widget.product.stockStatus == 'instock' ? "Stok Tersedia" : "Habis",
                          style: TextStyle(
                            color: widget.product.stockStatus == 'instock' ? Colors.green.shade800 : Colors.red.shade800,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    ],
                  ),
                  const Divider(height: 40, thickness: 1),
                  const Text(
                    "Deskripsi Produk",
                    style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 12),
                  Text(
                    widget.product.description ?? 'Tidak ada deskripsi tersedia.',
                    style: const TextStyle(fontSize: 15, color: Colors.black87, height: 1.5),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
      bottomNavigationBar: Container(
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
        decoration: BoxDecoration(
          color: Colors.white,
          boxShadow: [
            BoxShadow(color: Colors.grey.shade300, offset: const Offset(0, -1), blurRadius: 10),
          ],
        ),
        child: SafeArea(
          child: Row(
            children: [
              // Pengatur Jumlah (Quantity)
              Container(
                decoration: BoxDecoration(
                  border: Border.all(color: Colors.grey.shade300),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Row(
                  children: [
                    IconButton(
                      icon: const Icon(Icons.remove),
                      onPressed: () {
                        if (quantity > 1) setState(() => quantity--);
                      },
                    ),
                    Text(quantity.toString(), style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                    IconButton(
                      icon: const Icon(Icons.add),
                      onPressed: () {
                        setState(() => quantity++);
                      },
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 16),
              
              // Tombol Tambah ke Keranjang
              Expanded(
                child: SizedBox(
                  height: 50,
                  child: ElevatedButton.icon(
                    onPressed: isAddingToCart ? null : _addToCart,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: widget.product.stockStatus == 'instock' ? Colors.blue : Colors.grey,
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                    ),
                    icon: isAddingToCart 
                        ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2))
                        : const Icon(Icons.shopping_cart, color: Colors.white),
                    label: Text(
                      isAddingToCart ? "Menambahkan..." : "Tambah ke Keranjang",
                      style: const TextStyle(fontSize: 16, color: Colors.white, fontWeight: FontWeight.bold),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
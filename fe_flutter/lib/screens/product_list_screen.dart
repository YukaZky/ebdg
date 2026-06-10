import 'package:flutter/material.dart';
import '../models/product_model.dart';
import '../services/api_service.dart';
import 'product_detail_screen.dart';
import 'wishlist_screen.dart'; 

class ProductListScreen extends StatefulWidget {
  const ProductListScreen({Key? key}) : super(key: key);

  @override
  State<ProductListScreen> createState() => _ProductListScreenState();
}

class _ProductListScreenState extends State<ProductListScreen> {
  late Future<List<Product>> _productsFuture;

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  void _loadData() {
    setState(() {
      _productsFuture = ApiService.getProducts();
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        titleSpacing: 16,
        
        flexibleSpace: Container(
          decoration: const BoxDecoration(
            image: DecorationImage(
              image: AssetImage('assets/appbar.png'), 
              fit: BoxFit.cover, 
            ),
          ),
        ),

        title: Container(
          height: 45,
          decoration: BoxDecoration(
            color: Colors.white.withOpacity(0.95),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: Colors.grey.shade300),
          ),
          child: TextField(
            decoration: const InputDecoration(
              hintText: "Cari produk kesukaanmu...",
              hintStyle: TextStyle(color: Colors.grey, fontSize: 14),
              prefixIcon: Icon(Icons.search, color: Colors.grey),
              border: InputBorder.none,
              contentPadding: EdgeInsets.symmetric(vertical: 12),
            ),
            onChanged: (value) {
              // Fungsi pencarian
            },
          ),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.favorite_border, color: Colors.white, size: 28),
            onPressed: () {
              if (ApiService.token == null) {
                 ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Silakan login di menu Akun terlebih dahulu')),
                 );
              } else {
                 Navigator.push(
                   context,
                   MaterialPageRoute(builder: (context) => const WishlistScreen()),
                 );
              }
            },
          ),
          IconButton(
            icon: const Icon(Icons.notifications_none, color: Colors.white, size: 28),
            onPressed: () {
              // Fungsi notifikasi
            },
          ),
          const SizedBox(width: 8), 
        ],
      ),
      body: RefreshIndicator(
        onRefresh: () async {
          _loadData();
          await _productsFuture;
        },
        child: FutureBuilder<List<Product>>(
          future: _productsFuture,
          builder: (context, snapshot) {
            if (snapshot.connectionState == ConnectionState.waiting) {
              return const Center(child: CircularProgressIndicator());
            } else if (snapshot.hasError) {
              return Center(child: Text("Gagal memuat: ${snapshot.error}"));
            } else if (!snapshot.hasData || snapshot.data!.isEmpty) {
              return const Center(child: Text("Tidak ada produk tersedia"));
            }

            final products = snapshot.data!;
            return GridView.builder(
              padding: const EdgeInsets.all(16),
              gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: 2,
                childAspectRatio: 0.58, // Sedikit diperpanjang untuk memberi ruang variasi
                crossAxisSpacing: 16,
                mainAxisSpacing: 16,
              ),
              itemCount: products.length,
              itemBuilder: (context, index) {
                final product = products[index];
                // Memanggil widget ProductCard terpisah di bawah
                return ProductCard(product: product); 
              },
            );
          },
        ),
      ),
    );
  }
}

// ==============================================================
// WIDGET CARD PRODUK (Dinamis: Ganti gambar saat variasi diklik)
// ==============================================================
class ProductCard extends StatefulWidget {
  final Product product;
  const ProductCard({Key? key, required this.product}) : super(key: key);

  @override
  State<ProductCard> createState() => _ProductCardState();
}

class _ProductCardState extends State<ProductCard> {
  String? currentImageUrl;

  @override
  void initState() {
    super.initState();
    // Default gambar adalah gambar utama produk
    currentImageUrl = widget.product.image; 
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () {
        Navigator.push(
          context,
          MaterialPageRoute(builder: (context) => ProductDetailScreen(product: widget.product)),
        );
      },
      child: Container(
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          boxShadow: [
            BoxShadow(
              color: Colors.grey.withOpacity(0.1),
              blurRadius: 10,
              spreadRadius: 1,
              offset: const Offset(0, 5),
            )
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // --- GAMBAR UTAMA ---
            Expanded(
              child: ClipRRect(
                borderRadius: const BorderRadius.vertical(top: Radius.circular(16)),
                child: Container(
                  width: double.infinity,
                  color: Colors.white,
                  child: currentImageUrl != null
                      ? Image.network(
                          "http://127.0.0.1:8000/uploads/products/$currentImageUrl",
                          fit: BoxFit.cover,
                          errorBuilder: (c, e, s) => const Icon(Icons.image_not_supported, size: 50, color: Colors.grey),
                        )
                      : const Icon(Icons.image, size: 50, color: Colors.grey),
                ),
              ),
            ),
            
            // --- INFO PRODUK & VARIASI ---
            Padding(
              padding: const EdgeInsets.all(12.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    widget.product.name,
                    style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 4),
                  Text(
                    "Rp ${widget.product.price.toStringAsFixed(0)}",
                    style: const TextStyle(color: Color(0xFFE65100), fontWeight: FontWeight.w800, fontSize: 14),
                  ),
                  const SizedBox(height: 4),
                  Row(
                    children: [
                      Icon(
                        Icons.check_circle,
                        size: 14,
                        color: widget.product.stockStatus == 'instock' ? Colors.green : Colors.red,
                      ),
                      const SizedBox(width: 4),
                      Text(
                        widget.product.stockStatus == 'instock' ? "Stok Tersedia" : "Habis",
                        style: TextStyle(
                          fontSize: 12,
                          color: widget.product.stockStatus == 'instock' ? Colors.green : Colors.red,
                        ),
                      ),
                    ],
                  ),
                  
                  // --- PILIHAN VARIASI WARNA/JENIS ---
                  if (widget.product.variations != null && widget.product.variations!.isNotEmpty) ...[
                    const SizedBox(height: 8),
                    Wrap(
                      spacing: 6, 
                      runSpacing: 4, // Jarak vertikal jika variasi turun ke baris baru
                      children: widget.product.variations!.map((variation) {
                        return GestureDetector(
                          onTap: () {
                            setState(() {
                              // Ubah gambar utama menjadi gambar variasi saat diklik
                              currentImageUrl = variation.image ?? widget.product.image;
                            });
                          },
                          child: Container(
                            width: 26, 
                            height: 26,
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              border: Border.all(
                                // Highlight border jika variasi sedang dipilih
                                color: currentImageUrl == (variation.image ?? widget.product.image) 
                                    ? Colors.blue 
                                    : Colors.grey.shade300, 
                                width: 1.5
                              ),
                              image: variation.image != null
                                  ? DecorationImage(
                                      image: NetworkImage("http://127.0.0.1:8000/uploads/products/${variation.image}"),
                                      fit: BoxFit.cover,
                                    )
                                  : null, 
                            ),
                            child: variation.image == null 
                                ? Center(child: Text(variation.name.isNotEmpty ? variation.name[0].toUpperCase() : '?', style: const TextStyle(fontSize: 10, fontWeight: FontWeight.bold)))
                                : null,
                          ),
                        );
                      }).toList(),
                    ),
                  ],
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
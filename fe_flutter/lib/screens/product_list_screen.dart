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
              // TODO: Fungsi pencarian
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
              // TODO: Fungsi notifikasi
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
                childAspectRatio: 0.72, 
                crossAxisSpacing: 16,
                mainAxisSpacing: 16,
              ),
              itemCount: products.length,
              itemBuilder: (context, index) {
                final product = products[index];
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
// WIDGET CARD PRODUK (Khusus Beranda - Tanpa Variasi)
// ==============================================================
class ProductCard extends StatelessWidget {
  final Product product;
  const ProductCard({Key? key, required this.product}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    // --- LOGIKA URL GAMBAR DINAMIS ---
    // Mencegah hardcode IP dan otomatis menyelaraskan dengan ApiService
    String? imageUrl;
    if (product.image != null && product.image!.isNotEmpty) {
      if (product.image!.startsWith('http')) {
        imageUrl = product.image;
      } else {
        String base = ApiService.baseUrl.replaceAll('/api', '');
        imageUrl = "$base/uploads/products/${product.image}";
      }
    }

    return GestureDetector(
      onTap: () {
        Navigator.push(
          context,
          MaterialPageRoute(builder: (context) => ProductDetailScreen(product: product)),
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
            // --- GAMBAR UTAMA PRODUK ---
            Expanded(
              child: ClipRRect(
                borderRadius: const BorderRadius.vertical(top: Radius.circular(16)),
                child: Container(
                  width: double.infinity,
                  color: Colors.white,
                  child: imageUrl != null
                      ? Image.network(
                          imageUrl,
                          fit: BoxFit.cover,
                          errorBuilder: (context, error, stackTrace) => 
                              const Icon(Icons.image_not_supported, size: 50, color: Colors.grey),
                        )
                      : const Icon(Icons.image, size: 50, color: Colors.grey),
                ),
              ),
            ),
            
            // --- INFO PRODUK ---
            Padding(
              padding: const EdgeInsets.all(12.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    product.name,
                    style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 4),
                  Text(
                    "Rp ${product.price.toStringAsFixed(0)}",
                    style: const TextStyle(color: Color(0xFFE65100), fontWeight: FontWeight.w800, fontSize: 14),
                  ),
                  const SizedBox(height: 4),
                  Row(
                    children: [
                      Icon(
                        Icons.check_circle,
                        size: 14,
                        color: product.stockStatus == 'instock' && product.quantity > 0 ? Colors.green : Colors.red,
                      ),
                      const SizedBox(width: 4),
                      Text(
                        product.stockStatus == 'instock' && product.quantity > 0 ? "Stok Tersedia" : "Habis",
                        style: TextStyle(
                          fontSize: 12,
                          color: product.stockStatus == 'instock' && product.quantity > 0 ? Colors.green : Colors.red,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
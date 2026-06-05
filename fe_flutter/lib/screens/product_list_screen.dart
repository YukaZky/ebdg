import 'package:flutter/material.dart';
import '../models/product_model.dart';
import '../services/api_service.dart';
import 'product_detail_screen.dart';

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
        title: const Text("Katalog Produk"),
        actions: [
          IconButton(
              icon: const Icon(Icons.notifications_outlined), onPressed: () {}),
        ],
      ),
      body: Column(
        children: [
          // Kolom Pencarian Palsu (UI Only untuk tampilan profesional)
          Container(
            padding: const EdgeInsets.fromLTRB(16, 8, 16, 16),
            color: Colors.white,
            child: TextField(
              decoration: InputDecoration(
                hintText: "Cari produk kesukaanmu...",
                prefixIcon: const Icon(Icons.search, color: Colors.grey),
                contentPadding: const EdgeInsets.symmetric(vertical: 0),
                fillColor: Colors.grey.shade100,
              ),
            ),
          ),
          Expanded(
            child: RefreshIndicator(
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
                    return Center(
                        child: Text("Gagal memuat: ${snapshot.error}"));
                  } else if (!snapshot.hasData || snapshot.data!.isEmpty) {
                    return const Center(
                        child: Text("Tidak ada produk tersedia"));
                  }

                  final products = snapshot.data!;
                  return GridView.builder(
                    padding: const EdgeInsets.all(16),
                    gridDelegate:
                        const SliverGridDelegateWithFixedCrossAxisCount(
                      crossAxisCount: 2,
                      childAspectRatio:
                          0.65, // Mengatur tinggi proporsional card
                      crossAxisSpacing: 16,
                      mainAxisSpacing: 16,
                    ),
                    itemCount: products.length,
                    itemBuilder: (context, index) {
                      final product = products[index];
                      return GestureDetector(
                        onTap: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                                builder: (context) =>
                                    ProductDetailScreen(product: product)),
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
                              // Area Gambar Produk
                              Expanded(
                                child: ClipRRect(
                                  borderRadius: const BorderRadius.vertical(
                                      top: Radius.circular(16)),
                                  child: Container(
                                    width: double.infinity,
                                    color: Colors.white,
                                    child: product.image != null
                                        ? Image.network(
                                            "http://127.0.0.1:8000/uploads/products/${product.image}",
                                            fit: BoxFit.cover,
                                            // 1. MEMOTONG PENGGUNAAN MEMORI HINGGA 80% (Smooth Scrolling)
                                            cacheWidth: 300,
                                            // 2. MENAMBAHKAN INDIKATOR LOADING ANIMASI
                                            loadingBuilder: (context, child,
                                                loadingProgress) {
                                              if (loadingProgress == null)
                                                return child;
                                              return Center(
                                                child:
                                                    CircularProgressIndicator(
                                                  color: Colors.blue.shade200,
                                                  value: loadingProgress
                                                              .expectedTotalBytes !=
                                                          null
                                                      ? loadingProgress
                                                              .cumulativeBytesLoaded /
                                                          (loadingProgress
                                                                  .expectedTotalBytes ??
                                                              1)
                                                      : null,
                                                ),
                                              );
                                            },
                                            errorBuilder: (c, e, s) =>
                                                const Icon(
                                                    Icons.image_not_supported,
                                                    size: 50,
                                                    color: Colors.grey),
                                          )
                                        : const Icon(Icons.image,
                                            size: 50, color: Colors.grey),
                                  ),
                                ),
                              ),
                              // Area Teks
                              Padding(
                                padding: const EdgeInsets.all(12.0),
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      product.name,
                                      style: const TextStyle(
                                          fontWeight: FontWeight.bold,
                                          fontSize: 14),
                                      maxLines: 2,
                                      overflow: TextOverflow.ellipsis,
                                    ),
                                    const SizedBox(height: 6),
                                    Text(
                                      "Rp ${product.price.toStringAsFixed(0)}",
                                      style: const TextStyle(
                                          color: Color(0xFFE65100),
                                          fontWeight: FontWeight.w800,
                                          fontSize: 15),
                                    ),
                                    const SizedBox(height: 6),
                                    Row(
                                      children: [
                                        Icon(Icons.check_circle,
                                            size: 14,
                                            color:
                                                product.stockStatus == 'instock'
                                                    ? Colors.green
                                                    : Colors.red),
                                        const SizedBox(width: 4),
                                        Text(
                                          product.stockStatus == 'instock'
                                              ? "Stok Tersedia"
                                              : "Habis",
                                          style: TextStyle(
                                            fontSize: 12,
                                            color:
                                                product.stockStatus == 'instock'
                                                    ? Colors.green
                                                    : Colors.red,
                                          ),
                                        ),
                                      ],
                                    ),
                                  ],
                                ),
                              )
                            ],
                          ),
                        ),
                      );
                    },
                  );
                },
              ),
            ),
          ),
        ],
      ),
    );
  }
}

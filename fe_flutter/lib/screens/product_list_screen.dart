import 'package:flutter/material.dart';
import '../models/product_model.dart';
import '../services/api_service.dart';
import '../widgets/marketplace_product_card.dart';
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
          child: const TextField(
            decoration: InputDecoration(
              hintText: 'Cari produk kesukaanmu...',
              hintStyle: TextStyle(color: Colors.grey, fontSize: 14),
              prefixIcon: Icon(Icons.search, color: Colors.grey),
              border: InputBorder.none,
              contentPadding: EdgeInsets.symmetric(vertical: 12),
            ),
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
            onPressed: () {},
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
            }

            if (snapshot.hasError) {
              return Center(child: Text('Gagal memuat: ${snapshot.error}'));
            }

            if (!snapshot.hasData || snapshot.data!.isEmpty) {
              return const Center(child: Text('Tidak ada produk tersedia'));
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
                return MarketplaceProductCard(product: products[index]);
              },
            );
          },
        ),
      ),
    );
  }
}

import 'package:flutter/material.dart';
import '../models/product_model.dart';
import '../services/api_service.dart';
import '../widgets/marketplace_product_card.dart';
import 'marketplace/chat_list_screen.dart';
import 'wishlist_screen.dart';

class ProductListScreen extends StatefulWidget {
  const ProductListScreen({Key? key}) : super(key: key);

  @override
  State<ProductListScreen> createState() => _ProductListScreenState();
}

class _ProductListScreenState extends State<ProductListScreen> {
  late Future<List<Product>> _productsFuture;
  final TextEditingController _searchController = TextEditingController();
  String _searchQuery = '';

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  void _loadData() {
    setState(() {
      _productsFuture = ApiService.getProducts();
    });
  }

  List<Product> _filterProducts(List<Product> products) {
    final query = _searchQuery.trim().toLowerCase();
    if (query.isEmpty) return products;

    return products.where((product) {
      final name = product.name.toLowerCase();
      final description = (product.description ?? '').toLowerCase();
      final shortDescription = (product.shortDescription ?? '').toLowerCase();
      final sku = product.SKU.toLowerCase();
      final variations = (product.variations ?? [])
          .map((item) => item.name.toLowerCase())
          .join(' ');

      return name.contains(query) ||
          description.contains(query) ||
          shortDescription.contains(query) ||
          sku.contains(query) ||
          variations.contains(query);
    }).toList();
  }

  void _openChat() {
    if (ApiService.token == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
            content: Text('Silakan login terlebih dahulu untuk membuka chat')),
      );
      return;
    }

    Navigator.push(
        context, MaterialPageRoute(builder: (_) => const ChatListScreen()));
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
            controller: _searchController,
            onChanged: (value) => setState(() => _searchQuery = value),
            decoration: InputDecoration(
              hintText: 'Cari produk kesukaanmu...',
              hintStyle: const TextStyle(color: Colors.grey, fontSize: 14),
              prefixIcon: const Icon(Icons.search, color: Colors.grey),
              suffixIcon: _searchQuery.isEmpty
                  ? null
                  : IconButton(
                      icon:
                          const Icon(Icons.close, color: Colors.grey, size: 20),
                      onPressed: () {
                        _searchController.clear();
                        setState(() => _searchQuery = '');
                      },
                    ),
              border: InputBorder.none,
              contentPadding: const EdgeInsets.symmetric(vertical: 12),
            ),
          ),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.favorite_border,
                color: Colors.white, size: 27),
            onPressed: () {
              if (ApiService.token == null) {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                      content:
                          Text('Silakan login di menu Akun terlebih dahulu')),
                );
              } else {
                Navigator.push(
                    context,
                    MaterialPageRoute(
                        builder: (context) => const WishlistScreen()));
              }
            },
          ),
          IconButton(
            icon: const Icon(Icons.notifications_none,
                color: Colors.white, size: 27),
            onPressed: () {},
          ),
          IconButton(
            icon: const Icon(Icons.chat_bubble_outline,
                color: Colors.white, size: 25),
            onPressed: _openChat,
          ),
          const SizedBox(width: 6),
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
              return ListView(
                physics:
                    const AlwaysScrollableScrollPhysics(), // Memaksa agar layar selalu bisa di-scroll / di-refresh
                children: [
                  SizedBox(height: MediaQuery.of(context).size.height * 0.35),
                  const Center(
                    child: Text(
                      'Tidak ada produk tersedia',
                      style: TextStyle(fontSize: 16, color: Colors.grey),
                    ),
                  ),
                ],
              );
            }

            final products = _filterProducts(snapshot.data!);

            if (products.isEmpty) {
              return ListView(
                children: [
                  const SizedBox(height: 140),
                  Icon(Icons.search_off, size: 72, color: Colors.grey.shade400),
                  const SizedBox(height: 12),
                  Center(
                    child: Text(
                      'Produk "$_searchQuery" tidak ditemukan',
                      style: TextStyle(
                          color: Colors.grey.shade700,
                          fontWeight: FontWeight.w600),
                    ),
                  ),
                ],
              );
            }

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

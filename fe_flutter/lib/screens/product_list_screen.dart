import 'package:flutter/material.dart';
import '../models/product_model.dart';
import '../services/api_service.dart';
import '../services/product_cache_service.dart';
import '../widgets/marketplace_product_card.dart';
import 'marketplace/chat_list_screen.dart';
import 'wishlist_screen.dart';

class ProductListScreen extends StatefulWidget {
  const ProductListScreen({Key? key}) : super(key: key);

  @override
  State<ProductListScreen> createState() => _ProductListScreenState();
}

class _ProductListScreenState extends State<ProductListScreen> with AutomaticKeepAliveClientMixin<ProductListScreen> {
  final TextEditingController _searchController = TextEditingController();
  final ScrollController _scrollController = ScrollController();
  List<Product> _products = [];
  String _searchQuery = '';
  String? _errorMessage;
  bool _isLoading = true;
  bool _isRefreshing = false;
  int _loadRequestId = 0;

  @override
  bool get wantKeepAlive => true;

  @override
  void initState() {
    super.initState();
    final cachedProducts = ProductCacheService.cachedProducts;
    if (cachedProducts.isNotEmpty) {
      _products = cachedProducts;
      _isLoading = false;
    }
    _loadData();
  }

  @override
  void dispose() {
    _searchController.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  Future<void> _loadData({bool forceRefresh = false}) async {
    final requestId = ++_loadRequestId;

    if (mounted) {
      setState(() {
        if (_products.isEmpty) _isLoading = true;
        _isRefreshing = _products.isNotEmpty || forceRefresh;
        if (forceRefresh) _errorMessage = null;
      });
    }

    try {
      final products = await ProductCacheService.getProducts(forceRefresh: forceRefresh);
      if (!mounted || requestId != _loadRequestId) return;

      setState(() {
        _products = products;
        _errorMessage = null;
        _isLoading = false;
        _isRefreshing = false;
      });
    } catch (error) {
      if (!mounted || requestId != _loadRequestId) return;

      setState(() {
        _errorMessage = error.toString().replaceFirst('Exception: ', '');
        _isLoading = false;
        _isRefreshing = false;
      });
    }
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

  Widget _loadingList() {
    return ListView(
      physics: const AlwaysScrollableScrollPhysics(),
      children: [
        SizedBox(height: MediaQuery.of(context).size.height * 0.32),
        const Center(child: CircularProgressIndicator()),
      ],
    );
  }

  Widget _emptyOrErrorList() {
    final hasError = _errorMessage != null;
    return ListView(
      physics: const AlwaysScrollableScrollPhysics(),
      children: [
        SizedBox(height: MediaQuery.of(context).size.height * 0.24),
        Icon(hasError ? Icons.wifi_off_rounded : Icons.inventory_2_outlined, size: 76, color: Colors.grey.shade400),
        const SizedBox(height: 14),
        Center(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 28),
            child: Text(
              hasError ? _errorMessage! : 'Tidak ada produk tersedia',
              textAlign: TextAlign.center,
              style: TextStyle(fontSize: 15, color: Colors.grey.shade700, fontWeight: FontWeight.w600, height: 1.35),
            ),
          ),
        ),
        if (hasError) ...[
          const SizedBox(height: 16),
          Center(
            child: ElevatedButton.icon(
              onPressed: _isLoading ? null : () => _loadData(forceRefresh: true),
              icon: const Icon(Icons.refresh),
              label: const Text('Coba Lagi'),
            ),
          ),
        ],
      ],
    );
  }

  Widget _searchEmptyList() {
    return ListView(
      physics: const AlwaysScrollableScrollPhysics(),
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

  Widget _productGrid(List<Product> products) {
    return Stack(
      children: [
        GridView.builder(
          key: const PageStorageKey('home-product-grid'),
          controller: _scrollController,
          physics: const AlwaysScrollableScrollPhysics(),
          padding: EdgeInsets.fromLTRB(16, _errorMessage == null ? 16 : 66, 16, 16),
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
        ),
        if (_isRefreshing)
          const Positioned(left: 0, right: 0, top: 0, child: LinearProgressIndicator(minHeight: 2)),
        if (_errorMessage != null)
          Positioned(
            left: 12,
            right: 12,
            top: 10,
            child: Material(
              color: Colors.orange.shade50,
              elevation: 1,
              borderRadius: BorderRadius.circular(12),
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                child: Row(children: [
                  Icon(Icons.info_outline, color: Colors.orange.shade800, size: 18),
                  const SizedBox(width: 8),
                  Expanded(child: Text(_errorMessage!, maxLines: 2, overflow: TextOverflow.ellipsis, style: TextStyle(color: Colors.orange.shade900, fontSize: 12, fontWeight: FontWeight.w600))),
                  TextButton(onPressed: () => _loadData(forceRefresh: true), child: const Text('Ulangi')),
                ]),
              ),
            ),
          ),
      ],
    );
  }

  Widget _bodyContent() {
    if (_isLoading && _products.isEmpty) return _loadingList();
    if (_products.isEmpty) return _emptyOrErrorList();

    final products = _filterProducts(_products);
    if (products.isEmpty) return _searchEmptyList();

    return _productGrid(products);
  }

  @override
  Widget build(BuildContext context) {
    super.build(context);

    return Scaffold(
      appBar: AppBar(
        automaticallyImplyLeading: false,
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
        onRefresh: () => _loadData(forceRefresh: true),
        child: _bodyContent(),
      ),
    );
  }
}

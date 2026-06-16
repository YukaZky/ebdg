import 'package:flutter/material.dart';
import '../../services/api_service.dart';
import 'admin_product_form_screen.dart';

class AdminProductsScreen extends StatefulWidget {
  const AdminProductsScreen({Key? key}) : super(key: key);

  @override
  State<AdminProductsScreen> createState() => _AdminProductsScreenState();
}

class _AdminProductsScreenState extends State<AdminProductsScreen> {
  List<dynamic> products = [];
  List<dynamic> filteredProducts = [];
  bool isLoading = true;

  final TextEditingController _searchController = TextEditingController();
  String _filterStatus = 'all'; // all, instock, outofstock

  @override
  void initState() {
    super.initState();
    _loadProducts();
  }

  Future<void> _loadProducts() async {
    setState(() => isLoading = true);
    final data = await ApiService.getAdminProducts();
    setState(() {
      products = data;
      _applyFilters();
      isLoading = false;
    });
  }

  void _applyFilters() {
    String query = _searchController.text.toLowerCase().trim();

    setState(() {
      filteredProducts = products.where((item) {
        final name = (item['name'] ?? '').toLowerCase();
        final stock = int.tryParse(item['quantity'].toString()) ?? 0;
        final matchesSearch = query.isEmpty || name.contains(query);

        if (_filterStatus == 'instock') {
          return matchesSearch && stock > 0;
        } else if (_filterStatus == 'outofstock') {
          return matchesSearch && stock == 0;
        }
        return matchesSearch;
      }).toList();
    });
  }

  String _productImageUrl(dynamic image) {
    final value = image?.toString().trim() ?? '';
    if (value.isEmpty || value == 'null') return '';

    if (value.startsWith('http://') || value.startsWith('https://')) {
      return value;
    }

    final base = ApiService.baseUrl.replaceFirst(RegExp(r'/api/?$'), '');
    final cleanValue = value.startsWith('/') ? value.substring(1) : value;

    if (cleanValue.startsWith('uploads/') || cleanValue.startsWith('storage/')) {
      return '$base/$cleanValue';
    }

    return '$base/uploads/products/$cleanValue';
  }

  String _productCoverImageUrl(dynamic item) {
    if (item is! Map) return '';

    final mainImageUrl = _productImageUrl(item['image']);
    if (mainImageUrl.isNotEmpty) return mainImageUrl;

    final galleryImages = item['images'] ?? item['product_images'];
    if (galleryImages is List && galleryImages.isNotEmpty) {
      final firstImage = galleryImages.first;

      if (firstImage is Map) {
        return _productImageUrl(firstImage['image']);
      }

      return _productImageUrl(firstImage);
    }

    return '';
  }

  void _showCustomSnackBar(String message, {bool isError = false}) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message, style: const TextStyle(color: Colors.white)),
        backgroundColor: isError ? Colors.red.shade800 : Colors.indigo.shade700,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        margin: const EdgeInsets.all(16),
      ),
    );
  }

  Future<void> _deleteProduct(int id) async {
    bool success = await ApiService.deleteAdminProduct(id);
    if (success) {
      _showCustomSnackBar("Produk berhasil dihapus");
      _loadProducts();
    } else {
      _showCustomSnackBar("Gagal menghapus produk", isError: true);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF8F9FA),
      floatingActionButton: FloatingActionButton(
        backgroundColor: Colors.indigo,
        elevation: 4,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        child: const Icon(Icons.add, color: Colors.white, size: 28),
        onPressed: () async {
          final isChanged = await Navigator.push(
            context,
            MaterialPageRoute(builder: (context) => const AdminProductFormScreen()),
          );
          if (isChanged == true) _loadProducts();
        },
      ),
      body: RefreshIndicator(
        color: Colors.indigo,
        onRefresh: _loadProducts,
        child: CustomScrollView(
          slivers: [
            // App Bar dengan Search
            SliverAppBar(
              expandedHeight: 120,
              floating: true,
              pinned: true,
              backgroundColor: const Color(0xFFF8F9FA),
              elevation: 0,
              flexibleSpace: FlexibleSpaceBar(
                titlePadding: const EdgeInsets.only(left: 20, bottom: 16, right: 20),
                title: const Text(
                  "Daftar Produk",
                  style: TextStyle(
                    color: Colors.black87,
                    fontWeight: FontWeight.w800,
                    fontSize: 24,
                  ),
                ),
              ),
            ),

            SliverPadding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              sliver: SliverToBoxAdapter(
                child: Column(
                  children: [
                    // Search Bar
                    TextField(
                      controller: _searchController,
                      onChanged: (_) => _applyFilters(),
                      decoration: InputDecoration(
                        hintText: "Cari produk...",
                        prefixIcon: const Icon(Icons.search, color: Colors.grey),
                        filled: true,
                        fillColor: Colors.white,
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(16),
                          borderSide: BorderSide.none,
                        ),
                        contentPadding: const EdgeInsets.symmetric(vertical: 14),
                      ),
                    ),
                    const SizedBox(height: 16),

                    // Filter Chips
                    SingleChildScrollView(
                      scrollDirection: Axis.horizontal,
                      child: Row(
                        children: [
                          _buildFilterChip("Semua", 'all'),
                          const SizedBox(width: 8),
                          _buildFilterChip("Tersedia", 'instock'),
                          const SizedBox(width: 8),
                          _buildFilterChip("Habis", 'outofstock'),
                        ],
                      ),
                    ),
                    const SizedBox(height: 16),
                  ],
                ),
              ),
            ),

            SliverPadding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              sliver: _buildProductList(),
            ),

            const SliverToBoxAdapter(child: SizedBox(height: 100)),
          ],
        ),
      ),
    );
  }

  Widget _buildFilterChip(String label, String value) {
    final isSelected = _filterStatus == value;
    return FilterChip(
      selected: isSelected,
      label: Text(label),
      backgroundColor: Colors.white,
      selectedColor: Colors.indigo.shade50,
      labelStyle: TextStyle(
        color: isSelected ? Colors.indigo : Colors.black87,
        fontWeight: isSelected ? FontWeight.w600 : FontWeight.w500,
      ),
      onSelected: (selected) {
        setState(() {
          _filterStatus = value;
          _applyFilters();
        });
      },
    );
  }

  Widget _buildProductList() {
    if (isLoading) {
      return const SliverFillRemaining(
        child: Center(child: CircularProgressIndicator(color: Colors.indigo)),
      );
    }

    if (filteredProducts.isEmpty) {
      return SliverFillRemaining(
        child: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(Icons.inventory_2_outlined, size: 80, color: Colors.grey.shade300),
              const SizedBox(height: 24),
              const Text(
                "Tidak ada produk",
                style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 8),
              Text(
                _searchController.text.isNotEmpty ? "Tidak ditemukan hasil pencarian" : "Mulai tambahkan produk Anda",
                style: TextStyle(color: Colors.grey.shade600),
                textAlign: TextAlign.center,
              ),
            ],
          ),
        ),
      );
    }

    return SliverList(
      delegate: SliverChildBuilderDelegate(
        (context, index) {
          final item = filteredProducts[index];
          final int stock = int.tryParse(item['quantity'].toString()) ?? 0;
          final String imageUrl = _productCoverImageUrl(item);

          return Container(
            margin: const EdgeInsets.only(bottom: 16),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(20),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.04),
                  blurRadius: 10,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
            child: Material(
              color: Colors.transparent,
              child: InkWell(
                borderRadius: BorderRadius.circular(20),
                onTap: () async {
                  final isChanged = await Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => AdminProductFormScreen(product: item),
                    ),
                  );
                  if (isChanged == true) _loadProducts();
                },
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Row(
                    children: [
                      // Product Image
                      Hero(
                        tag: 'product_${item['id']}',
                        child: ClipRRect(
                          borderRadius: BorderRadius.circular(16),
                          child: imageUrl.isNotEmpty
                              ? Image.network(
                                  imageUrl,
                                  width: 72,
                                  height: 72,
                                  fit: BoxFit.cover,
                                  errorBuilder: (_, __, ___) => _buildPlaceholder(),
                                )
                              : _buildPlaceholder(),
                        ),
                      ),
                      const SizedBox(width: 16),

                      // Product Info
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              item['name'] ?? 'Tanpa Nama',
                              style: const TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.w700,
                                color: Colors.black87,
                              ),
                              maxLines: 2,
                              overflow: TextOverflow.ellipsis,
                            ),
                            const SizedBox(height: 6),
                            Text(
                              "Rp ${item['regular_price']}",
                              style: const TextStyle(
                                fontSize: 15,
                                fontWeight: FontWeight.w600,
                                color: Colors.indigo,
                              ),
                            ),
                            const SizedBox(height: 6),
                            Row(
                              children: [
                                Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                                  decoration: BoxDecoration(
                                    color: stock > 0 ? Colors.green.shade50 : Colors.red.shade50,
                                    borderRadius: BorderRadius.circular(20),
                                  ),
                                  child: Row(
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      CircleAvatar(
                                        radius: 4,
                                        backgroundColor: stock > 0 ? Colors.green : Colors.red,
                                      ),
                                      const SizedBox(width: 6),
                                      Text(
                                        stock > 0 ? "$stock Tersedia" : "Habis Stok",
                                        style: TextStyle(
                                          fontSize: 12,
                                          fontWeight: FontWeight.w600,
                                          color: stock > 0 ? Colors.green.shade700 : Colors.red.shade700,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),

                      // More Options
                      PopupMenuButton<String>(
                        icon: const Icon(Icons.more_vert, color: Colors.grey),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                        onSelected: (value) async {
                          if (value == 'edit') {
                            final isChanged = await Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (context) => AdminProductFormScreen(product: item),
                              ),
                            );
                            if (isChanged == true) _loadProducts();
                          } else if (value == 'delete') {
                            _showDeleteDialog(item['id']);
                          }
                        },
                        itemBuilder: (context) => [
                          const PopupMenuItem(
                            value: 'edit',
                            child: Row(children: [Icon(Icons.edit_outlined), SizedBox(width: 12), Text("Edit")]),
                          ),
                          PopupMenuItem(
                            value: 'delete',
                            child: Row(
                              children: [
                                Icon(Icons.delete_outline, color: Colors.red.shade700),
                                const SizedBox(width: 12),
                                Text("Hapus", style: TextStyle(color: Colors.red.shade700)),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
            ),
          );
        },
        childCount: filteredProducts.length,
      ),
    );
  }

  Widget _buildPlaceholder() {
    return Container(
      width: 72,
      height: 72,
      decoration: BoxDecoration(
        color: Colors.grey.shade100,
        borderRadius: BorderRadius.circular(16),
      ),
      child: const Icon(Icons.image_outlined, color: Colors.grey, size: 32),
    );
  }

  void _showDeleteDialog(int id) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: const Text("Hapus Produk?", style: TextStyle(fontWeight: FontWeight.bold)),
        content: const Text("Tindakan ini tidak dapat dibatalkan."),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text("Batal"),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.red.shade700,
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            ),
            onPressed: () {
              Navigator.pop(context);
              _deleteProduct(id);
            },
            child: const Text("Hapus"),
          ),
        ],
      ),
    );
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }
}

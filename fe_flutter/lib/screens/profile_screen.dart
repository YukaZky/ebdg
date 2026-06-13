import 'package:flutter/material.dart';
import '../services/api_service.dart';
import '../models/product_model.dart';
import 'product_detail_screen.dart';
import 'login_screen.dart';
import 'register_screen.dart';
import 'admin/admin_dashboard_screen.dart';
import 'wishlist_screen.dart'; // Import halaman Wishlist
import 'admin/admin_store_location_screen.dart'; // Import halaman Alamat/Lokasi

class ProfileScreen extends StatefulWidget {
  final Function(String?) onProfileUpdated;

  const ProfileScreen({Key? key, required this.onProfileUpdated}) : super(key: key);

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  Map<String, dynamic>? userProfile;
  bool isLoading = false;
  late Future<List<Product>> _productsFuture;

  @override
  void initState() {
    super.initState();
    _fetchProfile();
    // Memuat data produk untuk bagian "Mungkin Kamu Suka"
    _productsFuture = ApiService.getProducts();
  }

  Future<void> _fetchProfile() async {
    if (ApiService.token == null) {
      widget.onProfileUpdated('Akun');
      setState(() {
        userProfile = null;
      });
      return;
    }

    setState(() => isLoading = true);
    try {
      final data = await ApiService.getUserProfile();
      setState(() {
        userProfile = data;
        isLoading = false;
      });
      if (data != null && data['name'] != null) {
        widget.onProfileUpdated(data['name'].toString());
      }
    } catch (e) {
      setState(() => isLoading = false);
    }
  }

  Future<void> _handleLogout() async {
    setState(() => isLoading = true);
    bool success = await ApiService.logout();
    setState(() => isLoading = false);

    if (success) {
      setState(() {
        userProfile = null;
      });
      widget.onProfileUpdated('Akun');
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Berhasil keluar dari akun'),
          backgroundColor: Colors.green,
        ),
      );
    }
  }

  // Fungsi proteksi fitur wajib login
  void _handleFeatureTap(bool isLoggedIn, VoidCallback onSuccessAction) {
    if (!isLoggedIn) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Silakan login terlebih dahulu untuk mengakses fitur ini'),
          backgroundColor: Colors.redAccent,
          behavior: SnackBarBehavior.floating,
        ),
      );
      Navigator.push(
        context,
        MaterialPageRoute(builder: (context) => const LoginScreen()),
      ).then((_) => _fetchProfile()); 
    } else {
      onSuccessAction();
    }
  }

  @override
  Widget build(BuildContext context) {
    bool isLoggedIn = ApiService.token != null;

    return Scaffold(
      backgroundColor: Colors.white,
      body: isLoading
          ? const Center(
              child: CircularProgressIndicator(
                valueColor: AlwaysStoppedAnimation<Color>(Color(0xFF0C2442)),
              ),
            )
          : SingleChildScrollView(
              child: Column(
                children: [
                  _buildHeader(isLoggedIn),
                  _buildPesananSaya(isLoggedIn),
                  _buildSectionTitle('Aktifitas Saya'),
                  _buildAktifitasSaya(isLoggedIn),
                  _buildSectionTitle('Mulai Kelola Bisnis Anda'),
                  _buildTokoSaya(isLoggedIn),
                  _buildSectionTitleMungkinKamuSuka('Mungkin Kamu Suka'),
                  _buildProductKatalog(),
                  if (isLoggedIn) ...[
                    const SizedBox(height: 20),
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 16.0),
                      child: SizedBox(
                        width: double.infinity,
                        child: ElevatedButton(
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.red,
                            padding: const EdgeInsets.symmetric(vertical: 12),
                          ),
                          onPressed: _handleLogout,
                          child: const Text('Keluar Akun', style: TextStyle(color: Colors.white)),
                        ),
                      ),
                    ),
                    const SizedBox(height: 30),
                  ]
                ],
              ),
            ),
    );
  }

  // 1. BAGIAN HEADER DENGAN GAMBAR BACKGROUND LOKAL
  Widget _buildHeader(bool isLoggedIn) {
    String name = isLoggedIn ? (userProfile?['name'] ?? 'User') : 'Tamu (Belum Login)';
    String email = isLoggedIn ? (userProfile?['email'] ?? '') : 'Silakan masuk ke akun Anda';

    return Container(
      width: double.infinity,
      height: 220,
      decoration: const BoxDecoration(
        color: Color(0xFF0C2442), 
        image: DecorationImage(
          image: AssetImage('assets/appbar.png'), 
          fit: BoxFit.cover,
        ),
      ),
      child: SafeArea(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              width: 80,
              height: 80,
              decoration: const BoxDecoration(
                color: Colors.white,
                shape: BoxShape.circle,
              ),
              child: const Icon(
                Icons.person,
                size: 60,
                color: Color(0xFF0C2442),
              ),
            ),
            const SizedBox(height: 16),
            if (!isLoggedIn)
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  ElevatedButton(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.white,
                      foregroundColor: Colors.black,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(20),
                      ),
                      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 8),
                    ),
                    onPressed: () async {
                      await Navigator.push(
                        context,
                        MaterialPageRoute(builder: (context) => const LoginScreen()),
                      );
                      _fetchProfile();
                    },
                    child: const Text('Login', style: TextStyle(fontWeight: FontWeight.bold)),
                  ),
                  const SizedBox(width: 16),
                  ElevatedButton(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFFF39C12),
                      foregroundColor: Colors.black,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(20),
                      ),
                      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 8),
                    ),
                    onPressed: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(builder: (context) => const RegisterScreen()),
                      ).then((_) => _fetchProfile());
                    },
                    child: const Text('Daftar', style: TextStyle(fontWeight: FontWeight.bold)),
                  ),
                ],
              )
            else
              Column(
                children: [
                  Text(
                    name,
                    style: const TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    email,
                    style: TextStyle(color: Colors.white.withOpacity(0.9), fontSize: 13),
                  ),
                ],
              ),
          ],
        ),
      ),
    );
  }

  // 2. BAGIAN PESANAN SAYA
  Widget _buildPesananSaya(bool isLoggedIn) {
    return Container(
      margin: const EdgeInsets.all(16),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(8),
        boxShadow: [
          BoxShadow(
            color: Colors.grey.withOpacity(0.1),
            spreadRadius: 1,
            blurRadius: 5,
            offset: const Offset(0, 2),
          ),
        ],
        border: Border.all(color: Colors.grey.shade200),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Pesanan Saya',
            style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.black87),
          ),
          const SizedBox(height: 16),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              _buildPesananItem(Icons.account_balance_wallet_outlined, 'Belum Bayar', isLoggedIn),
              _buildPesananItem(Icons.inventory_2_outlined, 'Dikemas', isLoggedIn),
              _buildPesananItem(Icons.local_shipping_outlined, 'Dikirim', isLoggedIn),
              _buildPesananItem(Icons.star_outline, 'Beri Penilaian', isLoggedIn),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildPesananItem(IconData icon, String title, bool isLoggedIn) {
    return InkWell(
      onTap: () {
        _handleFeatureTap(isLoggedIn, () {
          // Aksi ke Riwayat Pesanan
        });
      },
      child: Column(
        children: [
          Icon(icon, size: 32, color: Colors.black87),
          const SizedBox(height: 8),
          Text(
            title,
            style: const TextStyle(fontSize: 11, color: Colors.black54),
          ),
        ],
      ),
    );
  }

  // 3. PEMBATAS JUDUL SEKSI
  Widget _buildSectionTitle(String title) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
      child: Row(
        children: [
          Expanded(child: Divider(color: Colors.grey.shade400, thickness: 1)),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 12.0),
            child: Text(
              title,
              style: const TextStyle(fontSize: 14, color: Colors.black87),
            ),
          ),
          Expanded(child: Divider(color: Colors.grey.shade400, thickness: 1)),
        ],
      ),
    );
  }

  Widget _buildSectionTitleMungkinKamuSuka(String title) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 16.0),
      child: Row(
        children: [
          Text(
            title,
            style: const TextStyle(fontSize: 14, color: Colors.black87),
          ),
          const SizedBox(width: 12),
          Expanded(child: Divider(color: Colors.grey.shade400, thickness: 1)),
        ],
      ),
    );
  }

  // 4. BAGIAN AKTIFITAS SAYA (MENAMBAHKAN NAVIGASI KE FAVORIT & ALAMAT)
  Widget _buildAktifitasSaya(bool isLoggedIn) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
      child: Column(
        children: [
          Row(
            children: [
              Expanded(
                child: _buildBoxMenu('Favorit Saya', Icons.favorite, const Color(0xFF0C2442), () {
                  _handleFeatureTap(isLoggedIn, () {
                    // Navigasi ke WishlistScreen
                    Navigator.push(
                      context,
                      MaterialPageRoute(builder: (context) => const WishlistScreen()),
                    );
                  });
                }),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _buildBoxMenu('Chat Penjual', Icons.chat_bubble, const Color(0xFF0C2442), () {
                  _handleFeatureTap(isLoggedIn, () {
                    // Aksi Buka Chat Penjual
                  });
                }),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                child: _buildBoxMenu('Alamat Anda', Icons.location_on, const Color(0xFF0C2442), () {
                  _handleFeatureTap(isLoggedIn, () {
                    // Navigasi ke AdminStoreLocationScreen sesuai permintaan
                    Navigator.push(
                      context,
                      MaterialPageRoute(builder: (context) => const AdminStoreLocationScreen()),
                    );
                  });
                }),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _buildBoxMenu('Kupon', Icons.local_activity, const Color(0xFF0C2442), () {
                  _handleFeatureTap(isLoggedIn, () {
                    // Aksi Buka Kupon
                  });
                }),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildBoxMenu(String title, IconData icon, Color iconColor, VoidCallback onTap) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(8),
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 12),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(8),
          border: Border.all(color: const Color(0xFFF39C12), width: 1.5),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              title,
              style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w500, color: Colors.black87),
            ),
            Icon(icon, color: iconColor, size: 20),
          ],
        ),
      ),
    );
  }

  // 5. BAGIAN TOKO SAYA
  Widget _buildTokoSaya(bool isLoggedIn) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
      child: InkWell(
        onTap: () {
          _handleFeatureTap(isLoggedIn, () {
            Navigator.push(
              context,
              MaterialPageRoute(builder: (context) => const AdminDashboardScreen()),
            );
          });
        },
        borderRadius: BorderRadius.circular(8),
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 16),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(8),
            border: Border.all(color: const Color(0xFFF39C12), width: 1.5),
          ),
          child: const Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Icon(Icons.storefront, color: Color(0xFF0C2442), size: 24),
              Text(
                'T O K O   S A Y A',
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, letterSpacing: 2.0, color: Colors.black87),
              ),
              Icon(Icons.storefront, color: Color(0xFF0C2442), size: 24),
            ],
          ),
        ),
      ),
    );
  }

  // 6. BAGIAN KATALOG PRODUK DINAMIS (MUNGKIN KAMU SUKA)
  Widget _buildProductKatalog() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16.0),
      child: FutureBuilder<List<Product>>(
        future: _productsFuture,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(
              child: Padding(
                padding: EdgeInsets.all(20.0),
                child: CircularProgressIndicator(),
              )
            );
          } else if (snapshot.hasError) {
            return Center(child: Text("Gagal memuat produk: ${snapshot.error}"));
          } else if (!snapshot.hasData || snapshot.data!.isEmpty) {
            return const Center(
              child: Padding(
                padding: EdgeInsets.all(20.0),
                child: Text("Tidak ada produk tersedia")
              )
            );
          }

          final products = snapshot.data!;
          return GridView.builder(
            physics: const NeverScrollableScrollPhysics(), // Scroll mengikuti Parent
            shrinkWrap: true, // Wajib true karena didalam SingleChildScrollView
            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 2,
              childAspectRatio: 0.58, // Rasio agar kartu panjang ke bawah
              crossAxisSpacing: 12,
              mainAxisSpacing: 12,
            ),
            itemCount: products.length,
            itemBuilder: (context, index) {
              final product = products[index];
              return ProductCard(product: product); 
            },
          );
        },
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
                      runSpacing: 4, 
                      children: widget.product.variations!.map((variation) {
                        return GestureDetector(
                          onTap: () {
                            setState(() {
                              currentImageUrl = variation.image ?? widget.product.image;
                            });
                          },
                          child: Container(
                            width: 26, 
                            height: 26,
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              border: Border.all(
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
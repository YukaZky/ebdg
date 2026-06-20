import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import '../models/product_model.dart';
import '../services/api_service.dart';
import '../services/profile_photo_service.dart';
import '../widgets/marketplace_product_card.dart';
import 'account_settings_screen.dart';
import 'admin/address_list_screen.dart';
import 'admin/admin_dashboard_screen.dart';
import 'login_screen.dart';
import 'register_screen.dart';

class ProfileScreen extends StatefulWidget {
  final Function(String?) onProfileUpdated;

  const ProfileScreen({Key? key, required this.onProfileUpdated}) : super(key: key);

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  Map<String, dynamic>? userProfile;
  bool isLoading = false;
  bool isUploadingPhoto = false;
  late Future<List<Product>> _productsFuture;
  final ImagePicker _picker = ImagePicker();

  @override
  void initState() {
    super.initState();
    _fetchProfile();
    _productsFuture = ApiService.getProducts();
  }

  Future<void> _fetchProfile() async {
    if (ApiService.token == null) {
      widget.onProfileUpdated('Akun');
      setState(() => userProfile = null);
      return;
    }

    setState(() => isLoading = true);
    try {
      final data = await ApiService.getUserProfile();
      if (!mounted) return;
      setState(() {
        userProfile = data;
        isLoading = false;
      });
      if (data != null && data['name'] != null) widget.onProfileUpdated(data['name'].toString());
    } catch (_) {
      if (!mounted) return;
      setState(() => isLoading = false);
    }
  }

  String _maskEmail(dynamic value) {
    final email = value?.toString().trim() ?? '';
    if (email.isEmpty || !email.contains('@')) return 'Email belum diatur';

    final parts = email.split('@');
    final name = parts.first;
    final domain = parts.length > 1 ? parts.last : '';
    final visible = name.length <= 2 ? name.substring(0, 1) : name.substring(0, 2);
    return '$visible***@$domain';
  }

  String _maskPhone(dynamic value) {
    final phone = value?.toString().trim() ?? '';
    if (phone.isEmpty || phone == 'null') return 'Nomor HP belum diatur';
    if (phone.length <= 4) return '****';

    final start = phone.length >= 4 ? phone.substring(0, 4) : phone.substring(0, 1);
    final end = phone.length >= 3 ? phone.substring(phone.length - 3) : '';
    return '$start****$end';
  }

  Future<void> _openAccountSettings() async {
    if (userProfile == null) return;

    final updated = await Navigator.push<Map<String, dynamic>>(
      context,
      MaterialPageRoute(builder: (_) => AccountSettingsScreen(userProfile: userProfile!)),
    );

    if (!mounted) return;
    if (updated != null) {
      setState(() => userProfile = updated);
      if (updated['name'] != null) widget.onProfileUpdated(updated['name'].toString());
    } else {
      _fetchProfile();
    }
  }

  Future<void> _changeProfilePhoto() async {
    if (ApiService.token == null) return;

    final picked = await _picker.pickImage(source: ImageSource.gallery, imageQuality: 80);
    if (picked == null) return;

    setState(() => isUploadingPhoto = true);
    final updatedProfile = await ProfilePhotoService.savePhoto(picked);
    if (!mounted) return;
    setState(() {
      if (updatedProfile != null) userProfile = updatedProfile;
      isUploadingPhoto = false;
    });

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(updatedProfile != null ? 'Foto profil berhasil diperbarui' : 'Gagal memperbarui foto profil')),
    );
  }

  Future<void> _handleLogout() async {
    final bool? confirm = await showDialog<bool>(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('Keluar Akun', style: TextStyle(fontWeight: FontWeight.bold)),
          content: const Text('Apakah Anda yakin ingin keluar dari akun saat ini?'),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context, false),
              child: const Text('Batal', style: TextStyle(color: Colors.grey)),
            ),
            TextButton(
              onPressed: () => Navigator.pop(context, true),
              child: const Text('Ya, Keluar', style: TextStyle(color: Colors.red, fontWeight: FontWeight.bold)),
            ),
          ],
        );
      },
    );

    if (confirm != true) return;

    setState(() => isLoading = true);
    final success = await ApiService.logout();
    if (!mounted) return;
    setState(() => isLoading = false);

    if (success) {
      setState(() => userProfile = null);
      widget.onProfileUpdated('Akun');
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Berhasil keluar dari akun'), backgroundColor: Colors.green));
    } else {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Gagal keluar, periksa koneksi Anda.'), backgroundColor: Colors.red));
    }
  }

  void _handleFeatureTap(bool isLoggedIn, VoidCallback action) {
    if (!isLoggedIn) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Silakan login terlebih dahulu untuk mengakses fitur ini'), backgroundColor: Colors.redAccent, behavior: SnackBarBehavior.floating));
      Navigator.push(context, MaterialPageRoute(builder: (context) => const LoginScreen())).then((_) => _fetchProfile());
      return;
    }
    action();
  }

  @override
  Widget build(BuildContext context) {
    final isLoggedIn = ApiService.token != null;

    return Scaffold(
      backgroundColor: Colors.white,
      body: isLoading
          ? const Center(child: CircularProgressIndicator(valueColor: AlwaysStoppedAnimation<Color>(Color(0xFF0C2442))))
          : SingleChildScrollView(
              child: Column(
                children: [
                  _buildHeader(isLoggedIn),
                  _buildPesananSaya(isLoggedIn),
                  _buildSectionTitle('Layanan Akun'),
                  _buildLayananAkun(isLoggedIn),
                  _buildSectionTitle('Mulai Kelola Bisnis Anda'),
                  _buildTokoSaya(isLoggedIn),
                  _buildSectionTitleMungkinKamuSuka('Mungkin Kamu Suka'),
                  _buildProductKatalog(),
                  if (isLoggedIn) ...[
                    const SizedBox(height: 16),
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 16),
                      child: SizedBox(
                        width: double.infinity,
                        child: ElevatedButton(
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.red.shade50, 
                            elevation: 0,
                            padding: const EdgeInsets.symmetric(vertical: 14), 
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(8),
                              side: BorderSide(color: Colors.red.shade200, width: 1)
                            )
                          ),
                          onPressed: _handleLogout,
                          child: const Text('Keluar Akun', style: TextStyle(color: Colors.red, fontWeight: FontWeight.bold, fontSize: 15)),
                        ),
                      ),
                    ),
                    const SizedBox(height: 30),
                  ],
                ],
              ),
            ),
    );
  }

  Widget _buildHeader(bool isLoggedIn) {
    final name = isLoggedIn ? (userProfile?['name'] ?? 'User') : 'Tamu (Belum Login)';
    final email = isLoggedIn ? _maskEmail(userProfile?['email']) : 'Silakan masuk ke akun Anda';
    final phone = isLoggedIn ? _maskPhone(userProfile?['phone']) : '';
    final avatarUrl = ProfilePhotoService.imageUrl(userProfile?['avatar']);

    return Container(
      width: double.infinity,
      decoration: const BoxDecoration(
        color: Color(0xFF0C2442),
        image: DecorationImage(image: AssetImage('assets/appbar.png'), fit: BoxFit.cover),
      ),
      child: SafeArea(
        bottom: false,
        child: Padding(
          padding: const EdgeInsets.only(left: 20.0, right: 12.0, top: 16.0, bottom: 24.0),
          child: !isLoggedIn
              ? Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Container(
                      width: 72,
                      height: 72,
                      decoration: const BoxDecoration(color: Colors.white, shape: BoxShape.circle),
                      clipBehavior: Clip.antiAlias,
                      child: const Icon(Icons.person, size: 50, color: Color(0xFF0C2442)),
                    ),
                    const SizedBox(height: 16),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        ElevatedButton(
                          style: ElevatedButton.styleFrom(backgroundColor: Colors.white, foregroundColor: Colors.black, shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)), padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 8)),
                          onPressed: () async {
                            await Navigator.push(context, MaterialPageRoute(builder: (context) => const LoginScreen()));
                            _fetchProfile();
                          },
                          child: const Text('Login', style: TextStyle(fontWeight: FontWeight.bold)),
                        ),
                        const SizedBox(width: 16),
                        ElevatedButton(
                          style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFFF39C12), foregroundColor: Colors.black, shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)), padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 8)),
                          onPressed: () => Navigator.push(context, MaterialPageRoute(builder: (context) => const RegisterScreen())).then((_) => _fetchProfile()),
                          child: const Text('Daftar', style: TextStyle(fontWeight: FontWeight.bold)),
                        ),
                      ],
                    )
                  ],
                )
              : Row(
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    // FOTO PROFIL (KIRI)
                    GestureDetector(
                      onTap: _changeProfilePhoto,
                      child: Stack(
                        clipBehavior: Clip.none,
                        children: [
                          Container(
                            width: 72,
                            height: 72,
                            decoration: BoxDecoration(color: Colors.white, shape: BoxShape.circle, border: Border.all(color: Colors.white, width: 2)),
                            clipBehavior: Clip.antiAlias,
                            child: avatarUrl.isNotEmpty
                                ? Image.network(avatarUrl, fit: BoxFit.cover, errorBuilder: (_, __, ___) => const Icon(Icons.person, size: 50, color: Color(0xFF0C2442)))
                                : const Icon(Icons.person, size: 50, color: Color(0xFF0C2442)),
                          ),
                          Positioned(
                            right: -2,
                            bottom: -2,
                            child: Container(
                              padding: const EdgeInsets.all(5),
                              decoration: const BoxDecoration(color: Color(0xFFF39C12), shape: BoxShape.circle),
                              child: isUploadingPhoto
                                  ? const SizedBox(width: 12, height: 12, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                                  : const Icon(Icons.camera_alt, size: 14, color: Colors.white),
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(width: 16),
                    
                    // DATA DIRI (TENGAH - EXPANDED)
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(name, style: const TextStyle(color: Colors.white, fontSize: 17, fontWeight: FontWeight.bold), maxLines: 1, overflow: TextOverflow.ellipsis),
                          const SizedBox(height: 4),
                          Text(email, style: TextStyle(color: Colors.white.withOpacity(0.9), fontSize: 13), maxLines: 1, overflow: TextOverflow.ellipsis),
                          const SizedBox(height: 2),
                          Text(phone, style: TextStyle(color: Colors.white.withOpacity(0.82), fontSize: 12), maxLines: 1, overflow: TextOverflow.ellipsis),
                        ],
                      ),
                    ),

                    // IKON AKSI (KANAN)
                    Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        IconButton(
                          icon: const Icon(Icons.settings, color: Colors.white, size: 24),
                          tooltip: 'Pengaturan Akun',
                          onPressed: _openAccountSettings,
                        ),
                        IconButton(
                          icon: const Icon(Icons.logout, color: Color.fromARGB(255, 255, 255, 255), size: 24),
                          tooltip: 'Keluar',
                          onPressed: _handleLogout,
                        ),
                      ],
                    )
                  ],
                ),
        ),
      ),
    );
  }

  Widget _buildPesananSaya(bool isLoggedIn) {
    return Container(
      margin: const EdgeInsets.all(16),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(12), boxShadow: [BoxShadow(color: Colors.grey.withOpacity(0.08), spreadRadius: 1, blurRadius: 8, offset: const Offset(0, 3))], border: Border.all(color: Colors.grey.shade200)),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        const Text('Pesanan Saya', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.black87)),
        const SizedBox(height: 16),
        Row(
          children: [
            Expanded(child: _buildPesananItem(Icons.account_balance_wallet_outlined, 'Belum Bayar', isLoggedIn)),
            Expanded(child: _buildPesananItem(Icons.inventory_2_outlined, 'Dikemas', isLoggedIn)),
            Expanded(child: _buildPesananItem(Icons.local_shipping_outlined, 'Dikirim', isLoggedIn)),
            Expanded(child: _buildPesananItem(Icons.star_outline, 'Dinilai', isLoggedIn)),
          ],
        ),
      ]),
    );
  }

  Widget _buildPesananItem(IconData icon, String title, bool isLoggedIn) {
    return InkWell(
      onTap: () => _handleFeatureTap(isLoggedIn, () {}),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 28, color: Colors.black87), 
          const SizedBox(height: 8), 
          Text(title, style: const TextStyle(fontSize: 11, color: Colors.black54), textAlign: TextAlign.center, maxLines: 1, overflow: TextOverflow.ellipsis)
        ]
      ),
    );
  }

  Widget _buildSectionTitle(String title) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
      child: Row(children: [Expanded(child: Divider(color: Colors.grey.shade300, thickness: 1)), Padding(padding: const EdgeInsets.symmetric(horizontal: 12), child: Text(title, style: const TextStyle(fontSize: 13, color: Colors.black54, fontWeight: FontWeight.w600))), Expanded(child: Divider(color: Colors.grey.shade300, thickness: 1))]),
    );
  }

  Widget _buildSectionTitleMungkinKamuSuka(String title) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
      child: Row(children: [Text(title, style: const TextStyle(fontSize: 15, fontWeight: FontWeight.bold, color: Colors.black87)), const SizedBox(width: 12), Expanded(child: Divider(color: Colors.grey.shade300, thickness: 1))]),
    );
  }

  Widget _buildLayananAkun(bool isLoggedIn) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: Row(
        children: [
          Expanded(
            child: _buildBoxMenu('Alamat Saya', Icons.location_on, const Color(0xFF0C2442), () {
              _handleFeatureTap(isLoggedIn, () => Navigator.push(context, MaterialPageRoute(builder: (context) => const AddressListScreen())));
            }),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: _buildBoxMenu('Kupon Saya', Icons.local_activity, const Color(0xFF0C2442), () => _handleFeatureTap(isLoggedIn, () {})),
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
        padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 12),
        decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(8), border: Border.all(color: const Color(0xFFF39C12), width: 1.2)),
        child: Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [Expanded(child: Text(title, style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: Colors.black87), maxLines: 1, overflow: TextOverflow.ellipsis)), Icon(icon, color: iconColor, size: 20)]),
      ),
    );
  }

  Widget _buildTokoSaya(bool isLoggedIn) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: InkWell(
        onTap: () => _handleFeatureTap(isLoggedIn, () => Navigator.push(context, MaterialPageRoute(builder: (context) => const AdminDashboardScreen()))),
        borderRadius: BorderRadius.circular(8),
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 16),
          decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(8), border: Border.all(color: const Color(0xFFF39C12), width: 1.2)),
          child: const Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [Icon(Icons.storefront, color: Color(0xFF0C2442), size: 24), Text('T O K O   S A Y A', style: TextStyle(fontSize: 15, fontWeight: FontWeight.bold, letterSpacing: 2, color: Colors.black87)), Icon(Icons.storefront, color: Color(0xFF0C2442), size: 24)]),
        ),
      ),
    );
  }

  Widget _buildProductKatalog() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: FutureBuilder<List<Product>>(
        future: _productsFuture,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) return const Center(child: Padding(padding: EdgeInsets.all(20), child: CircularProgressIndicator()));
          if (snapshot.hasError) return Center(child: Text('Gagal memuat produk: ${snapshot.error}'));
          if (!snapshot.hasData || snapshot.data!.isEmpty) return const Center(child: Padding(padding: EdgeInsets.all(20), child: Text('Tidak ada produk tersedia')));

          final products = snapshot.data!;
          return GridView.builder(
            physics: const NeverScrollableScrollPhysics(),
            shrinkWrap: true,
            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(crossAxisCount: 2, childAspectRatio: 0.72, crossAxisSpacing: 12, mainAxisSpacing: 12),
            itemCount: products.length,
            itemBuilder: (context, index) => MarketplaceProductCard(product: products[index]),
          );
        },
      ),
    );
  }
}
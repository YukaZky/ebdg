import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import '../models/product_model.dart';
import '../services/api_service.dart';
import '../services/product_cache_service.dart';
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

  static const Color _primary = Color(0xFF0C2442);
  static const Color _accent = Color(0xFFF39C12);
  static const Color _purple = Color(0xFF6C4DFF);
  static const Color _surface = Color(0xFFF7F8FC);

  @override
  void initState() {
    super.initState();
    _fetchProfile();
    _productsFuture = ProductCacheService.getProducts();
  }

  Future<void> _fetchProfile() async {
    if (ApiService.token == null) {
      widget.onProfileUpdated('Akun');
      if (mounted) setState(() => userProfile = null);
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
      if (mounted) setState(() => isLoading = false);
    }
  }

  String _maskEmail(dynamic value) {
    final email = value?.toString().trim() ?? '';
    if (email.isEmpty || !email.contains('@')) return 'Email belum diatur';
    final parts = email.split('@');
    final name = parts.first;
    final visible = name.length <= 2 ? name.substring(0, 1) : name.substring(0, 2);
    return '$visible***@${parts.last}';
  }

  String _maskPhone(dynamic value) {
    final phone = value?.toString().trim() ?? '';
    if (phone.isEmpty || phone == 'null') return 'Nomor HP belum diatur';
    if (phone.length <= 4) return '****';
    return '${phone.substring(0, 4)}****${phone.substring(phone.length - 3)}';
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
    final confirm = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('Keluar Akun', style: TextStyle(fontWeight: FontWeight.bold)),
        content: const Text('Apakah Anda yakin ingin keluar dari akun saat ini?'),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context, false), child: const Text('Batal')),
          TextButton(onPressed: () => Navigator.pop(context, true), child: const Text('Keluar', style: TextStyle(color: Colors.red, fontWeight: FontWeight.bold))),
        ],
      ),
    );
    if (confirm != true) return;

    setState(() => isLoading = true);
    final success = await ApiService.logout();
    if (!mounted) return;
    setState(() {
      isLoading = false;
      if (success) userProfile = null;
    });
    if (success) widget.onProfileUpdated('Akun');
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(success ? 'Berhasil keluar dari akun' : 'Gagal keluar, periksa koneksi Anda.')),
    );
  }

  void _guard(bool isLoggedIn, VoidCallback action) {
    if (isLoggedIn) {
      action();
      return;
    }
    ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Silakan login terlebih dahulu untuk mengakses fitur ini'), behavior: SnackBarBehavior.floating));
    Navigator.push(context, MaterialPageRoute(builder: (_) => const LoginScreen())).then((_) => _fetchProfile());
  }

  @override
  Widget build(BuildContext context) {
    final isLoggedIn = ApiService.token != null;
    return Scaffold(
      backgroundColor: _surface,
      body: RefreshIndicator(
        onRefresh: _fetchProfile,
        child: CustomScrollView(
          physics: const AlwaysScrollableScrollPhysics(parent: BouncingScrollPhysics()),
          slivers: [
            SliverToBoxAdapter(child: _header(isLoggedIn)),
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(16, 14, 16, 28),
                child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                  _orderCard(isLoggedIn),
                  const SizedBox(height: 14),
                  _sectionHeader('Layanan Akun'),
                  const SizedBox(height: 10),
                  Row(children: [
                    Expanded(child: _serviceTile('Alamat Saya', 'Kelola alamat pengiriman', Icons.location_on_rounded, () => _guard(isLoggedIn, () => Navigator.push(context, MaterialPageRoute(builder: (_) => const AddressListScreen()))))),
                    const SizedBox(width: 12),
                    Expanded(child: _serviceTile('Kupon Saya', 'Voucher dan promo', Icons.local_activity_rounded, () => _guard(isLoggedIn, () {}))),
                  ]),
                  const SizedBox(height: 14),
                  _storeCard(isLoggedIn),
                  const SizedBox(height: 20),
                  _sectionHeader('Mungkin Kamu Suka'),
                  const SizedBox(height: 12),
                  _productGrid(),
                  if (isLoggedIn) ...[
                    const SizedBox(height: 20),
                    _logoutButton(),
                  ],
                  const SizedBox(height: 16),
                ]),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _header(bool isLoggedIn) {
    final name = isLoggedIn ? (userProfile?['name'] ?? 'Pengguna') : 'Masuk ke Akun Anda';
    final email = isLoggedIn ? _maskEmail(userProfile?['email']) : 'Nikmati belanja lebih cepat dan aman';
    final phone = isLoggedIn ? _maskPhone(userProfile?['phone']) : 'Pantau pesanan, voucher, dan toko Anda';
    final avatarUrl = ProfilePhotoService.imageUrl(userProfile?['avatar']);

    return Container(
      decoration: const BoxDecoration(
        gradient: LinearGradient(colors: [_primary, Color(0xFF123A68)], begin: Alignment.topLeft, end: Alignment.bottomRight),
        borderRadius: BorderRadius.vertical(bottom: Radius.circular(30)),
      ),
      child: SafeArea(
        bottom: false,
        child: Padding(
          padding: const EdgeInsets.fromLTRB(18, 18, 18, 24),
          child: Column(children: [
            Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
              const Text('Akun Saya', style: TextStyle(color: Colors.white, fontSize: 22, fontWeight: FontWeight.w900)),
              Row(children: [
                _circleAction(Icons.settings_rounded, isLoggedIn ? _openAccountSettings : null),
                if (isLoggedIn) ...[
                  const SizedBox(width: 8),
                  _circleAction(Icons.logout_rounded, _handleLogout),
                ],
              ]),
            ]),
            const SizedBox(height: 20),
            Container(
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(color: Colors.white.withOpacity(0.12), borderRadius: BorderRadius.circular(26), border: Border.all(color: Colors.white.withOpacity(0.16))),
              child: Row(children: [
                GestureDetector(
                  onTap: isLoggedIn ? _changeProfilePhoto : null,
                  child: Stack(clipBehavior: Clip.none, children: [
                    Container(
                      width: 78,
                      height: 78,
                      clipBehavior: Clip.antiAlias,
                      decoration: BoxDecoration(color: Colors.white, shape: BoxShape.circle, border: Border.all(color: Colors.white, width: 2)),
                      child: avatarUrl.isNotEmpty ? Image.network(avatarUrl, fit: BoxFit.cover, errorBuilder: (_, __, ___) => const Icon(Icons.person_rounded, size: 48, color: _primary)) : const Icon(Icons.person_rounded, size: 48, color: _primary),
                    ),
                    if (isLoggedIn)
                      Positioned(
                        right: -2,
                        bottom: 0,
                        child: Container(
                          padding: const EdgeInsets.all(6),
                          decoration: const BoxDecoration(color: _accent, shape: BoxShape.circle),
                          child: isUploadingPhoto ? const SizedBox(width: 12, height: 12, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white)) : const Icon(Icons.camera_alt_rounded, size: 14, color: Colors.white),
                        ),
                      ),
                  ]),
                ),
                const SizedBox(width: 14),
                Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                  Text(name.toString(), maxLines: 1, overflow: TextOverflow.ellipsis, style: const TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.w900)),
                  const SizedBox(height: 5),
                  Text(email, maxLines: 1, overflow: TextOverflow.ellipsis, style: TextStyle(color: Colors.white.withOpacity(0.86), fontSize: 13)),
                  const SizedBox(height: 3),
                  Text(phone, maxLines: 1, overflow: TextOverflow.ellipsis, style: TextStyle(color: Colors.white.withOpacity(0.72), fontSize: 12)),
                  if (!isLoggedIn) ...[
                    const SizedBox(height: 12),
                    Row(children: [
                      _miniAuthButton('Login', Colors.white, _primary, () => Navigator.push(context, MaterialPageRoute(builder: (_) => const LoginScreen())).then((_) => _fetchProfile())),
                      const SizedBox(width: 8),
                      _miniAuthButton('Daftar', _accent, Colors.white, () => Navigator.push(context, MaterialPageRoute(builder: (_) => const RegisterScreen())).then((_) => _fetchProfile())),
                    ]),
                  ],
                ])),
              ]),
            ),
            if (isLoading)
              Padding(
                padding: const EdgeInsets.only(top: 12),
                child: LinearProgressIndicator(minHeight: 3, backgroundColor: Colors.white.withOpacity(0.20), color: _accent),
              ),
          ]),
        ),
      ),
    );
  }

  Widget _circleAction(IconData icon, VoidCallback? onTap) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(999),
      child: Container(width: 42, height: 42, decoration: BoxDecoration(color: Colors.white.withOpacity(0.14), shape: BoxShape.circle, border: Border.all(color: Colors.white.withOpacity(0.12))), child: Icon(icon, color: Colors.white, size: 21)),
    );
  }

  Widget _miniAuthButton(String text, Color bg, Color fg, VoidCallback onTap) {
    return SizedBox(height: 34, child: ElevatedButton(onPressed: onTap, style: ElevatedButton.styleFrom(backgroundColor: bg, foregroundColor: fg, elevation: 0, padding: const EdgeInsets.symmetric(horizontal: 16), shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12))), child: Text(text, style: const TextStyle(fontWeight: FontWeight.w900))));
  }

  Widget _orderCard(bool isLoggedIn) {
    return _card(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
        const Text('Pesanan Saya', style: TextStyle(fontSize: 17, fontWeight: FontWeight.w900, color: Colors.black87)),
        TextButton(onPressed: () => _guard(isLoggedIn, () {}), child: const Text('Lihat Semua')),
      ]),
      const SizedBox(height: 8),
      Row(children: [
        Expanded(child: _orderItem(Icons.account_balance_wallet_outlined, 'Belum Bayar', isLoggedIn)),
        Expanded(child: _orderItem(Icons.inventory_2_outlined, 'Dikemas', isLoggedIn)),
        Expanded(child: _orderItem(Icons.local_shipping_outlined, 'Dikirim', isLoggedIn)),
        Expanded(child: _orderItem(Icons.star_border_rounded, 'Dinilai', isLoggedIn)),
      ]),
    ]));
  }

  Widget _orderItem(IconData icon, String title, bool isLoggedIn) {
    return InkWell(
      borderRadius: BorderRadius.circular(16),
      onTap: () => _guard(isLoggedIn, () {}),
      child: Padding(padding: const EdgeInsets.symmetric(vertical: 8), child: Column(children: [
        Container(width: 48, height: 48, decoration: BoxDecoration(color: _purple.withOpacity(0.10), borderRadius: BorderRadius.circular(16)), child: Icon(icon, color: _primary, size: 24)),
        const SizedBox(height: 8),
        Text(title, style: TextStyle(fontSize: 11, color: Colors.grey.shade700, fontWeight: FontWeight.w700), textAlign: TextAlign.center, maxLines: 1, overflow: TextOverflow.ellipsis),
      ])),
    );
  }

  Widget _serviceTile(String title, String subtitle, IconData icon, VoidCallback onTap) {
    return _card(padding: const EdgeInsets.all(14), child: InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(18),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Container(width: 42, height: 42, decoration: BoxDecoration(color: _accent.withOpacity(0.12), borderRadius: BorderRadius.circular(14)), child: Icon(icon, color: _primary, size: 22)),
        const SizedBox(height: 12),
        Text(title, maxLines: 1, overflow: TextOverflow.ellipsis, style: const TextStyle(fontWeight: FontWeight.w900, color: Colors.black87)),
        const SizedBox(height: 3),
        Text(subtitle, maxLines: 1, overflow: TextOverflow.ellipsis, style: TextStyle(fontSize: 11, color: Colors.grey.shade600)),
      ]),
    ));
  }

  Widget _storeCard(bool isLoggedIn) {
    return InkWell(
      onTap: () => _guard(isLoggedIn, () => Navigator.push(context, MaterialPageRoute(builder: (_) => const AdminDashboardScreen()))),
      borderRadius: BorderRadius.circular(22),
      child: Container(
        padding: const EdgeInsets.all(18),
        decoration: BoxDecoration(gradient: const LinearGradient(colors: [_primary, Color(0xFF174C7E)], begin: Alignment.topLeft, end: Alignment.bottomRight), borderRadius: BorderRadius.circular(22), boxShadow: [BoxShadow(color: _primary.withOpacity(0.18), blurRadius: 18, offset: const Offset(0, 8))]),
        child: Row(children: [
          Container(width: 50, height: 50, decoration: BoxDecoration(color: Colors.white.withOpacity(0.15), borderRadius: BorderRadius.circular(16)), child: const Icon(Icons.storefront_rounded, color: Colors.white, size: 27)),
          const SizedBox(width: 14),
          Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            const Text('Toko Saya', style: TextStyle(color: Colors.white, fontSize: 17, fontWeight: FontWeight.w900)),
            const SizedBox(height: 4),
            Text('Kelola produk, pesanan, dan bisnis Anda', maxLines: 1, overflow: TextOverflow.ellipsis, style: TextStyle(color: Colors.white.withOpacity(0.75), fontSize: 12)),
          ])),
          const Icon(Icons.arrow_forward_ios_rounded, color: Colors.white, size: 17),
        ]),
      ),
    );
  }

  Widget _card({required Widget child, EdgeInsetsGeometry padding = const EdgeInsets.all(16)}) {
    return Container(padding: padding, decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(22), border: Border.all(color: Colors.grey.shade200), boxShadow: [BoxShadow(color: _primary.withOpacity(0.04), blurRadius: 16, offset: const Offset(0, 8))]), child: child);
  }

  Widget _sectionHeader(String title) {
    return Row(children: [Text(title, style: const TextStyle(fontSize: 17, fontWeight: FontWeight.w900, color: Colors.black87)), const SizedBox(width: 10), Expanded(child: Divider(color: Colors.grey.shade300))]);
  }

  Widget _logoutButton() {
    return SizedBox(width: double.infinity, child: OutlinedButton.icon(onPressed: _handleLogout, icon: const Icon(Icons.logout_rounded), label: const Text('Keluar Akun'), style: OutlinedButton.styleFrom(foregroundColor: Colors.red, side: BorderSide(color: Colors.red.shade200), padding: const EdgeInsets.symmetric(vertical: 14), shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)))));
  }

  Widget _productGrid() {
    return FutureBuilder<List<Product>>(
      future: _productsFuture,
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) return _card(child: const Center(child: Padding(padding: EdgeInsets.all(12), child: CircularProgressIndicator())));
        if (snapshot.hasError) return _card(child: Text('Produk rekomendasi belum bisa dimuat.', style: TextStyle(color: Colors.grey.shade700)));
        final products = (snapshot.data ?? <Product>[]).take(4).toList();
        if (products.isEmpty) return _card(child: Text('Belum ada produk tersedia.', style: TextStyle(color: Colors.grey.shade700)));
        return GridView.builder(
          physics: const NeverScrollableScrollPhysics(),
          shrinkWrap: true,
          gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(crossAxisCount: 2, childAspectRatio: 0.72, crossAxisSpacing: 12, mainAxisSpacing: 12),
          itemCount: products.length,
          itemBuilder: (context, index) => MarketplaceProductCard(product: products[index]),
        );
      },
    );
  }
}

import 'package:flutter/material.dart';
import '../../services/api_service.dart';
import '../marketplace/store_profile_screen.dart';
import '../marketplace/toko_pesanan_screen.dart';
import 'admin_brands_screen.dart';
import 'admin_categories_screen.dart';
import 'admin_products_screen.dart';

class AdminDashboardScreen extends StatefulWidget {
  const AdminDashboardScreen({Key? key}) : super(key: key);

  @override
  State<AdminDashboardScreen> createState() => _AdminDashboardScreenState();
}

class _AdminDashboardScreenState extends State<AdminDashboardScreen> {
  Map<String, dynamic>? dashboardStats;
  bool isLoading = true;

  @override
  void initState() {
    super.initState();
    _fetchDashboardData();
  }

  Future<void> _fetchDashboardData() async {
    try {
      final stats = await ApiService.getAdminDashboardStats();
      setState(() {
        dashboardStats = stats;
        isLoading = false;
      });
    } catch (e) {
      setState(() => isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF4F6F9),
      body: isLoading
          ? const Center(child: CircularProgressIndicator(color: Color(0xFF1E3A8A)))
          : RefreshIndicator(
              onRefresh: _fetchDashboardData,
              color: const Color(0xFF1E3A8A),
              child: SingleChildScrollView(
                physics: const AlwaysScrollableScrollPhysics(),
                child: Stack(
                  children: [
                    Positioned(
                      top: 0,
                      left: 0,
                      right: 0,
                      child: Container(
                        height: 260,
                        decoration: const BoxDecoration(
                          gradient: LinearGradient(colors: [Color(0xFF1E3A8A), Color(0xFF3B82F6)], begin: Alignment.topLeft, end: Alignment.bottomRight),
                          borderRadius: BorderRadius.only(bottomLeft: Radius.circular(32), bottomRight: Radius.circular(32)),
                        ),
                      ),
                    ),
                    SafeArea(
                      child: Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
                        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                          Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
                            const Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                              Text('Toko Saya Panel', style: TextStyle(color: Colors.white70, fontSize: 14)),
                              SizedBox(height: 4),
                              Text('Halo, Admin!', style: TextStyle(color: Colors.white, fontSize: 22, fontWeight: FontWeight.bold)),
                            ]),
                            Container(decoration: BoxDecoration(color: Colors.white.withOpacity(0.2), shape: BoxShape.circle), child: IconButton(icon: const Icon(Icons.notifications_active_rounded, color: Colors.white), onPressed: () {}))
                          ]),
                          const SizedBox(height: 32),
                          Container(
                            padding: const EdgeInsets.all(20),
                            decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(24), boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 15, offset: const Offset(0, 8))]),
                            child: Column(children: [
                              Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [const Text('Ringkasan Performa', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)), Icon(Icons.bar_chart_rounded, color: Colors.grey[400])]),
                              const Divider(height: 30),
                              Row(children: [
                                Expanded(child: _buildCompactStat('Produk', dashboardStats?['total_products']?.toString() ?? '0', Icons.inventory_2_outlined, Colors.blue)),
                                Container(width: 1, height: 40, color: Colors.grey[200]),
                                Expanded(child: _buildCompactStat('Pesanan', dashboardStats?['new_orders']?.toString() ?? '0', Icons.pending_actions_outlined, Colors.orange)),
                              ]),
                              const SizedBox(height: 20),
                              Row(children: [
                                Expanded(child: _buildCompactStat('Pesan', dashboardStats?['unread_messages']?.toString() ?? '0', Icons.mail_outline_rounded, Colors.red)),
                                Container(width: 1, height: 40, color: Colors.grey[200]),
                                Expanded(child: _buildCompactStat('Klien', dashboardStats?['total_customers']?.toString() ?? '0', Icons.people_outline_rounded, Colors.green)),
                              ]),
                            ]),
                          ),
                          const SizedBox(height: 32),
                          const Text('Manajemen Toko', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.black87)),
                          const SizedBox(height: 16),
                          Container(
                            decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(20), border: Border.all(color: Colors.grey.shade200)),
                            child: Column(children: [
                              _buildListMenu(context, 'Informasi Toko', 'Nama, deskripsi, maps, alamat, dan sosial media', Icons.store_mall_directory_outlined, Colors.deepOrange, true, () {
                                Navigator.push(context, MaterialPageRoute(builder: (_) => const StoreProfileScreen()));
                              }),
                              _buildListMenu(context, 'Kelola Produk', 'Tambah, edit, hapus barang', Icons.shopping_bag_outlined, Colors.teal, true, () {
                                Navigator.push(context, MaterialPageRoute(builder: (_) => const AdminProductsScreen()));
                              }),
                              _buildListMenu(context, 'Kelola Kategori', 'Atur pengelompokan', Icons.category_outlined, Colors.purple, true, () {
                                Navigator.push(context, MaterialPageRoute(builder: (_) => AdminCategoriesScreen()));
                              }),
                              _buildListMenu(context, 'Kelola Brand', 'Atur merek produk', Icons.branding_watermark_outlined, Colors.indigo, true, () {
                                Navigator.push(context, MaterialPageRoute(builder: (_) => AdminBrandsScreen()));
                              }),
                              _buildListMenu(context, 'Slide Banner', 'Atur banner depan', Icons.view_carousel_outlined, Colors.blueAccent, false, () {}),
                            ]),
                          ),
                          const SizedBox(height: 24),
                          const Text('Transaksi & Interaksi', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.black87)),
                          const SizedBox(height: 16),
                          Container(
                            decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(20), border: Border.all(color: Colors.grey.shade200)),
                            child: Column(children: [
                              _buildListMenu(context, 'Daftar Pesanan', 'Cek dan proses pesanan masuk', Icons.receipt_long_outlined, Colors.deepOrange, true, () {
                                Navigator.push(context, MaterialPageRoute(builder: (_) => const TokoPesananScreen()));
                              }),
                              _buildListMenu(context, 'Pesan Pelanggan', 'Balas pesan', Icons.chat_outlined, Colors.amber, true, () {}),
                              _buildListMenu(context, 'Kupon Diskon', 'Voucher promo', Icons.confirmation_num_outlined, Colors.pink, false, () {}),
                            ]),
                          ),
                          const SizedBox(height: 40),
                        ]),
                      ),
                    ),
                  ],
                ),
              ),
            ),
    );
  }

  Widget _buildCompactStat(String title, String value, IconData icon, Color color) {
    return Column(children: [Icon(icon, color: color, size: 28), const SizedBox(height: 8), Text(value, style: const TextStyle(fontSize: 22, fontWeight: FontWeight.bold, color: Colors.black87)), const SizedBox(height: 2), Text(title, style: TextStyle(fontSize: 12, color: Colors.grey[600], fontWeight: FontWeight.w500))]);
  }

  Widget _buildListMenu(BuildContext context, String title, String subtitle, IconData icon, Color color, bool showDivider, VoidCallback onTap) {
    return Column(children: [
      ListTile(
        contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
        leading: Container(padding: const EdgeInsets.all(10), decoration: BoxDecoration(color: color.withOpacity(0.1), borderRadius: BorderRadius.circular(12)), child: Icon(icon, color: color, size: 24)),
        title: Text(title, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15)),
        subtitle: Text(subtitle, style: TextStyle(fontSize: 12, color: Colors.grey[500])),
        trailing: const Icon(Icons.arrow_forward_ios_rounded, size: 16, color: Colors.grey),
        onTap: onTap,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      ),
      if (showDivider) Padding(padding: const EdgeInsets.only(left: 70, right: 20), child: Divider(height: 1, color: Colors.grey[100])),
    ]);
  }
}

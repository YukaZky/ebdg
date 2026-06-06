import 'package:flutter/material.dart';
import '../../services/api_service.dart';
import 'admin_products_screen.dart'; // File screen manajemen produk

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
    final stats = await ApiService.getAdminDashboardStats();
    setState(() {
      dashboardStats = stats;
      isLoading = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Toko Saya - Admin Panel"),
        backgroundColor: Colors.indigo,
        foregroundColor: Colors.white,
      ),
      body: isLoading
          ? const Center(child: CircularProgressIndicator())
          : Padding(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text("Ringkasan Performa Toko", style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                  const SizedBox(height: 12),
                  
                  // Row Utama Statistik Ringkas
                  SingleChildScrollView(
                    scrollDirection: Axis.horizontal,
                    child: Row(
                      children: [
                        _buildStatCard("Total Produk", dashboardStats?['total_products']?.toString() ?? "0", Icons.inventory, Colors.blue),
                        _buildStatCard("Pesanan Baru", dashboardStats?['new_orders']?.toString() ?? "0", Icons.pending_actions, Colors.orange),
                        _buildStatCard("Pesan Masuk", dashboardStats?['unread_messages']?.toString() ?? "0", Icons.message, Colors.red),
                      ],
                    ),
                  ),
                  const SizedBox(height: 24),
                  
                  const Text("Semua Fitur Kendali Toko", style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                  const SizedBox(height: 12),
                  
                  // Grid Menu Komplit sesuai fitur Web Panel
                  Expanded(
                    child: GridView.count(
                      crossAxisCount: 2,
                      crossAxisSpacing: 12,
                      mainAxisSpacing: 12,
                      children: [
                        _buildMenuCard(context, "Kelola Produk", Icons.shopping_bag, Colors.teal, () {
                          Navigator.push(context, MaterialPageRoute(builder: (context) => const AdminProductsScreen()));
                        }),
                        _buildMenuCard(context, "Kelola Pesanan", Icons.receipt_long, Colors.deepOrange, () {
                          // Implementasi Screen Pesanan Masuk
                        }),
                        _buildMenuCard(context, "Kategori & Brand", Icons.category, Colors.purple, () {}),
                        _buildMenuCard(context, "Kupon Diskon", Icons.card_giftcard, Colors.pink, () {}),
                        _buildMenuCard(context, "Slide Banner", Icons.view_carousel, Colors.blueAccent, () {}),
                        _buildMenuCard(context, "Pesan Pelanggan", Icons.quickreply, Colors.amber, () {}),
                      ],
                    ),
                  )
                ],
              ),
            ),
    );
  }

  Widget _buildStatCard(String title, String value, IconData icon, Color color) {
    return Container(
      width: 140,
      margin: const EdgeInsets.only(right: 12),
      child: Card(
        elevation: 2,
        color: color.withOpacity(0.08),
        child: Padding(
          padding: const EdgeInsets.all(12.0),
          child: Column(
            children: [
              Icon(icon, size: 28, color: color),
              const SizedBox(height: 6),
              Text(value, style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: color)),
              const SizedBox(height: 2),
              Text(title, textAlign: TextAlign.center, style: const TextStyle(fontSize: 12, color: Colors.grey)),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildMenuCard(BuildContext context, String title, IconData icon, Color color, VoidCallback onTap) {
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            CircleAvatar(radius: 26, backgroundColor: color.withOpacity(0.15), child: Icon(icon, size: 26, color: color)),
            const SizedBox(height: 12),
            Text(title, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
          ],
        ),
      ),
    );
  }
}
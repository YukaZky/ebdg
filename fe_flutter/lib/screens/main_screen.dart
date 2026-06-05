import 'package:flutter/material.dart';
import 'product_list_screen.dart';
import 'cart_screen.dart';
import 'order_history_screen.dart';
import 'profile_screen.dart'; // Import halaman profil yang dinamis

class MainScreen extends StatefulWidget {
  const MainScreen({Key? key}) : super(key: key);

  @override
  State<MainScreen> createState() => _MainScreenState();
}

class _MainScreenState extends State<MainScreen> {
  int _selectedIndex = 0;

  // Daftar halaman yang akan dipanggil oleh Bottom Navigation Bar
  final List<Widget> _screens = [
    const ProductListScreen(),
    const CartScreen(),
    const OrderHistoryScreen(),
    const ProfileScreen(), // Halaman Akun ditempatkan di indeks ke-3
  ];

  void _onItemTapped(int index) {
    setState(() {
      _selectedIndex = index;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: _screens[_selectedIndex],
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: _selectedIndex,
        onTap: _onItemTapped,
        // --- MENGUBAH WARNA TOMBOL DI SINI ---
        selectedItemColor: const Color(0xFFF7B602), // Warna saat di-klik (Kuning/Oranye)
        unselectedItemColor: const Color(0xFF05254F), // Warna saat belum di-klik (Biru Gelap)
        backgroundColor: Colors.white, // Background bar (bisa diubah jika perlu)
        type: BottomNavigationBarType.fixed, // Memastikan ke-4 tombol muat dengan proporsional
        items: const [
          BottomNavigationBarItem(
            icon: Icon(Icons.home),
            label: 'Beranda',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.shopping_cart),
            label: 'Keranjang',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.history),
            label: 'Pesanan',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.person),
            label: 'Akun',
          ),
        ],
      ),
    );
  }
}
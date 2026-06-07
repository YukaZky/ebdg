import 'package:flutter/material.dart';
import 'product_list_screen.dart';
import 'cart_screen.dart';
import 'order_history_screen.dart';
import 'profile_screen.dart'; 

class MainScreen extends StatefulWidget {
  final int initialIndex; // 1. Tambahkan parameter indeks awal
  const MainScreen({Key? key, this.initialIndex = 0}) : super(key: key); // 2. Set default ke 0 (Beranda)

  @override
  State<MainScreen> createState() => _MainScreenState();
}

class _MainScreenState extends State<MainScreen> {
  late int _selectedIndex; // 3. Ubah menjadi late variable

  // Daftar halaman yang akan dipanggil oleh Bottom Navigation Bar
  final List<Widget> _screens = [
    const ProductListScreen(),
    const CartScreen(),
    const OrderHistoryScreen(),
    const ProfileScreen(), // Indeks ke-3
  ];

  @override
  void initState() {
    super.initState();
    _selectedIndex = widget.initialIndex; // 4. Inisialisasi sesuai indeks yang dikirim
  }

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
        selectedItemColor: const Color(0xFFF7B602), 
        unselectedItemColor: const Color(0xFF05254F), 
        backgroundColor: Colors.white, 
        type: BottomNavigationBarType.fixed, 
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
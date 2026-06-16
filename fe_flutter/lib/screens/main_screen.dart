import 'package:flutter/material.dart';
import 'product_list_screen.dart';
import 'cart_screen.dart';
import 'order_history_screen.dart';
import 'profile_screen.dart'; 

class MainScreen extends StatefulWidget {
  final int initialIndex; 
  const MainScreen({Key? key, this.initialIndex = 0}) : super(key: key); 

  @override
  State<MainScreen> createState() => _MainScreenState();
}

class _MainScreenState extends State<MainScreen> {
  late int _selectedIndex; 
  String _accountLabel = 'Akun';
  late List<Widget> _screens;

  @override
  void initState() {
    super.initState();
    _selectedIndex = widget.initialIndex; 
    _initScreens();
  }

  void _initScreens() {
    _screens = [
      const ProductListScreen(),
      const CartScreen(),
      const OrderHistoryScreen(),
      ProfileScreen(
        onProfileUpdated: (String? name) {
          if (mounted) {
            setState(() {
              _accountLabel = name ?? 'Akun';
            });
          }
        },
      ), 
    ];
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
        items: [
          const BottomNavigationBarItem(
            icon: Icon(Icons.home),
            label: 'Beranda',
          ),
          const BottomNavigationBarItem(
            icon: Icon(Icons.shopping_cart),
            label: 'Keranjang',
          ),
          const BottomNavigationBarItem(
            icon: Icon(Icons.history),
            label: 'Pesanan',
          ),
          BottomNavigationBarItem(
            icon: const Icon(Icons.person),
            label: _accountLabel, 
          ),
        ],
      ),
    );
  }
}
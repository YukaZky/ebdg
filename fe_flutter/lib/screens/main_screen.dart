import 'package:flutter/material.dart';
import '../services/cart_badge_service.dart';
import 'cart_screen.dart';
import 'order_history_screen.dart';
import 'product_list_screen.dart';
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
    CartBadgeService.refresh();
  }

  void _initScreens() {
    _screens = [
      const ProductListScreen(),
      const CartScreen(),
      const OrderHistoryScreen(),
      ProfileScreen(
        onProfileUpdated: (String? name) {
          if (mounted) {
            setState(() => _accountLabel = name ?? 'Akun');
            CartBadgeService.refresh();
          }
        },
      ),
    ];
  }

  void _onItemTapped(int index) {
    setState(() => _selectedIndex = index);
    if (index == 1) {
      CartBadgeService.refresh();
    }
  }

  Widget _cartIconWithBadge() {
    return ValueListenableBuilder<int>(
      valueListenable: CartBadgeService.count,
      builder: (context, count, child) {
        return Stack(
          clipBehavior: Clip.none,
          children: [
            const Icon(Icons.shopping_cart),
            if (count > 0)
              Positioned(
                right: -8,
                top: -8,
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 2),
                  decoration: BoxDecoration(
                    color: Colors.red,
                    borderRadius: BorderRadius.circular(999),
                    border: Border.all(color: Colors.white, width: 1.5),
                  ),
                  constraints: const BoxConstraints(minWidth: 18, minHeight: 18),
                  child: Text(
                    count > 99 ? '99+' : count.toString(),
                    textAlign: TextAlign.center,
                    style: const TextStyle(color: Colors.white, fontSize: 10, fontWeight: FontWeight.bold, height: 1),
                  ),
                ),
              ),
          ],
        );
      },
    );
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
          BottomNavigationBarItem(
            icon: _cartIconWithBadge(),
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

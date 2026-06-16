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
    if (index == 1) CartBadgeService.refresh();
  }

  Widget _cartIconWithBadge({required bool active}) {
    return ValueListenableBuilder<int>(
      valueListenable: CartBadgeService.count,
      builder: (context, count, child) {
        return Stack(
          clipBehavior: Clip.none,
          children: [
            Icon(Icons.shopping_cart, size: 24, color: active ? const Color(0xFFF7B602) : const Color(0xFF05254F)),
            if (count > 0)
              Positioned(
                right: -9,
                top: -9,
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

  Widget _navIcon(int index, IconData icon) {
    final active = _selectedIndex == index;
    return Icon(icon, size: 24, color: active ? const Color(0xFFF7B602) : const Color(0xFF05254F));
  }

  Widget _navItem({required int index, required String label, required Widget icon}) {
    final active = _selectedIndex == index;

    return Expanded(
      child: GestureDetector(
        behavior: HitTestBehavior.opaque,
        onTap: () => _onItemTapped(index),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 220),
          curve: Curves.easeOut,
          transform: Matrix4.translationValues(0, active ? -10 : 0, 0),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              AnimatedContainer(
                duration: const Duration(milliseconds: 220),
                width: active ? 38 : 0,
                height: 3,
                margin: const EdgeInsets.only(bottom: 7),
                decoration: BoxDecoration(color: const Color(0xFFF7B602), borderRadius: BorderRadius.circular(99)),
              ),
              AnimatedContainer(
                duration: const Duration(milliseconds: 220),
                padding: EdgeInsets.symmetric(horizontal: active ? 13 : 0, vertical: active ? 7 : 0),
                decoration: BoxDecoration(
                  color: active ? const Color(0xFFFFF7D6) : Colors.transparent,
                  borderRadius: BorderRadius.circular(16),
                  boxShadow: active ? [BoxShadow(color: Colors.black.withOpacity(0.08), blurRadius: 12, offset: const Offset(0, 4))] : [],
                ),
                child: icon,
              ),
              const SizedBox(height: 4),
              Text(
                label,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(
                  fontSize: 12,
                  color: active ? const Color(0xFFF7B602) : const Color(0xFF05254F),
                  fontWeight: active ? FontWeight.w700 : FontWeight.w500,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _bottomNav() {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        border: Border(top: BorderSide(color: Colors.grey.shade200)),
        boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 14, offset: const Offset(0, -5))],
      ),
      child: SafeArea(
        top: false,
        child: SizedBox(
          height: 72,
          child: Row(
            children: [
              _navItem(index: 0, label: 'Beranda', icon: _navIcon(0, Icons.home)),
              _navItem(index: 1, label: 'Keranjang', icon: _cartIconWithBadge(active: _selectedIndex == 1)),
              _navItem(index: 2, label: 'Pesanan', icon: _navIcon(2, Icons.history)),
              _navItem(index: 3, label: _accountLabel, icon: _navIcon(3, Icons.person)),
            ],
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: _screens[_selectedIndex],
      bottomNavigationBar: _bottomNav(),
    );
  }
}

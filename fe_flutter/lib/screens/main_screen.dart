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

  static const Color _activeColor = Color(0xFF6C4DFF);
  static const Color _inactiveColor = Color(0xFF9CA3AF);
  static const Color _navDark = Color(0xFF05254F);

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

  Widget _cartIconWithBadge({required bool active, required Color color}) {
    return ValueListenableBuilder<int>(
      valueListenable: CartBadgeService.count,
      builder: (context, count, child) {
        return Stack(
          clipBehavior: Clip.none,
          children: [
            Icon(Icons.shopping_cart, size: active ? 27 : 24, color: color),
            if (count > 0)
              Positioned(
                right: active ? -11 : -9,
                top: active ? -10 : -9,
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

  Widget _navIcon(int index, IconData icon, {required bool active, required Color color}) {
    return Icon(icon, size: active ? 27 : 24, color: color);
  }

  Widget _navItem({required int index, required String label, required Widget Function(bool active, Color color) iconBuilder}) {
    final active = _selectedIndex == index;
    final color = active ? _activeColor : _inactiveColor;

    return Expanded(
      child: GestureDetector(
        behavior: HitTestBehavior.opaque,
        onTap: () => _onItemTapped(index),
        child: SizedBox(
          height: 82,
          child: Stack(
            clipBehavior: Clip.none,
            alignment: Alignment.topCenter,
            children: [
              Positioned(
                top: active ? -20 : 13,
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 240),
                  curve: Curves.easeOut,
                  width: active ? 58 : 42,
                  height: active ? 58 : 42,
                  decoration: BoxDecoration(
                    color: active ? _activeColor : Colors.transparent,
                    shape: BoxShape.circle,
                    boxShadow: active ? [BoxShadow(color: _activeColor.withOpacity(0.35), blurRadius: 16, offset: const Offset(0, 8))] : [],
                  ),
                  child: Center(child: iconBuilder(active, active ? Colors.white : _inactiveColor)),
                ),
              ),
              Positioned(
                top: active ? 43 : 50,
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 240),
                  width: active ? 24 : 0,
                  height: 3,
                  decoration: BoxDecoration(color: _activeColor, borderRadius: BorderRadius.circular(999)),
                ),
              ),
              Positioned(
                bottom: 6,
                left: 2,
                right: 2,
                child: Text(
                  label,
                  textAlign: TextAlign.center,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(fontSize: 11.5, color: active ? _activeColor : _inactiveColor, fontWeight: active ? FontWeight.w700 : FontWeight.w500),
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
        border: Border(top: BorderSide(color: Colors.grey.shade100)),
        boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.06), blurRadius: 18, offset: const Offset(0, -6))],
      ),
      child: SafeArea(
        top: false,
        child: SizedBox(
          height: 82,
          child: Row(
            children: [
              _navItem(index: 0, label: 'Beranda', iconBuilder: (active, color) => _navIcon(0, Icons.home, active: active, color: active ? color : _navDark)),
              _navItem(index: 1, label: 'Keranjang', iconBuilder: (active, color) => _cartIconWithBadge(active: active, color: active ? color : _navDark)),
              _navItem(index: 2, label: 'Pesanan', iconBuilder: (active, color) => _navIcon(2, Icons.history, active: active, color: active ? color : _navDark)),
              _navItem(index: 3, label: _accountLabel, iconBuilder: (active, color) => _navIcon(3, Icons.person, active: active, color: active ? color : _navDark)),
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

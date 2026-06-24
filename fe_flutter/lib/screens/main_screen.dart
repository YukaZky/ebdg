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
  late final List<Widget Function()> _screenBuilders;
  late final List<bool> _builtTabs;
  final PageStorageBucket _pageStorageBucket = PageStorageBucket();
  DateTime? _lastNavTapAt;

  static const Color _activeColor = Color(0xFF6C4DFF);
  static const Color _inactiveColor = Color(0xFF9CA3AF);
  static const Color _navDark = Color(0xFF05254F);
  static const Duration _navTapDebounce = Duration(milliseconds: 260);

  @override
  void initState() {
    super.initState();
    _selectedIndex = widget.initialIndex.clamp(0, 3).toInt();
    _screenBuilders = [
      () => const ProductListScreen(key: PageStorageKey('tab-home-products')),
      () => const CartScreen(key: PageStorageKey('tab-cart')),
      () => const OrderHistoryScreen(key: PageStorageKey('tab-orders')),
      () => ProfileScreen(
            key: const PageStorageKey('tab-profile'),
            onProfileUpdated: (String? name) {
              if (!mounted) return;
              setState(() => _accountLabel = name ?? 'Akun');
              CartBadgeService.refresh();
            },
          ),
    ];
    _builtTabs = List<bool>.filled(_screenBuilders.length, false);
    _builtTabs[_selectedIndex] = true;
    CartBadgeService.refresh();
  }

  bool _allowNavigationTap(int index) {
    if (index == _selectedIndex) return false;

    final now = DateTime.now();
    final previous = _lastNavTapAt;
    if (previous != null && now.difference(previous) < _navTapDebounce) {
      return false;
    }

    _lastNavTapAt = now;
    return true;
  }

  void _onItemTapped(int index) {
    if (!_allowNavigationTap(index)) return;

    FocusManager.instance.primaryFocus?.unfocus();
    setState(() {
      _selectedIndex = index;
      _builtTabs[index] = true;
    });
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
                    style: const TextStyle(
                        color: Colors.white,
                        fontSize: 10,
                        fontWeight: FontWeight.bold,
                        height: 1),
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

  Widget _navItem({
    required int index,
    required String label,
    required Widget Function(bool active, Color color) iconBuilder,
  }) {
    final active = _selectedIndex == index;

    return Expanded(
      child: GestureDetector(
        behavior: HitTestBehavior.opaque,
        onTap: () => _onItemTapped(index),
        child: Container(
          color: Colors.transparent, // Memastikan area sentuh penuh
          height: 82,
          child: TweenAnimationBuilder<double>(
            tween: Tween<double>(begin: 0.0, end: active ? 1.0 : 0.0),
            duration: const Duration(milliseconds: 350),
            curve: Curves.easeOutBack, // Memberikan efek memantul (bouncing)
            builder: (context, value, child) {
              return Stack(
                alignment: Alignment.center,
                clipBehavior: Clip.none,
                children: [
                  // Latar Belakang (Pill shape ala Material 3)
                  Positioned(
                    top: 14 + (4 * (1 - value)), // Bergeser sedikit saat muncul
                    child: Opacity(
                      opacity: value.clamp(0.0, 1.0),
                      child: Container(
                        width: 40 + (24 * value), // Memanjang ke samping
                        height: 32,
                        decoration: BoxDecoration(
                          color: _activeColor.withOpacity(0.15),
                          borderRadius: BorderRadius.circular(16),
                        ),
                      ),
                    ),
                  ),
                  // Ikon
                  Positioned(
                    top: 18 - (4 * value), // Naik sedikit saat aktif
                    child: iconBuilder(
                      active,
                      active ? _activeColor : _navDark.withOpacity(0.6),
                    ),
                  ),
                  // Teks Label
                  Positioned(
                    bottom: 12,
                    child: Opacity(
                      opacity: 0.6 + (0.4 * value), // Transisi opacity
                      child: Transform.scale(
                        scale: 0.9 + (0.1 * value), // Membesar sedikit
                        child: Text(
                          label,
                          style: TextStyle(
                            fontSize: 11.5,
                            color: active ? _activeColor : _inactiveColor,
                            fontWeight: active ? FontWeight.bold : FontWeight.w500,
                          ),
                        ),
                      ),
                    ),
                  ),
                ],
              );
            },
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
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.04),
            blurRadius: 20,
            offset: const Offset(0, -4),
          )
        ],
      ),
      child: SafeArea(
        top: false,
        child: SizedBox(
          height: 82,
          child: Row(
            children: [
              _navItem(
                index: 0,
                label: 'Beranda',
                iconBuilder: (active, color) => _navIcon(0, Icons.home, active: active, color: color),
              ),
              _navItem(
                index: 1,
                label: 'Keranjang',
                iconBuilder: (active, color) => _cartIconWithBadge(active: active, color: color),
              ),
              _navItem(
                index: 2,
                label: 'Pesanan',
                iconBuilder: (active, color) => _navIcon(2, Icons.history, active: active, color: color),
              ),
              _navItem(
                index: 3,
                label: _accountLabel,
                iconBuilder: (active, color) => _navIcon(3, Icons.person, active: active, color: color),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _persistentBody() {
    return PageStorage(
      bucket: _pageStorageBucket,
      child: IndexedStack(
        index: _selectedIndex,
        children: List.generate(_screenBuilders.length, (index) {
          if (!_builtTabs[index]) return const SizedBox.shrink();
          return TickerMode(
            enabled: _selectedIndex == index,
            child: RepaintBoundary(child: _screenBuilders[index]()),
          );
        }),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: _persistentBody(),
      bottomNavigationBar: _bottomNav(),
    );
  }
}
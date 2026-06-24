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
  static const Color _inactiveColor = Color(0xFF8A94A6);
  static const Color _navTextColor = Color(0xFF0C2442);
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
              setState(() => _accountLabel = _shortAccountLabel(name));
              CartBadgeService.refresh();
            },
          ),
    ];
    _builtTabs = List<bool>.filled(_screenBuilders.length, false);
    _builtTabs[_selectedIndex] = true;
    CartBadgeService.refresh();
  }

  String _shortAccountLabel(String? value) {
    final text = value?.trim() ?? '';
    if (text.isEmpty || text == 'Akun') return 'Akun';
    return text.length > 8 ? '${text.substring(0, 8)}…' : text;
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
            Icon(Icons.shopping_cart_rounded, size: active ? 24 : 23, color: color),
            if (count > 0)
              Positioned(
                right: -10,
                top: -10,
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 2),
                  decoration: BoxDecoration(
                    color: const Color(0xFFFF3B30),
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

  Widget _navIcon(IconData icon, {required bool active, required Color color}) {
    return Icon(icon, size: active ? 24 : 23, color: color);
  }

  Widget _navItem({
    required int index,
    required String label,
    required Widget Function(bool active, Color color) iconBuilder,
  }) {
    final active = _selectedIndex == index;
    final iconColor = active ? _activeColor : _inactiveColor;

    return Expanded(
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(20),
          onTap: () => _onItemTapped(index),
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 220),
            curve: Curves.easeOutCubic,
            height: 58,
            margin: const EdgeInsets.symmetric(horizontal: 3, vertical: 6),
            padding: const EdgeInsets.symmetric(horizontal: 4),
            decoration: BoxDecoration(
              color: active ? _activeColor.withOpacity(0.12) : Colors.transparent,
              borderRadius: BorderRadius.circular(18),
            ),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                AnimatedScale(
                  scale: active ? 1.04 : 1,
                  duration: const Duration(milliseconds: 180),
                  child: iconBuilder(active, iconColor),
                ),
                const SizedBox(height: 4),
                Text(
                  label,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    fontSize: 11,
                    color: active ? _activeColor : _inactiveColor,
                    fontWeight: active ? FontWeight.w800 : FontWeight.w600,
                    height: 1,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _bottomNav() {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        border: Border(top: BorderSide(color: Colors.grey.shade200, width: 0.8)),
        boxShadow: [
          BoxShadow(
            color: _navTextColor.withOpacity(0.08),
            blurRadius: 18,
            offset: const Offset(0, -6),
          ),
        ],
      ),
      child: SafeArea(
        top: false,
        child: Padding(
          padding: const EdgeInsets.fromLTRB(10, 4, 10, 6),
          child: Row(
            children: [
              _navItem(
                index: 0,
                label: 'Beranda',
                iconBuilder: (active, color) => _navIcon(Icons.home_rounded, active: active, color: color),
              ),
              _navItem(
                index: 1,
                label: 'Keranjang',
                iconBuilder: (active, color) => _cartIconWithBadge(active: active, color: color),
              ),
              _navItem(
                index: 2,
                label: 'Pesanan',
                iconBuilder: (active, color) => _navIcon(Icons.receipt_long_rounded, active: active, color: color),
              ),
              _navItem(
                index: 3,
                label: _accountLabel,
                iconBuilder: (active, color) => _navIcon(Icons.person_rounded, active: active, color: color),
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

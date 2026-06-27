import 'package:flutter/material.dart';
import '../../services/marketplace_api_service.dart';
import 'add_cuppon_screen.dart';

class ListKuponScreen extends StatefulWidget {
  const ListKuponScreen({Key? key}) : super(key: key);

  @override
  State<ListKuponScreen> createState() => _ListKuponScreenState();
}

class _ListKuponScreenState extends State<ListKuponScreen> {
  late Future<List<dynamic>> _future;

  static const Color _primary = Color(0xFF0C2442);
  static const Color _accent = Color(0xFFF39C12);
  static const Color _purple = Color(0xFF6C4DFF);
  static const Color _surface = Color(0xFFF7F8FC);

  @override
  void initState() {
    super.initState();
    _future = MarketplaceApiService.sellerCoupons();
  }

  Future<void> _refresh() async {
    setState(() => _future = MarketplaceApiService.sellerCoupons());
    await _future;
  }

  String _money(dynamic value) {
    final number = double.tryParse(value?.toString() ?? '0') ?? 0;
    return 'Rp ${number.toStringAsFixed(0)}';
  }

  String _discountLabel(Map<String, dynamic> coupon) {
    final type = coupon['type']?.toString() ?? 'fixed';
    final value = double.tryParse(coupon['value']?.toString() ?? '0') ?? 0;
    if (type == 'discount') return '${value.toStringAsFixed(value % 1 == 0 ? 0 : 1)}%';
    return _money(value);
  }

  String _limitLabel(Map<String, dynamic> coupon) {
    final raw = coupon['remaining_limit'] ?? coupon['usage_limit'];
    if (raw == null || raw.toString().trim().isEmpty || raw.toString() == 'null') return 'Tidak dibatasi';
    final value = int.tryParse(raw.toString());
    if (value == null) return raw.toString();
    return value <= 0 ? 'Habis' : '$value tersisa';
  }

  Future<void> _openAdd({Map<String, dynamic>? coupon}) async {
    final result = await Navigator.push(context, MaterialPageRoute(builder: (_) => AddCupponScreen(coupon: coupon)));
    if (result == true) _refresh();
  }

  Future<void> _openDetail(Map<String, dynamic> coupon) async {
    await Navigator.push(context, MaterialPageRoute(builder: (_) => CouponDetailScreen(coupon: coupon)));
    _refresh();
  }

  Future<void> _delete(Map<String, dynamic> coupon) async {
    final id = int.tryParse(coupon['id']?.toString() ?? '');
    if (id == null) return;
    final ok = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
        title: const Text('Hapus kupon?', style: TextStyle(fontWeight: FontWeight.w900)),
        content: Text('Kupon ${coupon['name'] ?? coupon['code'] ?? ''} akan dihapus dari toko kamu.'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context, false), child: const Text('Batal')),
          TextButton(onPressed: () => Navigator.pop(context, true), child: const Text('Hapus', style: TextStyle(color: Colors.red, fontWeight: FontWeight.w900))),
        ],
      ),
    );
    if (ok != true) return;
    final deleted = await MarketplaceApiService.deleteCoupon(id);
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(deleted ? 'Kupon berhasil dihapus.' : 'Gagal menghapus kupon.')));
    if (deleted) _refresh();
  }

  Widget _couponCard(Map<String, dynamic> coupon) {
    final active = coupon['status']?.toString() == 'active' || coupon['status'] == 1;
    final typeText = coupon['type']?.toString() == 'discount' ? 'Discount' : 'Fixed';
    return _card(
      padding: EdgeInsets.zero,
      child: InkWell(
        onTap: () => _openDetail(coupon),
        borderRadius: BorderRadius.circular(22),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Row(children: [
              Container(width: 50, height: 50, decoration: BoxDecoration(color: _purple.withOpacity(0.10), borderRadius: BorderRadius.circular(16)), child: const Icon(Icons.confirmation_number_rounded, color: _primary, size: 26)),
              const SizedBox(width: 12),
              Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                Text(coupon['name']?.toString() ?? 'Kupon', maxLines: 1, overflow: TextOverflow.ellipsis, style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w900, color: Colors.black87)),
                const SizedBox(height: 4),
                Text(coupon['code']?.toString() ?? '-', style: const TextStyle(fontSize: 12, color: _accent, fontWeight: FontWeight.w900, letterSpacing: .4)),
              ])),
              PopupMenuButton<String>(
                color: Colors.white,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                onSelected: (value) {
                  if (value == 'detail') _openDetail(coupon);
                  if (value == 'edit') _openAdd(coupon: coupon);
                  if (value == 'delete') _delete(coupon);
                },
                itemBuilder: (_) => const [
                  PopupMenuItem(value: 'detail', child: Text('Detail')),
                  PopupMenuItem(value: 'edit', child: Text('Edit')),
                  PopupMenuItem(value: 'delete', child: Text('Hapus')),
                ],
              ),
            ]),
            const SizedBox(height: 14),
            Container(
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(color: _surface, borderRadius: BorderRadius.circular(18)),
              child: Row(children: [
                Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                  const Text('Nilai Kupon', style: TextStyle(fontSize: 11, color: Color(0xFF64748B), fontWeight: FontWeight.w700)),
                  const SizedBox(height: 4),
                  Text(_discountLabel(coupon), style: const TextStyle(fontSize: 22, fontWeight: FontWeight.w900, color: _primary)),
                ])),
                Column(crossAxisAlignment: CrossAxisAlignment.end, children: [
                  _badge(typeText, _primary),
                  const SizedBox(height: 6),
                  _badge(active ? 'Aktif' : 'Nonaktif', active ? Colors.green : Colors.grey),
                ]),
              ]),
            ),
            const SizedBox(height: 10),
            Text('Min. belanja ${_money(coupon['min_purchase'])} • Sisa limit ${_limitLabel(coupon)} • Diambil ${coupon['taken_count'] ?? 0}x', style: const TextStyle(fontSize: 12, color: Color(0xFF64748B), fontWeight: FontWeight.w700)),
          ]),
        ),
      ),
    );
  }

  Widget _badge(String text, Color color) => Container(
        padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 5),
        decoration: BoxDecoration(color: color.withOpacity(.10), borderRadius: BorderRadius.circular(99)),
        child: Text(text, style: TextStyle(color: color, fontSize: 11, fontWeight: FontWeight.w900)),
      );

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: _surface,
      body: RefreshIndicator(
        onRefresh: _refresh,
        color: _accent,
        child: FutureBuilder<List<dynamic>>(
          future: _future,
          builder: (context, snapshot) {
            final data = (snapshot.data ?? []).whereType<Map>().map((e) => Map<String, dynamic>.from(e)).toList();
            return CustomScrollView(
              physics: const AlwaysScrollableScrollPhysics(parent: BouncingScrollPhysics()),
              slivers: [
                SliverToBoxAdapter(child: _header(data.length, snapshot.connectionState == ConnectionState.waiting)),
                if (snapshot.connectionState == ConnectionState.waiting)
                  const SliverFillRemaining(child: Center(child: CircularProgressIndicator(color: _accent)))
                else if (data.isEmpty)
                  SliverFillRemaining(hasScrollBody: false, child: _emptyState())
                else
                  SliverPadding(
                    padding: const EdgeInsets.fromLTRB(16, 14, 16, 96),
                    sliver: SliverList(delegate: SliverChildBuilderDelegate((context, index) => Padding(padding: const EdgeInsets.only(bottom: 12), child: _couponCard(data[index])), childCount: data.length)),
                  ),
              ],
            );
          },
        ),
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => _openAdd(),
        backgroundColor: _primary,
        foregroundColor: Colors.white,
        elevation: 0,
        icon: const Icon(Icons.add_rounded),
        label: const Text('Tambah'),
      ),
    );
  }

  Widget _header(int count, bool isLoading) {
    return Container(
      decoration: const BoxDecoration(
        gradient: LinearGradient(colors: [_primary, Color(0xFF123A68)], begin: Alignment.topLeft, end: Alignment.bottomRight),
        borderRadius: BorderRadius.vertical(bottom: Radius.circular(30)),
      ),
      child: SafeArea(
        bottom: false,
        child: Padding(
          padding: const EdgeInsets.fromLTRB(18, 18, 18, 24),
          child: Column(children: [
            Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
              _circleAction(Icons.arrow_back_rounded, () => Navigator.pop(context)),
              const Text('List Kupon', style: TextStyle(color: Colors.white, fontSize: 20, fontWeight: FontWeight.w900)),
              _circleAction(Icons.add_rounded, () => _openAdd()),
            ]),
            const SizedBox(height: 20),
            Container(
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(color: Colors.white.withOpacity(0.12), borderRadius: BorderRadius.circular(26), border: Border.all(color: Colors.white.withOpacity(0.16))),
              child: Row(children: [
                Container(width: 64, height: 64, decoration: const BoxDecoration(color: Colors.white, shape: BoxShape.circle), child: const Icon(Icons.local_activity_rounded, color: _primary, size: 34)),
                const SizedBox(width: 14),
                Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                  const Text('Kupon Diskon Toko', style: TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.w900)),
                  const SizedBox(height: 5),
                  Text('$count kupon tersedia untuk dikelola', style: TextStyle(color: Colors.white.withOpacity(0.78), fontSize: 12)),
                  const SizedBox(height: 3),
                  Text('Tarik halaman ke bawah untuk refresh data.', style: TextStyle(color: Colors.white.withOpacity(0.70), fontSize: 11)),
                ])),
              ]),
            ),
            if (isLoading)
              Padding(padding: const EdgeInsets.only(top: 12), child: LinearProgressIndicator(minHeight: 3, backgroundColor: Colors.white.withOpacity(0.20), color: _accent)),
          ]),
        ),
      ),
    );
  }

  Widget _circleAction(IconData icon, VoidCallback? onTap) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(999),
      child: Container(width: 42, height: 42, decoration: BoxDecoration(color: Colors.white.withOpacity(0.14), shape: BoxShape.circle, border: Border.all(color: Colors.white.withOpacity(0.12))), child: Icon(icon, color: Colors.white, size: 21)),
    );
  }

  Widget _card({required Widget child, EdgeInsetsGeometry padding = const EdgeInsets.all(16)}) {
    return Container(padding: padding, decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(22), border: Border.all(color: Colors.grey.shade200), boxShadow: [BoxShadow(color: _primary.withOpacity(0.04), blurRadius: 16, offset: const Offset(0, 8))]), child: child);
  }

  Widget _emptyState() {
    return Padding(
      padding: const EdgeInsets.all(24),
      child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
        Container(width: 84, height: 84, decoration: BoxDecoration(color: _accent.withOpacity(.12), shape: BoxShape.circle), child: const Icon(Icons.confirmation_number_outlined, size: 44, color: _primary)),
        const SizedBox(height: 16),
        const Text('Belum ada kupon toko.', style: TextStyle(fontSize: 17, fontWeight: FontWeight.w900, color: Colors.black87)),
        const SizedBox(height: 6),
        Text('Tekan tombol Tambah untuk membuat kupon pertama, atau tarik halaman ke bawah untuk refresh data.', textAlign: TextAlign.center, style: TextStyle(color: Colors.grey.shade600)),
      ]),
    );
  }
}

class CouponDetailScreen extends StatelessWidget {
  final Map<String, dynamic> coupon;

  const CouponDetailScreen({Key? key, required this.coupon}) : super(key: key);

  static const Color _primary = Color(0xFF0C2442);
  static const Color _accent = Color(0xFFF39C12);
  static const Color _surface = Color(0xFFF7F8FC);

  String _money(dynamic value) {
    final number = double.tryParse(value?.toString() ?? '0') ?? 0;
    return 'Rp ${number.toStringAsFixed(0)}';
  }

  String _value() {
    final type = coupon['type']?.toString() ?? 'fixed';
    final value = double.tryParse(coupon['value']?.toString() ?? '0') ?? 0;
    return type == 'discount' ? '${value.toStringAsFixed(value % 1 == 0 ? 0 : 1)}%' : _money(value);
  }

  String _limitLabel() {
    final raw = coupon['remaining_limit'] ?? coupon['usage_limit'];
    if (raw == null || raw.toString().trim().isEmpty || raw.toString() == 'null') return 'Tidak dibatasi';
    final value = int.tryParse(raw.toString());
    if (value == null) return raw.toString();
    return value <= 0 ? 'Habis' : '$value tersisa';
  }

  Future<void> _delete(BuildContext context) async {
    final id = int.tryParse(coupon['id']?.toString() ?? '');
    if (id == null) return;
    final ok = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
        title: const Text('Hapus kupon?', style: TextStyle(fontWeight: FontWeight.w900)),
        content: const Text('Kupon ini akan dihapus permanen.'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context, false), child: const Text('Batal')),
          TextButton(onPressed: () => Navigator.pop(context, true), child: const Text('Hapus', style: TextStyle(color: Colors.red, fontWeight: FontWeight.w900))),
        ],
      ),
    );
    if (ok != true) return;
    final deleted = await MarketplaceApiService.deleteCoupon(id);
    if (!context.mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(deleted ? 'Kupon dihapus.' : 'Gagal menghapus kupon.')));
    if (deleted) Navigator.pop(context, true);
  }

  Future<void> _edit(BuildContext context) async {
    final result = await Navigator.push(context, MaterialPageRoute(builder: (_) => AddCupponScreen(coupon: coupon)));
    if (context.mounted && result == true) Navigator.pop(context, true);
  }

  @override
  Widget build(BuildContext context) {
    final type = coupon['type']?.toString() == 'discount' ? 'Discount / persen' : 'Fixed / nominal';
    final active = coupon['status']?.toString() == 'active' || coupon['status'] == 1;
    return Scaffold(
      backgroundColor: _surface,
      body: CustomScrollView(
        physics: const BouncingScrollPhysics(parent: AlwaysScrollableScrollPhysics()),
        slivers: [
          SliverToBoxAdapter(child: _header(context)),
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(16, 14, 16, 28),
              child: Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
                _card(child: Column(children: [
                  _row('Tipe', type),
                  _row('Status', active ? 'Aktif' : 'Nonaktif'),
                  _row('Minimal Belanja', _money(coupon['min_purchase'])),
                  _row('Maksimal Potongan', coupon['max_discount'] == null ? '-' : _money(coupon['max_discount'])),
                  _row('Sisa Limit', _limitLabel()),
                  _row('Total Diambil', '${coupon['taken_count'] ?? 0}x'),
                  _row('Deskripsi', coupon['description']?.toString().isNotEmpty == true ? coupon['description'].toString() : '-'),
                ])),
                const SizedBox(height: 18),
                ElevatedButton.icon(onPressed: () => _edit(context), icon: const Icon(Icons.edit_rounded), label: const Text('Edit Kupon'), style: ElevatedButton.styleFrom(backgroundColor: _primary, foregroundColor: Colors.white, elevation: 0, padding: const EdgeInsets.symmetric(vertical: 14), shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)))),
                const SizedBox(height: 10),
                OutlinedButton.icon(onPressed: () => _delete(context), icon: const Icon(Icons.delete_outline_rounded), label: const Text('Hapus Kupon'), style: OutlinedButton.styleFrom(foregroundColor: Colors.red, side: BorderSide(color: Colors.red.shade200), padding: const EdgeInsets.symmetric(vertical: 14), shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)))),
              ]),
            ),
          ),
        ],
      ),
    );
  }

  Widget _header(BuildContext context) {
    return Container(
      decoration: const BoxDecoration(
        gradient: LinearGradient(colors: [_primary, Color(0xFF123A68)], begin: Alignment.topLeft, end: Alignment.bottomRight),
        borderRadius: BorderRadius.vertical(bottom: Radius.circular(30)),
      ),
      child: SafeArea(
        bottom: false,
        child: Padding(
          padding: const EdgeInsets.fromLTRB(18, 18, 18, 24),
          child: Column(children: [
            Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
              _circleAction(Icons.arrow_back_rounded, () => Navigator.pop(context)),
              const Text('Detail Kupon', style: TextStyle(color: Colors.white, fontSize: 20, fontWeight: FontWeight.w900)),
              _circleAction(Icons.edit_rounded, () => _edit(context)),
            ]),
            const SizedBox(height: 20),
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(color: Colors.white.withOpacity(0.12), borderRadius: BorderRadius.circular(26), border: Border.all(color: Colors.white.withOpacity(0.16))),
              child: Row(children: [
                Container(width: 66, height: 66, decoration: const BoxDecoration(color: Colors.white, shape: BoxShape.circle), child: const Icon(Icons.local_activity_rounded, color: _primary, size: 36)),
                const SizedBox(width: 14),
                Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                  Text(coupon['code']?.toString() ?? '-', style: const TextStyle(color: _accent, fontSize: 13, fontWeight: FontWeight.w900, letterSpacing: .8)),
                  const SizedBox(height: 5),
                  Text(_value(), style: const TextStyle(color: Colors.white, fontSize: 28, fontWeight: FontWeight.w900)),
                  const SizedBox(height: 4),
                  Text(coupon['name']?.toString() ?? 'Kupon', maxLines: 1, overflow: TextOverflow.ellipsis, style: TextStyle(color: Colors.white.withOpacity(.78), fontSize: 12, fontWeight: FontWeight.w700)),
                ])),
              ]),
            ),
          ]),
        ),
      ),
    );
  }

  Widget _circleAction(IconData icon, VoidCallback? onTap) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(999),
      child: Container(width: 42, height: 42, decoration: BoxDecoration(color: Colors.white.withOpacity(0.14), shape: BoxShape.circle, border: Border.all(color: Colors.white.withOpacity(0.12))), child: Icon(icon, color: Colors.white, size: 21)),
    );
  }

  Widget _card({required Widget child}) {
    return Container(padding: const EdgeInsets.all(16), decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(22), border: Border.all(color: Colors.grey.shade200), boxShadow: [BoxShadow(color: _primary.withOpacity(0.04), blurRadius: 16, offset: const Offset(0, 8))]), child: child);
  }

  Widget _row(String label, String value) => Container(
        margin: const EdgeInsets.only(bottom: 10),
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(color: _surface, borderRadius: BorderRadius.circular(16)),
        child: Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
          SizedBox(width: 130, child: Text(label, style: const TextStyle(fontSize: 12, color: Color(0xFF64748B), fontWeight: FontWeight.w700))),
          Expanded(child: Text(value, textAlign: TextAlign.right, style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w900, color: Colors.black87))),
        ]),
      );
}

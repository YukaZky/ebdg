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
        title: const Text('Hapus kupon?'),
        content: Text('Kupon ${coupon['name'] ?? coupon['code'] ?? ''} akan dihapus dari toko kamu.'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context, false), child: const Text('Batal')),
          ElevatedButton(onPressed: () => Navigator.pop(context, true), style: ElevatedButton.styleFrom(backgroundColor: Colors.red, foregroundColor: Colors.white), child: const Text('Hapus')),
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
    final active = coupon['status']?.toString() == 'active';
    final typeText = coupon['type']?.toString() == 'discount' ? 'Discount' : 'Fixed';
    return InkWell(
      onTap: () => _openDetail(coupon),
      borderRadius: BorderRadius.circular(18),
      child: Container(
        margin: const EdgeInsets.only(bottom: 12),
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(18),
          border: Border.all(color: active ? Colors.deepOrange.withOpacity(.22) : Colors.grey.shade300),
          boxShadow: [BoxShadow(color: Colors.black.withOpacity(.04), blurRadius: 12, offset: const Offset(0, 5))],
        ),
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Row(children: [
            Container(
              width: 48,
              height: 48,
              decoration: BoxDecoration(color: active ? const Color(0xFFFFF3E0) : const Color(0xFFF1F5F9), borderRadius: BorderRadius.circular(14)),
              child: Icon(Icons.confirmation_number_rounded, color: active ? Colors.deepOrange : Colors.grey, size: 26),
            ),
            const SizedBox(width: 12),
            Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Text(coupon['name']?.toString() ?? 'Kupon', maxLines: 1, overflow: TextOverflow.ellipsis, style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w900)),
              const SizedBox(height: 3),
              Text(coupon['code']?.toString() ?? '-', style: const TextStyle(fontSize: 12, color: Colors.deepOrange, fontWeight: FontWeight.w800)),
            ])),
            PopupMenuButton<String>(
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
          const SizedBox(height: 12),
          Row(children: [
            _badge(typeText, Colors.blueGrey),
            const SizedBox(width: 8),
            _badge(active ? 'Aktif' : 'Nonaktif', active ? Colors.green : Colors.grey),
            const Spacer(),
            Text(_discountLabel(coupon), style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w900, color: Colors.deepOrange)),
          ]),
          const SizedBox(height: 8),
          Text('Min. belanja ${_money(coupon['min_purchase'])} • Diambil ${coupon['taken_count'] ?? 0}x', style: const TextStyle(fontSize: 12, color: Color(0xFF64748B))),
        ]),
      ),
    );
  }

  Widget _badge(String text, Color color) => Container(
        padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 5),
        decoration: BoxDecoration(color: color.withOpacity(.10), borderRadius: BorderRadius.circular(99)),
        child: Text(text, style: TextStyle(color: color, fontSize: 11, fontWeight: FontWeight.w800)),
      );

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF6F7FB),
      appBar: AppBar(title: const Text('List Kupon'), backgroundColor: Colors.white, foregroundColor: Colors.black87),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => _openAdd(),
        backgroundColor: Colors.deepOrange,
        foregroundColor: Colors.white,
        icon: const Icon(Icons.add),
        label: const Text('Tambah'),
      ),
      body: RefreshIndicator(
        onRefresh: _refresh,
        child: FutureBuilder<List<dynamic>>(
          future: _future,
          builder: (context, snapshot) {
            if (snapshot.connectionState == ConnectionState.waiting) return const Center(child: CircularProgressIndicator(color: Colors.deepOrange));
            final data = (snapshot.data ?? []).whereType<Map>().map((e) => Map<String, dynamic>.from(e)).toList();
            if (data.isEmpty) {
              return ListView(
                padding: const EdgeInsets.all(24),
                children: const [
                  SizedBox(height: 120),
                  Icon(Icons.confirmation_number_outlined, size: 72, color: Colors.deepOrange),
                  SizedBox(height: 14),
                  Center(child: Text('Belum ada kupon toko.', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w800))),
                  SizedBox(height: 6),
                  Center(child: Text('Tekan tombol Tambah untuk membuat kupon pertama.', textAlign: TextAlign.center, style: TextStyle(color: Colors.black54))),
                ],
              );
            }
            return ListView.builder(padding: const EdgeInsets.fromLTRB(16, 16, 16, 92), itemCount: data.length, itemBuilder: (_, index) => _couponCard(data[index]));
          },
        ),
      ),
    );
  }
}

class CouponDetailScreen extends StatelessWidget {
  final Map<String, dynamic> coupon;

  const CouponDetailScreen({Key? key, required this.coupon}) : super(key: key);

  String _money(dynamic value) {
    final number = double.tryParse(value?.toString() ?? '0') ?? 0;
    return 'Rp ${number.toStringAsFixed(0)}';
  }

  String _value() {
    final type = coupon['type']?.toString() ?? 'fixed';
    final value = double.tryParse(coupon['value']?.toString() ?? '0') ?? 0;
    return type == 'discount' ? '${value.toStringAsFixed(value % 1 == 0 ? 0 : 1)}%' : _money(value);
  }

  Future<void> _delete(BuildContext context) async {
    final id = int.tryParse(coupon['id']?.toString() ?? '');
    if (id == null) return;
    final ok = await showDialog<bool>(context: context, builder: (_) => AlertDialog(title: const Text('Hapus kupon?'), content: const Text('Kupon ini akan dihapus permanen.'), actions: [TextButton(onPressed: () => Navigator.pop(context, false), child: const Text('Batal')), ElevatedButton(onPressed: () => Navigator.pop(context, true), style: ElevatedButton.styleFrom(backgroundColor: Colors.red, foregroundColor: Colors.white), child: const Text('Hapus'))]));
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
    final active = coupon['status']?.toString() == 'active';
    return Scaffold(
      backgroundColor: const Color(0xFFF6F7FB),
      appBar: AppBar(title: const Text('Detail Kupon'), backgroundColor: Colors.white, foregroundColor: Colors.black87),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
          Container(
            padding: const EdgeInsets.all(18),
            decoration: BoxDecoration(gradient: const LinearGradient(colors: [Color(0xFFE65100), Color(0xFFFF8A00)]), borderRadius: BorderRadius.circular(20)),
            child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Text(coupon['code']?.toString() ?? '-', style: const TextStyle(color: Colors.white, fontSize: 13, fontWeight: FontWeight.w800, letterSpacing: 1.2)),
              const SizedBox(height: 10),
              Text(_value(), style: const TextStyle(color: Colors.white, fontSize: 32, fontWeight: FontWeight.w900)),
              const SizedBox(height: 6),
              Text(coupon['name']?.toString() ?? 'Kupon', style: const TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.w700)),
            ]),
          ),
          const SizedBox(height: 16),
          _row('Tipe', type),
          _row('Status', active ? 'Aktif' : 'Nonaktif'),
          _row('Minimal Belanja', _money(coupon['min_purchase'])),
          _row('Maksimal Potongan', coupon['max_discount'] == null ? '-' : _money(coupon['max_discount'])),
          _row('Limit Pengambilan', coupon['usage_limit']?.toString() ?? '-'),
          _row('Total Diambil', '${coupon['taken_count'] ?? 0}x'),
          _row('Deskripsi', coupon['description']?.toString().isNotEmpty == true ? coupon['description'].toString() : '-'),
          const SizedBox(height: 18),
          ElevatedButton.icon(onPressed: () => _edit(context), icon: const Icon(Icons.edit), label: const Text('Edit Kupon'), style: ElevatedButton.styleFrom(backgroundColor: Colors.deepOrange, foregroundColor: Colors.white, padding: const EdgeInsets.symmetric(vertical: 13))),
          const SizedBox(height: 10),
          OutlinedButton.icon(onPressed: () => _delete(context), icon: const Icon(Icons.delete_outline), label: const Text('Hapus Kupon'), style: OutlinedButton.styleFrom(foregroundColor: Colors.red, side: const BorderSide(color: Colors.red), padding: const EdgeInsets.symmetric(vertical: 13))),
        ]),
      ),
    );
  }

  Widget _row(String label, String value) => Container(
        margin: const EdgeInsets.only(bottom: 10),
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(14), border: Border.all(color: const Color(0xFFE2E8F0))),
        child: Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
          SizedBox(width: 130, child: Text(label, style: const TextStyle(fontSize: 12, color: Color(0xFF64748B)))),
          Expanded(child: Text(value, textAlign: TextAlign.right, style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w800))),
        ]),
      );
}

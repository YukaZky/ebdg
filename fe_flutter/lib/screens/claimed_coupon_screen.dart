import 'package:flutter/material.dart';
import '../services/marketplace_api_service.dart';

class ClaimedCouponScreen extends StatefulWidget {
  const ClaimedCouponScreen({Key? key}) : super(key: key);

  @override
  State<ClaimedCouponScreen> createState() => _ClaimedCouponScreenState();
}

class _ClaimedCouponScreenState extends State<ClaimedCouponScreen> {
  late Future<List<dynamic>> _future;

  static const Color _primary = Color(0xFF0C2442);
  static const Color _accent = Color(0xFFF39C12);
  static const Color _surface = Color(0xFFF7F8FC);

  @override
  void initState() {
    super.initState();
    _future = MarketplaceApiService.claimedCoupons();
  }

  Future<void> _refresh() async {
    setState(() => _future = MarketplaceApiService.claimedCoupons());
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

  String _dateText(dynamic value) {
    final text = value?.toString() ?? '';
    if (text.isEmpty || text == 'null') return '-';
    return text.split(' ').first.split('T').first;
  }

  String _statusText(Map<String, dynamic> item) {
    if (item['is_expired'] == true || item['usage_status'] == 'expired') return 'Kadaluarsa';
    if (item['status']?.toString() == 'used') return 'Sudah digunakan';
    if (item['can_use'] == true) return 'Bisa digunakan';
    if (item['is_started'] == false) return 'Belum aktif';
    return 'Tidak tersedia';
  }

  Color _statusColor(Map<String, dynamic> item) {
    if (item['is_expired'] == true || item['usage_status'] == 'expired') return Colors.red;
    if (item['status']?.toString() == 'used') return Colors.grey;
    if (item['can_use'] == true) return Colors.green;
    return Colors.orange;
  }

  void _useCoupon(Map<String, dynamic> item) {
    final expired = item['is_expired'] == true || item['usage_status'] == 'expired';
    final canUse = item['can_use'] == true;

    if (expired) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Kupon sudah kadaluarsa dan tidak bisa digunakan.')));
      return;
    }

    if (!canUse) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Kupon belum bisa digunakan.')));
      return;
    }

    ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Kupon siap digunakan saat checkout.')));
  }

  Widget _couponCard(Map<String, dynamic> item) {
    final coupon = item['coupon'] is Map ? Map<String, dynamic>.from(item['coupon']) : <String, dynamic>{};
    final statusColor = _statusColor(item);
    final expired = item['is_expired'] == true || item['usage_status'] == 'expired';
    final canUse = item['can_use'] == true;

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(22), border: Border.all(color: Colors.grey.shade200), boxShadow: [BoxShadow(color: _primary.withOpacity(0.04), blurRadius: 16, offset: const Offset(0, 8))]),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Row(children: [
          Container(width: 52, height: 52, decoration: BoxDecoration(color: _accent.withOpacity(.12), borderRadius: BorderRadius.circular(16)), child: const Icon(Icons.local_activity_rounded, color: _primary, size: 28)),
          const SizedBox(width: 12),
          Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Text(coupon['name']?.toString() ?? 'Kupon', maxLines: 1, overflow: TextOverflow.ellipsis, style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w900, color: Colors.black87)),
            const SizedBox(height: 4),
            Text(coupon['code']?.toString() ?? '-', style: const TextStyle(fontSize: 12, color: _accent, fontWeight: FontWeight.w900, letterSpacing: .5)),
          ])),
          Container(padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 5), decoration: BoxDecoration(color: statusColor.withOpacity(.10), borderRadius: BorderRadius.circular(999)), child: Text(_statusText(item), style: TextStyle(color: statusColor, fontSize: 11, fontWeight: FontWeight.w900))),
        ]),
        const SizedBox(height: 14),
        Container(
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(color: _surface, borderRadius: BorderRadius.circular(18)),
          child: Row(children: [
            Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              const Text('Nilai Kupon', style: TextStyle(fontSize: 11, color: Color(0xFF64748B), fontWeight: FontWeight.w700)),
              const SizedBox(height: 4),
              Text(_discountLabel(coupon), style: const TextStyle(fontSize: 24, fontWeight: FontWeight.w900, color: _primary)),
            ])),
            Column(crossAxisAlignment: CrossAxisAlignment.end, children: [
              Text('Min. belanja', style: TextStyle(fontSize: 11, color: Colors.grey.shade600, fontWeight: FontWeight.w700)),
              const SizedBox(height: 4),
              Text(_money(coupon['min_purchase']), style: const TextStyle(fontSize: 13, color: Colors.black87, fontWeight: FontWeight.w900)),
            ]),
          ]),
        ),
        const SizedBox(height: 10),
        Row(children: [
          Expanded(child: Text('Diklaim: ${_dateText(item['claimed_at'])}', style: const TextStyle(fontSize: 12, color: Color(0xFF64748B), fontWeight: FontWeight.w700))),
          Text('Expired: ${_dateText(coupon['expires_at'])}', style: TextStyle(fontSize: 12, color: expired ? Colors.red : const Color(0xFF64748B), fontWeight: FontWeight.w800)),
        ]),
        const SizedBox(height: 12),
        SizedBox(
          width: double.infinity,
          child: ElevatedButton.icon(
            onPressed: canUse ? () => _useCoupon(item) : null,
            icon: Icon(expired ? Icons.block_rounded : Icons.check_circle_rounded),
            label: Text(expired ? 'Kupon Kadaluarsa' : canUse ? 'Gunakan Kupon' : 'Tidak Bisa Digunakan'),
            style: ElevatedButton.styleFrom(backgroundColor: _primary, foregroundColor: Colors.white, disabledBackgroundColor: const Color(0xFFE2E8F0), disabledForegroundColor: Colors.grey, elevation: 0, padding: const EdgeInsets.symmetric(vertical: 13), shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16))),
          ),
        ),
      ]),
    );
  }

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
                    padding: const EdgeInsets.fromLTRB(16, 14, 16, 28),
                    sliver: SliverList(delegate: SliverChildBuilderDelegate((context, index) => _couponCard(data[index]), childCount: data.length)),
                  ),
              ],
            );
          },
        ),
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
              const Text('Kupon Saya', style: TextStyle(color: Colors.white, fontSize: 20, fontWeight: FontWeight.w900)),
              _circleAction(Icons.local_activity_rounded, null),
            ]),
            const SizedBox(height: 20),
            Container(
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(color: Colors.white.withOpacity(0.12), borderRadius: BorderRadius.circular(26), border: Border.all(color: Colors.white.withOpacity(0.16))),
              child: Row(children: [
                Container(width: 64, height: 64, decoration: const BoxDecoration(color: Colors.white, shape: BoxShape.circle), child: const Icon(Icons.confirmation_number_rounded, color: _primary, size: 34)),
                const SizedBox(width: 14),
                Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                  const Text('Coupon Claimed', style: TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.w900)),
                  const SizedBox(height: 5),
                  Text('$count kupon sudah kamu ambil', style: TextStyle(color: Colors.white.withOpacity(0.78), fontSize: 12)),
                  const SizedBox(height: 3),
                  Text('Kupon kadaluarsa otomatis tidak bisa digunakan.', style: TextStyle(color: Colors.white.withOpacity(0.70), fontSize: 11)),
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

  Widget _emptyState() {
    return Padding(
      padding: const EdgeInsets.all(24),
      child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
        Container(width: 84, height: 84, decoration: BoxDecoration(color: _accent.withOpacity(.12), shape: BoxShape.circle), child: const Icon(Icons.local_activity_outlined, size: 44, color: _primary)),
        const SizedBox(height: 16),
        const Text('Belum ada kupon yang diambil.', style: TextStyle(fontSize: 17, fontWeight: FontWeight.w900, color: Colors.black87)),
        const SizedBox(height: 6),
        Text('Ambil kupon dari halaman detail toko, lalu kupon akan muncul di sini.', textAlign: TextAlign.center, style: TextStyle(color: Colors.grey.shade600)),
      ]),
    );
  }
}

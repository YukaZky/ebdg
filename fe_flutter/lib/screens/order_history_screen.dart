import 'dart:async';
import 'dart:convert';
import 'package:flutter/material.dart';
import '../services/api_service.dart';
import 'order_confirmation_screen.dart';
import 'resume_order_checkout_screen.dart';

class OrderHistoryScreen extends StatefulWidget {
  const OrderHistoryScreen({Key? key}) : super(key: key);

  @override
  State<OrderHistoryScreen> createState() => _OrderHistoryScreenState();
}

class _OrderHistoryScreenState extends State<OrderHistoryScreen> {
  static const Color navy = Color(0xFF0B1F4D);
  static const Color danger = Color(0xFFB91C1C);

  late Future<List<dynamic>> _future;
  Timer? _timer;
  String _tab = 'all';

  final List<List<dynamic>> tabs = const [
    ['all', 'Semua', Icons.apps_rounded],
    ['pending_payment', 'Belum Dibayar', Icons.payments_outlined],
    ['paid_not_checked_out', 'Dibayar', Icons.verified_outlined],
    ['packing', 'Dikemas', Icons.inventory_2_outlined],
    ['delivered', 'Dikirim', Icons.local_shipping_outlined],
    ['done', 'Selesai', Icons.task_alt_rounded],
    ['canceled', 'Dibatalkan', Icons.cancel_outlined],
  ];

  @override
  void initState() {
    super.initState();
    _future = ApiService.getOrders();
    _timer = Timer.periodic(const Duration(seconds: 1), (_) {
      if (mounted) setState(() {});
    });
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  Future<void> _refresh() async {
    setState(() => _future = ApiService.getOrders());
    await _future;
  }

  Map<String, dynamic> map(dynamic v) {
    if (v is Map<String, dynamic>) return v;
    if (v is Map) return Map<String, dynamic>.from(v);
    return {};
  }

  num number(dynamic v) {
    if (v is num) return v;
    return num.tryParse(v?.toString() ?? '') ?? 0;
  }

  String money(dynamic v) => 'Rp ${number(v).toStringAsFixed(0)}';

  Map<String, dynamic> details(Map<String, dynamic> order) {
    final trx = map(order['transaction']);
    final raw = trx['payment_details'];
    if (raw is Map<String, dynamic>) return raw;
    if (raw is Map) return Map<String, dynamic>.from(raw);
    if (raw is String && raw.isNotEmpty) {
      try {
        final decoded = jsonDecode(raw);
        if (decoded is Map<String, dynamic>) return decoded;
        if (decoded is Map) return Map<String, dynamic>.from(decoded);
      } catch (_) {}
    }
    return {};
  }

  String status(Map<String, dynamic> order) {
    final direct = order['frontend_status']?.toString().toLowerCase();
    if (direct != null && direct.isNotEmpty) return direct;

    final trx = map(order['transaction'])['status']?.toString().toLowerCase() ?? order['transaction_status']?.toString().toLowerCase() ?? '';
    final raw = order['status']?.toString().toLowerCase() ?? '';

    if (raw == 'canceled' || raw == 'cancelled') return 'canceled';
    if (raw == 'done' || raw == 'completed' || raw == 'complete' || raw == 'selesai') return 'done';
    if (raw == 'delivered' || raw == 'deliver') return 'delivered';
    if (raw == 'packing' || raw == 'processing' || raw == 'shipped' || raw == 'dikemas') return 'packing';
    if (raw == 'paid' || raw == 'dibayar' || trx == 'approved' || trx == 'settlement' || trx == 'capture') return 'paid_not_checked_out';
    return 'pending_payment';
  }

  String label(Map<String, dynamic> order) {
    final value = order['frontend_status_label']?.toString();
    if (value != null && value.isNotEmpty) return value;
    return tabs.firstWhere((t) => t[0] == status(order), orElse: () => ['pending_payment', 'Belum Dibayar', Icons.payments_outlined])[1] as String;
  }

  String timerText(Map<String, dynamic> order) {
    final info = map(details(order)['payment_info']);
    final expiry = (order['payment_deadline'] ?? info['expiry_time'])?.toString();
    if (expiry == null || expiry.isEmpty) return 'Menunggu pembayaran';
    try {
      final left = DateTime.parse(expiry).difference(DateTime.now());
      if (left.isNegative) return 'Waktu pembayaran habis';
      return '${left.inHours.toString().padLeft(2, '0')}:${left.inMinutes.remainder(60).toString().padLeft(2, '0')}:${left.inSeconds.remainder(60).toString().padLeft(2, '0')}';
    } catch (_) {
      return expiry;
    }
  }

  List<dynamic> filtered(List<dynamic> orders) => _tab == 'all' ? orders : orders.where((e) => status(map(e)) == _tab).toList();
  int countBy(List<dynamic> orders, String key) => key == 'all' ? orders.length : orders.where((e) => status(map(e)) == key).length;

  void open(Map<String, dynamic> order) {
    final s = status(order);
    if (s == 'pending_payment') {
      Navigator.push(context, MaterialPageRoute(builder: (_) => ResumeOrderCheckoutScreen(order: order))).then((_) => _refresh());
      return;
    }

    Navigator.push(context, MaterialPageRoute(builder: (_) => OrderConfirmationScreen(order: order))).then((_) => _refresh());
  }

  IconData statusIcon(String s) {
    switch (s) {
      case 'pending_payment':
        return Icons.payments_outlined;
      case 'paid_not_checked_out':
        return Icons.verified_outlined;
      case 'packing':
        return Icons.inventory_2_rounded;
      case 'delivered':
        return Icons.local_shipping_rounded;
      case 'done':
        return Icons.task_alt_rounded;
      case 'canceled':
        return Icons.cancel_outlined;
      default:
        return Icons.receipt_long_rounded;
    }
  }

  Color statusColor(String s) => s == 'canceled' ? danger : navy;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF5F7FB),
      appBar: AppBar(title: const Text('Riwayat Pesanan', style: TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.w800)), backgroundColor: navy, iconTheme: const IconThemeData(color: Colors.white)),
      body: FutureBuilder<List<dynamic>>(
        future: _future,
        builder: (context, snap) {
          final orders = snap.data ?? [];
          return Column(children: [
            _statusCards(orders),
            Expanded(child: RefreshIndicator(onRefresh: _refresh, child: Builder(builder: (context) {
              if (snap.connectionState == ConnectionState.waiting) return const Center(child: CircularProgressIndicator(color: navy));
              if (snap.hasError) return Center(child: Text('Error: ${snap.error}'));
              final data = filtered(orders);
              if (data.isEmpty) return ListView(physics: const AlwaysScrollableScrollPhysics(), children: const [SizedBox(height: 220), Center(child: Text('Belum ada pesanan pada status ini.'))]);
              return ListView.builder(physics: const AlwaysScrollableScrollPhysics(), padding: const EdgeInsets.all(16), itemCount: data.length, itemBuilder: (_, i) => card(map(data[i])));
            }))),
          ]);
        },
      ),
    );
  }

  Widget _countBadge(int count, bool active, Color activeColor) {
    return Container(
      constraints: const BoxConstraints(minWidth: 24),
      padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 3),
      decoration: BoxDecoration(color: active ? Colors.white : activeColor, borderRadius: BorderRadius.circular(999)),
      child: Text('$count', textAlign: TextAlign.center, style: TextStyle(fontSize: 11, fontWeight: FontWeight.w900, color: active ? activeColor : Colors.white)),
    );
  }

  Widget _statusCards(List<dynamic> orders) {
    return Container(
      color: Colors.white,
      padding: const EdgeInsets.fromLTRB(12, 12, 12, 10),
      child: SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        child: Row(children: tabs.map((t) {
          final key = t[0] as String;
          final title = t[1] as String;
          final icon = t[2] as IconData;
          final active = _tab == key;
          final isCanceled = key == 'canceled';
          final activeColor = isCanceled ? danger : navy;
          final count = countBy(orders, key);
          return Padding(
            padding: const EdgeInsets.only(right: 10),
            child: InkWell(
              onTap: () => setState(() => _tab = key),
              borderRadius: BorderRadius.circular(16),
              child: Container(
                width: 128,
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(color: active ? activeColor : isCanceled ? const Color(0xFFFEE2E2) : const Color(0xFFEAF0FF), borderRadius: BorderRadius.circular(16), border: Border.all(color: active ? activeColor : isCanceled ? const Color(0xFFFCA5A5) : const Color(0xFFD9E4FF))),
                child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                  Row(children: [Icon(icon, size: 19, color: active ? Colors.white : activeColor), const Spacer(), _countBadge(count, active, activeColor)]),
                  const SizedBox(height: 9),
                  Text(title, maxLines: 1, overflow: TextOverflow.ellipsis, style: TextStyle(fontSize: 12, fontWeight: FontWeight.w900, color: active ? Colors.white : activeColor)),
                  Text('Ketuk untuk buka', style: TextStyle(fontSize: 10.5, color: active ? Colors.white70 : const Color(0xFF64748B))),
                ]),
              ),
            ),
          );
        }).toList()),
      ),
    );
  }

  Widget card(Map<String, dynamic> order) {
    final items = order['items'] is List ? order['items'] as List : [];
    final product = items.isNotEmpty ? map(map(items.first)['product']) : {};
    final s = status(order);
    final color = statusColor(s);
    return InkWell(
      onTap: () => open(order),
      child: Container(
        margin: const EdgeInsets.only(bottom: 12),
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(16), border: Border.all(color: s == 'canceled' ? const Color(0xFFFCA5A5) : const Color(0xFFE2E8F0))),
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Row(children: [Icon(statusIcon(s), color: color), const SizedBox(width: 10), Expanded(child: Text('#ORDER-${order['id']}', style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w900))), Text(label(order), style: TextStyle(fontSize: 11, color: color, fontWeight: FontWeight.w900))]),
          const SizedBox(height: 10),
          Text(product['name']?.toString() ?? '${items.length} item produk', maxLines: 1, overflow: TextOverflow.ellipsis, style: const TextStyle(fontSize: 12.5, fontWeight: FontWeight.w700)),
          Text('${items.length} item • ${order['mode_pengiriman'] ?? '-'} ${order['jenis_pengiriman'] ?? ''}', style: const TextStyle(fontSize: 11.5, color: Color(0xFF64748B))),
          if (s == 'pending_payment') Padding(padding: const EdgeInsets.only(top: 8), child: Text('Sisa waktu pembayaran: ${timerText(order)}', style: const TextStyle(fontSize: 11.5, color: Color(0xFF92400E), fontWeight: FontWeight.w800))),
          if (s == 'paid_not_checked_out') const Padding(padding: EdgeInsets.only(top: 8), child: Text('Pesanan sudah dibayar dan menunggu toko memproses menjadi dikemas.', style: TextStyle(fontSize: 11.5, color: Color(0xFF15803D), fontWeight: FontWeight.w800))),
          if (s == 'canceled') const Padding(padding: EdgeInsets.only(top: 8), child: Text('Pesanan ini sudah dibatalkan.', style: TextStyle(fontSize: 11.5, color: danger, fontWeight: FontWeight.w800))),
          if (s == 'done') const Padding(padding: EdgeInsets.only(top: 8), child: Text('Pesanan selesai. Buka detail untuk memberi penilaian.', style: TextStyle(fontSize: 11.5, color: Color(0xFF15803D), fontWeight: FontWeight.w800))),
          const Divider(height: 22),
          Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [const Text('Total Order', style: TextStyle(fontSize: 12, color: Color(0xFF64748B))), Text(money(order['total']), style: TextStyle(fontSize: 15, color: color, fontWeight: FontWeight.w900))]),
        ]),
      ),
    );
  }
}

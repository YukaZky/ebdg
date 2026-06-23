import 'dart:async';
import 'dart:convert';
import 'package:flutter/material.dart';
import '../services/api_service.dart';
import 'checkout_screen.dart';
import 'order_confirmation_screen.dart';

class OrderHistoryScreen extends StatefulWidget {
  const OrderHistoryScreen({Key? key}) : super(key: key);

  @override
  State<OrderHistoryScreen> createState() => _OrderHistoryScreenState();
}

class _OrderHistoryScreenState extends State<OrderHistoryScreen> {
  static const Color _navy = Color(0xFF0B1F4D);
  static const Color _pageBg = Color(0xFFF5F7FB);

  late Future<List<dynamic>> _ordersFuture;
  Timer? _timer;
  String _selectedStatus = 'all';

  final List<Map<String, String>> _tabs = const [
    {'key': 'all', 'label': 'Semua'},
    {'key': 'pending_payment', 'label': 'Pending'},
    {'key': 'paid_not_checked_out', 'label': 'Dibayar'},
    {'key': 'packing', 'label': 'Packing'},
    {'key': 'delivered', 'label': 'Delivered'},
    {'key': 'done', 'label': 'Done'},
    {'key': 'canceled', 'label': 'Canceled'},
  ];

  @override
  void initState() {
    super.initState();
    _ordersFuture = ApiService.getOrders();
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
    setState(() => _ordersFuture = ApiService.getOrders());
    await _ordersFuture;
  }

  Map<String, dynamic> _map(dynamic value) {
    if (value is Map<String, dynamic>) return value;
    if (value is Map) return Map<String, dynamic>.from(value);
    return <String, dynamic>{};
  }

  Map<String, dynamic> _decodeMap(dynamic value) {
    if (value is Map<String, dynamic>) return value;
    if (value is Map) return Map<String, dynamic>.from(value);
    if (value is String && value.trim().isNotEmpty) {
      try {
        final decoded = jsonDecode(value);
        if (decoded is Map<String, dynamic>) return decoded;
        if (decoded is Map) return Map<String, dynamic>.from(decoded);
      } catch (_) {}
    }
    return <String, dynamic>{};
  }

  num _num(dynamic value) => value is num ? value : num.tryParse(value?.toString() ?? '') ?? 0;
  String _money(dynamic value) => 'Rp ${_num(value).toStringAsFixed(0)}';

  String _status(dynamic order) {
    final map = _map(order);
    final frontend = map['frontend_status']?.toString();
    if (frontend != null && frontend.isNotEmpty) return frontend;
    final transaction = _map(map['transaction']);
    final trx = transaction['status']?.toString();
    final raw = map['status']?.toString().toLowerCase() ?? '';
    if (raw == 'canceled') return 'canceled';
    if (raw == 'delivered') return 'delivered';
    if (trx == 'approved' || trx == 'settlement' || trx == 'capture') return 'paid_not_checked_out';
    return 'pending_payment';
  }

  String _label(dynamic order) {
    final label = _map(order)['frontend_status_label']?.toString();
    if (label != null && label.isNotEmpty) return label;
    final status = _status(order);
    return _tabs.firstWhere((tab) => tab['key'] == status, orElse: () => {'label': 'Pending'})['label']!;
  }

  Color _statusColor(String status) {
    switch (status) {
      case 'pending_payment':
        return const Color(0xFFF59E0B);
      case 'paid_not_checked_out':
        return const Color(0xFF2563EB);
      case 'packing':
        return const Color(0xFF7C3AED);
      case 'delivered':
      case 'done':
        return const Color(0xFF16A34A);
      case 'canceled':
        return const Color(0xFFDC2626);
      default:
        return _navy;
    }
  }

  String? _expiry(dynamic order) {
    final map = _map(order);
    if (map['payment_deadline'] != null) return map['payment_deadline'].toString();
    final details = _decodeMap(_map(map['transaction'])['payment_details']);
    final info = _map(details['payment_info']);
    return info['expiry_time']?.toString();
  }

  String _timerText(dynamic order) {
    final expiry = _expiry(order);
    if (expiry == null || expiry.isEmpty) return 'Batas pembayaran belum tersedia';
    try {
      final left = DateTime.parse(expiry).difference(DateTime.now());
      if (left.isNegative) return 'Waktu pembayaran habis';
      final hours = left.inHours.toString().padLeft(2, '0');
      final minutes = left.inMinutes.remainder(60).toString().padLeft(2, '0');
      final seconds = left.inSeconds.remainder(60).toString().padLeft(2, '0');
      return 'Sisa waktu pembayaran: $hours:$minutes:$seconds';
    } catch (_) {
      return 'Batas pembayaran: $expiry';
    }
  }

  List<Map<String, dynamic>> _cartItemsFromOrder(Map<String, dynamic> order) {
    final items = order['items'] is List ? order['items'] as List : [];
    return items.map((raw) {
      final item = _map(raw);
      final product = _map(item['product']);
      final option = _decodeMap(item['option']);
      return {
        'id': item['cart_item_id'] ?? item['id'],
        'product_id': item['product_id'] ?? product['id'],
        'quantity': item['quantity'] ?? 1,
        'price': item['price'] ?? product['regular_price'] ?? 0,
        'product': product,
        'variation_id': option['variation_id'],
        'variation_name': option['variation_name'],
        'selected_image': option['selected_image'] ?? product['image'],
        'weight': option['weight'] ?? product['weight'],
      };
    }).toList();
  }

  double _weightFromOrder(Map<String, dynamic> order) {
    return _cartItemsFromOrder(order).fold<double>(0, (sum, item) {
      final qty = _num(item['quantity']);
      final weight = _num(item['weight']);
      return sum + ((weight <= 0 ? 1000 : weight) * qty);
    });
  }

  void _openOrder(Map<String, dynamic> order) {
    final status = _status(order);
    if (status == 'pending_payment' || status == 'paid_not_checked_out') {
      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (_) => CheckoutScreen(
            totalAmount: _num(order['subtotal']).toDouble(),
            totalWeight: _weightFromOrder(order),
            cartItems: _cartItemsFromOrder(order),
          ),
        ),
      ).then((_) => _refresh());
      return;
    }

    Navigator.push(context, MaterialPageRoute(builder: (_) => OrderConfirmationScreen(order: order))).then((_) => _refresh());
  }

  List<dynamic> _filterOrders(List<dynamic> orders) {
    if (_selectedStatus == 'all') return orders;
    return orders.where((order) => _status(order) == _selectedStatus).toList();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: _pageBg,
      appBar: AppBar(
        title: const Text('Riwayat Pesanan', style: TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.w800)),
        backgroundColor: _navy,
        iconTheme: const IconThemeData(color: Colors.white),
      ),
      body: Column(
        children: [
          _statusTabs(),
          Expanded(
            child: RefreshIndicator(
              onRefresh: _refresh,
              child: FutureBuilder<List<dynamic>>(
                future: _ordersFuture,
                builder: (context, snapshot) {
                  if (snapshot.connectionState == ConnectionState.waiting) return const Center(child: CircularProgressIndicator(color: _navy));
                  if (snapshot.hasError) return Center(child: Text('Error: ${snapshot.error}', style: const TextStyle(fontSize: 13)));
                  final orders = _filterOrders(snapshot.data ?? []);
                  if (orders.isEmpty) return const Center(child: Text('Belum ada pesanan pada status ini.', style: TextStyle(fontSize: 13, color: Color(0xFF64748B))));

                  return ListView.builder(
                    padding: const EdgeInsets.fromLTRB(16, 12, 16, 24),
                    itemCount: orders.length,
                    itemBuilder: (context, index) => _orderCard(_map(orders[index])),
                  );
                },
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _statusTabs() {
    return Container(
      color: Colors.white,
      padding: const EdgeInsets.fromLTRB(12, 12, 12, 10),
      child: SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        child: Row(
          children: _tabs.map((tab) {
            final selected = _selectedStatus == tab['key'];
            return Padding(
              padding: const EdgeInsets.only(right: 8),
              child: ChoiceChip(
                selected: selected,
                label: Text(tab['label']!, style: TextStyle(fontSize: 12, fontWeight: FontWeight.w800, color: selected ? Colors.white : _navy)),
                selectedColor: _navy,
                backgroundColor: const Color(0xFFEAF0FF),
                side: BorderSide(color: selected ? _navy : const Color(0xFFE2E8F0)),
                onSelected: (_) => setState(() => _selectedStatus = tab['key']!),
              ),
            );
          }).toList(),
        ),
      ),
    );
  }

  Widget _orderCard(Map<String, dynamic> order) {
    final status = _status(order);
    final color = _statusColor(status);
    final items = order['items'] is List ? order['items'] as List : [];
    final firstProduct = items.isNotEmpty ? _map(_map(items.first)['product']) : <String, dynamic>{};

    return InkWell(
      onTap: () => _openOrder(order),
      borderRadius: BorderRadius.circular(16),
      child: Container(
        margin: const EdgeInsets.only(bottom: 12),
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: const Color(0xFFE2E8F0)),
          boxShadow: [BoxShadow(color: Colors.black.withOpacity(.04), blurRadius: 12, offset: const Offset(0, 5))],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(padding: const EdgeInsets.all(9), decoration: BoxDecoration(color: const Color(0xFFEAF0FF), borderRadius: BorderRadius.circular(12)), child: const Icon(Icons.receipt_long_rounded, color: _navy, size: 22)),
                const SizedBox(width: 10),
                Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                  Text('#ORDER-${order['id']}', style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w900, color: Color(0xFF111827))),
                  Text(order['created_at']?.toString().substring(0, 10) ?? '-', style: const TextStyle(fontSize: 11, color: Color(0xFF64748B))),
                ])),
                Container(padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 5), decoration: BoxDecoration(color: color.withOpacity(.12), borderRadius: BorderRadius.circular(20)), child: Text(_label(order), style: TextStyle(fontSize: 10.5, color: color, fontWeight: FontWeight.w900))),
              ],
            ),
            const SizedBox(height: 12),
            Text(firstProduct['name']?.toString() ?? '${items.length} item produk', maxLines: 1, overflow: TextOverflow.ellipsis, style: const TextStyle(fontSize: 12.5, color: Color(0xFF111827), fontWeight: FontWeight.w700)),
            const SizedBox(height: 5),
            Text('${items.length} item • ${order['mode_pengiriman'] ?? '-'} ${order['jenis_pengiriman'] ?? ''}', style: const TextStyle(fontSize: 11.5, color: Color(0xFF64748B))),
            if (status == 'pending_payment') ...[
              const SizedBox(height: 8),
              Container(width: double.infinity, padding: const EdgeInsets.all(10), decoration: BoxDecoration(color: const Color(0xFFFFFBEB), borderRadius: BorderRadius.circular(12), border: Border.all(color: const Color(0xFFFDE68A))), child: Text(_timerText(order), style: const TextStyle(fontSize: 11.5, color: Color(0xFF92400E), fontWeight: FontWeight.w800))),
            ],
            const Divider(height: 24),
            Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
              const Text('Total Order', style: TextStyle(fontSize: 12, color: Color(0xFF64748B))),
              Text(_money(order['total']), style: const TextStyle(fontSize: 15, color: _navy, fontWeight: FontWeight.w900)),
            ]),
          ],
        ),
      ),
    );
  }
}

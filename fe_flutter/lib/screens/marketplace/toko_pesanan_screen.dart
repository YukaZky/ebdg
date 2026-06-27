import 'dart:convert';
import 'package:flutter/material.dart';
import '../../services/marketplace_api_service.dart';

class TokoPesananScreen extends StatefulWidget {
  const TokoPesananScreen({Key? key}) : super(key: key);

  @override
  State<TokoPesananScreen> createState() => _TokoPesananScreenState();
}

class _TokoPesananScreenState extends State<TokoPesananScreen> {
  static const Color _navy = Color(0xFF0B1F3A);
  static const Color _softBlue = Color(0xFFEAF1FF);

  List<dynamic> orders = [];
  bool loading = true;
  String selectedStatus = 'paid';

  final filters = const [
    {'key': 'paid', 'label': 'Dibayar', 'icon': Icons.verified_outlined},
    {'key': 'packing', 'label': 'Dikemas', 'icon': Icons.inventory_2_outlined},
    {'key': 'delivered', 'label': 'Dikirim', 'icon': Icons.local_shipping_outlined},
    {'key': 'done', 'label': 'Selesai', 'icon': Icons.task_alt_rounded},
    {'key': 'canceled', 'label': 'Dibatalkan', 'icon': Icons.cancel_outlined},
  ];

  @override
  void initState() {
    super.initState();
    loadOrders();
  }

  Future<void> loadOrders() async {
    setState(() => loading = true);
    final result = await MarketplaceApiService.sellerOrders();
    if (!mounted) return;
    setState(() {
      orders = result;
      loading = false;
    });
  }

  String _statusKey(dynamic order) {
    final raw = (order['seller_status'] ?? order['frontend_status'] ?? order['status'])?.toString().toLowerCase() ?? 'paid';
    if (raw == 'ordered') return 'paid';
    if (raw == 'processing' || raw == 'shipped') return 'packing';
    if (raw == 'completed' || raw == 'complete' || raw == 'selesai') return 'done';
    if (raw == 'cancelled') return 'canceled';
    return raw;
  }

  String _labelStatus(dynamic status) {
    switch (status?.toString().toLowerCase()) {
      case 'paid':
      case 'ordered': return 'Dibayar';
      case 'packing':
      case 'processing':
      case 'shipped': return 'Dikemas';
      case 'delivered': return 'Dikirim';
      case 'done':
      case 'completed':
      case 'complete': return 'Selesai';
      case 'canceled':
      case 'cancelled': return 'Dibatalkan';
      default: return status?.toString() ?? '-';
    }
  }

  String _currency(dynamic value) {
    final number = double.tryParse(value?.toString() ?? '0') ?? 0;
    final text = number.toStringAsFixed(0);
    final buffer = StringBuffer();
    for (int i = 0; i < text.length; i++) {
      final reverseIndex = text.length - i;
      buffer.write(text[i]);
      if (reverseIndex > 1 && reverseIndex % 3 == 1) buffer.write('.');
    }
    return 'Rp ${buffer.toString()}';
  }

  Map<String, dynamic> _map(dynamic value) {
    if (value is Map<String, dynamic>) return value;
    if (value is Map) return Map<String, dynamic>.from(value);
    return <String, dynamic>{};
  }

  Map<String, dynamic> _details(dynamic order) {
    final raw = _map(order['transaction'])['payment_details'];
    if (raw is Map) return Map<String, dynamic>.from(raw);
    if (raw is String && raw.isNotEmpty) {
      try {
        final decoded = jsonDecode(raw);
        if (decoded is Map) return Map<String, dynamic>.from(decoded);
      } catch (_) {}
    }
    return <String, dynamic>{};
  }

  int _sellerId(dynamic order) {
    final items = order['items'] as List? ?? [];
    for (final item in items) {
      final id = int.tryParse((_map(item is Map ? item['product'] : null)['user_id'] ?? '').toString()) ?? 0;
      if (id > 0) return id;
    }
    return 0;
  }

  double _sellerDiscount(dynamic order) {
    final coupon = _map(_details(order)['coupon']);
    final couponSellerId = int.tryParse((coupon['seller_id'] ?? '').toString()) ?? 0;
    if (couponSellerId <= 0 || couponSellerId != _sellerId(order)) return 0;
    return double.tryParse((coupon['amount'] ?? 0).toString()) ?? 0;
  }

  double _sellerSubtotal(dynamic order) => double.tryParse((order['seller_total'] ?? order['total'] ?? 0).toString()) ?? 0;
  double _sellerNet(dynamic order) => (_sellerSubtotal(order) - _sellerDiscount(order)).clamp(0, double.infinity).toDouble();

  Future<void> updateStatus(int orderId, String status) async {
    final ok = await MarketplaceApiService.updateOrderStatus(orderId, status);
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(ok ? 'Status pesanan berhasil diperbarui' : 'Gagal memperbarui status pesanan')));
    if (ok) {
      setState(() => selectedStatus = status);
      loadOrders();
    }
  }

  Widget _filterBar() => Container(
    color: Colors.white,
    padding: const EdgeInsets.fromLTRB(12, 12, 12, 10),
    child: SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: Row(children: filters.map((filter) {
        final key = filter['key'] as String;
        final active = selectedStatus == key;
        final count = orders.where((order) => _statusKey(order) == key).length;
        return Padding(
          padding: const EdgeInsets.only(right: 10),
          child: InkWell(
            onTap: () => setState(() => selectedStatus = key),
            borderRadius: BorderRadius.circular(16),
            child: Container(
              width: 126,
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(color: active ? _navy : _softBlue, borderRadius: BorderRadius.circular(16)),
              child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                Row(children: [Icon(filter['icon'] as IconData, size: 19, color: active ? Colors.white : _navy), const Spacer(), Text('$count', style: TextStyle(color: active ? Colors.white : _navy, fontWeight: FontWeight.w900))]),
                const SizedBox(height: 8),
                Text(filter['label'] as String, style: TextStyle(fontSize: 12, fontWeight: FontWeight.w900, color: active ? Colors.white : _navy)),
              ]),
            ),
          ),
        );
      }).toList()),
    ),
  );

  Widget _orderCard(dynamic order) {
    final status = _statusKey(order);
    final items = order['items'] as List? ?? [];
    final orderId = int.tryParse(order['id']?.toString() ?? '0') ?? 0;
    final discount = _sellerDiscount(order);
    return InkWell(
      onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => TokoPesananDetailScreen(order: order))).then((_) => loadOrders()),
      child: Container(
        margin: const EdgeInsets.only(bottom: 14),
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(18), border: Border.all(color: const Color(0xFFE5EAF3))),
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Row(children: [Expanded(child: Text('Pesanan #$orderId', style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w800, color: _navy))), Text(_labelStatus(status), style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w800, color: _navy))]),
          const SizedBox(height: 8),
          Text('${items.length} produk • ${order['name'] ?? '-'}', style: TextStyle(fontSize: 12, color: Colors.grey.shade700)),
          const SizedBox(height: 6),
          if (discount > 0) Text('Potongan kupon: -${_currency(discount)}', style: const TextStyle(fontSize: 12, color: Color(0xFF15803D), fontWeight: FontWeight.w800)),
          Text('Total toko: ${_currency(_sellerNet(order))}', style: const TextStyle(fontSize: 13, color: _navy, fontWeight: FontWeight.w900)),
          if (status == 'paid') ElevatedButton(onPressed: () => updateStatus(orderId, 'packing'), child: const Text('Jadikan Dikemas')),
          if (status == 'packing') ElevatedButton(onPressed: () => updateStatus(orderId, 'delivered'), child: const Text('Jadikan Dikirim')),
          if (status == 'delivered') ElevatedButton(onPressed: () => updateStatus(orderId, 'done'), child: const Text('Jadikan Selesai')),
        ]),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final filtered = orders.where((order) => _statusKey(order) == selectedStatus).toList();
    return Scaffold(
      backgroundColor: const Color(0xFFF4F7FB),
      appBar: AppBar(title: const Text('Pesanan Toko'), backgroundColor: _navy, foregroundColor: Colors.white),
      body: Column(children: [_filterBar(), Expanded(child: loading ? const Center(child: CircularProgressIndicator()) : RefreshIndicator(onRefresh: loadOrders, child: filtered.isEmpty ? ListView(padding: const EdgeInsets.all(24), children: [const SizedBox(height: 120), Center(child: Text('Belum ada pesanan ${_labelStatus(selectedStatus).toLowerCase()}'))]) : ListView.builder(padding: const EdgeInsets.all(16), itemCount: filtered.length, itemBuilder: (context, index) => _orderCard(filtered[index]))))]),
    );
  }
}

class TokoPesananDetailScreen extends StatelessWidget {
  static const Color _navy = Color(0xFF0B1F3A);
  static const Color _softBlue = Color(0xFFEAF1FF);
  final dynamic order;
  const TokoPesananDetailScreen({Key? key, required this.order}) : super(key: key);

  String _currency(dynamic value) {
    final number = double.tryParse(value?.toString() ?? '0') ?? 0;
    return 'Rp ${number.toStringAsFixed(0)}';
  }

  Map<String, dynamic> _map(dynamic value) {
    if (value is Map<String, dynamic>) return value;
    if (value is Map) return Map<String, dynamic>.from(value);
    return <String, dynamic>{};
  }

  Map<String, dynamic> _details() {
    final raw = _map(order['transaction'])['payment_details'];
    if (raw is Map) return Map<String, dynamic>.from(raw);
    if (raw is String && raw.isNotEmpty) {
      try {
        final decoded = jsonDecode(raw);
        if (decoded is Map) return Map<String, dynamic>.from(decoded);
      } catch (_) {}
    }
    return <String, dynamic>{};
  }

  int _sellerId() {
    final items = order['items'] as List? ?? [];
    for (final item in items) {
      final id = int.tryParse((_map(item is Map ? item['product'] : null)['user_id'] ?? '').toString()) ?? 0;
      if (id > 0) return id;
    }
    return 0;
  }

  double _sellerDiscount() {
    final coupon = _map(_details()['coupon']);
    final couponSellerId = int.tryParse((coupon['seller_id'] ?? '').toString()) ?? 0;
    if (couponSellerId <= 0 || couponSellerId != _sellerId()) return 0;
    return double.tryParse((coupon['amount'] ?? 0).toString()) ?? 0;
  }

  String _couponText() {
    final coupon = _map(_details()['coupon']);
    if (coupon.isEmpty) return '-';
    return '${coupon['coupon_code'] ?? '-'} • ${coupon['coupon_name'] ?? 'Kupon'}';
  }

  Widget _section(String title, List<Widget> children) => Container(width: double.infinity, margin: const EdgeInsets.only(bottom: 14), padding: const EdgeInsets.all(14), decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(18), border: Border.all(color: const Color(0xFFE5EAF3))), child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [Text(title, style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w800, color: _navy)), const SizedBox(height: 10), ...children]));
  Widget _row(String label, dynamic value, {Color? color}) => Padding(padding: const EdgeInsets.only(bottom: 8), child: Row(crossAxisAlignment: CrossAxisAlignment.start, children: [SizedBox(width: 118, child: Text(label, style: TextStyle(fontSize: 12, color: Colors.grey.shade600))), Expanded(child: Text(value?.toString() ?? '-', style: TextStyle(fontSize: 12, fontWeight: FontWeight.w700, color: color ?? Colors.black87)))]));

  @override
  Widget build(BuildContext context) {
    final items = order['items'] as List? ?? [];
    final sellerSubtotal = double.tryParse((order['seller_total'] ?? order['total'] ?? 0).toString()) ?? 0;
    final discount = _sellerDiscount();
    final total = (sellerSubtotal - discount).clamp(0, double.infinity);
    return Scaffold(
      backgroundColor: const Color(0xFFF4F7FB),
      appBar: AppBar(title: const Text('Detail Pesanan'), backgroundColor: _navy, foregroundColor: Colors.white),
      body: ListView(padding: const EdgeInsets.all(16), children: [
        _section('Informasi Pembeli', [_row('Nama', order['name']), _row('No HP', order['phone']), _row('Alamat', order['address']), _row('Kota', order['city']), _row('Provinsi', order['state'])]),
        _section('Informasi Pembayaran', [_row('Status transaksi', order['transaction_status']), _row('Payment ID', order['payment_transaction_id']), _row('Metode', order['payment_type']), _row('Bank', order['payment_bank'] ?? '-')]),
        _section('Produk Toko Ini', [
          ...items.map((item) { final product = item['product'] as Map? ?? {}; final lineTotal = item['line_total'] ?? ((double.tryParse(item['price']?.toString() ?? '0') ?? 0) * (int.tryParse(item['quantity']?.toString() ?? '1') ?? 1)); return Container(margin: const EdgeInsets.only(bottom: 10), padding: const EdgeInsets.all(10), decoration: BoxDecoration(color: _softBlue.withOpacity(0.55), borderRadius: BorderRadius.circular(12)), child: Row(children: [Expanded(child: Text(product['name']?.toString() ?? 'Produk', style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w800, color: _navy))), Text(_currency(lineTotal), style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w900, color: _navy))])); }),
          const Divider(height: 18),
          _row('Subtotal toko', _currency(sellerSubtotal)),
          if (discount > 0) ...[_row('Kupon', _couponText()), _row('Potongan', '-${_currency(discount)}', color: const Color(0xFF15803D))],
          _row('Total toko', _currency(total), color: _navy),
        ]),
      ]),
    );
  }
}

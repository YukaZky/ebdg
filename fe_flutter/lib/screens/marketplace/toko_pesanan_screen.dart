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

  final List<Map<String, dynamic>> _filters = const [
    {'key': 'paid', 'label': 'Dibayar', 'icon': Icons.verified_outlined},
    {'key': 'packing', 'label': 'Dikemas', 'icon': Icons.inventory_2_outlined},
    {'key': 'delivered', 'label': 'Dikirim', 'icon': Icons.local_shipping_outlined},
    {'key': 'done', 'label': 'Selesai', 'icon': Icons.task_alt_rounded},
    {'key': 'canceled', 'label': 'Dibatalkan', 'icon': Icons.cancel_outlined},
  ];

  List<dynamic> orders = [];
  bool loading = true;
  String selectedStatus = 'paid';

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

  Future<void> updateStatus(int orderId, String status) async {
    final label = _labelStatus(status);
    final confirm = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        title: Text('Ubah ke $label?'),
        content: const Text('Status pesanan akan diperbarui dan pindah ke kartu status berikutnya.'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context, false), child: const Text('Batal')),
          ElevatedButton(onPressed: () => Navigator.pop(context, true), style: ElevatedButton.styleFrom(backgroundColor: _navy, foregroundColor: Colors.white), child: const Text('Update')),
        ],
      ),
    );

    if (confirm != true) return;
    final ok = await MarketplaceApiService.updateOrderStatus(orderId, status);
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(ok ? 'Status pesanan berhasil diperbarui' : 'Gagal memperbarui status pesanan')));
    if (ok) {
      setState(() => selectedStatus = status);
      loadOrders();
    }
  }

  List<dynamic> get _filteredOrders => orders.where((order) => _statusKey(order) == selectedStatus).toList();
  int _countByStatus(String status) => orders.where((order) => _statusKey(order) == status).length;

  String _statusKey(dynamic order) {
    final status = order['seller_status'] ?? order['frontend_status'] ?? order['status'];
    final raw = status?.toString().toLowerCase() ?? 'paid';
    if (raw == 'ordered') return 'paid';
    if (raw == 'processing' || raw == 'shipped') return 'packing';
    if (raw == 'completed' || raw == 'complete' || raw == 'selesai') return 'done';
    if (raw == 'cancelled') return 'canceled';
    return raw;
  }

  String _labelStatus(dynamic status) {
    switch (status?.toString().toLowerCase()) {
      case 'paid':
      case 'ordered':
        return 'Dibayar';
      case 'packing':
      case 'processing':
      case 'shipped':
        return 'Dikemas';
      case 'delivered':
        return 'Dikirim';
      case 'done':
      case 'completed':
      case 'complete':
        return 'Selesai';
      case 'canceled':
      case 'cancelled':
        return 'Dibatalkan';
      default:
        return status?.toString() ?? '-';
    }
  }

  Color _statusColor(dynamic status) {
    switch (_statusKey({'status': status})) {
      case 'paid':
        return const Color(0xFF0B63CE);
      case 'packing':
        return const Color(0xFF7C3AED);
      case 'delivered':
        return const Color(0xFF0F766E);
      case 'done':
        return const Color(0xFF15803D);
      case 'canceled':
        return const Color(0xFFB91C1C);
      default:
        return Colors.grey;
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

  dynamic _total(dynamic order) => order['seller_total'] ?? order['total'] ?? 0;
  int _orderId(dynamic order) => int.tryParse(order['id']?.toString() ?? '0') ?? 0;

  void _openDetail(dynamic order) async {
    await Navigator.push(context, MaterialPageRoute(builder: (_) => TokoPesananDetailScreen(order: order)));
    if (mounted) loadOrders();
  }

  Widget _countBadge(int count, bool active) {
    return Container(
      constraints: const BoxConstraints(minWidth: 24),
      padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 3),
      decoration: BoxDecoration(color: active ? Colors.white : _navy, borderRadius: BorderRadius.circular(99)),
      child: Text('$count', textAlign: TextAlign.center, style: TextStyle(fontSize: 11, fontWeight: FontWeight.w900, color: active ? _navy : Colors.white)),
    );
  }

  Widget _filterBar() {
    return Container(
      color: Colors.white,
      padding: const EdgeInsets.fromLTRB(12, 12, 12, 10),
      child: SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        child: Row(children: _filters.map((filter) {
          final key = filter['key'] as String;
          final active = selectedStatus == key;
          final count = _countByStatus(key);
          return Padding(
            padding: const EdgeInsets.only(right: 10),
            child: InkWell(
              onTap: () => setState(() => selectedStatus = key),
              borderRadius: BorderRadius.circular(16),
              child: Container(
                width: 126,
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(color: active ? _navy : _softBlue, borderRadius: BorderRadius.circular(16), border: Border.all(color: active ? _navy : const Color(0xFFDCE7FF))),
                child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                  Row(children: [
                    Icon(filter['icon'] as IconData, size: 19, color: active ? Colors.white : _navy),
                    const Spacer(),
                    _countBadge(count, active),
                  ]),
                  const SizedBox(height: 9),
                  Text(filter['label'] as String, style: TextStyle(fontSize: 12, fontWeight: FontWeight.w900, color: active ? Colors.white : _navy)),
                  Text('Ketuk untuk buka', style: TextStyle(fontSize: 10.5, color: active ? Colors.white70 : Colors.grey.shade700)),
                ]),
              ),
            ),
          );
        }).toList()),
      ),
    );
  }

  Widget _actionButton(dynamic order) {
    final status = _statusKey(order);
    final orderId = _orderId(order);
    if (status == 'paid') return _button('Jadikan Dikemas', Icons.inventory_2_outlined, _navy, () => updateStatus(orderId, 'packing'));
    if (status == 'packing') return _button('Jadikan Dikirim', Icons.local_shipping_outlined, const Color(0xFF0F766E), () => updateStatus(orderId, 'delivered'));
    if (status == 'delivered') return _button('Jadikan Selesai', Icons.task_alt_rounded, const Color(0xFF15803D), () => updateStatus(orderId, 'done'));
    return const SizedBox.shrink();
  }

  Widget _button(String text, IconData icon, Color color, VoidCallback onTap) => ElevatedButton.icon(
        onPressed: onTap,
        icon: Icon(icon, size: 17),
        label: Text(text),
        style: ElevatedButton.styleFrom(backgroundColor: color, foregroundColor: Colors.white, minimumSize: const Size.fromHeight(42), shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12))),
      );

  Widget _orderCard(dynamic order) {
    final status = _statusKey(order);
    final items = order['items'] as List? ?? [];
    final orderId = _orderId(order);
    final hasAction = status == 'paid' || status == 'packing' || status == 'delivered';
    return InkWell(
      onTap: () => _openDetail(order),
      borderRadius: BorderRadius.circular(18),
      child: Container(
        margin: const EdgeInsets.only(bottom: 14),
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(18), border: Border.all(color: const Color(0xFFE5EAF3)), boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.04), blurRadius: 12, offset: const Offset(0, 6))]),
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Row(children: [
            Container(width: 42, height: 42, decoration: BoxDecoration(color: _softBlue, borderRadius: BorderRadius.circular(13)), child: Icon(status == 'packing' ? Icons.inventory_2_outlined : status == 'delivered' ? Icons.local_shipping_outlined : status == 'done' ? Icons.task_alt_rounded : Icons.receipt_long_outlined, color: _navy)),
            const SizedBox(width: 10),
            Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Text('Pesanan #$orderId', style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w800, color: _navy)),
              const SizedBox(height: 2),
              Text('${items.length} produk • ${order['seller_item_count'] ?? items.length} item', style: TextStyle(fontSize: 12, color: Colors.grey.shade600)),
            ])),
            Container(padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6), decoration: BoxDecoration(color: _statusColor(status).withOpacity(0.12), borderRadius: BorderRadius.circular(999)), child: Text(_labelStatus(status), style: TextStyle(color: _statusColor(status), fontSize: 11, fontWeight: FontWeight.w800))),
          ]),
          const SizedBox(height: 12),
          _miniRow(Icons.person_outline, 'Pembeli', order['name'] ?? '-'),
          _miniRow(Icons.phone_outlined, 'No HP', order['phone'] ?? '-'),
          _miniRow(Icons.payments_outlined, 'Total toko', _currency(_total(order))),
          if (items.isNotEmpty) ...[
            const SizedBox(height: 10),
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(color: const Color(0xFFF8FAFC), borderRadius: BorderRadius.circular(12)),
              child: Column(children: items.take(2).map((item) {
                final product = item['product'] as Map? ?? {};
                return Padding(padding: const EdgeInsets.only(bottom: 6), child: Row(children: [Expanded(child: Text(product['name']?.toString() ?? 'Produk', style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600))), Text('x${item['quantity'] ?? 1}', style: TextStyle(fontSize: 12, color: Colors.grey.shade700))]));
              }).toList()),
            ),
          ],
          if (hasAction) ...[const SizedBox(height: 12), _actionButton(order)],
        ]),
      ),
    );
  }

  Widget _miniRow(IconData icon, String label, dynamic value) => Padding(
        padding: const EdgeInsets.only(bottom: 6),
        child: Row(children: [Icon(icon, size: 16, color: Colors.grey.shade600), const SizedBox(width: 8), SizedBox(width: 82, child: Text(label, style: TextStyle(fontSize: 12, color: Colors.grey.shade600))), Expanded(child: Text(value?.toString() ?? '-', style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w700)))]),
      );

  @override
  Widget build(BuildContext context) {
    final filtered = _filteredOrders;
    return Scaffold(
      backgroundColor: const Color(0xFFF4F7FB),
      appBar: AppBar(title: const Text('Pesanan Toko', style: TextStyle(fontWeight: FontWeight.w800)), backgroundColor: _navy, foregroundColor: Colors.white, elevation: 0),
      body: Column(children: [
        _filterBar(),
        Expanded(child: loading ? const Center(child: CircularProgressIndicator()) : RefreshIndicator(
          onRefresh: loadOrders,
          child: filtered.isEmpty
              ? ListView(padding: const EdgeInsets.all(24), children: [const SizedBox(height: 120), Icon(Icons.receipt_long_outlined, size: 72, color: Colors.grey.shade400), const SizedBox(height: 12), Center(child: Text('Belum ada pesanan ${_labelStatus(selectedStatus).toLowerCase()}.', style: TextStyle(color: Colors.grey.shade700)))])
              : ListView.builder(padding: const EdgeInsets.all(16), itemCount: filtered.length, itemBuilder: (context, index) => _orderCard(filtered[index])),
        )),
      ]),
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
    final text = number.toStringAsFixed(0);
    final buffer = StringBuffer();
    for (int i = 0; i < text.length; i++) {
      final reverseIndex = text.length - i;
      buffer.write(text[i]);
      if (reverseIndex > 1 && reverseIndex % 3 == 1) buffer.write('.');
    }
    return 'Rp ${buffer.toString()}';
  }

  String _statusLabel(dynamic status) {
    switch (status?.toString().toLowerCase()) {
      case 'paid':
      case 'ordered':
        return 'Dibayar';
      case 'packing':
      case 'processing':
      case 'shipped':
        return 'Dikemas';
      case 'delivered':
        return 'Dikirim';
      case 'done':
      case 'completed':
      case 'complete':
        return 'Selesai';
      case 'canceled':
      case 'cancelled':
        return 'Dibatalkan';
      default:
        return status?.toString() ?? '-';
    }
  }

  Widget _section(String title, List<Widget> children) => Container(width: double.infinity, margin: const EdgeInsets.only(bottom: 14), padding: const EdgeInsets.all(14), decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(18), border: Border.all(color: const Color(0xFFE5EAF3)), boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.035), blurRadius: 12, offset: const Offset(0, 6))]), child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [Text(title, style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w800, color: _navy)), const SizedBox(height: 10), ...children]));
  Widget _row(String label, dynamic value) => Padding(padding: const EdgeInsets.only(bottom: 8), child: Row(crossAxisAlignment: CrossAxisAlignment.start, children: [SizedBox(width: 112, child: Text(label, style: TextStyle(fontSize: 12, color: Colors.grey.shade600))), Expanded(child: Text(value?.toString() ?? '-', style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w700)))]));

  @override
  Widget build(BuildContext context) {
    final items = order['items'] as List? ?? [];
    final paymentInfo = order['payment_info'] as Map?;
    final status = order['seller_status'] ?? order['status'];
    return Scaffold(
      backgroundColor: const Color(0xFFF4F7FB),
      appBar: AppBar(title: const Text('Detail Pesanan', style: TextStyle(fontWeight: FontWeight.w800)), backgroundColor: _navy, foregroundColor: Colors.white, elevation: 0),
      body: ListView(padding: const EdgeInsets.all(16), children: [
        Container(padding: const EdgeInsets.all(16), decoration: BoxDecoration(gradient: const LinearGradient(colors: [_navy, Color(0xFF123B6D)]), borderRadius: BorderRadius.circular(20)), child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [Text('Pesanan #${order['id'] ?? '-'}', style: const TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.w900)), const SizedBox(height: 8), Container(padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6), decoration: BoxDecoration(color: Colors.white.withOpacity(0.15), borderRadius: BorderRadius.circular(999)), child: Text(_statusLabel(status), style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w800, fontSize: 12)))])),
        const SizedBox(height: 14),
        _section('Informasi Pembeli', [_row('Nama', order['name']), _row('No HP', order['phone']), _row('Alamat', order['address']), _row('Kota', order['city']), _row('Provinsi', order['state'])]),
        _section('Informasi Pembayaran', [_row('Status transaksi', order['transaction_status']), _row('Payment ID', order['payment_transaction_id'] ?? paymentInfo?['transaction_id']), _row('Metode', order['payment_type'] ?? paymentInfo?['payment_type']), _row('Bank', order['payment_bank'] ?? '-')]),
        _section('Produk Toko Ini', [
          ...items.map((item) {
            final product = item['product'] as Map? ?? {};
            final lineTotal = item['line_total'] ?? ((double.tryParse(item['price']?.toString() ?? '0') ?? 0) * (int.tryParse(item['quantity']?.toString() ?? '1') ?? 1));
            return Container(margin: const EdgeInsets.only(bottom: 10), padding: const EdgeInsets.all(10), decoration: BoxDecoration(color: _softBlue.withOpacity(0.55), borderRadius: BorderRadius.circular(12)), child: Row(children: [Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [Text(product['name']?.toString() ?? 'Produk', style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w800, color: _navy)), const SizedBox(height: 4), Text('${_currency(item['price'])} x ${item['quantity'] ?? 1}', style: TextStyle(fontSize: 12, color: Colors.grey.shade700))])), Text(_currency(lineTotal), style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w900, color: _navy))]));
          }).toList(),
          const Divider(height: 18), _row('Total toko', _currency(order['seller_total'] ?? order['total'] ?? 0)),
        ]),
      ]),
    );
  }
}

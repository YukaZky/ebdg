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

  final List<Map<String, String>> _filters = const [
    {'key': 'paid', 'label': 'Dibayar'},
    {'key': 'packing', 'label': 'Packing'},
    {'key': 'delivered', 'label': 'Delivered'},
    {'key': 'done', 'label': 'Done'},
    {'key': 'canceled', 'label': 'Canceled'},
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
        content: const Text('Status pesanan akan diperbarui dan tampil di tab status berikutnya.'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context, false), child: const Text('Batal')),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            style: ElevatedButton.styleFrom(backgroundColor: _navy, foregroundColor: Colors.white),
            child: const Text('Update'),
          ),
        ],
      ),
    );

    if (confirm != true) return;

    final ok = await MarketplaceApiService.updateOrderStatus(orderId, status);
    if (!mounted) return;

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(ok ? 'Status pesanan berhasil diperbarui' : 'Gagal memperbarui status pesanan')),
    );

    if (ok) {
      setState(() => selectedStatus = status == 'delivered' ? 'delivered' : status);
      loadOrders();
    }
  }

  List<dynamic> get _filteredOrders {
    return orders.where((order) => _statusKey(order) == selectedStatus).toList();
  }

  int _countByStatus(String status) {
    return orders.where((order) => _statusKey(order) == status).length;
  }

  String _statusKey(dynamic order) {
    final status = order['seller_status'] ?? order['frontend_status'] ?? order['status'];
    final raw = status?.toString().toLowerCase() ?? 'paid';
    if (raw == 'ordered') return 'paid';
    if (raw == 'processing' || raw == 'shipped') return 'packing';
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
        return 'Packing';
      case 'delivered':
        return 'Delivered';
      case 'done':
      case 'completed':
        return 'Done';
      case 'canceled':
      case 'cancelled':
        return 'Canceled';
      default:
        return status?.toString() ?? '-';
    }
  }

  Color _statusColor(dynamic status) {
    switch (status?.toString().toLowerCase()) {
      case 'paid':
      case 'ordered':
        return const Color(0xFF0B63CE);
      case 'packing':
      case 'processing':
      case 'shipped':
        return const Color(0xFF7C3AED);
      case 'delivered':
        return const Color(0xFF0F766E);
      case 'done':
      case 'completed':
        return const Color(0xFF15803D);
      case 'canceled':
      case 'cancelled':
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

  dynamic _total(dynamic order) {
    return order['seller_total'] ?? order['total'] ?? 0;
  }

  int _orderId(dynamic order) {
    return int.tryParse(order['id']?.toString() ?? '0') ?? 0;
  }

  void _openDetail(dynamic order) async {
    await Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => TokoPesananDetailScreen(order: order)),
    );
    if (mounted) loadOrders();
  }

  Widget _filterBar() {
    return Container(
      color: Colors.white,
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 10),
      child: SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        child: Row(
          children: _filters.map((filter) {
            final key = filter['key']!;
            final active = selectedStatus == key;
            final count = _countByStatus(key);
            return Padding(
              padding: const EdgeInsets.only(right: 8),
              child: ChoiceChip(
                selected: active,
                label: Text('${filter['label']} ($count)'),
                selectedColor: _navy,
                backgroundColor: _softBlue,
                labelStyle: TextStyle(
                  color: active ? Colors.white : _navy,
                  fontWeight: FontWeight.w700,
                  fontSize: 12,
                ),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(999)),
                onSelected: (_) => setState(() => selectedStatus = key),
              ),
            );
          }).toList(),
        ),
      ),
    );
  }

  Widget _actionButton(dynamic order) {
    final status = _statusKey(order);
    final orderId = _orderId(order);

    if (status == 'paid') {
      return ElevatedButton.icon(
        onPressed: () => updateStatus(orderId, 'packing'),
        icon: const Icon(Icons.inventory_2_outlined, size: 17),
        label: const Text('Jadikan Packing'),
        style: ElevatedButton.styleFrom(
          backgroundColor: _navy,
          foregroundColor: Colors.white,
          minimumSize: const Size.fromHeight(42),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        ),
      );
    }

    if (status == 'packing') {
      return ElevatedButton.icon(
        onPressed: () => updateStatus(orderId, 'delivered'),
        icon: const Icon(Icons.local_shipping_outlined, size: 17),
        label: const Text('Jadikan Delivered'),
        style: ElevatedButton.styleFrom(
          backgroundColor: const Color(0xFF0F766E),
          foregroundColor: Colors.white,
          minimumSize: const Size.fromHeight(42),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        ),
      );
    }

    return const SizedBox.shrink();
  }

  Widget _orderCard(dynamic order) {
    final status = _statusKey(order);
    final items = order['items'] as List? ?? [];
    final orderId = _orderId(order);
    final hasAction = status == 'paid' || status == 'packing';

    return InkWell(
      onTap: () => _openDetail(order),
      borderRadius: BorderRadius.circular(18),
      child: Container(
        margin: const EdgeInsets.only(bottom: 14),
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(18),
          border: Border.all(color: const Color(0xFFE5EAF3)),
          boxShadow: [
            BoxShadow(color: Colors.black.withOpacity(0.04), blurRadius: 12, offset: const Offset(0, 6)),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  width: 42,
                  height: 42,
                  decoration: BoxDecoration(color: _softBlue, borderRadius: BorderRadius.circular(13)),
                  child: const Icon(Icons.receipt_long_outlined, color: _navy),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('Pesanan #$orderId', style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w800, color: _navy)),
                      const SizedBox(height: 2),
                      Text('${items.length} produk • ${order['seller_item_count'] ?? items.length} item', style: TextStyle(fontSize: 12, color: Colors.grey.shade600)),
                    ],
                  ),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                  decoration: BoxDecoration(color: _statusColor(status).withOpacity(0.12), borderRadius: BorderRadius.circular(999)),
                  child: Text(_labelStatus(status), style: TextStyle(color: _statusColor(status), fontSize: 11, fontWeight: FontWeight.w800)),
                ),
              ],
            ),
            const SizedBox(height: 12),
            _miniRow(Icons.person_outline, 'Pembeli', order['name'] ?? '-'),
            _miniRow(Icons.phone_outlined, 'No HP', order['phone'] ?? '-'),
            _miniRow(Icons.payments_outlined, 'Total toko', _currency(_total(order))),
            if (items.isNotEmpty) ...[
              const SizedBox(height: 10),
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(color: const Color(0xFFF8FAFC), borderRadius: BorderRadius.circular(12)),
                child: Column(
                  children: items.take(2).map((item) {
                    final product = item['product'] as Map? ?? {};
                    return Padding(
                      padding: const EdgeInsets.only(bottom: 6),
                      child: Row(
                        children: [
                          Expanded(child: Text(product['name']?.toString() ?? 'Produk', style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600))),
                          Text('x${item['quantity'] ?? 1}', style: TextStyle(fontSize: 12, color: Colors.grey.shade700)),
                        ],
                      ),
                    );
                  }).toList(),
                ),
              ),
            ],
            if (hasAction) ...[
              const SizedBox(height: 12),
              _actionButton(order),
            ],
          ],
        ),
      ),
    );
  }

  Widget _miniRow(IconData icon, String label, dynamic value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 6),
      child: Row(
        children: [
          Icon(icon, size: 16, color: Colors.grey.shade600),
          const SizedBox(width: 8),
          SizedBox(width: 82, child: Text(label, style: TextStyle(fontSize: 12, color: Colors.grey.shade600))),
          Expanded(child: Text(value?.toString() ?? '-', style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w700))),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final filtered = _filteredOrders;

    return Scaffold(
      backgroundColor: const Color(0xFFF4F7FB),
      appBar: AppBar(
        title: const Text('Pesanan Toko', style: TextStyle(fontWeight: FontWeight.w800)),
        backgroundColor: _navy,
        foregroundColor: Colors.white,
        elevation: 0,
      ),
      body: Column(
        children: [
          _filterBar(),
          Expanded(
            child: loading
                ? const Center(child: CircularProgressIndicator())
                : RefreshIndicator(
                    onRefresh: loadOrders,
                    child: filtered.isEmpty
                        ? ListView(
                            padding: const EdgeInsets.all(24),
                            children: [
                              const SizedBox(height: 120),
                              Icon(Icons.receipt_long_outlined, size: 72, color: Colors.grey.shade400),
                              const SizedBox(height: 12),
                              Center(
                                child: Text(
                                  'Belum ada pesanan ${_labelStatus(selectedStatus).toLowerCase()}.',
                                  style: TextStyle(color: Colors.grey.shade700),
                                ),
                              ),
                            ],
                          )
                        : ListView.builder(
                            padding: const EdgeInsets.all(16),
                            itemCount: filtered.length,
                            itemBuilder: (context, index) => _orderCard(filtered[index]),
                          ),
                  ),
          ),
        ],
      ),
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
        return 'Packing';
      case 'delivered':
        return 'Delivered';
      case 'done':
      case 'completed':
        return 'Done';
      case 'canceled':
      case 'cancelled':
        return 'Canceled';
      default:
        return status?.toString() ?? '-';
    }
  }

  Widget _section(String title, List<Widget> children) {
    return Container(
      width: double.infinity,
      margin: const EdgeInsets.only(bottom: 14),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: const Color(0xFFE5EAF3)),
        boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.035), blurRadius: 12, offset: const Offset(0, 6))],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(title, style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w800, color: _navy)),
          const SizedBox(height: 10),
          ...children,
        ],
      ),
    );
  }

  Widget _row(String label, dynamic value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(width: 112, child: Text(label, style: TextStyle(fontSize: 12, color: Colors.grey.shade600))),
          Expanded(child: Text(value?.toString() ?? '-', style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w700))),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final items = order['items'] as List? ?? [];
    final paymentInfo = order['payment_info'] as Map?;
    final status = order['seller_status'] ?? order['status'];

    return Scaffold(
      backgroundColor: const Color(0xFFF4F7FB),
      appBar: AppBar(
        title: const Text('Detail Pesanan', style: TextStyle(fontWeight: FontWeight.w800)),
        backgroundColor: _navy,
        foregroundColor: Colors.white,
        elevation: 0,
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              gradient: const LinearGradient(colors: [_navy, Color(0xFF123B6D)]),
              borderRadius: BorderRadius.circular(20),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Pesanan #${order['id'] ?? '-'}', style: const TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.w900)),
                const SizedBox(height: 8),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                  decoration: BoxDecoration(color: Colors.white.withOpacity(0.15), borderRadius: BorderRadius.circular(999)),
                  child: Text(_statusLabel(status), style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w800, fontSize: 12)),
                ),
              ],
            ),
          ),
          const SizedBox(height: 14),
          _section('Informasi Pembeli', [
            _row('Nama', order['name']),
            _row('No HP', order['phone']),
            _row('Alamat', order['address']),
            _row('Kota', order['city']),
            _row('Provinsi', order['state']),
          ]),
          _section('Informasi Pembayaran', [
            _row('Status transaksi', order['transaction_status']),
            _row('Payment ID', order['payment_transaction_id'] ?? paymentInfo?['transaction_id']),
            _row('Metode', order['payment_type'] ?? paymentInfo?['payment_type']),
            _row('Bank', order['payment_bank'] ?? '-'),
          ]),
          _section('Produk Toko Ini', [
            ...items.map((item) {
              final product = item['product'] as Map? ?? {};
              return Container(
                margin: const EdgeInsets.only(bottom: 10),
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(color: _softBlue.withOpacity(0.55), borderRadius: BorderRadius.circular(12)),
                child: Row(
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(product['name']?.toString() ?? 'Produk', style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w800, color: _navy)),
                          const SizedBox(height: 4),
                          Text('${_currency(item['price'])} x ${item['quantity'] ?? 1}', style: TextStyle(fontSize: 12, color: Colors.grey.shade700)),
                        ],
                      ),
                    ),
                    Text(_currency(item['line_total'] ?? ((double.tryParse(item['price']?.toString() ?? '0') ?? 0) * (int.tryParse(item['quantity']?.toString() ?? '1') ?? 1))), style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w900, color: _navy)),
                  ],
                ),
              );
            }).toList(),
            const Divider(height: 18),
            _row('Total toko', _currency(order['seller_total'] ?? order['total'] ?? 0)),
          ]),
        ],
      ),
    );
  }
}

import 'dart:convert';
import 'package:flutter/material.dart';
import 'main_screen.dart';

class OrderConfirmationScreen extends StatelessWidget {
  final Map<String, dynamic> order;

  const OrderConfirmationScreen({Key? key, required this.order}) : super(key: key);

  static const Color _navy = Color(0xFF0B1F4D);
  static const Color _pageBg = Color(0xFFF5F7FB);

  Map<String, dynamic> _map(dynamic value) {
    if (value is Map<String, dynamic>) return value;
    if (value is Map) return Map<String, dynamic>.from(value);
    return <String, dynamic>{};
  }

  List<dynamic> _list(dynamic value) => value is List ? value : [];

  Map<String, dynamic> _paymentDetails() {
    final raw = _map(order['transaction'])['payment_details'];
    if (raw is Map<String, dynamic>) return raw;
    if (raw is Map) return Map<String, dynamic>.from(raw);
    if (raw is String && raw.isNotEmpty) {
      try {
        final decoded = jsonDecode(raw);
        if (decoded is Map<String, dynamic>) return decoded;
        if (decoded is Map) return Map<String, dynamic>.from(decoded);
      } catch (_) {}
    }
    return <String, dynamic>{};
  }

  num _num(dynamic value) => value is num ? value : num.tryParse(value?.toString() ?? '') ?? 0;
  String _money(dynamic value) => 'Rp ${_num(value).toStringAsFixed(0)}';

  String _statusText() {
    final label = order['frontend_status_label']?.toString();
    if (label != null && label.isNotEmpty) return label;
    final status = order['status']?.toString().toLowerCase() ?? '';
    final trx = _map(order['transaction'])['status']?.toString() ?? '';
    if (status == 'canceled') return 'Canceled';
    if (status == 'delivered') return 'Delivered';
    if (trx == 'approved' || trx == 'settlement' || trx == 'capture') return 'Packing';
    return 'Pending Payment';
  }

  @override
  Widget build(BuildContext context) {
    final items = _list(order['items']);
    final transaction = _map(order['transaction']);
    final details = _paymentDetails();
    final paymentInfo = _map(details['payment_info']);
    final paymentId = paymentInfo['transaction_id'] ?? transaction['payment_token'] ?? '-';
    final vaNumber = paymentInfo['va_number'] ?? '-';

    return Scaffold(
      backgroundColor: _pageBg,
      appBar: AppBar(
        title: const Text('Detail Pesanan', style: TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.w800)),
        backgroundColor: _navy,
        automaticallyImplyLeading: false,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.fromLTRB(16, 16, 16, 110),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _header(paymentId.toString()),
            const SizedBox(height: 14),
            _title('Order & Transaksi'),
            _card([
              _row('Order ID', '#ORDER-${order['id'] ?? '-'}'),
              _row('Status', _statusText()),
              _row('ID Pembayaran', paymentId.toString()),
              _row('Status Transaksi', transaction['status']?.toString().toUpperCase() ?? '-'),
              _row('Metode', (details['payment_type'] ?? paymentInfo['payment_type'] ?? '-').toString().toUpperCase()),
              _row('Bank', (details['bank'] ?? '-').toString().toUpperCase()),
              if (vaNumber.toString() != '-') _row('Nomor VA', vaNumber.toString()),
            ]),
            const SizedBox(height: 14),
            _title('Pengiriman'),
            _card([
              _row('Penerima', '${order['name'] ?? '-'}'),
              _row('No HP', '${order['phone'] ?? '-'}'),
              _row('Kurir', '${order['mode_pengiriman'] ?? '-'} - ${order['jenis_pengiriman'] ?? '-'}'),
              Padding(
                padding: const EdgeInsets.only(top: 8),
                child: Text('${order['address'] ?? '-'}, ${order['city'] ?? '-'}, ${order['state'] ?? '-'}', style: const TextStyle(fontSize: 12, color: Color(0xFF475569), height: 1.4)),
              ),
            ]),
            const SizedBox(height: 14),
            _title('Daftar Barang'),
            Container(
              padding: const EdgeInsets.all(14),
              decoration: _box(),
              child: Column(
                children: [
                  ...items.map(_productRow),
                  const Divider(height: 22),
                  _priceRow('Subtotal Produk', order['subtotal']),
                  const SizedBox(height: 7),
                  _priceRow('Ongkir', order['ongkir']),
                  const Divider(height: 22),
                  _priceRow('Total Order', order['total'], strong: true),
                ],
              ),
            ),
          ],
        ),
      ),
      bottomSheet: Container(
        padding: const EdgeInsets.fromLTRB(16, 12, 16, 16),
        color: Colors.white,
        child: SafeArea(
          child: SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              onPressed: () => Navigator.pushAndRemoveUntil(context, MaterialPageRoute(builder: (_) => const MainScreen()), (_) => false),
              style: ElevatedButton.styleFrom(backgroundColor: _navy, padding: const EdgeInsets.symmetric(vertical: 13), shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12))),
              child: const Text('KEMBALI KE BERANDA', style: TextStyle(color: Colors.white, fontSize: 13, fontWeight: FontWeight.w800)),
            ),
          ),
        ),
      ),
    );
  }

  Widget _header(String paymentId) => Container(
        width: double.infinity,
        padding: const EdgeInsets.all(18),
        decoration: BoxDecoration(gradient: const LinearGradient(colors: [_navy, Color(0xFF163A73)]), borderRadius: BorderRadius.circular(18)),
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          const Icon(Icons.receipt_long_rounded, color: Colors.white, size: 34),
          const SizedBox(height: 12),
          const Text('Ringkasan Pesanan', style: TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.w900)),
          const SizedBox(height: 5),
          Text('Payment ID: $paymentId', style: const TextStyle(color: Color(0xFFCBD5E1), fontSize: 12)),
        ]),
      );

  Widget _title(String text) => Padding(padding: const EdgeInsets.only(bottom: 8), child: Text(text, style: const TextStyle(fontSize: 13, color: _navy, fontWeight: FontWeight.w900)));

  BoxDecoration _box() => BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(16), border: Border.all(color: const Color(0xFFE2E8F0)));

  Widget _card(List<Widget> children) => Container(width: double.infinity, padding: const EdgeInsets.all(14), decoration: _box(), child: Column(children: children));

  Widget _row(String label, String value) => Padding(
        padding: const EdgeInsets.symmetric(vertical: 5),
        child: Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
          SizedBox(width: 120, child: Text(label, style: const TextStyle(fontSize: 12, color: Color(0xFF64748B)))),
          Expanded(child: Text(value, textAlign: TextAlign.right, style: const TextStyle(fontSize: 12.5, color: Color(0xFF111827), fontWeight: FontWeight.w700))),
        ]),
      );

  Widget _productRow(dynamic value) {
    final item = _map(value);
    final product = _map(item['product']);
    final qty = _num(item['quantity']);
    final price = _num(item['price']);
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Row(children: [
        Expanded(child: Text('${qty.toInt()}x ${product['name'] ?? 'Produk'}', maxLines: 1, overflow: TextOverflow.ellipsis, style: const TextStyle(fontSize: 12.5, fontWeight: FontWeight.w700))),
        Text(_money(price * qty), style: const TextStyle(fontSize: 12, color: _navy, fontWeight: FontWeight.w900)),
      ]),
    );
  }

  Widget _priceRow(String label, dynamic value, {bool strong = false}) => Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label, style: TextStyle(fontSize: strong ? 14 : 12, color: strong ? _navy : const Color(0xFF64748B), fontWeight: strong ? FontWeight.w900 : FontWeight.w500)),
          Text(_money(value), style: TextStyle(fontSize: strong ? 18 : 12.5, color: strong ? _navy : const Color(0xFF111827), fontWeight: FontWeight.w900)),
        ],
      );
}

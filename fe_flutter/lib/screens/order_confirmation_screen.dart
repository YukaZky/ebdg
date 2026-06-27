import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'main_screen.dart';
import 'resume_order_checkout_screen.dart';

class OrderConfirmationScreen extends StatelessWidget {
  final Map<String, dynamic> order;

  const OrderConfirmationScreen({Key? key, required this.order}) : super(key: key);

  static const Color _primary = Color(0xFF0C2442);
  static const Color _accent = Color(0xFFF39C12);
  static const Color _purple = Color(0xFF6C4DFF);
  static const Color _surface = Color(0xFFF7F8FC);
  static const Color _muted = Color(0xFF64748B);
  static const Color _danger = Color(0xFFB91C1C);
  static const Color _dangerDark = Color(0xFF7F1D1D);

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

  String _statusKey() {
    final direct = order['frontend_status']?.toString();
    if (direct != null && direct.isNotEmpty) return direct;

    final status = order['status']?.toString().toLowerCase() ?? '';
    final trxStatus = _map(order['transaction'])['status']?.toString().toLowerCase() ?? '';
    final stage = _paymentDetails()['stage']?.toString().toLowerCase() ?? '';

    if (status == 'canceled' || status == 'cancelled') return 'canceled';
    if (status == 'delivered') return 'delivered';
    if (stage == 'checkout_completed') return 'packing';
    if (trxStatus == 'approved' || trxStatus == 'settlement' || trxStatus == 'capture') return 'paid_not_checked_out';
    return 'pending_payment';
  }

  bool get _isCanceled => _statusKey() == 'canceled';
  Color get _main => _isCanceled ? _danger : _primary;
  Color get _gradientEnd => _isCanceled ? _dangerDark : const Color(0xFF123A68);

  String _statusText() {
    final label = order['frontend_status_label']?.toString();
    if (label != null && label.isNotEmpty) return label;
    switch (_statusKey()) {
      case 'pending_payment':
        return 'Pending Payment';
      case 'paid_not_checked_out':
        return 'Dibayar';
      case 'packing':
        return 'Packing';
      case 'delivered':
        return 'Delivered';
      case 'done':
        return 'Done';
      case 'canceled':
        return 'Canceled';
      default:
        return 'Pending Payment';
    }
  }

  bool get _canResumeCheckout => _statusKey() == 'pending_payment' || _statusKey() == 'paid_not_checked_out';
  bool get _canPrintReceipt => !_isCanceled && (_statusKey() == 'paid_not_checked_out' || _statusKey() == 'packing');

  String _primaryActionLabel() {
    if (_statusKey() == 'pending_payment') return 'LANJUTKAN PEMBAYARAN';
    if (_statusKey() == 'paid_not_checked_out') return 'SELESAIKAN CHECKOUT';
    return 'KEMBALI KE BERANDA';
  }

  IconData _statusIcon() {
    switch (_statusKey()) {
      case 'pending_payment':
        return Icons.schedule_rounded;
      case 'paid_not_checked_out':
        return Icons.verified_rounded;
      case 'packing':
        return Icons.inventory_2_rounded;
      case 'delivered':
        return Icons.local_shipping_rounded;
      case 'done':
        return Icons.check_circle_rounded;
      case 'canceled':
        return Icons.cancel_rounded;
      default:
        return Icons.receipt_long_rounded;
    }
  }

  void _handlePrimaryAction(BuildContext context) {
    if (_canResumeCheckout) {
      Navigator.push(context, MaterialPageRoute(builder: (_) => ResumeOrderCheckoutScreen(order: order)));
      return;
    }
    Navigator.pushAndRemoveUntil(context, MaterialPageRoute(builder: (_) => const MainScreen()), (_) => false);
  }

  String _receiptText() {
    final transaction = _map(order['transaction']);
    final details = _paymentDetails();
    final paymentInfo = _map(details['payment_info']);
    final paymentId = paymentInfo['transaction_id'] ?? transaction['payment_token'] ?? '-';
    final vaNumber = paymentInfo['va_number'] ?? '-';
    final buffer = StringBuffer()
      ..writeln('RESI PESANAN')
      ..writeln('Order ID: #ORDER-${order['id'] ?? '-'}')
      ..writeln('Status: ${_statusText()}')
      ..writeln('ID Pembayaran: $paymentId')
      ..writeln('Metode: ${(details['payment_type'] ?? paymentInfo['payment_type'] ?? '-').toString().toUpperCase()}')
      ..writeln('Bank: ${(details['bank'] ?? '-').toString().toUpperCase()}')
      ..writeln('Nomor VA: $vaNumber')
      ..writeln('')
      ..writeln('PENERIMA')
      ..writeln('${order['name'] ?? '-'}')
      ..writeln('${order['phone'] ?? '-'}')
      ..writeln('${order['address'] ?? '-'}, ${order['city'] ?? '-'}, ${order['state'] ?? '-'}')
      ..writeln('Kurir: ${order['mode_pengiriman'] ?? '-'} - ${order['jenis_pengiriman'] ?? '-'}')
      ..writeln('')
      ..writeln('BARANG');

    for (final raw in _list(order['items'])) {
      final item = _map(raw);
      final product = _map(item['product']);
      final qty = _num(item['quantity']).toInt();
      final price = _num(item['price']);
      buffer.writeln('$qty x ${product['name'] ?? 'Produk'} = ${_money(price * qty)}');
    }

    buffer
      ..writeln('')
      ..writeln('Subtotal: ${_money(order['subtotal'])}')
      ..writeln('Ongkir: ${_money(order['ongkir'])}')
      ..writeln('Total Order: ${_money(order['total'])}');

    return buffer.toString();
  }

  void _showReceiptPreview(BuildContext context) {
    final receipt = _receiptText();
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => DraggableScrollableSheet(
        initialChildSize: .72,
        minChildSize: .45,
        maxChildSize: .92,
        builder: (context, controller) => Container(
          padding: const EdgeInsets.fromLTRB(16, 14, 16, 16),
          decoration: const BoxDecoration(color: Colors.white, borderRadius: BorderRadius.vertical(top: Radius.circular(28))),
          child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Center(child: Container(width: 44, height: 5, decoration: BoxDecoration(color: const Color(0xFFE2E8F0), borderRadius: BorderRadius.circular(99)))),
            const SizedBox(height: 18),
            Row(children: const [Icon(Icons.print_rounded, color: _primary), SizedBox(width: 10), Text('Preview Resi Pesanan', style: TextStyle(fontSize: 16, color: _primary, fontWeight: FontWeight.w900))]),
            const SizedBox(height: 12),
            Expanded(child: Container(width: double.infinity, padding: const EdgeInsets.all(14), decoration: BoxDecoration(color: _surface, borderRadius: BorderRadius.circular(18), border: Border.all(color: const Color(0xFFE2E8F0))), child: SingleChildScrollView(controller: controller, child: SelectableText(receipt, style: const TextStyle(fontSize: 12.5, height: 1.45, color: Color(0xFF111827), fontWeight: FontWeight.w600))))),
            const SizedBox(height: 12),
            SizedBox(width: double.infinity, child: ElevatedButton.icon(onPressed: () { Clipboard.setData(ClipboardData(text: receipt)); Navigator.pop(context); ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Detail resi berhasil disalin.'))); }, style: ElevatedButton.styleFrom(backgroundColor: _primary, foregroundColor: Colors.white, elevation: 0, padding: const EdgeInsets.symmetric(vertical: 13), shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14))), icon: const Icon(Icons.copy_rounded, size: 18), label: const Text('SALIN DETAIL RESI', style: TextStyle(fontSize: 13, fontWeight: FontWeight.w900)))),
          ]),
        ),
      ),
    );
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
      backgroundColor: _surface,
      body: SingleChildScrollView(
        physics: const BouncingScrollPhysics(),
        padding: const EdgeInsets.only(bottom: 150),
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          _pageHeader(context, paymentId.toString()),
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 16, 16, 0),
            child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              _actionNotice(),
              const SizedBox(height: 14),
              _title('Order & Transaksi'),
              _card([
                _row('Order ID', '#ORDER-${order['id'] ?? '-'}'),
                _row('Status', _statusText()),
                _row('ID Pembayaran', paymentId.toString()),
                _row('Status Transaksi', transaction['status']?.toString().toUpperCase() ?? '-'),
                _row('Metode', (details['payment_type'] ?? paymentInfo['payment_type'] ?? '-').toString().toUpperCase()),
                _row('Bank', (details['bank'] ?? '-').toString().toUpperCase()),
                if (vaNumber.toString() != '-' && !_isCanceled) _row('Nomor VA', vaNumber.toString()),
              ]),
              const SizedBox(height: 14),
              _title('Pengiriman'),
              _card([
                _row('Penerima', '${order['name'] ?? '-'}'),
                _row('No HP', '${order['phone'] ?? '-'}'),
                _row('Kurir', '${order['mode_pengiriman'] ?? '-'} - ${order['jenis_pengiriman'] ?? '-'}'),
                Padding(padding: const EdgeInsets.only(top: 8), child: Text('${order['address'] ?? '-'}, ${order['city'] ?? '-'}, ${order['state'] ?? '-'}', style: const TextStyle(fontSize: 12, color: Color(0xFF475569), height: 1.4))),
              ]),
              const SizedBox(height: 14),
              _title('Daftar Barang'),
              Container(padding: const EdgeInsets.all(14), decoration: _box(), child: Column(children: [
                ...items.map(_productRow),
                const Divider(height: 22),
                _priceRow('Subtotal Produk', order['subtotal']),
                const SizedBox(height: 7),
                _priceRow('Ongkir', order['ongkir']),
                const Divider(height: 22),
                _priceRow('Total Order', order['total'], strong: true),
              ])),
            ]),
          ),
        ]),
      ),
      bottomSheet: _bottomActionBar(context),
    );
  }

  Widget _bottomActionBar(BuildContext context) => Container(
        padding: const EdgeInsets.fromLTRB(16, 12, 16, 16),
        decoration: BoxDecoration(color: Colors.white, boxShadow: [BoxShadow(color: Colors.black.withOpacity(.08), blurRadius: 16, offset: const Offset(0, -5))]),
        child: SafeArea(child: Column(mainAxisSize: MainAxisSize.min, children: [
          if (_canPrintReceipt) ...[SizedBox(width: double.infinity, child: OutlinedButton.icon(onPressed: () => _showReceiptPreview(context), style: OutlinedButton.styleFrom(foregroundColor: _main, side: BorderSide(color: _main), padding: const EdgeInsets.symmetric(vertical: 13), shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14))), icon: const Icon(Icons.print_rounded, size: 18), label: const Text('CETAK RESI', style: TextStyle(fontSize: 13, fontWeight: FontWeight.w900)))), const SizedBox(height: 8)],
          SizedBox(width: double.infinity, child: ElevatedButton.icon(onPressed: () => _handlePrimaryAction(context), style: ElevatedButton.styleFrom(backgroundColor: _main, foregroundColor: Colors.white, elevation: 0, padding: const EdgeInsets.symmetric(vertical: 13), shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14))), icon: Icon(_canResumeCheckout ? Icons.play_arrow_rounded : Icons.home_rounded, size: 18), label: Text(_primaryActionLabel(), style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w900)))),
        ])),
      );

  Widget _circleAction(IconData icon, VoidCallback? onTap) => InkWell(onTap: onTap, borderRadius: BorderRadius.circular(999), child: Container(width: 42, height: 42, decoration: BoxDecoration(color: Colors.white.withOpacity(0.14), shape: BoxShape.circle, border: Border.all(color: Colors.white.withOpacity(0.12))), child: Icon(icon, color: Colors.white, size: 21)));

  Widget _pageHeader(BuildContext context, String paymentId) => Container(
        decoration: BoxDecoration(gradient: LinearGradient(colors: [_main, _gradientEnd], begin: Alignment.topLeft, end: Alignment.bottomRight), borderRadius: const BorderRadius.vertical(bottom: Radius.circular(30))),
        child: SafeArea(bottom: false, child: Padding(padding: const EdgeInsets.fromLTRB(18, 16, 18, 22), child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
            _circleAction(Icons.arrow_back_rounded, () { if (Navigator.canPop(context)) { Navigator.pop(context); } else { Navigator.pushAndRemoveUntil(context, MaterialPageRoute(builder: (_) => const MainScreen()), (_) => false); } }),
            Container(padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 7), decoration: BoxDecoration(color: Colors.white.withOpacity(0.14), borderRadius: BorderRadius.circular(99), border: Border.all(color: Colors.white.withOpacity(0.12))), child: Text(_statusText(), style: const TextStyle(color: Colors.white, fontSize: 12, fontWeight: FontWeight.w800))),
          ]),
          const SizedBox(height: 16),
          Container(padding: const EdgeInsets.all(14), decoration: BoxDecoration(color: Colors.white.withOpacity(0.12), borderRadius: BorderRadius.circular(24), border: Border.all(color: Colors.white.withOpacity(0.16))), child: Row(children: [
            Container(width: 56, height: 56, decoration: const BoxDecoration(color: Colors.white, shape: BoxShape.circle), child: Icon(_statusIcon(), color: _main, size: 30)),
            const SizedBox(width: 14),
            Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              const Text('Detail Pesanan', style: TextStyle(color: Colors.white, fontSize: 17, fontWeight: FontWeight.w900)),
              const SizedBox(height: 5),
              Text(_isCanceled ? 'Order #${order['id'] ?? '-'} sudah dibatalkan' : 'Payment ID: $paymentId', maxLines: 1, overflow: TextOverflow.ellipsis, style: TextStyle(color: Colors.white.withOpacity(0.84), fontSize: 12.5)),
            ])),
          ])),
        ]))),
      );

  Widget _actionNotice() => Container(width: double.infinity, padding: const EdgeInsets.all(14), decoration: _box(), child: Row(children: [
    Container(width: 46, height: 46, decoration: BoxDecoration(color: _isCanceled ? const Color(0xFFFEE2E2) : _purple.withOpacity(0.10), borderRadius: BorderRadius.circular(16)), child: Icon(_statusIcon(), color: _main, size: 22)),
    const SizedBox(width: 12),
    Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      Text(_statusText(), style: TextStyle(fontSize: 14, color: _main, fontWeight: FontWeight.w900)),
      const SizedBox(height: 3),
      Text(_isCanceled ? 'Pesanan ini sudah canceled dan tidak bisa dilanjutkan.' : _canResumeCheckout ? 'Pesanan ini masih bisa dilanjutkan dari halaman detail.' : 'Detail akhir pesanan sudah dapat dilihat di halaman ini.', style: const TextStyle(fontSize: 11.5, color: _muted, height: 1.35)),
    ])),
  ]));

  Widget _title(String text) => Padding(padding: const EdgeInsets.only(bottom: 8), child: Text(text, style: TextStyle(fontSize: 13, color: _main, fontWeight: FontWeight.w900)));
  BoxDecoration _box() => BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(22), border: Border.all(color: _isCanceled ? const Color(0xFFFCA5A5) : const Color(0xFFE2E8F0)), boxShadow: [BoxShadow(color: Colors.black.withOpacity(.04), blurRadius: 14, offset: const Offset(0, 6))]);
  Widget _card(List<Widget> children) => Container(width: double.infinity, padding: const EdgeInsets.all(14), decoration: _box(), child: Column(children: children));

  Widget _row(String label, String value) => Padding(padding: const EdgeInsets.symmetric(vertical: 5), child: Row(crossAxisAlignment: CrossAxisAlignment.start, children: [SizedBox(width: 120, child: Text(label, style: const TextStyle(fontSize: 12, color: _muted))), Expanded(child: Text(value, textAlign: TextAlign.right, style: const TextStyle(fontSize: 12.5, color: Color(0xFF111827), fontWeight: FontWeight.w700)))]));

  Widget _productRow(dynamic value) {
    final item = _map(value); final product = _map(item['product']); final qty = _num(item['quantity']); final price = _num(item['price']);
    return Padding(padding: const EdgeInsets.only(bottom: 10), child: Row(children: [Expanded(child: Text('${qty.toInt()}x ${product['name'] ?? 'Produk'}', maxLines: 1, overflow: TextOverflow.ellipsis, style: const TextStyle(fontSize: 12.5, fontWeight: FontWeight.w700))), Text(_money(price * qty), style: TextStyle(fontSize: 12, color: _main, fontWeight: FontWeight.w900))]));
  }

  Widget _priceRow(String label, dynamic value, {bool strong = false}) => Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [Text(label, style: TextStyle(fontSize: strong ? 14 : 12, color: strong ? _main : _muted, fontWeight: strong ? FontWeight.w900 : FontWeight.w500)), Text(_money(value), style: TextStyle(fontSize: strong ? 18 : 12.5, color: strong ? _main : const Color(0xFF111827), fontWeight: FontWeight.w900))]);
}

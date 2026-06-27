import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../services/marketplace_api_service.dart';
import 'main_screen.dart';
import 'resume_order_checkout_screen.dart';

class OrderConfirmationScreen extends StatefulWidget {
  final Map<String, dynamic> order;
  const OrderConfirmationScreen({Key? key, required this.order}) : super(key: key);

  @override
  State<OrderConfirmationScreen> createState() => _OrderConfirmationScreenState();
}

class _OrderConfirmationScreenState extends State<OrderConfirmationScreen> {
  static const Color _navy = Color(0xFF0B1F4D);
  static const Color _pageBg = Color(0xFFF5F7FB);
  static const Color _muted = Color(0xFF64748B);

  late Map<String, dynamic> order;
  final Set<int> _reviewedProductIds = {};
  bool _submittingReview = false;

  @override
  void initState() {
    super.initState();
    order = Map<String, dynamic>.from(widget.order);
    final reviewed = order['reviewed_product_ids'];
    if (reviewed is List) {
      _reviewedProductIds.addAll(reviewed.map((e) => int.tryParse(e.toString()) ?? 0).where((id) => id > 0));
    }
  }

  Map<String, dynamic> _map(dynamic value) => value is Map<String, dynamic> ? value : value is Map ? Map<String, dynamic>.from(value) : <String, dynamic>{};
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
    if (status == 'done' || status == 'completed' || status == 'complete' || status == 'selesai') return 'done';
    if (status == 'delivered' || status == 'deliver') return 'delivered';
    if (status == 'packing' || status == 'processing' || status == 'shipped') return 'packing';
    if (stage == 'checkout_completed') return 'packing';
    if (trxStatus == 'approved' || trxStatus == 'settlement' || trxStatus == 'capture') return 'paid_not_checked_out';
    return 'pending_payment';
  }

  String _statusText() {
    final label = order['frontend_status_label']?.toString();
    if (label != null && label.isNotEmpty) return label;
    switch (_statusKey()) {
      case 'pending_payment': return 'Belum Dibayar';
      case 'paid_not_checked_out': return 'Dibayar';
      case 'packing': return 'Dikemas';
      case 'delivered': return 'Dikirim';
      case 'done': return 'Selesai';
      case 'canceled': return 'Dibatalkan';
      default: return 'Belum Dibayar';
    }
  }

  bool get _canResumeCheckout => _statusKey() == 'pending_payment' || _statusKey() == 'paid_not_checked_out';
  bool get _canPrintReceipt => _statusKey() == 'paid_not_checked_out' || _statusKey() == 'packing' || _statusKey() == 'delivered' || _statusKey() == 'done';
  bool get _canReview => _statusKey() == 'delivered' || _statusKey() == 'done';

  List<Map<String, dynamic>> get _reviewableItems {
    final result = <Map<String, dynamic>>[];
    final seen = <int>{};
    for (final raw in _list(order['items'])) {
      final item = _map(raw);
      final product = _map(item['product']);
      final productId = int.tryParse((item['product_id'] ?? product['id'] ?? '').toString()) ?? 0;
      if (productId <= 0 || seen.contains(productId)) continue;
      seen.add(productId);
      result.add({'product_id': productId, 'name': product['name']?.toString() ?? 'Produk'});
    }
    return result;
  }

  String _primaryActionLabel() {
    if (_statusKey() == 'pending_payment') return 'LANJUTKAN PEMBAYARAN';
    if (_statusKey() == 'paid_not_checked_out') return 'SELESAIKAN CHECKOUT';
    return 'KEMBALI KE BERANDA';
  }

  IconData _statusIcon() {
    switch (_statusKey()) {
      case 'pending_payment': return Icons.schedule_rounded;
      case 'paid_not_checked_out': return Icons.verified_rounded;
      case 'packing': return Icons.inventory_2_rounded;
      case 'delivered': return Icons.local_shipping_rounded;
      case 'done': return Icons.check_circle_rounded;
      case 'canceled': return Icons.cancel_rounded;
      default: return Icons.receipt_long_rounded;
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
          decoration: const BoxDecoration(color: Colors.white, borderRadius: BorderRadius.vertical(top: Radius.circular(24))),
          child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Center(child: Container(width: 44, height: 5, decoration: BoxDecoration(color: const Color(0xFFE2E8F0), borderRadius: BorderRadius.circular(99)))),
            const SizedBox(height: 18),
            Row(children: const [Icon(Icons.print_rounded, color: _navy), SizedBox(width: 10), Text('Preview Resi Pesanan', style: TextStyle(fontSize: 16, color: _navy, fontWeight: FontWeight.w900))]),
            const SizedBox(height: 12),
            Expanded(child: Container(width: double.infinity, padding: const EdgeInsets.all(14), decoration: BoxDecoration(color: const Color(0xFFF8FAFC), borderRadius: BorderRadius.circular(14), border: Border.all(color: const Color(0xFFE2E8F0))), child: SingleChildScrollView(controller: controller, child: SelectableText(receipt, style: const TextStyle(fontSize: 12.5, height: 1.45, color: Color(0xFF111827), fontWeight: FontWeight.w600))))),
            const SizedBox(height: 12),
            SizedBox(width: double.infinity, child: ElevatedButton.icon(onPressed: () { Clipboard.setData(ClipboardData(text: receipt)); Navigator.pop(context); ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Detail resi berhasil disalin.'))); }, style: ElevatedButton.styleFrom(backgroundColor: _navy, padding: const EdgeInsets.symmetric(vertical: 13), shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12))), icon: const Icon(Icons.copy_rounded, color: Colors.white, size: 18), label: const Text('SALIN DETAIL RESI', style: TextStyle(color: Colors.white, fontSize: 13, fontWeight: FontWeight.w900)))),
          ]),
        ),
      ),
    );
  }

  Future<void> _showReviewSheet() async {
    final products = _reviewableItems;
    if (products.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Produk pada pesanan ini belum tersedia untuk diulas.')));
      return;
    }

    final available = products.where((p) => !_reviewedProductIds.contains(p['product_id'])).toList();
    if (available.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Semua produk pada pesanan ini sudah diberi penilaian.')));
      return;
    }

    int selectedProductId = available.first['product_id'] as int;
    int rating = 5;
    final reviewCtrl = TextEditingController();

    await showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => StatefulBuilder(builder: (context, setSheetState) {
        final bottom = MediaQuery.of(context).viewInsets.bottom;
        return Padding(
          padding: EdgeInsets.only(bottom: bottom),
          child: Container(
            padding: const EdgeInsets.fromLTRB(16, 16, 16, 18),
            decoration: const BoxDecoration(color: Colors.white, borderRadius: BorderRadius.vertical(top: Radius.circular(24))),
            child: Column(mainAxisSize: MainAxisSize.min, crossAxisAlignment: CrossAxisAlignment.start, children: [
              Center(child: Container(width: 44, height: 5, decoration: BoxDecoration(color: const Color(0xFFE2E8F0), borderRadius: BorderRadius.circular(99)))),
              const SizedBox(height: 16),
              const Text('Beri Penilaian Produk', style: TextStyle(fontSize: 16, color: _navy, fontWeight: FontWeight.w900)),
              const SizedBox(height: 12),
              DropdownButtonFormField<int>(
                value: selectedProductId,
                decoration: const InputDecoration(labelText: 'Produk', border: OutlineInputBorder()),
                items: available.map((p) => DropdownMenuItem<int>(value: p['product_id'] as int, child: Text(p['name'].toString(), maxLines: 1, overflow: TextOverflow.ellipsis))).toList(),
                onChanged: (value) => setSheetState(() => selectedProductId = value ?? selectedProductId),
              ),
              const SizedBox(height: 12),
              Row(children: List.generate(5, (index) => IconButton(
                onPressed: () => setSheetState(() => rating = index + 1),
                icon: Icon(index < rating ? Icons.star_rounded : Icons.star_border_rounded, color: const Color(0xFFF59E0B), size: 32),
              ))),
              TextField(controller: reviewCtrl, maxLines: 4, decoration: const InputDecoration(labelText: 'Ulasan', hintText: 'Tulis pengalaman kamu tentang produk ini', border: OutlineInputBorder())),
              const SizedBox(height: 14),
              SizedBox(width: double.infinity, child: ElevatedButton.icon(
                onPressed: _submittingReview ? null : () async {
                  setSheetState(() => _submittingReview = true);
                  final ok = await MarketplaceApiService.addReview(productId: selectedProductId, orderId: int.tryParse(order['id']?.toString() ?? ''), rating: rating, review: reviewCtrl.text.trim());
                  if (!mounted) return;
                  setSheetState(() => _submittingReview = false);
                  Navigator.pop(context);
                  if (ok) {
                    setState(() => _reviewedProductIds.add(selectedProductId));
                    ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Penilaian berhasil disimpan.')));
                  } else {
                    ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Gagal menyimpan penilaian.')));
                  }
                },
                style: ElevatedButton.styleFrom(backgroundColor: _navy, foregroundColor: Colors.white, padding: const EdgeInsets.symmetric(vertical: 13), shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12))),
                icon: _submittingReview ? const SizedBox(width: 17, height: 17, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white)) : const Icon(Icons.rate_review_rounded, size: 18),
                label: const Text('KIRIM PENILAIAN', style: TextStyle(fontSize: 13, fontWeight: FontWeight.w900)),
              )),
            ]),
          ),
        );
      }),
    );
    reviewCtrl.dispose();
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
      appBar: AppBar(title: const Text('Detail Pesanan', style: TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.w800)), backgroundColor: _navy, iconTheme: const IconThemeData(color: Colors.white)),
      body: SingleChildScrollView(
        padding: const EdgeInsets.fromLTRB(16, 16, 16, 178),
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          _header(paymentId.toString()),
          const SizedBox(height: 14),
          _actionNotice(),
          const SizedBox(height: 14),
          _title('Order & Transaksi'),
          _card([_row('Order ID', '#ORDER-${order['id'] ?? '-'}'), _row('Status', _statusText()), _row('ID Pembayaran', paymentId.toString()), _row('Status Transaksi', transaction['status']?.toString().toUpperCase() ?? '-'), _row('Metode', (details['payment_type'] ?? paymentInfo['payment_type'] ?? '-').toString().toUpperCase()), _row('Bank', (details['bank'] ?? '-').toString().toUpperCase()), if (vaNumber.toString() != '-') _row('Nomor VA', vaNumber.toString())]),
          const SizedBox(height: 14),
          _title('Pengiriman'),
          _card([_row('Penerima', '${order['name'] ?? '-'}'), _row('No HP', '${order['phone'] ?? '-'}'), _row('Kurir', '${order['mode_pengiriman'] ?? '-'} - ${order['jenis_pengiriman'] ?? '-'}'), Padding(padding: const EdgeInsets.only(top: 8), child: Text('${order['address'] ?? '-'}, ${order['city'] ?? '-'}, ${order['state'] ?? '-'}', style: const TextStyle(fontSize: 12, color: Color(0xFF475569), height: 1.4)))]),
          const SizedBox(height: 14),
          _title('Daftar Barang'),
          Container(padding: const EdgeInsets.all(14), decoration: _box(), child: Column(children: [...items.map(_productRow), const Divider(height: 22), _priceRow('Subtotal Produk', order['subtotal']), const SizedBox(height: 7), _priceRow('Ongkir', order['ongkir']), const Divider(height: 22), _priceRow('Total Order', order['total'], strong: true)])),
        ]),
      ),
      bottomSheet: Container(
        padding: const EdgeInsets.fromLTRB(16, 12, 16, 16),
        decoration: BoxDecoration(color: Colors.white, boxShadow: [BoxShadow(color: Colors.black.withOpacity(.08), blurRadius: 16, offset: const Offset(0, -5))]),
        child: SafeArea(child: Column(mainAxisSize: MainAxisSize.min, children: [
          if (_canReview) ...[
            SizedBox(width: double.infinity, child: OutlinedButton.icon(onPressed: _showReviewSheet, style: OutlinedButton.styleFrom(foregroundColor: const Color(0xFF15803D), side: const BorderSide(color: Color(0xFF15803D)), padding: const EdgeInsets.symmetric(vertical: 13), shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12))), icon: const Icon(Icons.star_rate_rounded, size: 18), label: const Text('BERI PENILAIAN', style: TextStyle(fontSize: 13, fontWeight: FontWeight.w900)))),
            const SizedBox(height: 8),
          ],
          if (_canPrintReceipt) ...[
            SizedBox(width: double.infinity, child: OutlinedButton.icon(onPressed: () => _showReceiptPreview(context), style: OutlinedButton.styleFrom(foregroundColor: _navy, side: const BorderSide(color: _navy), padding: const EdgeInsets.symmetric(vertical: 13), shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12))), icon: const Icon(Icons.print_rounded, size: 18), label: const Text('CETAK RESI', style: TextStyle(fontSize: 13, fontWeight: FontWeight.w900)))),
            const SizedBox(height: 8),
          ],
          SizedBox(width: double.infinity, child: ElevatedButton.icon(onPressed: () => _handlePrimaryAction(context), style: ElevatedButton.styleFrom(backgroundColor: _navy, padding: const EdgeInsets.symmetric(vertical: 13), shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12))), icon: Icon(_canResumeCheckout ? Icons.play_arrow_rounded : Icons.home_rounded, color: Colors.white, size: 18), label: Text(_primaryActionLabel(), style: const TextStyle(color: Colors.white, fontSize: 13, fontWeight: FontWeight.w900)))),
        ])),
      ),
    );
  }

  Widget _actionNotice() => Container(width: double.infinity, padding: const EdgeInsets.all(14), decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(16), border: Border.all(color: const Color(0xFFE2E8F0))), child: Row(children: [Container(width: 38, height: 38, decoration: BoxDecoration(color: const Color(0xFFEAF0FF), borderRadius: BorderRadius.circular(12)), child: Icon(_statusIcon(), color: _navy, size: 20)), const SizedBox(width: 12), Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [Text(_statusText(), style: const TextStyle(fontSize: 13, color: _navy, fontWeight: FontWeight.w900)), const SizedBox(height: 3), Text(_canReview ? 'Pesanan sudah bisa diberi penilaian produk.' : _canResumeCheckout ? 'Pesanan ini masih bisa dilanjutkan dari halaman detail.' : 'Detail akhir pesanan sudah dapat dilihat di halaman ini.', style: const TextStyle(fontSize: 11.5, color: _muted, height: 1.35))]))]));
  Widget _header(String paymentId) => Container(width: double.infinity, padding: const EdgeInsets.all(18), decoration: BoxDecoration(gradient: const LinearGradient(colors: [_navy, Color(0xFF163A73)]), borderRadius: BorderRadius.circular(18)), child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [const Icon(Icons.receipt_long_rounded, color: Colors.white, size: 34), const SizedBox(height: 12), const Text('Ringkasan Pesanan', style: TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.w900)), const SizedBox(height: 5), Text('Payment ID: $paymentId', style: const TextStyle(color: Color(0xFFCBD5E1), fontSize: 12))]));
  Widget _title(String text) => Padding(padding: const EdgeInsets.only(bottom: 8), child: Text(text, style: const TextStyle(fontSize: 13, color: _navy, fontWeight: FontWeight.w900)));
  BoxDecoration _box() => BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(16), border: Border.all(color: const Color(0xFFE2E8F0)));
  Widget _card(List<Widget> children) => Container(width: double.infinity, padding: const EdgeInsets.all(14), decoration: _box(), child: Column(children: children));
  Widget _row(String label, String value) => Padding(padding: const EdgeInsets.symmetric(vertical: 5), child: Row(crossAxisAlignment: CrossAxisAlignment.start, children: [SizedBox(width: 120, child: Text(label, style: const TextStyle(fontSize: 12, color: _muted))), Expanded(child: Text(value, textAlign: TextAlign.right, style: const TextStyle(fontSize: 12.5, color: Color(0xFF111827), fontWeight: FontWeight.w700)))]));
  Widget _productRow(dynamic value) { final item = _map(value); final product = _map(item['product']); final qty = _num(item['quantity']); final price = _num(item['price']); final productId = int.tryParse((item['product_id'] ?? product['id'] ?? '').toString()) ?? 0; final reviewed = _reviewedProductIds.contains(productId); return Padding(padding: const EdgeInsets.only(bottom: 10), child: Row(children: [Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [Text('${qty.toInt()}x ${product['name'] ?? 'Produk'}', maxLines: 1, overflow: TextOverflow.ellipsis, style: const TextStyle(fontSize: 12.5, fontWeight: FontWeight.w700)), if (reviewed) const Text('Sudah diberi penilaian', style: TextStyle(fontSize: 10.5, color: Color(0xFF15803D), fontWeight: FontWeight.w700))])), Text(_money(price * qty), style: const TextStyle(fontSize: 12, color: _navy, fontWeight: FontWeight.w900))])); }
  Widget _priceRow(String label, dynamic value, {bool strong = false}) => Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [Text(label, style: TextStyle(fontSize: strong ? 14 : 12, color: strong ? _navy : _muted, fontWeight: strong ? FontWeight.w900 : FontWeight.w500)), Text(_money(value), style: TextStyle(fontSize: strong ? 18 : 12.5, color: strong ? _navy : const Color(0xFF111827), fontWeight: FontWeight.w900))]);
}

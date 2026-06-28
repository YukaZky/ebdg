import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../../services/marketplace_api_service.dart';

class TokoPesananScreen extends StatefulWidget {
  const TokoPesananScreen({Key? key}) : super(key: key);

  @override
  State<TokoPesananScreen> createState() => _TokoPesananScreenState();
}

class _TokoPesananScreenState extends State<TokoPesananScreen> {
  static const Color _primary = Color(0xFF0C2442);
  // static const Color _accent = Color(0xFFF39C12);
  static const Color _purple = Color(0xFF6C4DFF);
  static const Color _surface = Color(0xFFF7F8FC);
  static const Color _muted = Color(0xFF64748B);
  static const Color _danger = Color(0xFFB91C1C);

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
    if (raw == 'ordered' || raw == 'dibayar') return 'paid';
    if (raw == 'processing' || raw == 'shipped' || raw == 'dikemas') return 'packing';
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
  int _countByStatus(String key) => orders.where((order) => _statusKey(order) == key).length;

  Color _statusColor(String status) {
    switch (status) {
      case 'paid':
        return const Color(0xFF0C2442);
      case 'packing':
        return _purple;
      case 'delivered':
        return const Color(0xFF0F766E);
      case 'done':
        return const Color(0xFF15803D);
      case 'canceled':
        return _danger;
      default:
        return _primary;
    }
  }

  Future<void> updateStatus(int orderId, String status) async {
    final ok = await MarketplaceApiService.updateOrderStatus(orderId, status);
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(ok ? 'Status pesanan berhasil diperbarui' : 'Gagal memperbarui status pesanan')));
    if (ok) {
      setState(() => selectedStatus = status);
      loadOrders();
    }
  }

  Widget _header() {
    final total = orders.length;
    final active = _countByStatus('paid') + _countByStatus('packing') + _countByStatus('delivered');
    return Container(
      decoration: const BoxDecoration(
        gradient: LinearGradient(colors: [_primary, Color(0xFF123A68)], begin: Alignment.topLeft, end: Alignment.bottomRight),
        borderRadius: BorderRadius.vertical(bottom: Radius.circular(30)),
      ),
      child: SafeArea(
        bottom: false,
        child: Padding(
          padding: const EdgeInsets.fromLTRB(18, 16, 18, 22),
          child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
              const Text('Pesanan Toko', style: TextStyle(color: Colors.white, fontSize: 22, fontWeight: FontWeight.w900)),
              InkWell(
                onTap: loadOrders,
                borderRadius: BorderRadius.circular(999),
                child: Container(width: 42, height: 42, decoration: BoxDecoration(color: Colors.white.withOpacity(0.14), shape: BoxShape.circle, border: Border.all(color: Colors.white.withOpacity(0.12))), child: const Icon(Icons.refresh_rounded, color: Colors.white)),
              ),
            ]),
            const SizedBox(height: 16),
            Container(
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(color: Colors.white.withOpacity(0.12), borderRadius: BorderRadius.circular(24), border: Border.all(color: Colors.white.withOpacity(0.16))),
              child: Row(children: [
                Container(width: 56, height: 56, decoration: const BoxDecoration(color: Colors.white, shape: BoxShape.circle), child: const Icon(Icons.storefront_rounded, color: _primary, size: 30)),
                const SizedBox(width: 14),
                Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                  const Text('Kelola Pesanan Marketplace', style: TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.w900)),
                  const SizedBox(height: 5),
                  Text('$active pesanan aktif • $total total pesanan toko', style: TextStyle(color: Colors.white.withOpacity(0.78), fontSize: 12.5)),
                ])),
              ]),
            ),
          ]),
        ),
      ),
    );
  }

  Widget _filterBar() => Container(
        color: _surface,
        padding: const EdgeInsets.fromLTRB(16, 14, 16, 8),
        child: SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          child: Row(children: filters.map((filter) {
            final key = filter['key'] as String;
            final active = selectedStatus == key;
            final color = _statusColor(key);
            final count = _countByStatus(key);
            return Padding(
              padding: const EdgeInsets.only(right: 10),
              child: InkWell(
                onTap: () => setState(() => selectedStatus = key),
                borderRadius: BorderRadius.circular(18),
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 180),
                  width: 118,
                  padding: const EdgeInsets.all(11),
                  decoration: BoxDecoration(
                    color: active ? color : Colors.white,
                    borderRadius: BorderRadius.circular(18),
                    border: Border.all(color: active ? color : const Color(0xFFE2E8F0)),
                    boxShadow: [BoxShadow(color: _primary.withOpacity(0.04), blurRadius: 14, offset: const Offset(0, 7))],
                  ),
                  child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                    Row(children: [
                      Icon(filter['icon'] as IconData, size: 18, color: active ? Colors.white : color),
                      const Spacer(),
                      Container(
                        constraints: const BoxConstraints(minWidth: 24),
                        padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 3),
                        decoration: BoxDecoration(color: active ? Colors.white : color, borderRadius: BorderRadius.circular(999)),
                        child: Text('$count', textAlign: TextAlign.center, style: TextStyle(fontSize: 10.5, fontWeight: FontWeight.w900, color: active ? color : Colors.white)),
                      ),
                    ]),
                    const SizedBox(height: 8),
                    Text(filter['label'] as String, maxLines: 1, overflow: TextOverflow.ellipsis, style: TextStyle(fontSize: 11.5, fontWeight: FontWeight.w900, color: active ? Colors.white : color)),
                  ]),
                ),
              ),
            );
          }).toList()),
        ),
      );

  Widget _miniInfo(IconData icon, String text) => Row(children: [Icon(icon, size: 15, color: _muted), const SizedBox(width: 6), Expanded(child: Text(text, maxLines: 1, overflow: TextOverflow.ellipsis, style: const TextStyle(fontSize: 11.5, color: _muted, fontWeight: FontWeight.w600)))]);

  Widget _smallAction(String text, IconData icon, Color color, VoidCallback onTap) {
    return SizedBox(
      height: 34,
      child: ElevatedButton.icon(
        onPressed: onTap,
        icon: Icon(icon, size: 14),
        label: Text(text, style: const TextStyle(fontSize: 11.2, fontWeight: FontWeight.w900)),
        style: ElevatedButton.styleFrom(backgroundColor: color, foregroundColor: Colors.white, elevation: 0, padding: const EdgeInsets.symmetric(horizontal: 10), minimumSize: const Size(0, 34), tapTargetSize: MaterialTapTargetSize.shrinkWrap, shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(11))),
      ),
    );
  }

  Widget _orderCard(dynamic order) {
    final status = _statusKey(order);
    final items = order['items'] as List? ?? [];
    final orderId = int.tryParse(order['id']?.toString() ?? '0') ?? 0;
    final discount = _sellerDiscount(order);
    final color = _statusColor(status);
    final firstProduct = items.isNotEmpty ? _map(_map(items.first)['product']) : <String, dynamic>{};
    return InkWell(
      onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => TokoPesananDetailScreen(order: order))).then((_) => loadOrders()),
      borderRadius: BorderRadius.circular(22),
      child: Container(
        margin: const EdgeInsets.only(bottom: 14),
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(22), border: Border.all(color: const Color(0xFFE2E8F0)), boxShadow: [BoxShadow(color: _primary.withOpacity(0.04), blurRadius: 16, offset: const Offset(0, 8))]),
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Row(children: [
            Container(width: 46, height: 46, decoration: BoxDecoration(color: color.withOpacity(0.10), borderRadius: BorderRadius.circular(16)), child: Icon(Icons.receipt_long_rounded, color: color, size: 23)),
            const SizedBox(width: 10),
            Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Text('Pesanan #$orderId', style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w900, color: Colors.black87)),
              const SizedBox(height: 3),
              Text(firstProduct['name']?.toString() ?? '${items.length} produk toko', maxLines: 1, overflow: TextOverflow.ellipsis, style: const TextStyle(fontSize: 11.5, color: _muted)),
            ])),
            Container(padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 5), decoration: BoxDecoration(color: color.withOpacity(0.10), borderRadius: BorderRadius.circular(999)), child: Text(_labelStatus(status), style: TextStyle(fontSize: 10.8, color: color, fontWeight: FontWeight.w900))),
          ]),
          const SizedBox(height: 12),
          _miniInfo(Icons.person_outline_rounded, 'Pembeli: ${order['name'] ?? '-'}'),
          const SizedBox(height: 6),
          _miniInfo(Icons.shopping_bag_outlined, '${items.length} jenis produk • ${order['seller_item_count'] ?? items.length} item'),
          const SizedBox(height: 10),
          Container(
            padding: const EdgeInsets.all(11),
            decoration: BoxDecoration(color: _surface, borderRadius: BorderRadius.circular(16)),
            child: Column(children: [
              _priceLine('Subtotal toko', _currency(_sellerSubtotal(order))),
              if (discount > 0) ...[const SizedBox(height: 5), _priceLine('Potongan kupon', '-${_currency(discount)}', color: const Color(0xFF15803D))],
              const SizedBox(height: 5),
              _priceLine('Total toko', _currency(_sellerNet(order)), strong: true, color: _primary),
            ]),
          ),
          if (status == 'paid' || status == 'packing' || status == 'delivered') ...[
            const SizedBox(height: 10),
            Wrap(spacing: 8, runSpacing: 8, children: [
              if (status == 'paid') _smallAction('Dikemas', Icons.inventory_2_outlined, _primary, () => updateStatus(orderId, 'packing')),
              if (status == 'packing') _smallAction('Dikirim', Icons.local_shipping_outlined, const Color(0xFF0F766E), () => updateStatus(orderId, 'delivered')),
              if (status == 'delivered') _smallAction('Selesai', Icons.task_alt_rounded, const Color(0xFF15803D), () => updateStatus(orderId, 'done')),
              if (status == 'paid' || status == 'packing') _smallAction('Batalkan', Icons.cancel_outlined, _danger, () => updateStatus(orderId, 'canceled')),
            ]),
          ],
        ]),
      ),
    );
  }

  Widget _priceLine(String label, String value, {bool strong = false, Color? color}) => Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [Text(label, style: TextStyle(fontSize: strong ? 12.5 : 11.5, color: _muted, fontWeight: strong ? FontWeight.w900 : FontWeight.w600)), Text(value, style: TextStyle(fontSize: strong ? 13.5 : 12, color: color ?? Colors.black87, fontWeight: FontWeight.w900))]);

  @override
  Widget build(BuildContext context) {
    final filtered = orders.where((order) => _statusKey(order) == selectedStatus).toList();
    return Scaffold(
      backgroundColor: _surface,
      body: Column(children: [
        _header(),
        _filterBar(),
        Expanded(
          child: loading
              ? const Center(child: CircularProgressIndicator())
              : RefreshIndicator(
                  onRefresh: loadOrders,
                  child: filtered.isEmpty
                      ? ListView(padding: const EdgeInsets.all(24), children: [const SizedBox(height: 110), Icon(Icons.receipt_long_outlined, size: 66, color: Colors.grey.shade400), const SizedBox(height: 12), Center(child: Text('Belum ada pesanan ${_labelStatus(selectedStatus).toLowerCase()}.', style: const TextStyle(color: _muted)))])
                      : ListView.builder(padding: const EdgeInsets.fromLTRB(16, 8, 16, 20), itemCount: filtered.length, itemBuilder: (context, index) => _orderCard(filtered[index])),
                ),
        ),
      ]),
    );
  }
}

class TokoPesananDetailScreen extends StatefulWidget {
  final dynamic order;
  const TokoPesananDetailScreen({Key? key, required this.order}) : super(key: key);

  @override
  State<TokoPesananDetailScreen> createState() => _TokoPesananDetailScreenState();
}

class _TokoPesananDetailScreenState extends State<TokoPesananDetailScreen> {
  static const Color _primary = Color(0xFF0C2442);
  // static const Color _accent = Color(0xFFF39C12);
  static const Color _surface = Color(0xFFF7F8FC);
  static const Color _muted = Color(0xFF64748B);
  // static const Color _danger = Color(0xFFB91C1C);

  Map<String, dynamic>? storeProfile;
  bool loadingStore = true;

  dynamic get order => widget.order;

  @override
  void initState() {
    super.initState();
    _loadStoreProfile();
  }

  Future<void> _loadStoreProfile() async {
    final store = await MarketplaceApiService.myStore();
    if (!mounted) return;
    setState(() {
      storeProfile = store;
      loadingStore = false;
    });
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

  double get _sellerSubtotal => double.tryParse((order['seller_total'] ?? order['total'] ?? 0).toString()) ?? 0;
  double get _sellerNet => (_sellerSubtotal - _sellerDiscount()).clamp(0, double.infinity).toDouble();

  String _couponText() {
    final coupon = _map(_details()['coupon']);
    if (coupon.isEmpty) return '-';
    return '${coupon['coupon_code'] ?? '-'} • ${coupon['coupon_name'] ?? 'Kupon'}';
  }

  String _storeName() => storeProfile?['name']?.toString() ?? storeProfile?['store_name']?.toString() ?? 'Nama Toko';
  String _storePhone() => storeProfile?['phone']?.toString() ?? '-';
  String _storeAddress() {
    final direct = storeProfile?['address']?.toString() ?? '';
    final city = storeProfile?['city_name']?.toString() ?? '';
    final province = storeProfile?['province_name']?.toString() ?? '';
    final parts = [direct, city, province].where((item) => item.trim().isNotEmpty && item != 'null' && item != '-').toList();
    return parts.isEmpty ? '-' : parts.join(', ');
  }

  String _courierText() {
    final courier = order['mode_pengiriman']?.toString() ?? '-';
    final service = order['jenis_pengiriman']?.toString() ?? '-';
    return '$courier - $service'.toUpperCase();
  }

  String _receiptText() {
    final items = order['items'] as List? ?? [];
    final paymentInfo = _map(order['payment_info']);
    final orderId = order['id']?.toString() ?? '-';
    final date = order['created_at']?.toString() ?? DateTime.now().toString();
    final weightTotal = items.fold<num>(0, (sum, raw) {
      final item = _map(raw);
      final option = item['option'];
      int weight = 0;
      if (option is String && option.isNotEmpty) {
        try {
          final decoded = jsonDecode(option);
          if (decoded is Map) weight = int.tryParse(decoded['weight']?.toString() ?? '0') ?? 0;
        } catch (_) {}
      }
      weight = weight == 0 ? int.tryParse(item['weight']?.toString() ?? '0') ?? 0 : weight;
      final qty = int.tryParse(item['quantity']?.toString() ?? '1') ?? 1;
      return sum + (weight * qty);
    });

    final buffer = StringBuffer()
      ..writeln('==============================')
      ..writeln('        STRUK PENGIRIMAN      ')
      ..writeln('==============================')
      ..writeln('KURIR      : ${_courierText()}')
      ..writeln('ORDER      : #ORDER-$orderId')
      ..writeln('TANGGAL    : ${date.length > 19 ? date.substring(0, 19) : date}')
      ..writeln('PAYMENT ID : ${order['payment_transaction_id'] ?? paymentInfo['transaction_id'] ?? '-'}')
      ..writeln('------------------------------')
      ..writeln('PENGIRIM / TOKO')
      ..writeln(_storeName())
      ..writeln('Telp: ${_storePhone()}')
      ..writeln(_storeAddress())
      ..writeln('------------------------------')
      ..writeln('PENERIMA')
      ..writeln('${order['name'] ?? '-'}')
      ..writeln('Telp: ${order['phone'] ?? '-'}')
      ..writeln('${order['address'] ?? '-'}')
      ..writeln('${order['city'] ?? '-'}, ${order['state'] ?? '-'}')
      ..writeln('------------------------------')
      ..writeln('DETAIL PAKET')
      ..writeln('Isi paket  : ${items.length} jenis produk')
      ..writeln('Total item : ${order['seller_item_count'] ?? items.length}')
      ..writeln('Berat      : ${weightTotal <= 0 ? '-' : '$weightTotal gram'}')
      ..writeln('Ongkir     : ${_currency(order['ongkir'])}')
      ..writeln('Nilai COD  : NON COD / SUDAH DIBAYAR')
      ..writeln('------------------------------')
      ..writeln('DAFTAR PRODUK');

    for (final raw in items) {
      final item = _map(raw);
      final product = _map(item['product']);
      final qty = int.tryParse(item['quantity']?.toString() ?? '1') ?? 1;
      final price = double.tryParse(item['price']?.toString() ?? '0') ?? 0;
      buffer.writeln('- ${product['name'] ?? 'Produk'}');
      buffer.writeln('  $qty x ${_currency(price)} = ${_currency(price * qty)}');
    }

    final discount = _sellerDiscount();
    buffer
      ..writeln('------------------------------')
      ..writeln('Subtotal toko : ${_currency(_sellerSubtotal)}');
    if (discount > 0) buffer.writeln('Diskon kupon  : -${_currency(discount)}');
    buffer
      ..writeln('Total toko    : ${_currency(_sellerNet)}')
      ..writeln('==============================')
      ..writeln('Tempelkan struk ini pada paket.')
      ..writeln('Pastikan data penerima sesuai.')
      ..writeln('==============================');

    return buffer.toString();
  }

  void _showShippingReceipt() {
    final receipt = _receiptText();
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => DraggableScrollableSheet(
        initialChildSize: .78,
        minChildSize: .46,
        maxChildSize: .94,
        builder: (context, controller) => Container(
          padding: const EdgeInsets.fromLTRB(16, 14, 16, 16),
          decoration: const BoxDecoration(color: Colors.white, borderRadius: BorderRadius.vertical(top: Radius.circular(28))),
          child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Center(child: Container(width: 44, height: 5, decoration: BoxDecoration(color: const Color(0xFFE2E8F0), borderRadius: BorderRadius.circular(999)))),
            const SizedBox(height: 16),
            Row(children: [const Icon(Icons.local_printshop_rounded, color: _primary), const SizedBox(width: 10), const Expanded(child: Text('Struk Pengiriman', style: TextStyle(fontSize: 16, color: _primary, fontWeight: FontWeight.w900))), if (loadingStore) const SizedBox(width: 16, height: 16, child: CircularProgressIndicator(strokeWidth: 2))]),
            const SizedBox(height: 6),
            const Text('Format memuat header, pengirim, penerima, kurir, detail paket, dan nilai barang seperti struk POS/JNE pada umumnya.', style: TextStyle(fontSize: 11.5, color: _muted, height: 1.35)),
            const SizedBox(height: 12),
            Expanded(
              child: Container(
                width: double.infinity,
                padding: const EdgeInsets.all(14),
                decoration: BoxDecoration(color: _surface, borderRadius: BorderRadius.circular(18), border: Border.all(color: const Color(0xFFE2E8F0))),
                child: SingleChildScrollView(controller: controller, child: SelectableText(receipt, style: const TextStyle(fontFamily: 'monospace', fontSize: 12.5, height: 1.45, color: Color(0xFF111827), fontWeight: FontWeight.w600))),
              ),
            ),
            const SizedBox(height: 12),
            Row(children: [
              Expanded(child: OutlinedButton.icon(onPressed: () { Clipboard.setData(ClipboardData(text: receipt)); ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Struk pengiriman disalin.'))); }, style: OutlinedButton.styleFrom(foregroundColor: _primary, side: const BorderSide(color: _primary), padding: const EdgeInsets.symmetric(vertical: 12), shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14))), icon: const Icon(Icons.copy_rounded, size: 17), label: const Text('SALIN', style: TextStyle(fontSize: 12, fontWeight: FontWeight.w900)))),
              const SizedBox(width: 10),
              Expanded(child: ElevatedButton.icon(onPressed: () { Clipboard.setData(ClipboardData(text: receipt)); Navigator.pop(context); ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Struk siap dicetak. Teks struk sudah disalin.'))); }, style: ElevatedButton.styleFrom(backgroundColor: _primary, foregroundColor: Colors.white, elevation: 0, padding: const EdgeInsets.symmetric(vertical: 12), shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14))), icon: const Icon(Icons.local_printshop_rounded, size: 17), label: const Text('CETAK', style: TextStyle(fontSize: 12, fontWeight: FontWeight.w900)))),
            ]),
          ]),
        ),
      ),
    );
  }

  Widget _section(String title, List<Widget> children) => Container(width: double.infinity, margin: const EdgeInsets.only(bottom: 14), padding: const EdgeInsets.all(14), decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(22), border: Border.all(color: const Color(0xFFE2E8F0)), boxShadow: [BoxShadow(color: _primary.withOpacity(0.04), blurRadius: 16, offset: const Offset(0, 8))]), child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [Text(title, style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w900, color: _primary)), const SizedBox(height: 10), ...children]));

  Widget _row(String label, dynamic value, {Color? color}) => Padding(padding: const EdgeInsets.only(bottom: 8), child: Row(crossAxisAlignment: CrossAxisAlignment.start, children: [SizedBox(width: 112, child: Text(label, style: const TextStyle(fontSize: 12, color: _muted, fontWeight: FontWeight.w600))), Expanded(child: Text(value?.toString() ?? '-', textAlign: TextAlign.right, style: TextStyle(fontSize: 12, fontWeight: FontWeight.w800, color: color ?? Colors.black87)))]));

  Widget _headerDetail() {
    return Container(
      decoration: const BoxDecoration(gradient: LinearGradient(colors: [_primary, Color(0xFF123A68)], begin: Alignment.topLeft, end: Alignment.bottomRight), borderRadius: BorderRadius.vertical(bottom: Radius.circular(30))),
      child: SafeArea(
        bottom: false,
        child: Padding(
          padding: const EdgeInsets.fromLTRB(18, 16, 18, 22),
          child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
              InkWell(onTap: () => Navigator.pop(context), borderRadius: BorderRadius.circular(999), child: Container(width: 42, height: 42, decoration: BoxDecoration(color: Colors.white.withOpacity(0.14), shape: BoxShape.circle, border: Border.all(color: Colors.white.withOpacity(0.12))), child: const Icon(Icons.arrow_back_rounded, color: Colors.white))),
              Container(padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 7), decoration: BoxDecoration(color: Colors.white.withOpacity(0.14), borderRadius: BorderRadius.circular(99), border: Border.all(color: Colors.white.withOpacity(0.12))), child: Text(order['seller_status_label']?.toString() ?? 'Detail', style: const TextStyle(color: Colors.white, fontSize: 12, fontWeight: FontWeight.w800))),
            ]),
            const SizedBox(height: 16),
            Container(
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(color: Colors.white.withOpacity(0.12), borderRadius: BorderRadius.circular(24), border: Border.all(color: Colors.white.withOpacity(0.16))),
              child: Row(children: [
                Container(width: 56, height: 56, decoration: const BoxDecoration(color: Colors.white, shape: BoxShape.circle), child: const Icon(Icons.receipt_long_rounded, color: _primary, size: 30)),
                const SizedBox(width: 14),
                Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                  Text('Pesanan #${order['id'] ?? '-'}', style: const TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.w900)),
                  const SizedBox(height: 5),
                  Text('${order['name'] ?? '-'} • ${_courierText()}', maxLines: 1, overflow: TextOverflow.ellipsis, style: TextStyle(color: Colors.white.withOpacity(0.78), fontSize: 12.5)),
                ])),
              ]),
            ),
          ]),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final items = order['items'] as List? ?? [];
    final paymentInfo = _map(order['payment_info']);
    final discount = _sellerDiscount();
    return Scaffold(
      backgroundColor: _surface,
      body: ListView(padding: EdgeInsets.zero, children: [
        _headerDetail(),
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 16, 16, 26),
          child: Column(children: [
            _section('Profil Toko / Pengirim', [
              _row('Nama toko', _storeName()),
              _row('No HP toko', _storePhone()),
              _row('Alamat toko', _storeAddress()),
            ]),
            _section('Informasi Pembeli', [_row('Nama', order['name']), _row('No HP', order['phone']), _row('Alamat', order['address']), _row('Kota', order['city']), _row('Provinsi', order['state'])]),
            _section('Informasi Pembayaran', [_row('Status transaksi', order['transaction_status']), _row('Payment ID', order['payment_transaction_id'] ?? paymentInfo['transaction_id']), _row('Metode', order['payment_type'] ?? paymentInfo['payment_type']), _row('Bank', order['payment_bank'] ?? '-')]),
            _section('Produk Toko Ini', [
              ...items.map((item) {
                final product = _map(item is Map ? item['product'] : null);
                final qty = int.tryParse(_map(item)['quantity']?.toString() ?? '1') ?? 1;
                final price = double.tryParse(_map(item)['price']?.toString() ?? '0') ?? 0;
                final lineTotal = _map(item)['line_total'] ?? price * qty;
                return Container(margin: const EdgeInsets.only(bottom: 10), padding: const EdgeInsets.all(11), decoration: BoxDecoration(color: _surface, borderRadius: BorderRadius.circular(16)), child: Row(children: [Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [Text(product['name']?.toString() ?? 'Produk', style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w900, color: _primary)), const SizedBox(height: 3), Text('${_currency(price)} x $qty', style: const TextStyle(fontSize: 11.5, color: _muted))])), Text(_currency(lineTotal), style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w900, color: _primary))]));
              }).toList(),
              const Divider(height: 18),
              _row('Subtotal toko', _currency(_sellerSubtotal)),
              if (discount > 0) ...[_row('Kupon', _couponText()), _row('Potongan', '-${_currency(discount)}', color: const Color(0xFF15803D))],
              _row('Total toko', _currency(_sellerNet), color: _primary),
            ]),
          ]),
        ),
      ]),
      bottomNavigationBar: SafeArea(
        child: Container(
          padding: const EdgeInsets.fromLTRB(16, 10, 16, 14),
          decoration: BoxDecoration(color: Colors.white, boxShadow: [BoxShadow(color: Colors.black.withOpacity(.08), blurRadius: 16, offset: const Offset(0, -5))]),
          child: SizedBox(
            height: 44,
            child: ElevatedButton.icon(
              onPressed: _showShippingReceipt,
              style: ElevatedButton.styleFrom(backgroundColor: _primary, foregroundColor: Colors.white, elevation: 0, shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14))),
              icon: const Icon(Icons.local_printshop_rounded, size: 18),
              label: const Text('CETAK STRUK PENGIRIMAN', style: TextStyle(fontSize: 12.5, fontWeight: FontWeight.w900)),
            ),
          ),
        ),
      ),
    );
  }
}

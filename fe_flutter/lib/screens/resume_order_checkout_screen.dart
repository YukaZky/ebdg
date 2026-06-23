import 'dart:async';
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../services/api_service.dart';
import '../services/checkout_api_service.dart';
import 'checkout_screen.dart';
import 'order_confirmation_screen.dart';

class ResumeOrderCheckoutScreen extends StatefulWidget {
  final Map<String, dynamic> order;

  const ResumeOrderCheckoutScreen({Key? key, required this.order}) : super(key: key);

  @override
  State<ResumeOrderCheckoutScreen> createState() => _ResumeOrderCheckoutScreenState();
}

class _ResumeOrderCheckoutScreenState extends State<ResumeOrderCheckoutScreen> {
  static const Color _navy = Color(0xFF0B1F4D);
  static const Color _pageBg = Color(0xFFF5F7FB);
  Timer? _timer;
  bool _loading = false;
  late Map<String, dynamic> _order;
  Duration _timeLeft = Duration.zero;

  @override
  void initState() {
    super.initState();
    _order = Map<String, dynamic>.from(widget.order);
    _syncTimer();
    _timer = Timer.periodic(const Duration(seconds: 1), (_) {
      if (!mounted) return;
      setState(() {
        if (_timeLeft.inSeconds > 0) _timeLeft -= const Duration(seconds: 1);
      });
    });
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
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

  List<dynamic> _items() => _order['items'] is List ? _order['items'] as List : [];
  num _num(dynamic value) => value is num ? value : num.tryParse(value?.toString() ?? '') ?? 0;
  String _money(dynamic value) => 'Rp ${_num(value).toStringAsFixed(0)}';

  Map<String, dynamic> get _transaction => _map(_order['transaction']);
  Map<String, dynamic> get _details => _decodeMap(_transaction['payment_details']);
  Map<String, dynamic> get _paymentInfo => _map(_details['payment_info']);

  bool get _isPaid {
    final status = _transaction['status']?.toString();
    return status == 'approved' || status == 'settlement' || status == 'capture';
  }

  String? get _expiry => _paymentInfo['expiry_time']?.toString();
  String? get _vaNumber => _paymentInfo['va_number']?.toString();
  String? get _qrCodeUrl => _paymentInfo['qr_code_url']?.toString();

  void _syncTimer() {
    try {
      _timeLeft = _expiry == null ? Duration.zero : DateTime.parse(_expiry!).difference(DateTime.now());
      if (_timeLeft.isNegative) _timeLeft = Duration.zero;
    } catch (_) {
      _timeLeft = Duration.zero;
    }
  }

  String get _timerText {
    if (_isPaid) return 'Pembayaran sudah diterima';
    if (_timeLeft.inSeconds <= 0) return 'Waktu pembayaran habis';
    final hours = _timeLeft.inHours.toString().padLeft(2, '0');
    final minutes = _timeLeft.inMinutes.remainder(60).toString().padLeft(2, '0');
    final seconds = _timeLeft.inSeconds.remainder(60).toString().padLeft(2, '0');
    return '$hours : $minutes : $seconds';
  }

  Future<void> _refreshStatus() async {
    final id = _order['id']?.toString();
    if (id == null) return;
    setState(() => _loading = true);
    final status = await CheckoutApiService.checkOrderStatus(id);
    final response = await CheckoutApiService.getOrder(id);
    if (!mounted) return;
    if (response != null && response['success'] == true && response['order'] != null) {
      _order = Map<String, dynamic>.from(response['order']);
      _syncTimer();
    }
    setState(() => _loading = false);
    final trx = status?['transaction_status']?.toString();
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text((trx == 'approved' || trx == 'settlement' || trx == 'capture') ? 'Pembayaran sudah diterima.' : 'Pembayaran masih menunggu proses.')));
  }

  Future<void> _completeCheckout() async {
    final id = _order['id']?.toString();
    if (id == null) return;
    setState(() => _loading = true);
    final response = await CheckoutApiService.completeCheckout(id);
    if (!mounted) return;
    setState(() => _loading = false);
    if (response != null && response['success'] == true && response['order'] != null) {
      Navigator.pushReplacement(context, MaterialPageRoute(builder: (_) => OrderConfirmationScreen(order: Map<String, dynamic>.from(response['order']))));
    } else {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Checkout akhir belum bisa diselesaikan.')));
    }
  }

  Future<void> _editCheckout() async {
    final id = _order['id']?.toString();
    if (id != null) {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString('active_checkout_order_id', id);
      await prefs.remove('active_checkout_signature');
    }
    if (!mounted) return;
    Navigator.pushReplacement(
      context,
      MaterialPageRoute(
        builder: (_) => CheckoutScreen(
          totalAmount: _num(_order['subtotal']).toDouble(),
          totalWeight: _totalWeight(),
          cartItems: _cartItemsFromOrder(),
        ),
      ),
    );
  }

  List<Map<String, dynamic>> _cartItemsFromOrder() {
    return _items().map((raw) {
      final item = _map(raw);
      final product = _map(item['product']);
      final option = _decodeMap(item['option']);
      return {
        'id': item['id'],
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

  double _totalWeight() {
    return _cartItemsFromOrder().fold<double>(0, (sum, item) {
      final weight = _num(item['weight']);
      final qty = _num(item['quantity']);
      return sum + ((weight <= 0 ? 1000 : weight) * qty);
    });
  }

  void _copyVa() {
    if (_vaNumber == null) return;
    Clipboard.setData(ClipboardData(text: _vaNumber!));
    ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Nomor VA disalin.')));
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: _pageBg,
      appBar: AppBar(
        title: const Text('Lanjutkan Checkout', style: TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.w800)),
        backgroundColor: _navy,
        iconTheme: const IconThemeData(color: Colors.white),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.fromLTRB(16, 16, 16, 120),
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          _paymentCard(),
          const SizedBox(height: 14),
          _section('Daftar Barang'),
          _productCard(),
          const SizedBox(height: 14),
          _section('Total Order'),
          _totalCard(),
        ]),
      ),
      bottomSheet: Container(
        padding: const EdgeInsets.fromLTRB(16, 12, 16, 16),
        decoration: BoxDecoration(color: Colors.white, boxShadow: [BoxShadow(color: Colors.black.withOpacity(.08), blurRadius: 16, offset: const Offset(0, -5))]),
        child: SafeArea(child: Column(mainAxisSize: MainAxisSize.min, children: [
          if (_isPaid)
            SizedBox(width: double.infinity, child: ElevatedButton(onPressed: _loading ? null : _completeCheckout, style: _buttonStyle(), child: _loading ? const SizedBox(width: 18, height: 18, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2)) : const Text('SELESAIKAN CHECKOUT', style: TextStyle(color: Colors.white, fontSize: 13, fontWeight: FontWeight.w800))))
          else
            SizedBox(width: double.infinity, child: OutlinedButton.icon(onPressed: _loading ? null : _refreshStatus, icon: const Icon(Icons.refresh_rounded), label: const Text('REFRESH STATUS'), style: OutlinedButton.styleFrom(foregroundColor: _navy, side: const BorderSide(color: _navy), padding: const EdgeInsets.symmetric(vertical: 13), textStyle: const TextStyle(fontSize: 13, fontWeight: FontWeight.w800)))),
          const SizedBox(height: 8),
          SizedBox(width: double.infinity, child: TextButton(onPressed: _editCheckout, child: const Text('Ubah alamat, kurir, atau metode pembayaran', style: TextStyle(fontSize: 12, fontWeight: FontWeight.w700)))),
        ])),
      ),
    );
  }

  ButtonStyle _buttonStyle() => ElevatedButton.styleFrom(backgroundColor: _navy, padding: const EdgeInsets.symmetric(vertical: 13), shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)));
  Widget _section(String text) => Padding(padding: const EdgeInsets.only(bottom: 8), child: Text(text, style: const TextStyle(fontSize: 13, color: _navy, fontWeight: FontWeight.w900)));
  BoxDecoration _box() => BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(16), border: Border.all(color: const Color(0xFFE2E8F0)));

  Widget _paymentCard() => Container(
    width: double.infinity,
    padding: const EdgeInsets.all(16),
    decoration: BoxDecoration(gradient: const LinearGradient(colors: [_navy, Color(0xFF163A73)]), borderRadius: BorderRadius.circular(18)),
    child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      Text(_isPaid ? 'PEMBAYARAN DITERIMA' : 'MENUNGGU PEMBAYARAN', style: const TextStyle(color: Colors.white, fontSize: 11, fontWeight: FontWeight.w900)),
      const SizedBox(height: 12),
      Text(_timerText, style: const TextStyle(color: Colors.white, fontSize: 24, fontWeight: FontWeight.w900)),
      const SizedBox(height: 14),
      Container(width: double.infinity, padding: const EdgeInsets.all(14), decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(14)), child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        if (_vaNumber != null) ...[
          const Text('Nomor Virtual Account', style: TextStyle(fontSize: 11, color: Color(0xFF64748B), fontWeight: FontWeight.w700)),
          Row(children: [Expanded(child: SelectableText(_vaNumber!, style: const TextStyle(fontSize: 18, color: _navy, fontWeight: FontWeight.w900))), IconButton(onPressed: _copyVa, icon: const Icon(Icons.copy_rounded, color: _navy))]),
        ],
        if (_qrCodeUrl != null) Center(child: Image.network(_qrCodeUrl!, width: 190, height: 190, fit: BoxFit.contain)),
        if (_vaNumber == null && _qrCodeUrl == null) const Text('Detail VA/QRIS tidak tersedia. Refresh status atau ubah metode pembayaran.', style: TextStyle(fontSize: 12, color: Color(0xFF475569))),
      ])),
    ]),
  );

  Widget _productCard() => Container(width: double.infinity, padding: const EdgeInsets.all(14), decoration: _box(), child: Column(children: _items().map((raw) {
    final item = _map(raw);
    final product = _map(item['product']);
    final qty = _num(item['quantity']);
    final price = _num(item['price']);
    return Padding(padding: const EdgeInsets.only(bottom: 10), child: Row(children: [Expanded(child: Text('${qty.toInt()}x ${product['name'] ?? 'Produk'}', maxLines: 1, overflow: TextOverflow.ellipsis, style: const TextStyle(fontSize: 12.5, fontWeight: FontWeight.w700))), Text(_money(price * qty), style: const TextStyle(fontSize: 12, color: _navy, fontWeight: FontWeight.w900))]));
  }).toList()));

  Widget _totalCard() => Container(width: double.infinity, padding: const EdgeInsets.all(14), decoration: _box(), child: Column(children: [
    _row('Subtotal Produk', _money(_order['subtotal'])),
    const SizedBox(height: 7),
    _row('Ongkir', _money(_order['ongkir'])),
    const Divider(height: 22),
    _row('Total Order', _money(_order['total']), strong: true),
  ]));

  Widget _row(String label, String value, {bool strong = false}) => Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [Text(label, style: TextStyle(fontSize: strong ? 14 : 12, color: strong ? _navy : const Color(0xFF64748B), fontWeight: strong ? FontWeight.w900 : FontWeight.w500)), Text(value, style: TextStyle(fontSize: strong ? 18 : 12.5, color: strong ? _navy : const Color(0xFF111827), fontWeight: FontWeight.w900))]);
}

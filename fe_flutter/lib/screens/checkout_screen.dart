import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../models/payment_method_model.dart';
import '../services/api_service.dart';
import '../services/checkout_api_service.dart';
import 'admin/address_list_screen.dart';
import 'metode_screen.dart';
import 'order_confirmation_screen.dart';

enum PaymentState { initial, pending, approved, expired }

class CheckoutScreen extends StatefulWidget {
  final double totalAmount;
  final double totalWeight;
  final List<Map<String, dynamic>> cartItems;
  const CheckoutScreen({Key? key, required this.totalAmount, required this.totalWeight, required this.cartItems}) : super(key: key);
  @override
  State<CheckoutScreen> createState() => _CheckoutScreenState();
}

class _CheckoutScreenState extends State<CheckoutScreen> {
  final _couriers = ['jne', 'pos', 'tiki'];
  Map<String, dynamic>? _addr;
  List _costs = [];
  String? _courier, _service, _orderId, _va, _qr;
  double _shipping = 0;
  PaymentMethodModel? _method;
  PaymentState _state = PaymentState.initial;
  bool _loadingAddr = true, _loadingCost = false, _loading = false;
  Timer? _timer;
  Duration _left = Duration.zero;
  Map<String, dynamic>? _order;

  double get _total => widget.totalAmount + _shipping;
  bool get _locked => _state == PaymentState.pending || _state == PaymentState.approved;
  String get _address => _addr?['address']?.toString() ?? _addr?['detail_address']?.toString() ?? '-';
  String get _phone => _addr?['phone']?.toString() ?? '-';
  String get _province => _addr?['province_name']?.toString() ?? 'Unknown';
  String get _city => _addr?['city_name']?.toString() ?? 'Unknown';
  String get _shipName => '${_courier?.toUpperCase()} - $_service';

  @override
  void initState() { super.initState(); _loadAddress(); }
  @override
  void dispose() { _timer?.cancel(); super.dispose(); }

  Future<void> _loadAddress() async {
    setState(() => _loadingAddr = true);
    final data = await ApiService.getUserAddresses();
    if (!mounted) return;
    Map<String, dynamic>? chosen;
    if (data is List && data.isNotEmpty) {
      try {
        chosen = Map<String, dynamic>.from(data.firstWhere((a) => a['isdefault'] == 1 || a['isdefault'] == '1' || a['isdefault'] == true || a['is_main'] == 1 || a['is_main'] == '1' || a['is_main'] == true));
      } catch (_) { chosen = Map<String, dynamic>.from(data.first); }
    }
    setState(() { _addr = chosen; _loadingAddr = false; _costs = []; _service = null; _shipping = 0; });
    if (_addr != null && _courier != null) _loadShipping();
  }

  Future<void> _loadShipping() async {
    if (_addr == null || _addr!['city_id'] == null || _courier == null) return;
    setState(() { _loadingCost = true; _costs = []; _service = null; _shipping = 0; });
    final data = await ApiService.checkCost(_addr!['city_id'].toString(), widget.totalWeight.toInt(), _courier!);
    if (!mounted) return;
    setState(() {
      _loadingCost = false; _costs = data;
      if (data.isNotEmpty && data[0]['cost'] is List && data[0]['cost'].isNotEmpty) {
        _service = data[0]['service']?.toString();
        _shipping = double.tryParse(data[0]['cost'][0]['value']?.toString() ?? '0') ?? 0;
      }
    });
  }

  Future<void> _pickMethod() async {
    final result = await Navigator.push(context, MaterialPageRoute(builder: (_) => const MetodeScreen()));
    if (result is PaymentMethodModel) setState(() => _method = result);
  }

  Future<void> _payNow() async {
    if (_addr == null) return _toast('Harap atur alamat terlebih dahulu.', error: true);
    if (_courier == null || _service == null || _shipping <= 0) return _toast('Pilih kurir dan layanan pengiriman.', error: true);
    if (_method == null) return _toast('Pilih metode pembayaran terlebih dahulu.', error: true);
    setState(() => _loading = true);
    final res = await CheckoutApiService.checkout(address: _address, phone: _phone, provinceName: _province, cityName: _city, courier: _shipName, shippingCost: _shipping, cartItems: widget.cartItems, paymentType: _method!.paymentType, bankCode: _method!.bankCode);
    if (!mounted) return;
    setState(() => _loading = false);
    if (res == null || res['success'] != true) return _toast('Gagal memproses pesanan.', error: true);
    final info = res['payment_info'];
    final mid = res['midtrans_response'];
    setState(() {
      if (res['order'] != null) { _order = Map<String, dynamic>.from(res['order']); _orderId = res['order']['id'].toString(); }
      _va = _readVa(info, mid); _qr = _readQr(info, mid); _state = PaymentState.pending;
      _startTimer(_readExpiry(info, mid));
    });
  }

  String? _readVa(dynamic info, dynamic mid) {
    if (info is Map && info['va_number'] != null) return info['va_number'].toString();
    if (mid is Map && mid['va_numbers'] is List && mid['va_numbers'].isNotEmpty) return mid['va_numbers'][0]['va_number']?.toString();
    if (mid is Map && mid['permata_va_number'] != null) return mid['permata_va_number'].toString();
    if (mid is Map && mid['bill_key'] != null) return 'Bill Key: ${mid['bill_key']}\nBiller Code: ${mid['biller_code'] ?? ''}';
    return null;
  }
  String? _readQr(dynamic info, dynamic mid) {
    if (info is Map && info['qr_code_url'] != null) return info['qr_code_url'].toString();
    if (mid is Map && mid['actions'] is List) { for (final a in mid['actions']) { if (a is Map && a['name'] == 'generate-qr-code') return a['url']?.toString(); } }
    return null;
  }
  String? _readExpiry(dynamic info, dynamic mid) => info is Map && info['expiry_time'] != null ? info['expiry_time'].toString() : mid is Map && mid['expiry_time'] != null ? mid['expiry_time'].toString() : null;

  void _startTimer(String? expiry) {
    _timer?.cancel();
    try { _left = expiry == null ? const Duration(hours: 24) : DateTime.parse(expiry).difference(DateTime.now()); } catch (_) { _left = const Duration(hours: 24); }
    if (_left.isNegative) { _left = Duration.zero; _state = PaymentState.expired; return; }
    _timer = Timer.periodic(const Duration(seconds: 1), (t) {
      if (!mounted) return;
      setState(() { if (_left.inSeconds <= 0) { t.cancel(); _state = PaymentState.expired; } else { _left -= const Duration(seconds: 1); } });
    });
  }

  Future<void> _refreshStatus() async {
    if (_orderId == null) return;
    setState(() => _loading = true);
    final res = await CheckoutApiService.checkOrderStatus(_orderId!);
    if (!mounted) return;
    setState(() => _loading = false);
    final s = res?['transaction_status'];
    if (s == 'settlement' || s == 'capture' || s == 'approved') { setState(() => _state = PaymentState.approved); _timer?.cancel(); _toast('Pembayaran berhasil diterima.'); }
    else if (s == 'expire' || s == 'cancel' || s == 'declined') { setState(() => _state = PaymentState.expired); _timer?.cancel(); }
    else { _toast('Pembayaran masih menunggu proses.'); }
  }

  void _confirm() {
    if (_state != PaymentState.approved) return _toast('Konfirmasi pesanan baru bisa dibuka setelah pembayaran diterima.');
    if (_order == null) return;
    Navigator.pushAndRemoveUntil(context, MaterialPageRoute(builder: (_) => OrderConfirmationScreen(order: _order!)), (_) => false);
  }

  void _toast(String msg, {bool error = false}) => ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(msg), backgroundColor: error ? Colors.red : null));
  double _price(Map<String, dynamic> item) => double.tryParse((item['price'] ?? item['product']?['regular_price'] ?? 0).toString()) ?? 0;
  int _qty(Map<String, dynamic> item) => int.tryParse((item['quantity'] ?? 1).toString()) ?? 1;
  String _img(dynamic image) { final v = image?.toString().trim() ?? ''; if (v.isEmpty || v == 'null') return ''; if (v.startsWith('http')) return v; final base = ApiService.baseUrl.replaceFirst(RegExp(r'/api/?$'), ''); final c = v.startsWith('/') ? v.substring(1) : v; return c.startsWith('uploads/') || c.startsWith('storage/') ? '$base/$c' : '$base/uploads/products/$c'; }

  @override
  Widget build(BuildContext context) {
    final timer = '${_left.inHours.remainder(24).toString().padLeft(2, '0')} : ${_left.inMinutes.remainder(60).toString().padLeft(2, '0')} : ${_left.inSeconds.remainder(60).toString().padLeft(2, '0')}';
    return Scaffold(
      backgroundColor: const Color(0xFFF5F7FA),
      appBar: AppBar(title: const Text('Pengiriman & Checkout', style: TextStyle(color: Colors.black, fontWeight: FontWeight.bold)), backgroundColor: Colors.white, iconTheme: const IconThemeData(color: Colors.black), elevation: .5),
      body: SingleChildScrollView(padding: const EdgeInsets.all(16), child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [_addressCard(), const SizedBox(height: 16), _shippingCard(), const SizedBox(height: 16), _paymentCard(timer), const SizedBox(height: 16), _summaryCard(), const SizedBox(height: 120)])),
      bottomSheet: Container(padding: const EdgeInsets.all(16), decoration: BoxDecoration(color: Colors.white, boxShadow: [BoxShadow(color: Colors.grey.withOpacity(.12), blurRadius: 10, offset: const Offset(0, -5))]), child: SafeArea(child: Column(mainAxisSize: MainAxisSize.min, children: [Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [const Text('Total Tagihan', style: TextStyle(color: Colors.grey, fontSize: 16)), Text('Rp ${_total.toStringAsFixed(0)}', style: const TextStyle(fontSize: 22, fontWeight: FontWeight.w900, color: Color(0xFFE65100)))]), const SizedBox(height: 12), SizedBox(width: double.infinity, child: _bottomButton())]))),
    );
  }

  Widget _box(Widget child) => Container(width: double.infinity, padding: const EdgeInsets.all(16), decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(16), border: Border.all(color: Colors.grey.shade200), boxShadow: [BoxShadow(color: Colors.black.withOpacity(.03), blurRadius: 10, offset: const Offset(0, 4))]), child: child);
  Widget _addressCard() {
    if (_loadingAddr) return const Center(child: Padding(padding: EdgeInsets.all(20), child: CircularProgressIndicator(color: Color(0xFFE65100))));
    if (_addr == null) return InkWell(onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const AddressListScreen())).then((_) => _loadAddress()), child: _box(const Row(children: [Icon(Icons.location_off, color: Colors.red), SizedBox(width: 12), Expanded(child: Text('Alamat belum diatur. Klik di sini.', style: TextStyle(color: Colors.red, fontWeight: FontWeight.bold)))])));
    return _box(Column(crossAxisAlignment: CrossAxisAlignment.start, children: [Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [const Text('Alamat Pengiriman', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)), TextButton(onPressed: _locked ? null : () => Navigator.push(context, MaterialPageRoute(builder: (_) => const AddressListScreen())).then((_) => _loadAddress()), child: const Text('Ubah'))]), const Divider(), Text('${_addr!['name']} | ${_addr!['phone']}', style: const TextStyle(fontWeight: FontWeight.w600)), const SizedBox(height: 6), Text(_address), Text('${_addr!['city_name']}, ${_addr!['province_name']} - ${_addr!['postal_code']}', style: TextStyle(color: Colors.grey.shade700))]));
  }
  Widget _shippingCard() => _addr == null ? const SizedBox.shrink() : _box(Column(crossAxisAlignment: CrossAxisAlignment.start, children: [const Text('Kurir Pengiriman', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)), const SizedBox(height: 12), DropdownButtonFormField<String>(decoration: const InputDecoration(labelText: 'Pilih Ekspedisi', border: OutlineInputBorder()), value: _courier, items: _couriers.map((c) => DropdownMenuItem(value: c, child: Text(c.toUpperCase()))).toList(), onChanged: _locked ? null : (v) { setState(() => _courier = v); _loadShipping(); }), const SizedBox(height: 16), if (_loadingCost) const Center(child: CircularProgressIndicator()) else if (_costs.isNotEmpty) DropdownButtonFormField<String>(isExpanded: true, decoration: const InputDecoration(labelText: 'Pilih Layanan', border: OutlineInputBorder()), value: _service, items: _costs.map<DropdownMenuItem<String>>((o) { final cost = o['cost'] as List?; final val = cost != null && cost.isNotEmpty ? cost[0]['value']?.toString() ?? '0' : '0'; return DropdownMenuItem(value: o['service']?.toString(), child: Text('${o['service']} - Rp $val', overflow: TextOverflow.ellipsis)); }).toList(), onChanged: _locked ? null : (v) { final s = _costs.firstWhere((o) => o['service']?.toString() == v); final cost = s['cost'] as List?; setState(() { _service = v; _shipping = double.tryParse(cost != null && cost.isNotEmpty ? cost[0]['value']?.toString() ?? '0' : '0') ?? 0; }); })]));
  Widget _paymentCard(String timer) => _box(Column(crossAxisAlignment: CrossAxisAlignment.start, children: [Row(children: [const Icon(Icons.payment, color: Color(0xFFE65100)), const SizedBox(width: 10), const Expanded(child: Text('Metode Pembayaran', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16))), if (_state == PaymentState.pending) const Chip(label: Text('Menunggu')) else if (_state == PaymentState.approved) const Chip(label: Text('Lunas'))]), const SizedBox(height: 12), if (_state == PaymentState.initial || _state == PaymentState.expired) InkWell(onTap: _pickMethod, child: Container(padding: const EdgeInsets.all(14), decoration: BoxDecoration(border: Border.all(color: Colors.grey.shade300), borderRadius: BorderRadius.circular(12)), child: Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [Expanded(child: Text(_method?.name ?? 'Pilih Metode Pembayaran', style: TextStyle(color: _method == null ? Colors.grey : Colors.black, fontWeight: _method == null ? FontWeight.normal : FontWeight.bold))), const Icon(Icons.arrow_forward_ios, size: 16, color: Colors.grey)]))), if (_state == PaymentState.expired) const Padding(padding: EdgeInsets.only(top: 10), child: Text('Sesi pembayaran berakhir. Silakan pilih metode kembali.', style: TextStyle(color: Colors.red))), if (_state == PaymentState.pending) ...[Text(_method?.name ?? 'Metode Pembayaran', style: const TextStyle(fontWeight: FontWeight.bold)), const Text('Status: Menunggu Pembayaran', style: TextStyle(color: Colors.orange, fontWeight: FontWeight.w600)), const SizedBox(height: 14), Center(child: Text(timer, style: const TextStyle(fontSize: 30, color: Colors.red, fontWeight: FontWeight.bold))), const Divider(height: 28), if (_va != null) Row(children: [Expanded(child: SelectableText(_va!, style: const TextStyle(fontSize: 22, fontWeight: FontWeight.bold))), TextButton.icon(onPressed: () { Clipboard.setData(ClipboardData(text: _va!)); _toast('Nomor VA disalin.'); }, icon: const Icon(Icons.copy), label: const Text('Salin'))]), if (_qr != null) Center(child: Image.network(_qr!, width: 220, height: 200)), if (_va == null && _qr == null) const Text('Selesaikan pembayaran sesuai instruksi metode yang dipilih.'), const SizedBox(height: 14), SizedBox(width: double.infinity, child: OutlinedButton.icon(onPressed: _loading ? null : _refreshStatus, icon: const Icon(Icons.refresh), label: const Text('Refresh Status Pembayaran')))], if (_state == PaymentState.approved) const Center(child: Column(children: [Icon(Icons.check_circle, color: Colors.green, size: 64), SizedBox(height: 8), Text('Pembayaran Berhasil!', style: TextStyle(color: Colors.green, fontWeight: FontWeight.bold, fontSize: 18))]))]));
  Widget _summaryCard() => _box(Column(crossAxisAlignment: CrossAxisAlignment.start, children: [const Text('Ringkasan Pesanan', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)), const SizedBox(height: 12), ...widget.cartItems.map((item) { final product = item['product'] ?? {}; final price = _price(item); final qty = _qty(item); final image = _img(item['selected_image'] ?? product['image']); return Padding(padding: const EdgeInsets.only(bottom: 12), child: Row(children: [Container(width: 50, height: 50, clipBehavior: Clip.antiAlias, decoration: BoxDecoration(borderRadius: BorderRadius.circular(8), border: Border.all(color: Colors.grey.shade200)), child: image.isEmpty ? const Icon(Icons.image, color: Colors.grey) : Image.network(image, fit: BoxFit.cover, errorBuilder: (_, __, ___) => const Icon(Icons.image_not_supported, color: Colors.grey))), const SizedBox(width: 12), Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [Text(product['name'] ?? 'Produk', maxLines: 1, overflow: TextOverflow.ellipsis, style: const TextStyle(fontWeight: FontWeight.w600)), Text('$qty x Rp ${price.toStringAsFixed(0)}', style: TextStyle(color: Colors.grey[600], fontSize: 12))])), Text('Rp ${(price * qty).toStringAsFixed(0)}', style: const TextStyle(fontWeight: FontWeight.bold))])); })]));
  Widget _bottomButton() { if (_state == PaymentState.pending) return ElevatedButton(onPressed: null, style: ElevatedButton.styleFrom(disabledBackgroundColor: Colors.grey.shade400, padding: const EdgeInsets.symmetric(vertical: 14)), child: const Text('MENUNGGU PEMBAYARAN...', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold))); if (_state == PaymentState.approved) return ElevatedButton(onPressed: _confirm, style: ElevatedButton.styleFrom(backgroundColor: Colors.green, padding: const EdgeInsets.symmetric(vertical: 14)), child: const Text('SELESAIKAN PESANAN', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold))); return ElevatedButton(onPressed: _loading ? null : _payNow, style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFFE65100), disabledBackgroundColor: Colors.grey.shade300, padding: const EdgeInsets.symmetric(vertical: 14)), child: _loading ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2)) : const Text('BAYAR SEKARANG', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 16))); }
}

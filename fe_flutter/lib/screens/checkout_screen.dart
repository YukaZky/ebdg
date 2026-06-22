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

  const CheckoutScreen({super.key, required this.totalAmount, required this.totalWeight, required this.cartItems});

  @override
  State<CheckoutScreen> createState() => _CheckoutScreenState();
}

class _CheckoutScreenState extends State<CheckoutScreen> {
  final List<String> _couriers = ['jne', 'pos', 'tiki'];
  Map<String, dynamic>? _address;
  List _shippingOptions = [];
  String? _courier;
  String? _service;
  double _shippingCost = 0;
  String? _orderId;
  String? _vaNumber;
  String? _qrCodeUrl;
  String? _finalizedSignature;
  PaymentMethodModel? _method;
  PaymentState _paymentState = PaymentState.initial;
  Map<String, dynamic>? _order;
  Timer? _timer;
  Duration _timeLeft = Duration.zero;
  bool _loadingAddress = true;
  bool _loadingShipping = false;
  bool _finalizing = false;
  bool _loadingPayment = false;

  bool get _paymentLocked => _paymentState == PaymentState.pending || _paymentState == PaymentState.approved;

  @override
  void initState() {
    super.initState();
    _fetchAddress();
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  String get _addressText => _address?['address']?.toString() ?? _address?['detail_address']?.toString() ?? '-';
  String get _phone => _address?['phone']?.toString() ?? '-';
  String get _province => _address?['province_name']?.toString() ?? 'Unknown';
  String get _city => _address?['city_name']?.toString() ?? 'Unknown';
  String get _courierWithService => '${_courier?.toUpperCase()} - $_service';
  double get _grandTotal => widget.totalAmount + _shippingCost;

  String get _signature {
    final itemKey = widget.cartItems.map((e) => '${e['id']}:${e['product_id'] ?? e['product']?['id']}:${e['quantity']}').join('|');
    return '$_addressText|$_phone|$_province|$_city|$_courierWithService|$_shippingCost|$itemKey';
  }

  String _imageUrl(dynamic image) {
    final value = image?.toString().trim() ?? '';
    if (value.isEmpty || value == 'null') return '';
    if (value.startsWith('http')) return value;
    final base = ApiService.baseUrl.replaceFirst(RegExp(r'/api/?$'), '');
    final clean = value.startsWith('/') ? value.substring(1) : value;
    if (clean.startsWith('uploads/') || clean.startsWith('storage/')) return '$base/$clean';
    return '$base/uploads/products/$clean';
  }

  Future<void> _fetchAddress() async {
    setState(() => _loadingAddress = true);
    final data = await ApiService.getUserAddresses();
    if (!mounted) return;
    Map<String, dynamic>? mainAddress;
    if (data is List && data.isNotEmpty) {
      try {
        mainAddress = Map<String, dynamic>.from(data.firstWhere((a) => a['isdefault'] == 1 || a['isdefault'] == '1' || a['is_main'] == 1 || a['is_main'] == '1' || a['isdefault'] == true || a['is_main'] == true));
      } catch (_) {
        mainAddress = Map<String, dynamic>.from(data.first);
      }
    }
    setState(() {
      _address = mainAddress;
      _loadingAddress = false;
      _shippingOptions = [];
      _service = null;
      _shippingCost = 0;
      _finalizedSignature = null;
    });
    if (_courier != null && _address != null) _calculateShipping();
  }

  Future<void> _calculateShipping() async {
    if (_address == null || _address!['city_id'] == null || _courier == null) return;
    setState(() {
      _loadingShipping = true;
      _shippingOptions = [];
      _service = null;
      _shippingCost = 0;
      _method = null;
      _vaNumber = null;
      _qrCodeUrl = null;
      _paymentState = PaymentState.initial;
      _finalizedSignature = null;
      _timer?.cancel();
    });
    final cityId = _address!['city_id'].toString();
    final data = await ApiService.checkCost(cityId, widget.totalWeight.toInt(), _courier!);
    if (!mounted) return;
    setState(() {
      _loadingShipping = false;
      _shippingOptions = data;
      if (data.isNotEmpty && data[0]['cost'] is List && data[0]['cost'].isNotEmpty) {
        _service = data[0]['service']?.toString();
        _shippingCost = double.tryParse(data[0]['cost'][0]['value']?.toString() ?? '0') ?? 0;
      }
    });
    await _finalizeIfReady();
  }

  void _chooseService(String? value) {
    final selected = _shippingOptions.firstWhere((e) => e['service']?.toString() == value, orElse: () => null);
    final costList = selected == null ? null : selected['cost'] as List?;
    setState(() {
      _service = value;
      _shippingCost = double.tryParse((costList != null && costList.isNotEmpty) ? costList[0]['value']?.toString() ?? '0' : '0') ?? 0;
      _method = null;
      _vaNumber = null;
      _qrCodeUrl = null;
      _paymentState = PaymentState.initial;
      _finalizedSignature = null;
      _timer?.cancel();
    });
    _finalizeIfReady();
  }

  Future<bool> _finalizeIfReady({bool showError = false}) async {
    if (_finalizing) return false;
    if (_address == null || _courier == null || _service == null || _shippingCost <= 0) {
      if (showError && mounted) {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Lengkapi alamat dan ongkir terlebih dahulu.'), backgroundColor: Colors.red));
      }
      return false;
    }
    if (_orderId != null && _finalizedSignature == _signature) return true;
    setState(() => _finalizing = true);
    final response = await CheckoutApiService.finalizeOrder(
      orderId: _orderId,
      address: _addressText,
      phone: _phone,
      provinceName: _province,
      cityName: _city,
      courier: _courierWithService,
      shippingCost: _shippingCost,
      cartItems: widget.cartItems,
    );
    if (!mounted) return false;
    setState(() => _finalizing = false);
    if (response != null && response['success'] == true && response['order'] != null) {
      setState(() {
        _order = Map<String, dynamic>.from(response['order']);
        _orderId = response['order']['id'].toString();
        _finalizedSignature = _signature;
      });
      return true;
    }
    if (showError) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Gagal menyiapkan pesanan.'), backgroundColor: Colors.red));
    }
    return false;
  }

  Future<void> _selectPaymentMethod() async {
    final ready = await _finalizeIfReady(showError: true);
    if (!ready || _orderId == null) return;
    final result = await Navigator.push(context, MaterialPageRoute(builder: (_) => const MetodeScreen()));
    if (result == null || result is! PaymentMethodModel) return;
    setState(() {
      _method = result;
      _loadingPayment = true;
    });
    final response = await CheckoutApiService.setPaymentMethod(orderId: _orderId!, paymentType: result.paymentType, bankCode: result.bankCode);
    if (!mounted) return;
    setState(() => _loadingPayment = false);
    if (response != null && response['success'] == true) {
      _applyPayment(response);
    } else {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Gagal membuat VA/instruksi pembayaran.'), backgroundColor: Colors.red));
    }
  }

  void _applyPayment(Map<String, dynamic> response) {
    final info = response['payment_info'];
    final mid = response['midtrans_response'];
    setState(() {
      if (response['order'] != null) {
        _order = Map<String, dynamic>.from(response['order']);
        _orderId = response['order']['id'].toString();
      }
      _vaNumber = _readVa(info, mid);
      _qrCodeUrl = _readQr(info, mid);
      _paymentState = PaymentState.pending;
      _setTimer(_readExpiry(info, mid));
    });
  }

  String? _readVa(dynamic info, dynamic mid) {
    if (info is Map && info['va_number'] != null) return info['va_number'].toString();
    if (mid is Map && mid['va_numbers'] is List && mid['va_numbers'].isNotEmpty) return mid['va_numbers'][0]['va_number']?.toString();
    if (mid is Map && mid['permata_va_number'] != null) return mid['permata_va_number'].toString();
    return null;
  }

  String? _readQr(dynamic info, dynamic mid) {
    if (info is Map && info['qr_code_url'] != null) return info['qr_code_url'].toString();
    if (mid is Map && mid['actions'] is List) {
      for (final action in mid['actions']) {
        if (action is Map && action['name'] == 'generate-qr-code') return action['url']?.toString();
      }
    }
    return null;
  }

  String? _readExpiry(dynamic info, dynamic mid) {
    if (info is Map && info['expiry_time'] != null) return info['expiry_time'].toString();
    if (mid is Map && mid['expiry_time'] != null) return mid['expiry_time'].toString();
    return null;
  }

  void _setTimer(String? expiry) {
    _timer?.cancel();
    try {
      _timeLeft = expiry == null ? const Duration(hours: 24) : DateTime.parse(expiry).difference(DateTime.now());
    } catch (_) {
      _timeLeft = const Duration(hours: 24);
    }
    if (_timeLeft.isNegative) {
      _timeLeft = Duration.zero;
      _paymentState = PaymentState.expired;
      return;
    }
    _timer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (!mounted) return;
      setState(() {
        if (_timeLeft.inSeconds <= 0) {
          timer.cancel();
          _paymentState = PaymentState.expired;
        } else {
          _timeLeft -= const Duration(seconds: 1);
        }
      });
    });
  }

  Future<void> _resetPayment() async {
    if (_orderId == null) return;
    setState(() => _loadingPayment = true);
    final response = await CheckoutApiService.resetPayment(_orderId!);
    if (!mounted) return;
    setState(() => _loadingPayment = false);
    if (response != null && response['success'] == true) {
      setState(() {
        if (response['order'] != null) _order = Map<String, dynamic>.from(response['order']);
        _method = null;
        _vaNumber = null;
        _qrCodeUrl = null;
        _timeLeft = Duration.zero;
        _paymentState = PaymentState.initial;
        _timer?.cancel();
      });
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Metode pembayaran berhasil direset.')));
    }
  }

  Future<void> _checkPaymentStatus() async {
    if (_orderId == null) return;
    setState(() => _loadingPayment = true);
    final response = await CheckoutApiService.checkOrderStatus(_orderId!);
    if (!mounted) return;
    setState(() => _loadingPayment = false);
    final status = response?['transaction_status'];
    if (response != null && response['success'] == true) {
      if (status == 'settlement' || status == 'capture' || status == 'approved') {
        setState(() => _paymentState = PaymentState.approved);
        _timer?.cancel();
      } else if (status == 'expire' || status == 'cancel' || status == 'declined') {
        setState(() => _paymentState = PaymentState.expired);
        _timer?.cancel();
      } else {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Pembayaran masih menunggu proses.')));
      }
    }
  }

  Future<void> _goToConfirmation() async {
    if (_order == null && _orderId != null) {
      final response = await CheckoutApiService.getOrder(_orderId!);
      if (response != null && response['success'] == true && response['order'] != null) _order = Map<String, dynamic>.from(response['order']);
    }
    if (!mounted || _order == null) return;
    Navigator.pushAndRemoveUntil(context, MaterialPageRoute(builder: (_) => OrderConfirmationScreen(order: _order!)), (_) => false);
  }

  void _lockedMessage() {
    ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Reset metode pembayaran dulu jika ingin mengubah alamat atau ongkir.')));
  }

  double _itemPrice(Map<String, dynamic> item) {
    final product = item['product'] ?? {};
    return double.tryParse((item['price'] ?? product['regular_price'] ?? 0).toString()) ?? 0;
  }

  int _itemQty(Map<String, dynamic> item) => int.tryParse((item['quantity'] ?? 1).toString()) ?? 1;

  @override
  Widget build(BuildContext context) {
    final timerText = '${_timeLeft.inHours.remainder(24).toString().padLeft(2, '0')} : ${_timeLeft.inMinutes.remainder(60).toString().padLeft(2, '0')} : ${_timeLeft.inSeconds.remainder(60).toString().padLeft(2, '0')}';
    return Scaffold(
      backgroundColor: const Color(0xFFF5F7FA),
      appBar: AppBar(title: const Text('Pengiriman & Checkout', style: TextStyle(color: Colors.black, fontWeight: FontWeight.bold)), backgroundColor: Colors.white, iconTheme: const IconThemeData(color: Colors.black), elevation: .5),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          _addressCard(),
          const SizedBox(height: 16),
          if (_address != null) _shippingCard(),
          const SizedBox(height: 16),
          _paymentCard(timerText),
          const SizedBox(height: 16),
          _summaryCard(),
          const SizedBox(height: 120),
        ]),
      ),
      bottomSheet: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(color: Colors.white, boxShadow: [BoxShadow(color: Colors.black.withOpacity(.05), blurRadius: 14, offset: const Offset(0, -4))]),
        child: SafeArea(
          child: Column(mainAxisSize: MainAxisSize.min, children: [
            Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [const Text('Total Tagihan', style: TextStyle(color: Colors.grey, fontSize: 16)), Text('Rp ${_grandTotal.toStringAsFixed(0)}', style: const TextStyle(fontSize: 22, fontWeight: FontWeight.w900, color: Color(0xFFE65100)))]),
            const SizedBox(height: 12),
            SizedBox(width: double.infinity, child: _bottomButton()),
          ]),
        ),
      ),
    );
  }

  Widget _card(Widget child) => Container(width: double.infinity, padding: const EdgeInsets.all(16), decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(18), border: Border.all(color: const Color(0xFFE5E7EB)), boxShadow: [BoxShadow(color: Colors.black.withOpacity(.035), blurRadius: 12, offset: const Offset(0, 6))]), child: child);

  Widget _sectionTitle(IconData icon, String title, {String? badge}) => Row(children: [
        Container(width: 34, height: 34, decoration: BoxDecoration(color: const Color(0xFFFFF3E0), borderRadius: BorderRadius.circular(10)), child: Icon(icon, size: 19, color: const Color(0xFFE65100))),
        const SizedBox(width: 10),
        Expanded(child: Text(title, style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 16))),
        if (badge != null) Container(padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5), decoration: BoxDecoration(color: const Color(0xFFE8F5E9), borderRadius: BorderRadius.circular(20)), child: Text(badge, style: const TextStyle(color: Colors.green, fontWeight: FontWeight.bold, fontSize: 11))),
      ]);

  Widget _addressCard() {
    if (_loadingAddress) return _card(const Center(child: Padding(padding: EdgeInsets.all(20), child: CircularProgressIndicator(color: Color(0xFFE65100)))));
    if (_address == null) {
      return InkWell(onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const AddressListScreen())).then((_) => _fetchAddress()), child: _card(Row(children: const [Icon(Icons.location_off, color: Colors.red), SizedBox(width: 12), Expanded(child: Text('Alamat belum diatur. Klik di sini.', style: TextStyle(color: Colors.red, fontWeight: FontWeight.bold))), Icon(Icons.arrow_forward_ios, size: 16, color: Colors.red)])));
    }
    return _card(Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      _sectionTitle(Icons.location_on_outlined, 'Alamat Pengiriman', badge: 'Dipilih'),
      const SizedBox(height: 14),
      Container(padding: const EdgeInsets.all(12), decoration: BoxDecoration(color: const Color(0xFFF9FAFB), borderRadius: BorderRadius.circular(14)), child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Text('${_address!['name']} | ${_address!['phone']}', style: const TextStyle(fontWeight: FontWeight.w700)),
        const SizedBox(height: 6),
        Text(_addressText, style: const TextStyle(height: 1.35)),
        const SizedBox(height: 4),
        Text('${_address!['city_name']}, ${_address!['province_name']} - ${_address!['postal_code']}', style: TextStyle(color: Colors.grey.shade700, fontSize: 13)),
      ])),
      const SizedBox(height: 10),
      Align(alignment: Alignment.centerRight, child: TextButton.icon(onPressed: _paymentLocked ? _lockedMessage : () => Navigator.push(context, MaterialPageRoute(builder: (_) => const AddressListScreen())).then((_) => _fetchAddress()), icon: const Icon(Icons.edit_location_alt_outlined, size: 18), label: const Text('Ubah Alamat'))),
    ]));
  }

  Widget _shippingCard() => _card(Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        _sectionTitle(Icons.local_shipping_outlined, 'Kurir Pengiriman', badge: _orderId == null ? null : 'Siap'),
        const SizedBox(height: 14),
        DropdownButtonFormField<String>(decoration: InputDecoration(labelText: 'Pilih Ekspedisi', border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)), prefixIcon: const Icon(Icons.local_post_office_outlined)), value: _courier, items: _couriers.map((c) => DropdownMenuItem(value: c, child: Text(c.toUpperCase()))).toList(), onChanged: _paymentLocked ? null : (v) { setState(() => _courier = v); _calculateShipping(); }),
        const SizedBox(height: 14),
        if (_loadingShipping) const Center(child: Padding(padding: EdgeInsets.all(12), child: CircularProgressIndicator())) else if (_shippingOptions.isNotEmpty) DropdownButtonFormField<String>(isExpanded: true, decoration: InputDecoration(labelText: 'Pilih Layanan Ongkir', border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)), prefixIcon: const Icon(Icons.inventory_2_outlined)), value: _service, items: _shippingOptions.map<DropdownMenuItem<String>>((option) { final cost = option['cost'] as List?; final price = cost != null && cost.isNotEmpty ? cost[0]['value']?.toString() ?? '0' : '0'; return DropdownMenuItem(value: option['service']?.toString(), child: Text('${option['service']} - Rp $price', overflow: TextOverflow.ellipsis)); }).toList(), onChanged: _paymentLocked ? null : _chooseService),
        if (_finalizing) const Padding(padding: EdgeInsets.only(top: 12), child: Row(children: [SizedBox(width: 16, height: 16, child: CircularProgressIndicator(strokeWidth: 2)), SizedBox(width: 8), Text('Menyiapkan pesanan final...', style: TextStyle(color: Colors.grey))])) else if (_orderId != null) Padding(padding: const EdgeInsets.only(top: 12), child: Row(children: const [Icon(Icons.check_circle_outline, color: Colors.green, size: 18), SizedBox(width: 8), Expanded(child: Text('Alamat dan ongkir sudah final. Lanjut pilih metode pembayaran.', style: TextStyle(color: Colors.green, fontWeight: FontWeight.w600)))])),
        if (_paymentLocked) Padding(padding: const EdgeInsets.only(top: 8), child: Text('Reset metode pembayaran jika ingin mengubah alamat atau ongkir.', style: TextStyle(color: Colors.grey.shade600, fontSize: 12))),
      ]));

  Widget _paymentCard(String timerText) => _card(Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        _sectionTitle(Icons.account_balance_wallet_outlined, 'Metode Pembayaran', badge: _paymentState == PaymentState.pending ? 'Menunggu' : _paymentState == PaymentState.approved ? 'Lunas' : null),
        const SizedBox(height: 14),
        if (_paymentState == PaymentState.initial || _paymentState == PaymentState.expired) ...[
          InkWell(onTap: _loadingPayment || _finalizing ? null : _selectPaymentMethod, child: Container(padding: const EdgeInsets.all(14), decoration: BoxDecoration(color: const Color(0xFFF9FAFB), border: Border.all(color: Colors.grey.shade300), borderRadius: BorderRadius.circular(14)), child: Row(children: [Container(width: 42, height: 42, decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(12), border: Border.all(color: Colors.grey.shade200)), child: _method?.iconUrl.isNotEmpty == true ? Padding(padding: const EdgeInsets.all(6), child: Image.network(_method!.iconUrl, fit: BoxFit.contain, errorBuilder: (_, __, ___) => const Icon(Icons.payment))) : const Icon(Icons.payment, color: Color(0xFFE65100))), const SizedBox(width: 12), Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [Text(_orderId == null ? 'Lengkapi alamat dan ongkir dulu' : (_method?.name ?? 'Pilih Metode Pembayaran'), style: TextStyle(color: _method == null ? Colors.grey.shade600 : Colors.black, fontWeight: FontWeight.w700)), const SizedBox(height: 3), Text(_orderId == null ? 'VA/QRIS dibuat setelah ongkir final' : 'Tap untuk memilih bank, QRIS, atau e-wallet', style: TextStyle(color: Colors.grey.shade600, fontSize: 12))])), _loadingPayment ? const SizedBox(width: 18, height: 18, child: CircularProgressIndicator(strokeWidth: 2)) : const Icon(Icons.arrow_forward_ios, size: 16, color: Colors.grey)]))),
          if (_paymentState == PaymentState.expired) const Padding(padding: EdgeInsets.only(top: 10), child: Text('Sesi pembayaran berakhir. Pilih metode kembali.', style: TextStyle(color: Colors.red))),
        ],
        if (_paymentState == PaymentState.pending) ...[
          Container(width: double.infinity, padding: const EdgeInsets.all(14), decoration: BoxDecoration(color: const Color(0xFFFFF8E1), borderRadius: BorderRadius.circular(14), border: Border.all(color: const Color(0xFFFFE0B2))), child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Row(children: [Expanded(child: Text(_method?.name ?? 'Metode pembayaran', style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 15))), Container(padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5), decoration: BoxDecoration(color: Colors.orange.shade100, borderRadius: BorderRadius.circular(20)), child: const Text('Menunggu Pembayaran', style: TextStyle(color: Colors.deepOrange, fontWeight: FontWeight.bold, fontSize: 11)))]),
            const SizedBox(height: 12),
            Center(child: Column(children: [const Text('Batas waktu pembayaran', style: TextStyle(color: Colors.grey, fontSize: 12)), const SizedBox(height: 4), Text(timerText, style: const TextStyle(fontSize: 30, color: Colors.red, fontWeight: FontWeight.w900, letterSpacing: 1.2))])),
          ])),
          const SizedBox(height: 14),
          if (_vaNumber != null) Container(width: double.infinity, padding: const EdgeInsets.all(14), decoration: BoxDecoration(color: const Color(0xFFF3F4F6), borderRadius: BorderRadius.circular(14)), child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [const Text('Nomor Virtual Account', style: TextStyle(color: Colors.grey, fontSize: 12)), const SizedBox(height: 6), Row(children: [Expanded(child: SelectableText(_vaNumber!, style: const TextStyle(fontSize: 22, fontWeight: FontWeight.w900, letterSpacing: 1.1))), TextButton.icon(onPressed: () { Clipboard.setData(ClipboardData(text: _vaNumber!)); ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Nomor VA disalin!'))); }, icon: const Icon(Icons.copy, size: 18), label: const Text('Salin'))])])),
          if (_qrCodeUrl != null) Padding(padding: const EdgeInsets.only(top: 12), child: Center(child: Container(padding: const EdgeInsets.all(10), decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(14), border: Border.all(color: Colors.grey.shade300)), child: Image.network(_qrCodeUrl!, width: 220, height: 200, fit: BoxFit.contain)))),
          if (_vaNumber == null && _qrCodeUrl == null) const Text('Selesaikan pembayaran sesuai instruksi metode yang dipilih.'),
          const SizedBox(height: 14),
          Row(children: [Expanded(child: OutlinedButton.icon(onPressed: _loadingPayment ? null : _checkPaymentStatus, icon: const Icon(Icons.refresh), label: const Text('Refresh Status'))), const SizedBox(width: 10), Expanded(child: OutlinedButton.icon(onPressed: _loadingPayment ? null : _resetPayment, icon: const Icon(Icons.restart_alt), label: const Text('Reset Metode')))]),
        ],
        if (_paymentState == PaymentState.approved) const Center(child: Column(children: [Icon(Icons.check_circle, color: Colors.green, size: 64), SizedBox(height: 8), Text('Pembayaran Berhasil!', style: TextStyle(color: Colors.green, fontWeight: FontWeight.bold, fontSize: 18))])),
      ]));

  Widget _summaryCard() => _card(Column(crossAxisAlignment: CrossAxisAlignment.start, children: [_sectionTitle(Icons.receipt_long_outlined, 'Ringkasan Pesanan'), const SizedBox(height: 14), ...widget.cartItems.map(_summaryItem)]));

  Widget _summaryItem(Map<String, dynamic> item) {
    final product = item['product'] ?? {};
    final price = _itemPrice(item);
    final qty = _itemQty(item);
    final image = _imageUrl(item['selected_image'] ?? product['image']);
    return Padding(padding: const EdgeInsets.only(bottom: 12), child: Row(children: [Container(width: 52, height: 52, clipBehavior: Clip.antiAlias, decoration: BoxDecoration(borderRadius: BorderRadius.circular(12), border: Border.all(color: Colors.grey.shade200)), child: image.isEmpty ? const Icon(Icons.image, color: Colors.grey) : Image.network(image, fit: BoxFit.cover, errorBuilder: (_, __, ___) => const Icon(Icons.image_not_supported, color: Colors.grey))), const SizedBox(width: 12), Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [Text(product['name'] ?? 'Produk', style: const TextStyle(fontWeight: FontWeight.w700), maxLines: 1, overflow: TextOverflow.ellipsis), Text('$qty x Rp ${price.toStringAsFixed(0)}', style: TextStyle(color: Colors.grey[600], fontSize: 12))])), Text('Rp ${(price * qty).toStringAsFixed(0)}', style: const TextStyle(fontWeight: FontWeight.bold))]));
  }

  Widget _bottomButton() {
    if (_paymentState == PaymentState.pending) {
      return ElevatedButton(onPressed: _loadingPayment ? null : _goToConfirmation, style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFFE65100), padding: const EdgeInsets.symmetric(vertical: 14), shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12))), child: const Text('KONFIRMASI PESANAN', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)));
    }
    if (_paymentState == PaymentState.approved) {
      return ElevatedButton(onPressed: _goToConfirmation, style: ElevatedButton.styleFrom(backgroundColor: Colors.green, padding: const EdgeInsets.symmetric(vertical: 14), shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12))), child: const Text('SELESAIKAN PESANAN', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)));
    }
    return ElevatedButton(onPressed: _orderId == null || _loadingPayment || _finalizing ? null : _selectPaymentMethod, style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFFE65100), disabledBackgroundColor: Colors.grey.shade300, padding: const EdgeInsets.symmetric(vertical: 14), shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12))), child: Text(_finalizing ? 'MENYIAPKAN PESANAN...' : 'PILIH METODE PEMBAYARAN', style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold)));
  }
}

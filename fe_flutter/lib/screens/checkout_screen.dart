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
          if (_paymentState == PaymentState.initial || _paymentState == PaymentState.expired) ...[_addressCard(), const SizedBox(height: 16), if (_address != null) _shippingCard(), const SizedBox(height: 16)],
          _paymentCard(timerText),
          const SizedBox(height: 16),
          _summaryCard(),
          const SizedBox(height: 120),
        ]),
      ),
      bottomSheet: Container(
        padding: const EdgeInsets.all(16),
        color: Colors.white,
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

  Widget _card(Widget child) => Container(width: double.infinity, padding: const EdgeInsets.all(16), decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(16), border: Border.all(color: Colors.grey.shade200)), child: child);

  Widget _addressCard() {
    if (_loadingAddress) return const Center(child: Padding(padding: EdgeInsets.all(20), child: CircularProgressIndicator(color: Color(0xFFE65100))));
    if (_address == null) {
      return InkWell(onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const AddressListScreen())).then((_) => _fetchAddress()), child: _card(const Row(children: [Icon(Icons.location_off, color: Colors.red), SizedBox(width: 12), Expanded(child: Text('Alamat belum diatur. Klik di sini.', style: TextStyle(color: Colors.red, fontWeight: FontWeight.bold)))])));
    }
    return _card(Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [const Text('Alamat Pengiriman', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)), TextButton(onPressed: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const AddressListScreen())).then((_) => _fetchAddress()), child: const Text('Ubah'))]),
      const Divider(),
      Text('${_address!['name']} | ${_address!['phone']}', style: const TextStyle(fontWeight: FontWeight.w600)),
      const SizedBox(height: 6),
      Text(_addressText),
      Text('${_address!['city_name']}, ${_address!['province_name']} - ${_address!['postal_code']}', style: TextStyle(color: Colors.grey.shade700)),
    ]));
  }

  Widget _shippingCard() => _card(Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        const Text('Kurir Pengiriman', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
        const SizedBox(height: 12),
        DropdownButtonFormField<String>(decoration: const InputDecoration(labelText: 'Pilih Ekspedisi', border: OutlineInputBorder()), value: _courier, items: _couriers.map((c) => DropdownMenuItem(value: c, child: Text(c.toUpperCase()))).toList(), onChanged: (v) { setState(() => _courier = v); _calculateShipping(); }),
        const SizedBox(height: 16),
        if (_loadingShipping) const Center(child: CircularProgressIndicator()) else if (_shippingOptions.isNotEmpty) DropdownButtonFormField<String>(isExpanded: true, decoration: const InputDecoration(labelText: 'Pilih Layanan', border: OutlineInputBorder()), value: _service, items: _shippingOptions.map<DropdownMenuItem<String>>((option) { final cost = option['cost'] as List?; final price = cost != null && cost.isNotEmpty ? cost[0]['value']?.toString() ?? '0' : '0'; return DropdownMenuItem(value: option['service']?.toString(), child: Text('${option['service']} - Rp $price', overflow: TextOverflow.ellipsis)); }).toList(), onChanged: _chooseService),
        if (_finalizing) const Padding(padding: EdgeInsets.only(top: 12), child: Text('Menyiapkan pesanan final...', style: TextStyle(color: Colors.grey))) else if (_orderId != null) const Padding(padding: EdgeInsets.only(top: 12), child: Text('Pesanan siap. Silakan pilih metode pembayaran.', style: TextStyle(color: Colors.green, fontWeight: FontWeight.w600))),
      ]));

  Widget _paymentCard(String timerText) => _card(Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        if (_paymentState == PaymentState.initial || _paymentState == PaymentState.expired) ...[
          const Text('Metode Pembayaran', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
          const SizedBox(height: 12),
          InkWell(onTap: _loadingPayment || _finalizing ? null : _selectPaymentMethod, child: Container(padding: const EdgeInsets.all(14), decoration: BoxDecoration(border: Border.all(color: Colors.grey.shade300), borderRadius: BorderRadius.circular(8)), child: Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [Expanded(child: Text(_orderId == null ? 'Lengkapi ongkir dulu' : (_method?.name ?? 'Pilih Metode Pembayaran'), style: TextStyle(color: _method == null ? Colors.grey : Colors.black, fontWeight: _method == null ? FontWeight.normal : FontWeight.bold))), _loadingPayment ? const SizedBox(width: 18, height: 18, child: CircularProgressIndicator(strokeWidth: 2)) : const Icon(Icons.arrow_forward_ios, size: 16, color: Colors.grey)]))),
          if (_paymentState == PaymentState.expired) const Padding(padding: EdgeInsets.only(top: 10), child: Text('Sesi pembayaran berakhir. Pilih metode kembali.', style: TextStyle(color: Colors.red))),
        ],
        if (_paymentState == PaymentState.pending) ...[
          Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [const Text('Metode Pembayaran', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)), TextButton(onPressed: _loadingPayment ? null : _resetPayment, child: const Text('Reset Status'))]),
          Text(_method?.name ?? 'Metode pembayaran', style: const TextStyle(fontWeight: FontWeight.bold)),
          const Text('Status: Menunggu Pembayaran', style: TextStyle(color: Colors.orange, fontWeight: FontWeight.w600)),
          const SizedBox(height: 12),
          Center(child: Text(timerText, style: const TextStyle(fontSize: 30, color: Colors.red, fontWeight: FontWeight.bold))),
          const Divider(height: 28),
          if (_vaNumber != null) Row(children: [Expanded(child: SelectableText(_vaNumber!, style: const TextStyle(fontSize: 22, fontWeight: FontWeight.bold))), TextButton.icon(onPressed: () { Clipboard.setData(ClipboardData(text: _vaNumber!)); ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Nomor VA disalin!'))); }, icon: const Icon(Icons.copy), label: const Text('Salin'))]),
          if (_qrCodeUrl != null) Center(child: Image.network(_qrCodeUrl!, width: 220, height: 200, fit: BoxFit.contain)),
          if (_vaNumber == null && _qrCodeUrl == null) const Text('Selesaikan pembayaran sesuai instruksi metode yang dipilih.'),
          const SizedBox(height: 16),
          SizedBox(width: double.infinity, child: OutlinedButton.icon(onPressed: _loadingPayment ? null : _checkPaymentStatus, icon: const Icon(Icons.refresh), label: const Text('Refresh Status Pembayaran'))),
        ],
        if (_paymentState == PaymentState.approved) const Center(child: Column(children: [Icon(Icons.check_circle, color: Colors.green, size: 64), SizedBox(height: 8), Text('Pembayaran Berhasil!', style: TextStyle(color: Colors.green, fontWeight: FontWeight.bold, fontSize: 18))])),
      ]));

  Widget _summaryCard() => _card(Column(crossAxisAlignment: CrossAxisAlignment.start, children: [const Text('Ringkasan Pesanan', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)), const SizedBox(height: 12), ...widget.cartItems.map(_summaryItem)]));

  Widget _summaryItem(Map<String, dynamic> item) {
    final product = item['product'] ?? {};
    final price = _itemPrice(item);
    final qty = _itemQty(item);
    final image = _imageUrl(item['selected_image'] ?? product['image']);
    return Padding(padding: const EdgeInsets.only(bottom: 12), child: Row(children: [Container(width: 50, height: 50, clipBehavior: Clip.antiAlias, decoration: BoxDecoration(borderRadius: BorderRadius.circular(8), border: Border.all(color: Colors.grey.shade200)), child: image.isEmpty ? const Icon(Icons.image, color: Colors.grey) : Image.network(image, fit: BoxFit.cover, errorBuilder: (_, __, ___) => const Icon(Icons.image_not_supported, color: Colors.grey))), const SizedBox(width: 12), Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [Text(product['name'] ?? 'Produk', style: const TextStyle(fontWeight: FontWeight.w600), maxLines: 1, overflow: TextOverflow.ellipsis), Text('$qty x Rp ${price.toStringAsFixed(0)}', style: TextStyle(color: Colors.grey[600], fontSize: 12))])), Text('Rp ${(price * qty).toStringAsFixed(0)}', style: const TextStyle(fontWeight: FontWeight.bold))]));
  }

  Widget _bottomButton() {
    if (_paymentState == PaymentState.pending) {
      return ElevatedButton(onPressed: _loadingPayment ? null : _goToConfirmation, style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFFE65100), padding: const EdgeInsets.symmetric(vertical: 14)), child: const Text('KONFIRMASI PESANAN', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)));
    }
    if (_paymentState == PaymentState.approved) {
      return ElevatedButton(onPressed: _goToConfirmation, style: ElevatedButton.styleFrom(backgroundColor: Colors.green, padding: const EdgeInsets.symmetric(vertical: 14)), child: const Text('SELESAIKAN PESANAN', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)));
    }
    return ElevatedButton(onPressed: null, style: ElevatedButton.styleFrom(disabledBackgroundColor: Colors.grey.shade300, padding: const EdgeInsets.symmetric(vertical: 14)), child: Text(_finalizing ? 'MENYIAPKAN PESANAN...' : 'PILIH METODE PEMBAYARAN', style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold)));
  }
}

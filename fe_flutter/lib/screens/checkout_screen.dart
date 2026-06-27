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

  const CheckoutScreen({
    Key? key,
    required this.totalAmount,
    required this.totalWeight,
    required this.cartItems,
  }) : super(key: key);

  @override
  State<CheckoutScreen> createState() => _CheckoutScreenState();
}

class _CheckoutScreenState extends State<CheckoutScreen> {
  static const Color _primary = Color(0xFF0C2442);
  static const Color _accent = Color(0xFFF39C12);
  static const Color _purple = Color(0xFF6C4DFF);
  static const Color _surface = Color(0xFFF7F8FC);
  static const Color _muted = Color(0xFF64748B);
  static const Color _navy = Color(0xFF0C2442);
  static const Color _navySoft = Color(0xFFEDEAFF);
  static const Color _pageBg = Color(0xFFF7F8FC);

  final List<String> _couriers = ['jne', 'pos', 'tiki'];

  Map<String, dynamic>? _addressData;
  List _shippingOptions = [];
  String? _selectedCourier;
  String? _selectedService;
  double _shippingCost = 0;

  PaymentMethodModel? _selectedPaymentMethod;
  PaymentState _paymentState = PaymentState.initial;

  bool _isLoadingAddress = true;
  bool _isLoadingShipping = false;
  bool _isLoading = false;

  String? _orderId;
  String? _vaNumber;
  String? _qrCodeUrl;
  Timer? _countdownTimer;
  Duration _timeLeft = Duration.zero;
  Map<String, dynamic>? _orderData;

  double get _grandTotal => widget.totalAmount + _shippingCost;
  bool get _isPaymentMode => _paymentState == PaymentState.pending || _paymentState == PaymentState.approved;

  String get _addressText =>
      _addressData?['address']?.toString() ?? _addressData?['detail_address']?.toString() ?? '-';
  String get _phoneText => _addressData?['phone']?.toString() ?? '-';
  String get _provinceName => _addressData?['province_name']?.toString() ?? 'Unknown';
  String get _cityName => _addressData?['city_name']?.toString() ?? 'Unknown';
  String get _courierWithService => '${_selectedCourier?.toUpperCase()} - $_selectedService';

  @override
  void initState() {
    super.initState();
    _loadMainAddress();
  }

  @override
  void dispose() {
    _countdownTimer?.cancel();
    super.dispose();
  }

  Future<bool> _handleBack() async {
    if (_isPaymentMode || _paymentState == PaymentState.expired) {
      _backToCheckoutForm();
      return false;
    }
    return true;
  }

  void _backToCheckoutForm() {
    setState(() {
      _paymentState = PaymentState.initial;
      _orderId = null;
      _vaNumber = null;
      _qrCodeUrl = null;
      _orderData = null;
      _timeLeft = Duration.zero;
      _countdownTimer?.cancel();
    });
  }

  Future<void> _loadMainAddress() async {
    setState(() => _isLoadingAddress = true);
    final data = await ApiService.getUserAddresses();
    if (!mounted) return;

    Map<String, dynamic>? selected;
    if (data is List && data.isNotEmpty) {
      try {
        selected = Map<String, dynamic>.from(data.firstWhere((address) =>
            address['isdefault'] == 1 ||
            address['isdefault'] == '1' ||
            address['isdefault'] == true ||
            address['is_main'] == 1 ||
            address['is_main'] == '1' ||
            address['is_main'] == true));
      } catch (_) {
        selected = Map<String, dynamic>.from(data.first);
      }
    }

    setState(() {
      _addressData = selected;
      _isLoadingAddress = false;
      _shippingOptions = [];
      _selectedService = null;
      _shippingCost = 0;
    });

    if (_addressData != null && _selectedCourier != null) {
      _loadShippingCost();
    }
  }

  Future<void> _loadShippingCost() async {
    if (_addressData == null || _addressData!['city_id'] == null || _selectedCourier == null) return;

    setState(() {
      _isLoadingShipping = true;
      _shippingOptions = [];
      _selectedService = null;
      _shippingCost = 0;
    });

    final data = await ApiService.checkCost(
      _addressData!['city_id'].toString(),
      widget.totalWeight.toInt(),
      _selectedCourier!,
    );

    if (!mounted) return;

    setState(() {
      _isLoadingShipping = false;
      _shippingOptions = data;
      if (data.isNotEmpty && data[0]['cost'] is List && data[0]['cost'].isNotEmpty) {
        _selectedService = data[0]['service']?.toString();
        _shippingCost = double.tryParse(data[0]['cost'][0]['value']?.toString() ?? '0') ?? 0;
      }
    });
  }

  Future<void> _selectPaymentMethod() async {
    final result = await Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => const MetodeScreen()),
    );

    if (result is PaymentMethodModel) {
      setState(() => _selectedPaymentMethod = result);
    }
  }

  Future<void> _payNow() async {
    if (_addressData == null) {
      _showSnack('Harap pilih alamat terlebih dahulu.', error: true);
      return;
    }
    if (_selectedCourier == null || _selectedService == null || _shippingCost <= 0) {
      _showSnack('Pilih kurir dan layanan pengiriman terlebih dahulu.', error: true);
      return;
    }
    if (_selectedPaymentMethod == null) {
      _showSnack('Pilih metode pembayaran terlebih dahulu.', error: true);
      return;
    }

    setState(() => _isLoading = true);

    final response = await CheckoutApiService.checkout(
      address: _addressText,
      phone: _phoneText,
      provinceName: _provinceName,
      cityName: _cityName,
      courier: _courierWithService,
      shippingCost: _shippingCost,
      cartItems: widget.cartItems,
      paymentType: _selectedPaymentMethod!.paymentType,
      bankCode: _selectedPaymentMethod!.bankCode,
    );

    if (!mounted) return;
    setState(() => _isLoading = false);

    if (response == null || response['success'] != true) {
      _showSnack('Gagal memproses pesanan.', error: true);
      return;
    }

    final paymentInfo = response['payment_info'];
    final midtrans = response['midtrans_response'];

    setState(() {
      if (response['order'] != null) {
        _orderData = Map<String, dynamic>.from(response['order']);
        _orderId = response['order']['id'].toString();
      }
      _vaNumber = _readVaNumber(paymentInfo, midtrans);
      _qrCodeUrl = _readQrCodeUrl(paymentInfo, midtrans);
      _paymentState = PaymentState.pending;
      _startTimer(_readExpiry(paymentInfo, midtrans));
    });
  }

  String? _readVaNumber(dynamic info, dynamic midtrans) {
    if (info is Map && info['va_number'] != null) return info['va_number'].toString();
    if (midtrans is Map && midtrans['va_numbers'] is List && midtrans['va_numbers'].isNotEmpty) {
      return midtrans['va_numbers'][0]['va_number']?.toString();
    }
    if (midtrans is Map && midtrans['permata_va_number'] != null) return midtrans['permata_va_number'].toString();
    if (midtrans is Map && midtrans['bill_key'] != null) {
      return 'Bill Key: ${midtrans['bill_key']}\nBiller Code: ${midtrans['biller_code'] ?? ''}';
    }
    return null;
  }

  String? _readQrCodeUrl(dynamic info, dynamic midtrans) {
    if (info is Map && info['qr_code_url'] != null) return info['qr_code_url'].toString();
    if (midtrans is Map && midtrans['actions'] is List) {
      for (final action in midtrans['actions']) {
        if (action is Map && action['name'] == 'generate-qr-code') return action['url']?.toString();
      }
    }
    return null;
  }

  String? _readExpiry(dynamic info, dynamic midtrans) {
    if (info is Map && info['expiry_time'] != null) return info['expiry_time'].toString();
    if (midtrans is Map && midtrans['expiry_time'] != null) return midtrans['expiry_time'].toString();
    return null;
  }

  void _startTimer(String? expiryTime) {
    _countdownTimer?.cancel();

    try {
      _timeLeft = expiryTime == null
          ? const Duration(hours: 24)
          : DateTime.parse(expiryTime).difference(DateTime.now());
    } catch (_) {
      _timeLeft = const Duration(hours: 24);
    }

    if (_timeLeft.isNegative) {
      _timeLeft = Duration.zero;
      _paymentState = PaymentState.expired;
      return;
    }

    _countdownTimer = Timer.periodic(const Duration(seconds: 1), (timer) {
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

  Future<void> _refreshPaymentStatus() async {
    if (_orderId == null) return;

    setState(() => _isLoading = true);
    final response = await CheckoutApiService.checkOrderStatus(_orderId!);
    if (!mounted) return;
    setState(() => _isLoading = false);

    final status = response?['transaction_status'];
    if (response != null && response['success'] == true) {
      if (status == 'settlement' || status == 'capture' || status == 'approved') {
        setState(() => _paymentState = PaymentState.approved);
        _countdownTimer?.cancel();
        _showSnack('Pembayaran berhasil diterima.');
      } else if (status == 'expire' || status == 'cancel' || status == 'declined') {
        setState(() => _paymentState = PaymentState.expired);
        _countdownTimer?.cancel();
      } else {
        _showSnack('Pembayaran masih menunggu proses.');
      }
    }
  }

  Future<void> _confirmOrder() async {
    if (_paymentState != PaymentState.approved) {
      _showSnack('Konfirmasi pesanan baru bisa dibuka setelah pembayaran diterima.');
      return;
    }

    if (_orderData == null && _orderId != null) {
      final response = await CheckoutApiService.getOrder(_orderId!);
      if (response != null && response['success'] == true && response['order'] != null) {
        _orderData = Map<String, dynamic>.from(response['order']);
      }
    }

    if (!mounted || _orderData == null) return;

    Navigator.pushAndRemoveUntil(
      context,
      MaterialPageRoute(builder: (_) => OrderConfirmationScreen(order: _orderData!)),
      (_) => false,
    );
  }

  void _copyVa() {
    if (_vaNumber == null) return;
    Clipboard.setData(ClipboardData(text: _vaNumber!));
    _showSnack('Nomor VA disalin.');
  }

  void _showSnack(String message, {bool error = false}) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message, style: const TextStyle(fontSize: 13)),
        backgroundColor: error ? Colors.red : null,
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  double _itemPrice(Map<String, dynamic> item) {
    final product = item['product'] ?? {};
    return double.tryParse((item['price'] ?? product['regular_price'] ?? 0).toString()) ?? 0;
  }

  int _itemQty(Map<String, dynamic> item) {
    return int.tryParse((item['quantity'] ?? 1).toString()) ?? 1;
  }

  String _imageUrl(dynamic image) {
    final value = image?.toString().trim() ?? '';
    if (value.isEmpty || value == 'null') return '';
    if (value.startsWith('http')) return value;
    final base = ApiService.baseUrl.replaceFirst(RegExp(r'/api/?$'), '');
    final cleanValue = value.startsWith('/') ? value.substring(1) : value;
    if (cleanValue.startsWith('uploads/') || cleanValue.startsWith('storage/')) return '$base/$cleanValue';
    return '$base/uploads/products/$cleanValue';
  }

  String _currency(num value) => 'Rp ${value.toStringAsFixed(0)}';

  @override
  Widget build(BuildContext context) {
    final timerText =
        '${_timeLeft.inHours.remainder(24).toString().padLeft(2, '0')} : '
        '${_timeLeft.inMinutes.remainder(60).toString().padLeft(2, '0')} : '
        '${_timeLeft.inSeconds.remainder(60).toString().padLeft(2, '0')}';

    return WillPopScope(
      onWillPop: _handleBack,
      child: Scaffold(
        backgroundColor: _pageBg,
        body: Column(
          children: [
            _pageHeader(timerText),
            Expanded(child: _isPaymentMode ? _buildPaymentBody(timerText) : _buildCheckoutBody()),
          ],
        ),
        bottomSheet: Container(
          padding: const EdgeInsets.fromLTRB(16, 12, 16, 16),
          decoration: BoxDecoration(
            color: Colors.white,
            boxShadow: [BoxShadow(color: Colors.black.withOpacity(.08), blurRadius: 16, offset: const Offset(0, -5))],
          ),
          child: SafeArea(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Text('Total Order', style: TextStyle(color: _muted, fontSize: 13)),
                    Text(_currency(_grandTotal), style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w900, color: _primary)),
                  ],
                ),
                const SizedBox(height: 10),
                SizedBox(width: double.infinity, child: _bottomButton()),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _circleAction(IconData icon, VoidCallback? onTap) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(999),
      child: Container(width: 42, height: 42, decoration: BoxDecoration(color: Colors.white.withOpacity(0.14), shape: BoxShape.circle, border: Border.all(color: Colors.white.withOpacity(0.12))), child: Icon(icon, color: Colors.white, size: 21)),
    );
  }

  Widget _pageHeader(String timerText) {
    final title = _isPaymentMode ? 'Pembayaran' : 'Checkout';
    final subtitle = _isPaymentMode
        ? (_paymentState == PaymentState.approved ? 'Pembayaran diterima, selesaikan pesanan.' : 'Selesaikan pembayaran sebelum waktu habis.')
        : '${widget.cartItems.length} produk siap diproses.';
    final chip = _isPaymentMode
        ? (_paymentState == PaymentState.approved ? 'LUNAS' : timerText)
        : 'Ringkasan order';

    return Container(
      decoration: const BoxDecoration(
        gradient: LinearGradient(colors: [_primary, Color(0xFF123A68)], begin: Alignment.topLeft, end: Alignment.bottomRight),
        borderRadius: BorderRadius.vertical(bottom: Radius.circular(30)),
      ),
      child: SafeArea(
        bottom: false,
        child: Padding(
          padding: const EdgeInsets.fromLTRB(18, 16, 18, 24),
          child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
              _circleAction(Icons.arrow_back_rounded, () async {
                final canPop = await _handleBack();
                if (canPop && mounted) Navigator.pop(context);
              }),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 7),
                decoration: BoxDecoration(color: Colors.white.withOpacity(0.14), borderRadius: BorderRadius.circular(99), border: Border.all(color: Colors.white.withOpacity(0.12))),
                child: Text(chip, style: const TextStyle(color: Colors.white, fontSize: 12, fontWeight: FontWeight.w800)),
              ),
            ]),
            const SizedBox(height: 18),
            Container(
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(color: Colors.white.withOpacity(0.12), borderRadius: BorderRadius.circular(26), border: Border.all(color: Colors.white.withOpacity(0.16))),
              child: Row(children: [
                Container(
                  width: 62,
                  height: 62,
                  decoration: const BoxDecoration(color: Colors.white, shape: BoxShape.circle),
                  child: Icon(_isPaymentMode ? Icons.account_balance_wallet_rounded : Icons.shopping_bag_rounded, color: _primary, size: 34),
                ),
                const SizedBox(width: 14),
                Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                  Text(title, style: const TextStyle(color: Colors.white, fontSize: 22, fontWeight: FontWeight.w900)),
                  const SizedBox(height: 5),
                  Text(subtitle, maxLines: 2, overflow: TextOverflow.ellipsis, style: TextStyle(color: Colors.white.withOpacity(0.84), fontSize: 13, height: 1.35)),
                  if (_selectedPaymentMethod != null) ...[
                    const SizedBox(height: 3),
                    Text(_selectedPaymentMethod!.name, maxLines: 1, overflow: TextOverflow.ellipsis, style: TextStyle(color: Colors.white.withOpacity(0.72), fontSize: 12)),
                  ],
                ])),
              ]),
            ),
          ]),
        ),
      ),
    );
  }

  Widget _buildCheckoutBody() {
    return SingleChildScrollView(
      physics: const BouncingScrollPhysics(),
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 120),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _sectionLabel('Alamat'),
          const SizedBox(height: 8),
          _addressCard(),
          const SizedBox(height: 14),
          _sectionLabel('Pengiriman'),
          const SizedBox(height: 8),
          _shippingCard(),
          const SizedBox(height: 14),
          _sectionLabel('Pembayaran'),
          const SizedBox(height: 8),
          _methodCard(),
          const SizedBox(height: 14),
          _sectionLabel('Ringkasan'),
          const SizedBox(height: 8),
          _summaryCard(showOnlyProducts: false),
        ],
      ),
    );
  }

  Widget _buildPaymentBody(String timerText) {
    return SingleChildScrollView(
      physics: const BouncingScrollPhysics(),
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 120),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _paymentInstructionCard(timerText),
          const SizedBox(height: 14),
          _sectionLabel('Daftar Barang yang Diorder'),
          const SizedBox(height: 8),
          _summaryCard(showOnlyProducts: true),
          const SizedBox(height: 14),
          _totalOrderCard(),
          const SizedBox(height: 12),
          TextButton.icon(
            onPressed: _backToCheckoutForm,
            icon: const Icon(Icons.arrow_back, size: 18),
            label: const Text('Kembali ubah alamat, kurir, atau metode pembayaran'),
            style: TextButton.styleFrom(foregroundColor: _primary, textStyle: const TextStyle(fontSize: 12, fontWeight: FontWeight.w700)),
          ),
        ],
      ),
    );
  }

  Widget _sectionLabel(String text) {
    return Text(text, style: const TextStyle(fontSize: 13, color: _primary, fontWeight: FontWeight.w900));
  }

  Widget _card({required Widget child, EdgeInsetsGeometry padding = const EdgeInsets.all(14)}) {
    return Container(
      width: double.infinity,
      padding: padding,
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(22),
        border: Border.all(color: const Color(0xFFE2E8F0)),
        boxShadow: [BoxShadow(color: Colors.black.withOpacity(.04), blurRadius: 14, offset: const Offset(0, 6))],
      ),
      child: child,
    );
  }

  Widget _addressCard() {
    if (_isLoadingAddress) {
      return _card(
        child: const Center(child: Padding(padding: EdgeInsets.all(8), child: CircularProgressIndicator(color: _primary))),
      );
    }

    if (_addressData == null) {
      return InkWell(
        onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const AddressListScreen())).then((_) => _loadMainAddress()),
        borderRadius: BorderRadius.circular(22),
        child: _card(
          child: const Row(
            children: [
              Icon(Icons.location_off, color: Colors.red, size: 20),
              SizedBox(width: 10),
              Expanded(child: Text('Alamat belum diatur. Klik untuk memilih alamat.', style: TextStyle(color: Colors.red, fontWeight: FontWeight.w700, fontSize: 13))),
            ],
          ),
        ),
      );
    }

    return _card(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                padding: const EdgeInsets.all(9),
                decoration: BoxDecoration(color: _purple.withOpacity(0.10), borderRadius: BorderRadius.circular(14)),
                child: const Icon(Icons.location_on_rounded, color: _primary, size: 20),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('${_addressData!['name']} | ${_addressData!['phone']}', style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w800, color: Color(0xFF111827))),
                    const SizedBox(height: 5),
                    Text(_addressText, style: const TextStyle(fontSize: 12, height: 1.35, color: Color(0xFF475569))),
                    const SizedBox(height: 3),
                    Text('${_addressData!['city_name']}, ${_addressData!['province_name']} - ${_addressData!['postal_code']}', style: const TextStyle(fontSize: 12, color: _muted)),
                  ],
                ),
              ),
              TextButton(
                onPressed: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const AddressListScreen())).then((_) => _loadMainAddress()),
                child: const Text('Ubah', style: TextStyle(fontSize: 12, fontWeight: FontWeight.w800)),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _shippingCard() {
    if (_addressData == null) return const SizedBox.shrink();

    return _card(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          DropdownButtonFormField<String>(
            value: _selectedCourier,
            decoration: _inputDecoration('Pilih Ekspedisi'),
            style: const TextStyle(fontSize: 13, color: Color(0xFF111827)),
            items: _couriers.map((courier) => DropdownMenuItem(value: courier, child: Text(courier.toUpperCase()))).toList(),
            onChanged: (value) {
              setState(() => _selectedCourier = value);
              _loadShippingCost();
            },
          ),
          const SizedBox(height: 12),
          if (_isLoadingShipping)
            const Center(child: Padding(padding: EdgeInsets.all(8), child: CircularProgressIndicator(color: _primary)))
          else if (_shippingOptions.isNotEmpty)
            DropdownButtonFormField<String>(
              isExpanded: true,
              value: _selectedService,
              decoration: _inputDecoration('Pilih Layanan'),
              style: const TextStyle(fontSize: 13, color: Color(0xFF111827)),
              items: _shippingOptions.map<DropdownMenuItem<String>>((option) {
                final cost = option['cost'] as List?;
                final value = cost != null && cost.isNotEmpty ? cost[0]['value']?.toString() ?? '0' : '0';
                return DropdownMenuItem(value: option['service']?.toString(), child: Text('${option['service']} - Rp $value', overflow: TextOverflow.ellipsis));
              }).toList(),
              onChanged: (value) {
                final selected = _shippingOptions.firstWhere((option) => option['service']?.toString() == value);
                final cost = selected['cost'] as List?;
                setState(() {
                  _selectedService = value;
                  _shippingCost = double.tryParse(cost != null && cost.isNotEmpty ? cost[0]['value']?.toString() ?? '0' : '0') ?? 0;
                });
              },
            ),
        ],
      ),
    );
  }

  Widget _methodCard() {
    return InkWell(
      onTap: _selectPaymentMethod,
      borderRadius: BorderRadius.circular(22),
      child: _card(
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(9),
              decoration: BoxDecoration(color: _purple.withOpacity(0.10), borderRadius: BorderRadius.circular(14)),
              child: const Icon(Icons.account_balance_wallet_rounded, color: _primary, size: 20),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(_selectedPaymentMethod?.name ?? 'Pilih Metode Pembayaran', style: TextStyle(fontSize: 13, fontWeight: FontWeight.w800, color: _selectedPaymentMethod == null ? _muted : const Color(0xFF111827))),
                  const SizedBox(height: 3),
                  const Text('Virtual Account / QRIS / e-wallet', style: TextStyle(fontSize: 11, color: Color(0xFF94A3B8))),
                ],
              ),
            ),
            const Icon(Icons.chevron_right, color: Color(0xFF94A3B8)),
          ],
        ),
      ),
    );
  }

  InputDecoration _inputDecoration(String label) {
    return InputDecoration(
      labelText: label,
      labelStyle: const TextStyle(fontSize: 12, color: _muted),
      contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
      enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(14), borderSide: const BorderSide(color: Color(0xFFE2E8F0))),
      focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(14), borderSide: const BorderSide(color: _primary, width: 1.4)),
      border: OutlineInputBorder(borderRadius: BorderRadius.circular(14)),
    );
  }

  Widget _paymentInstructionCard(String timerText) {
    final isApproved = _paymentState == PaymentState.approved;

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        gradient: const LinearGradient(colors: [_primary, Color(0xFF123A68)], begin: Alignment.topLeft, end: Alignment.bottomRight),
        borderRadius: BorderRadius.circular(26),
        boxShadow: [BoxShadow(color: _primary.withOpacity(.22), blurRadius: 18, offset: const Offset(0, 8))],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                decoration: BoxDecoration(color: Colors.white.withOpacity(.14), borderRadius: BorderRadius.circular(20), border: Border.all(color: Colors.white.withOpacity(.12))),
                child: Text(isApproved ? 'LUNAS' : 'MENUNGGU PEMBAYARAN', style: const TextStyle(color: Colors.white, fontSize: 10, fontWeight: FontWeight.w800, letterSpacing: .4)),
              ),
              const Spacer(),
              Icon(isApproved ? Icons.check_circle : Icons.schedule_rounded, color: Colors.white, size: 22),
            ],
          ),
          const SizedBox(height: 16),
          Text(_selectedPaymentMethod?.name ?? 'Metode Pembayaran', style: const TextStyle(color: Colors.white, fontSize: 14, fontWeight: FontWeight.w800)),
          const SizedBox(height: 6),
          if (!isApproved) ...[
            Text('Selesaikan pembayaran sebelum waktu habis', style: TextStyle(color: Colors.white.withOpacity(0.74), fontSize: 12)),
            const SizedBox(height: 10),
            Text(timerText, style: const TextStyle(color: Colors.white, fontSize: 24, fontWeight: FontWeight.w900, letterSpacing: 1.2)),
          ] else ...[
            Text('Pembayaran sudah diterima oleh sistem.', style: TextStyle(color: Colors.white.withOpacity(0.74), fontSize: 12)),
          ],
          const SizedBox(height: 18),
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(18)),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                if (_vaNumber != null) ...[
                  const Text('Nomor Virtual Account', style: TextStyle(fontSize: 11, color: _muted, fontWeight: FontWeight.w700)),
                  const SizedBox(height: 6),
                  Row(
                    children: [
                      Expanded(child: SelectableText(_vaNumber!, style: const TextStyle(fontSize: 18, color: _primary, fontWeight: FontWeight.w900, letterSpacing: .8))),
                      IconButton(onPressed: _copyVa, icon: const Icon(Icons.copy_rounded, color: _primary, size: 20)),
                    ],
                  ),
                ],
                if (_qrCodeUrl != null) ...[
                  const Text('Scan QRIS', style: TextStyle(fontSize: 11, color: _muted, fontWeight: FontWeight.w700)),
                  const SizedBox(height: 10),
                  Center(child: Image.network(_qrCodeUrl!, width: 190, height: 190, fit: BoxFit.contain)),
                ],
                if (_vaNumber == null && _qrCodeUrl == null)
                  const Text('Ikuti instruksi pembayaran sesuai metode yang dipilih.', style: TextStyle(fontSize: 12, color: Color(0xFF475569))),
              ],
            ),
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                child: OutlinedButton.icon(
                  onPressed: _isLoading ? null : _refreshPaymentStatus,
                  icon: _isLoading
                      ? const SizedBox(width: 14, height: 14, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                      : const Icon(Icons.refresh_rounded, size: 17),
                  label: const Text('Refresh Status'),
                  style: OutlinedButton.styleFrom(
                    foregroundColor: Colors.white,
                    side: BorderSide(color: Colors.white.withOpacity(.55)),
                    textStyle: const TextStyle(fontSize: 12, fontWeight: FontWeight.w800),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _summaryCard({required bool showOnlyProducts}) {
    return _card(
      padding: const EdgeInsets.all(12),
      child: Column(
        children: [
          ...widget.cartItems.map(_summaryItem),
          if (!showOnlyProducts) ...[
            const Divider(height: 20),
            _priceRow('Subtotal Produk', widget.totalAmount),
            const SizedBox(height: 6),
            _priceRow('Ongkir', _shippingCost),
          ],
        ],
      ),
    );
  }

  Widget _summaryItem(Map<String, dynamic> item) {
    final product = item['product'] ?? {};
    final price = _itemPrice(item);
    final qty = _itemQty(item);
    final image = _imageUrl(item['selected_image'] ?? product['image']);
    final variation = item['variation_name']?.toString() ?? '';

    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Row(
        children: [
          Container(
            width: 48,
            height: 48,
            clipBehavior: Clip.antiAlias,
            decoration: BoxDecoration(color: _surface, borderRadius: BorderRadius.circular(14), border: Border.all(color: const Color(0xFFE2E8F0))),
            child: image.isEmpty
                ? const Icon(Icons.image_outlined, color: Color(0xFF94A3B8), size: 22)
                : Image.network(image, fit: BoxFit.cover, errorBuilder: (_, __, ___) => const Icon(Icons.image_not_supported, color: Color(0xFF94A3B8))),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(product['name'] ?? 'Produk', maxLines: 1, overflow: TextOverflow.ellipsis, style: const TextStyle(fontSize: 12.5, fontWeight: FontWeight.w800, color: Color(0xFF111827))),
                if (variation.isNotEmpty) Text('Variasi: $variation', maxLines: 1, overflow: TextOverflow.ellipsis, style: const TextStyle(fontSize: 11, color: _muted)),
                Text('$qty x ${_currency(price)}', style: const TextStyle(fontSize: 11, color: _muted)),
              ],
            ),
          ),
          Text(_currency(price * qty), style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w900, color: _primary)),
        ],
      ),
    );
  }

  Widget _totalOrderCard() {
    return _card(
      child: Column(
        children: [
          _priceRow('Subtotal Produk', widget.totalAmount),
          const SizedBox(height: 8),
          _priceRow('Ongkir', _shippingCost),
          const Divider(height: 22),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text('Total Order', style: TextStyle(fontSize: 14, color: _primary, fontWeight: FontWeight.w900)),
              Text(_currency(_grandTotal), style: const TextStyle(fontSize: 18, color: _primary, fontWeight: FontWeight.w900)),
            ],
          ),
        ],
      ),
    );
  }

  Widget _priceRow(String label, num value) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(label, style: const TextStyle(fontSize: 12, color: _muted)),
        Text(_currency(value), style: const TextStyle(fontSize: 12.5, color: Color(0xFF111827), fontWeight: FontWeight.w800)),
      ],
    );
  }

  Widget _bottomButton() {
    if (_paymentState == PaymentState.pending) {
      return ElevatedButton(
        onPressed: null,
        style: ElevatedButton.styleFrom(
          disabledBackgroundColor: const Color(0xFF94A3B8),
          padding: const EdgeInsets.symmetric(vertical: 13),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
        ),
        child: const Text('MENUNGGU PEMBAYARAN...', style: TextStyle(color: Colors.white, fontSize: 13, fontWeight: FontWeight.w900)),
      );
    }

    if (_paymentState == PaymentState.approved) {
      return ElevatedButton(
        onPressed: _confirmOrder,
        style: ElevatedButton.styleFrom(
          backgroundColor: _primary,
          foregroundColor: Colors.white,
          elevation: 0,
          padding: const EdgeInsets.symmetric(vertical: 13),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
        ),
        child: const Text('SELESAIKAN PESANAN', style: TextStyle(fontSize: 13, fontWeight: FontWeight.w900)),
      );
    }

    return ElevatedButton(
      onPressed: _isLoading ? null : _payNow,
      style: ElevatedButton.styleFrom(
        backgroundColor: _primary,
        disabledBackgroundColor: const Color(0xFFCBD5E1),
        foregroundColor: Colors.white,
        elevation: 0,
        padding: const EdgeInsets.symmetric(vertical: 13),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
      ),
      child: _isLoading
          ? const SizedBox(width: 19, height: 19, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2))
          : const Text('BAYAR SEKARANG', style: TextStyle(fontSize: 13, fontWeight: FontWeight.w900)),
    );
  }
}

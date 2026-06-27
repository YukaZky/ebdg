import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../models/payment_method_model.dart';
import '../services/api_service.dart';
import '../services/checkout_api_service.dart';
import '../services/marketplace_api_service.dart';
import 'admin/address_list_screen.dart';
import 'metode_screen.dart';
import 'order_confirmation_screen.dart';

// ignore_for_file: deprecated_member_use

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
  static const Color _primary = Color(0xFF0C2442);
  static const Color _accent = Color(0xFFF39C12);
  static const Color _purple = Color(0xFF6C4DFF);
  static const Color _surface = Color(0xFFF7F8FC);
  static const Color _muted = Color(0xFF64748B);
  static const Color _danger = Color(0xFFB91C1C);
  static const Color _dangerDark = Color(0xFF7F1D1D);

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
  bool _isLoadingCoupons = false;

  List<Map<String, dynamic>> _claimedCoupons = [];
  Map<String, dynamic>? _selectedCouponTake;

  String? _orderId;
  String? _vaNumber;
  String? _qrCodeUrl;
  Timer? _countdownTimer;
  Duration _timeLeft = Duration.zero;
  Map<String, dynamic>? _orderData;

  double get _discountTotal => _couponDiscountPreview(_selectedCouponTake);
  double get _grandTotal => (widget.totalAmount + _shippingCost - _discountTotal).clamp(0, double.infinity).toDouble();
  bool get _isPaymentMode => _paymentState == PaymentState.pending || _paymentState == PaymentState.approved;
  bool get _isCanceledCheckout {
    final raw = _orderData?['frontend_status']?.toString().toLowerCase() ?? _orderData?['status']?.toString().toLowerCase() ?? '';
    return raw == 'canceled' || raw == 'cancelled';
  }
  Color get _main => _isCanceledCheckout ? _danger : _primary;
  Color get _gradientEnd => _isCanceledCheckout ? _dangerDark : const Color(0xFF123A68);

  String get _addressText => _addressData?['address']?.toString() ?? _addressData?['detail_address']?.toString() ?? '-';
  String get _phoneText => _addressData?['phone']?.toString() ?? '-';
  String get _provinceName => _addressData?['province_name']?.toString() ?? 'Unknown';
  String get _cityName => _addressData?['city_name']?.toString() ?? 'Unknown';
  String get _courierWithService => '${_selectedCourier?.toUpperCase()} - $_selectedService';

  @override
  void initState() {
    super.initState();
    _loadMainAddress();
    _loadClaimedCoupons();
  }

  @override
  void dispose() {
    _countdownTimer?.cancel();
    super.dispose();
  }

  Map<String, dynamic> _asMap(dynamic value) {
    if (value is Map<String, dynamic>) return value;
    if (value is Map) return Map<String, dynamic>.from(value);
    return <String, dynamic>{};
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
        selected = Map<String, dynamic>.from(data.firstWhere((address) => address['isdefault'] == 1 || address['isdefault'] == '1' || address['isdefault'] == true || address['is_main'] == 1 || address['is_main'] == '1' || address['is_main'] == true));
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

    if (_addressData != null && _selectedCourier != null) _loadShippingCost();
  }

  Future<void> _loadClaimedCoupons() async {
    setState(() => _isLoadingCoupons = true);
    final data = await MarketplaceApiService.claimedCoupons();
    if (!mounted) return;
    setState(() {
      _claimedCoupons = data.whereType<Map>().map((item) => Map<String, dynamic>.from(item)).toList();
      _isLoadingCoupons = false;
      if (_selectedCouponTake != null) {
        final currentId = _selectedCouponTake!['id']?.toString();
        final updated = _claimedCoupons.where((item) => item['id']?.toString() == currentId).toList();
        _selectedCouponTake = updated.isEmpty ? null : updated.first;
      }
    });
  }

  Future<void> _loadShippingCost() async {
    if (_addressData == null || _addressData!['city_id'] == null || _selectedCourier == null) return;

    setState(() {
      _isLoadingShipping = true;
      _shippingOptions = [];
      _selectedService = null;
      _shippingCost = 0;
    });

    final data = await ApiService.checkCost(_addressData!['city_id'].toString(), widget.totalWeight.toInt(), _selectedCourier!);
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
    final result = await Navigator.push(context, MaterialPageRoute(builder: (_) => const MetodeScreen()));
    if (result is PaymentMethodModel) setState(() => _selectedPaymentMethod = result);
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
    if (_selectedCouponTake != null && _discountTotal <= 0) {
      _showSnack('Kupon tidak berlaku untuk produk di keranjang ini.', error: true);
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
      couponTakeId: _selectedCouponTake == null ? null : int.tryParse(_selectedCouponTake!['id']?.toString() ?? ''),
    );

    if (!mounted) return;
    setState(() => _isLoading = false);

    if (response == null || response['success'] != true) {
      _showSnack(response?['message']?.toString() ?? 'Gagal memproses pesanan.', error: true);
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

    if (_selectedPaymentMethod?.paymentType == 'qris' && _qrCodeUrl == null) {
      _showSnack('Pembayaran QRIS dibuat, tetapi URL QR belum diterima dari Midtrans. Tekan Refresh Status.');
    }
  }

  String? _readVaNumber(dynamic info, dynamic midtrans) {
    if (info is Map && info['va_number'] != null) return info['va_number'].toString();
    if (midtrans is Map && midtrans['va_numbers'] is List && midtrans['va_numbers'].isNotEmpty) return midtrans['va_numbers'][0]['va_number']?.toString();
    if (midtrans is Map && midtrans['permata_va_number'] != null) return midtrans['permata_va_number'].toString();
    if (midtrans is Map && midtrans['bill_key'] != null) return 'Bill Key: ${midtrans['bill_key']}\nBiller Code: ${midtrans['biller_code'] ?? ''}';
    return null;
  }

  String? _readQrCodeUrl(dynamic info, dynamic midtrans) {
    if (info is Map && info['qr_code_url'] != null) return info['qr_code_url'].toString();
    final actions = midtrans is Map ? midtrans['actions'] : null;
    if (actions is List) {
      for (final action in actions) {
        if (action is Map && (action['name'] == 'generate-qr-code' || action['name'] == 'deeplink-redirect')) return action['url']?.toString();
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
      _timeLeft = expiryTime == null ? const Duration(hours: 24) : DateTime.parse(expiryTime).difference(DateTime.now());
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
      final paymentInfo = response['payment_info'];
      if (paymentInfo != null) _qrCodeUrl = _readQrCodeUrl(paymentInfo, null) ?? _qrCodeUrl;
      if (status == 'settlement' || status == 'capture' || status == 'approved') {
        setState(() => _paymentState = PaymentState.approved);
        _countdownTimer?.cancel();
        _showSnack('Pembayaran berhasil diterima.');
      } else if (status == 'expire' || status == 'cancel' || status == 'declined') {
        setState(() => _paymentState = PaymentState.expired);
        _countdownTimer?.cancel();
      } else {
        setState(() {});
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
      if (response != null && response['success'] == true && response['order'] != null) _orderData = Map<String, dynamic>.from(response['order']);
    }
    if (!mounted || _orderData == null) return;
    Navigator.pushAndRemoveUntil(context, MaterialPageRoute(builder: (_) => OrderConfirmationScreen(order: _orderData!)), (_) => false);
  }

  void _copyVa() {
    if (_vaNumber == null) return;
    Clipboard.setData(ClipboardData(text: _vaNumber!));
    _showSnack('Nomor VA disalin.');
  }

  void _showSnack(String message, {bool error = false}) {
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(message, style: const TextStyle(fontSize: 13)), backgroundColor: error ? Colors.red : null, behavior: SnackBarBehavior.floating));
  }

  double _itemPrice(Map<String, dynamic> item) {
    final product = _asMap(item['product']);
    return double.tryParse((item['price'] ?? product['regular_price'] ?? product['active_price'] ?? 0).toString()) ?? 0;
  }

  int _itemQty(Map<String, dynamic> item) => int.tryParse((item['quantity'] ?? 1).toString()) ?? 1;

  int _productSellerId(Map<String, dynamic> item) {
    final product = _asMap(item['product']);
    return int.tryParse((product['user_id'] ?? item['user_id'] ?? item['seller_id'] ?? '').toString()) ?? 0;
  }

  Map<String, dynamic> _couponMap(Map<String, dynamic>? take) => _asMap(take?['coupon']);

  int _couponSellerId(Map<String, dynamic>? take) {
    final coupon = _couponMap(take);
    return int.tryParse((coupon['id_user'] ?? coupon['user_id'] ?? coupon['seller_id'] ?? '').toString()) ?? 0;
  }

  double _couponEligibleSubtotal(Map<String, dynamic>? take) {
    final sellerId = _couponSellerId(take);
    if (sellerId <= 0) return 0;
    double total = 0;
    for (final item in widget.cartItems) {
      if (_productSellerId(item) == sellerId) total += _itemPrice(item) * _itemQty(item);
    }
    return total;
  }

  double _couponDiscountPreview(Map<String, dynamic>? take) {
    if (take == null || take['can_use'] != true || take['is_expired'] == true) return 0;
    final coupon = _couponMap(take);
    final eligible = _couponEligibleSubtotal(take);
    if (eligible <= 0) return 0;
    final minPurchase = double.tryParse((coupon['min_purchase'] ?? coupon['cart_value'] ?? 0).toString()) ?? 0;
    if (minPurchase > 0 && eligible < minPurchase) return 0;
    final type = coupon['type']?.toString() ?? 'fixed';
    final value = double.tryParse((coupon['value'] ?? 0).toString()) ?? 0;
    final maxDiscount = double.tryParse((coupon['max_discount'] ?? 0).toString()) ?? 0;
    double discount = type == 'discount' ? eligible * value.clamp(0, 100) / 100 : value;
    if (maxDiscount > 0 && type == 'discount') discount = discount.clamp(0, maxDiscount).toDouble();
    return discount.clamp(0, eligible).toDouble();
  }

  bool _couponCanBeSelected(Map<String, dynamic> take) => take['can_use'] == true && take['is_expired'] != true && _couponDiscountPreview(take) > 0;

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
    final timerText = '${_timeLeft.inHours.remainder(24).toString().padLeft(2, '0')} : ${_timeLeft.inMinutes.remainder(60).toString().padLeft(2, '0')} : ${_timeLeft.inSeconds.remainder(60).toString().padLeft(2, '0')}';
    return WillPopScope(
      onWillPop: _handleBack,
      child: Scaffold(
        backgroundColor: _surface,
        body: SingleChildScrollView(
          physics: const BouncingScrollPhysics(),
          padding: const EdgeInsets.only(bottom: 120),
          child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            _pageHeader(timerText),
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 16, 16, 0),
              child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: _isPaymentMode ? _paymentChildren(timerText) : _checkoutChildren()),
            ),
          ]),
        ),
        bottomSheet: _bottomSheet(),
      ),
    );
  }

  List<Widget> _checkoutChildren() => [
        _sectionLabel('Alamat'), const SizedBox(height: 8), _addressCard(), const SizedBox(height: 14),
        _sectionLabel('Pengiriman'), const SizedBox(height: 8), _shippingCard(), const SizedBox(height: 14),
        _sectionLabel('Pembayaran'), const SizedBox(height: 8), _methodCard(), const SizedBox(height: 14),
        _sectionLabel('Kupon Diskon'), const SizedBox(height: 8), _couponCard(), const SizedBox(height: 14),
        _sectionLabel('Ringkasan'), const SizedBox(height: 8), _summaryCard(showOnlyProducts: false),
      ];

  List<Widget> _paymentChildren(String timerText) => [
        _paymentInstructionCard(timerText), const SizedBox(height: 14),
        _sectionLabel('Daftar Barang yang Diorder'), const SizedBox(height: 8), _summaryCard(showOnlyProducts: true),
        const SizedBox(height: 14), _totalOrderCard(), const SizedBox(height: 12),
        TextButton.icon(onPressed: _backToCheckoutForm, icon: const Icon(Icons.arrow_back, size: 18), label: const Text('Kembali ubah alamat, kurir, metode pembayaran, atau kupon'), style: TextButton.styleFrom(foregroundColor: _main, textStyle: const TextStyle(fontSize: 12, fontWeight: FontWeight.w700))),
      ];

  Widget _bottomSheet() => Container(
        padding: const EdgeInsets.fromLTRB(16, 12, 16, 16),
        decoration: BoxDecoration(color: Colors.white, boxShadow: [BoxShadow(color: Colors.black.withOpacity(.08), blurRadius: 16, offset: const Offset(0, -5))]),
        child: SafeArea(child: Column(mainAxisSize: MainAxisSize.min, children: [
          Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [const Text('Total Order', style: TextStyle(color: _muted, fontSize: 13)), Text(_currency(_grandTotal), style: TextStyle(fontSize: 18, fontWeight: FontWeight.w900, color: _main))]),
          if (_discountTotal > 0) Padding(padding: const EdgeInsets.only(top: 3), child: Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [const Text('Diskon kupon diterapkan', style: TextStyle(color: Colors.green, fontSize: 11, fontWeight: FontWeight.w700)), Text('-${_currency(_discountTotal)}', style: const TextStyle(color: Colors.green, fontSize: 11, fontWeight: FontWeight.w900))])),
          const SizedBox(height: 10),
          SizedBox(width: double.infinity, child: _bottomButton()),
        ])),
      );

  Widget _circleAction(IconData icon, VoidCallback? onTap) => InkWell(onTap: onTap, borderRadius: BorderRadius.circular(999), child: Container(width: 42, height: 42, decoration: BoxDecoration(color: Colors.white.withOpacity(0.14), shape: BoxShape.circle, border: Border.all(color: Colors.white.withOpacity(0.12))), child: Icon(icon, color: Colors.white, size: 21)));

  Widget _pageHeader(String timerText) {
    final title = _isCanceledCheckout ? 'Checkout Canceled' : _isPaymentMode ? 'Pembayaran' : 'Checkout';
    final subtitle = _isCanceledCheckout ? 'Pesanan sudah canceled dan tidak bisa dilanjutkan.' : _isPaymentMode ? (_paymentState == PaymentState.approved ? 'Pembayaran diterima, selesaikan pesanan.' : 'Selesaikan pembayaran sebelum waktu habis.') : '${widget.cartItems.length} produk siap diproses.';
    final chip = _isCanceledCheckout ? 'Canceled' : _isPaymentMode ? (_paymentState == PaymentState.approved ? 'LUNAS' : timerText) : 'Ringkasan order';
    return Container(
      decoration: BoxDecoration(gradient: LinearGradient(colors: [_main, _gradientEnd], begin: Alignment.topLeft, end: Alignment.bottomRight), borderRadius: const BorderRadius.vertical(bottom: Radius.circular(30))),
      child: SafeArea(bottom: false, child: Padding(padding: const EdgeInsets.fromLTRB(18, 16, 18, 22), child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [_circleAction(Icons.arrow_back_rounded, () async { final canPop = await _handleBack(); if (canPop && mounted) Navigator.pop(context); }), Container(padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 7), decoration: BoxDecoration(color: Colors.white.withOpacity(0.14), borderRadius: BorderRadius.circular(99), border: Border.all(color: Colors.white.withOpacity(0.12))), child: Text(chip, style: const TextStyle(color: Colors.white, fontSize: 12, fontWeight: FontWeight.w800)))]),
        const SizedBox(height: 16),
        Container(padding: const EdgeInsets.all(14), decoration: BoxDecoration(color: Colors.white.withOpacity(0.12), borderRadius: BorderRadius.circular(24), border: Border.all(color: Colors.white.withOpacity(0.16))), child: Row(children: [
          Container(width: 56, height: 56, decoration: const BoxDecoration(color: Colors.white, shape: BoxShape.circle), child: Icon(_isCanceledCheckout ? Icons.cancel_rounded : _isPaymentMode ? Icons.account_balance_wallet_rounded : Icons.shopping_bag_rounded, color: _main, size: 30)),
          const SizedBox(width: 14),
          Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [Text(title, style: const TextStyle(color: Colors.white, fontSize: 17, fontWeight: FontWeight.w900)), const SizedBox(height: 5), Text(subtitle, maxLines: 2, overflow: TextOverflow.ellipsis, style: TextStyle(color: Colors.white.withOpacity(0.84), fontSize: 12.5, height: 1.35)), if (_selectedPaymentMethod != null) ...[const SizedBox(height: 3), Text(_selectedPaymentMethod!.name, maxLines: 1, overflow: TextOverflow.ellipsis, style: TextStyle(color: Colors.white.withOpacity(0.72), fontSize: 12))]])),
        ])),
      ]))),
    );
  }

  Widget _sectionLabel(String text) => Text(text, style: TextStyle(fontSize: 13, color: _main, fontWeight: FontWeight.w900));
  Widget _card({required Widget child, EdgeInsetsGeometry padding = const EdgeInsets.all(14)}) => Container(width: double.infinity, padding: padding, decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(22), border: Border.all(color: _isCanceledCheckout ? const Color(0xFFFCA5A5) : const Color(0xFFE2E8F0)), boxShadow: [BoxShadow(color: Colors.black.withOpacity(.04), blurRadius: 14, offset: const Offset(0, 6))]), child: child);

  Widget _addressCard() {
    if (_isLoadingAddress) return _card(child: Center(child: Padding(padding: const EdgeInsets.all(8), child: CircularProgressIndicator(color: _main))));
    if (_addressData == null) return InkWell(onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const AddressListScreen())).then((_) => _loadMainAddress()), borderRadius: BorderRadius.circular(22), child: _card(child: const Row(children: [Icon(Icons.location_off, color: Colors.red, size: 20), SizedBox(width: 10), Expanded(child: Text('Alamat belum diatur. Klik untuk memilih alamat.', style: TextStyle(color: Colors.red, fontWeight: FontWeight.w700, fontSize: 13)))])));
    return _card(child: Row(crossAxisAlignment: CrossAxisAlignment.start, children: [Container(padding: const EdgeInsets.all(9), decoration: BoxDecoration(color: _purple.withOpacity(0.10), borderRadius: BorderRadius.circular(14)), child: Icon(Icons.location_on_rounded, color: _main, size: 20)), const SizedBox(width: 10), Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [Text('${_addressData!['name']} | ${_addressData!['phone']}', style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w800, color: Color(0xFF111827))), const SizedBox(height: 5), Text(_addressText, style: const TextStyle(fontSize: 12, height: 1.35, color: Color(0xFF475569))), const SizedBox(height: 3), Text('${_addressData!['city_name']}, ${_addressData!['province_name']} - ${_addressData!['postal_code']}', style: const TextStyle(fontSize: 12, color: _muted))])), TextButton(onPressed: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const AddressListScreen())).then((_) => _loadMainAddress()), child: const Text('Ubah', style: TextStyle(fontSize: 12, fontWeight: FontWeight.w800)))]));
  }

  Widget _shippingCard() {
    if (_addressData == null) return const SizedBox.shrink();
    return _card(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      DropdownButtonFormField<String>(value: _selectedCourier, decoration: _inputDecoration('Pilih Ekspedisi'), style: const TextStyle(fontSize: 13, color: Color(0xFF111827)), items: _couriers.map((courier) => DropdownMenuItem(value: courier, child: Text(courier.toUpperCase()))).toList(), onChanged: (value) { setState(() => _selectedCourier = value); _loadShippingCost(); }),
      const SizedBox(height: 12),
      if (_isLoadingShipping) Center(child: Padding(padding: const EdgeInsets.all(8), child: CircularProgressIndicator(color: _main))) else if (_shippingOptions.isNotEmpty) DropdownButtonFormField<String>(isExpanded: true, value: _selectedService, decoration: _inputDecoration('Pilih Layanan'), style: const TextStyle(fontSize: 13, color: Color(0xFF111827)), items: _shippingOptions.map<DropdownMenuItem<String>>((option) { final cost = option['cost'] as List?; final value = cost != null && cost.isNotEmpty ? cost[0]['value']?.toString() ?? '0' : '0'; return DropdownMenuItem(value: option['service']?.toString(), child: Text('${option['service']} - Rp $value', overflow: TextOverflow.ellipsis)); }).toList(), onChanged: (value) { final selected = _shippingOptions.firstWhere((option) => option['service']?.toString() == value); final cost = selected['cost'] as List?; setState(() { _selectedService = value; _shippingCost = double.tryParse(cost != null && cost.isNotEmpty ? cost[0]['value']?.toString() ?? '0' : '0') ?? 0; }); }),
    ]));
  }

  Widget _methodCard() => InkWell(onTap: _selectPaymentMethod, borderRadius: BorderRadius.circular(22), child: _card(child: Row(children: [Container(padding: const EdgeInsets.all(9), decoration: BoxDecoration(color: _purple.withOpacity(0.10), borderRadius: BorderRadius.circular(14)), child: Icon(Icons.account_balance_wallet_rounded, color: _main, size: 20)), const SizedBox(width: 10), Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [Text(_selectedPaymentMethod?.name ?? 'Pilih Metode Pembayaran', style: TextStyle(fontSize: 13, fontWeight: FontWeight.w800, color: _selectedPaymentMethod == null ? _muted : const Color(0xFF111827))), const SizedBox(height: 3), const Text('Virtual Account / QRIS / e-wallet', style: TextStyle(fontSize: 11, color: Color(0xFF94A3B8)))])), const Icon(Icons.chevron_right, color: Color(0xFF94A3B8))])));

  Widget _couponCard() {
    final selected = _selectedCouponTake;
    final coupon = _couponMap(selected);
    final discount = _discountTotal;
    return InkWell(
      onTap: _isLoadingCoupons ? null : _showCouponSheet,
      borderRadius: BorderRadius.circular(22),
      child: _card(child: Row(children: [
        Container(padding: const EdgeInsets.all(9), decoration: BoxDecoration(color: _accent.withOpacity(0.12), borderRadius: BorderRadius.circular(14)), child: Icon(Icons.local_activity_rounded, color: _main, size: 20)),
        const SizedBox(width: 10),
        Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Text(selected == null ? 'Pilih Kupon Saya' : '${coupon['code'] ?? '-'} • -${_currency(discount)}', style: TextStyle(fontSize: 13, fontWeight: FontWeight.w900, color: selected == null ? _muted : const Color(0xFF111827))),
          const SizedBox(height: 3),
          Text(selected == null ? '${_claimedCoupons.length} kupon sudah kamu ambil' : 'Hanya memotong produk toko pemilik kupon', style: const TextStyle(fontSize: 11, color: Color(0xFF94A3B8))),
        ])),
        if (selected != null) IconButton(onPressed: () => setState(() => _selectedCouponTake = null), icon: const Icon(Icons.close_rounded, color: _muted, size: 19)) else const Icon(Icons.chevron_right, color: Color(0xFF94A3B8)),
      ])),
    );
  }

  void _showCouponSheet() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => DraggableScrollableSheet(
        initialChildSize: .62,
        minChildSize: .38,
        maxChildSize: .92,
        builder: (context, controller) => Container(
          padding: const EdgeInsets.fromLTRB(16, 14, 16, 16),
          decoration: const BoxDecoration(color: Colors.white, borderRadius: BorderRadius.vertical(top: Radius.circular(26))),
          child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Center(child: Container(width: 44, height: 5, decoration: BoxDecoration(color: const Color(0xFFE2E8F0), borderRadius: BorderRadius.circular(99)))),
            const SizedBox(height: 16),
            const Text('Pilih Kupon Saya', style: TextStyle(fontSize: 17, fontWeight: FontWeight.w900, color: _primary)),
            const SizedBox(height: 4),
            const Text('Kupon hanya memotong produk dari toko pemilik kupon.', style: TextStyle(fontSize: 12, color: _muted)),
            const SizedBox(height: 12),
            Expanded(
              child: _claimedCoupons.isEmpty
                  ? const Center(child: Text('Belum ada kupon yang bisa dipilih.'))
                  : ListView.builder(controller: controller, itemCount: _claimedCoupons.length, itemBuilder: (context, index) {
                      final take = _claimedCoupons[index];
                      final coupon = _couponMap(take);
                      final discount = _couponDiscountPreview(take);
                      final eligible = _couponEligibleSubtotal(take);
                      final canSelect = _couponCanBeSelected(take);
                      final reason = take['is_expired'] == true ? 'Kadaluarsa' : take['can_use'] != true ? 'Tidak bisa digunakan' : eligible <= 0 ? 'Tidak ada produk toko ini' : discount <= 0 ? 'Minimum belum terpenuhi' : 'Potongan ${_currency(discount)}';
                      return Opacity(
                        opacity: canSelect ? 1 : .55,
                        child: Container(
                          margin: const EdgeInsets.only(bottom: 10),
                          padding: const EdgeInsets.all(13),
                          decoration: BoxDecoration(color: _surface, borderRadius: BorderRadius.circular(18), border: Border.all(color: canSelect ? _accent.withOpacity(.45) : const Color(0xFFE2E8F0))),
                          child: Row(children: [
                            const Icon(Icons.confirmation_number_rounded, color: _primary),
                            const SizedBox(width: 10),
                            Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [Text(coupon['code']?.toString() ?? '-', style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w900, color: _primary)), const SizedBox(height: 3), Text('${coupon['name'] ?? 'Kupon'} • $reason', maxLines: 2, overflow: TextOverflow.ellipsis, style: const TextStyle(fontSize: 11.5, color: _muted))])),
                            TextButton(onPressed: canSelect ? () { setState(() => _selectedCouponTake = take); Navigator.pop(context); } : null, child: const Text('Pakai')),
                          ]),
                        ),
                      );
                    }),
            ),
          ]),
        ),
      ),
    );
  }

  InputDecoration _inputDecoration(String label) => InputDecoration(labelText: label, labelStyle: const TextStyle(fontSize: 12, color: _muted), contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12), enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(14), borderSide: const BorderSide(color: Color(0xFFE2E8F0))), focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(14), borderSide: BorderSide(color: _main, width: 1.5)));

  Widget _paymentInstructionCard(String timerText) {
    final isApproved = _paymentState == PaymentState.approved;
    return Container(width: double.infinity, padding: const EdgeInsets.all(16), decoration: BoxDecoration(gradient: LinearGradient(colors: [_main, _gradientEnd], begin: Alignment.topLeft, end: Alignment.bottomRight), borderRadius: BorderRadius.circular(24), boxShadow: [BoxShadow(color: _main.withOpacity(.22), blurRadius: 18, offset: const Offset(0, 8))]), child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      Row(children: [Container(padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5), decoration: BoxDecoration(color: Colors.white.withOpacity(.14), borderRadius: BorderRadius.circular(20), border: Border.all(color: Colors.white.withOpacity(.12))), child: Text(isApproved ? 'LUNAS' : 'MENUNGGU PEMBAYARAN', style: const TextStyle(color: Colors.white, fontSize: 10, fontWeight: FontWeight.w800, letterSpacing: .4))), const Spacer(), Icon(isApproved ? Icons.check_circle : Icons.schedule_rounded, color: Colors.white, size: 22)]),
      const SizedBox(height: 16), Text(_selectedPaymentMethod?.name ?? 'Metode Pembayaran', style: const TextStyle(color: Colors.white, fontSize: 14, fontWeight: FontWeight.w800)), const SizedBox(height: 6),
      if (!isApproved) ...[Text('Selesaikan pembayaran sebelum waktu habis', style: TextStyle(color: Colors.white.withOpacity(0.74), fontSize: 12)), const SizedBox(height: 10), Text(timerText, style: const TextStyle(color: Colors.white, fontSize: 20, fontWeight: FontWeight.w900, letterSpacing: 1.2))] else Text('Pembayaran sudah diterima oleh sistem.', style: TextStyle(color: Colors.white.withOpacity(0.74), fontSize: 12)),
      const SizedBox(height: 18), Container(width: double.infinity, padding: const EdgeInsets.all(14), decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(18)), child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        if (_vaNumber != null) ...[const Text('Nomor Virtual Account', style: TextStyle(fontSize: 11, color: _muted, fontWeight: FontWeight.w700)), const SizedBox(height: 6), Row(children: [Expanded(child: SelectableText(_vaNumber!, style: TextStyle(fontSize: 18, color: _main, fontWeight: FontWeight.w900, letterSpacing: .8))), IconButton(onPressed: _copyVa, icon: Icon(Icons.copy_rounded, color: _main, size: 20))])],
        if (_qrCodeUrl != null) ...[const Text('Scan QRIS', style: TextStyle(fontSize: 11, color: _muted, fontWeight: FontWeight.w700)), const SizedBox(height: 10), Center(child: Image.network(_qrCodeUrl!, width: 190, height: 190, fit: BoxFit.contain))],
        if (_vaNumber == null && _qrCodeUrl == null) Text(_selectedPaymentMethod?.paymentType == 'qris' ? 'QRIS belum diterima dari Midtrans. Tekan Refresh Status untuk mencoba membaca ulang QR.' : 'Ikuti instruksi pembayaran sesuai metode yang dipilih.', style: const TextStyle(fontSize: 12, color: Color(0xFF475569))),
      ])),
      const SizedBox(height: 12), OutlinedButton.icon(onPressed: _isLoading ? null : _refreshPaymentStatus, icon: _isLoading ? const SizedBox(width: 14, height: 14, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white)) : const Icon(Icons.refresh_rounded, size: 17), label: const Text('Refresh Status'), style: OutlinedButton.styleFrom(foregroundColor: Colors.white, side: BorderSide(color: Colors.white.withOpacity(.55)), textStyle: const TextStyle(fontSize: 12, fontWeight: FontWeight.w800), shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)))),
    ]));
  }

  Widget _summaryCard({required bool showOnlyProducts}) => _card(padding: const EdgeInsets.all(12), child: Column(children: [...widget.cartItems.map(_summaryItem), if (!showOnlyProducts) ...[const Divider(height: 20), _priceRow('Subtotal Produk', widget.totalAmount), const SizedBox(height: 6), _priceRow('Ongkir', _shippingCost), if (_discountTotal > 0) ...[const SizedBox(height: 6), _priceRow('Diskon Kupon', -_discountTotal, green: true)]]));

  Widget _summaryItem(Map<String, dynamic> item) {
    final product = _asMap(item['product']); final price = _itemPrice(item); final qty = _itemQty(item); final image = _imageUrl(item['selected_image'] ?? product['image']); final variation = item['variation_name']?.toString() ?? '';
    return Padding(padding: const EdgeInsets.only(bottom: 10), child: Row(children: [Container(width: 48, height: 48, clipBehavior: Clip.antiAlias, decoration: BoxDecoration(color: _surface, borderRadius: BorderRadius.circular(14), border: Border.all(color: const Color(0xFFE2E8F0))), child: image.isEmpty ? const Icon(Icons.image_outlined, color: Color(0xFF94A3B8), size: 22) : Image.network(image, fit: BoxFit.cover, errorBuilder: (_, __, ___) => const Icon(Icons.image_not_supported, color: Color(0xFF94A3B8)))), const SizedBox(width: 10), Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [Text(product['name'] ?? 'Produk', maxLines: 1, overflow: TextOverflow.ellipsis, style: const TextStyle(fontSize: 12.5, fontWeight: FontWeight.w800, color: Color(0xFF111827))), if (variation.isNotEmpty) Text('Variasi: $variation', maxLines: 1, overflow: TextOverflow.ellipsis, style: const TextStyle(fontSize: 11, color: _muted)), Text('$qty x ${_currency(price)}', style: const TextStyle(fontSize: 11, color: _muted))])), Text(_currency(price * qty), style: TextStyle(fontSize: 12, fontWeight: FontWeight.w900, color: _main))]));
  }

  Widget _totalOrderCard() => _card(child: Column(children: [_priceRow('Subtotal Produk', widget.totalAmount), const SizedBox(height: 8), _priceRow('Ongkir', _shippingCost), if (_discountTotal > 0) ...[const SizedBox(height: 8), _priceRow('Diskon Kupon', -_discountTotal, green: true)], const Divider(height: 22), Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [Text('Total Order', style: TextStyle(fontSize: 14, color: _main, fontWeight: FontWeight.w900)), Text(_currency(_grandTotal), style: TextStyle(fontSize: 18, color: _main, fontWeight: FontWeight.w900))]) ]));

  Widget _priceRow(String label, num value, {bool strong = false, bool green = false}) => Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [Text(label, style: TextStyle(fontSize: 12, color: green ? Colors.green : _muted)), Text(value < 0 ? '-${_currency(value.abs())}' : _currency(value), style: TextStyle(fontSize: 12.5, color: green ? Colors.green : const Color(0xFF111827), fontWeight: FontWeight.w800))]);

  Widget _bottomButton() {
    if (_paymentState == PaymentState.pending) return ElevatedButton(onPressed: null, style: ElevatedButton.styleFrom(disabledBackgroundColor: const Color(0xFF94A3B8), padding: const EdgeInsets.symmetric(vertical: 13), shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14))), child: const Text('MENUNGGU PEMBAYARAN...', style: TextStyle(color: Colors.white, fontSize: 13, fontWeight: FontWeight.w900)));
    if (_paymentState == PaymentState.approved) return ElevatedButton(onPressed: _confirmOrder, style: ElevatedButton.styleFrom(backgroundColor: _main, foregroundColor: Colors.white, elevation: 0, padding: const EdgeInsets.symmetric(vertical: 13), shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14))), child: const Text('SELESAIKAN PESANAN', style: TextStyle(fontSize: 13, fontWeight: FontWeight.w900)));
    return ElevatedButton(onPressed: _isLoading ? null : _payNow, style: ElevatedButton.styleFrom(backgroundColor: _main, disabledBackgroundColor: const Color(0xFFCBD5E1), foregroundColor: Colors.white, elevation: 0, padding: const EdgeInsets.symmetric(vertical: 13), shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14))), child: _isLoading ? const SizedBox(width: 19, height: 19, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2)) : const Text('BAYAR SEKARANG', style: TextStyle(fontSize: 13, fontWeight: FontWeight.w900)));
  }
}

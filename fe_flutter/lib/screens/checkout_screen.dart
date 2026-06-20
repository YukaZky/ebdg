import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart'; // Untuk Copy-Paste Clipboard
import '../services/api_service.dart';
import '../services/checkout_api_service.dart';
import '../models/payment_method_model.dart';
import 'metode_screen.dart';
import 'order_confirmation_screen.dart';
import 'admin/address_list_screen.dart';

// Enum untuk State Machine Pembayaran
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
  // State 1: Alamat & Kurir
  Map<String, dynamic>? _mainAddress;
  bool _isLoadingAddress = true;
  List _shippingOptions = [];
  String? _selectedCourier;
  String? _selectedService;
  double _shippingCost = 0;
  final List<String> _couriers = ['jne', 'pos', 'tiki'];

  // State 2: Pembayaran
  PaymentMethodModel? _selectedPaymentMethod;
  PaymentState _paymentState = PaymentState.initial;
  bool _isLoading = false;
  bool _isLoadingOngkir = false;

  // Variabel penampung respons Midtrans Core API
  String? _orderId;
  String? _vaNumber;
  String? _qrCodeUrl;
  Timer? _countdownTimer;
  Duration _timeLeft = Duration.zero;
  Map<String, dynamic>? _finalOrderData;

  @override
  void initState() {
    super.initState();
    _fetchMainAddress();
  }

  @override
  void dispose() {
    _countdownTimer?.cancel();
    super.dispose();
  }

  // --- Fungsi Bawaan (Format Gambar, Alamat, Ongkir) ---
  String _imageUrl(dynamic image) {
    final value = image?.toString().trim() ?? '';
    if (value.isEmpty || value == 'null') return '';
    if (value.startsWith('http://') || value.startsWith('https://')) return value;
    final base = ApiService.baseUrl.replaceFirst(RegExp(r'/api/?$'), '');
    final cleanValue = value.startsWith('/') ? value.substring(1) : value;
    if (cleanValue.startsWith('uploads/') || cleanValue.startsWith('storage/')) return '$base/$cleanValue';
    return '$base/uploads/products/$cleanValue';
  }

  void _fetchMainAddress() async {
    setState(() => _isLoadingAddress = true);
    final data = await ApiService.getUserAddresses();
    if (!mounted) return;
    Map<String, dynamic>? mainAddr;
    if (data != null && data is List && data.isNotEmpty) {
      try {
        mainAddr = data.firstWhere((a) => a['isdefault'] == 1 || a['isdefault'] == '1' || a['isdefault'] == true || a['is_main'] == 1 || a['is_main'] == '1' || a['is_main'] == true);
      } catch (e) {
        mainAddr = data.first;
      }
    }
    setState(() {
      _mainAddress = mainAddr;
      _isLoadingAddress = false;
      _shippingOptions = [];
      _selectedService = null;
      _shippingCost = 0;
    });
    if (_selectedCourier != null && _mainAddress != null) _calculateShipping();
  }

  void _calculateShipping() async {
    if (_mainAddress == null || _mainAddress!['city_id'] == null || _selectedCourier == null) return;
    setState(() {
      _isLoadingOngkir = true;
      _shippingCost = 0;
      _selectedService = null;
    });
    final cityId = _mainAddress!['city_id'].toString();
    final data = await ApiService.checkCost(cityId, widget.totalWeight.toInt(), _selectedCourier!);
    if (!mounted) return;
    setState(() {
      _isLoadingOngkir = false;
      _shippingOptions = data;
      if (data.isNotEmpty && data[0]['cost'].isNotEmpty) {
        _selectedService = data[0]['service']?.toString();
        _shippingCost = double.tryParse(data[0]['cost'][0]['value']?.toString() ?? '0') ?? 0;
      }
    });
  }

  double _itemPrice(Map<String, dynamic> item) {
    final product = item['product'] ?? {};
    return double.tryParse((item['price'] ?? product['regular_price'] ?? 0).toString()) ?? 0;
  }

  int _itemQty(Map<String, dynamic> item) {
    return int.tryParse(item['quantity'].toString()) ?? 1;
  }

  // --- Navigasi Pilih Metode Pembayaran ---
  void _selectPaymentMethod() async {
    final result = await Navigator.push(
      context,
      MaterialPageRoute(builder: (context) => const MetodeScreen()),
    );
    if (result != null && result is PaymentMethodModel) {
      setState(() {
        _selectedPaymentMethod = result;
      });
    }
  }

  // --- LOGIKA STATE MACHINE ---

  // Aksi Klik Bayar Sekarang
  void _processCheckout() async {
    if (_mainAddress == null) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Harap atur alamat!'), backgroundColor: Colors.red));
      return;
    }
    if (_shippingCost == 0 || _selectedService == null) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Pilih layanan kurir!'), backgroundColor: Colors.red));
      return;
    }
    if (_selectedPaymentMethod == null) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Pilih metode pembayaran!'), backgroundColor: Colors.red));
      return;
    }

    setState(() => _isLoading = true);
    
    final courierWithService = '${_selectedCourier?.toUpperCase()} - $_selectedService';
    final addressString = _mainAddress!['address']?.toString() ?? _mainAddress!['detail_address']?.toString() ?? '-';
    final phoneString = _mainAddress!['phone']?.toString() ?? '-';
    final provinceName = _mainAddress!['province_name']?.toString() ?? 'Unknown';
    final cityName = _mainAddress!['city_name']?.toString() ?? 'Unknown';

    final responseData = await CheckoutApiService.checkout(
      address: addressString,
      phone: phoneString,
      provinceName: provinceName,
      cityName: cityName,
      courier: courierWithService,
      shippingCost: _shippingCost,
      cartItems: widget.cartItems,
      paymentType: _selectedPaymentMethod!.paymentType,
      bankCode: _selectedPaymentMethod!.bankCode,
    );

    if (!mounted) return;
    setState(() => _isLoading = false);

    if (responseData != null && responseData['success'] == true) {
      // Ambil data instruksi pembayaran dari respons Laravel
      final orderData = responseData['order'];
      final paymentInfo = responseData['payment_info'] ?? responseData['order']; // Sesuaikan dengan key JSON backend Anda
      
      if (orderData != null) {
        setState(() {
          _finalOrderData = orderData;
          _orderId = orderData['id'].toString();
          
          // Mengambil VA atau URL QRIS
          _vaNumber = paymentInfo['va_number']?.toString();
          _qrCodeUrl = paymentInfo['qr_code_url']?.toString();
          
          // Menyiapkan Timer mundur
          if (paymentInfo['expiry_time'] != null) {
            final expDate = DateTime.parse(paymentInfo['expiry_time']);
            _timeLeft = expDate.difference(DateTime.now());
            _startTimer();
          }

          // Transisi State ke Pending
          _paymentState = PaymentState.pending;
        });
      }
    } else {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Gagal memproses pesanan.'), backgroundColor: Colors.red));
    }
  }

  void _startTimer() {
    _countdownTimer?.cancel();
    _countdownTimer = Timer.periodic(const Duration(seconds: 1), (timer) {
      setState(() {
        if (_timeLeft.inSeconds > 0) {
          _timeLeft = _timeLeft - const Duration(seconds: 1);
        } else {
          // Jika waktu habis
          timer.cancel();
          _paymentState = PaymentState.expired;
        }
      });
    });
  }

  void _checkPaymentStatus() async {
    if (_orderId == null) return;
    setState(() => _isLoading = true);

    final statusResponse = await CheckoutApiService.checkOrderStatus(_orderId!);
    
    if (!mounted) return;
    setState(() => _isLoading = false);

    if (statusResponse != null && statusResponse['success'] == true) {
      final status = statusResponse['transaction_status'];
      
      setState(() {
        if (status == 'settlement' || status == 'capture' || status == 'approved') {
          _paymentState = PaymentState.approved;
          _countdownTimer?.cancel();
        } else if (status == 'expire' || status == 'cancel') {
          _paymentState = PaymentState.expired;
          _countdownTimer?.cancel();
        } else {
          ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Pembayaran belum diterima/menunggu proses.')));
        }
      });
    }
  }

  void _goToConfirmation() {
    if (_finalOrderData == null) return;
    Navigator.pushAndRemoveUntil(
      context,
      MaterialPageRoute(builder: (context) => OrderConfirmationScreen(order: _finalOrderData!)),
      (route) => false,
    );
  }

  void _copyToClipboard(String text) {
    Clipboard.setData(ClipboardData(text: text));
    ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Nomor VA Disalin!'), backgroundColor: Colors.green));
  }

  // --- WIDGET RENDERER ---

  Widget _summaryItem(Map<String, dynamic> item) {
    final product = item['product'] ?? {};
    final price = _itemPrice(item);
    final qty = _itemQty(item);
    final variationName = item['variation_name']?.toString() ?? '';
    final image = _imageUrl(item['selected_image'] ?? product['image']);

    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Row(
        children: [
          Container(
            width: 50, height: 50, clipBehavior: Clip.antiAlias,
            decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(8), border: Border.all(color: Colors.grey.shade200)),
            child: image.isNotEmpty
                ? Image.network(image, fit: BoxFit.cover, errorBuilder: (_, __, ___) => const Icon(Icons.image_not_supported, color: Colors.grey))
                : const Icon(Icons.image, color: Colors.grey),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Text(product['name'] ?? 'Produk', style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 14), maxLines: 1, overflow: TextOverflow.ellipsis),
              if (variationName.isNotEmpty) Text('Variasi: $variationName', style: TextStyle(color: Colors.grey[600], fontSize: 12)),
              Text('$qty x Rp ${price.toStringAsFixed(0)}', style: TextStyle(color: Colors.grey[600], fontSize: 12)),
            ]),
          ),
          Text('Rp ${(price * qty).toStringAsFixed(0)}', style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final grandTotal = widget.totalAmount + _shippingCost;
    
    // Format Waktu Mundur
    String strDigits(int n) => n.toString().padLeft(2, '0');
    final hours = strDigits(_timeLeft.inHours.remainder(24));
    final minutes = strDigits(_timeLeft.inMinutes.remainder(60));
    final seconds = strDigits(_timeLeft.inSeconds.remainder(60));

    return Scaffold(
      backgroundColor: const Color(0xFFF5F7FA),
      appBar: AppBar(title: const Text('Pengiriman & Checkout')),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          
          // BLOK 1: Alamat & Kurir (Hanya tampil jika state Initial)
          if (_paymentState == PaymentState.initial || _paymentState == PaymentState.expired) ...[
            if (_isLoadingAddress)
              const Center(child: Padding(padding: EdgeInsets.all(20.0), child: CircularProgressIndicator(color: Color(0xFFE65100))))
            else if (_mainAddress == null)
              InkWell(
                onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const AddressListScreen())).then((_) => _fetchMainAddress()),
                child: Container(
                  padding: const EdgeInsets.all(16), decoration: BoxDecoration(color: Colors.red.shade50, borderRadius: BorderRadius.circular(12), border: Border.all(color: Colors.red.shade200)),
                  child: const Row(children: [Icon(Icons.location_off, color: Colors.red), SizedBox(width: 12), Expanded(child: Text('Alamat belum diatur. Klik di sini.', style: TextStyle(color: Colors.red, fontWeight: FontWeight.bold))), Icon(Icons.arrow_forward_ios, size: 16, color: Colors.red)])
                )
              )
            else
              Container(
                padding: const EdgeInsets.all(16), decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(16), border: Border.all(color: Colors.grey.shade300)),
                child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                  Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
                    const Text('Alamat Pengiriman', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                    InkWell(
                      onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const AddressListScreen())).then((_) => _fetchMainAddress()),
                      child: const Text('Ubah', style: TextStyle(color: Color(0xFFE65100), fontWeight: FontWeight.bold)),
                    )
                  ]),
                  const Divider(height: 24),
                  Row(children: [
                    Container(padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4), decoration: BoxDecoration(color: const Color(0xFFE65100).withOpacity(0.1), borderRadius: BorderRadius.circular(4)), child: Text(_mainAddress!['label']?.toString() ?? 'Utama', style: const TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: Color(0xFFE65100)))),
                    const SizedBox(width: 8), Text('${_mainAddress!['name']} | ${_mainAddress!['phone']}', style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 14)),
                  ]),
                  const SizedBox(height: 8),
                  Text('${_mainAddress!['address'] ?? _mainAddress!['detail_address']}', style: TextStyle(color: Colors.grey.shade700, fontSize: 13, height: 1.4)),
                  const SizedBox(height: 4),
                  Text('${_mainAddress!['city_name']}, ${_mainAddress!['province_name']} - ${_mainAddress!['postal_code']}', style: TextStyle(color: Colors.grey.shade700, fontSize: 13)),
                ])
              ),

            const SizedBox(height: 16),

            if (_mainAddress != null)
              Container(
                padding: const EdgeInsets.all(16), decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(16)),
                child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                  const Text('Kurir Pengiriman', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                  const SizedBox(height: 12),
                  DropdownButtonFormField<String>(
                    decoration: const InputDecoration(labelText: 'Pilih Ekspedisi', border: OutlineInputBorder()), value: _selectedCourier,
                    items: _couriers.map((c) => DropdownMenuItem(value: c, child: Text(c.toUpperCase()))).toList(),
                    onChanged: (value) { setState(() => _selectedCourier = value); _calculateShipping(); },
                  ),
                  const SizedBox(height: 16),
                  if (_isLoadingOngkir) const Center(child: CircularProgressIndicator())
                  else if (_shippingOptions.isNotEmpty)
                    DropdownButtonFormField<String>(
                      isExpanded: true, decoration: const InputDecoration(labelText: 'Pilih Layanan', border: OutlineInputBorder()), value: _selectedService,
                      items: _shippingOptions.map<DropdownMenuItem<String>>((option) {
                        final service = option['service']?.toString() ?? 'Layanan';
                        final costList = option['cost'] as List?;
                        final costVal = (costList != null && costList.isNotEmpty) ? (costList[0]['value']?.toString() ?? '0') : '0';
                        return DropdownMenuItem(value: service, child: Text('$service - Rp $costVal', overflow: TextOverflow.ellipsis));
                      }).toList(),
                      onChanged: (value) {
                        setState(() {
                          _selectedService = value;
                          final selectedOption = _shippingOptions.firstWhere((opt) => opt['service']?.toString() == value);
                          final costList = selectedOption['cost'] as List?;
                          _shippingCost = double.tryParse((costList != null && costList.isNotEmpty) ? costList[0]['value']?.toString() ?? '0' : '0') ?? 0;
                        });
                      },
                    )
                ]),
              ),
              const SizedBox(height: 16),
          ], // Akhir Blok Initial

          // BLOK 2: Pilihan Metode Pembayaran ATAU Instruksi VA
          Container(
            padding: const EdgeInsets.all(16), decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(16)),
            child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              
              if (_paymentState == PaymentState.initial || _paymentState == PaymentState.expired) ...[
                const Text('Metode Pembayaran', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                const SizedBox(height: 12),
                InkWell(
                  onTap: _selectPaymentMethod,
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                    decoration: BoxDecoration(border: Border.all(color: Colors.grey.shade300), borderRadius: BorderRadius.circular(8)),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        _selectedPaymentMethod == null 
                          ? const Text('Pilih Metode Pembayaran', style: TextStyle(color: Colors.grey))
                          : Row(
                              children: [
                                Image.network(_selectedPaymentMethod!.iconUrl, width: 40, height: 25, errorBuilder: (_,__,___) => const Icon(Icons.payment)),
                                const SizedBox(width: 12),
                                Text(_selectedPaymentMethod!.name, style: const TextStyle(fontWeight: FontWeight.bold)),
                              ],
                            ),
                        const Icon(Icons.arrow_forward_ios, size: 16, color: Colors.grey),
                      ],
                    ),
                  ),
                ),
              ],

              // State Instruksi Pembayaran (Pending / Approved / Expired Text)
              if (_paymentState == PaymentState.pending) ...[
                const Center(child: Text('Selesaikan Pembayaran Dalam Waktu', style: TextStyle(color: Colors.grey))),
                const SizedBox(height: 8),
                Center(child: Text('$hours : $minutes : $seconds', style: const TextStyle(fontSize: 28, fontWeight: FontWeight.bold, color: Colors.red))),
                const Divider(height: 32),
                const Text('Instruksi Pembayaran:', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                const SizedBox(height: 16),
                
                if (_vaNumber != null) ...[
                   Text('${_selectedPaymentMethod?.name ?? 'Virtual Account'}', style: const TextStyle(color: Colors.grey)),
                   Row(
                     mainAxisAlignment: MainAxisAlignment.spaceBetween,
                     children: [
                       Text('$_vaNumber', style: const TextStyle(fontSize: 22, fontWeight: FontWeight.bold)),
                       TextButton.icon(
                         onPressed: () => _copyToClipboard(_vaNumber!),
                         icon: const Icon(Icons.copy),
                         label: const Text('Salin'),
                       )
                     ],
                   )
                ],

                if (_qrCodeUrl != null) ...[
                  const Text('Scan QRIS berikut menggunakan aplikasi dompet digital Anda:'),
                  const SizedBox(height: 12),
                  Center(child: Image.network(_qrCodeUrl!, width: 200, height: 200)),
                ],

                const SizedBox(height: 20),
                SizedBox(
                  width: double.infinity,
                  child: OutlinedButton(
                    onPressed: _isLoading ? null : _checkPaymentStatus,
                    style: OutlinedButton.styleFrom(side: const BorderSide(color: Color(0xFFE65100))),
                    child: _isLoading 
                      ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator())
                      : const Text('Refresh Status Pembayaran', style: TextStyle(color: Color(0xFFE65100))),
                  ),
                )
              ],

              if (_paymentState == PaymentState.approved) ...[
                const Center(
                  child: Column(
                    children: [
                      Icon(Icons.check_circle, color: Colors.green, size: 64),
                      SizedBox(height: 12),
                      Text('Pembayaran Berhasil!', style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: Colors.green)),
                    ],
                  ),
                )
              ],

              if (_paymentState == PaymentState.expired) ...[
                 const Center(
                  child: Column(
                    children: [
                      Icon(Icons.cancel, color: Colors.red, size: 64),
                      SizedBox(height: 12),
                      Text('Waktu Pembayaran Habis / Dibatalkan', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.red)),
                      SizedBox(height: 8),
                      Text('Silakan pilih metode pembayaran kembali dan buat pesanan ulang.', textAlign: TextAlign.center),
                    ],
                  ),
                )
              ]

            ]),
          ),

          const SizedBox(height: 16),
          // Ringkasan Pesanan (Tetap tampil di semua state untuk review)
          Container(
            padding: const EdgeInsets.all(16), decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(16)),
            child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              const Text('Ringkasan Pesanan', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
              const SizedBox(height: 12),
              ...widget.cartItems.map(_summaryItem),
            ]),
          ),
            
          const SizedBox(height: 120),
        ]),
      ),

      // TOMBOL BAWAH BERDASARKAN STATE
      bottomSheet: Container(
        padding: const EdgeInsets.all(16), decoration: BoxDecoration(color: Colors.white, boxShadow: [BoxShadow(color: Colors.grey.withOpacity(0.1), blurRadius: 10, offset: const Offset(0, -5))]),
        child: SafeArea(
          child: Column(mainAxisSize: MainAxisSize.min, children: [
            Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
              const Text('Total Tagihan', style: TextStyle(color: Colors.grey, fontSize: 16)),
              Text('Rp ${grandTotal.toStringAsFixed(0)}', style: const TextStyle(fontSize: 22, fontWeight: FontWeight.w900, color: Color(0xFFE65100))),
            ]),
            const SizedBox(height: 12),
            SizedBox(
              width: double.infinity,
              child: _buildBottomButton(),
            ),
          ]),
        ),
      ),
    );
  }

  // Merender tampilan tombol berdasarkan State
  Widget _buildBottomButton() {
    switch (_paymentState) {
      case PaymentState.initial:
      case PaymentState.expired:
        return ElevatedButton(
          onPressed: _isLoading || _mainAddress == null || _selectedPaymentMethod == null ? null : _processCheckout,
          style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFFE65100), padding: const EdgeInsets.symmetric(vertical: 14)),
          child: _isLoading
              ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2))
              : const Text('BAYAR SEKARANG', style: TextStyle(fontSize: 16, color: Colors.white, fontWeight: FontWeight.bold)),
        );
      case PaymentState.pending:
        return ElevatedButton(
          onPressed: null, // Dikunci selama pending
          style: ElevatedButton.styleFrom(backgroundColor: Colors.grey.shade400, padding: const EdgeInsets.symmetric(vertical: 14)),
          child: const Text('MENUNGGU PEMBAYARAN...', style: TextStyle(fontSize: 16, color: Colors.white, fontWeight: FontWeight.bold)),
        );
      case PaymentState.approved:
        return ElevatedButton(
          onPressed: _goToConfirmation,
          style: ElevatedButton.styleFrom(backgroundColor: Colors.green, padding: const EdgeInsets.symmetric(vertical: 14)),
          child: const Text('SELESAIKAN PESANAN', style: TextStyle(fontSize: 16, color: Colors.white, fontWeight: FontWeight.bold)),
        );
    }
  }
}
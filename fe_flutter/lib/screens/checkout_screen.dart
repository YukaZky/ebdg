import 'package:flutter/material.dart';
import 'package:webview_flutter/webview_flutter.dart';
import '../services/api_service.dart';
import '../services/checkout_api_service.dart';
import 'order_confirmation_screen.dart';
import 'admin/address_list_screen.dart'; // Sesuaikan path ini jika AddressListScreen Anda berada di folder berbeda

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
  Map<String, dynamic>? _mainAddress;
  bool _isLoadingAddress = true;

  List _shippingOptions = [];
  String? _selectedCourier;
  String? _selectedService;

  double _shippingCost = 0;
  bool _isLoading = false;
  bool _isLoadingOngkir = false;

  final List<String> _couriers = ['jne', 'pos', 'tiki'];

  @override
  void initState() {
    super.initState();
    _fetchMainAddress();
  }

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
    
    // Ambil data alamat dari API
    final data = await ApiService.getUserAddresses();
    if (!mounted) return;

    Map<String, dynamic>? mainAddr;
    
    if (data != null && data is List && data.isNotEmpty) {
      try {
        // Cari alamat yang ditandai sebagai alamat utama
        mainAddr = data.firstWhere((a) => 
          a['isdefault'] == 1 || a['isdefault'] == '1' || a['isdefault'] == true ||
          a['is_main'] == 1 || a['is_main'] == '1' || a['is_main'] == true
        );
      } catch (e) {
        // Jika tidak ada yang ditandai, pakai alamat pertama yang ada di database
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

    // Jika kurir sudah pernah dipilih sebelumnya dan alamat berganti, hitung ulang ongkir
    if (_selectedCourier != null && _mainAddress != null) {
      _calculateShipping();
    }
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

  void _processCheckout() async {
    if (_mainAddress == null) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Harap atur alamat pengiriman terlebih dahulu!'), backgroundColor: Colors.red));
      return;
    }
    if (_shippingCost == 0 || _selectedService == null) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Pilih layanan kurir!'), backgroundColor: Colors.red));
      return;
    }

    setState(() => _isLoading = true);
    final courierWithService = '${_selectedCourier?.toUpperCase()} - $_selectedService';
    
    final addressString = _mainAddress!['address']?.toString() ?? _mainAddress!['detail_address']?.toString() ?? '-';
    final phoneString = _mainAddress!['phone']?.toString() ?? '-';
    final provinceName = _mainAddress!['province_name']?.toString() ?? 'Tidak Diketahui';
    final cityName = _mainAddress!['city_name']?.toString() ?? 'Tidak Diketahui';

    final responseData = await CheckoutApiService.checkout(
      address: addressString,
      phone: phoneString,
      provinceName: provinceName,
      cityName: cityName,
      courier: courierWithService,
      shippingCost: _shippingCost,
      cartItems: widget.cartItems,
    );

    if (!mounted) return;
    setState(() => _isLoading = false);

    if (responseData != null && responseData['success'] == true) {
      final paymentUrl = responseData['payment_url'];
      final orderData = responseData['order'];
      if (paymentUrl != null && orderData != null) _showPaymentPopup(paymentUrl, orderData);
    } else {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Gagal memproses pesanan ke server.'), backgroundColor: Colors.red));
    }
  }

  void _showPaymentPopup(String paymentUrl, Map<String, dynamic> orderData) {
    final controller = WebViewController()
      ..setJavaScriptMode(JavaScriptMode.unrestricted)
      ..setNavigationDelegate(
        NavigationDelegate(
          onPageFinished: (url) {
            if (url.contains('status_code=200') || url.contains('transaction_status=settlement') || url.contains('/finish') || url.contains('/success')) {
              Future.delayed(const Duration(seconds: 2), () {
                if (!mounted) return;
                Navigator.pop(context);
                _goToConfirmation(orderData);
              });
            }
          },
        ),
      )
      ..loadRequest(Uri.parse(paymentUrl));

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => Dialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        insetPadding: const EdgeInsets.all(16),
        child: SizedBox(
          height: MediaQuery.of(context).size.height * 0.75,
          child: Column(
            children: [
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                decoration: const BoxDecoration(
                  color: Color(0xFFE65100),
                  borderRadius: BorderRadius.only(topLeft: Radius.circular(16), topRight: Radius.circular(16)),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Text('Pembayaran Aman Midtrans', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
                    IconButton(
                      icon: const Icon(Icons.close, color: Colors.white),
                      onPressed: () {
                        Navigator.pop(context);
                        _goToConfirmation(orderData);
                      },
                    ),
                  ],
                ),
              ),
              Expanded(child: WebViewWidget(controller: controller)),
            ],
          ),
        ),
      ),
    );
  }

  void _goToConfirmation(Map<String, dynamic> orderData) {
    if (!mounted) return;
    Navigator.pushAndRemoveUntil(
      context,
      MaterialPageRoute(builder: (context) => OrderConfirmationScreen(order: orderData)),
      (route) => false,
    );
  }

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
            width: 50,
            height: 50,
            clipBehavior: Clip.antiAlias,
            decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(8), border: Border.all(color: Colors.grey.shade200)),
            child: image.isNotEmpty
                ? Image.network(image, fit: BoxFit.cover, errorBuilder: (_, __, ___) => const Icon(Icons.image_not_supported, color: Colors.grey, size: 24))
                : const Icon(Icons.image, color: Colors.grey, size: 24),
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

    return Scaffold(
      backgroundColor: const Color(0xFFF5F7FA),
      appBar: AppBar(title: const Text('Pengiriman & Checkout')),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          
          // 1. Bagian Alamat Otomatis
          if (_isLoadingAddress)
            const Center(child: Padding(
              padding: EdgeInsets.all(20.0),
              child: CircularProgressIndicator(color: Color(0xFFE65100)),
            ))
          else if (_mainAddress == null)
            InkWell(
              onTap: () {
                // Navigasi ke list alamat, lalu refresh data saat kembali
                Navigator.push(context, MaterialPageRoute(builder: (_) => const AddressListScreen())).then((_) => _fetchMainAddress());
              },
              child: Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.red.shade50, 
                  borderRadius: BorderRadius.circular(12), 
                  border: Border.all(color: Colors.red.shade200)
                ),
                child: const Row(
                  children: [
                    Icon(Icons.location_off, color: Colors.red),
                    SizedBox(width: 12),
                    Expanded(child: Text('Alamat belum diatur. Klik di sini untuk menambahkan alamat.', style: TextStyle(color: Colors.red, fontWeight: FontWeight.bold))),
                    Icon(Icons.arrow_forward_ios, size: 16, color: Colors.red)
                  ]
                )
              )
            )
          else
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(16), border: Border.all(color: Colors.grey.shade300)),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start, 
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text('Alamat Pengiriman', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                      InkWell(
                        onTap: () {
                          // Navigasi ke list alamat untuk ganti alamat utama
                          Navigator.push(context, MaterialPageRoute(builder: (_) => const AddressListScreen())).then((_) => _fetchMainAddress());
                        },
                        child: const Text('Ubah', style: TextStyle(color: Color(0xFFE65100), fontWeight: FontWeight.bold)),
                      )
                    ]
                  ),
                  const Divider(height: 24),
                  Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                        decoration: BoxDecoration(color: const Color(0xFFE65100).withOpacity(0.1), borderRadius: BorderRadius.circular(4)),
                        child: Text(_mainAddress!['label']?.toString() ?? 'Utama', style: const TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: Color(0xFFE65100))),
                      ),
                      const SizedBox(width: 8),
                      Text('${_mainAddress!['name']} | ${_mainAddress!['phone']}', style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 14)),
                    ],
                  ),
                  const SizedBox(height: 8),
                  Text('${_mainAddress!['address'] ?? _mainAddress!['detail_address']}', style: TextStyle(color: Colors.grey.shade700, fontSize: 13, height: 1.4)),
                  const SizedBox(height: 4),
                  Text('${_mainAddress!['city_name']}, ${_mainAddress!['province_name']} - ${_mainAddress!['postal_code']}', style: TextStyle(color: Colors.grey.shade700, fontSize: 13)),
                ]
              )
            ),

          const SizedBox(height: 16),

          // 2. Ringkasan Pesanan
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(16)),
            child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              const Text('Ringkasan Pesanan', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
              const SizedBox(height: 12),
              ...widget.cartItems.map(_summaryItem),
            ]),
          ),
          
          const SizedBox(height: 16),

          // 3. Kurir Pengiriman (Hanya tampil jika alamat sudah ada)
          if (_mainAddress != null)
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(16)),
              child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                const Text('Kurir Pengiriman', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                const SizedBox(height: 12),
                DropdownButtonFormField<String>(
                  decoration: const InputDecoration(labelText: 'Pilih Ekspedisi', border: OutlineInputBorder()),
                  value: _selectedCourier,
                  items: _couriers.map((c) => DropdownMenuItem(value: c, child: Text(c.toUpperCase()))).toList(),
                  onChanged: (value) {
                    setState(() => _selectedCourier = value);
                    _calculateShipping();
                  },
                ),
                const SizedBox(height: 16),
                if (_isLoadingOngkir)
                  const Center(child: CircularProgressIndicator())
                else if (_shippingOptions.isNotEmpty)
                  DropdownButtonFormField<String>(
                    isExpanded: true,
                    decoration: const InputDecoration(labelText: 'Pilih Layanan Pengiriman', border: OutlineInputBorder()),
                    value: _selectedService,
                    items: _shippingOptions.map<DropdownMenuItem<String>>((option) {
                      final service = option['service']?.toString() ?? 'Layanan';
                      final costList = option['cost'] as List?;
                      final costVal = (costList != null && costList.isNotEmpty) ? (costList[0]['value']?.toString() ?? '0') : '0';
                      final etd = (costList != null && costList.isNotEmpty) ? (costList[0]['etd']?.toString() ?? '') : '';
                      return DropdownMenuItem(value: service, child: Text('$service - Rp $costVal (${etd.isNotEmpty ? '$etd hari' : '-'})', overflow: TextOverflow.ellipsis));
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
                else if (_selectedCourier != null)
                  const Text('Tidak ada layanan kurir tersedia untuk rute ini.', style: TextStyle(color: Colors.red)),
              ]),
            ),
            
          const SizedBox(height: 120),
        ]),
      ),
      bottomSheet: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(color: Colors.white, boxShadow: [BoxShadow(color: Colors.grey.withOpacity(0.1), blurRadius: 10, offset: const Offset(0, -5))]),
        child: SafeArea(
          child: Column(mainAxisSize: MainAxisSize.min, children: [
            Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
              const Text('Total Pembayaran', style: TextStyle(color: Colors.grey, fontSize: 16)),
              Text('Rp ${grandTotal.toStringAsFixed(0)}', style: const TextStyle(fontSize: 22, fontWeight: FontWeight.w900, color: Color(0xFFE65100))),
            ]),
            const SizedBox(height: 12),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                // Tombol di-disable secara otomatis jika alamat kosong atau sedang loading
                onPressed: _isLoading || _mainAddress == null ? null : _processCheckout,
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFFE65100), 
                  disabledBackgroundColor: Colors.grey.shade300,
                  padding: const EdgeInsets.symmetric(vertical: 14)
                ),
                child: _isLoading
                    ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2))
                    : const Text('BAYAR SEKARANG', style: TextStyle(fontSize: 16, color: Colors.white, fontWeight: FontWeight.bold)),
              ),
            ),
          ]),
        ),
      ),
    );
  }
}
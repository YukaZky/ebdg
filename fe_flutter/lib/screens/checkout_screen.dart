import 'package:flutter/material.dart';
import 'package:webview_flutter/webview_flutter.dart';
import '../services/api_service.dart';
import '../services/checkout_api_service.dart';
import 'order_confirmation_screen.dart';

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
  final _addressController = TextEditingController();
  final _phoneController = TextEditingController();

  List _provinces = [];
  List _cities = [];
  List _shippingOptions = [];

  String? _selectedProvinceId;
  String? _selectedProvinceName;
  String? _selectedCityId;
  String? _selectedCityName;
  String? _selectedCourier;
  String? _selectedService;

  double _shippingCost = 0;
  bool _isLoading = false;
  bool _isLoadingOngkir = false;

  final List<String> _couriers = ['jne', 'pos', 'tiki'];

  @override
  void initState() {
    super.initState();
    _fetchProvinces();
  }

  @override
  void dispose() {
    _addressController.dispose();
    _phoneController.dispose();
    super.dispose();
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

  void _fetchProvinces() async {
    final data = await ApiService.getProvinces();
    if (!mounted) return;
    setState(() => _provinces = data);
  }

  void _fetchCities(String provinceId) async {
    setState(() {
      _selectedCityId = null;
      _cities = [];
      _shippingCost = 0;
      _shippingOptions = [];
      _selectedService = null;
    });
    final data = await ApiService.getCities(provinceId);
    if (!mounted) return;
    setState(() => _cities = data);
  }

  void _calculateShipping() async {
    if (_selectedCityId == null || _selectedCourier == null) return;
    setState(() {
      _isLoadingOngkir = true;
      _shippingCost = 0;
      _selectedService = null;
    });

    final data = await ApiService.checkCost(_selectedCityId!, widget.totalWeight.toInt(), _selectedCourier!);
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
    if (_addressController.text.isEmpty || _phoneController.text.isEmpty || _shippingCost == 0 || _selectedService == null) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Lengkapi semua data dan pilih layanan kurir!'), backgroundColor: Colors.red));
      return;
    }

    setState(() => _isLoading = true);
    final courierWithService = '${_selectedCourier?.toUpperCase()} - $_selectedService';

    final responseData = await CheckoutApiService.checkout(
      address: _addressController.text,
      phone: _phoneController.text,
      provinceName: _selectedProvinceName ?? 'Tidak Diketahui',
      cityName: _selectedCityName ?? 'Tidak Diketahui',
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
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(16)),
            child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              const Text('Alamat Penerima', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
              const SizedBox(height: 16),
              DropdownButtonFormField<String>(
                decoration: const InputDecoration(labelText: 'Pilih Provinsi', border: OutlineInputBorder()),
                value: _selectedProvinceId,
                items: _provinces.map<DropdownMenuItem<String>>((prov) {
                  final id = (prov['id'] ?? prov['province_id'])?.toString() ?? '';
                  final name = (prov['name'] ?? prov['province'])?.toString() ?? 'Tidak Diketahui';
                  return DropdownMenuItem(value: id, child: Text(name));
                }).toList(),
                onChanged: (value) {
                  setState(() {
                    _selectedProvinceId = value;
                    final selected = _provinces.firstWhere((p) => (p['id'] ?? p['province_id'])?.toString() == value);
                    _selectedProvinceName = (selected['name'] ?? selected['province'])?.toString() ?? 'Tidak Diketahui';
                  });
                  if (value != null) _fetchCities(value);
                },
              ),
              const SizedBox(height: 12),
              DropdownButtonFormField<String>(
                decoration: const InputDecoration(labelText: 'Pilih Kota/Kabupaten', border: OutlineInputBorder()),
                value: _selectedCityId,
                items: _cities.map<DropdownMenuItem<String>>((city) {
                  final id = (city['id'] ?? city['city_id'])?.toString() ?? '';
                  final name = city['name']?.toString() ?? '${city['type'] ?? ''} ${city['city_name'] ?? ''}'.trim();
                  return DropdownMenuItem(value: id, child: Text(name.isEmpty ? 'Tidak Diketahui' : name));
                }).toList(),
                onChanged: (value) {
                  setState(() {
                    _selectedCityId = value;
                    final selected = _cities.firstWhere((c) => (c['id'] ?? c['city_id'])?.toString() == value);
                    _selectedCityName = selected['name']?.toString() ?? '${selected['type'] ?? ''} ${selected['city_name'] ?? ''}'.trim();
                  });
                  _calculateShipping();
                },
              ),
              const SizedBox(height: 12),
              TextField(controller: _addressController, decoration: const InputDecoration(labelText: 'Detail Alamat', border: OutlineInputBorder()), maxLines: 2),
              const SizedBox(height: 12),
              TextField(controller: _phoneController, decoration: const InputDecoration(labelText: 'Nomor HP Aktif', border: OutlineInputBorder()), keyboardType: TextInputType.phone),
            ]),
          ),
          const SizedBox(height: 16),
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
                onPressed: _isLoading ? null : _processCheckout,
                style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFFE65100), padding: const EdgeInsets.symmetric(vertical: 14)),
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

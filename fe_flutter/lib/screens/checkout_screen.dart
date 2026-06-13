import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';
import '../services/api_service.dart';
import 'main_screen.dart';
import 'order_confirmation_screen.dart';
import 'package:webview_flutter/webview_flutter.dart';

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

  void _fetchProvinces() async {
    final data = await ApiService.getProvinces();
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
    setState(() => _cities = data);
  }

  void _calculateShipping() async {
    if (_selectedCityId == null || _selectedCourier == null) return;

    setState(() {
      _isLoadingOngkir = true;
      _shippingCost = 0;
      _selectedService = null;
    });

    final data = await ApiService.checkCost(
        _selectedCityId!, widget.totalWeight.toInt(), _selectedCourier!);

    setState(() {
      _isLoadingOngkir = false;
      _shippingOptions = data;
      if (data.isNotEmpty && data[0]['cost'].isNotEmpty) {
        _selectedService = data[0]['service']?.toString();
        _shippingCost =
            double.tryParse(data[0]['cost'][0]['value']?.toString() ?? '0') ??
                0;
      }
    });
  }

  void _processCheckout() async {
    if (_addressController.text.isEmpty ||
        _phoneController.text.isEmpty ||
        _shippingCost == 0 ||
        _selectedService == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
            content: Text("Lengkapi semua data dan pilih layanan kurir!"),
            backgroundColor: Colors.red),
      );
      return;
    }

    setState(() => _isLoading = true);

    String courierWithService =
        "${_selectedCourier?.toUpperCase()} - $_selectedService";

    // Panggil API service yang baru dengan menyertakan data widget.cartItems
    Map<String, dynamic>? responseData = await ApiService.checkout(
        _addressController.text,
        _phoneController.text,
        _selectedProvinceName ?? 'Tidak Diketahui',
        _selectedCityName ?? 'Tidak Diketahui',
        courierWithService,
        _shippingCost,
        widget.cartItems // Mengirim data item dari layar keranjang sebelumnya
        );

    setState(() => _isLoading = false);

    if (responseData != null && responseData['success'] == true) {
      String? paymentUrl = responseData['payment_url'];
      var orderData = responseData['order'];

      if (paymentUrl != null && mounted) {
        // 1. Cukup panggil fungsi popup ini saja.
        // Fungsi ini yang akan mengontrol kapan dialog ditutup dan kapan harus pindah halaman.
        _showPaymentPopup(paymentUrl, orderData);
      }
      
      // 2. BAGIAN Navigator.pushAndRemoveUntil DI SINI SUDAH DIHAPUS!
      
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
            content: Text("Gagal memproses pesanan ke server."),
            backgroundColor: Colors.red),
      );
    }
  }

  // --- KODE LENGKAP LANGKAH 2: POPUP DIALOG WEBVIEW ---
  void _showPaymentPopup(String paymentUrl, Map<String, dynamic> orderData) {
    // 1. Inisialisasi WebViewController bawaan webview_flutter v4+
    final WebViewController webController = WebViewController()
      ..setJavaScriptMode(JavaScriptMode.unrestricted) // Mengaktifkan JavaScript agar Midtrans berjalan lancar
      ..setBackgroundColor(const Color(0x00000000))
      ..setNavigationDelegate(
        NavigationDelegate(
          onPageFinished: (String url) {
            // DETEKSI OTOMATIS: Jika URL mengandung kata di bawah ini (biasanya halaman akhir Midtrans),
            // maka popup akan menutup sendiri secara otomatis.
            if (url.contains('status_code=200') || 
                url.contains('transaction_status=settlement') || 
                url.contains('/finish') || 
                url.contains('/success')) {
              
              // Beri jeda sedikit agar user bisa melihat status sukses di webview sebelum ditutup
              Future.delayed(const Duration(seconds: 2), () {
                if (mounted) {
                  Navigator.pop(context); // Menutup popup dialog webview
                  _navigateToConfirmation(orderData); // Pindah ke layar konfirmasi pesanan
                }
              });
            }
          },
        ),
      )
      ..loadRequest(Uri.parse(paymentUrl)); // Memuat URL Snap Midtrans

    // 2. Tampilkan Kotak Dialog (Popup Box) di Tengah Layar
    showDialog(
      context: context,
      barrierDismissible: false, // User tidak bisa menutup popup dengan menekan area luar demi keamanan transaksi
      builder: (BuildContext context) {
        return Dialog(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          insetPadding: const EdgeInsets.all(16), // Jarak popup ke tepi layar HP
          child: Container(
            width: MediaQuery.of(context).size.width,
            height: MediaQuery.of(context).size.height * 0.75, // Tinggi popup 75% dari layar
            child: Column(
              children: [
                // Bagian Header Popup
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                  decoration: const BoxDecoration(
                    color: Color(0xFFE65100), // Warna oranye menyesuaikan tema aplikasi Anda
                    borderRadius: BorderRadius.only(
                      topLeft: Radius.circular(16),
                      topRight: Radius.circular(16),
                    ),
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text(
                        "Pembayaran Aman Midtrans",
                        style: TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.bold,
                          fontSize: 16,
                        ),
                      ),
                      // Tombol Close (X) Manual jika user ingin keluar/menyelesaikan nanti
                      IconButton(
                        icon: const Icon(Icons.close, color: Colors.white),
                        onPressed: () {
                          Navigator.pop(context); // Tutup popup dialog
                          _navigateToConfirmation(orderData); // Tetap alihkan ke halaman konfirmasi
                        },
                      ),
                    ],
                  ),
                ),
                
                // Bagian Body WebView untuk memuat Snap Midtrans
                Expanded(
                  child: ClipRRect(
                    borderRadius: const BorderRadius.only(
                      bottomLeft: Radius.circular(16),
                      bottomRight: Radius.circular(16),
                    ),
                    child: WebViewWidget(controller: webController),
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  // Fungsi pembantu (helper) untuk mengalihkan navigasi ke halaman OrderConfirmationScreen
  void _navigateToConfirmation(Map<String, dynamic> orderData) {
    if (mounted) {
      Navigator.pushAndRemoveUntil(
        context,
        MaterialPageRoute(
          builder: (context) => OrderConfirmationScreen(order: orderData),
        ),
        (route) => false,
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    double grandTotal = widget.totalAmount + _shippingCost;

    return Scaffold(
      backgroundColor: const Color(0xFFF5F7FA),
      appBar: AppBar(title: const Text("Pengiriman & Checkout")),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // --- SECTION: RINGKASAN PESANAN ---
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                  color: Colors.white, borderRadius: BorderRadius.circular(16)),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text("Ringkasan Pesanan",
                      style:
                          TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                  const SizedBox(height: 12),
                  ...widget.cartItems.map((item) {
                    final product = item['product'];
                    final qty = int.tryParse(item['quantity'].toString()) ?? 1;
                    final price =
                        double.tryParse(product['regular_price'].toString()) ??
                            0;

                    return Padding(
                      padding: const EdgeInsets.only(bottom: 12.0),
                      child: Row(
                        children: [
                          // Gambar Produk
                          Container(
                            width: 50,
                            height: 50,
                            decoration: BoxDecoration(
                                color: Colors.white,
                                borderRadius: BorderRadius.circular(8),
                                border:
                                    Border.all(color: Colors.grey.shade200)),
                            child: ClipRRect(
                              borderRadius: BorderRadius.circular(8),
                              child: product['image'] != null
                                  ? Image.network(
                                      "http://192.168.1.6:8000/uploads/products/${product['image']}",
                                      fit: BoxFit.cover,
                                      errorBuilder: (_, __, ___) => const Icon(
                                          Icons.image_not_supported,
                                          color: Colors.grey,
                                          size: 24))
                                  : const Icon(Icons.image,
                                      color: Colors.grey, size: 24),
                            ),
                          ),
                          const SizedBox(width: 12),
                          // Detail Nama & Kuantitas
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(product['name'] ?? 'Produk',
                                    style: const TextStyle(
                                        fontWeight: FontWeight.w600,
                                        fontSize: 14),
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis),
                                const SizedBox(height: 4),
                                Text("$qty x Rp ${price.toStringAsFixed(0)}",
                                    style: TextStyle(
                                        color: Colors.grey[600], fontSize: 12)),
                              ],
                            ),
                          ),
                          // Subtotal Harga
                          Text("Rp ${(price * qty).toStringAsFixed(0)}",
                              style: const TextStyle(
                                  fontWeight: FontWeight.bold, fontSize: 14)),
                        ],
                      ),
                    );
                  }).toList(),
                ],
              ),
            ),
            const SizedBox(height: 16),

            // --- SECTION: ALAMAT PENERIMA ---
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                  color: Colors.white, borderRadius: BorderRadius.circular(16)),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text("Alamat Penerima",
                      style:
                          TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                  const SizedBox(height: 16),

                  // DROPDOWN PROVINSI
                  DropdownButtonFormField<String>(
                    decoration: const InputDecoration(
                        labelText: "Pilih Provinsi",
                        border: OutlineInputBorder()),
                    value: _selectedProvinceId,
                    items: _provinces.map<DropdownMenuItem<String>>((prov) {
                      final id =
                          (prov['id'] ?? prov['province_id'])?.toString() ?? '';
                      final name =
                          (prov['name'] ?? prov['province'])?.toString() ??
                              'Tidak Diketahui';
                      return DropdownMenuItem<String>(
                        value: id,
                        child: Text(name),
                      );
                    }).toList(),
                    onChanged: (value) {
                      setState(() {
                        _selectedProvinceId = value;
                        final selected = _provinces.firstWhere((p) =>
                            (p['id'] ?? p['province_id'])?.toString() == value);
                        _selectedProvinceName =
                            (selected['name'] ?? selected['province'])
                                    ?.toString() ??
                                'Tidak Diketahui';
                      });
                      if (value != null) _fetchCities(value);
                    },
                  ),
                  const SizedBox(height: 12),

                  // DROPDOWN KOTA
                  DropdownButtonFormField<String>(
                    decoration: const InputDecoration(
                        labelText: "Pilih Kota/Kabupaten",
                        border: OutlineInputBorder()),
                    value: _selectedCityId,
                    items: _cities.map<DropdownMenuItem<String>>((city) {
                      final id =
                          (city['id'] ?? city['city_id'])?.toString() ?? '';
                      String cityName = city['name']?.toString() ??
                          "${city['type'] ?? ''} ${city['city_name'] ?? ''}"
                              .trim();
                      if (cityName.isEmpty) cityName = 'Tidak Diketahui';
                      return DropdownMenuItem<String>(
                        value: id,
                        child: Text(cityName),
                      );
                    }).toList(),
                    onChanged: (value) {
                      setState(() {
                        _selectedCityId = value;
                        final selected = _cities.firstWhere((c) =>
                            (c['id'] ?? c['city_id'])?.toString() == value);
                        _selectedCityName = selected['name']?.toString() ??
                            "${selected['type'] ?? ''} ${selected['city_name'] ?? ''}"
                                .trim();
                      });
                      _calculateShipping();
                    },
                  ),
                  const SizedBox(height: 12),

                  TextField(
                    controller: _addressController,
                    decoration: const InputDecoration(
                        labelText: "Detail Alamat (Jalan, RT/RW)",
                        border: OutlineInputBorder()),
                    maxLines: 2,
                  ),
                  const SizedBox(height: 12),
                  TextField(
                    controller: _phoneController,
                    decoration: const InputDecoration(
                        labelText: "Nomor HP Aktif",
                        border: OutlineInputBorder()),
                    keyboardType: TextInputType.phone,
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),

            // --- SECTION: EKSPEDISI ---
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                  color: Colors.white, borderRadius: BorderRadius.circular(16)),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text("Kurir Pengiriman",
                      style:
                          TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                  const SizedBox(height: 12),
                  DropdownButtonFormField<String>(
                    decoration: const InputDecoration(
                        labelText: "Pilih Ekspedisi",
                        border: OutlineInputBorder()),
                    value: _selectedCourier,
                    items: _couriers
                        .map((c) => DropdownMenuItem(
                            value: c, child: Text(c.toUpperCase())))
                        .toList(),
                    onChanged: (value) {
                      setState(() => _selectedCourier = value);
                      _calculateShipping();
                    },
                  ),
                  const SizedBox(height: 16),
                  if (_isLoadingOngkir)
                    const Center(child: CircularProgressIndicator())
                  else if (_shippingOptions.isNotEmpty)
                    // DROPDOWN LAYANAN ONGKIR
                    // DROPDOWN LAYANAN ONGKIR
                    DropdownButtonFormField<String>(
                      isExpanded: true, // <-- Pastikan ini bernilai true agar teks bisa dipotong
                      decoration: const InputDecoration(labelText: "Pilih Layanan Pengiriman", border: OutlineInputBorder()),
                      value: _selectedService,
                      items: _shippingOptions.map<DropdownMenuItem<String>>((option) {
                        final service = option['service']?.toString() ?? 'Layanan';
                        // Safety check untuk list cost
                        final costList = option['cost'] as List?;
                        final costVal = (costList != null && costList.isNotEmpty) ? (costList[0]['value']?.toString() ?? '0') : '0';
                        final etd = (costList != null && costList.isNotEmpty) ? (costList[0]['etd']?.toString() ?? '') : '';
                        
                        return DropdownMenuItem<String>(
                          value: service,
                          child: Text(
                            "$service - Rp $costVal (${etd.isNotEmpty ? '$etd hari' : '-'})",
                            overflow: TextOverflow.ellipsis, // <-- Berada di dalam Text
                            maxLines: 1,                     // <-- Berada di dalam Text
                          ),
                        );
                      }).toList(),
                      onChanged: (value) {
                        setState(() {
                          _selectedService = value;
                          final selectedOption = _shippingOptions.firstWhere((opt) => opt['service']?.toString() == value);
                          final costList = selectedOption['cost'] as List?;
                          _shippingCost = double.tryParse((costList != null && costList.isNotEmpty) ? costList[0]['value']?.toString() ?? '0' : '0') ?? 0;
                        });
                      },
                    )else if (_selectedCourier != null && !_isLoadingOngkir)
                    const Text(
                        "Tidak ada layanan kurir tersedia untuk rute ini.",
                        style: TextStyle(color: Colors.red))
                ],
              ),
            ),
            const SizedBox(height: 100),
          ],
        ),
      ),
      bottomSheet: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.white,
          boxShadow: [
            BoxShadow(
                color: Colors.grey.withOpacity(0.1),
                blurRadius: 10,
                offset: const Offset(0, -5))
          ],
        ),
        child: SafeArea(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text("Total Pembayaran",
                      style: TextStyle(color: Colors.grey, fontSize: 16)),
                  Text("Rp ${grandTotal.toStringAsFixed(0)}",
                      style: const TextStyle(
                          fontSize: 22,
                          fontWeight: FontWeight.w900,
                          color: Color(0xFFE65100))),
                ],
              ),
              const SizedBox(height: 12),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: _isLoading ? null : _processCheckout,
                  style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFFE65100),
                      padding: const EdgeInsets.symmetric(vertical: 14)),
                  child: _isLoading
                      ? const SizedBox(
                          width: 20,
                          height: 20,
                          child: CircularProgressIndicator(
                              color: Colors.white, strokeWidth: 2))
                      : const Text("BAYAR SEKARANG",
                          style: TextStyle(
                              fontSize: 16,
                              color: Colors.white,
                              fontWeight: FontWeight.bold)),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';
import '../services/api_service.dart';
import 'main_screen.dart';

class CheckoutScreen extends StatefulWidget {
  final double totalAmount;
  const CheckoutScreen({Key? key, required this.totalAmount}) : super(key: key);

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
    });
    final data = await ApiService.getCities(provinceId);
    setState(() => _cities = data);
  }

  void _calculateShipping() async {
    if (_selectedCityId == null || _selectedCourier == null) return;
    
    setState(() {
      _isLoadingOngkir = true;
      _shippingCost = 0;
    });

    // Asumsi berat total adalah 1000 gram (1 Kg). Bisa disesuaikan dengan total berat keranjang Anda
    final data = await ApiService.checkCost(_selectedCityId!, 1000, _selectedCourier!);
    
    setState(() {
      _isLoadingOngkir = false;
      _shippingOptions = data;
      // Mengambil tarif pertama (Reguler) secara otomatis jika ada
      if (data.isNotEmpty && data[0]['cost'].isNotEmpty) {
        _shippingCost = double.parse(data[0]['cost'][0]['value'].toString());
      }
    });
  }

  void _processCheckout() async {
    if (_addressController.text.isEmpty || _phoneController.text.isEmpty || _shippingCost == 0) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Lengkapi semua data dan pilih kurir!"), backgroundColor: Colors.red),
      );
      return;
    }

    setState(() => _isLoading = true);

    String? paymentUrl = await ApiService.checkout(
      _addressController.text,
      _phoneController.text,
      _selectedProvinceName ?? '',
      _selectedCityName ?? '',
      _selectedCourier?.toUpperCase() ?? '',
      _shippingCost
    );

    setState(() => _isLoading = false);

    if (paymentUrl != null) {
      final Uri url = Uri.parse(paymentUrl);
      if (!await launchUrl(url, mode: LaunchMode.externalApplication)) {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("Gagal membuka pembayaran")));
      } else {
        if (mounted) {
          Navigator.pushAndRemoveUntil(
            context, MaterialPageRoute(builder: (context) => const MainScreen()), (route) => false,
          );
        }
      }
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
            // Section: Alamat
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(16)),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text("Alamat Penerima", style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                  const SizedBox(height: 16),
                  DropdownButtonFormField<String>(
                    decoration: const InputDecoration(labelText: "Pilih Provinsi"),
                    value: _selectedProvinceId,
                    items: _provinces.map<DropdownMenuItem<String>>((prov) {
                      return DropdownMenuItem<String>(
                        value: prov['province_id'],
                        child: Text(prov['province']),
                      );
                    }).toList(),
                    onChanged: (value) {
                      setState(() {
                        _selectedProvinceId = value;
                        _selectedProvinceName = _provinces.firstWhere((p) => p['province_id'] == value)['province'];
                      });
                      _fetchCities(value!);
                    },
                  ),
                  const SizedBox(height: 12),
                  DropdownButtonFormField<String>(
                    decoration: const InputDecoration(labelText: "Pilih Kota/Kabupaten"),
                    value: _selectedCityId,
                    items: _cities.map<DropdownMenuItem<String>>((city) {
                      return DropdownMenuItem<String>(
                        value: city['city_id'],
                        child: Text("${city['type']} ${city['city_name']}"),
                      );
                    }).toList(),
                    onChanged: (value) {
                      setState(() {
                        _selectedCityId = value;
                        _selectedCityName = _cities.firstWhere((c) => c['city_id'] == value)['city_name'];
                      });
                      _calculateShipping();
                    },
                  ),
                  const SizedBox(height: 12),
                  TextField(
                    controller: _addressController,
                    decoration: const InputDecoration(labelText: "Detail Alamat (Jalan, RT/RW)"),
                    maxLines: 2,
                  ),
                  const SizedBox(height: 12),
                  TextField(
                    controller: _phoneController,
                    decoration: const InputDecoration(labelText: "Nomor HP"),
                    keyboardType: TextInputType.phone,
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),

            // Section: Ekspedisi
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(16)),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text("Kurir Pengiriman", style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                  const SizedBox(height: 12),
                  DropdownButtonFormField<String>(
                    decoration: const InputDecoration(labelText: "Pilih Kurir"),
                    value: _selectedCourier,
                    items: _couriers.map((c) => DropdownMenuItem(value: c, child: Text(c.toUpperCase()))).toList(),
                    onChanged: (value) {
                      setState(() => _selectedCourier = value);
                      _calculateShipping();
                    },
                  ),
                  const SizedBox(height: 12),
                  if (_isLoadingOngkir)
                    const Center(child: CircularProgressIndicator())
                  else if (_shippingCost > 0)
                    Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(color: Colors.blue.shade50, borderRadius: BorderRadius.circular(8)),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text("Ongkos Kirim (${_shippingOptions[0]['service']})", style: const TextStyle(fontWeight: FontWeight.bold)),
                          Text("Rp ${_shippingCost.toStringAsFixed(0)}", style: const TextStyle(fontWeight: FontWeight.bold, color: Colors.blue)),
                        ],
                      ),
                    )
                ],
              ),
            ),
            const SizedBox(height: 100), // Space for bottom bar
          ],
        ),
      ),
      bottomSheet: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.white,
          boxShadow: [BoxShadow(color: Colors.grey.withOpacity(0.1), blurRadius: 10, offset: const Offset(0, -5))],
        ),
        child: SafeArea(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text("Total Pembayaran", style: TextStyle(color: Colors.grey, fontSize: 16)),
                  Text("Rp ${grandTotal.toStringAsFixed(0)}", 
                      style: const TextStyle(fontSize: 22, fontWeight: FontWeight.w900, color: Color(0xFFE65100))),
                ],
              ),
              const SizedBox(height: 12),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: _isLoading ? null : _processCheckout,
                  style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFFE65100)),
                  child: _isLoading 
                      ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(color: Colors.white))
                      : const Text("BAYAR SEKARANG", style: TextStyle(fontSize: 16)),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
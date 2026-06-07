import 'package:flutter/material.dart';
import '../../services/api_service.dart';

class AdminStoreLocationScreen extends StatefulWidget {
  const AdminStoreLocationScreen({Key? key}) : super(key: key);

  @override
  State<AdminStoreLocationScreen> createState() => _AdminStoreLocationScreenState();
}

class _AdminStoreLocationScreenState extends State<AdminStoreLocationScreen> {
  List _provinces = [];
  List _cities = [];

  String? _selectedProvinceId;
  String? _selectedCityId;
  bool _isLoading = false;
  bool _isSaving = false;

  @override
  void initState() {
    super.initState();
    _loadInitialData();
  }

  void _loadInitialData() async {
    setState(() => _isLoading = true);
    
    // 1. Ambil data provinsi rajaongkir
    final provData = await ApiService.getProvinces();
    setState(() {
      _provinces = provData;
    });

    // 2. Ambil data origin toko yang sudah tersimpan di database
    final storeData = await ApiService.getAdminStoreLocation();
    
    if (storeData != null && storeData['province_id'] != null) {
      String fetchedProvId = storeData['province_id'].toString();
      
      // Pastikan ID provinsi dari database benar-benar ada di list API
      bool provExists = _provinces.any((p) => p['province_id']?.toString() == fetchedProvId);
      
      if (provExists) {
         _selectedProvinceId = fetchedProvId;
         await _fetchCities(_selectedProvinceId!); // Panggil API Kota
         
         if (storeData['city_id'] != null) {
            String fetchedCityId = storeData['city_id'].toString();
            
            // Pastikan ID kota dari database benar-benar ada di list API
            bool cityExists = _cities.any((c) => c['city_id']?.toString() == fetchedCityId);
            
            if (cityExists) {
              setState(() {
                 _selectedCityId = fetchedCityId;
              });
            }
         }
      }
    }
    
    setState(() => _isLoading = false);
  }

  Future<void> _fetchCities(String provinceId) async {
    final data = await ApiService.getCities(provinceId);
    setState(() {
      _cities = data;
    });
  }

  void _saveLocation() async {
    if (_selectedProvinceId == null || _selectedCityId == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Pilih Provinsi dan Kota terlebih dahulu!")),
      );
      return;
    }

    setState(() => _isSaving = true);
    bool success = await ApiService.saveAdminStoreLocation(_selectedProvinceId!, _selectedCityId!);
    setState(() => _isSaving = false);

    if (success) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Lokasi Toko berhasil disimpan!", style: TextStyle(color: Colors.white)), backgroundColor: Colors.green),
      );
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Gagal menyimpan lokasi toko.", style: TextStyle(color: Colors.white)), backgroundColor: Colors.red),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("Manajemen Lokasi Toko")),
      body: _isLoading 
        ? const Center(child: CircularProgressIndicator())
        : Padding(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text("Tentukan Lokasi Pengiriman (Origin)", style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                const SizedBox(height: 8),
                const Text(
                  "Lokasi ini akan digunakan oleh RajaOngkir untuk menghitung ongkos kirim ke pembeli.", 
                  style: TextStyle(color: Colors.grey)
                ),
                const SizedBox(height: 24),
                
                DropdownButtonFormField<String>(
                  decoration: const InputDecoration(labelText: "Provinsi Asal Toko", border: OutlineInputBorder()),
                  value: _selectedProvinceId,
                  items: _provinces.map<DropdownMenuItem<String>>((prov) {
                    return DropdownMenuItem<String>(
                      // Mencegah error Null dengan aman
                      value: prov['province_id']?.toString() ?? '',
                      child: Text(prov['province']?.toString() ?? 'Tidak Diketahui'),
                    );
                  }).toList(),
                  onChanged: (value) {
                    setState(() {
                      _selectedProvinceId = value;
                      _selectedCityId = null; // Reset kota jika provinsi diganti
                      _cities = [];
                    });
                    // Pastikan value tidak kosong sebelum mengambil data kota
                    if (value != null && value.isNotEmpty) _fetchCities(value);
                  },
                ),
                const SizedBox(height: 16),
                
                DropdownButtonFormField<String>(
                  decoration: const InputDecoration(labelText: "Kota/Kabupaten Asal Toko", border: OutlineInputBorder()),
                  value: _selectedCityId,
                  items: _cities.map<DropdownMenuItem<String>>((city) {
                    return DropdownMenuItem<String>(
                      // Mencegah error Null dengan aman
                      value: city['city_id']?.toString() ?? '',
                      child: Text("${city['type'] ?? ''} ${city['city_name'] ?? 'Tidak Diketahui'}".trim()),
                    );
                  }).toList(),
                  onChanged: (value) {
                    setState(() {
                      _selectedCityId = value;
                    });
                  },
                ),
                const SizedBox(height: 32),
                
                SizedBox(
                  width: double.infinity,
                  height: 50,
                  child: ElevatedButton(
                    onPressed: _isSaving ? null : _saveLocation,
                    style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFFE65100)),
                    child: _isSaving
                        ? const CircularProgressIndicator(color: Colors.white)
                        : const Text("SIMPAN LOKASI TOKO", style: TextStyle(fontSize: 16, color: Colors.white, fontWeight: FontWeight.bold)),
                  ),
                )
              ],
            ),
          ),
    );
  }
}
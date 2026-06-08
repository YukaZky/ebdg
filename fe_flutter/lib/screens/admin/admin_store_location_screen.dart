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
    
    // 1. Ambil data provinsi
    final provData = await ApiService.getProvinces();
    setState(() {
      _provinces = provData;
    });

    // 2. Ambil respon origin toko dari API
    final responseData = await ApiService.getAdminStoreLocation();
    
    // Mengekstrak isi dari key 'data' jika API Laravel membungkusnya
    Map<String, dynamic>? storeData;
    if (responseData != null) {
      if (responseData.containsKey('data')) {
        storeData = responseData['data']; // Mengambil object di dalam "data"
      } else {
        storeData = responseData;
      }
    }
    
    // Cek apakah datanya benar-benar ada
    if (storeData != null && storeData['province_id'] != null) {
      String fetchedProvId = storeData['province_id'].toString();
      
      // Mengakomodasi key 'id' atau 'province_id'
      bool provExists = _provinces.any((p) => (p['id'] ?? p['province_id'])?.toString() == fetchedProvId);
      
      if (provExists) {
         // Pastikan masuk ke dalam setState
         setState(() {
           _selectedProvinceId = fetchedProvId;
         });
         
         await _fetchCities(_selectedProvinceId!); // Ambil list kota berdasarkan provinsi
         
         if (storeData['city_id'] != null) {
            String fetchedCityId = storeData['city_id'].toString();
            
            // Mengakomodasi key 'id' atau 'city_id'
            bool cityExists = _cities.any((c) => (c['id'] ?? c['city_id'])?.toString() == fetchedCityId);
            
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

  List<DropdownMenuItem<String>> _buildProvinceItems() {
    final seen = <String>{};
    return _provinces.where((prov) {
      final id = (prov['id'] ?? prov['province_id'])?.toString() ?? '';
      if (id.isEmpty || seen.contains(id)) return false;
      seen.add(id);
      return true;
    }).map<DropdownMenuItem<String>>((prov) {
      final id = (prov['id'] ?? prov['province_id']).toString();
      final name = (prov['name'] ?? prov['province'])?.toString() ?? 'Tidak Diketahui';
      
      return DropdownMenuItem<String>(
        value: id,
        child: Text(name),
      );
    }).toList();
  }

  List<DropdownMenuItem<String>> _buildCityItems() {
    final seen = <String>{};
    return _cities.where((city) {
      final id = (city['id'] ?? city['city_id'])?.toString() ?? '';
      if (id.isEmpty || seen.contains(id)) return false;
      seen.add(id);
      return true;
    }).map<DropdownMenuItem<String>>((city) {
      final id = (city['id'] ?? city['city_id']).toString();
      
      String cityName = city['name']?.toString() ?? "${city['type'] ?? ''} ${city['city_name'] ?? ''}".trim();
      if (cityName.isEmpty) cityName = 'Tidak Diketahui';

      return DropdownMenuItem<String>(
        value: id,
        child: Text(cityName),
      );
    }).toList();
  }

  @override
  Widget build(BuildContext context) {
    // Validasi value sesuai dengan data yang sudah di-mapping
    final validProvinceId = _selectedProvinceId != null && 
                            _provinces.any((p) => (p['id'] ?? p['province_id'])?.toString() == _selectedProvinceId) 
                            ? _selectedProvinceId : null;

    final validCityId = _selectedCityId != null && 
                        _cities.any((c) => (c['id'] ?? c['city_id'])?.toString() == _selectedCityId) 
                        ? _selectedCityId : null;

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
                  value: validProvinceId,
                  items: _buildProvinceItems(),
                  onChanged: (value) {
                    setState(() {
                      _selectedProvinceId = value;
                      _selectedCityId = null; 
                      _cities = [];
                    });
                    if (value != null && value.isNotEmpty) _fetchCities(value);
                  },
                ),
                const SizedBox(height: 16),
                
                DropdownButtonFormField<String>(
                  decoration: const InputDecoration(labelText: "Kota/Kabupaten Asal Toko", border: OutlineInputBorder()),
                  value: validCityId,
                  items: _buildCityItems(),
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
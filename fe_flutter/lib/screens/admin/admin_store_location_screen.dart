import 'package:flutter/material.dart';
import '../../services/api_service.dart';

class AdminStoreLocationScreen extends StatefulWidget {
  const AdminStoreLocationScreen({Key? key}) : super(key: key);

  @override
  State<AdminStoreLocationScreen> createState() => _AdminStoreLocationScreenState();
}

class _AdminStoreLocationScreenState extends State<AdminStoreLocationScreen> {
  // State API RajaOngkir
  List _provinces = [];
  List _cities = [];
  String? _selectedProvinceId;
  String? _selectedCityId;
  bool _isLoading = false;
  bool _isSaving = false;

  // Controller untuk Field Lengkap (UI Form)
  final TextEditingController _nameController = TextEditingController();
  final TextEditingController _phoneController = TextEditingController();
  final TextEditingController _kecamatanController = TextEditingController();
  final TextEditingController _postalCodeController = TextEditingController();
  final TextEditingController _detailAddressController = TextEditingController();
  final TextEditingController _noteController = TextEditingController();

  // State Pengaturan Alamat (UI Form)
  String _addressLabel = 'Rumah';
  bool _isMainAddress = true;

  @override
  void initState() {
    super.initState();
    _loadInitialData();
  }

  // LOGIKA AMAN: Pemuatan data dengan validasi
  void _loadInitialData() async {
    setState(() => _isLoading = true);
    
    // 1. Ambil data provinsi
    final provData = await ApiService.getProvinces();
    if (mounted) {
      setState(() {
        _provinces = provData;
      });
    }

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
    if (storeData != null && storeData['province_id'] != null && mounted) {
      String fetchedProvId = storeData['province_id'].toString();
      
      // Mengakomodasi key 'id' atau 'province_id'
      bool provExists = _provinces.any((p) => (p['id'] ?? p['province_id'])?.toString() == fetchedProvId);
      
      if (provExists) {
         setState(() {
           _selectedProvinceId = fetchedProvId;
         });
         
         await _fetchCities(_selectedProvinceId!); 
         
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
    
    if (mounted) {
      setState(() => _isLoading = false);
    }
  }

  Future<void> _fetchCities(String provinceId) async {
    final data = await ApiService.getCities(provinceId);
    if (mounted) {
      setState(() {
        _cities = data;
      });
    }
  }

  void _saveLocation() async {
    if (_selectedProvinceId == null || _selectedCityId == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Pilih Provinsi dan Kota terlebih dahulu!"), backgroundColor: Colors.redAccent),
      );
      return;
    }

    setState(() => _isSaving = true);
    bool success = await ApiService.saveAdminStoreLocation(_selectedProvinceId!, _selectedCityId!);
    if (!mounted) return;
    setState(() => _isSaving = false);

    if (success) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Lokasi Toko berhasil disimpan!", style: TextStyle(color: Colors.white)), backgroundColor: Colors.green),
      );
      Navigator.pop(context); // Kembali ke halaman sebelumnya jika sukses
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Gagal menyimpan lokasi toko.", style: TextStyle(color: Colors.white)), backgroundColor: Colors.red),
      );
    }
  }

  // LOGIKA AMAN: Mencegah duplikat item pada dropdown Provinsi
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
        child: Text(name, style: const TextStyle(fontSize: 14)),
      );
    }).toList();
  }

  // LOGIKA AMAN: Mencegah duplikat item pada dropdown Kota
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
        child: Text(cityName, style: const TextStyle(fontSize: 14)),
      );
    }).toList();
  }

  @override
  Widget build(BuildContext context) {
    // LOGIKA AMAN: Validasi value sesuai dengan data yang sudah di-mapping
    final validProvinceId = _selectedProvinceId != null && 
                            _provinces.any((p) => (p['id'] ?? p['province_id'])?.toString() == _selectedProvinceId) 
                            ? _selectedProvinceId : null;

    final validCityId = _selectedCityId != null && 
                        _cities.any((c) => (c['id'] ?? c['city_id'])?.toString() == _selectedCityId) 
                        ? _selectedCityId : null;

    return Scaffold(
      backgroundColor: const Color(0xFFF5F7FA), // Warna background
      appBar: AppBar(
        title: const Text('Detail Alamat', style: TextStyle(color: Colors.black87, fontWeight: FontWeight.bold, fontSize: 16)),
        backgroundColor: Colors.white,
        elevation: 0.5,
        iconTheme: const IconThemeData(color: Colors.black87),
        centerTitle: true,
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator(color: Color(0xFF0C2442)))
          : SingleChildScrollView(
              child: Column(
                children: [
                  _buildSectionContainer(
                    title: 'Info Kontak',
                    children: [
                      _buildTextField('Nama Lengkap', _nameController, icon: Icons.person_outline),
                      _buildTextField('Nomor Telepon', _phoneController, isNumber: true, icon: Icons.phone_outlined),
                    ],
                  ),
                  _buildSectionContainer(
                    title: 'Lokasi Lengkap',
                    children: [
                      _buildMapPin(), // UI Dummy Peta
                      
                      // UI DROPDOWN PROVINSI DENGAN DATA AMAN
                      Padding(
                        padding: const EdgeInsets.only(bottom: 16.0),
                        child: DropdownButtonFormField<String>(
                          isExpanded: true,
                          icon: const Icon(Icons.keyboard_arrow_down_rounded, color: Colors.grey),
                          decoration: InputDecoration(
                            labelText: 'Provinsi',
                            labelStyle: TextStyle(color: Colors.grey.shade600, fontSize: 13),
                            filled: true,
                            fillColor: Colors.grey.shade50,
                            border: OutlineInputBorder(borderRadius: BorderRadius.circular(8), borderSide: BorderSide(color: Colors.grey.shade300)),
                            enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(8), borderSide: BorderSide(color: Colors.grey.shade300)),
                            focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(8), borderSide: const BorderSide(color: Color(0xFFF39C12))),
                            contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                          ),
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
                      ),
                      
                      // UI DROPDOWN KOTA DENGAN DATA AMAN
                      Padding(
                        padding: const EdgeInsets.only(bottom: 16.0),
                        child: DropdownButtonFormField<String>(
                          isExpanded: true,
                          icon: const Icon(Icons.keyboard_arrow_down_rounded, color: Colors.grey),
                          decoration: InputDecoration(
                            labelText: 'Kota / Kabupaten',
                            labelStyle: TextStyle(color: Colors.grey.shade600, fontSize: 13),
                            filled: true,
                            fillColor: Colors.grey.shade50,
                            border: OutlineInputBorder(borderRadius: BorderRadius.circular(8), borderSide: BorderSide(color: Colors.grey.shade300)),
                            enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(8), borderSide: BorderSide(color: Colors.grey.shade300)),
                            focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(8), borderSide: const BorderSide(color: Color(0xFFF39C12))),
                            contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                          ),
                          value: validCityId,
                          items: _buildCityItems(),
                          onChanged: (value) {
                            setState(() {
                              _selectedCityId = value;
                            });
                          },
                        ),
                      ),
                      
                      _buildTextField('Kecamatan', _kecamatanController),
                      _buildTextField('Kode Pos', _postalCodeController, isNumber: true),
                      _buildTextField('Detail Alamat (Jalan, Gedung, No. Rumah)', _detailAddressController, maxLines: 3),
                      _buildTextField('Catatan untuk Kurir (Opsional)', _noteController),
                    ],
                  ),
                  _buildSectionContainer(
                    title: 'Pengaturan',
                    children: [
                      _buildLabelSelector(),
                      const Divider(height: 32),
                      SwitchListTile(
                        contentPadding: EdgeInsets.zero,
                        activeColor: const Color(0xFFF39C12),
                        title: const Text('Jadikan Alamat Utama', style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600)),
                        subtitle: const Text('Alamat ini akan otomatis terpilih saat checkout.', style: TextStyle(fontSize: 12, color: Colors.grey)),
                        value: _isMainAddress,
                        onChanged: (val) => setState(() => _isMainAddress = val),
                      ),
                    ],
                  ),
                  const SizedBox(height: 24),
                ],
              ),
            ),
      bottomNavigationBar: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        decoration: BoxDecoration(
          color: Colors.white,
          boxShadow: [BoxShadow(color: Colors.grey.withOpacity(0.2), blurRadius: 10, offset: const Offset(0, -5))],
        ),
        child: SafeArea(
          child: SizedBox(
            height: 48,
            child: ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF0C2442), 
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
              ),
              onPressed: _isLoading || _isSaving ? null : _saveLocation,
              child: _isSaving 
                ? const SizedBox(height: 24, width: 24, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2.5))
                : const Text('SIMPAN ALAMAT', style: TextStyle(color: Colors.white, fontSize: 14, fontWeight: FontWeight.bold, letterSpacing: 1.2)),
            ),
          ),
        ),
      ),
    );
  }

  // --- KOMPONEN UI ---

  Widget _buildSectionContainer({required String title, required List<Widget> children}) {
    return Container(
      width: double.infinity,
      margin: const EdgeInsets.only(top: 12),
      padding: const EdgeInsets.all(16),
      color: Colors.white,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(title, style: const TextStyle(fontSize: 15, fontWeight: FontWeight.bold, color: Colors.black87)),
          const SizedBox(height: 16),
          ...children,
        ],
      ),
    );
  }

  Widget _buildTextField(String label, TextEditingController controller, {bool isNumber = false, int maxLines = 1, IconData? icon}) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 16.0),
      child: TextFormField(
        controller: controller,
        keyboardType: isNumber ? TextInputType.phone : TextInputType.text,
        maxLines: maxLines,
        style: const TextStyle(fontSize: 14),
        decoration: InputDecoration(
          labelText: label,
          labelStyle: TextStyle(color: Colors.grey.shade600, fontSize: 13),
          prefixIcon: icon != null ? Icon(icon, size: 20, color: Colors.grey.shade600) : null,
          filled: true,
          fillColor: Colors.grey.shade50,
          border: OutlineInputBorder(borderRadius: BorderRadius.circular(8), borderSide: BorderSide(color: Colors.grey.shade300)),
          enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(8), borderSide: BorderSide(color: Colors.grey.shade300)),
          focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(8), borderSide: const BorderSide(color: Color(0xFFF39C12), width: 1.5)),
          contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        ),
      ),
    );
  }

  Widget _buildMapPin() {
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: const Color(0xFFE3F2FD),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: Colors.blue.shade200),
      ),
      child: Row(
        children: [
          const Icon(Icons.location_on, color: Colors.blue, size: 28),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: const [
                Text('Pilih Titik Lokasi Pada Peta', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13, color: Colors.blue)),
                SizedBox(height: 2),
                Text('Akurasi tinggi untuk kurir pengiriman', style: TextStyle(fontSize: 11, color: Colors.black54)),
              ],
            ),
          ),
          const Icon(Icons.arrow_forward_ios_rounded, size: 14, color: Colors.blue),
        ],
      ),
    );
  }

  Widget _buildLabelSelector() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text('Tandai Sebagai', style: TextStyle(fontSize: 13, color: Colors.black54)),
        const SizedBox(height: 12),
        Row(
          children: [
            _buildChip('Rumah'),
            const SizedBox(width: 12),
            _buildChip('Kantor'),
          ],
        ),
      ],
    );
  }

  Widget _buildChip(String label) {
    bool isSelected = _addressLabel == label;
    return GestureDetector(
      onTap: () => setState(() => _addressLabel = label),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 10),
        decoration: BoxDecoration(
          color: isSelected ? const Color(0xFFF39C12).withOpacity(0.1) : Colors.white,
          border: Border.all(color: isSelected ? const Color(0xFFF39C12) : Colors.grey.shade300, width: 1.5),
          borderRadius: BorderRadius.circular(20),
        ),
        child: Text(
          label,
          style: TextStyle(
            color: isSelected ? const Color(0xFFD35400) : Colors.grey.shade600,
            fontWeight: isSelected ? FontWeight.bold : FontWeight.w500,
            fontSize: 13,
          ),
        ),
      ),
    );
  }
}
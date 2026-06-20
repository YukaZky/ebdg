import 'package:flutter/material.dart';
import '../../services/api_service.dart';
import '../map_picker_screen.dart'; 

class AdminStoreLocationScreen extends StatefulWidget {
  final Map<String, dynamic>? existingAddress; 
  const AdminStoreLocationScreen({Key? key, this.existingAddress}) : super(key: key);

  @override
  State<AdminStoreLocationScreen> createState() => _AdminStoreLocationScreenState();
}

class _AdminStoreLocationScreenState extends State<AdminStoreLocationScreen> {
  List _provinces = [];
  List _cities = [];
  List _subdistricts = []; 

  String? _selectedProvinceId;
  String? _selectedCityId;
  String? _selectedSubdistrictId; 

  bool _isLoading = false;
  bool _isSaving = false;

  final TextEditingController _nameController = TextEditingController();
  final TextEditingController _phoneController = TextEditingController();
  final TextEditingController _postalCodeController = TextEditingController();
  final TextEditingController _detailAddressController = TextEditingController();
  final TextEditingController _landmarkController = TextEditingController();
  final TextEditingController _noteController = TextEditingController();

  String _addressLabel = 'Rumah';
  bool _isMainAddress = false;
  bool _isStoreAddress = false;

  double? _latitude;
  double? _longitude;
  String _mapAddressText = 'Pilih Titik Lokasi Pada Peta';

  @override
  void initState() {
    super.initState();
    _loadInitialData();
  }

  void _loadInitialData() async {
    setState(() => _isLoading = true);
    
    final provData = await ApiService.getProvinces();
    if (mounted) {
      setState(() => _provinces = provData);
    }
    
    if (widget.existingAddress != null && mounted) {
      final storeData = widget.existingAddress!;

      _nameController.text = storeData['name']?.toString() ?? '';
      _phoneController.text = storeData['phone']?.toString() ?? '';
      _detailAddressController.text = storeData['address']?.toString() ?? '';
      _landmarkController.text = storeData['landmark']?.toString() ?? '';
      _postalCodeController.text = storeData['postal_code']?.toString() ?? storeData['zip']?.toString() ?? '';
      _noteController.text = storeData['note']?.toString() ?? '';
      
      if (storeData['label'] != null) {
        _addressLabel = storeData['label'].toString();
      }
      
      // PERBAIKAN: Memastikan semua tipe parameter tersimpan terbaca sebagai true
      _isMainAddress = storeData['isdefault'] == 1 || storeData['isdefault'] == '1' || storeData['isdefault'] == true ||
                       storeData['is_main'] == 1 || storeData['is_main'] == '1' || storeData['is_main'] == true;
                       
      _isStoreAddress = storeData['is_store_address'] == 1 || storeData['is_store_address'] == '1' || storeData['is_store_address'] == true ||
                        storeData['is_store'] == 1 || storeData['is_store'] == '1' || storeData['is_store'] == true;

      if (storeData['latitude'] != null) _latitude = double.tryParse(storeData['latitude'].toString());
      if (storeData['longitude'] != null) _longitude = double.tryParse(storeData['longitude'].toString());
      if (_latitude != null && _longitude != null) _mapAddressText = 'Koordinat Peta Telah Dikunci';

      if (storeData['province_id'] != null) {
        String fetchedProvId = storeData['province_id'].toString();
        bool provExists = _provinces.any((p) => (p['id'] ?? p['province_id'])?.toString() == fetchedProvId);
        
        if (provExists) {
           setState(() => _selectedProvinceId = fetchedProvId);
           await _fetchCities(_selectedProvinceId!); 
           
           if (storeData['city_id'] != null) {
              String fetchedCityId = storeData['city_id'].toString();
              bool cityExists = _cities.any((c) => (c['id'] ?? c['city_id'])?.toString() == fetchedCityId);
              if (cityExists) {
                setState(() => _selectedCityId = fetchedCityId);
                await _fetchSubdistricts(fetchedCityId); 

                if (storeData['district_id'] != null && storeData['district_id'].toString() != '0') {
                  String fetchedSubId = storeData['district_id'].toString();
                  bool subExists = _subdistricts.any((s) => (s['id'] ?? s['subdistrict_id'])?.toString() == fetchedSubId);
                  if (subExists) {
                    setState(() => _selectedSubdistrictId = fetchedSubId);
                  }
                }
              }
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
    if (mounted) setState(() => _cities = data);
  }

  Future<void> _fetchSubdistricts(String cityId) async {
    final data = await ApiService.getSubdistricts(cityId);
    if (mounted) setState(() => _subdistricts = data);
  }

  void _saveLocation() async {
    if (_selectedProvinceId == null || _selectedCityId == null || _selectedSubdistrictId == null) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("Pilih Provinsi, Kota, dan Kecamatan!"), backgroundColor: Colors.redAccent));
      return;
    }

    if (_latitude == null || _longitude == null) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("Harap tentukan titik lokasi pada peta!"), backgroundColor: Colors.redAccent));
      return;
    }

    setState(() => _isSaving = true);
    
    String provinceName = '-';
    try {
      final prov = _provinces.firstWhere((p) => (p['id'] ?? p['province_id']).toString() == _selectedProvinceId);
      provinceName = (prov['name'] ?? prov['province']).toString();
    } catch (e) {}

    String cityName = '-';
    try {
      final city = _cities.firstWhere((c) => (c['id'] ?? c['city_id']).toString() == _selectedCityId);
      cityName = city['name']?.toString() ?? "${city['type'] ?? ''} ${city['city_name'] ?? ''}".trim();
    } catch (e) {}

    String subdistrictName = '-';
    try {
      final sub = _subdistricts.firstWhere((s) => (s['id'] ?? s['subdistrict_id']).toString() == _selectedSubdistrictId);
      subdistrictName = (sub['name'] ?? sub['subdistrict_name']).toString();
    } catch (e) {}

    Map<String, dynamic> payload = {
      if (widget.existingAddress != null) 'address_id': widget.existingAddress!['id'],
      'name': _nameController.text,
      'phone': _phoneController.text,
      'province_id': _selectedProvinceId,
      'province_name': provinceName,
      'city_id': _selectedCityId,
      'city_name': cityName,
      'district_id': _selectedSubdistrictId, 
      'kecamatan': subdistrictName,          
      'postal_code': _postalCodeController.text,
      'detail_address': _detailAddressController.text,
      'landmark': _landmarkController.text, 
      'note': _noteController.text,
      'label': _addressLabel,
      
      // PERBAIKAN: Mengirim angka integer 1/0 dan duplikasi key
      'is_main': _isMainAddress ? 1 : 0,
      'isdefault': _isMainAddress ? 1 : 0,
      'is_store': _isStoreAddress ? 1 : 0,
      'is_store_address': _isStoreAddress ? 1 : 0,
      
      'latitude': _latitude?.toString(),
      'longitude': _longitude?.toString(),
    };

    bool success = await ApiService.saveUserAddress(payload); 
    
    if (!mounted) return;
    setState(() => _isSaving = false);

    if (success) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("Detail Alamat berhasil disimpan!", style: TextStyle(color: Colors.white)), backgroundColor: Colors.green));
      Navigator.pop(context); 
    } else {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("Gagal menyimpan lokasi.", style: TextStyle(color: Colors.white)), backgroundColor: Colors.red));
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
      return DropdownMenuItem<String>(value: id, child: Text(name, style: const TextStyle(fontSize: 14)));
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
      return DropdownMenuItem<String>(value: id, child: Text(cityName, style: const TextStyle(fontSize: 14)));
    }).toList();
  }

  List<DropdownMenuItem<String>> _buildSubdistrictItems() {
    final seen = <String>{};
    return _subdistricts.where((sub) {
      final id = (sub['id'] ?? sub['subdistrict_id'])?.toString() ?? '';
      if (id.isEmpty || seen.contains(id)) return false;
      seen.add(id);
      return true;
    }).map<DropdownMenuItem<String>>((sub) {
      final id = (sub['id'] ?? sub['subdistrict_id']).toString();
      String subName = (sub['name'] ?? sub['subdistrict_name'])?.toString() ?? 'Tidak Diketahui';
      return DropdownMenuItem<String>(value: id, child: Text(subName, style: const TextStyle(fontSize: 14)));
    }).toList();
  }

  @override
  Widget build(BuildContext context) {
    final validProvinceId = _selectedProvinceId != null && _provinces.any((p) => (p['id'] ?? p['province_id'])?.toString() == _selectedProvinceId) ? _selectedProvinceId : null;
    final validCityId = _selectedCityId != null && _cities.any((c) => (c['id'] ?? c['city_id'])?.toString() == _selectedCityId) ? _selectedCityId : null;
    final validSubId = _selectedSubdistrictId != null && _subdistricts.any((s) => (s['id'] ?? s['subdistrict_id'])?.toString() == _selectedSubdistrictId) ? _selectedSubdistrictId : null;

    return Scaffold(
      backgroundColor: const Color(0xFFF5F7FA),
      appBar: AppBar(
        title: Text(widget.existingAddress != null ? 'Ubah Alamat Toko' : 'Pengaturan Alamat Toko', style: const TextStyle(color: Colors.black87, fontWeight: FontWeight.bold, fontSize: 16)),
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
                      Padding(
                        padding: const EdgeInsets.only(bottom: 16.0),
                        child: DropdownButtonFormField<String>(
                          isExpanded: true,
                          icon: const Icon(Icons.keyboard_arrow_down_rounded, color: Colors.grey),
                          decoration: _inputDecoration('Provinsi'),
                          value: validProvinceId,
                          items: _buildProvinceItems(),
                          onChanged: (value) {
                            setState(() {
                              _selectedProvinceId = value;
                              _selectedCityId = null; 
                              _selectedSubdistrictId = null; 
                              _cities = [];
                              _subdistricts = [];
                            });
                            if (value != null && value.isNotEmpty) _fetchCities(value);
                          },
                        ),
                      ),
                      
                      Padding(
                        padding: const EdgeInsets.only(bottom: 16.0),
                        child: DropdownButtonFormField<String>(
                          isExpanded: true,
                          icon: const Icon(Icons.keyboard_arrow_down_rounded, color: Colors.grey),
                          decoration: _inputDecoration('Kota / Kabupaten'),
                          value: validCityId,
                          items: _buildCityItems(),
                          onChanged: (value) {
                            setState(() {
                              _selectedCityId = value;
                              _selectedSubdistrictId = null;
                              _subdistricts = [];
                            });
                            if (value != null && value.isNotEmpty) _fetchSubdistricts(value);
                          },
                        ),
                      ),
                      
                      Padding(
                        padding: const EdgeInsets.only(bottom: 16.0),
                        child: DropdownButtonFormField<String>(
                          isExpanded: true,
                          icon: const Icon(Icons.keyboard_arrow_down_rounded, color: Colors.grey),
                          decoration: _inputDecoration('Kecamatan'),
                          value: validSubId,
                          items: _buildSubdistrictItems(),
                          onChanged: (value) => setState(() => _selectedSubdistrictId = value),
                        ),
                      ),

                      _buildTextField('Detail Alamat (Jalan, Gedung, No. Rumah)', _detailAddressController, maxLines: 3),
                      _buildTextField('Patokan / Landmark (Opsional)', _landmarkController),
                      _buildTextField('Kode Pos', _postalCodeController, isNumber: true),
                      _buildMapPin(),
                      _buildTextField('Catatan untuk Kurir (Opsional)', _noteController),
                    ],
                  ),
                  _buildSectionContainer(
                    title: 'Pengaturan',
                    children: [
                      _buildLabelSelector(),
                      const Divider(height: 24),
                      SwitchListTile(
                        contentPadding: EdgeInsets.zero,
                        activeColor: const Color(0xFFF39C12),
                        title: const Text('Atur sebagai alamat utama', style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600)),
                        subtitle: const Text('Pilih otomatis saat checkout.', style: TextStyle(fontSize: 12, color: Colors.grey)),
                        value: _isMainAddress,
                        onChanged: (val) => setState(() => _isMainAddress = val),
                      ),
                      const Divider(height: 16),
                      SwitchListTile(
                        contentPadding: EdgeInsets.zero,
                        activeColor: const Color(0xFFF39C12),
                        title: const Text('Atur sebagai alamat toko', style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600)),
                        subtitle: const Text('Gunakan untuk lokasi pengiriman toko.', style: TextStyle(fontSize: 12, color: Colors.grey)),
                        value: _isStoreAddress,
                        onChanged: (val) => setState(() => _isStoreAddress = val),
                      ),
                    ],
                  ),
                  const SizedBox(height: 24),
                ],
              ),
            ),
      bottomNavigationBar: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        decoration: BoxDecoration(color: Colors.white, boxShadow: [BoxShadow(color: Colors.grey.withOpacity(0.2), blurRadius: 10, offset: const Offset(0, -5))]),
        child: SafeArea(
          child: SizedBox(
            height: 48,
            child: ElevatedButton(
              style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFF0C2442), shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8))),
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

  Widget _buildSectionContainer({required String title, required List<Widget> children}) {
    return Container(
      width: double.infinity, margin: const EdgeInsets.only(top: 12), padding: const EdgeInsets.all(16), color: Colors.white,
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [Text(title, style: const TextStyle(fontSize: 15, fontWeight: FontWeight.bold)), const SizedBox(height: 16), ...children]),
    );
  }

  InputDecoration _inputDecoration(String label, {IconData? icon}) {
    return InputDecoration(
      labelText: label, labelStyle: TextStyle(color: Colors.grey.shade600, fontSize: 13),
      prefixIcon: icon != null ? Icon(icon, size: 20, color: Colors.grey.shade600) : null,
      filled: true, fillColor: Colors.grey.shade50,
      border: OutlineInputBorder(borderRadius: BorderRadius.circular(8), borderSide: BorderSide(color: Colors.grey.shade300)),
      enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(8), borderSide: BorderSide(color: Colors.grey.shade300)),
      focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(8), borderSide: const BorderSide(color: Color(0xFFF39C12), width: 1.5)),
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
    );
  }

  Widget _buildTextField(String label, TextEditingController controller, {bool isNumber = false, int maxLines = 1, IconData? icon}) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 16.0),
      child: TextFormField(
        controller: controller, keyboardType: isNumber ? TextInputType.phone : TextInputType.text, maxLines: maxLines, style: const TextStyle(fontSize: 14),
        decoration: _inputDecoration(label, icon: icon),
      ),
    );
  }

  Widget _buildMapPin() {
    bool hasLocation = _latitude != null && _longitude != null;
    return GestureDetector(
      onTap: () async {
        String provinceName = '';
        String cityName = '';
        String subdistrictName = '';
        
        try {
          if (_selectedProvinceId != null) {
            final prov = _provinces.firstWhere((p) => (p['id'] ?? p['province_id']).toString() == _selectedProvinceId);
            provinceName = (prov['name'] ?? prov['province']).toString();
          }
          if (_selectedCityId != null) {
            final city = _cities.firstWhere((c) => (c['id'] ?? c['city_id']).toString() == _selectedCityId);
            cityName = city['name']?.toString() ?? "${city['type'] ?? ''} ${city['city_name'] ?? ''}".trim();
          }
          if (_selectedSubdistrictId != null) {
            final sub = _subdistricts.firstWhere((s) => (s['id'] ?? s['subdistrict_id']).toString() == _selectedSubdistrictId);
            subdistrictName = (sub['name'] ?? sub['subdistrict_name']).toString();
          }
        } catch (e) {}

        List<String> addressParts = [];
        if (_detailAddressController.text.isNotEmpty) addressParts.add(_detailAddressController.text);
        if (subdistrictName.isNotEmpty) addressParts.add(subdistrictName);
        if (cityName.isNotEmpty) addressParts.add(cityName);
        if (provinceName.isNotEmpty) addressParts.add(provinceName);
        
        String fullSearchAddress = addressParts.join(', ');

        final result = await Navigator.push(
          context,
          MaterialPageRoute(builder: (context) => MapPickerScreen(
            initialLat: _latitude,
            initialLng: _longitude,
            searchAddress: fullSearchAddress,
          )),
        );

        if (!mounted) return;

        if (result != null) {
          setState(() {
            _latitude = result['latitude'];
            _longitude = result['longitude'];
            _mapAddressText = 'Koordinat Peta Telah Dikunci';
            
            if (_detailAddressController.text.isEmpty) {
              _detailAddressController.text = result['addressText'];
            }
          });
        }
      },
      child: Container(
        margin: const EdgeInsets.only(bottom: 16),
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: hasLocation ? Colors.green.shade50 : const Color(0xFFE3F2FD),
          borderRadius: BorderRadius.circular(8),
          border: Border.all(color: hasLocation ? Colors.green : Colors.blue.shade200),
        ),
        child: Row(
          children: [
            Icon(Icons.location_on, color: hasLocation ? Colors.green : Colors.blue, size: 28),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(_mapAddressText, style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13, color: hasLocation ? Colors.green : Colors.blue)),
                  const SizedBox(height: 2),
                  Text(hasLocation ? 'Akurat: $_latitude, $_longitude' : 'Akurasi tinggi untuk kurir pengiriman', style: const TextStyle(fontSize: 11, color: Colors.black54)),
                ],
              ),
            ),
            Icon(hasLocation ? Icons.check_circle : Icons.arrow_forward_ios_rounded, size: 14, color: hasLocation ? Colors.green : Colors.blue),
          ],
        ),
      ),
    );
  }

  Widget _buildLabelSelector() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text('Tandai Sebagai', style: TextStyle(fontSize: 13, color: Colors.black54)),
        const SizedBox(height: 12),
        Row(children: [_buildChip('Rumah'), const SizedBox(width: 12), _buildChip('Kantor')]),
      ],
    );
  }

  Widget _buildChip(String label) {
    bool isSelected = _addressLabel == label;
    return GestureDetector(
      onTap: () => setState(() => _addressLabel = label),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 10),
        decoration: BoxDecoration(color: isSelected ? const Color(0xFFF39C12).withOpacity(0.1) : Colors.white, border: Border.all(color: isSelected ? const Color(0xFFF39C12) : Colors.grey.shade300, width: 1.5), borderRadius: BorderRadius.circular(20)),
        child: Text(label, style: TextStyle(color: isSelected ? const Color(0xFFD35400) : Colors.grey.shade600, fontWeight: isSelected ? FontWeight.bold : FontWeight.w500, fontSize: 13)),
      ),
    );
  }
}
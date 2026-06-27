import 'package:flutter/material.dart';
import '../../services/api_service.dart';
import '../map_picker_screen.dart';

class AddressFormScreen extends StatefulWidget {
  final Map<String, dynamic>? existingAddress;
  const AddressFormScreen({Key? key, this.existingAddress}) : super(key: key);

  @override
  State<AddressFormScreen> createState() => _AddressFormScreenState();
}

class _AddressFormScreenState extends State<AddressFormScreen> {
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

  double? _latitude;
  double? _longitude;
  String _mapAddressText = 'Pilih Titik Lokasi Pada Peta';

  @override
  void initState() {
    super.initState();
    _loadInitialData();
  }

  @override
  void dispose() {
    _nameController.dispose();
    _phoneController.dispose();
    _postalCodeController.dispose();
    _detailAddressController.dispose();
    _landmarkController.dispose();
    _noteController.dispose();
    super.dispose();
  }

  Future<void> _loadInitialData() async {
    setState(() => _isLoading = true);

    final provData = await ApiService.getProvinces();
    if (!mounted) return;
    setState(() => _provinces = provData);

    final addressData = widget.existingAddress;
    if (addressData != null) {
      _nameController.text = addressData['name']?.toString() ?? '';
      _phoneController.text = addressData['phone']?.toString() ?? '';
      _detailAddressController.text = addressData['address']?.toString() ?? '';
      _landmarkController.text = addressData['landmark']?.toString() ?? '';
      _postalCodeController.text = addressData['postal_code']?.toString() ?? addressData['zip']?.toString() ?? '';
      _noteController.text = addressData['note']?.toString() ?? '';

      final label = addressData['label']?.toString();
      if (label == 'Rumah' || label == 'Kantor') _addressLabel = label!;

      _isMainAddress = addressData['isdefault'] == 1 ||
          addressData['isdefault'] == '1' ||
          addressData['isdefault'] == true ||
          addressData['is_main'] == 1 ||
          addressData['is_main'] == '1' ||
          addressData['is_main'] == true;

      _latitude = double.tryParse(addressData['latitude']?.toString() ?? '');
      _longitude = double.tryParse(addressData['longitude']?.toString() ?? '');
      if (_latitude != null && _longitude != null) _mapAddressText = 'Koordinat Peta Telah Dikunci';

      final provinceId = addressData['province_id']?.toString();
      if (provinceId != null && _provinces.any((p) => (p['id'] ?? p['province_id'])?.toString() == provinceId)) {
        _selectedProvinceId = provinceId;
        await _fetchCities(provinceId);

        final cityId = addressData['city_id']?.toString();
        if (cityId != null && _cities.any((c) => (c['id'] ?? c['city_id'])?.toString() == cityId)) {
          _selectedCityId = cityId;
          await _fetchSubdistricts(cityId);

          final districtId = addressData['district_id']?.toString();
          if (districtId != null && districtId != '0' && _subdistricts.any((s) => (s['id'] ?? s['subdistrict_id'])?.toString() == districtId)) {
            _selectedSubdistrictId = districtId;
          }
        }
      }
    }

    if (mounted) setState(() => _isLoading = false);
  }

  Future<void> _fetchCities(String provinceId) async {
    final data = await ApiService.getCities(provinceId);
    if (mounted) setState(() => _cities = data);
  }

  Future<void> _fetchSubdistricts(String cityId) async {
    final data = await ApiService.getSubdistricts(cityId);
    if (mounted) setState(() => _subdistricts = data);
  }

  String _provinceName() {
    try {
      final prov = _provinces.firstWhere((p) => (p['id'] ?? p['province_id']).toString() == _selectedProvinceId);
      return (prov['name'] ?? prov['province']).toString();
    } catch (_) {
      return '-';
    }
  }

  String _cityName() {
    try {
      final city = _cities.firstWhere((c) => (c['id'] ?? c['city_id']).toString() == _selectedCityId);
      final name = city['name']?.toString() ?? '${city['type'] ?? ''} ${city['city_name'] ?? ''}'.trim();
      return name.isEmpty ? '-' : name;
    } catch (_) {
      return '-';
    }
  }

  String _subdistrictName() {
    try {
      final sub = _subdistricts.firstWhere((s) => (s['id'] ?? s['subdistrict_id']).toString() == _selectedSubdistrictId);
      return (sub['name'] ?? sub['subdistrict_name']).toString();
    } catch (_) {
      return '-';
    }
  }

  Future<void> _saveLocation() async {
    if (_selectedProvinceId == null || _selectedCityId == null || _selectedSubdistrictId == null) {
      _showSnack('Pilih Provinsi, Kota, dan Kecamatan!', error: true);
      return;
    }

    if (_latitude == null || _longitude == null) {
      _showSnack('Harap tentukan titik lokasi pada peta!', error: true);
      return;
    }

    setState(() => _isSaving = true);

    final payload = <String, dynamic>{
      if (widget.existingAddress != null) 'address_id': widget.existingAddress!['id'],
      'name': _nameController.text,
      'phone': _phoneController.text,
      'province_id': _selectedProvinceId,
      'province_name': _provinceName(),
      'city_id': _selectedCityId,
      'city_name': _cityName(),
      'district_id': _selectedSubdistrictId,
      'kecamatan': _subdistrictName(),
      'postal_code': _postalCodeController.text,
      'detail_address': _detailAddressController.text,
      'landmark': _landmarkController.text,
      'note': _noteController.text,
      'label': _addressLabel,
      'is_main': _isMainAddress ? 1 : 0,
      'isdefault': _isMainAddress ? 1 : 0,
      'is_store': 0,
      'is_store_address': 0,
      'latitude': _latitude?.toString(),
      'longitude': _longitude?.toString(),
    };

    final success = await ApiService.saveUserAddress(payload);

    if (!mounted) return;
    setState(() => _isSaving = false);

    if (success) {
      _showSnack('Detail alamat berhasil disimpan.');
      Navigator.pop(context);
    } else {
      _showSnack('Gagal menyimpan lokasi.', error: true);
    }
  }

  void _showSnack(String message, {bool error = false}) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message), backgroundColor: error ? Colors.red : Colors.green),
    );
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
      final name = city['name']?.toString() ?? '${city['type'] ?? ''} ${city['city_name'] ?? ''}'.trim();
      return DropdownMenuItem<String>(value: id, child: Text(name.isEmpty ? 'Tidak Diketahui' : name, style: const TextStyle(fontSize: 14)));
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
      final name = (sub['name'] ?? sub['subdistrict_name'])?.toString() ?? 'Tidak Diketahui';
      return DropdownMenuItem<String>(value: id, child: Text(name, style: const TextStyle(fontSize: 14)));
    }).toList();
  }

  Future<void> _pickMap() async {
    final parts = <String>[];
    if (_detailAddressController.text.trim().isNotEmpty) parts.add(_detailAddressController.text.trim());
    if (_subdistrictName() != '-') parts.add(_subdistrictName());
    if (_cityName() != '-') parts.add(_cityName());
    if (_provinceName() != '-') parts.add(_provinceName());

    final result = await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => MapPickerScreen(
          initialLat: _latitude,
          initialLng: _longitude,
          searchAddress: parts.join(', '),
        ),
      ),
    );

    if (!mounted || result == null) return;
    setState(() {
      _latitude = result['latitude'];
      _longitude = result['longitude'];
      _mapAddressText = 'Koordinat Peta Telah Dikunci';
      if (_detailAddressController.text.trim().isEmpty) {
        _detailAddressController.text = result['addressText']?.toString() ?? '';
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final validProvinceId = _selectedProvinceId != null && _provinces.any((p) => (p['id'] ?? p['province_id'])?.toString() == _selectedProvinceId) ? _selectedProvinceId : null;
    final validCityId = _selectedCityId != null && _cities.any((c) => (c['id'] ?? c['city_id'])?.toString() == _selectedCityId) ? _selectedCityId : null;
    final validSubId = _selectedSubdistrictId != null && _subdistricts.any((s) => (s['id'] ?? s['subdistrict_id'])?.toString() == _selectedSubdistrictId) ? _selectedSubdistrictId : null;

    return Scaffold(
      backgroundColor: const Color(0xFFF5F7FA),
      appBar: AppBar(
        title: Text(widget.existingAddress != null ? 'Ubah Alamat' : 'Tambah Alamat', style: const TextStyle(color: Colors.black87, fontWeight: FontWeight.bold, fontSize: 16)),
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
                      _dropdown('Provinsi', validProvinceId, _buildProvinceItems(), (value) {
                        setState(() {
                          _selectedProvinceId = value;
                          _selectedCityId = null;
                          _selectedSubdistrictId = null;
                          _cities = [];
                          _subdistricts = [];
                        });
                        if (value != null && value.isNotEmpty) _fetchCities(value);
                      }),
                      _dropdown('Kota / Kabupaten', validCityId, _buildCityItems(), (value) {
                        setState(() {
                          _selectedCityId = value;
                          _selectedSubdistrictId = null;
                          _subdistricts = [];
                        });
                        if (value != null && value.isNotEmpty) _fetchSubdistricts(value);
                      }),
                      _dropdown('Kecamatan', validSubId, _buildSubdistrictItems(), (value) => setState(() => _selectedSubdistrictId = value)),
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
                      const SizedBox(height: 6),
                      const Text('Alamat toko hanya bisa diatur dari halaman Pengaturan Alamat Toko.', style: TextStyle(fontSize: 12, color: Colors.grey)),
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
      width: double.infinity,
      margin: const EdgeInsets.only(top: 12),
      padding: const EdgeInsets.all(16),
      color: Colors.white,
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [Text(title, style: const TextStyle(fontSize: 15, fontWeight: FontWeight.bold)), const SizedBox(height: 16), ...children]),
    );
  }

  Widget _dropdown(String label, String? value, List<DropdownMenuItem<String>> items, ValueChanged<String?> onChanged) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: DropdownButtonFormField<String>(
        isExpanded: true,
        icon: const Icon(Icons.keyboard_arrow_down_rounded, color: Colors.grey),
        decoration: _inputDecoration(label),
        value: value,
        items: items,
        onChanged: onChanged,
      ),
    );
  }

  InputDecoration _inputDecoration(String label, {IconData? icon}) {
    return InputDecoration(
      labelText: label,
      labelStyle: TextStyle(color: Colors.grey.shade600, fontSize: 13),
      prefixIcon: icon != null ? Icon(icon, size: 20, color: Colors.grey.shade600) : null,
      filled: true,
      fillColor: Colors.grey.shade50,
      border: OutlineInputBorder(borderRadius: BorderRadius.circular(8), borderSide: BorderSide(color: Colors.grey.shade300)),
      enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(8), borderSide: BorderSide(color: Colors.grey.shade300)),
      focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(8), borderSide: const BorderSide(color: Color(0xFFF39C12), width: 1.5)),
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
    );
  }

  Widget _buildTextField(String label, TextEditingController controller, {bool isNumber = false, int maxLines = 1, IconData? icon}) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: TextFormField(
        controller: controller,
        keyboardType: isNumber ? TextInputType.phone : TextInputType.text,
        maxLines: maxLines,
        style: const TextStyle(fontSize: 14),
        decoration: _inputDecoration(label, icon: icon),
      ),
    );
  }

  Widget _buildMapPin() {
    final hasLocation = _latitude != null && _longitude != null;
    return GestureDetector(
      onTap: _pickMap,
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
    final isSelected = _addressLabel == label;
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

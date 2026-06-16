import 'package:flutter/material.dart';
import '../../services/marketplace_api_service.dart';

class StoreProfileScreen extends StatefulWidget {
  const StoreProfileScreen({Key? key}) : super(key: key);

  @override
  State<StoreProfileScreen> createState() => _StoreProfileScreenState();
}

class _StoreProfileScreenState extends State<StoreProfileScreen> {
  final _formKey = GlobalKey<FormState>();
  final _nameCtrl = TextEditingController();
  final _phoneCtrl = TextEditingController();
  final _descriptionCtrl = TextEditingController();
  final _addressCtrl = TextEditingController();
  final _mapsCtrl = TextEditingController();
  final _provinceCtrl = TextEditingController();
  final _cityCtrl = TextEditingController();
  final _instagramCtrl = TextEditingController();
  final _tiktokCtrl = TextEditingController();
  final _facebookCtrl = TextEditingController();
  final _websiteCtrl = TextEditingController();
  bool _loading = true;
  bool _saving = false;

  @override
  void initState() {
    super.initState();
    _loadStore();
  }

  Future<void> _loadStore() async {
    final store = await MarketplaceApiService.myStore();
    if (!mounted) return;
    if (store != null) {
      _nameCtrl.text = store['name']?.toString() ?? '';
      _phoneCtrl.text = store['phone']?.toString() ?? '';
      _descriptionCtrl.text = store['description']?.toString() ?? '';
      _addressCtrl.text = store['address']?.toString() ?? '';
      _mapsCtrl.text = store['maps_url']?.toString() ?? '';
      _provinceCtrl.text = store['province_name']?.toString() ?? '';
      _cityCtrl.text = store['city_name']?.toString() ?? '';
      _instagramCtrl.text = store['instagram']?.toString() ?? '';
      _tiktokCtrl.text = store['tiktok']?.toString() ?? '';
      _facebookCtrl.text = store['facebook']?.toString() ?? '';
      _websiteCtrl.text = store['website']?.toString() ?? '';
    }
    setState(() => _loading = false);
  }

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _saving = true);
    final store = await MarketplaceApiService.saveStore({
      'name': _nameCtrl.text,
      'phone': _phoneCtrl.text,
      'description': _descriptionCtrl.text,
      'address': _addressCtrl.text,
      'maps_url': _mapsCtrl.text,
      'province_name': _provinceCtrl.text,
      'city_name': _cityCtrl.text,
      'instagram': _instagramCtrl.text,
      'tiktok': _tiktokCtrl.text,
      'facebook': _facebookCtrl.text,
      'website': _websiteCtrl.text,
    });
    if (!mounted) return;
    setState(() => _saving = false);
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(store != null ? 'Profil toko berhasil disimpan' : 'Gagal menyimpan profil toko')));
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF6F7FB),
      appBar: AppBar(title: const Text('Profil Toko'), backgroundColor: Colors.white, foregroundColor: Colors.black87),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : SingleChildScrollView(
              padding: const EdgeInsets.all(16),
              child: Form(
                key: _formKey,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.all(18),
                      decoration: BoxDecoration(color: Colors.deepOrange, borderRadius: BorderRadius.circular(18)),
                      child: const Text('Atur toko agar lebih dipercaya pembeli. Nama toko, alamat, maps, dan sosial media akan muncul di detail produk.', style: TextStyle(color: Colors.white, height: 1.4)),
                    ),
                    const SizedBox(height: 16),
                    _section('Informasi Utama'),
                    _field('Nama Toko', _nameCtrl, required: true),
                    _field('Nomor HP Toko', _phoneCtrl),
                    _field('Deskripsi Toko', _descriptionCtrl, maxLines: 4),
                    _section('Lokasi Toko'),
                    _field('Kota', _cityCtrl),
                    _field('Provinsi', _provinceCtrl),
                    _field('Alamat Toko', _addressCtrl, maxLines: 3),
                    _field('Link Google Maps / Maps Toko', _mapsCtrl, maxLines: 2),
                    _section('Sosial Media Toko'),
                    _field('Instagram', _instagramCtrl),
                    _field('TikTok', _tiktokCtrl),
                    _field('Facebook', _facebookCtrl),
                    _field('Website', _websiteCtrl),
                    const SizedBox(height: 16),
                    ElevatedButton(
                      onPressed: _saving ? null : _save,
                      style: ElevatedButton.styleFrom(backgroundColor: Colors.deepOrange, foregroundColor: Colors.white, padding: const EdgeInsets.symmetric(vertical: 14)),
                      child: Text(_saving ? 'Menyimpan...' : 'Simpan Profil Toko'),
                    ),
                  ],
                ),
              ),
            ),
    );
  }

  Widget _section(String title) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 10, top: 6),
      child: Text(title, style: const TextStyle(fontSize: 15, fontWeight: FontWeight.bold, color: Colors.black87)),
    );
  }

  Widget _field(String label, TextEditingController controller, {bool required = false, int maxLines = 1}) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 14),
      child: TextFormField(
        controller: controller,
        maxLines: maxLines,
        decoration: InputDecoration(labelText: label, filled: true, fillColor: Colors.white, border: OutlineInputBorder(borderRadius: BorderRadius.circular(14))),
        validator: (value) => required && (value == null || value.isEmpty) ? '$label wajib diisi' : null,
      ),
    );
  }
}

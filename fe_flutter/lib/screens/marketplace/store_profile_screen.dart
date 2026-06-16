import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import '../../services/api_service.dart';
import '../../services/marketplace_api_service.dart';
import '../admin/address_list_screen.dart';

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
  final ImagePicker _picker = ImagePicker();

  XFile? _logoFile;
  String? _existingLogo;
  bool _loading = true;
  bool _saving = false;

  @override
  void initState() {
    super.initState();
    _loadStore();
  }

  @override
  void dispose() {
    _nameCtrl.dispose();
    _phoneCtrl.dispose();
    _descriptionCtrl.dispose();
    _addressCtrl.dispose();
    _mapsCtrl.dispose();
    _provinceCtrl.dispose();
    _cityCtrl.dispose();
    _instagramCtrl.dispose();
    _tiktokCtrl.dispose();
    _facebookCtrl.dispose();
    _websiteCtrl.dispose();
    super.dispose();
  }

  String _storeMediaUrl(dynamic image) {
    final value = image?.toString().trim() ?? '';
    if (value.isEmpty || value == 'null') return '';
    if (value.startsWith('http://') || value.startsWith('https://')) return value;

    final base = ApiService.baseUrl.replaceFirst(RegExp(r'/api/?$'), '');
    final clean = value.startsWith('/') ? value.substring(1) : value;
    if (clean.startsWith('uploads/') || clean.startsWith('storage/')) return '$base/$clean';
    return '$base/uploads/stores/$clean';
  }

  Future<void> _loadStore() async {
    setState(() => _loading = true);
    final store = await MarketplaceApiService.myStore();
    if (!mounted) return;
    if (store != null) {
      _existingLogo = store['logo']?.toString();
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

  Future<void> _openAddressPage() async {
    await Navigator.push(context, MaterialPageRoute(builder: (_) => const AddressListScreen()));
    if (!mounted) return;
    await _loadStore();
  }

  Future<void> _pickLogo() async {
    final picked = await _picker.pickImage(source: ImageSource.gallery, imageQuality: 85);
    if (picked != null) setState(() => _logoFile = picked);
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
    }, logo: _logoFile);
    if (!mounted) return;
    setState(() {
      if (store != null) {
        _existingLogo = store['logo']?.toString();
        _logoFile = null;
      }
      _saving = false;
    });
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(store != null ? 'Profil toko berhasil disimpan' : 'Gagal menyimpan profil toko')));
  }

  Widget _logoPreview() {
    final existingUrl = _storeMediaUrl(_existingLogo);
    return InkWell(
      onTap: _pickLogo,
      borderRadius: BorderRadius.circular(18),
      child: Container(
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(18), border: Border.all(color: Colors.deepOrange.withOpacity(0.25))),
        child: Row(children: [
          Container(
            width: 72,
            height: 72,
            clipBehavior: Clip.antiAlias,
            decoration: const BoxDecoration(color: Color(0xFFFFF3E0), shape: BoxShape.circle),
            child: _logoFile != null
                ? FutureBuilder(
                    future: _logoFile!.readAsBytes(),
                    builder: (context, snapshot) {
                      if (!snapshot.hasData) return const Center(child: CircularProgressIndicator(strokeWidth: 2));
                      return Image.memory(snapshot.data!, fit: BoxFit.cover);
                    },
                  )
                : existingUrl.isNotEmpty
                    ? Image.network(existingUrl, fit: BoxFit.cover, errorBuilder: (_, __, ___) => const Icon(Icons.storefront, color: Colors.deepOrange, size: 34))
                    : const Icon(Icons.storefront, color: Colors.deepOrange, size: 34),
          ),
          const SizedBox(width: 14),
          const Expanded(
            child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Text('Logo / Foto Profil Toko', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 15)),
              SizedBox(height: 4),
              Text('Ketuk untuk upload logo toko. Logo ini akan muncul di detail produk dan halaman toko.', style: TextStyle(color: Colors.black54, fontSize: 12, height: 1.35)),
            ]),
          ),
          const Icon(Icons.chevron_right, color: Colors.deepOrange),
        ]),
      ),
    );
  }

  Widget _lockedLocationNotice() {
    return Container(
      padding: const EdgeInsets.all(14),
      margin: const EdgeInsets.only(bottom: 14),
      decoration: BoxDecoration(color: const Color(0xFFFFF7ED), borderRadius: BorderRadius.circular(14), border: Border.all(color: Colors.deepOrange.withOpacity(0.2))),
      child: Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
        const Icon(Icons.lock_outline, color: Colors.deepOrange, size: 22),
        const SizedBox(width: 10),
        const Expanded(
          child: Text(
            'Lokasi toko tidak diubah dari form ini. Atur melalui Alamat Saya, lalu aktifkan pilihan Atur sebagai alamat toko.',
            style: TextStyle(fontSize: 12.5, height: 1.4, color: Colors.black87),
          ),
        ),
      ]),
    );
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
                      child: const Text('Lokasi toko akan otomatis mengikuti alamat yang ditandai sebagai Alamat Toko di menu Alamat Saya. Di sini kamu bisa melengkapi logo, deskripsi, dan link sosial media.', style: TextStyle(color: Colors.white, height: 1.4)),
                    ),
                    const SizedBox(height: 16),
                    _logoPreview(),
                    const SizedBox(height: 16),
                    _section('Informasi Utama'),
                    _field('Nama Toko', _nameCtrl, required: true),
                    _field('Nomor HP Toko', _phoneCtrl),
                    _field('Deskripsi Toko', _descriptionCtrl, maxLines: 4),
                    _section('Lokasi Toko dari Alamat Saya'),
                    _lockedLocationNotice(),
                    _field('Kota', _cityCtrl, readOnly: true),
                    _field('Provinsi', _provinceCtrl, readOnly: true),
                    _field('Alamat Toko', _addressCtrl, maxLines: 3, readOnly: true),
                    _field('Link Google Maps / Maps Toko', _mapsCtrl, maxLines: 2, readOnly: true),
                    OutlinedButton.icon(
                      onPressed: _openAddressPage,
                      icon: const Icon(Icons.location_on_outlined),
                      label: const Text('Buka Alamat Saya untuk Atur Alamat Toko'),
                      style: OutlinedButton.styleFrom(
                        foregroundColor: Colors.deepOrange,
                        side: const BorderSide(color: Colors.deepOrange),
                        padding: const EdgeInsets.symmetric(vertical: 13),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                      ),
                    ),
                    const SizedBox(height: 16),
                    _section('Link Sosial Media Toko'),
                    _field('Link Instagram', _instagramCtrl),
                    _field('Link TikTok', _tiktokCtrl),
                    _field('Link Facebook', _facebookCtrl),
                    _field('Link Website', _websiteCtrl),
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

  Widget _field(String label, TextEditingController controller, {bool required = false, int maxLines = 1, bool readOnly = false}) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 14),
      child: TextFormField(
        controller: controller,
        maxLines: maxLines,
        readOnly: readOnly,
        decoration: InputDecoration(
          labelText: label,
          filled: true,
          fillColor: readOnly ? const Color(0xFFF1F5F9) : Colors.white,
          suffixIcon: readOnly ? const Icon(Icons.lock_outline, size: 18, color: Colors.grey) : null,
          border: OutlineInputBorder(borderRadius: BorderRadius.circular(14)),
        ),
        validator: (value) => required && (value == null || value.isEmpty) ? '$label wajib diisi' : null,
      ),
    );
  }
}

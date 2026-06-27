import 'dart:io';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import '../../services/api_service.dart';
import '../../services/admin_brand_api_service.dart';

class AdminBrandFormScreen extends StatefulWidget {
  final Map<String, dynamic>? brand;

  const AdminBrandFormScreen({Key? key, this.brand}) : super(key: key);

  @override
  _AdminBrandFormScreenState createState() => _AdminBrandFormScreenState();
}

class _AdminBrandFormScreenState extends State<AdminBrandFormScreen> {
  final _formKey = GlobalKey<FormState>();
  final TextEditingController _nameController = TextEditingController();

  List<dynamic> _categories = [];
  String? _selectedCategoryId;

  XFile? _selectedImage;
  bool _isSaving = false;
  bool _isLoading = true;

  static const Color _primary = Color(0xFF0C2442);
  static const Color _accent = Color(0xFFFFB703);
  static const Color _surface = Color(0xFFF7F8FC);
  static const Color _muted = Color(0xFF64748B);

  @override
  void initState() {
    super.initState();
    if (widget.brand != null) {
      _nameController.text = widget.brand!['name']?.toString() ?? '';
      if (widget.brand!['category_id'] != null) {
        _selectedCategoryId = widget.brand!['category_id'].toString();
      }
    }
    _fetchCategories();
  }

  @override
  void dispose() {
    _nameController.dispose();
    super.dispose();
  }

  Future<void> _fetchCategories() async {
    final categories = await ApiService.getAdminCategories();
    if (!mounted) return;
    setState(() {
      _categories = categories;
      final exists = _selectedCategoryId == null || _categories.any((cat) => cat['id']?.toString() == _selectedCategoryId);
      if (!exists) _selectedCategoryId = null;
      _isLoading = false;
    });
  }

  Future<void> _pickImage() async {
    final ImagePicker picker = ImagePicker();
    final XFile? image = await picker.pickImage(source: ImageSource.gallery, imageQuality: 85);
    if (image != null && mounted) setState(() => _selectedImage = image);
  }

  Future<void> _saveBrand() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isSaving = true);

    final fields = <String, String>{
      'name': _nameController.text.trim(),
    };

    if (_selectedCategoryId != null && _selectedCategoryId!.trim().isNotEmpty) {
      fields['category_id'] = _selectedCategoryId!;
    }

    final success = await AdminBrandApiService.saveBrand(
      fields,
      image: _selectedImage,
      brandId: widget.brand?['id'],
    );

    if (!mounted) return;
    setState(() => _isSaving = false);

    if (success) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Berhasil menyimpan brand')));
      Navigator.pop(context, true);
    } else {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(AdminBrandApiService.lastError ?? 'Gagal menyimpan brand')));
    }
  }

  InputDecoration _inputDecoration(String label, IconData icon) {
    return InputDecoration(
      labelText: label,
      labelStyle: const TextStyle(fontSize: 12.5, color: _muted, fontWeight: FontWeight.w700),
      prefixIcon: Icon(icon, size: 18, color: _primary),
      isDense: true,
      contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
      border: OutlineInputBorder(borderRadius: BorderRadius.circular(14)),
      enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(14), borderSide: const BorderSide(color: Color(0xFFE2E8F0))),
      focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(14), borderSide: const BorderSide(color: _primary, width: 1.4)),
      filled: true,
      fillColor: Colors.white,
    );
  }

  Widget _imagePreview(bool isEdit) {
    if (_selectedImage != null) {
      if (kIsWeb) {
        return Image.network(_selectedImage!.path, width: 68, height: 68, fit: BoxFit.cover);
      }
      return Image.file(File(_selectedImage!.path), width: 68, height: 68, fit: BoxFit.cover);
    }

    final existingImage = widget.brand?['image']?.toString();
    if (isEdit && existingImage != null && existingImage.isNotEmpty && existingImage != 'null') {
      return Image.network(
        '${ApiService.baseUrl.replaceAll('/api', '')}/uploads/brands/$existingImage',
        width: 68,
        height: 68,
        fit: BoxFit.cover,
        errorBuilder: (_, __, ___) => const Icon(Icons.image_not_supported, size: 32, color: _muted),
      );
    }

    return Container(
      width: 68,
      height: 68,
      decoration: BoxDecoration(color: const Color(0xFFEFF4FA), borderRadius: BorderRadius.circular(16)),
      child: const Icon(Icons.branding_watermark_rounded, color: _primary, size: 28),
    );
  }

  @override
  Widget build(BuildContext context) {
    final isEdit = widget.brand != null;

    if (_isLoading) {
      return Scaffold(
        backgroundColor: _surface,
        appBar: AppBar(title: Text(isEdit ? 'Edit Brand' : 'Tambah Brand', style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w900)), foregroundColor: _primary, backgroundColor: Colors.white, elevation: 0),
        body: const Center(child: CircularProgressIndicator()),
      );
    }

    return Scaffold(
      backgroundColor: _surface,
      appBar: AppBar(
        title: Text(isEdit ? 'Edit Brand' : 'Tambah Brand', style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w900)),
        backgroundColor: Colors.white,
        foregroundColor: _primary,
        elevation: 0,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(14),
                decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(20), border: Border.all(color: const Color(0xFFE2E8F0))),
                child: Row(
                  children: [
                    Container(width: 42, height: 42, decoration: BoxDecoration(color: _accent.withOpacity(.16), borderRadius: BorderRadius.circular(14)), child: const Icon(Icons.verified_rounded, color: _primary, size: 22)),
                    const SizedBox(width: 12),
                    Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: const [
                      Text('Data Brand', style: TextStyle(fontSize: 14.5, fontWeight: FontWeight.w900, color: _primary)),
                      SizedBox(height: 3),
                      Text('Isi nama, kategori opsional, dan gambar brand.', style: TextStyle(fontSize: 11.5, color: _muted)),
                    ])),
                  ],
                ),
              ),
              const SizedBox(height: 14),
              TextFormField(
                controller: _nameController,
                style: const TextStyle(fontSize: 13.5, fontWeight: FontWeight.w700),
                decoration: _inputDecoration('Nama Brand', Icons.sell_outlined),
                validator: (value) => value == null || value.trim().isEmpty ? 'Nama tidak boleh kosong' : null,
              ),
              const SizedBox(height: 14),
              DropdownButtonFormField<String>(
                decoration: _inputDecoration('Pilih Kategori (Opsional)', Icons.category_outlined),
                value: _selectedCategoryId,
                style: const TextStyle(fontSize: 13, color: Colors.black87, fontWeight: FontWeight.w700),
                items: _categories.map<DropdownMenuItem<String>>((cat) {
                  return DropdownMenuItem<String>(value: cat['id'].toString(), child: Text(cat['name']?.toString() ?? '-'));
                }).toList(),
                onChanged: _isSaving ? null : (value) => setState(() => _selectedCategoryId = value),
              ),
              if (_selectedCategoryId != null) ...[
                const SizedBox(height: 6),
                SizedBox(height: 30, child: TextButton.icon(onPressed: _isSaving ? null : () => setState(() => _selectedCategoryId = null), icon: const Icon(Icons.close, size: 14), label: const Text('Kosongkan kategori', style: TextStyle(fontSize: 12)))),
              ],
              const SizedBox(height: 14),
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(18), border: Border.all(color: const Color(0xFFE2E8F0))),
                child: Row(
                  children: [
                    ClipRRect(borderRadius: BorderRadius.circular(14), child: _imagePreview(isEdit)),
                    const SizedBox(width: 12),
                    Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                      const Text('Logo Brand', style: TextStyle(fontSize: 13, fontWeight: FontWeight.w900, color: _primary)),
                      const SizedBox(height: 3),
                      const Text('Gunakan gambar 1:1 agar tampil rapi di daftar brand.', style: TextStyle(fontSize: 11, color: _muted, height: 1.3)),
                      const SizedBox(height: 8),
                      SizedBox(height: 34, child: OutlinedButton.icon(onPressed: _isSaving ? null : _pickImage, icon: const Icon(Icons.upload_rounded, size: 16), label: const Text('Pilih Gambar', style: TextStyle(fontSize: 12, fontWeight: FontWeight.w800)))),
                    ])),
                  ],
                ),
              ),
              const SizedBox(height: 22),
              SizedBox(
                width: double.infinity,
                height: 44,
                child: ElevatedButton(
                  onPressed: _isSaving ? null : _saveBrand,
                  style: ElevatedButton.styleFrom(backgroundColor: _primary, foregroundColor: Colors.white, elevation: 0, shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14))),
                  child: _isSaving ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2)) : Text(isEdit ? 'Update Brand' : 'Simpan Brand', style: const TextStyle(fontSize: 13.5, fontWeight: FontWeight.w900)),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

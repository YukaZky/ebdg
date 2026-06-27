import 'dart:io';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import '../../services/api_service.dart';

class AdminCategoryFormScreen extends StatefulWidget {
  final Map<String, dynamic>? category;

  const AdminCategoryFormScreen({Key? key, this.category}) : super(key: key);

  @override
  _AdminCategoryFormScreenState createState() => _AdminCategoryFormScreenState();
}

class _AdminCategoryFormScreenState extends State<AdminCategoryFormScreen> {
  final _formKey = GlobalKey<FormState>();
  final TextEditingController _nameController = TextEditingController();

  XFile? _selectedImage;
  bool _isSaving = false;

  static const Color _primary = Color(0xFF0C2442);
  static const Color _accent = Color(0xFFFFB703);
  static const Color _surface = Color(0xFFF7F8FC);
  static const Color _muted = Color(0xFF64748B);

  @override
  void initState() {
    super.initState();
    if (widget.category != null) {
      _nameController.text = widget.category!['name']?.toString() ?? '';
    }
  }

  @override
  void dispose() {
    _nameController.dispose();
    super.dispose();
  }

  Future<void> _pickImage() async {
    final ImagePicker picker = ImagePicker();
    final XFile? image = await picker.pickImage(source: ImageSource.gallery, imageQuality: 85);
    if (image != null && mounted) setState(() => _selectedImage = image);
  }

  Future<void> _saveCategory() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isSaving = true);

    final fields = <String, String>{
      'name': _nameController.text.trim(),
    };

    final success = await ApiService.saveAdminCategory(
      fields,
      image: _selectedImage,
      categoryId: widget.category?['id'],
    );

    if (!mounted) return;
    setState(() => _isSaving = false);

    if (success) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Berhasil menyimpan kategori')));
      Navigator.pop(context, true);
    } else {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Gagal menyimpan kategori')));
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

    final existingImage = widget.category?['image']?.toString();
    if (isEdit && existingImage != null && existingImage.isNotEmpty && existingImage != 'null') {
      return Image.network(
        '${ApiService.baseUrl.replaceAll('/api', '')}/uploads/categories/$existingImage',
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
      child: const Icon(Icons.image_outlined, color: _primary, size: 28),
    );
  }

  @override
  Widget build(BuildContext context) {
    final isEdit = widget.category != null;

    return Scaffold(
      backgroundColor: _surface,
      appBar: AppBar(
        title: Text(isEdit ? 'Edit Kategori' : 'Tambah Kategori', style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w900)),
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
                    Container(width: 42, height: 42, decoration: BoxDecoration(color: _accent.withOpacity(.16), borderRadius: BorderRadius.circular(14)), child: const Icon(Icons.category_rounded, color: _primary, size: 22)),
                    const SizedBox(width: 12),
                    Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: const [
                      Text('Data Kategori', style: TextStyle(fontSize: 14.5, fontWeight: FontWeight.w900, color: _primary)),
                      SizedBox(height: 3),
                      Text('Isi nama dan gambar kategori produk.', style: TextStyle(fontSize: 11.5, color: _muted)),
                    ])),
                  ],
                ),
              ),
              const SizedBox(height: 14),
              TextFormField(
                controller: _nameController,
                style: const TextStyle(fontSize: 13.5, fontWeight: FontWeight.w700),
                decoration: _inputDecoration('Nama Kategori', Icons.sell_outlined),
                validator: (value) => value == null || value.trim().isEmpty ? 'Nama tidak boleh kosong' : null,
              ),
              const SizedBox(height: 14),
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(18), border: Border.all(color: const Color(0xFFE2E8F0))),
                child: Row(
                  children: [
                    ClipRRect(borderRadius: BorderRadius.circular(14), child: _imagePreview(isEdit)),
                    const SizedBox(width: 12),
                    Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                      const Text('Gambar Kategori', style: TextStyle(fontSize: 13, fontWeight: FontWeight.w900, color: _primary)),
                      const SizedBox(height: 3),
                      const Text('Ukuran disarankan 1:1, maksimal gambar kecil agar cepat dimuat.', style: TextStyle(fontSize: 11, color: _muted, height: 1.3)),
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
                  onPressed: _isSaving ? null : _saveCategory,
                  style: ElevatedButton.styleFrom(backgroundColor: _primary, foregroundColor: Colors.white, elevation: 0, shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14))),
                  child: _isSaving ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2)) : Text(isEdit ? 'Update Kategori' : 'Simpan Kategori', style: const TextStyle(fontSize: 13.5, fontWeight: FontWeight.w900)),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

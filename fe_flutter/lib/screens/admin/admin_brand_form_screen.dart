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

  Widget _imagePreview(bool isEdit) {
    if (_selectedImage != null) {
      if (kIsWeb) {
        return Image.network(_selectedImage!.path, width: 80, height: 80, fit: BoxFit.cover);
      }
      return Image.file(File(_selectedImage!.path), width: 80, height: 80, fit: BoxFit.cover);
    }

    final existingImage = widget.brand?['image']?.toString();
    if (isEdit && existingImage != null && existingImage.isNotEmpty && existingImage != 'null') {
      return Image.network(
        '${ApiService.baseUrl.replaceAll('/api', '')}/uploads/brands/$existingImage',
        width: 80,
        height: 80,
        fit: BoxFit.cover,
        errorBuilder: (_, __, ___) => const Icon(Icons.image_not_supported, size: 40),
      );
    }

    return Container(width: 80, height: 80, color: Colors.grey[300], child: const Icon(Icons.image));
  }

  @override
  Widget build(BuildContext context) {
    final isEdit = widget.brand != null;

    if (_isLoading) {
      return Scaffold(
        appBar: AppBar(title: Text(isEdit ? 'Edit Brand' : 'Tambah Brand')),
        body: const Center(child: CircularProgressIndicator()),
      );
    }

    return Scaffold(
      appBar: AppBar(title: Text(isEdit ? 'Edit Brand' : 'Tambah Brand')),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              TextFormField(
                controller: _nameController,
                decoration: const InputDecoration(labelText: 'Nama Brand', border: OutlineInputBorder()),
                validator: (value) => value == null || value.trim().isEmpty ? 'Nama tidak boleh kosong' : null,
              ),
              const SizedBox(height: 15),
              DropdownButtonFormField<String>(
                decoration: const InputDecoration(labelText: 'Pilih Kategori (Opsional)', border: OutlineInputBorder()),
                value: _selectedCategoryId,
                items: _categories.map<DropdownMenuItem<String>>((cat) {
                  return DropdownMenuItem<String>(value: cat['id'].toString(), child: Text(cat['name']?.toString() ?? '-'));
                }).toList(),
                onChanged: _isSaving ? null : (value) => setState(() => _selectedCategoryId = value),
              ),
              if (_selectedCategoryId != null) ...[
                const SizedBox(height: 8),
                TextButton.icon(
                  onPressed: _isSaving ? null : () => setState(() => _selectedCategoryId = null),
                  icon: const Icon(Icons.close, size: 16),
                  label: const Text('Kosongkan kategori'),
                ),
              ],
              const SizedBox(height: 15),
              Row(
                children: [
                  ClipRRect(borderRadius: BorderRadius.circular(10), child: _imagePreview(isEdit)),
                  const SizedBox(width: 15),
                  ElevatedButton.icon(onPressed: _isSaving ? null : _pickImage, icon: const Icon(Icons.upload), label: const Text('Pilih Gambar')),
                ],
              ),
              const SizedBox(height: 30),
              SizedBox(
                width: double.infinity,
                height: 50,
                child: ElevatedButton(
                  onPressed: _isSaving ? null : _saveBrand,
                  child: _isSaving ? const CircularProgressIndicator(color: Colors.white) : Text(isEdit ? 'Update Brand' : 'Simpan Brand', style: const TextStyle(fontSize: 16)),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

import 'dart:io';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import '../../services/api_service.dart';
import 'package:flutter/foundation.dart' show kIsWeb;

class AdminBrandFormScreen extends StatefulWidget {
  final Map<String, dynamic>? brand;

  AdminBrandFormScreen({this.brand});

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
      _nameController.text = widget.brand!['name'];
      if (widget.brand!['category_id'] != null) {
        _selectedCategoryId = widget.brand!['category_id'].toString();
      }
    }
    _fetchCategories();
  }

  // Mengambil data kategori untuk dropdown
  Future<void> _fetchCategories() async {
    final categories = await ApiService.getAdminCategories();
    setState(() {
      _categories = categories;
      _isLoading = false;
    });
  }

  Future<void> _pickImage() async {
    final ImagePicker picker = ImagePicker();
    final XFile? image = await picker.pickImage(source: ImageSource.gallery);
    if (image != null) setState(() => _selectedImage = image);
  }

  Future<void> _saveBrand() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isSaving = true);

    Map<String, String> fields = {
      "name": _nameController.text,
    };
    if (_selectedCategoryId != null) {
      fields['category_id'] = _selectedCategoryId!;
    }

    bool success = await ApiService.saveAdminBrand(
      fields,
      image: _selectedImage,
      brandId: widget.brand?['id'],
    );

    setState(() => _isSaving = false);

    if (success) {
      ScaffoldMessenger.of(context)
          .showSnackBar(SnackBar(content: Text("Berhasil menyimpan brand")));
      Navigator.pop(context);
    } else {
      ScaffoldMessenger.of(context)
          .showSnackBar(SnackBar(content: Text("Gagal menyimpan brand")));
    }
  }

  @override
  Widget build(BuildContext context) {
    bool isEdit = widget.brand != null;

    if (_isLoading) {
      return Scaffold(
        appBar: AppBar(title: Text(isEdit ? "Edit Brand" : "Tambah Brand")),
        body: Center(child: CircularProgressIndicator()),
      );
    }

    return Scaffold(
      appBar: AppBar(title: Text(isEdit ? "Edit Brand" : "Tambah Brand")),
      body: SingleChildScrollView(
        padding: EdgeInsets.all(16.0),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              TextFormField(
                controller: _nameController,
                decoration: InputDecoration(
                    labelText: 'Nama Brand', border: OutlineInputBorder()),
                validator: (value) =>
                    value!.isEmpty ? 'Nama tidak boleh kosong' : null,
              ),
              SizedBox(height: 15),
              DropdownButtonFormField<String>(
                decoration: InputDecoration(
                    labelText: 'Pilih Kategori (Opsional)',
                    border: OutlineInputBorder()),
                value: _selectedCategoryId,
                items: _categories.map<DropdownMenuItem<String>>((cat) {
                  return DropdownMenuItem<String>(
                    value: cat['id'].toString(),
                    child: Text(cat['name']),
                  );
                }).toList(),
                onChanged: (value) =>
                    setState(() => _selectedCategoryId = value),
              ),
              SizedBox(height: 15),
              Row(
                children: [
                  _selectedImage != null
                      ? (kIsWeb
                          ? Image.network(_selectedImage!.path,
                              width: 80, height: 80, fit: BoxFit.cover)
                          : Image.file(File(_selectedImage!.path),
                              width: 80, height: 80, fit: BoxFit.cover))
                      : (isEdit && widget.brand!['image'] != null)
                          ? Image.network(
                              "${ApiService.baseUrl.replaceAll('/api', '')}/uploads/brands/${widget.brand!['image']}",
                              width: 80,
                              height: 80,
                              fit: BoxFit.cover,
                            )
                          : Container(
                              width: 80,
                              height: 80,
                              color: Colors.grey[300],
                              child: Icon(Icons.image)),
                  SizedBox(width: 15),
                  ElevatedButton.icon(
                    onPressed: _pickImage,
                    icon: Icon(Icons.upload),
                    label: Text("Pilih Gambar"),
                  ),
                ],
              ),
              SizedBox(height: 30),
              SizedBox(
                width: double.infinity,
                height: 50,
                child: ElevatedButton(
                  onPressed: _isSaving ? null : _saveBrand,
                  child: _isSaving
                      ? CircularProgressIndicator(color: Colors.white)
                      : Text(isEdit ? "Update Brand" : "Simpan Brand",
                          style: TextStyle(fontSize: 16)),
                ),
              )
            ],
          ),
        ),
      ),
    );
  }
}

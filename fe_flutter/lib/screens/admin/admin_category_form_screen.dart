import 'dart:io';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import '../../services/api_service.dart';
import 'package:flutter/foundation.dart' show kIsWeb;

class AdminCategoryFormScreen extends StatefulWidget {
  final Map<String, dynamic>? category;

  AdminCategoryFormScreen({this.category});

  @override
  _AdminCategoryFormScreenState createState() =>
      _AdminCategoryFormScreenState();
}

class _AdminCategoryFormScreenState extends State<AdminCategoryFormScreen> {
  final _formKey = GlobalKey<FormState>();
  final TextEditingController _nameController = TextEditingController();

  XFile? _selectedImage;
  bool _isSaving = false;

  @override
  void initState() {
    super.initState();
    if (widget.category != null) {
      _nameController.text = widget.category!['name'];
    }
  }

  Future<void> _pickImage() async {
    final ImagePicker picker = ImagePicker();
    final XFile? image = await picker.pickImage(source: ImageSource.gallery);
    if (image != null) {
      setState(() => _selectedImage = image);
    }
  }

  Future<void> _saveCategory() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isSaving = true);

    Map<String, String> fields = {
      "name": _nameController.text,
    };

    bool success = await ApiService.saveAdminCategory(
      fields,
      image: _selectedImage,
      categoryId: widget.category?['id'],
    );

    setState(() => _isSaving = false);

    if (success) {
      ScaffoldMessenger.of(context)
          .showSnackBar(SnackBar(content: Text("Berhasil menyimpan kategori")));
      Navigator.pop(context); // Kembali ke halaman sebelumnya
    } else {
      ScaffoldMessenger.of(context)
          .showSnackBar(SnackBar(content: Text("Gagal menyimpan kategori")));
    }
  }

  @override
  Widget build(BuildContext context) {
    bool isEdit = widget.category != null;

    return Scaffold(
      appBar: AppBar(title: Text(isEdit ? "Edit Kategori" : "Tambah Kategori")),
      body: SingleChildScrollView(
        padding: EdgeInsets.all(16.0),
        child: Form(
          key: _formKey,
          child: Column(
            children: [
              TextFormField(
                controller: _nameController,
                decoration: InputDecoration(
                    labelText: 'Nama Kategori', border: OutlineInputBorder()),
                validator: (value) =>
                    value!.isEmpty ? 'Nama tidak boleh kosong' : null,
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
                      : (isEdit && widget.category!['image'] != null)
                          ? Image.network(
                              "${ApiService.baseUrl.replaceAll('/api', '')}/uploads/categories/${widget.category!['image']}",
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
                  onPressed: _isSaving ? null : _saveCategory,
                  child: _isSaving
                      ? CircularProgressIndicator(color: Colors.white)
                      : Text(isEdit ? "Update Kategori" : "Simpan Kategori",
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

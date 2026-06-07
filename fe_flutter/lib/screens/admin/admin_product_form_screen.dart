import 'dart:io';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import '../../services/api_service.dart';

class AdminProductFormScreen extends StatefulWidget {
  final Map<String, dynamic>? product; // Jika null = Tambah, Jika ada isi = Edit

  const AdminProductFormScreen({Key? key, this.product}) : super(key: key);

  @override
  State<AdminProductFormScreen> createState() => _AdminProductFormScreenState();
}

class _AdminProductFormScreenState extends State<AdminProductFormScreen> {
  final _formKey = GlobalKey<FormState>();
  bool isSaving = false;
  bool isLoadingData = true;

  List<dynamic> categories = [];
  List<dynamic> brands = [];

  // Controllers
  final _nameCtrl = TextEditingController();
  final _shortDescCtrl = TextEditingController();
  final _descCtrl = TextEditingController();
  final _priceCtrl = TextEditingController();
  final _salePriceCtrl = TextEditingController(); // Baru
  final _qtyCtrl = TextEditingController();
  final _weightCtrl = TextEditingController(); // Baru
  final _expDateCtrl = TextEditingController(); // Baru

  String? _selectedCategory;
  String? _selectedBrand;
  String _stockStatus = 'instock';

  // Image Upload Variables
  File? _mainImage;
  List<File> _galleryImages = [];
  final ImagePicker _picker = ImagePicker();

  @override
  void initState() {
    super.initState();
    _loadDropdownData().then((_) {
      if (widget.product != null) {
        _setupEditData();
      }
    });
  }

  Future<void> _loadDropdownData() async {
    final fetchedCategories = await ApiService.getAdminCategories();
    final fetchedBrands = await ApiService.getAdminBrands();
    setState(() {
      categories = fetchedCategories;
      brands = fetchedBrands;
      isLoadingData = false;
    });
  }

  void _setupEditData() {
    final p = widget.product!;
    _nameCtrl.text = p['name'] ?? '';
    _shortDescCtrl.text = p['short_description'] ?? '';
    _descCtrl.text = p['description'] ?? '';
    _priceCtrl.text = p['regular_price']?.toString() ?? '';
    _salePriceCtrl.text = p['sale_price']?.toString() ?? '';
    _qtyCtrl.text = p['quantity']?.toString() ?? '';
    _weightCtrl.text = p['weight']?.toString() ?? '';
    
    // Format Tanggal Kadaluarsa
    if (p['exp_date'] != null) {
      // Mengambil bagian "YYYY-MM-DD" saja jika ada timestamp
      _expDateCtrl.text = p['exp_date'].toString().split(' ')[0]; 
    }
    
    _stockStatus = p['stock_status'] ?? 'instock';

    if (categories.any((c) => c['id'] == p['category_id'])) {
      _selectedCategory = p['category_id'].toString();
    }
    if (brands.any((b) => b['id'] == p['brand_id'])) {
      _selectedBrand = p['brand_id'].toString();
    }
    setState(() {});
  }

  // --- Fungsi Pilih Gambar Utama ---
  Future<void> _pickMainImage() async {
    final XFile? picked = await _picker.pickImage(source: ImageSource.gallery);
    if (picked != null) {
      setState(() => _mainImage = File(picked.path));
    }
  }

  // --- Fungsi Pilih Galeri Gambar ---
  Future<void> _pickGalleryImages() async {
    final List<XFile> picked = await _picker.pickMultiImage();
    if (picked.isNotEmpty) {
      setState(() {
        _galleryImages.addAll(picked.map((e) => File(e.path)));
      });
    }
  }

  // --- Fungsi Pilih Tanggal ---
  Future<void> _pickExpDate() async {
    DateTime? picked = await showDatePicker(
      context: context,
      initialDate: DateTime.now(),
      firstDate: DateTime.now(),
      lastDate: DateTime(2030),
    );
    if (picked != null) {
      setState(() {
        _expDateCtrl.text = "${picked.year}-${picked.month.toString().padLeft(2, '0')}-${picked.day.toString().padLeft(2, '0')}";
      });
    }
  }

  Future<void> _saveProduct() async {
    if (!_formKey.currentState!.validate()) return;
    if (_selectedCategory == null || _selectedBrand == null) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Pilih Kategori dan Brand!')));
      return;
    }

    setState(() => isSaving = true);

    // Semua field string/text diubah jadi String
    Map<String, String> productFields = {
      "name": _nameCtrl.text,
      "short_description": _shortDescCtrl.text,
      "description": _descCtrl.text,
      "regular_price": _priceCtrl.text,
      "sale_price": _salePriceCtrl.text,
      "weight": _weightCtrl.text,
      "exp_date": _expDateCtrl.text,
      "stock_status": _stockStatus,
      "quantity": _qtyCtrl.text,
      "category_id": _selectedCategory!,
      "brand_id": _selectedBrand!,
    };

    bool success = await ApiService.saveAdminProduct(
      productFields,
      mainImage: _mainImage,
      galleryImages: _galleryImages,
      productId: widget.product?['id'], // Kirim ID jika ini mode edit
    );

    setState(() => isSaving = false);

    if (success) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(widget.product == null ? "Produk berhasil ditambahkan!" : "Produk berhasil diperbarui!")));
      Navigator.pop(context, true); 
    } else {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("Gagal menyimpan produk!")));
    }
  }

  @override
  Widget build(BuildContext context) {
    bool isEdit = widget.product != null;

    return Scaffold(
      appBar: AppBar(
        title: Text(isEdit ? "Edit Produk" : "Tambah Produk Baru"),
        backgroundColor: Colors.indigo,
        foregroundColor: Colors.white,
      ),
      body: isLoadingData
          ? const Center(child: CircularProgressIndicator())
          : SingleChildScrollView(
              padding: const EdgeInsets.all(16.0),
              child: Form(
                key: _formKey,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    // --- SECTION UNGGAH GAMBAR ---
                    const Text("Gambar Utama", style: TextStyle(fontWeight: FontWeight.bold)),
                    const SizedBox(height: 8),
                    GestureDetector(
                      onTap: _pickMainImage,
                      child: Container(
                        height: 150,
                        decoration: BoxDecoration(
                          color: Colors.grey.shade200,
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(color: Colors.grey),
                        ),
                        child: _mainImage != null
                            ? ClipRRect(borderRadius: BorderRadius.circular(12), child: Image.file(_mainImage!, fit: BoxFit.cover))
                            : isEdit && widget.product!['image'] != null
                                ? ClipRRect(
                                    borderRadius: BorderRadius.circular(12),
                                    child: Image.network("http://127.0.0.1:8000/uploads/products/${widget.product!['image']}", fit: BoxFit.cover),
                                  )
                                : const Column(
                                    mainAxisAlignment: MainAxisAlignment.center,
                                    children: [Icon(Icons.add_a_photo, size: 40, color: Colors.grey), Text("Ketuk untuk Unggah Gambar")],
                                  ),
                      ),
                    ),
                    const SizedBox(height: 16),

                    // --- SECTION GALERI GAMBAR ---
                    const Text("Galeri Gambar", style: TextStyle(fontWeight: FontWeight.bold)),
                    const SizedBox(height: 8),
                    Wrap(
                      spacing: 8,
                      runSpacing: 8,
                      children: [
                        ..._galleryImages.map((img) => Stack(
                              alignment: Alignment.topRight,
                              children: [
                                ClipRRect(borderRadius: BorderRadius.circular(8), child: Image.file(img, width: 80, height: 80, fit: BoxFit.cover)),
                                GestureDetector(
                                  onTap: () => setState(() => _galleryImages.remove(img)),
                                  child: const CircleAvatar(radius: 12, backgroundColor: Colors.red, child: Icon(Icons.close, size: 14, color: Colors.white)),
                                )
                              ],
                            )),
                        GestureDetector(
                          onTap: _pickGalleryImages,
                          child: Container(
                            width: 80, height: 80,
                            decoration: BoxDecoration(color: Colors.grey.shade200, borderRadius: BorderRadius.circular(8), border: Border.all(color: Colors.grey)),
                            child: const Icon(Icons.add_photo_alternate, color: Colors.grey),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 24),

                    // --- SECTION FORM TEKS ---
                    _buildTextField("Nama Produk", _nameCtrl),
                    _buildTextField("Deskripsi Singkat", _shortDescCtrl, maxLines: 2),
                    _buildTextField("Deskripsi Lengkap", _descCtrl, maxLines: 4),
                    
                    Row(
                      children: [
                        Expanded(child: _buildTextField("Harga Reguler (Rp)", _priceCtrl, isNumber: true)),
                        const SizedBox(width: 16),
                        Expanded(child: _buildTextField("Harga Promo (Rp)", _salePriceCtrl, isNumber: true, isRequired: false)),
                      ],
                    ),

                    Row(
                      children: [
                        Expanded(child: _buildTextField("Kuantitas Stok", _qtyCtrl, isNumber: true)),
                        const SizedBox(width: 16),
                        Expanded(child: _buildTextField("Berat (Gram)", _weightCtrl, isNumber: true)),
                      ],
                    ),

                    // --- SECTION TANGGAL KADALUARSA ---
                    const SizedBox(height: 8),
                    TextFormField(
                      controller: _expDateCtrl,
                      readOnly: true,
                      onTap: _pickExpDate,
                      decoration: const InputDecoration(
                        labelText: "Tanggal Kadaluarsa (Opsional)",
                        border: OutlineInputBorder(),
                        suffixIcon: Icon(Icons.calendar_today),
                      ),
                    ),
                    const SizedBox(height: 16),

                    // --- SECTION DROPDOWN KATEGORI, BRAND & STATUS ---
                    DropdownButtonFormField<String>(
                      decoration: const InputDecoration(labelText: "Kategori", border: OutlineInputBorder()),
                      value: _selectedCategory,
                      items: categories.map<DropdownMenuItem<String>>((cat) {
                        return DropdownMenuItem<String>(value: cat['id'].toString(), child: Text(cat['name']));
                      }).toList(),
                      onChanged: (val) => setState(() => _selectedCategory = val),
                    ),
                    const SizedBox(height: 16),

                    DropdownButtonFormField<String>(
                      decoration: const InputDecoration(labelText: "Brand", border: OutlineInputBorder()),
                      value: _selectedBrand,
                      items: brands.map<DropdownMenuItem<String>>((brand) {
                        return DropdownMenuItem<String>(value: brand['id'].toString(), child: Text(brand['name']));
                      }).toList(),
                      onChanged: (val) => setState(() => _selectedBrand = val),
                    ),
                    const SizedBox(height: 16),

                    DropdownButtonFormField<String>(
                      decoration: const InputDecoration(labelText: "Status Stok", border: OutlineInputBorder()),
                      value: _stockStatus,
                      items: const [
                        DropdownMenuItem(value: "instock", child: Text("Tersedia (In Stock)")),
                        DropdownMenuItem(value: "outofstock", child: Text("Habis (Out of Stock)")),
                      ],
                      onChanged: (val) => setState(() => _stockStatus = val!),
                    ),

                    const SizedBox(height: 32),
                    
                    // --- TOMBOL SIMPAN ---
                    isSaving
                        ? const Center(child: CircularProgressIndicator())
                        : ElevatedButton.icon(
                            style: ElevatedButton.styleFrom(backgroundColor: Colors.indigo, foregroundColor: Colors.white, padding: const EdgeInsets.symmetric(vertical: 16)),
                            onPressed: _saveProduct,
                            icon: const Icon(Icons.save),
                            label: const Text("Simpan Produk", style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                          )
                  ],
                ),
              ),
            ),
    );
  }

  Widget _buildTextField(String label, TextEditingController controller, {bool isNumber = false, int maxLines = 1, bool isRequired = true}) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 16.0),
      child: TextFormField(
        controller: controller,
        keyboardType: isNumber ? TextInputType.number : TextInputType.text,
        maxLines: maxLines,
        decoration: InputDecoration(labelText: label, border: const OutlineInputBorder()),
        validator: (val) {
          if (isRequired && (val == null || val.isEmpty)) {
            return "$label wajib diisi";
          }
          return null;
        },
      ),
    );
  }
}
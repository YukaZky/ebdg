// ignore_for_file: avoid_print

import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import '../../services/api_service.dart';

class VariationInput {
  int? id; 
  String name = '';
  XFile? image;
  String? existingImageUrl; 
  String regularPrice = '';
  String salePrice = '';
  String weight = '';
  String quantity = '';
}

class AdminProductFormScreen extends StatefulWidget {
  final Map<String, dynamic>? product;

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

  final _nameCtrl = TextEditingController();
  final _shortDescCtrl = TextEditingController();
  final _descCtrl = TextEditingController();
  final _priceCtrl = TextEditingController();
  final _salePriceCtrl = TextEditingController();
  final _qtyCtrl = TextEditingController();
  final _weightCtrl = TextEditingController(); 
  final _expDateCtrl = TextEditingController();

  String? _selectedCategory;
  String? _selectedBrand;
  String _stockStatus = 'instock';

  List<VariationInput> variations = [];
  
  XFile? _mainImage;
  List<XFile> _galleryImages = []; 
  List<dynamic> _existingGalleryImages = []; 
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

  String _cleanNumber(dynamic value) {
    if (value == null || value.toString() == 'null' || value.toString().isEmpty) return '';
    double? d = double.tryParse(value.toString());
    return (d != null && d == d.toInt()) ? d.toInt().toString() : value.toString();
  }

  void _setupEditData() {
    final p = widget.product!;
    _nameCtrl.text = p['name'] ?? '';
    _shortDescCtrl.text = p['short_description']?.toString() == 'null' ? '' : (p['short_description'] ?? '');
    _descCtrl.text = p['description']?.toString() == 'null' ? '' : (p['description'] ?? '');
    
    _priceCtrl.text = _cleanNumber(p['regular_price']);
    _salePriceCtrl.text = _cleanNumber(p['sale_price']);
    _qtyCtrl.text = _cleanNumber(p['quantity']);
    _weightCtrl.text = _cleanNumber(p['weight']);
    
    if (p['exp_date'] != null && p['exp_date'].toString() != 'null') {
      _expDateCtrl.text = p['exp_date'].toString().split(' ')[0]; 
    }
    
    _stockStatus = p['stock_status'] ?? 'instock';

    if (categories.any((c) => c['id'].toString() == p['category_id'].toString())) {
      _selectedCategory = p['category_id'].toString();
    }
    if (brands.any((b) => b['id'].toString() == p['brand_id'].toString())) {
      _selectedBrand = p['brand_id'].toString();
    }

    if (p['images'] != null) {
      _existingGalleryImages = List<dynamic>.from(p['images']);
    } else if (p['product_images'] != null) {
      _existingGalleryImages = List<dynamic>.from(p['product_images']);
    }

    if (p['variations'] != null) {
      for (var v in p['variations']) {
        final varInput = VariationInput();
        varInput.id = v['id']; 
        varInput.name = v['name'] ?? '';
        varInput.existingImageUrl = v['image'];
        varInput.regularPrice = _cleanNumber(v['regular_price']);
        varInput.salePrice = _cleanNumber(v['sale_price']);
        varInput.weight = _cleanNumber(v['weight']);
        varInput.quantity = _cleanNumber(v['quantity']);
        variations.add(varInput);
      }
    }
    
    setState(() {});
  }

  Future<void> _pickMainImage() async {
    try {
      final XFile? picked = await _picker.pickImage(source: ImageSource.gallery);
      if (picked != null) setState(() => _mainImage = picked);
    } catch (e) {
      print("Gagal mengambil gambar: $e");
    }
  }

  Future<void> _pickGalleryImages() async {
    try {
      final List<XFile> picked = await _picker.pickMultiImage();
      if (picked.isNotEmpty) setState(() => _galleryImages.addAll(picked));
    } catch (e) {
      print("Gagal mengambil galeri gambar: $e");
    }
  }

  Future<void> _pickVariationImage(int index) async {
    try {
      final XFile? picked = await _picker.pickImage(source: ImageSource.gallery);
      if (picked != null) {
        setState(() {
          variations[index].image = picked;
          variations[index].existingImageUrl = null; 
        });
      }
    } catch (e) {
      print("Gagal mengambil gambar variasi: $e");
    }
  }

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
    
    if (variations.any((v) => v.name.trim().isEmpty)) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Semua nama variasi wajib diisi!')));
      return;
    }

    setState(() => isSaving = true);

    Map<String, String> productFields = {
      "name": _nameCtrl.text,
      "short_description": _shortDescCtrl.text,
      "description": _descCtrl.text,
      "regular_price": _priceCtrl.text.isEmpty ? "0" : _priceCtrl.text,
      "weight": _weightCtrl.text.isEmpty ? "0" : _weightCtrl.text,
      "stock_status": _stockStatus,
      "quantity": _qtyCtrl.text.isEmpty ? "0" : _qtyCtrl.text,
      "category_id": _selectedCategory ?? "",
      "brand_id": _selectedBrand ?? "",
    };

    if (_salePriceCtrl.text.isNotEmpty) productFields["sale_price"] = _salePriceCtrl.text;
    if (_expDateCtrl.text.isNotEmpty) productFields["exp_date"] = _expDateCtrl.text;

    List<String> variationNames = variations.map((v) => v.name).toList();
    List<XFile?> variationImages = variations.map((v) => v.image).toList();
    List<String> variationIds = variations.map((v) => v.id?.toString() ?? '').toList();
    List<String> variationRegularPrices = variations.map((v) => v.regularPrice).toList();
    List<String> variationSalePrices = variations.map((v) => v.salePrice).toList();
    List<String> variationWeights = variations.map((v) => v.weight).toList();
    List<String> variationQuantities = variations.map((v) => v.quantity).toList();

    // Merekam ID Gambar Galeri yang TIDAK Dihapus oleh User
    List<String> keptGalleryIds = _existingGalleryImages.map((img) => img['id'].toString()).toList();

    bool success = await ApiService.saveAdminProduct(
      productFields,
      mainImage: _mainImage,
      galleryImages: _galleryImages,
      keptGalleryImageIds: keptGalleryIds,
      productId: widget.product?['id'],
      variationNames: variationNames,
      variationImages: variationImages,
      variationIds: variationIds,
      variationRegularPrices: variationRegularPrices,
      variationSalePrices: variationSalePrices,
      variationWeights: variationWeights,
      variationQuantities: variationQuantities,
    );

    setState(() => isSaving = false);

    if (success) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(widget.product == null ? "Produk berhasil ditambahkan!" : "Produk berhasil diperbarui!")));
      Navigator.pop(context, true); 
    } else {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("Gagal menyimpan produk!")));
    }
  }

  Widget _buildImage(XFile file) {
    if (kIsWeb) return Image.network(file.path, fit: BoxFit.cover); 
    return Image.file(File(file.path), fit: BoxFit.cover);
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
                            ? ClipRRect(borderRadius: BorderRadius.circular(12), child: _buildImage(_mainImage!))
                            : isEdit && widget.product!['image'] != null && widget.product!['image'].toString().isNotEmpty
                                ? ClipRRect(
                                    borderRadius: BorderRadius.circular(12),
                                    child: Image.network("http://127.0.0.1:8000/uploads/products/${widget.product!['image']}", fit: BoxFit.cover),
                                  )
                                : const Column(
                                    mainAxisAlignment: MainAxisAlignment.center,
                                    children: [Icon(Icons.add_a_photo, size: 40, color: Colors.grey), Text("Ketuk untuk Unggah Gambar Utama")],
                                  ),
                      ),
                    ),
                    const SizedBox(height: 16),

                    const Text("Galeri Gambar (Opsional)", style: TextStyle(fontWeight: FontWeight.bold)),
                    const SizedBox(height: 8),
                    Wrap(
                      spacing: 8,
                      runSpacing: 8,
                      children: [
                        // Tampilkan Gambar Galeri Existing (Dengan Tombol Delete)
                        ..._existingGalleryImages.map((imgData) {
                          String imgUrl = imgData['image'] ?? '';
                          return Stack(
                            alignment: Alignment.topRight,
                            children: [
                              SizedBox(
                                width: 80, height: 80, 
                                child: ClipRRect(
                                  borderRadius: BorderRadius.circular(8), 
                                  child: Image.network(
                                    "http://127.0.0.1:8000/uploads/products/$imgUrl", 
                                    fit: BoxFit.cover,
                                    errorBuilder: (c, e, s) => Container(color: Colors.grey.shade300, child: const Icon(Icons.broken_image, color: Colors.grey)),
                                  )
                                )
                              ),
                              GestureDetector(
                                onTap: () => setState(() => _existingGalleryImages.remove(imgData)),
                                child: const CircleAvatar(radius: 12, backgroundColor: Colors.red, child: Icon(Icons.close, size: 14, color: Colors.white)),
                              )
                            ],
                          );
                        }),
                        
                        // Tampilkan Gambar Galeri Baru
                        ..._galleryImages.map((img) => Stack(
                              alignment: Alignment.topRight,
                              children: [
                                SizedBox(
                                  width: 80, height: 80, 
                                  child: ClipRRect(borderRadius: BorderRadius.circular(8), child: _buildImage(img))
                                ),
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

                    _buildTextField("Nama Produk", _nameCtrl),
                    _buildTextField("Deskripsi Singkat", _shortDescCtrl, maxLines: 2, isRequired: false),
                    _buildTextField("Deskripsi Lengkap", _descCtrl, maxLines: 4, isRequired: false),
                    
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
                        Expanded(child: _buildTextField("Berat Total (Gram)", _weightCtrl, isNumber: true)),
                      ],
                    ),

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

                    const Text("Variasi Warna / Jenis Produk", style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                    const SizedBox(height: 8),
                    Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: Colors.blue.shade50,
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: Colors.blue.shade200),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          ...variations.asMap().entries.map((entry) {
                            int index = entry.key;
                            VariationInput variation = entry.value;
                            return Card(
                              elevation: 1,
                              margin: const EdgeInsets.only(bottom: 16.0),
                              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                              child: Padding(
                                padding: const EdgeInsets.all(12.0),
                                child: Column(
                                  children: [
                                    Row(
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      children: [
                                        GestureDetector(
                                          onTap: () => _pickVariationImage(index),
                                          child: Container(
                                            width: 55,
                                            height: 55,
                                            decoration: BoxDecoration(
                                              color: Colors.white,
                                              borderRadius: BorderRadius.circular(8),
                                              border: Border.all(color: Colors.grey.shade400),
                                            ),
                                            child: variation.image != null
                                                ? ClipRRect(borderRadius: BorderRadius.circular(8), child: _buildImage(variation.image!))
                                                : variation.existingImageUrl != null
                                                    ? ClipRRect(
                                                        borderRadius: BorderRadius.circular(8),
                                                        child: Image.network("http://127.0.0.1:8000/uploads/products/${variation.existingImageUrl}", fit: BoxFit.cover),
                                                      )
                                                    : const Icon(Icons.add_photo_alternate, color: Colors.grey, size: 22),
                                          ),
                                        ),
                                        const SizedBox(width: 12),
                                        Expanded(
                                          child: TextFormField(
                                            initialValue: variation.name,
                                            onChanged: (val) => variation.name = val,
                                            decoration: const InputDecoration(
                                              labelText: "Nama Variasi (Misal: Merah / XL)",
                                              border: OutlineInputBorder(),
                                              contentPadding: EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                                            ),
                                          ),
                                        ),
                                        IconButton(
                                          icon: const Icon(Icons.delete_outline, color: Colors.red),
                                          onPressed: () => setState(() => variations.removeAt(index)),
                                        )
                                      ],
                                    ),
                                    const SizedBox(height: 12),
                                    Row(
                                      children: [
                                        Expanded(
                                          child: TextFormField(
                                            initialValue: variation.regularPrice,
                                            keyboardType: TextInputType.number,
                                            onChanged: (val) => variation.regularPrice = val,
                                            decoration: const InputDecoration(
                                              labelText: "Harga Reguler (Rp)",
                                              border: OutlineInputBorder(),
                                              contentPadding: EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                                            ),
                                          ),
                                        ),
                                        const SizedBox(width: 8),
                                        Expanded(
                                          child: TextFormField(
                                            initialValue: variation.salePrice,
                                            keyboardType: TextInputType.number,
                                            onChanged: (val) => variation.salePrice = val,
                                            decoration: const InputDecoration(
                                              labelText: "Harga Promo (Rp)",
                                              border: OutlineInputBorder(),
                                              contentPadding: EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                                            ),
                                          ),
                                        ),
                                      ],
                                    ),
                                    const SizedBox(height: 12),
                                    Row(
                                      children: [
                                        Expanded(
                                          child: TextFormField(
                                            initialValue: variation.weight,
                                            keyboardType: TextInputType.number,
                                            onChanged: (val) => variation.weight = val,
                                            decoration: const InputDecoration(
                                              labelText: "Berat (Gram)",
                                              border: OutlineInputBorder(),
                                              contentPadding: EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                                            ),
                                          ),
                                        ),
                                        const SizedBox(width: 8),
                                        Expanded(
                                          child: TextFormField(
                                            initialValue: variation.quantity,
                                            keyboardType: TextInputType.number,
                                            onChanged: (val) => variation.quantity = val,
                                            decoration: const InputDecoration(
                                              labelText: "Stok Variasi",
                                              border: OutlineInputBorder(),
                                              contentPadding: EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                                            ),
                                          ),
                                        ),
                                      ],
                                    ),
                                  ],
                                ),
                              ),
                            );
                          }).toList(),
                          ElevatedButton.icon(
                            style: ElevatedButton.styleFrom(
                              backgroundColor: Colors.white,
                              foregroundColor: Colors.indigo,
                              elevation: 0,
                              side: const BorderSide(color: Colors.indigo),
                            ),
                            onPressed: () => setState(() => variations.add(VariationInput())),
                            icon: const Icon(Icons.add),
                            label: const Text("Tambah Variasi Baru"),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 32),

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
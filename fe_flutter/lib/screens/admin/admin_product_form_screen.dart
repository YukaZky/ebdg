import 'package:flutter/material.dart';
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

  final _nameCtrl = TextEditingController();
  final _shortDescCtrl = TextEditingController();
  final _descCtrl = TextEditingController();
  final _priceCtrl = TextEditingController();
  final _qtyCtrl = TextEditingController();

  String? _selectedCategory;
  String? _selectedBrand;
  String _stockStatus = 'instock';

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
    _qtyCtrl.text = p['quantity']?.toString() ?? '';
    _stockStatus = p['stock_status'] ?? 'instock';

    // Set dropdown jika ID tersedia di list
    if (categories.any((c) => c['id'] == p['category_id'])) {
      _selectedCategory = p['category_id'].toString();
    }
    if (brands.any((b) => b['id'] == p['brand_id'])) {
      _selectedBrand = p['brand_id'].toString();
    }
    setState(() {});
  }

  Future<void> _saveProduct() async {
    if (!_formKey.currentState!.validate()) return;
    if (_selectedCategory == null || _selectedBrand == null) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Pilih Kategori dan Brand!')));
      return;
    }

    setState(() => isSaving = true);

    Map<String, dynamic> productData = {
      "name": _nameCtrl.text,
      "short_description": _shortDescCtrl.text,
      "description": _descCtrl.text,
      "regular_price": _priceCtrl.text,
      "stock_status": _stockStatus,
      "quantity": _qtyCtrl.text,
      "category_id": _selectedCategory,
      "brand_id": _selectedBrand,
    };

    bool success;
    if (widget.product == null) {
      // Tambah Baru
      success = await ApiService.addAdminProduct(productData);
    } else {
      // Update Lama
      success = await ApiService.updateAdminProduct(widget.product!['id'], productData);
    }

    setState(() => isSaving = false);

    if (success) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(widget.product == null ? "Produk berhasil ditambahkan!" : "Produk berhasil diperbarui!")));
      Navigator.pop(context, true); // Kembali & beritahu ada perubahan
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
                    _buildTextField("Nama Produk", _nameCtrl),
                    _buildTextField("Deskripsi Singkat", _shortDescCtrl, maxLines: 2),
                    _buildTextField("Deskripsi Lengkap", _descCtrl, maxLines: 4),
                    
                    Row(
                      children: [
                        Expanded(child: _buildTextField("Harga Normal (Rp)", _priceCtrl, isNumber: true)),
                        const SizedBox(width: 16),
                        Expanded(child: _buildTextField("Kuantitas Stok", _qtyCtrl, isNumber: true)),
                      ],
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
                    isSaving
                        ? const Center(child: CircularProgressIndicator())
                        : ElevatedButton(
                            style: ElevatedButton.styleFrom(backgroundColor: Colors.indigo, foregroundColor: Colors.white, padding: const EdgeInsets.symmetric(vertical: 16)),
                            onPressed: _saveProduct,
                            child: const Text("Simpan Produk", style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                          )
                  ],
                ),
              ),
            ),
    );
  }

  Widget _buildTextField(String label, TextEditingController controller, {bool isNumber = false, int maxLines = 1}) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 16.0),
      child: TextFormField(
        controller: controller,
        keyboardType: isNumber ? TextInputType.number : TextInputType.text,
        maxLines: maxLines,
        decoration: InputDecoration(labelText: label, border: const OutlineInputBorder()),
        validator: (val) => val!.isEmpty ? "$label wajib diisi" : null,
      ),
    );
  }
}
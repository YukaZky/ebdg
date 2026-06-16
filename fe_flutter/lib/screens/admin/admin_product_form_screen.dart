// ignore_for_file: avoid_print

import 'dart:typed_data';
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

  XFile? _mainImage;
  final List<VariationInput> variations = [];
  final ImagePicker _picker = ImagePicker();
  final Map<String, Future<Uint8List>> _pickedImageBytesCache = {};

  @override
  void initState() {
    super.initState();
    _loadDropdownData().then((_) {
      if (widget.product != null) _setupEditData();
    });
  }

  Future<void> _loadDropdownData() async {
    final fetchedCategories = await ApiService.getAdminCategories();
    final fetchedBrands = await ApiService.getAdminBrands();
    if (!mounted) return;
    setState(() {
      categories = fetchedCategories;
      brands = fetchedBrands;
      isLoadingData = false;
    });
  }

  String _cleanNumber(dynamic value) {
    if (value == null || value.toString() == 'null' || value.toString().isEmpty) return '';
    final number = double.tryParse(value.toString());
    return (number != null && number == number.toInt()) ? number.toInt().toString() : value.toString();
  }

  String _productImageUrl(dynamic image) {
    final value = image?.toString().trim() ?? '';
    if (value.isEmpty || value == 'null') return '';
    if (value.startsWith('http://') || value.startsWith('https://')) return value;

    final base = ApiService.baseUrl.replaceFirst(RegExp(r'/api/?$'), '');
    final cleanValue = value.startsWith('/') ? value.substring(1) : value;
    if (cleanValue.startsWith('uploads/') || cleanValue.startsWith('storage/')) return '$base/$cleanValue';
    return '$base/uploads/products/$cleanValue';
  }

  Future<Uint8List> _readPickedImageBytes(XFile file) {
    final key = '${file.name}_${file.path}_${file.mimeType ?? ''}';
    return _pickedImageBytesCache.putIfAbsent(key, () => file.readAsBytes());
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

    if (p['variations'] != null) {
      for (final v in p['variations']) {
        final input = VariationInput();
        input.id = v['id'];
        input.name = v['name'] ?? '';
        input.existingImageUrl = v['image'];
        input.regularPrice = _cleanNumber(v['regular_price']);
        input.salePrice = _cleanNumber(v['sale_price']);
        input.weight = _cleanNumber(v['weight']);
        input.quantity = _cleanNumber(v['quantity']);
        variations.add(input);
      }
    }

    setState(() {});
  }

  Future<void> _pickMainImage() async {
    try {
      final picked = await _picker.pickImage(source: ImageSource.gallery);
      if (picked != null) setState(() => _mainImage = picked);
    } catch (e) {
      print('Gagal mengambil gambar utama: $e');
    }
  }

  Future<void> _pickVariationImage(int index) async {
    try {
      final picked = await _picker.pickImage(source: ImageSource.gallery);
      if (picked != null) {
        setState(() {
          variations[index].image = picked;
          variations[index].existingImageUrl = null;
        });
      }
    } catch (e) {
      print('Gagal mengambil gambar variasi: $e');
    }
  }

  Future<void> _pickExpDate() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: DateTime.now(),
      firstDate: DateTime.now(),
      lastDate: DateTime(2030),
    );
    if (picked != null) {
      setState(() {
        _expDateCtrl.text = '${picked.year}-${picked.month.toString().padLeft(2, '0')}-${picked.day.toString().padLeft(2, '0')}';
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

    final fields = <String, String>{
      'name': _nameCtrl.text,
      'short_description': _shortDescCtrl.text,
      'description': _descCtrl.text,
      'regular_price': _priceCtrl.text.isEmpty ? '0' : _priceCtrl.text,
      'weight': _weightCtrl.text.isEmpty ? '0' : _weightCtrl.text,
      'stock_status': _stockStatus,
      'quantity': _qtyCtrl.text.isEmpty ? '0' : _qtyCtrl.text,
      'category_id': _selectedCategory ?? '',
      'brand_id': _selectedBrand ?? '',
    };

    if (_salePriceCtrl.text.isNotEmpty) fields['sale_price'] = _salePriceCtrl.text;
    if (_expDateCtrl.text.isNotEmpty) fields['exp_date'] = _expDateCtrl.text;

    final success = await ApiService.saveAdminProduct(
      fields,
      mainImage: _mainImage,
      productId: widget.product?['id'],
      variationNames: variations.map((v) => v.name).toList(),
      variationImages: variations.map((v) => v.image).toList(),
      variationIds: variations.map((v) => v.id?.toString() ?? '').toList(),
      variationRegularPrices: variations.map((v) => v.regularPrice).toList(),
      variationSalePrices: variations.map((v) => v.salePrice).toList(),
      variationWeights: variations.map((v) => v.weight).toList(),
      variationQuantities: variations.map((v) => v.quantity).toList(),
    );

    if (!mounted) return;
    setState(() => isSaving = false);

    if (success) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(widget.product == null ? 'Produk berhasil ditambahkan!' : 'Produk berhasil diperbarui!')));
      Navigator.pop(context, true);
    } else {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Gagal menyimpan produk!')));
    }
  }

  Widget _pickedImage(XFile file) {
    return FutureBuilder<Uint8List>(
      future: _readPickedImageBytes(file),
      builder: (context, snapshot) {
        if (!snapshot.hasData) {
          return Container(color: Colors.grey.shade200, child: const Center(child: CircularProgressIndicator(strokeWidth: 2)));
        }
        return Image.memory(snapshot.data!, fit: BoxFit.cover, gaplessPlayback: true);
      },
    );
  }

  Widget _networkImage(dynamic image, {double? width, double? height}) {
    final url = _productImageUrl(image);
    if (url.isEmpty) return const Icon(Icons.image_not_supported, color: Colors.grey);
    return Image.network(
      url,
      width: width,
      height: height,
      fit: BoxFit.cover,
      errorBuilder: (_, __, ___) => const Icon(Icons.broken_image, color: Colors.grey),
    );
  }

  @override
  Widget build(BuildContext context) {
    final isEdit = widget.product != null;

    return Scaffold(
      appBar: AppBar(
        title: Text(isEdit ? 'Edit Produk' : 'Tambah Produk Baru'),
        backgroundColor: Colors.indigo,
        foregroundColor: Colors.white,
      ),
      body: isLoadingData
          ? const Center(child: CircularProgressIndicator())
          : SingleChildScrollView(
              padding: const EdgeInsets.all(16),
              child: Form(
                key: _formKey,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    const Text('Gambar Utama', style: TextStyle(fontWeight: FontWeight.bold)),
                    const SizedBox(height: 8),
                    GestureDetector(
                      onTap: _pickMainImage,
                      child: Container(
                        height: 150,
                        clipBehavior: Clip.antiAlias,
                        decoration: BoxDecoration(color: Colors.grey.shade200, borderRadius: BorderRadius.circular(12), border: Border.all(color: Colors.grey)),
                        child: _mainImage != null
                            ? _pickedImage(_mainImage!)
                            : isEdit && _productImageUrl(widget.product!['image']).isNotEmpty
                                ? _networkImage(widget.product!['image'])
                                : const Column(mainAxisAlignment: MainAxisAlignment.center, children: [Icon(Icons.add_a_photo, size: 40, color: Colors.grey), Text('Ketuk untuk Unggah Gambar Utama')]),
                      ),
                    ),
                    const SizedBox(height: 24),
                    _field('Nama Produk', _nameCtrl),
                    _field('Deskripsi Singkat', _shortDescCtrl, maxLines: 2, requiredField: false),
                    _field('Deskripsi Lengkap', _descCtrl, maxLines: 4, requiredField: false),
                    Row(children: [
                      Expanded(child: _field('Harga Reguler (Rp)', _priceCtrl, number: true)),
                      const SizedBox(width: 16),
                      Expanded(child: _field('Harga Promo (Rp)', _salePriceCtrl, number: true, requiredField: false)),
                    ]),
                    Row(children: [
                      Expanded(child: _field('Kuantitas Stok', _qtyCtrl, number: true)),
                      const SizedBox(width: 16),
                      Expanded(child: _field('Berat Total (Gram)', _weightCtrl, number: true)),
                    ]),
                    TextFormField(
                      controller: _expDateCtrl,
                      readOnly: true,
                      onTap: _pickExpDate,
                      decoration: const InputDecoration(labelText: 'Tanggal Kadaluarsa (Opsional)', border: OutlineInputBorder(), suffixIcon: Icon(Icons.calendar_today)),
                    ),
                    const SizedBox(height: 16),
                    DropdownButtonFormField<String>(
                      decoration: const InputDecoration(labelText: 'Kategori', border: OutlineInputBorder()),
                      value: _selectedCategory,
                      items: categories.map<DropdownMenuItem<String>>((cat) => DropdownMenuItem(value: cat['id'].toString(), child: Text(cat['name']))).toList(),
                      onChanged: (val) => setState(() => _selectedCategory = val),
                    ),
                    const SizedBox(height: 16),
                    DropdownButtonFormField<String>(
                      decoration: const InputDecoration(labelText: 'Brand', border: OutlineInputBorder()),
                      value: _selectedBrand,
                      items: brands.map<DropdownMenuItem<String>>((brand) => DropdownMenuItem(value: brand['id'].toString(), child: Text(brand['name']))).toList(),
                      onChanged: (val) => setState(() => _selectedBrand = val),
                    ),
                    const SizedBox(height: 16),
                    DropdownButtonFormField<String>(
                      decoration: const InputDecoration(labelText: 'Status Stok', border: OutlineInputBorder()),
                      value: _stockStatus,
                      items: const [DropdownMenuItem(value: 'instock', child: Text('Tersedia')), DropdownMenuItem(value: 'outofstock', child: Text('Habis'))],
                      onChanged: (val) => setState(() => _stockStatus = val!),
                    ),
                    const SizedBox(height: 28),
                    _variationSection(),
                    const SizedBox(height: 32),
                    isSaving
                        ? const Center(child: CircularProgressIndicator())
                        : ElevatedButton.icon(
                            style: ElevatedButton.styleFrom(backgroundColor: Colors.indigo, foregroundColor: Colors.white, padding: const EdgeInsets.symmetric(vertical: 16)),
                            onPressed: _saveProduct,
                            icon: const Icon(Icons.save),
                            label: const Text('Simpan Produk', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                          ),
                  ],
                ),
              ),
            ),
    );
  }

  Widget _variationSection() {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(color: Colors.blue.shade50, borderRadius: BorderRadius.circular(12), border: Border.all(color: Colors.blue.shade200)),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          const Text('Variasi Warna / Jenis Produk', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
          const SizedBox(height: 12),
          ...variations.asMap().entries.map((entry) {
            final index = entry.key;
            final variation = entry.value;
            return Card(
              margin: const EdgeInsets.only(bottom: 14),
              child: Padding(
                padding: const EdgeInsets.all(12),
                child: Column(children: [
                  Row(children: [
                    GestureDetector(
                      onTap: () => _pickVariationImage(index),
                      child: Container(
                        width: 58,
                        height: 58,
                        clipBehavior: Clip.antiAlias,
                        decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(8), border: Border.all(color: Colors.grey.shade400)),
                        child: variation.image != null
                            ? _pickedImage(variation.image!)
                            : variation.existingImageUrl != null && _productImageUrl(variation.existingImageUrl).isNotEmpty
                                ? _networkImage(variation.existingImageUrl, width: 58, height: 58)
                                : const Icon(Icons.add_photo_alternate, color: Colors.grey),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: TextFormField(
                        initialValue: variation.name,
                        onChanged: (val) => variation.name = val,
                        decoration: const InputDecoration(labelText: 'Nama Variasi', border: OutlineInputBorder()),
                      ),
                    ),
                    IconButton(icon: const Icon(Icons.delete_outline, color: Colors.red), onPressed: () => setState(() => variations.removeAt(index))),
                  ]),
                  const SizedBox(height: 12),
                  Row(children: [
                    Expanded(child: _smallVariationField('Harga Reguler', variation.regularPrice, (v) => variation.regularPrice = v)),
                    const SizedBox(width: 8),
                    Expanded(child: _smallVariationField('Harga Promo', variation.salePrice, (v) => variation.salePrice = v)),
                  ]),
                  const SizedBox(height: 12),
                  Row(children: [
                    Expanded(child: _smallVariationField('Berat', variation.weight, (v) => variation.weight = v)),
                    const SizedBox(width: 8),
                    Expanded(child: _smallVariationField('Stok', variation.quantity, (v) => variation.quantity = v)),
                  ]),
                ]),
              ),
            );
          }),
          ElevatedButton.icon(
            style: ElevatedButton.styleFrom(backgroundColor: Colors.white, foregroundColor: Colors.indigo, elevation: 0, side: const BorderSide(color: Colors.indigo)),
            onPressed: () => setState(() => variations.add(VariationInput())),
            icon: const Icon(Icons.add),
            label: const Text('Tambah Variasi Baru'),
          ),
        ],
      ),
    );
  }

  Widget _smallVariationField(String label, String value, ValueChanged<String> onChanged) {
    return TextFormField(
      initialValue: value,
      keyboardType: TextInputType.number,
      onChanged: onChanged,
      decoration: InputDecoration(labelText: label, border: const OutlineInputBorder(), contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8)),
    );
  }

  Widget _field(String label, TextEditingController controller, {bool number = false, int maxLines = 1, bool requiredField = true}) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: TextFormField(
        controller: controller,
        keyboardType: number ? TextInputType.number : TextInputType.text,
        maxLines: maxLines,
        decoration: InputDecoration(labelText: label, border: const OutlineInputBorder()),
        validator: (val) {
          if (requiredField && (val == null || val.isEmpty)) return '$label wajib diisi';
          return null;
        },
      ),
    );
  }

  @override
  void dispose() {
    _nameCtrl.dispose();
    _shortDescCtrl.dispose();
    _descCtrl.dispose();
    _priceCtrl.dispose();
    _salePriceCtrl.dispose();
    _qtyCtrl.dispose();
    _weightCtrl.dispose();
    _expDateCtrl.dispose();
    super.dispose();
  }
}

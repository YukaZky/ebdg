import 'package:flutter/material.dart';
import '../../services/marketplace_api_service.dart';

class AddCupponScreen extends StatefulWidget {
  final Map<String, dynamic>? coupon;

  const AddCupponScreen({Key? key, this.coupon}) : super(key: key);

  @override
  State<AddCupponScreen> createState() => _AddCupponScreenState();
}

class _AddCupponScreenState extends State<AddCupponScreen> {
  final _formKey = GlobalKey<FormState>();
  final _nameCtrl = TextEditingController();
  final _codeCtrl = TextEditingController();
  final _valueCtrl = TextEditingController();
  final _minPurchaseCtrl = TextEditingController();
  final _maxDiscountCtrl = TextEditingController();
  final _usageLimitCtrl = TextEditingController();
  final _descriptionCtrl = TextEditingController();

  String _type = 'fixed';
  String _status = 'active';
  bool _saving = false;

  bool get _isEdit => widget.coupon != null;

  @override
  void initState() {
    super.initState();
    final coupon = widget.coupon;
    if (coupon != null) {
      _nameCtrl.text = coupon['name']?.toString() ?? '';
      _codeCtrl.text = coupon['code']?.toString() ?? '';
      _valueCtrl.text = _numberText(coupon['value']);
      _minPurchaseCtrl.text = _numberText(coupon['min_purchase']);
      _maxDiscountCtrl.text = _numberText(coupon['max_discount']);
      _usageLimitCtrl.text = coupon['usage_limit']?.toString() ?? '';
      _descriptionCtrl.text = coupon['description']?.toString() ?? '';
      _type = ['fixed', 'discount'].contains(coupon['type']?.toString()) ? coupon['type'].toString() : 'fixed';
      _status = ['active', 'inactive'].contains(coupon['status']?.toString()) ? coupon['status'].toString() : 'active';
    }
  }

  @override
  void dispose() {
    _nameCtrl.dispose();
    _codeCtrl.dispose();
    _valueCtrl.dispose();
    _minPurchaseCtrl.dispose();
    _maxDiscountCtrl.dispose();
    _usageLimitCtrl.dispose();
    _descriptionCtrl.dispose();
    super.dispose();
  }

  String _numberText(dynamic value) {
    if (value == null || value.toString() == 'null') return '';
    final parsed = double.tryParse(value.toString());
    if (parsed == null) return value.toString();
    if (parsed % 1 == 0) return parsed.toInt().toString();
    return parsed.toString();
  }

  double _toDouble(String value) => double.tryParse(value.replaceAll('.', '').replaceAll(',', '.')) ?? 0;
  int? _toInt(String value) => value.trim().isEmpty ? null : int.tryParse(value.trim());

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _saving = true);

    final payload = {
      'name': _nameCtrl.text.trim(),
      'code': _codeCtrl.text.trim().toUpperCase(),
      'type': _type,
      'value': _toDouble(_valueCtrl.text),
      'min_purchase': _toDouble(_minPurchaseCtrl.text),
      'max_discount': _maxDiscountCtrl.text.trim().isEmpty ? null : _toDouble(_maxDiscountCtrl.text),
      'usage_limit': _toInt(_usageLimitCtrl.text),
      'description': _descriptionCtrl.text.trim(),
      'status': _status,
    };

    final id = int.tryParse(widget.coupon?['id']?.toString() ?? '');
    final result = await MarketplaceApiService.saveCoupon(payload, id: id);
    if (!mounted) return;

    setState(() => _saving = false);
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(result != null ? 'Kupon berhasil disimpan.' : 'Gagal menyimpan kupon.')));
    if (result != null) Navigator.pop(context, true);
  }

  String get _valueLabel => _type == 'fixed' ? 'Nominal Potongan' : 'Persentase Diskon';
  String get _valueHint => _type == 'fixed' ? 'Contoh: 10000' : 'Contoh: 15';

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF6F7FB),
      appBar: AppBar(
        title: Text(_isEdit ? 'Edit Kupon' : 'Tambah Kupon'),
        backgroundColor: Colors.white,
        foregroundColor: Colors.black87,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Form(
          key: _formKey,
          child: Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(color: Colors.deepOrange, borderRadius: BorderRadius.circular(18)),
              child: const Text('Kupon akan terhubung ke toko kamu melalui id_user. Type fixed berarti potongan nominal, type discount berarti potongan persen.', style: TextStyle(color: Colors.white, height: 1.4)),
            ),
            const SizedBox(height: 16),
            _field('Nama Kupon', _nameCtrl, required: true),
            _field('Kode Kupon', _codeCtrl, hint: 'Contoh: HEMAT10'),
            DropdownButtonFormField<String>(
              value: _type,
              decoration: _decoration('Tipe Kupon'),
              items: const [
                DropdownMenuItem(value: 'fixed', child: Text('Fixed - potongan nominal')),
                DropdownMenuItem(value: 'discount', child: Text('Discount - potongan persen')),
              ],
              onChanged: (value) => setState(() => _type = value ?? 'fixed'),
            ),
            const SizedBox(height: 14),
            _field(_valueLabel, _valueCtrl, required: true, keyboardType: TextInputType.number, hint: _valueHint, validator: (value) {
              final number = _toDouble(value ?? '');
              if (number <= 0) return 'Nilai kupon wajib lebih dari 0';
              if (_type == 'discount' && number > 100) return 'Diskon maksimal 100%';
              return null;
            }),
            _field('Minimum Belanja', _minPurchaseCtrl, keyboardType: TextInputType.number, hint: 'Opsional, contoh: 50000'),
            if (_type == 'discount') _field('Maksimal Potongan', _maxDiscountCtrl, keyboardType: TextInputType.number, hint: 'Opsional, contoh: 25000'),
            _field('Limit Pengambilan', _usageLimitCtrl, keyboardType: TextInputType.number, hint: 'Opsional'),
            DropdownButtonFormField<String>(
              value: _status,
              decoration: _decoration('Status'),
              items: const [
                DropdownMenuItem(value: 'active', child: Text('Aktif')),
                DropdownMenuItem(value: 'inactive', child: Text('Nonaktif')),
              ],
              onChanged: (value) => setState(() => _status = value ?? 'active'),
            ),
            const SizedBox(height: 14),
            _field('Deskripsi', _descriptionCtrl, maxLines: 3, hint: 'Contoh: Berlaku untuk semua produk toko'),
            const SizedBox(height: 8),
            ElevatedButton(
              onPressed: _saving ? null : _save,
              style: ElevatedButton.styleFrom(backgroundColor: Colors.deepOrange, foregroundColor: Colors.white, padding: const EdgeInsets.symmetric(vertical: 14), shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14))),
              child: Text(_saving ? 'Menyimpan...' : _isEdit ? 'Simpan Perubahan' : 'Tambah Kupon'),
            ),
          ]),
        ),
      ),
    );
  }

  Widget _field(String label, TextEditingController controller, {bool required = false, int maxLines = 1, String? hint, TextInputType? keyboardType, String? Function(String?)? validator}) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 14),
      child: TextFormField(
        controller: controller,
        maxLines: maxLines,
        keyboardType: keyboardType,
        textCapitalization: label == 'Kode Kupon' ? TextCapitalization.characters : TextCapitalization.sentences,
        decoration: _decoration(label, hint: hint),
        validator: validator ?? (value) => required && (value == null || value.trim().isEmpty) ? '$label wajib diisi' : null,
      ),
    );
  }

  InputDecoration _decoration(String label, {String? hint}) {
    return InputDecoration(
      labelText: label,
      hintText: hint,
      filled: true,
      fillColor: Colors.white,
      border: OutlineInputBorder(borderRadius: BorderRadius.circular(14)),
      enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(14), borderSide: BorderSide(color: Colors.grey.shade200)),
      focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(14), borderSide: const BorderSide(color: Colors.deepOrange)),
    );
  }
}

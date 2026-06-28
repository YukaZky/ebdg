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

  static const Color _primary = Color(0xFF0C2442);
  static const Color _accent = Color(0xFFF39C12);
  // static const Color _purple = Color(0xFF6C4DFF);
  static const Color _surface = Color(0xFFF7F8FC);

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
    final message = result != null ? 'Kupon berhasil disimpan.' : (MarketplaceApiService.lastError ?? 'Gagal menyimpan kupon.');
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(message)));
    if (result != null) Navigator.pop(context, true);
  }

  String get _valueLabel => _type == 'fixed' ? 'Nominal Potongan' : 'Persentase Diskon';
  String get _valueHint => _type == 'fixed' ? 'Contoh: 10000' : 'Contoh: 15';

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: _surface,
      body: CustomScrollView(
        physics: const BouncingScrollPhysics(parent: AlwaysScrollableScrollPhysics()),
        slivers: [
          SliverToBoxAdapter(child: _header()),
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(16, 14, 16, 28),
              child: Form(
                key: _formKey,
                child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                  _sectionHeader('Informasi Kupon'),
                  const SizedBox(height: 10),
                  _card(child: Column(children: [
                    _field('Nama Kupon', _nameCtrl, required: true, icon: Icons.local_activity_rounded),
                    _field('Kode Kupon', _codeCtrl, hint: 'Contoh: HEMAT10', icon: Icons.qr_code_2_rounded),
                    DropdownButtonFormField<String>(
                      value: _type,
                      decoration: _decoration('Tipe Kupon', icon: Icons.discount_rounded),
                      items: const [
                        DropdownMenuItem(value: 'fixed', child: Text('Fixed - potongan nominal')),
                        DropdownMenuItem(value: 'discount', child: Text('Discount - potongan persen')),
                      ],
                      onChanged: (value) => setState(() => _type = value ?? 'fixed'),
                    ),
                  ])),
                  const SizedBox(height: 14),
                  _sectionHeader('Nilai Diskon'),
                  const SizedBox(height: 10),
                  _card(child: Column(children: [
                    _field(_valueLabel, _valueCtrl, required: true, keyboardType: TextInputType.number, hint: _valueHint, icon: _type == 'fixed' ? Icons.payments_rounded : Icons.percent_rounded, validator: (value) {
                      final number = _toDouble(value ?? '');
                      if (number <= 0) return 'Nilai kupon wajib lebih dari 0';
                      if (_type == 'discount' && number > 100) return 'Diskon maksimal 100%';
                      return null;
                    }),
                    _field('Minimum Belanja', _minPurchaseCtrl, keyboardType: TextInputType.number, hint: 'Opsional, contoh: 50000', icon: Icons.shopping_bag_rounded),
                    if (_type == 'discount') _field('Maksimal Potongan', _maxDiscountCtrl, keyboardType: TextInputType.number, hint: 'Opsional, contoh: 25000', icon: Icons.savings_rounded),
                    _field('Limit Pengambilan', _usageLimitCtrl, keyboardType: TextInputType.number, hint: 'Opsional', icon: Icons.group_rounded),
                    DropdownButtonFormField<String>(
                      value: _status,
                      decoration: _decoration('Status', icon: Icons.toggle_on_rounded),
                      items: const [
                        DropdownMenuItem(value: 'active', child: Text('Aktif')),
                        DropdownMenuItem(value: 'inactive', child: Text('Nonaktif')),
                      ],
                      onChanged: (value) => setState(() => _status = value ?? 'active'),
                    ),
                    const SizedBox(height: 14),
                    _field('Deskripsi', _descriptionCtrl, maxLines: 3, hint: 'Contoh: Berlaku untuk semua produk toko', icon: Icons.notes_rounded),
                  ])),
                  const SizedBox(height: 18),
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton.icon(
                      onPressed: _saving ? null : _save,
                      icon: _saving ? const SizedBox(width: 18, height: 18, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white)) : const Icon(Icons.save_rounded),
                      label: Text(_saving ? 'Menyimpan...' : _isEdit ? 'Simpan Perubahan' : 'Tambah Kupon'),
                      style: ElevatedButton.styleFrom(backgroundColor: _primary, foregroundColor: Colors.white, elevation: 0, padding: const EdgeInsets.symmetric(vertical: 15), shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16))),
                    ),
                  ),
                ]),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _header() {
    return Container(
      decoration: const BoxDecoration(
        gradient: LinearGradient(colors: [_primary, Color(0xFF123A68)], begin: Alignment.topLeft, end: Alignment.bottomRight),
        borderRadius: BorderRadius.vertical(bottom: Radius.circular(30)),
      ),
      child: SafeArea(
        bottom: false,
        child: Padding(
          padding: const EdgeInsets.fromLTRB(18, 18, 18, 24),
          child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
              _circleAction(Icons.arrow_back_rounded, () => Navigator.pop(context)),
              Text(_isEdit ? 'Edit Kupon' : 'Tambah Kupon', style: const TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.w900)),
              _circleAction(Icons.confirmation_number_rounded, null),
            ]),
            const SizedBox(height: 20),
            Container(
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(color: Colors.white.withOpacity(0.12), borderRadius: BorderRadius.circular(26), border: Border.all(color: Colors.white.withOpacity(0.16))),
              child: Row(children: [
                Container(width: 58, height: 58, decoration: const BoxDecoration(color: Colors.white, shape: BoxShape.circle), child: const Icon(Icons.local_activity_rounded, color: _primary, size: 32)),
                const SizedBox(width: 14),
                Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                  Text(_isEdit ? 'Perbarui voucher toko' : 'Buat voucher toko', style: const TextStyle(color: Colors.white, fontSize: 17, fontWeight: FontWeight.w900)),
                  const SizedBox(height: 5),
                  Text('Fixed untuk nominal, discount untuk persen.', style: TextStyle(color: Colors.white.withOpacity(0.78), fontSize: 12, height: 1.35)),
                ])),
              ]),
            ),
          ]),
        ),
      ),
    );
  }

  Widget _circleAction(IconData icon, VoidCallback? onTap) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(999),
      child: Container(width: 42, height: 42, decoration: BoxDecoration(color: Colors.white.withOpacity(0.14), shape: BoxShape.circle, border: Border.all(color: Colors.white.withOpacity(0.12))), child: Icon(icon, color: Colors.white, size: 21)),
    );
  }

  Widget _card({required Widget child}) {
    return Container(padding: const EdgeInsets.all(16), decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(22), border: Border.all(color: Colors.grey.shade200), boxShadow: [BoxShadow(color: _primary.withOpacity(0.04), blurRadius: 16, offset: const Offset(0, 8))]), child: child);
  }

  Widget _sectionHeader(String title) {
    return Row(children: [Text(title, style: const TextStyle(fontSize: 17, fontWeight: FontWeight.w900, color: Colors.black87)), const SizedBox(width: 10), Expanded(child: Divider(color: Colors.grey.shade300))]);
  }

  Widget _field(String label, TextEditingController controller, {bool required = false, int maxLines = 1, String? hint, TextInputType? keyboardType, String? Function(String?)? validator, IconData? icon}) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 14),
      child: TextFormField(
        controller: controller,
        maxLines: maxLines,
        keyboardType: keyboardType,
        textCapitalization: label == 'Kode Kupon' ? TextCapitalization.characters : TextCapitalization.sentences,
        decoration: _decoration(label, hint: hint, icon: icon),
        validator: validator ?? ((value) => required && (value == null || value.trim().isEmpty) ? '$label wajib diisi' : null),
      ),
    );
  }

  InputDecoration _decoration(String label, {String? hint, IconData? icon}) {
    return InputDecoration(
      labelText: label,
      hintText: hint,
      prefixIcon: icon == null ? null : Icon(icon, color: _primary, size: 20),
      filled: true,
      fillColor: _surface,
      contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
      border: OutlineInputBorder(borderRadius: BorderRadius.circular(16), borderSide: BorderSide.none),
      enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(16), borderSide: BorderSide(color: Colors.grey.shade200)),
      focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(16), borderSide: const BorderSide(color: _accent, width: 1.4)),
    );
  }
}

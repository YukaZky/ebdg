import 'package:flutter/material.dart';

import '../../services/api_service.dart';
import '../../services/store_income_api_service.dart';

class PendapatanTokoScreen extends StatefulWidget {
  const PendapatanTokoScreen({Key? key}) : super(key: key);

  @override
  State<PendapatanTokoScreen> createState() => _PendapatanTokoScreenState();
}

class _PendapatanTokoScreenState extends State<PendapatanTokoScreen> {
  static const Color _primary = Color(0xFF1E3A8A);
  static const Color _success = Color(0xFF15803D);
  static const Color _surface = Color(0xFFF4F6F9);

  bool loading = true;
  int selectedMenu = 0;
  Map<String, dynamic> income = {};
  List<dynamic> payouts = [];
  List<dynamic> accounts = [];
  List<String> providers = [];

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    setState(() => loading = true);
    final incomeResult = await StoreIncomeApiService.sellerIncome();
    final payoutResult = await StoreIncomeApiService.sellerPayouts();
    final bankResult = await StoreIncomeApiService.bankAccounts();
    if (!mounted) return;

    setState(() {
      income = incomeResult ?? {};
      payouts = payoutResult;
      accounts = bankResult['accounts'] is List ? bankResult['accounts'] : [];
      providers = (bankResult['providers'] as List? ?? [])
          .map((item) => item.toString())
          .toList();
      loading = false;
    });
  }

  String _currency(dynamic value) {
    final number = double.tryParse(value?.toString() ?? '0') ?? 0;
    final raw = number.toStringAsFixed(0);
    final buffer = StringBuffer();
    for (int i = 0; i < raw.length; i++) {
      final remaining = raw.length - i;
      buffer.write(raw[i]);
      if (remaining > 1 && remaining % 3 == 1) buffer.write('.');
    }
    return 'Rp ${buffer.toString()}';
  }

  String _date(dynamic value) {
    final text = value?.toString() ?? '-';
    final parts = text.split('-');
    if (parts.length == 3) return '${parts[2]}/${parts[1]}/${parts[0]}';
    return text;
  }

  Map<String, dynamic> _map(dynamic value) {
    if (value is Map<String, dynamic>) return value;
    if (value is Map) return Map<String, dynamic>.from(value);
    return <String, dynamic>{};
  }

  List<dynamic> get _daily => income['daily'] is List ? income['daily'] : [];

  Future<void> _showBankSetting() async {
    final fallbackProviders = <String>[
      'BRI', 'BCA', 'BNI', 'MANDIRI', 'BSI', 'PERMATA', 'SEABANK',
      'DANA', 'OVO', 'GOPAY', 'SHOPEEPAY', 'LAINNYA'
    ];
    final choices = providers.isEmpty ? fallbackProviders : providers;

    Map<String, dynamic>? primaryAccount;
    Map<String, dynamic>? optionalAccount;
    for (final raw in accounts) {
      final account = _map(raw);
      final slot = int.tryParse(account['slot']?.toString() ?? '0') ?? 0;
      if (slot == 1) primaryAccount = account;
      if (slot == 2) optionalAccount = account;
    }

    String? primaryProvider = primaryAccount?['provider']?.toString();
    String? optionalProvider = optionalAccount?['provider']?.toString();
    final primaryNumber = TextEditingController(text: primaryAccount?['account_number']?.toString() ?? '');
    final primaryName = TextEditingController(text: primaryAccount?['account_name']?.toString() ?? '');
    final optionalNumber = TextEditingController(text: optionalAccount?['account_number']?.toString() ?? '');
    final optionalName = TextEditingController(text: optionalAccount?['account_name']?.toString() ?? '');
    bool saving = false;

    await showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (sheetContext) {
        return StatefulBuilder(builder: (context, setModalState) {
          Future<void> save() async {
            if (primaryProvider == null || primaryNumber.text.trim().isEmpty) {
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('Jenis rekening dan nomor rekening utama wajib diisi.')),
              );
              return;
            }
            if ((optionalProvider == null) != optionalNumber.text.trim().isEmpty) {
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('Rekening opsi harus diisi lengkap atau dikosongkan.')),
              );
              return;
            }

            setModalState(() => saving = true);
            final payload = <Map<String, dynamic>>[
              {
                'slot': 1,
                'provider': primaryProvider,
                'account_number': primaryNumber.text.trim(),
                'account_name': primaryName.text.trim(),
              }
            ];
            if (optionalProvider != null && optionalNumber.text.trim().isNotEmpty) {
              payload.add({
                'slot': 2,
                'provider': optionalProvider,
                'account_number': optionalNumber.text.trim(),
                'account_name': optionalName.text.trim(),
              });
            }

            final ok = await StoreIncomeApiService.saveBankAccounts(payload);
            if (!context.mounted) return;
            setModalState(() => saving = false);
            if (!ok) {
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(content: Text(StoreIncomeApiService.lastError ?? 'Gagal menyimpan rekening.')),
              );
              return;
            }
            Navigator.pop(context);
          }

          Widget accountSection({
            required String title,
            required String subtitle,
            required bool requiredAccount,
            required String? provider,
            required ValueChanged<String?> onProviderChanged,
            required TextEditingController numberController,
            required TextEditingController nameController,
          }) {
            return Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: const Color(0xFFF8FAFC),
                borderRadius: BorderRadius.circular(18),
                border: Border.all(color: const Color(0xFFE2E8F0)),
              ),
              child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                Row(children: [
                  Expanded(child: Text(title, style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w900))),
                  Text(requiredAccount ? 'Wajib' : 'Opsional', style: TextStyle(fontSize: 11, fontWeight: FontWeight.w800, color: requiredAccount ? Colors.red : Colors.grey[600])),
                ]),
                const SizedBox(height: 4),
                Text(subtitle, style: TextStyle(fontSize: 12, color: Colors.grey[600])),
                const SizedBox(height: 14),
                DropdownButtonFormField<String>(
                  value: choices.contains(provider) ? provider : null,
                  decoration: const InputDecoration(labelText: 'Jenis Bank / Dompet', border: OutlineInputBorder()),
                  items: choices.map((item) => DropdownMenuItem(value: item, child: Text(item))).toList(),
                  onChanged: onProviderChanged,
                ),
                const SizedBox(height: 12),
                TextField(
                  controller: numberController,
                  keyboardType: TextInputType.number,
                  decoration: const InputDecoration(labelText: 'Nomor Rekening / Nomor Akun', border: OutlineInputBorder()),
                ),
                const SizedBox(height: 12),
                TextField(
                  controller: nameController,
                  decoration: const InputDecoration(labelText: 'Nama Pemilik Rekening (opsional)', border: OutlineInputBorder()),
                ),
              ]),
            );
          }

          return Container(
            padding: EdgeInsets.fromLTRB(18, 18, 18, 18 + MediaQuery.of(context).viewInsets.bottom),
            decoration: const BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
            ),
            child: SafeArea(
              top: false,
              child: SingleChildScrollView(
                child: Column(mainAxisSize: MainAxisSize.min, crossAxisAlignment: CrossAxisAlignment.start, children: [
                  Row(children: [
                    const Expanded(child: Text('Setting Rekening Toko', style: TextStyle(fontSize: 20, fontWeight: FontWeight.w900))),
                    IconButton(onPressed: () => Navigator.pop(context), icon: const Icon(Icons.close_rounded)),
                  ]),
                  const SizedBox(height: 6),
                  Text('Isi rekening utama untuk pencairan. Rekening kedua dapat dipakai sebagai opsi pencairan.', style: TextStyle(color: Colors.grey[600], fontSize: 12.5)),
                  const SizedBox(height: 18),
                  accountSection(
                    title: 'Rekening Utama',
                    subtitle: 'Dipakai otomatis oleh Super Admin saat melakukan pencairan.',
                    requiredAccount: true,
                    provider: primaryProvider,
                    onProviderChanged: (value) => setModalState(() => primaryProvider = value),
                    numberController: primaryNumber,
                    nameController: primaryName,
                  ),
                  const SizedBox(height: 14),
                  accountSection(
                    title: 'Rekening Opsi',
                    subtitle: 'Alternatif bila pencairan tidak menggunakan rekening utama.',
                    requiredAccount: false,
                    provider: optionalProvider,
                    onProviderChanged: (value) => setModalState(() => optionalProvider = value),
                    numberController: optionalNumber,
                    nameController: optionalName,
                  ),
                  const SizedBox(height: 18),
                  SizedBox(
                    width: double.infinity,
                    height: 50,
                    child: ElevatedButton.icon(
                      onPressed: saving ? null : save,
                      icon: saving
                          ? const SizedBox(width: 18, height: 18, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                          : const Icon(Icons.save_outlined),
                      label: Text(saving ? 'Menyimpan...' : 'Simpan Rekening'),
                      style: ElevatedButton.styleFrom(backgroundColor: _primary, foregroundColor: Colors.white, shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14))),
                    ),
                  ),
                ]),
              ),
            ),
          );
        });
      },
    );

    primaryNumber.dispose();
    primaryName.dispose();
    optionalNumber.dispose();
    optionalName.dispose();
    await _loadData();
  }

  Widget _menuButton({required String title, required IconData icon, required bool active, required VoidCallback onTap}) {
    return Expanded(
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(14),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 160),
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 11),
          decoration: BoxDecoration(
            color: active ? _primary : Colors.white,
            borderRadius: BorderRadius.circular(14),
            border: Border.all(color: active ? _primary : const Color(0xFFE2E8F0)),
          ),
          child: Column(children: [
            Icon(icon, size: 21, color: active ? Colors.white : _primary),
            const SizedBox(height: 6),
            Text(title, textAlign: TextAlign.center, maxLines: 2, style: TextStyle(fontSize: 10.5, fontWeight: FontWeight.w800, color: active ? Colors.white : Colors.black87)),
          ]),
        ),
      ),
    );
  }

  Widget _balanceView() {
    return Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      Container(
        width: double.infinity,
        padding: const EdgeInsets.all(22),
        decoration: BoxDecoration(
          gradient: const LinearGradient(colors: [Color(0xFF1E3A8A), Color(0xFF2563EB)]),
          borderRadius: BorderRadius.circular(24),
          boxShadow: [BoxShadow(color: _primary.withOpacity(0.20), blurRadius: 24, offset: const Offset(0, 12))],
        ),
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Text('TOTAL SALDO BELUM DICAIRKAN', style: TextStyle(color: Colors.white.withOpacity(0.78), fontSize: 11, fontWeight: FontWeight.w800, letterSpacing: 0.8)),
          const SizedBox(height: 8),
          Text(_currency(income['available_balance']), style: const TextStyle(color: Colors.white, fontSize: 31, fontWeight: FontWeight.w900)),
          const SizedBox(height: 8),
          Text('${income['available_order_count'] ?? 0} order selesai siap dicairkan', style: TextStyle(color: Colors.white.withOpacity(0.84), fontSize: 12.5)),
        ]),
      ),
      const SizedBox(height: 24),
      const Text('Pendapatan per Tanggal', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w900)),
      const SizedBox(height: 6),
      Text('Klik tanggal untuk melihat daftar order dan nominal pendapatan yang belum dicairkan.', style: TextStyle(fontSize: 12, color: Colors.grey[600])),
      const SizedBox(height: 12),
      if (_daily.isEmpty)
        _emptyCard(Icons.account_balance_wallet_outlined, 'Belum ada saldo dari pesanan yang selesai.')
      else
        ..._daily.map((rawDay) {
          final day = _map(rawDay);
          final orders = day['orders'] is List ? day['orders'] as List : <dynamic>[];
          return Card(
            margin: const EdgeInsets.only(bottom: 12),
            elevation: 0,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18), side: const BorderSide(color: Color(0xFFE2E8F0))),
            child: ExpansionTile(
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
              collapsedShape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
              leading: Container(width: 44, height: 44, decoration: BoxDecoration(color: _success.withOpacity(0.10), borderRadius: BorderRadius.circular(14)), child: const Icon(Icons.calendar_month_outlined, color: _success)),
              title: Text(_date(day['date']), style: const TextStyle(fontWeight: FontWeight.w900)),
              subtitle: Text('${day['order_count'] ?? orders.length} order belum dicairkan', style: TextStyle(fontSize: 12, color: Colors.grey[600])),
              trailing: Column(mainAxisAlignment: MainAxisAlignment.center, crossAxisAlignment: CrossAxisAlignment.end, children: [
                Text(_currency(day['available_total']), style: const TextStyle(fontWeight: FontWeight.w900, color: _success)),
                const SizedBox(height: 2),
                const Text('Belum dicairkan', style: TextStyle(fontSize: 9.5, color: Colors.orange, fontWeight: FontWeight.w800)),
              ]),
              children: orders.map((rawOrder) {
                final order = _map(rawOrder);
                final items = order['items'] is List ? order['items'] as List : <dynamic>[];
                return Container(
                  margin: const EdgeInsets.fromLTRB(14, 0, 14, 12),
                  padding: const EdgeInsets.all(13),
                  decoration: BoxDecoration(color: const Color(0xFFF8FAFC), borderRadius: BorderRadius.circular(14)),
                  child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                    Row(children: [
                      Expanded(child: Text(order['order_number']?.toString() ?? '#${order['id']}', style: const TextStyle(fontWeight: FontWeight.w900))),
                      Text(_currency(order['amount']), style: const TextStyle(fontWeight: FontWeight.w900, color: _success)),
                    ]),
                    const SizedBox(height: 5),
                    Text('Pembeli: ${order['buyer_name'] ?? '-'}', style: TextStyle(fontSize: 11.5, color: Colors.grey[700])),
                    const SizedBox(height: 5),
                    Text('${items.length} jenis produk • Status ${order['status'] ?? '-'}', style: TextStyle(fontSize: 11.5, color: Colors.grey[600])),
                    if (items.isNotEmpty) ...[
                      const SizedBox(height: 8),
                      ...items.map((rawItem) {
                        final item = _map(rawItem);
                        return Padding(
                          padding: const EdgeInsets.only(bottom: 4),
                          child: Row(children: [
                            Expanded(child: Text('${item['product_name'] ?? 'Produk'} × ${item['quantity'] ?? 0}', style: const TextStyle(fontSize: 11.5))),
                            Text(_currency(item['line_total']), style: const TextStyle(fontSize: 11.5, fontWeight: FontWeight.w700)),
                          ]),
                        );
                      }),
                    ],
                  ]),
                );
              }).toList(),
            ),
          );
        }),
    ]);
  }

  Widget _payoutView() {
    if (payouts.isEmpty) {
      return _emptyCard(Icons.payments_outlined, 'Belum ada riwayat pencairan dari Super Admin.');
    }

    return Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      const Text('Info Pencairan', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w900)),
      const SizedBox(height: 6),
      Text('Klik pencairan untuk membuka detail tanggal, deskripsi, rekening, dan bukti transfer.', style: TextStyle(fontSize: 12, color: Colors.grey[600])),
      const SizedBox(height: 12),
      ...payouts.map((raw) {
        final payout = _map(raw);
        final payoutId = int.tryParse(payout['id']?.toString() ?? '0') ?? 0;
        final hasProof = payout['proof_photo']?.toString().isNotEmpty == true;
        final proofUrl = hasProof && payoutId > 0
            ? '${ApiService.baseUrl}/marketplace/payouts/$payoutId/proof'
            : null;
        return Card(
          margin: const EdgeInsets.only(bottom: 12),
          elevation: 0,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18), side: const BorderSide(color: Color(0xFFE2E8F0))),
          child: ExpansionTile(
            leading: Container(width: 44, height: 44, decoration: BoxDecoration(color: _success.withOpacity(0.10), borderRadius: BorderRadius.circular(14)), child: const Icon(Icons.check_circle_outline_rounded, color: _success)),
            title: Text(_currency(payout['amount']), style: const TextStyle(fontWeight: FontWeight.w900)),
            subtitle: Text('Dicairkan ${_date(payout['payout_date'])}', style: TextStyle(fontSize: 12, color: Colors.grey[600])),
            trailing: const Chip(label: Text('Sudah dicairkan', style: TextStyle(fontSize: 9.5, fontWeight: FontWeight.w800, color: _success)), side: BorderSide(color: Color(0xFFBBF7D0)), backgroundColor: Color(0xFFF0FDF4)),
            children: [
              Container(
                width: double.infinity,
                margin: const EdgeInsets.fromLTRB(14, 0, 14, 14),
                padding: const EdgeInsets.all(14),
                decoration: BoxDecoration(color: const Color(0xFFF8FAFC), borderRadius: BorderRadius.circular(14)),
                child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                  _detailLine('Tanggal pendapatan', _date(payout['income_date'])),
                  _detailLine('Tanggal pencairan', _date(payout['payout_date'])),
                  _detailLine('Jumlah order', '${payout['order_count'] ?? 0} order'),
                  _detailLine('Rekening', '${payout['bank_provider'] ?? '-'} • ${payout['account_number'] ?? '-'}'),
                  _detailLine('Atas nama', payout['account_name']?.toString().isNotEmpty == true ? payout['account_name'].toString() : '-'),
                  _detailLine('Deskripsi', payout['description']?.toString().isNotEmpty == true ? payout['description'].toString() : '-'),
                  if (proofUrl != null) ...[
                    const SizedBox(height: 10),
                    const Text('Bukti Pencairan', style: TextStyle(fontSize: 12, fontWeight: FontWeight.w900)),
                    const SizedBox(height: 8),
                    ClipRRect(
                      borderRadius: BorderRadius.circular(14),
                      child: Image.network(
                        proofUrl,
                        headers: ApiService.token == null
                            ? null
                            : {'Authorization': 'Bearer ${ApiService.token}', 'Accept': 'image/*'},
                        width: double.infinity,
                        height: 190,
                        fit: BoxFit.cover,
                        errorBuilder: (_, __, ___) => Container(height: 100, alignment: Alignment.center, color: Colors.grey[200], child: const Text('Bukti foto tidak dapat dimuat.')),
                      ),
                    ),
                  ],
                ]),
              ),
            ],
          ),
        );
      }),
    ]);
  }

  Widget _detailLine(String label, String value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 7),
      child: Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
        SizedBox(width: 125, child: Text(label, style: TextStyle(fontSize: 11.5, color: Colors.grey[600]))),
        Expanded(child: Text(value, style: const TextStyle(fontSize: 11.5, fontWeight: FontWeight.w700))),
      ]),
    );
  }

  Widget _emptyCard(IconData icon, String text) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 30),
      decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(18), border: Border.all(color: const Color(0xFFE2E8F0))),
      child: Column(children: [Icon(icon, size: 36, color: Colors.grey[400]), const SizedBox(height: 10), Text(text, textAlign: TextAlign.center, style: TextStyle(color: Colors.grey[600], fontSize: 12.5))]),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: _surface,
      appBar: AppBar(
        title: const Text('Pendapatan Toko', style: TextStyle(fontWeight: FontWeight.w900)),
        backgroundColor: Colors.white,
        foregroundColor: Colors.black87,
        elevation: 0,
        actions: [IconButton(onPressed: _loadData, icon: const Icon(Icons.refresh_rounded))],
      ),
      body: loading
          ? const Center(child: CircularProgressIndicator(color: _primary))
          : RefreshIndicator(
              onRefresh: _loadData,
              child: SingleChildScrollView(
                physics: const AlwaysScrollableScrollPhysics(),
                padding: const EdgeInsets.all(16),
                child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                  Container(
                    padding: const EdgeInsets.all(7),
                    decoration: BoxDecoration(color: const Color(0xFFEFF6FF), borderRadius: BorderRadius.circular(18)),
                    child: Row(children: [
                      _menuButton(title: 'Daftar Saldo', icon: Icons.account_balance_wallet_outlined, active: selectedMenu == 0, onTap: () => setState(() => selectedMenu = 0)),
                      const SizedBox(width: 7),
                      _menuButton(title: 'Info Pencairan', icon: Icons.payments_outlined, active: selectedMenu == 1, onTap: () => setState(() => selectedMenu = 1)),
                      const SizedBox(width: 7),
                      _menuButton(title: 'Setting Rekening', icon: Icons.account_balance_outlined, active: false, onTap: _showBankSetting),
                    ]),
                  ),
                  const SizedBox(height: 18),
                  selectedMenu == 0 ? _balanceView() : _payoutView(),
                  const SizedBox(height: 28),
                ]),
              ),
            ),
    );
  }
}

import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';

import '../../services/store_income_api_service.dart';

class PencairanPendapatanScreen extends StatefulWidget {
  const PencairanPendapatanScreen({Key? key}) : super(key: key);

  @override
  State<PencairanPendapatanScreen> createState() => _PencairanPendapatanScreenState();
}

class _PencairanPendapatanScreenState extends State<PencairanPendapatanScreen> {
  static const Color _primary = Color(0xFF1E3A8A);
  bool loading = true;
  List<dynamic> stores = [];

  @override
  void initState() {
    super.initState();
    _loadStores();
  }

  Future<void> _loadStores() async {
    setState(() => loading = true);
    final result = await StoreIncomeApiService.superAdminStores();
    if (!mounted) return;
    setState(() {
      stores = result ?? [];
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

  Map<String, dynamic> _map(dynamic value) {
    if (value is Map<String, dynamic>) return value;
    if (value is Map) return Map<String, dynamic>.from(value);
    return <String, dynamic>{};
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF4F6F9),
      appBar: AppBar(
        title: const Text('Pencairan Pendapatan', style: TextStyle(fontWeight: FontWeight.w900)),
        backgroundColor: Colors.white,
        foregroundColor: Colors.black87,
        elevation: 0,
        actions: [IconButton(onPressed: _loadStores, icon: const Icon(Icons.refresh_rounded))],
      ),
      body: loading
          ? const Center(child: CircularProgressIndicator(color: _primary))
          : RefreshIndicator(
              onRefresh: _loadStores,
              child: ListView(
                physics: const AlwaysScrollableScrollPhysics(),
                padding: const EdgeInsets.all(16),
                children: [
                  Container(
                    padding: const EdgeInsets.all(18),
                    decoration: BoxDecoration(
                      gradient: const LinearGradient(colors: [Color(0xFF1E3A8A), Color(0xFF3B82F6)]),
                      borderRadius: BorderRadius.circular(22),
                    ),
                    child: const Row(children: [
                      Icon(Icons.admin_panel_settings_outlined, color: Colors.white, size: 34),
                      SizedBox(width: 14),
                      Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                        Text('Panel Super Admin', style: TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.w900)),
                        SizedBox(height: 4),
                        Text('Pilih toko untuk melihat saldo per tanggal dan memproses pencairan.', style: TextStyle(color: Colors.white70, fontSize: 12)),
                      ])),
                    ]),
                  ),
                  const SizedBox(height: 18),
                  if (stores.isEmpty)
                    Container(
                      padding: const EdgeInsets.symmetric(vertical: 36, horizontal: 18),
                      decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(18)),
                      child: const Column(children: [
                        Icon(Icons.storefront_outlined, size: 38, color: Colors.grey),
                        SizedBox(height: 10),
                        Text('Belum ada toko yang dapat ditampilkan.'),
                      ]),
                    )
                  else
                    ...stores.map((raw) {
                      final store = _map(raw);
                      final balance = double.tryParse(store['available_balance']?.toString() ?? '0') ?? 0;
                      return Card(
                        elevation: 0,
                        margin: const EdgeInsets.only(bottom: 12),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18), side: const BorderSide(color: Color(0xFFE2E8F0))),
                        child: ListTile(
                          contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                          leading: Container(width: 48, height: 48, decoration: BoxDecoration(color: _primary.withOpacity(0.09), borderRadius: BorderRadius.circular(15)), child: const Icon(Icons.store_mall_directory_outlined, color: _primary)),
                          title: Text(store['store_name']?.toString() ?? 'Toko', style: const TextStyle(fontWeight: FontWeight.w900)),
                          subtitle: Padding(
                            padding: const EdgeInsets.only(top: 5),
                            child: Text('${store['owner_name'] ?? '-'} • ${store['available_order_count'] ?? 0} order belum dicairkan', style: TextStyle(fontSize: 11.5, color: Colors.grey[600])),
                          ),
                          trailing: Column(mainAxisAlignment: MainAxisAlignment.center, crossAxisAlignment: CrossAxisAlignment.end, children: [
                            Text(_currency(balance), style: TextStyle(fontWeight: FontWeight.w900, color: balance > 0 ? const Color(0xFF15803D) : Colors.grey)),
                            const SizedBox(height: 4),
                            const Icon(Icons.arrow_forward_ios_rounded, size: 14, color: Colors.grey),
                          ]),
                          onTap: () async {
                            final sellerId = int.tryParse(store['seller_id']?.toString() ?? '0') ?? 0;
                            if (sellerId <= 0) return;
                            await Navigator.push(
                              context,
                              MaterialPageRoute(builder: (_) => PencairanTokoDetailScreen(sellerId: sellerId, initialStoreName: store['store_name']?.toString() ?? 'Toko')),
                            );
                            if (mounted) _loadStores();
                          },
                        ),
                      );
                    }),
                ],
              ),
            ),
    );
  }
}

class PencairanTokoDetailScreen extends StatefulWidget {
  final int sellerId;
  final String initialStoreName;

  const PencairanTokoDetailScreen({Key? key, required this.sellerId, required this.initialStoreName}) : super(key: key);

  @override
  State<PencairanTokoDetailScreen> createState() => _PencairanTokoDetailScreenState();
}

class _PencairanTokoDetailScreenState extends State<PencairanTokoDetailScreen> {
  static const Color _primary = Color(0xFF1E3A8A);
  static const Color _success = Color(0xFF15803D);
  bool loading = true;
  Map<String, dynamic> data = {};

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() => loading = true);
    final result = await StoreIncomeApiService.superAdminSellerDetail(widget.sellerId);
    if (!mounted) return;
    setState(() {
      data = result ?? {};
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

  Future<void> _openPayoutForm(Map<String, dynamic> day) async {
    final bankAccounts = data['bank_accounts'] is List ? data['bank_accounts'] as List : <dynamic>[];
    if (bankAccounts.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Toko belum mengatur rekening pencairan.')));
      return;
    }

    int? selectedBankId;
    for (final raw in bankAccounts) {
      final account = _map(raw);
      if ((int.tryParse(account['slot']?.toString() ?? '0') ?? 0) == 1) {
        selectedBankId = int.tryParse(account['id']?.toString() ?? '');
        break;
      }
    }
    selectedBankId ??= int.tryParse(_map(bankAccounts.first)['id']?.toString() ?? '');

    final descriptionController = TextEditingController();
    XFile? proofPhoto;
    bool saving = false;

    await showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (sheetContext) {
        return StatefulBuilder(builder: (context, setModalState) {
          Future<void> pickProof() async {
            final image = await ImagePicker().pickImage(source: ImageSource.gallery, imageQuality: 80);
            if (image != null) setModalState(() => proofPhoto = image);
          }

          Future<void> submit() async {
            if (selectedBankId == null) {
              ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Pilih rekening pencairan.')));
              return;
            }
            setModalState(() => saving = true);
            final ok = await StoreIncomeApiService.processPayout(
              sellerId: widget.sellerId,
              incomeDate: day['date'].toString(),
              description: descriptionController.text,
              bankAccountId: selectedBankId,
              proofPhoto: proofPhoto,
            );
            if (!context.mounted) return;
            setModalState(() => saving = false);
            if (!ok) {
              ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(StoreIncomeApiService.lastError ?? 'Gagal memproses pencairan.')));
              return;
            }
            Navigator.pop(context);
          }

          return Container(
            padding: EdgeInsets.fromLTRB(18, 18, 18, 18 + MediaQuery.of(context).viewInsets.bottom),
            decoration: const BoxDecoration(color: Colors.white, borderRadius: BorderRadius.vertical(top: Radius.circular(28))),
            child: SafeArea(
              top: false,
              child: SingleChildScrollView(
                child: Column(mainAxisSize: MainAxisSize.min, crossAxisAlignment: CrossAxisAlignment.start, children: [
                  Row(children: [
                    const Expanded(child: Text('Proses Pencairan', style: TextStyle(fontSize: 20, fontWeight: FontWeight.w900))),
                    IconButton(onPressed: () => Navigator.pop(context), icon: const Icon(Icons.close_rounded)),
                  ]),
                  const SizedBox(height: 4),
                  Text('${widget.initialStoreName} • Pendapatan ${_date(day['date'])}', style: TextStyle(fontSize: 12.5, color: Colors.grey[600])),
                  const SizedBox(height: 14),
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(color: const Color(0xFFF0FDF4), borderRadius: BorderRadius.circular(16)),
                    child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                      const Text('Total yang akan dicairkan', style: TextStyle(fontSize: 11.5, color: _success, fontWeight: FontWeight.w700)),
                      const SizedBox(height: 5),
                      Text(_currency(day['available_total']), style: const TextStyle(fontSize: 25, fontWeight: FontWeight.w900, color: _success)),
                    ]),
                  ),
                  const SizedBox(height: 14),
                  DropdownButtonFormField<int>(
                    value: selectedBankId,
                    decoration: const InputDecoration(labelText: 'Rekening Tujuan', border: OutlineInputBorder()),
                    items: bankAccounts.map((raw) {
                      final account = _map(raw);
                      final id = int.tryParse(account['id']?.toString() ?? '0') ?? 0;
                      final label = '${account['provider'] ?? '-'} • ${account['account_number'] ?? '-'}';
                      return DropdownMenuItem(value: id, child: Text(label, overflow: TextOverflow.ellipsis));
                    }).toList(),
                    onChanged: (value) => setModalState(() => selectedBankId = value),
                  ),
                  const SizedBox(height: 12),
                  TextField(
                    controller: descriptionController,
                    maxLines: 3,
                    decoration: const InputDecoration(labelText: 'Deskripsi Pencairan', hintText: 'Contoh: Pencairan pendapatan tanggal 14 Agustus 2026', border: OutlineInputBorder()),
                  ),
                  const SizedBox(height: 12),
                  InkWell(
                    onTap: pickProof,
                    borderRadius: BorderRadius.circular(14),
                    child: Container(
                      width: double.infinity,
                      padding: const EdgeInsets.all(14),
                      decoration: BoxDecoration(border: Border.all(color: const Color(0xFFE2E8F0)), borderRadius: BorderRadius.circular(14)),
                      child: Row(children: [
                        const Icon(Icons.image_outlined, color: _primary),
                        const SizedBox(width: 10),
                        Expanded(child: Text(proofPhoto == null ? 'Pilih foto bukti transfer' : proofPhoto!.name, maxLines: 1, overflow: TextOverflow.ellipsis, style: const TextStyle(fontWeight: FontWeight.w700))),
                        const Icon(Icons.chevron_right_rounded),
                      ]),
                    ),
                  ),
                  const SizedBox(height: 18),
                  SizedBox(
                    width: double.infinity,
                    height: 50,
                    child: ElevatedButton.icon(
                      onPressed: saving ? null : submit,
                      icon: saving ? const SizedBox(width: 18, height: 18, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white)) : const Icon(Icons.payments_outlined),
                      label: Text(saving ? 'Memproses...' : 'Tandai Sudah Dicairkan'),
                      style: ElevatedButton.styleFrom(backgroundColor: _success, foregroundColor: Colors.white, shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14))),
                    ),
                  ),
                ]),
              ),
            ),
          );
        });
      },
    );

    descriptionController.dispose();
    await _load();
  }

  Widget _statusBadge(String status) {
    final paid = status == 'sudah_dicairkan';
    final color = paid ? _success : Colors.orange.shade800;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 5),
      decoration: BoxDecoration(color: color.withOpacity(0.09), borderRadius: BorderRadius.circular(999), border: Border.all(color: color.withOpacity(0.25))),
      child: Text(paid ? 'Sudah dicairkan' : 'Belum dicairkan', style: TextStyle(fontSize: 9.5, color: color, fontWeight: FontWeight.w900)),
    );
  }

  @override
  Widget build(BuildContext context) {
    final daily = data['daily'] is List ? data['daily'] as List : <dynamic>[];
    return Scaffold(
      backgroundColor: const Color(0xFFF4F6F9),
      appBar: AppBar(
        title: Text(data['store_name']?.toString() ?? widget.initialStoreName, style: const TextStyle(fontWeight: FontWeight.w900)),
        backgroundColor: Colors.white,
        foregroundColor: Colors.black87,
        elevation: 0,
        actions: [IconButton(onPressed: _load, icon: const Icon(Icons.refresh_rounded))],
      ),
      body: loading
          ? const Center(child: CircularProgressIndicator(color: _primary))
          : RefreshIndicator(
              onRefresh: _load,
              child: ListView(
                physics: const AlwaysScrollableScrollPhysics(),
                padding: const EdgeInsets.all(16),
                children: [
                  Container(
                    padding: const EdgeInsets.all(20),
                    decoration: BoxDecoration(gradient: const LinearGradient(colors: [_primary, Color(0xFF2563EB)]), borderRadius: BorderRadius.circular(22)),
                    child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                      Text('SALDO BELUM DICAIRKAN', style: TextStyle(color: Colors.white.withOpacity(0.78), fontSize: 11, fontWeight: FontWeight.w800)),
                      const SizedBox(height: 7),
                      Text(_currency(data['available_balance']), style: const TextStyle(color: Colors.white, fontSize: 28, fontWeight: FontWeight.w900)),
                      const SizedBox(height: 6),
                      Text('Pemilik: ${data['owner_name'] ?? '-'}', style: TextStyle(color: Colors.white.withOpacity(0.80), fontSize: 12)),
                    ]),
                  ),
                  const SizedBox(height: 20),
                  const Text('Pendapatan per Tanggal', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w900)),
                  const SizedBox(height: 5),
                  Text('Klik tanggal untuk melihat order. Status menunjukkan apakah pendapatan tanggal tersebut sudah dicairkan.', style: TextStyle(fontSize: 12, color: Colors.grey[600])),
                  const SizedBox(height: 12),
                  if (daily.isEmpty)
                    Container(padding: const EdgeInsets.all(26), decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(18)), child: const Center(child: Text('Belum ada pendapatan dari order selesai.')))
                  else
                    ...daily.map((rawDay) {
                      final day = _map(rawDay);
                      final orders = day['orders'] is List ? day['orders'] as List : <dynamic>[];
                      final status = day['status']?.toString() ?? 'belum_dicairkan';
                      final available = double.tryParse(day['available_total']?.toString() ?? '0') ?? 0;
                      return Card(
                        margin: const EdgeInsets.only(bottom: 12),
                        elevation: 0,
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18), side: const BorderSide(color: Color(0xFFE2E8F0))),
                        child: ExpansionTile(
                          leading: Container(width: 44, height: 44, decoration: BoxDecoration(color: _primary.withOpacity(0.09), borderRadius: BorderRadius.circular(14)), child: const Icon(Icons.calendar_today_outlined, color: _primary)),
                          title: Row(children: [
                            Expanded(child: Text(_date(day['date']), style: const TextStyle(fontWeight: FontWeight.w900))),
                            _statusBadge(status),
                          ]),
                          subtitle: Padding(
                            padding: const EdgeInsets.only(top: 4),
                            child: Row(children: [
                              Text('${day['order_count'] ?? orders.length} order', style: TextStyle(fontSize: 11.5, color: Colors.grey[600])),
                              const Spacer(),
                              Text(_currency(day['total']), style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w900)),
                            ]),
                          ),
                          children: [
                            ...orders.map((rawOrder) {
                              final order = _map(rawOrder);
                              final paid = order['payout_status']?.toString() == 'sudah_dicairkan';
                              return Container(
                                margin: const EdgeInsets.fromLTRB(14, 0, 14, 9),
                                padding: const EdgeInsets.all(12),
                                decoration: BoxDecoration(color: const Color(0xFFF8FAFC), borderRadius: BorderRadius.circular(13)),
                                child: Row(children: [
                                  Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                                    Text(order['order_number']?.toString() ?? '#${order['id']}', style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w900)),
                                    const SizedBox(height: 3),
                                    Text('${order['buyer_name'] ?? '-'} • ${paid ? 'Sudah dicairkan' : 'Belum dicairkan'}', style: TextStyle(fontSize: 10.5, color: paid ? _success : Colors.orange.shade800)),
                                  ])),
                                  Text(_currency(order['amount']), style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w900)),
                                ]),
                              );
                            }),
                            if (available > 0)
                              Padding(
                                padding: const EdgeInsets.fromLTRB(14, 5, 14, 14),
                                child: SizedBox(
                                  width: double.infinity,
                                  child: ElevatedButton.icon(
                                    onPressed: () => _openPayoutForm(day),
                                    icon: const Icon(Icons.payments_outlined, size: 18),
                                    label: Text('Cairkan ${_currency(available)}'),
                                    style: ElevatedButton.styleFrom(backgroundColor: _success, foregroundColor: Colors.white, shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12))),
                                  ),
                                ),
                              ),
                          ],
                        ),
                      );
                    }),
                ],
              ),
            ),
    );
  }
}

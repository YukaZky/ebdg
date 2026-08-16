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
                      Expanded(
                        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                          Text('Panel Super Admin', style: TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.w900)),
                          SizedBox(height: 4),
                          Text('Saldo memuat semua order yang sudah dibayar dan belum dicairkan.', style: TextStyle(color: Colors.white70, fontSize: 12)),
                        ]),
                      ),
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
                      final eligible = double.tryParse(store['eligible_payout_balance']?.toString() ?? '0') ?? 0;
                      return Card(
                        elevation: 0,
                        margin: const EdgeInsets.only(bottom: 12),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(18),
                          side: const BorderSide(color: Color(0xFFE2E8F0)),
                        ),
                        child: ListTile(
                          contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                          leading: Container(
                            width: 48,
                            height: 48,
                            decoration: BoxDecoration(color: _primary.withOpacity(0.09), borderRadius: BorderRadius.circular(15)),
                            child: const Icon(Icons.store_mall_directory_outlined, color: _primary),
                          ),
                          title: Text(store['store_name']?.toString() ?? 'Toko', style: const TextStyle(fontWeight: FontWeight.w900)),
                          subtitle: Padding(
                            padding: const EdgeInsets.only(top: 5),
                            child: Text(
                              '${store['available_order_count'] ?? 0} order belum dicairkan • ${store['eligible_order_count'] ?? 0} siap cair',
                              style: TextStyle(fontSize: 11.5, color: Colors.grey[600]),
                            ),
                          ),
                          trailing: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            crossAxisAlignment: CrossAxisAlignment.end,
                            children: [
                              Text(_currency(balance), style: TextStyle(fontWeight: FontWeight.w900, color: balance > 0 ? const Color(0xFF15803D) : Colors.grey)),
                              const SizedBox(height: 2),
                              Text('Siap: ${_currency(eligible)}', style: const TextStyle(fontSize: 9.5, color: Colors.indigo, fontWeight: FontWeight.w700)),
                            ],
                          ),
                          onTap: () async {
                            final sellerId = int.tryParse(store['seller_id']?.toString() ?? '0') ?? 0;
                            if (sellerId <= 0) return;
                            await Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (_) => PencairanTokoDetailScreen(
                                  sellerId: sellerId,
                                  initialStoreName: store['store_name']?.toString() ?? 'Toko',
                                ),
                              ),
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

  const PencairanTokoDetailScreen({
    Key? key,
    required this.sellerId,
    required this.initialStoreName,
  }) : super(key: key);

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

  String _dateTime(dynamic value) {
    final raw = value?.toString().trim() ?? '';
    if (raw.isEmpty) return '-';
    try {
      final parsed = DateTime.parse(raw).toLocal();
      String two(int n) => n.toString().padLeft(2, '0');
      return '${two(parsed.day)}/${two(parsed.month)}/${parsed.year} ${two(parsed.hour)}:${two(parsed.minute)}';
    } catch (_) {
      return raw;
    }
  }

  Map<String, dynamic> _map(dynamic value) {
    if (value is Map<String, dynamic>) return value;
    if (value is Map) return Map<String, dynamic>.from(value);
    return <String, dynamic>{};
  }

  List<dynamic> get _orders => data['orders'] is List ? data['orders'] as List : <dynamic>[];

  List<Map<String, dynamic>> get _eligibleOrders => _orders
      .map(_map)
      .where((order) => order['payout_eligible'] == true)
      .toList();

  Widget _badge(String text, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 5),
      decoration: BoxDecoration(
        color: color.withOpacity(0.09),
        borderRadius: BorderRadius.circular(999),
        border: Border.all(color: color.withOpacity(0.22)),
      ),
      child: Text(text, style: TextStyle(fontSize: 9.5, color: color, fontWeight: FontWeight.w900)),
    );
  }

  Future<void> _openPayoutForm() async {
    final bankAccounts = data['bank_accounts'] is List ? data['bank_accounts'] as List : <dynamic>[];
    final eligibleOrders = _eligibleOrders;

    if (eligibleOrders.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Belum ada order yang melewati 3 x 24 jam sejak pembayaran approved.')),
      );
      return;
    }

    if (bankAccounts.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Toko belum mengatur rekening pencairan.')),
      );
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

    final selectedOrderIds = <int>{};
    final descriptionController = TextEditingController(
      text: 'Pencairan pendapatan toko ${data['store_name'] ?? widget.initialStoreName}',
    );
    XFile? proofPhoto;
    bool saving = false;

    await showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (sheetContext) {
        return StatefulBuilder(builder: (context, setModalState) {
          double selectedAmount() {
            return eligibleOrders
                .where((order) => selectedOrderIds.contains(int.tryParse(order['id']?.toString() ?? '0') ?? 0))
                .fold<double>(0, (sum, order) => sum + (double.tryParse(order['amount']?.toString() ?? '0') ?? 0));
          }

          Future<void> pickProof() async {
            final image = await ImagePicker().pickImage(source: ImageSource.gallery, imageQuality: 82);
            if (image != null) setModalState(() => proofPhoto = image);
          }

          Future<void> submit() async {
            if (selectedOrderIds.isEmpty) {
              ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Pilih minimal satu order yang akan dicairkan.')));
              return;
            }
            if (selectedBankId == null) {
              ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Pilih rekening pencairan.')));
              return;
            }
            if (proofPhoto == null) {
              ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Foto bukti transfer wajib diunggah.')));
              return;
            }

            setModalState(() => saving = true);
            final ok = await StoreIncomeApiService.processPayout(
              sellerId: widget.sellerId,
              orderIds: selectedOrderIds.toList(),
              description: descriptionController.text,
              bankAccountId: selectedBankId!,
              proofPhoto: proofPhoto!,
            );
            if (!context.mounted) return;
            setModalState(() => saving = false);

            if (!ok) {
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(content: Text(StoreIncomeApiService.lastError ?? 'Gagal memproses pencairan.')),
              );
              return;
            }

            Navigator.pop(context);
          }

          return Container(
            constraints: BoxConstraints(maxHeight: MediaQuery.of(context).size.height * 0.90),
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
                    const Expanded(child: Text('Cairkan Dana Toko', style: TextStyle(fontSize: 20, fontWeight: FontWeight.w900))),
                    IconButton(onPressed: () => Navigator.pop(context), icon: const Icon(Icons.close_rounded)),
                  ]),
                  Text(
                    'Hanya order yang sudah 3 x 24 jam sejak pembayaran approved yang dapat dipilih.',
                    style: TextStyle(fontSize: 12, color: Colors.grey[600]),
                  ),
                  const SizedBox(height: 14),
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(color: const Color(0xFFF0FDF4), borderRadius: BorderRadius.circular(16)),
                    child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                      const Text('Total order terpilih', style: TextStyle(fontSize: 11.5, color: _success, fontWeight: FontWeight.w700)),
                      const SizedBox(height: 5),
                      Text(_currency(selectedAmount()), style: const TextStyle(fontSize: 25, fontWeight: FontWeight.w900, color: _success)),
                      const SizedBox(height: 3),
                      Text('${selectedOrderIds.length} order dipilih', style: const TextStyle(fontSize: 11, color: _success)),
                    ]),
                  ),
                  const SizedBox(height: 16),
                  const Text('Pilih Order yang Dicairkan', style: TextStyle(fontSize: 14, fontWeight: FontWeight.w900)),
                  const SizedBox(height: 8),
                  Container(
                    constraints: const BoxConstraints(maxHeight: 280),
                    decoration: BoxDecoration(
                      border: Border.all(color: const Color(0xFFE2E8F0)),
                      borderRadius: BorderRadius.circular(14),
                    ),
                    child: ListView.separated(
                      shrinkWrap: true,
                      itemCount: eligibleOrders.length,
                      separatorBuilder: (_, __) => const Divider(height: 1),
                      itemBuilder: (context, index) {
                        final order = eligibleOrders[index];
                        final id = int.tryParse(order['id']?.toString() ?? '0') ?? 0;
                        final selected = selectedOrderIds.contains(id);
                        return CheckboxListTile(
                          value: selected,
                          activeColor: _success,
                          controlAffinity: ListTileControlAffinity.leading,
                          title: Text(order['order_number']?.toString() ?? '#$id', style: const TextStyle(fontSize: 12.5, fontWeight: FontWeight.w900)),
                          subtitle: Text(
                            '${order['status_label'] ?? order['status'] ?? '-'} • approved ${_dateTime(order['payment_approved_at'])}',
                            style: TextStyle(fontSize: 10.5, color: Colors.grey[600]),
                          ),
                          secondary: Text(_currency(order['amount']), style: const TextStyle(fontSize: 11.5, fontWeight: FontWeight.w900)),
                          onChanged: (value) {
                            setModalState(() {
                              if (value == true) {
                                selectedOrderIds.add(id);
                              } else {
                                selectedOrderIds.remove(id);
                              }
                            });
                          },
                        );
                      },
                    ),
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
                    decoration: const InputDecoration(
                      labelText: 'Deskripsi Pencairan',
                      hintText: 'Deskripsi dapat diedit manual',
                      border: OutlineInputBorder(),
                    ),
                  ),
                  const SizedBox(height: 12),
                  InkWell(
                    onTap: pickProof,
                    borderRadius: BorderRadius.circular(14),
                    child: Container(
                      width: double.infinity,
                      padding: const EdgeInsets.all(14),
                      decoration: BoxDecoration(
                        border: Border.all(color: proofPhoto == null ? const Color(0xFFE2E8F0) : const Color(0xFF86EFAC)),
                        borderRadius: BorderRadius.circular(14),
                      ),
                      child: Row(children: [
                        Icon(proofPhoto == null ? Icons.image_outlined : Icons.check_circle_outline_rounded, color: proofPhoto == null ? _primary : _success),
                        const SizedBox(width: 10),
                        Expanded(
                          child: Text(
                            proofPhoto == null ? 'Upload foto bukti transfer *' : proofPhoto!.name,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: const TextStyle(fontWeight: FontWeight.w700),
                          ),
                        ),
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
                      icon: saving
                          ? const SizedBox(width: 18, height: 18, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                          : const Icon(Icons.payments_outlined),
                      label: Text(saving ? 'Memproses...' : 'Simpan Pencairan'),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: _success,
                        foregroundColor: Colors.white,
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                      ),
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

  @override
  Widget build(BuildContext context) {
    final orders = _orders;
    final eligibleCount = int.tryParse(data['eligible_order_count']?.toString() ?? '0') ?? 0;

    return Scaffold(
      backgroundColor: const Color(0xFFF4F6F9),
      appBar: AppBar(
        title: Text(data['store_name']?.toString() ?? widget.initialStoreName, style: const TextStyle(fontWeight: FontWeight.w900)),
        backgroundColor: Colors.white,
        foregroundColor: Colors.black87,
        elevation: 0,
        actions: [IconButton(onPressed: _load, icon: const Icon(Icons.refresh_rounded))],
      ),
      floatingActionButton: loading
          ? null
          : FloatingActionButton.extended(
              onPressed: _openPayoutForm,
              backgroundColor: _success,
              foregroundColor: Colors.white,
              icon: const Icon(Icons.payments_outlined),
              label: const Text('Cairkan Dana Toko', style: TextStyle(fontWeight: FontWeight.w900)),
            ),
      body: loading
          ? const Center(child: CircularProgressIndicator(color: _primary))
          : RefreshIndicator(
              onRefresh: _load,
              child: ListView(
                physics: const AlwaysScrollableScrollPhysics(),
                padding: const EdgeInsets.fromLTRB(16, 16, 16, 100),
                children: [
                  Container(
                    padding: const EdgeInsets.all(20),
                    decoration: BoxDecoration(
                      gradient: const LinearGradient(colors: [_primary, Color(0xFF2563EB)]),
                      borderRadius: BorderRadius.circular(22),
                    ),
                    child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                      Text('SALDO BELUM DICAIRKAN', style: TextStyle(color: Colors.white.withOpacity(0.78), fontSize: 11, fontWeight: FontWeight.w800)),
                      const SizedBox(height: 7),
                      Text(_currency(data['available_balance']), style: const TextStyle(color: Colors.white, fontSize: 28, fontWeight: FontWeight.w900)),
                      const SizedBox(height: 12),
                      Row(children: [
                        Expanded(child: Text('${data['available_order_count'] ?? orders.length} order berbayar', style: const TextStyle(color: Colors.white70, fontSize: 11.5))),
                        Expanded(child: Text('$eligibleCount order siap dicairkan', textAlign: TextAlign.end, style: const TextStyle(color: Colors.white70, fontSize: 11.5))),
                      ]),
                      const SizedBox(height: 6),
                      Text('Siap dicairkan: ${_currency(data['eligible_payout_balance'])}', style: const TextStyle(color: Colors.white, fontSize: 13, fontWeight: FontWeight.w800)),
                    ]),
                  ),
                  const SizedBox(height: 20),
                  const Text('Daftar Order Toko Belum Dicairkan', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w900)),
                  const SizedBox(height: 5),
                  Text(
                    'Semua order di bawah sudah dibayar. Order baru dapat dipilih untuk pencairan setelah 3 x 24 jam dari waktu transaksi approved.',
                    style: TextStyle(fontSize: 12, color: Colors.grey[600]),
                  ),
                  const SizedBox(height: 12),
                  if (orders.isEmpty)
                    Container(
                      padding: const EdgeInsets.all(28),
                      decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(18)),
                      child: const Center(child: Text('Tidak ada order berbayar yang belum dicairkan.')),
                    )
                  else
                    ...orders.map((raw) {
                      final order = _map(raw);
                      final eligible = order['payout_eligible'] == true;
                      final items = order['items'] is List ? order['items'] as List : <dynamic>[];
                      final remainingHours = int.tryParse(order['remaining_hours']?.toString() ?? '0') ?? 0;
                      return Card(
                        margin: const EdgeInsets.only(bottom: 12),
                        elevation: 0,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(18),
                          side: const BorderSide(color: Color(0xFFE2E8F0)),
                        ),
                        child: ExpansionTile(
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
                          collapsedShape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
                          leading: Container(
                            width: 44,
                            height: 44,
                            decoration: BoxDecoration(color: _primary.withOpacity(0.09), borderRadius: BorderRadius.circular(14)),
                            child: const Icon(Icons.receipt_long_outlined, color: _primary),
                          ),
                          title: Row(children: [
                            Expanded(child: Text(order['order_number']?.toString() ?? '#${order['id']}', style: const TextStyle(fontWeight: FontWeight.w900, fontSize: 13))),
                            Text(_currency(order['amount']), style: const TextStyle(fontWeight: FontWeight.w900, color: _success, fontSize: 12.5)),
                          ]),
                          subtitle: Padding(
                            padding: const EdgeInsets.only(top: 5),
                            child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                              Text('${order['buyer_name'] ?? '-'} • ${order['status_label'] ?? order['status'] ?? '-'}', style: TextStyle(fontSize: 11, color: Colors.grey[700])),
                              const SizedBox(height: 5),
                              Row(children: [
                                if (eligible)
                                  _badge('Siap dicairkan', _success)
                                else
                                  _badge(remainingHours > 0 ? 'Tunggu ±$remainingHours jam' : 'Belum 3 hari', Colors.orange.shade800),
                              ]),
                            ]),
                          ),
                          children: [
                            Container(
                              width: double.infinity,
                              margin: const EdgeInsets.fromLTRB(14, 0, 14, 14),
                              padding: const EdgeInsets.all(13),
                              decoration: BoxDecoration(color: const Color(0xFFF8FAFC), borderRadius: BorderRadius.circular(14)),
                              child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                                Text('Pembayaran approved: ${_dateTime(order['payment_approved_at'])}', style: const TextStyle(fontSize: 11.5, fontWeight: FontWeight.w700)),
                                const SizedBox(height: 4),
                                Text('Bisa dicairkan mulai: ${_dateTime(order['payout_available_at'])}', style: TextStyle(fontSize: 11.5, color: Colors.grey[700])),
                                const SizedBox(height: 10),
                                ...items.map((rawItem) {
                                  final item = _map(rawItem);
                                  return Padding(
                                    padding: const EdgeInsets.only(bottom: 5),
                                    child: Row(children: [
                                      Expanded(child: Text('${item['product_name'] ?? 'Produk'} × ${item['quantity'] ?? 0}', style: const TextStyle(fontSize: 11.5))),
                                      Text(_currency(item['line_total']), style: const TextStyle(fontSize: 11.5, fontWeight: FontWeight.w800)),
                                    ]),
                                  );
                                }),
                              ]),
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

import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../../services/manual_payment_api_service.dart';
import 'manual_payment_detail_screen.dart';

class ManualPaymentsScreen extends StatefulWidget {
  const ManualPaymentsScreen({Key? key}) : super(key: key);

  @override
  State<ManualPaymentsScreen> createState() => _ManualPaymentsScreenState();
}

class _ManualPaymentsScreenState extends State<ManualPaymentsScreen>
    with SingleTickerProviderStateMixin {
  static const _primary = Color(0xFF1E3A8A);
  late final TabController _tabController;
  final _searchController = TextEditingController();
  List<Map<String, dynamic>> _payments = [];
  List<Map<String, dynamic>> _accounts = [];
  bool _loadingPayments = true;
  bool _loadingAccounts = true;
  String _filter = 'all';

  final _filters = const <String, String>{
    'all': 'Semua',
    'proof_submitted': 'Menunggu Verifikasi',
    'waiting_payment': 'Belum Dibayar',
    'proof_rejected': 'Bukti Ditolak',
    'approved': 'Dibayar',
    'expired': 'Kedaluwarsa',
    'canceled': 'Dibatalkan',
  };

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this)
      ..addListener(() => setState(() {}));
    _loadAll();
  }

  @override
  void dispose() {
    _tabController.dispose();
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _loadAll() async {
    await Future.wait([_loadPayments(), _loadAccounts()]);
  }

  Future<void> _loadPayments() async {
    setState(() => _loadingPayments = true);
    final response = await ManualPaymentApiService.adminPayments(
      status: _filter,
      search: _searchController.text,
    );
    if (!mounted) return;
    final pagination = response?['data'];
    final rows = pagination is Map ? pagination['data'] : null;
    setState(() {
      _payments = rows is List
          ? rows
                .whereType<Map>()
                .map((item) => Map<String, dynamic>.from(item))
                .toList()
          : [];
      _loadingPayments = false;
    });
  }

  Future<void> _loadAccounts() async {
    setState(() => _loadingAccounts = true);
    final accounts = await ManualPaymentApiService.accounts();
    if (!mounted) return;
    setState(() {
      _accounts = accounts ?? [];
      _loadingAccounts = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF4F6F9),
      appBar: AppBar(
        backgroundColor: _primary,
        foregroundColor: Colors.white,
        title: const Text(
          'Pembayaran User',
          style: TextStyle(fontWeight: FontWeight.w800),
        ),
        bottom: TabBar(
          controller: _tabController,
          indicatorColor: Colors.white,
          labelColor: Colors.white,
          unselectedLabelColor: Colors.white70,
          tabs: const [
            Tab(text: 'Daftar Pembayaran'),
            Tab(text: 'Rekening / VA'),
          ],
        ),
      ),
      floatingActionButton: _tabController.index == 1
          ? FloatingActionButton.extended(
              onPressed: () => _showAccountDialog(),
              backgroundColor: _primary,
              foregroundColor: Colors.white,
              icon: const Icon(Icons.add_card_rounded),
              label: const Text('Tambah VA'),
            )
          : null,
      body: TabBarView(
        controller: _tabController,
        children: [_paymentsTab(), _accountsTab()],
      ),
    );
  }

  Widget _paymentsTab() {
    return RefreshIndicator(
      onRefresh: _loadPayments,
      child: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          TextField(
            controller: _searchController,
            textInputAction: TextInputAction.search,
            onSubmitted: (_) => _loadPayments(),
            decoration: InputDecoration(
              hintText: 'Cari Order ID, nama, atau telepon',
              prefixIcon: const Icon(Icons.search_rounded),
              suffixIcon: IconButton(
                onPressed: _loadPayments,
                icon: const Icon(Icons.arrow_forward_rounded),
              ),
              filled: true,
              fillColor: Colors.white,
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(16),
                borderSide: BorderSide.none,
              ),
            ),
          ),
          const SizedBox(height: 12),
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: Row(
              children: _filters.entries.map((entry) {
                return Padding(
                  padding: const EdgeInsets.only(right: 8),
                  child: ChoiceChip(
                    label: Text(entry.value),
                    selected: _filter == entry.key,
                    onSelected: (_) {
                      setState(() => _filter = entry.key);
                      _loadPayments();
                    },
                  ),
                );
              }).toList(),
            ),
          ),
          const SizedBox(height: 12),
          if (_loadingPayments)
            const Padding(
              padding: EdgeInsets.all(50),
              child: Center(child: CircularProgressIndicator()),
            )
          else if (_payments.isEmpty)
            _emptyState(
              Icons.receipt_long_outlined,
              ManualPaymentApiService.lastError ??
                  'Belum ada pembayaran pada filter ini.',
            )
          else
            ..._payments.map(_paymentCard),
        ],
      ),
    );
  }

  Widget _paymentCard(Map<String, dynamic> payment) {
    final state = payment['payment_state']?.toString() ?? 'waiting_payment';
    final color = _stateColor(state);
    final latest = payment['latest_confirmation'] is Map
        ? Map<String, dynamic>.from(payment['latest_confirmation'])
        : <String, dynamic>{};
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(18),
        side: BorderSide(color: color.withOpacity(.25)),
      ),
      child: InkWell(
        borderRadius: BorderRadius.circular(18),
        onTap: () async {
          await Navigator.push(
            context,
            MaterialPageRoute(
              builder: (_) => ManualPaymentDetailScreen(
                orderId: int.parse(payment['id'].toString()),
              ),
            ),
          );
          if (mounted) _loadPayments();
        },
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Expanded(
                    child: Text(
                      payment['order_number']?.toString() ?? '-',
                      style: const TextStyle(
                        fontWeight: FontWeight.w900,
                        fontSize: 15,
                      ),
                    ),
                  ),
                  _stateChip(state),
                ],
              ),
              const SizedBox(height: 10),
              Text(
                payment['buyer_name']?.toString() ?? '-',
                style: const TextStyle(fontWeight: FontWeight.w700),
              ),
              const SizedBox(height: 4),
              Text(
                _currency(payment['total']),
                style: const TextStyle(
                  color: _primary,
                  fontSize: 16,
                  fontWeight: FontWeight.w900,
                ),
              ),
              const Divider(height: 24),
              Row(
                children: [
                  const Icon(
                    Icons.account_balance_outlined,
                    size: 17,
                    color: Colors.black54,
                  ),
                  const SizedBox(width: 7),
                  Expanded(
                    child: Text(
                      '${payment['destination_bank'] ?? '-'} • ${payment['destination_account'] ?? '-'}',
                      style: const TextStyle(
                        fontSize: 12,
                        color: Colors.black54,
                      ),
                    ),
                  ),
                ],
              ),
              if (latest.isNotEmpty) ...[
                const SizedBox(height: 7),
                Text(
                  'Bukti: ${latest['sender_bank'] ?? '-'} • ${latest['sender_account_number'] ?? '-'}',
                  style: const TextStyle(fontSize: 12, color: Colors.black54),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }

  Widget _accountsTab() {
    return RefreshIndicator(
      onRefresh: _loadAccounts,
      child: ListView(
        padding: const EdgeInsets.fromLTRB(16, 16, 16, 100),
        children: [
          Container(
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: const Color(0xFFEFF6FF),
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: const Color(0xFFBFDBFE)),
            ),
            child: const Text(
              'Opsi A aktif: semua order baru memakai satu rekening/VA utama. Order lama tetap memakai snapshot rekening saat order dibuat.',
              style: TextStyle(fontSize: 12.5, height: 1.4),
            ),
          ),
          const SizedBox(height: 14),
          if (_loadingAccounts)
            const Padding(
              padding: EdgeInsets.all(50),
              child: Center(child: CircularProgressIndicator()),
            )
          else if (_accounts.isEmpty)
            _emptyState(
              Icons.add_card_rounded,
              'Belum ada rekening/VA. Tekan Tambah VA untuk mengaktifkan checkout.',
            )
          else
            ..._accounts.map(_accountCard),
        ],
      ),
    );
  }

  Widget _accountCard(Map<String, dynamic> account) {
    final primary = account['is_primary'] == true || account['is_primary'] == 1;
    final active = account['is_active'] == true || account['is_active'] == 1;
    return Card(
      elevation: 0,
      margin: const EdgeInsets.only(bottom: 12),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(18),
        side: BorderSide(
          color: primary ? _primary.withOpacity(.45) : Colors.grey.shade200,
        ),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Expanded(
                  child: Text(
                    account['label']?.toString().isNotEmpty == true
                        ? account['label'].toString()
                        : account['bank_name']?.toString() ?? '-',
                  ),
                ),
                if (primary)
                  const Chip(
                    label: Text('UTAMA', style: TextStyle(fontSize: 10)),
                    visualDensity: VisualDensity.compact,
                  ),
              ],
            ),
            Text(
              account['bank_name']?.toString() ?? '-',
              style: const TextStyle(fontWeight: FontWeight.w800),
            ),
            const SizedBox(height: 5),
            SelectableText(
              account['account_number']?.toString() ?? '-',
              style: const TextStyle(
                color: _primary,
                fontWeight: FontWeight.w900,
                fontSize: 18,
              ),
            ),
            Text(
              'a.n. ${account['account_name'] ?? '-'}',
              style: const TextStyle(color: Colors.black54),
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                Icon(
                  active ? Icons.check_circle : Icons.pause_circle,
                  size: 18,
                  color: active ? Colors.green : Colors.orange,
                ),
                const SizedBox(width: 6),
                Text(active ? 'Aktif' : 'Nonaktif'),
                const Spacer(),
                TextButton(
                  onPressed: () => _showAccountDialog(account: account),
                  child: const Text('Edit'),
                ),
                if (!primary)
                  TextButton(
                    onPressed: () => _setPrimary(account),
                    child: const Text('Jadikan Utama'),
                  ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _setPrimary(Map<String, dynamic> account) async {
    final ok = await ManualPaymentApiService.setPrimaryAccount(
      int.parse(account['id'].toString()),
    );
    if (!mounted) return;
    _snack(
      ok
          ? 'Rekening/VA utama diperbarui.'
          : ManualPaymentApiService.lastError ??
                'Gagal menetapkan rekening utama.',
      error: !ok,
    );
    if (ok) _loadAccounts();
  }

  Future<void> _showAccountDialog({Map<String, dynamic>? account}) async {
    final bank = TextEditingController(text: account?['bank_name']?.toString());
    final number = TextEditingController(
      text: account?['account_number']?.toString(),
    );
    final name = TextEditingController(
      text: account?['account_name']?.toString(),
    );
    final label = TextEditingController(text: account?['label']?.toString());
    final instructions = TextEditingController(
      text: account?['instructions']?.toString(),
    );
    var type = account?['account_type']?.toString() ?? 'virtual_account';
    var active =
        account == null ||
        account['is_active'] == true ||
        account['is_active'] == 1;
    var primary =
        account == null ||
        account['is_primary'] == true ||
        account['is_primary'] == 1;

    final saved = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => StatefulBuilder(
        builder: (context, setDialogState) => AlertDialog(
          title: Text(
            account == null ? 'Tambah Rekening / VA' : 'Edit Rekening / VA',
          ),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                DropdownButtonFormField<String>(
                  value: type,
                  decoration: const InputDecoration(labelText: 'Jenis akun'),
                  items: const [
                    DropdownMenuItem(
                      value: 'virtual_account',
                      child: Text('Virtual Account'),
                    ),
                    DropdownMenuItem(
                      value: 'bank_account',
                      child: Text('Rekening Bank'),
                    ),
                  ],
                  onChanged: (value) => setDialogState(() => type = value!),
                ),
                TextField(
                  controller: bank,
                  decoration: const InputDecoration(labelText: 'Nama bank'),
                ),
                TextField(
                  controller: number,
                  keyboardType: TextInputType.number,
                  decoration: const InputDecoration(
                    labelText: 'Nomor rekening / VA',
                  ),
                ),
                TextField(
                  controller: name,
                  decoration: const InputDecoration(labelText: 'Nama pemilik'),
                ),
                TextField(
                  controller: label,
                  decoration: const InputDecoration(
                    labelText: 'Label internal (opsional)',
                  ),
                ),
                TextField(
                  controller: instructions,
                  maxLines: 3,
                  decoration: const InputDecoration(
                    labelText: 'Instruksi pembayaran (opsional)',
                  ),
                ),
                SwitchListTile(
                  contentPadding: EdgeInsets.zero,
                  title: const Text('Aktif'),
                  value: active,
                  onChanged: (value) => setDialogState(() => active = value),
                ),
                SwitchListTile(
                  contentPadding: EdgeInsets.zero,
                  title: const Text('Jadikan akun utama'),
                  value: primary,
                  onChanged: (value) => setDialogState(() => primary = value),
                ),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(dialogContext, false),
              child: const Text('Batal'),
            ),
            FilledButton(
              onPressed: () async {
                if (bank.text.trim().isEmpty ||
                    number.text.trim().isEmpty ||
                    name.text.trim().isEmpty) {
                  _snack(
                    'Nama bank, nomor, dan nama pemilik wajib diisi.',
                    error: true,
                  );
                  return;
                }
                final payload = <String, dynamic>{
                  'account_type': type,
                  'bank_name': bank.text.trim(),
                  'account_number': number.text.trim(),
                  'account_name': name.text.trim(),
                  'label': label.text.trim(),
                  'instructions': instructions.text.trim(),
                  'is_active': active,
                  'is_primary': primary,
                };
                final ok = account == null
                    ? await ManualPaymentApiService.createAccount(payload)
                    : await ManualPaymentApiService.updateAccount(
                        int.parse(account['id'].toString()),
                        payload,
                      );
                if (!dialogContext.mounted) return;
                if (ok) {
                  Navigator.pop(dialogContext, true);
                } else {
                  _snack(
                    ManualPaymentApiService.lastError ??
                        'Gagal menyimpan rekening/VA.',
                    error: true,
                  );
                }
              },
              child: const Text('Simpan'),
            ),
          ],
        ),
      ),
    );
    bank.dispose();
    number.dispose();
    name.dispose();
    label.dispose();
    instructions.dispose();
    if (saved == true) {
      _snack('Rekening/VA berhasil disimpan.');
      _loadAccounts();
    }
  }

  Widget _stateChip(String state) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 5),
      decoration: BoxDecoration(
        color: _stateColor(state).withOpacity(.12),
        borderRadius: BorderRadius.circular(99),
      ),
      child: Text(
        _stateLabel(state),
        style: TextStyle(
          color: _stateColor(state),
          fontSize: 10,
          fontWeight: FontWeight.w900,
        ),
      ),
    );
  }

  Color _stateColor(String state) => switch (state) {
    'proof_submitted' => Colors.orange,
    'proof_rejected' => Colors.redAccent,
    'payment_approved' => Colors.green,
    'expired' || 'canceled' => Colors.red,
    _ => Colors.blueGrey,
  };

  String _stateLabel(String state) => switch (state) {
    'proof_submitted' => 'MENUNGGU VERIFIKASI',
    'proof_rejected' => 'BUKTI DITOLAK',
    'payment_approved' => 'DIBAYAR',
    'expired' => 'KEDALUWARSA',
    'canceled' => 'DIBATALKAN',
    _ => 'BELUM DIBAYAR',
  };

  String _currency(dynamic value) => NumberFormat.currency(
    locale: 'id_ID',
    symbol: 'Rp ',
    decimalDigits: 0,
  ).format(double.tryParse(value?.toString() ?? '0') ?? 0);

  Widget _emptyState(IconData icon, String text) => Padding(
    padding: const EdgeInsets.symmetric(vertical: 60, horizontal: 20),
    child: Column(
      children: [
        Icon(icon, size: 52, color: Colors.grey.shade400),
        const SizedBox(height: 12),
        Text(
          text,
          textAlign: TextAlign.center,
          style: const TextStyle(color: Colors.black54),
        ),
      ],
    ),
  );

  void _snack(String message, {bool error = false}) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: error ? Colors.red : null,
        behavior: SnackBarBehavior.floating,
      ),
    );
  }
}

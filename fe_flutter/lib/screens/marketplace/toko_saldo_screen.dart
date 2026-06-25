import 'package:flutter/material.dart';
import '../../services/marketplace_api_service.dart';

class TokoSaldoScreen extends StatefulWidget {
  const TokoSaldoScreen({Key? key}) : super(key: key);

  @override
  State<TokoSaldoScreen> createState() => _TokoSaldoScreenState();
}

class _TokoSaldoScreenState extends State<TokoSaldoScreen> {
  static const Color navy = Color(0xFF0B1F3A);

  final TextEditingController rekeningController = TextEditingController();
  final TextEditingController pemilikController = TextEditingController();

  Map<String, dynamic> data = {};
  bool loading = true;
  bool saving = false;
  bool editingBank = false;
  String? selectedBank;

  @override
  void initState() {
    super.initState();
    loadBalance();
  }

  @override
  void dispose() {
    rekeningController.dispose();
    pemilikController.dispose();
    super.dispose();
  }

  Future<void> loadBalance() async {
    if (!mounted) return;
    setState(() => loading = true);
    final result = await MarketplaceApiService.sellerBalance();
    if (!mounted) return;
    setState(() {
      data = result ?? {};
      final bank = bankAccount;
      selectedBank = _validBank(bank['bank_code']?.toString() ?? bank['bank_name']?.toString()) ?? selectedBank;
      rekeningController.text = bank['bank_account_number']?.toString() ?? '';
      pemilikController.text = bank['bank_account_name']?.toString() ?? '';
      editingBank = !hasBankAccount;
      loading = false;
    });
  }

  Map<String, dynamic> get summary => _asMap(data['summary']);
  Map<String, dynamic> get bankAccount => _asMap(data['bank_account']);
  List<dynamic> get balances => data['balances'] as List? ?? [];
  List<dynamic> get withdrawals => data['withdrawals'] as List? ?? [];
  double get availableBalance => _num(summary['available_balance']);
  double get minimumWithdrawal => _num(data['minimum_withdrawal_amount'] ?? 10000);
  bool get isSandbox => data['is_sandbox'] == true;

  bool get hasBankAccount {
    final code = _validBank(bankAccount['bank_code']?.toString() ?? bankAccount['bank_name']?.toString());
    return code != null &&
        (bankAccount['bank_account_number']?.toString().trim().isNotEmpty ?? false) &&
        (bankAccount['bank_account_name']?.toString().trim().isNotEmpty ?? false);
  }

  Map<String, dynamic> _asMap(dynamic value) {
    if (value is Map<String, dynamic>) return value;
    if (value is Map) return Map<String, dynamic>.from(value);
    return {};
  }

  double _num(dynamic value) {
    if (value is num) return value.toDouble();
    return double.tryParse(value?.toString() ?? '0') ?? 0;
  }

  String _currency(dynamic value) {
    final text = _num(value).toStringAsFixed(0);
    final buffer = StringBuffer();
    for (int i = 0; i < text.length; i++) {
      final reverseIndex = text.length - i;
      buffer.write(text[i]);
      if (reverseIndex > 1 && reverseIndex % 3 == 1) buffer.write('.');
    }
    return 'Rp ${buffer.toString()}';
  }

  List<Map<String, String>> get bankOptions {
    final raw = data['bank_options'];
    if (raw is List) {
      final result = raw.map((item) {
        final map = item as Map? ?? {};
        return {'code': map['code']?.toString() ?? '', 'label': map['label']?.toString() ?? ''};
      }).where((item) => item['code']!.isNotEmpty && item['label']!.isNotEmpty).toList();
      if (result.isNotEmpty) return result;
    }
    return const [
      {'code': 'bca', 'label': 'BCA'},
      {'code': 'bni', 'label': 'BNI'},
      {'code': 'bri', 'label': 'BRI'},
      {'code': 'mandiri', 'label': 'Mandiri'},
      {'code': 'permata', 'label': 'Permata Bank'},
      {'code': 'cimb', 'label': 'CIMB Niaga'},
    ];
  }

  String? _validBank(String? code) {
    if (code == null || code.trim().isEmpty) return null;
    final clean = code.trim();
    return bankOptions.any((bank) => bank['code'] == clean) ? clean : null;
  }

  String bankLabel(String? code) {
    final valid = _validBank(code);
    if (valid == null) return '-';
    return bankOptions.firstWhere((bank) => bank['code'] == valid)['label'] ?? valid.toUpperCase();
  }

  Future<void> saveBank() async {
    final bank = _validBank(selectedBank);
    final rekening = rekeningController.text.trim();
    final pemilik = pemilikController.text.trim();

    if (bank == null || rekening.isEmpty || pemilik.isEmpty) {
      showMessage('Lengkapi nama bank, nomor rekening, dan nama pemilik rekening.');
      return;
    }

    setState(() => saving = true);
    final result = await MarketplaceApiService.saveSellerBankAccount(
      bankName: bank,
      bankAccountNumber: rekening,
      bankAccountName: pemilik,
    );
    if (!mounted) return;
    setState(() => saving = false);

    if (result == null) {
      showMessage('Gagal menyimpan rekening.');
      return;
    }

    showMessage('Rekening berhasil disimpan.');
    setState(() => editingBank = false);
    await loadBalance();
  }

  Future<void> openWithdrawalDialog() async {
    if (!hasBankAccount) {
      setState(() => editingBank = true);
      showMessage('Simpan rekening toko terlebih dahulu.');
      return;
    }

    if (availableBalance <= 0) {
      showMessage('Belum ada saldo yang bisa ditarik.');
      return;
    }

    final bank = bankAccount;
    final result = await showDialog<Map<String, dynamic>>(
      context: context,
      barrierDismissible: false,
      builder: (_) => _TarikSaldoDialog(
        availableBalance: availableBalance,
        minimumWithdrawal: minimumWithdrawal,
        bankLabel: bankLabel(bank['bank_code']?.toString() ?? bank['bank_name']?.toString()),
        bankNumber: bank['bank_account_number']?.toString() ?? '-',
        bankOwner: bank['bank_account_name']?.toString() ?? '-',
        currency: _currency,
      ),
    );

    if (!mounted || result == null) return;
    final success = result['success'] == true;
    showMessage(result['message']?.toString() ?? (success ? 'Request tarik saldo berhasil dibuat.' : 'Gagal membuat request tarik saldo.'));
    if (success) await loadBalance();
  }

  void showMessage(String message) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(message)));
  }

  Widget summaryCard(String title, dynamic value, IconData icon, Color color) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(18), border: Border.all(color: const Color(0xFFE5EAF3))),
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Icon(icon, color: color),
          const SizedBox(height: 10),
          Text(title, style: TextStyle(fontSize: 11, color: Colors.grey.shade600, fontWeight: FontWeight.w700)),
          const SizedBox(height: 4),
          Text(_currency(value), maxLines: 1, overflow: TextOverflow.ellipsis, style: const TextStyle(fontSize: 15, color: navy, fontWeight: FontWeight.w900)),
        ]),
      ),
    );
  }

  Widget miniRow(String label, dynamic value, {bool bold = false}) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 7),
      child: Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
        SizedBox(width: 128, child: Text(label, style: TextStyle(fontSize: 12, color: Colors.grey.shade600))),
        Expanded(child: Text(value?.toString() ?? '-', style: TextStyle(fontSize: 12, fontWeight: bold ? FontWeight.w900 : FontWeight.w700, color: bold ? navy : Colors.black87))),
      ]),
    );
  }

  Widget statusChip(String label, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(color: color.withOpacity(0.12), borderRadius: BorderRadius.circular(999)),
      child: Text(label, style: TextStyle(color: color, fontSize: 11, fontWeight: FontWeight.w800)),
    );
  }

  Color balanceColor(String status) {
    if (status == 'available') return const Color(0xFF15803D);
    if (status == 'pending') return const Color(0xFFEAB308);
    if (status == 'withdrawn') return const Color(0xFF0F766E);
    if (status == 'cancelled' || status == 'canceled') return const Color(0xFFB91C1C);
    return Colors.grey;
  }

  Color withdrawalColor(String status) {
    if (status == 'paid') return const Color(0xFF15803D);
    if (status == 'pending') return const Color(0xFFEAB308);
    if (status == 'approved' || status == 'processing') return const Color(0xFF7C3AED);
    if (status == 'failed' || status == 'rejected') return const Color(0xFFB91C1C);
    return Colors.grey;
  }

  Widget bankCard() {
    final storedCode = _validBank(bankAccount['bank_code']?.toString() ?? bankAccount['bank_name']?.toString());

    return Container(
      margin: const EdgeInsets.only(bottom: 14),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(20), border: Border.all(color: const Color(0xFFE5EAF3))),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Row(children: [
          const Icon(Icons.account_balance_outlined, color: navy),
          const SizedBox(width: 10),
          const Expanded(child: Text('Rekening Penarikan', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w900, color: navy))),
          if (hasBankAccount)
            TextButton.icon(
              onPressed: saving ? null : () => setState(() => editingBank = !editingBank),
              icon: Icon(editingBank ? Icons.close : Icons.edit_outlined, size: 16),
              label: Text(editingBank ? 'Batal' : 'Edit'),
            ),
        ]),
        const SizedBox(height: 12),
        if (!editingBank && hasBankAccount) ...[
          miniRow('Nama rekening', bankLabel(storedCode)),
          miniRow('Nama pemilik rekening', bankAccount['bank_account_name'] ?? '-'),
          miniRow('No. rek', bankAccount['bank_account_number'] ?? '-'),
          miniRow('Kode Midtrans', storedCode ?? '-'),
        ] else ...[
          if (!hasBankAccount)
            Container(
              width: double.infinity,
              margin: const EdgeInsets.only(bottom: 12),
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(color: const Color(0xFFFFFBEB), borderRadius: BorderRadius.circular(14), border: Border.all(color: const Color(0xFFFDE68A))),
              child: const Text('Belum ada rekening penarikan. Isi data rekening toko terlebih dahulu.', style: TextStyle(fontSize: 12, color: Color(0xFF92400E), fontWeight: FontWeight.w700)),
            ),
          DropdownButtonFormField<String>(
            value: _validBank(selectedBank),
            isExpanded: true,
            items: bankOptions.map((bank) => DropdownMenuItem(value: bank['code'], child: Text('${bank['label']} (${bank['code']})'))).toList(),
            onChanged: (value) => setState(() => selectedBank = value),
            decoration: inputDecoration('Nama bank'),
          ),
          const SizedBox(height: 12),
          TextField(controller: rekeningController, keyboardType: TextInputType.number, onChanged: (_) => setState(() {}), decoration: inputDecoration('Bank account number / nomor rekening')),
          const SizedBox(height: 12),
          TextField(controller: pemilikController, onChanged: (_) => setState(() {}), decoration: inputDecoration('Bank account name / nama pemilik rekening')),
          const SizedBox(height: 12),
          SizedBox(
            width: double.infinity,
            child: ElevatedButton.icon(
              onPressed: saving ? null : saveBank,
              icon: saving ? const SizedBox(width: 16, height: 16, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white)) : const Icon(Icons.save_outlined),
              label: Text(saving ? 'Menyimpan...' : 'Simpan Rekening'),
              style: ElevatedButton.styleFrom(backgroundColor: navy, foregroundColor: Colors.white, minimumSize: const Size.fromHeight(46), shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14))),
            ),
          ),
        ],
      ]),
    );
  }

  InputDecoration inputDecoration(String label) {
    return InputDecoration(
      labelText: label,
      filled: true,
      fillColor: const Color(0xFFF8FAFC),
      border: OutlineInputBorder(borderRadius: BorderRadius.circular(14), borderSide: BorderSide(color: Colors.grey.shade200)),
      enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(14), borderSide: BorderSide(color: Colors.grey.shade200)),
    );
  }

  Widget incomeCard(dynamic item) {
    final map = item as Map? ?? {};
    final status = map['status']?.toString() ?? '-';
    final color = balanceColor(status);
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(18), border: Border.all(color: const Color(0xFFE5EAF3))),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Row(children: [
          const Icon(Icons.receipt_long_outlined, color: navy),
          const SizedBox(width: 10),
          Expanded(child: Text(map['product_name']?.toString() ?? 'Produk', maxLines: 1, overflow: TextOverflow.ellipsis, style: const TextStyle(fontWeight: FontWeight.w900, color: navy))),
          statusChip(map['status_label']?.toString() ?? status, color),
        ]),
        const SizedBox(height: 12),
        miniRow('Order', '#${map['order_id'] ?? '-'}'),
        miniRow('Pendapatan kotor', _currency(map['gross_amount'])),
        miniRow('Fee platform', _currency(map['platform_fee'])),
        miniRow('Saldo toko', _currency(map['amount']), bold: true),
        if (map['available_at'] != null) miniRow('Bisa ditarik', map['available_at']),
      ]),
    );
  }

  Widget withdrawalCard(dynamic item) {
    final map = item as Map? ?? {};
    final status = map['status']?.toString() ?? '-';
    final color = withdrawalColor(status);
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(18), border: Border.all(color: const Color(0xFFE5EAF3))),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Row(children: [
          Icon(Icons.account_balance_outlined, color: color),
          const SizedBox(width: 10),
          Expanded(child: Text(_currency(map['amount']), style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w900, color: navy))),
          statusChip(map['status_label']?.toString() ?? status, color),
        ]),
        const SizedBox(height: 12),
        miniRow('Nama rekening', map['bank_account_name'] ?? '-'),
        miniRow('Bank', map['bank_label'] ?? bankLabel(map['bank_name']?.toString())),
        miniRow('No. rek', map['bank_account_number'] ?? '-'),
        miniRow('Tanggal request', map['created_at'] ?? '-'),
        if (map['paid_at'] != null) miniRow('Tanggal cair', map['paid_at']),
      ]),
    );
  }

  Widget empty(String text, IconData icon) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 48),
        child: Column(children: [
          Icon(icon, size: 64, color: Colors.grey.shade400),
          const SizedBox(height: 10),
          Text(text, textAlign: TextAlign.center, style: TextStyle(color: Colors.grey.shade700)),
        ]),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return DefaultTabController(
      length: 2,
      child: Scaffold(
        backgroundColor: const Color(0xFFF4F7FB),
        appBar: AppBar(
          title: const Text('Saldo & Pendapatan', style: TextStyle(fontWeight: FontWeight.w800)),
          backgroundColor: navy,
          foregroundColor: Colors.white,
          bottom: const TabBar(
            indicatorColor: Colors.white,
            labelColor: Colors.white,
            unselectedLabelColor: Colors.white70,
            tabs: [Tab(text: 'Pendapatan Order'), Tab(text: 'Riwayat Tarik')],
          ),
        ),
        body: loading
            ? const Center(child: CircularProgressIndicator())
            : RefreshIndicator(
                onRefresh: loadBalance,
                child: ListView(padding: const EdgeInsets.all(16), children: [
                  if (isSandbox)
                    Container(
                      margin: const EdgeInsets.only(bottom: 12),
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(color: const Color(0xFFEFF6FF), borderRadius: BorderRadius.circular(14), border: Border.all(color: const Color(0xFFBFDBFE))),
                      child: const Text('Mode sandbox/developer: saldo dari order settlement langsung menjadi Bisa Ditarik.', style: TextStyle(color: Color(0xFF1D4ED8), fontWeight: FontWeight.w700)),
                    ),
                  bankCard(),
                  Container(
                    padding: const EdgeInsets.all(18),
                    decoration: BoxDecoration(gradient: const LinearGradient(colors: [navy, Color(0xFF123B6D)]), borderRadius: BorderRadius.circular(22)),
                    child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                      const Text('Total Pendapatan Toko', style: TextStyle(color: Colors.white70, fontSize: 13, fontWeight: FontWeight.w700)),
                      const SizedBox(height: 6),
                      Text(_currency(summary['total_income']), style: const TextStyle(color: Colors.white, fontSize: 28, fontWeight: FontWeight.w900)),
                      const SizedBox(height: 8),
                      Text(hasBankAccount ? 'Rekening aktif: ${bankLabel(bankAccount['bank_code']?.toString() ?? bankAccount['bank_name']?.toString())} • ${bankAccount['bank_account_number']}' : 'Lengkapi rekening toko sebelum tarik saldo.', style: const TextStyle(color: Colors.white70, fontSize: 12, fontWeight: FontWeight.w700)),
                      const SizedBox(height: 14),
                      SizedBox(
                        width: double.infinity,
                        child: ElevatedButton.icon(
                          onPressed: (availableBalance <= 0 || !hasBankAccount) ? null : openWithdrawalDialog,
                          icon: const Icon(Icons.account_balance_outlined),
                          label: const Text('Tarik ke Rekening'),
                          style: ElevatedButton.styleFrom(backgroundColor: Colors.white, foregroundColor: navy, disabledBackgroundColor: Colors.white24, disabledForegroundColor: Colors.white70, minimumSize: const Size.fromHeight(44), shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14))),
                        ),
                      ),
                    ]),
                  ),
                  const SizedBox(height: 14),
                  Row(children: [summaryCard('Pending', summary['pending_balance'], Icons.hourglass_top_rounded, const Color(0xFFEAB308)), const SizedBox(width: 10), summaryCard('Bisa Ditarik', summary['available_balance'], Icons.account_balance_wallet_outlined, const Color(0xFF15803D))]),
                  const SizedBox(height: 10),
                  Row(children: [summaryCard('Proses Tarik', summary['requested_balance'], Icons.pending_actions_outlined, const Color(0xFF7C3AED)), const SizedBox(width: 10), summaryCard('Sudah Ditarik', summary['withdrawn_balance'], Icons.check_circle_outline, const Color(0xFF0F766E))]),
                  const SizedBox(height: 18),
                  SizedBox(
                    height: MediaQuery.of(context).size.height * 0.58,
                    child: TabBarView(children: [
                      balances.isEmpty ? empty('Belum ada pendapatan order. Saldo akan muncul setelah pembayaran Midtrans settlement.', Icons.receipt_long_outlined) : ListView.builder(padding: EdgeInsets.zero, itemCount: balances.length, itemBuilder: (context, index) => incomeCard(balances[index])),
                      withdrawals.isEmpty ? empty('Belum ada saldo yang ditarik atau request withdrawal.', Icons.account_balance_outlined) : ListView.builder(padding: EdgeInsets.zero, itemCount: withdrawals.length, itemBuilder: (context, index) => withdrawalCard(withdrawals[index])),
                    ]),
                  ),
                ]),
              ),
      ),
    );
  }
}

class _TarikSaldoDialog extends StatefulWidget {
  const _TarikSaldoDialog({
    required this.availableBalance,
    required this.minimumWithdrawal,
    required this.bankLabel,
    required this.bankNumber,
    required this.bankOwner,
    required this.currency,
  });

  final double availableBalance;
  final double minimumWithdrawal;
  final String bankLabel;
  final String bankNumber;
  final String bankOwner;
  final String Function(dynamic value) currency;

  @override
  State<_TarikSaldoDialog> createState() => _TarikSaldoDialogState();
}

class _TarikSaldoDialogState extends State<_TarikSaldoDialog> {
  late final TextEditingController amountController;
  bool submitting = false;
  String? error;

  @override
  void initState() {
    super.initState();
    amountController = TextEditingController(text: widget.availableBalance.toStringAsFixed(0));
  }

  @override
  void dispose() {
    amountController.dispose();
    super.dispose();
  }

  double amountValue() {
    final raw = amountController.text.trim().replaceAll('.', '').replaceAll(',', '.');
    return double.tryParse(raw) ?? 0;
  }

  Future<void> submit() async {
    final amount = amountValue();
    if (amount <= 0) {
      setState(() => error = 'Nominal tarik harus lebih dari 0.');
      return;
    }
    if (amount < widget.minimumWithdrawal) {
      setState(() => error = 'Minimal tarik adalah ${widget.currency(widget.minimumWithdrawal)}.');
      return;
    }
    if (amount > widget.availableBalance) {
      setState(() => error = 'Nominal melebihi saldo tersedia.');
      return;
    }

    setState(() {
      submitting = true;
      error = null;
    });

    final response = await MarketplaceApiService.requestWithdrawal(amount: amount);
    if (!mounted) return;
    Navigator.of(context).pop(response ?? {'success': false, 'message': 'Gagal membuat request tarik saldo.'});
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      title: const Text('Tarik Saldo ke Rekening', style: TextStyle(fontWeight: FontWeight.w900, color: _TokoSaldoScreenState.navy)),
      content: SingleChildScrollView(
        child: Column(mainAxisSize: MainAxisSize.min, crossAxisAlignment: CrossAxisAlignment.start, children: [
          Text('Saldo tersedia: ${widget.currency(widget.availableBalance)}', style: TextStyle(fontSize: 13, color: Colors.grey.shade700, fontWeight: FontWeight.w700)),
          const SizedBox(height: 12),
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(color: const Color(0xFFF8FAFC), borderRadius: BorderRadius.circular(14), border: Border.all(color: const Color(0xFFE5EAF3))),
            child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              const Text('Rekening tujuan', style: TextStyle(fontSize: 12, color: Colors.black54, fontWeight: FontWeight.w800)),
              const SizedBox(height: 8),
              _dialogRow('Nama rekening', widget.bankLabel),
              _dialogRow('Pemilik rekening', widget.bankOwner),
              _dialogRow('No. rek', widget.bankNumber),
            ]),
          ),
          const SizedBox(height: 14),
          TextField(controller: amountController, keyboardType: TextInputType.number, enabled: !submitting, decoration: const InputDecoration(labelText: 'Nominal tarik', border: OutlineInputBorder())),
          const SizedBox(height: 6),
          Text('Minimal tarik: ${widget.currency(widget.minimumWithdrawal)}', style: TextStyle(fontSize: 12, color: Colors.grey.shade600, fontWeight: FontWeight.w700)),
          if (error != null) ...[
            const SizedBox(height: 10),
            Text(error!, style: const TextStyle(fontSize: 12, color: Color(0xFFB91C1C), fontWeight: FontWeight.w800)),
          ],
        ]),
      ),
      actions: [
        TextButton(onPressed: submitting ? null : () => Navigator.of(context).pop(), child: const Text('Batal')),
        ElevatedButton.icon(
          onPressed: submitting ? null : submit,
          icon: submitting ? const SizedBox(width: 16, height: 16, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white)) : const Icon(Icons.account_balance_wallet_outlined),
          label: Text(submitting ? 'Memproses...' : 'Ajukan Penarikan'),
          style: ElevatedButton.styleFrom(backgroundColor: _TokoSaldoScreenState.navy, foregroundColor: Colors.white),
        ),
      ],
    );
  }

  Widget _dialogRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 7),
      child: Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
        SizedBox(width: 112, child: Text(label, style: TextStyle(fontSize: 12, color: Colors.grey.shade600))),
        Expanded(child: Text(value, style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w800, color: Colors.black87))),
      ]),
    );
  }
}

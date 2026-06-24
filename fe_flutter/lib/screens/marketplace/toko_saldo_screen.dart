import 'package:flutter/material.dart';
import '../../services/marketplace_api_service.dart';

class TokoSaldoScreen extends StatefulWidget {
  const TokoSaldoScreen({Key? key}) : super(key: key);

  @override
  State<TokoSaldoScreen> createState() => _TokoSaldoScreenState();
}

class _TokoSaldoScreenState extends State<TokoSaldoScreen> {
  static const Color _navy = Color(0xFF0B1F3A);
  static const Color _softBlue = Color(0xFFEAF1FF);

  Map<String, dynamic>? data;
  bool loading = true;

  @override
  void initState() {
    super.initState();
    loadBalance();
  }

  Future<void> loadBalance() async {
    setState(() => loading = true);
    final result = await MarketplaceApiService.sellerBalance();
    if (!mounted) return;
    setState(() {
      data = result;
      loading = false;
    });
  }

  double _num(dynamic value) {
    if (value is num) return value.toDouble();
    return double.tryParse(value?.toString() ?? '0') ?? 0;
  }

  String _currency(dynamic value) {
    final number = _num(value);
    final text = number.toStringAsFixed(0);
    final buffer = StringBuffer();
    for (int i = 0; i < text.length; i++) {
      final reverseIndex = text.length - i;
      buffer.write(text[i]);
      if (reverseIndex > 1 && reverseIndex % 3 == 1) buffer.write('.');
    }
    return 'Rp ${buffer.toString()}';
  }

  Map<String, dynamic> get _summary {
    final raw = data?['summary'];
    if (raw is Map<String, dynamic>) return raw;
    if (raw is Map) return Map<String, dynamic>.from(raw);
    return {};
  }

  Map<String, dynamic> get _bankAccount {
    final raw = data?['bank_account'];
    if (raw is Map<String, dynamic>) return raw;
    if (raw is Map) return Map<String, dynamic>.from(raw);
    return {};
  }

  bool get _isSandbox => data?['is_sandbox'] == true;

  List<dynamic> get _balances => data?['balances'] as List? ?? [];
  List<dynamic> get _withdrawals => data?['withdrawals'] as List? ?? [];

  double get _availableBalance => _num(_summary['available_balance']);

  Color _balanceStatusColor(String status) {
    switch (status) {
      case 'available':
        return const Color(0xFF15803D);
      case 'pending':
        return const Color(0xFFEAB308);
      case 'withdrawn':
        return const Color(0xFF0F766E);
      case 'withdraw_requested':
        return const Color(0xFF7C3AED);
      case 'cancelled':
      case 'canceled':
        return const Color(0xFFB91C1C);
      default:
        return Colors.grey;
    }
  }

  Color _withdrawalStatusColor(String status) {
    switch (status) {
      case 'paid':
        return const Color(0xFF15803D);
      case 'pending':
        return const Color(0xFFEAB308);
      case 'approved':
      case 'processing':
        return const Color(0xFF7C3AED);
      case 'failed':
      case 'rejected':
        return const Color(0xFFB91C1C);
      default:
        return Colors.grey;
    }
  }

  Widget _summaryCard(String title, dynamic value, IconData icon, Color color) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(18),
          border: Border.all(color: const Color(0xFFE5EAF3)),
          boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.035), blurRadius: 12, offset: const Offset(0, 6))],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              padding: const EdgeInsets.all(9),
              decoration: BoxDecoration(color: color.withOpacity(0.1), borderRadius: BorderRadius.circular(12)),
              child: Icon(icon, color: color, size: 20),
            ),
            const SizedBox(height: 12),
            Text(title, style: TextStyle(fontSize: 11, color: Colors.grey.shade600, fontWeight: FontWeight.w700)),
            const SizedBox(height: 4),
            Text(_currency(value), maxLines: 1, overflow: TextOverflow.ellipsis, style: const TextStyle(fontSize: 15, color: _navy, fontWeight: FontWeight.w900)),
          ],
        ),
      ),
    );
  }

  Widget _statusChip(String label, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(color: color.withOpacity(0.12), borderRadius: BorderRadius.circular(999)),
      child: Text(label, style: TextStyle(color: color, fontSize: 11, fontWeight: FontWeight.w800)),
    );
  }

  Widget _incomeCard(dynamic item) {
    final balance = item as Map? ?? {};
    final status = balance['status']?.toString() ?? '-';
    final color = _balanceStatusColor(status);

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: const Color(0xFFE5EAF3)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 42,
                height: 42,
                decoration: BoxDecoration(color: _softBlue, borderRadius: BorderRadius.circular(13)),
                child: const Icon(Icons.receipt_long_outlined, color: _navy),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(balance['product_name']?.toString() ?? 'Produk', maxLines: 1, overflow: TextOverflow.ellipsis, style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w900, color: _navy)),
                    const SizedBox(height: 3),
                    Text('Order #${balance['order_id'] ?? '-'}', style: TextStyle(fontSize: 12, color: Colors.grey.shade600)),
                  ],
                ),
              ),
              _statusChip(balance['status_label']?.toString() ?? status, color),
            ],
          ),
          const SizedBox(height: 12),
          _miniRow('Pendapatan kotor', _currency(balance['gross_amount'])),
          _miniRow('Fee platform', _currency(balance['platform_fee'])),
          _miniRow('Saldo toko', _currency(balance['amount']), bold: true),
          if (balance['available_at'] != null) _miniRow('Bisa ditarik', balance['available_at']),
        ],
      ),
    );
  }

  Widget _withdrawalCard(dynamic item) {
    final withdrawal = item as Map? ?? {};
    final status = withdrawal['status']?.toString() ?? '-';
    final color = _withdrawalStatusColor(status);

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: const Color(0xFFE5EAF3)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 42,
                height: 42,
                decoration: BoxDecoration(color: color.withOpacity(0.1), borderRadius: BorderRadius.circular(13)),
                child: Icon(Icons.account_balance_outlined, color: color),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(_currency(withdrawal['amount']), style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w900, color: _navy)),
                    const SizedBox(height: 3),
                    Text('${withdrawal['bank_name'] ?? '-'} • ${withdrawal['bank_account_number'] ?? '-'}', style: TextStyle(fontSize: 12, color: Colors.grey.shade600)),
                  ],
                ),
              ),
              _statusChip(withdrawal['status_label']?.toString() ?? status, color),
            ],
          ),
          const SizedBox(height: 10),
          _miniRow('Nama rekening', withdrawal['bank_account_name'] ?? '-'),
          _miniRow('Tanggal request', withdrawal['created_at'] ?? '-'),
          if (withdrawal['paid_at'] != null) _miniRow('Tanggal cair', withdrawal['paid_at']),
        ],
      ),
    );
  }

  Widget _miniRow(String label, dynamic value, {bool bold = false}) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 7),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(width: 112, child: Text(label, style: TextStyle(fontSize: 12, color: Colors.grey.shade600))),
          Expanded(child: Text(value?.toString() ?? '-', style: TextStyle(fontSize: 12, fontWeight: bold ? FontWeight.w900 : FontWeight.w700, color: bold ? _navy : Colors.black87))),
        ],
      ),
    );
  }

  Future<void> _openWithdrawalSheet() async {
    final amountController = TextEditingController(text: _availableBalance.toStringAsFixed(0));
    final bankController = TextEditingController(text: _bankAccount['bank_name']?.toString() ?? '');
    final accountNumberController = TextEditingController(text: _bankAccount['bank_account_number']?.toString() ?? '');
    final accountNameController = TextEditingController(text: _bankAccount['bank_account_name']?.toString() ?? '');

    final success = await showModalBottomSheet<bool>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(24))),
      builder: (context) {
        return Padding(
          padding: EdgeInsets.only(left: 20, right: 20, top: 20, bottom: MediaQuery.of(context).viewInsets.bottom + 20),
          child: SingleChildScrollView(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                const Text('Tarik Saldo ke Rekening', style: TextStyle(fontSize: 18, fontWeight: FontWeight.w900, color: _navy)),
                const SizedBox(height: 6),
                Text('Saldo tersedia: ${_currency(_availableBalance)}', style: TextStyle(fontSize: 13, color: Colors.grey.shade700)),
                const SizedBox(height: 16),
                _input(amountController, 'Nominal tarik', TextInputType.number),
                _input(bankController, 'Nama bank', TextInputType.text),
                _input(accountNumberController, 'Nomor rekening', TextInputType.number),
                _input(accountNameController, 'Nama pemilik rekening', TextInputType.text),
                const SizedBox(height: 10),
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton.icon(
                    onPressed: () async {
                      final amount = double.tryParse(amountController.text.replaceAll('.', '').replaceAll(',', '')) ?? 0;
                      final ok = await MarketplaceApiService.requestWithdrawal(
                        amount: amount,
                        bankName: bankController.text.trim(),
                        bankAccountNumber: accountNumberController.text.trim(),
                        bankAccountName: accountNameController.text.trim(),
                      );
                      if (context.mounted) Navigator.pop(context, ok != null);
                    },
                    icon: const Icon(Icons.account_balance_wallet_outlined),
                    label: const Text('Ajukan Penarikan'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: _navy,
                      foregroundColor: Colors.white,
                      minimumSize: const Size.fromHeight(48),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                    ),
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );

    amountController.dispose();
    bankController.dispose();
    accountNumberController.dispose();
    accountNameController.dispose();

    if (!mounted || success == null) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(success ? 'Request tarik saldo berhasil dibuat' : 'Gagal membuat request tarik saldo')),
    );
    if (success) loadBalance();
  }

  Widget _input(TextEditingController controller, String label, TextInputType type) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: TextField(
        controller: controller,
        keyboardType: type,
        decoration: InputDecoration(
          labelText: label,
          filled: true,
          fillColor: const Color(0xFFF8FAFC),
          border: OutlineInputBorder(borderRadius: BorderRadius.circular(14), borderSide: BorderSide(color: Colors.grey.shade200)),
          enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(14), borderSide: BorderSide(color: Colors.grey.shade200)),
        ),
      ),
    );
  }

  Widget _empty(String text, IconData icon) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(vertical: 48),
      child: Column(
        children: [
          Icon(icon, size: 64, color: Colors.grey.shade400),
          const SizedBox(height: 10),
          Text(text, textAlign: TextAlign.center, style: TextStyle(color: Colors.grey.shade700)),
        ],
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
          backgroundColor: _navy,
          foregroundColor: Colors.white,
          elevation: 0,
          bottom: const TabBar(
            indicatorColor: Colors.white,
            labelColor: Colors.white,
            unselectedLabelColor: Colors.white70,
            tabs: [
              Tab(text: 'Pendapatan Order'),
              Tab(text: 'Riwayat Tarik'),
            ],
          ),
        ),
        body: loading
            ? const Center(child: CircularProgressIndicator())
            : RefreshIndicator(
                onRefresh: loadBalance,
                child: ListView(
                  padding: const EdgeInsets.all(16),
                  children: [
                    if (_isSandbox)
                      Container(
                        margin: const EdgeInsets.only(bottom: 12),
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(color: const Color(0xFFEFF6FF), borderRadius: BorderRadius.circular(14), border: Border.all(color: const Color(0xFFBFDBFE))),
                        child: const Text('Mode sandbox/developer: saldo dari order settlement langsung menjadi Bisa Ditarik.', style: TextStyle(color: Color(0xFF1D4ED8), fontWeight: FontWeight.w700)),
                      ),
                    Container(
                      padding: const EdgeInsets.all(18),
                      decoration: BoxDecoration(
                        gradient: const LinearGradient(colors: [_navy, Color(0xFF123B6D)]),
                        borderRadius: BorderRadius.circular(22),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text('Total Pendapatan Toko', style: TextStyle(color: Colors.white70, fontSize: 13, fontWeight: FontWeight.w700)),
                          const SizedBox(height: 6),
                          Text(_currency(_summary['total_income']), style: const TextStyle(color: Colors.white, fontSize: 28, fontWeight: FontWeight.w900)),
                          const SizedBox(height: 14),
                          SizedBox(
                            width: double.infinity,
                            child: ElevatedButton.icon(
                              onPressed: _availableBalance <= 0 ? null : _openWithdrawalSheet,
                              icon: const Icon(Icons.account_balance_outlined),
                              label: const Text('Tarik ke Rekening'),
                              style: ElevatedButton.styleFrom(
                                backgroundColor: Colors.white,
                                foregroundColor: _navy,
                                disabledBackgroundColor: Colors.white24,
                                disabledForegroundColor: Colors.white70,
                                minimumSize: const Size.fromHeight(44),
                                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 14),
                    Row(children: [
                      _summaryCard('Pending', _summary['pending_balance'], Icons.hourglass_top_rounded, const Color(0xFFEAB308)),
                      const SizedBox(width: 10),
                      _summaryCard('Bisa Ditarik', _summary['available_balance'], Icons.account_balance_wallet_outlined, const Color(0xFF15803D)),
                    ]),
                    const SizedBox(height: 10),
                    Row(children: [
                      _summaryCard('Proses Tarik', _summary['requested_balance'], Icons.pending_actions_outlined, const Color(0xFF7C3AED)),
                      const SizedBox(width: 10),
                      _summaryCard('Sudah Ditarik', _summary['withdrawn_balance'], Icons.check_circle_outline, const Color(0xFF0F766E)),
                    ]),
                    const SizedBox(height: 18),
                    SizedBox(
                      height: MediaQuery.of(context).size.height * 0.58,
                      child: TabBarView(
                        children: [
                          _balances.isEmpty
                              ? _empty('Belum ada pendapatan order. Saldo akan muncul setelah pembayaran Midtrans settlement.', Icons.receipt_long_outlined)
                              : ListView.builder(
                                  padding: EdgeInsets.zero,
                                  itemCount: _balances.length,
                                  itemBuilder: (context, index) => _incomeCard(_balances[index]),
                                ),
                          _withdrawals.isEmpty
                              ? _empty('Belum ada saldo yang ditarik atau request withdrawal.', Icons.account_balance_outlined)
                              : ListView.builder(
                                  padding: EdgeInsets.zero,
                                  itemCount: _withdrawals.length,
                                  itemBuilder: (context, index) => _withdrawalCard(_withdrawals[index]),
                                ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
      ),
    );
  }
}

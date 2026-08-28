import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../../services/manual_payment_api_service.dart';

class ManualPaymentDetailScreen extends StatefulWidget {
  const ManualPaymentDetailScreen({Key? key, required this.orderId})
    : super(key: key);

  final int orderId;

  @override
  State<ManualPaymentDetailScreen> createState() =>
      _ManualPaymentDetailScreenState();
}

class _ManualPaymentDetailScreenState extends State<ManualPaymentDetailScreen> {
  static const _primary = Color(0xFF1E3A8A);
  Map<String, dynamic>? _data;
  bool _loading = true;
  bool _processing = false;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() => _loading = true);
    final data = await ManualPaymentApiService.adminPaymentDetail(
      widget.orderId,
    );
    if (!mounted) return;
    setState(() {
      _data = data;
      _loading = false;
    });
  }

  Map<String, dynamic> _map(dynamic value) =>
      value is Map ? Map<String, dynamic>.from(value) : <String, dynamic>{};

  List<dynamic> _list(dynamic value) => value is List ? value : const [];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF4F6F9),
      appBar: AppBar(
        backgroundColor: _primary,
        foregroundColor: Colors.white,
        title: Text(_data?['order_number']?.toString() ?? 'Detail Pembayaran'),
        actions: [
          IconButton(onPressed: _load, icon: const Icon(Icons.refresh_rounded)),
        ],
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : _data == null
          ? _errorView()
          : _content(),
      bottomNavigationBar: _data == null ? null : _actionBar(),
    );
  }

  Widget _errorView() => Center(
    child: Padding(
      padding: const EdgeInsets.all(28),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Icon(
            Icons.error_outline_rounded,
            size: 52,
            color: Colors.redAccent,
          ),
          const SizedBox(height: 12),
          Text(
            ManualPaymentApiService.lastError ??
                'Detail pembayaran gagal dimuat.',
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 16),
          FilledButton(onPressed: _load, child: const Text('Coba Lagi')),
        ],
      ),
    ),
  );

  Widget _content() {
    final order = _map(_data!['order']);
    final transaction = _map(order['transaction']);
    final paymentInfo = _map(_data!['payment_info']);
    final confirmation = _map(_data!['latest_confirmation']);
    final items = _list(order['items']);
    final state = _data!['payment_state']?.toString() ?? 'waiting_payment';

    return RefreshIndicator(
      onRefresh: _load,
      child: ListView(
        padding: const EdgeInsets.fromLTRB(16, 16, 16, 120),
        children: [
          _statusCard(state, order, transaction),
          const SizedBox(height: 14),
          _section('Informasi Order', [
            _row('Order ID', _data!['order_number']?.toString() ?? '-'),
            _row('Pembeli', order['name']?.toString() ?? '-'),
            _row('Telepon', order['phone']?.toString() ?? '-'),
            _row(
              'Alamat',
              '${order['address'] ?? '-'}, ${order['city'] ?? '-'}, ${order['state'] ?? '-'}',
            ),
            _row(
              'Pengiriman',
              '${order['mode_pengiriman'] ?? '-'} • ${_currency(order['ongkir'])}',
            ),
            _row('Total', _currency(order['total']), strong: true),
          ]),
          const SizedBox(height: 14),
          _section(
            'Produk (${items.length})',
            items.map((raw) => _itemCard(_map(raw))).toList(),
          ),
          const SizedBox(height: 14),
          _section('Rekening / VA Tujuan', [
            _row('Bank', paymentInfo['bank_name']?.toString() ?? '-'),
            _row('Nomor', paymentInfo['account_number']?.toString() ?? '-'),
            _row('Atas nama', paymentInfo['account_name']?.toString() ?? '-'),
            _row('Batas waktu', _date(paymentInfo['expiry_time'])),
          ]),
          const SizedBox(height: 14),
          _paymentProofSection(confirmation),
          const SizedBox(height: 14),
          _historySection(),
        ],
      ),
    );
  }

  Widget _statusCard(
    String state,
    Map<String, dynamic> order,
    Map<String, dynamic> transaction,
  ) {
    final color = _stateColor(state);
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: color.withOpacity(.10),
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: color.withOpacity(.30)),
      ),
      child: Row(
        children: [
          CircleAvatar(
            backgroundColor: color,
            foregroundColor: Colors.white,
            child: Icon(_stateIcon(state)),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  _stateLabel(state),
                  style: TextStyle(
                    color: color,
                    fontSize: 15,
                    fontWeight: FontWeight.w900,
                  ),
                ),
                const SizedBox(height: 3),
                Text(
                  'Order: ${order['status'] ?? '-'} • Transaksi: ${transaction['status'] ?? '-'}',
                  style: const TextStyle(fontSize: 12, color: Colors.black54),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _paymentProofSection(Map<String, dynamic> confirmation) {
    if (confirmation.isEmpty) {
      return _section('Detail Pembayaran User', [
        const Padding(
          padding: EdgeInsets.symmetric(vertical: 10),
          child: Text(
            'User belum mengirim bukti pembayaran.',
            style: TextStyle(color: Colors.black54),
          ),
        ),
      ]);
    }

    final proofUrl = confirmation['proof_url']?.toString();
    return _section('Detail Pembayaran User', [
      _row('Nama pengirim', confirmation['sender_name']?.toString() ?? '-'),
      _row('Bank pengirim', confirmation['sender_bank']?.toString() ?? '-'),
      _row(
        'Nomor rekening',
        confirmation['sender_account_number']?.toString() ?? '-',
      ),
      _row(
        'Nominal',
        _currency(confirmation['transferred_amount']),
        strong: true,
      ),
      if (confirmation['transferred_at'] != null)
        _row('Waktu transfer', _date(confirmation['transferred_at'])),
      _row('Dikirim pada', _date(confirmation['submitted_at'])),
      if (confirmation['note']?.toString().isNotEmpty == true)
        _row('Catatan', confirmation['note'].toString()),
      if (confirmation['rejection_reason']?.toString().isNotEmpty == true)
        Container(
          margin: const EdgeInsets.only(top: 10),
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: const Color(0xFFFEF2F2),
            borderRadius: BorderRadius.circular(12),
          ),
          child: Text(
            'Alasan penolakan: ${confirmation['rejection_reason']}',
            style: const TextStyle(color: Colors.red),
          ),
        ),
      if (proofUrl != null && proofUrl.isNotEmpty) ...[
        const SizedBox(height: 12),
        GestureDetector(
          onTap: () => _showProof(proofUrl),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(14),
            child: Image.network(
              proofUrl,
              headers: ManualPaymentApiService.authenticatedImageHeaders,
              fit: BoxFit.cover,
              errorBuilder: (_, __, ___) => Container(
                height: 180,
                color: Colors.grey.shade100,
                alignment: Alignment.center,
                child: const Text('Bukti tidak dapat ditampilkan.'),
              ),
            ),
          ),
        ),
      ],
    ]);
  }

  Widget _historySection() {
    final audits = _list(_data!['audits']);
    if (audits.isEmpty) return const SizedBox.shrink();
    return _section(
      'Riwayat Perubahan',
      audits.take(8).map((raw) {
        final audit = _map(raw);
        final actor = _map(audit['actor']);
        return ListTile(
          contentPadding: EdgeInsets.zero,
          dense: true,
          leading: const Icon(Icons.history_rounded, size: 20),
          title: Text(audit['action']?.toString() ?? '-'),
          subtitle: Text(
            '${actor['name'] ?? 'Sistem'} • ${_date(audit['created_at'])}${audit['reason'] == null ? '' : '\n${audit['reason']}'}',
          ),
        );
      }).toList(),
    );
  }

  Widget _itemCard(Map<String, dynamic> item) {
    final product = _map(item['product']);
    final qty = int.tryParse(item['quantity']?.toString() ?? '0') ?? 0;
    final price = double.tryParse(item['price']?.toString() ?? '0') ?? 0;
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 7),
      child: Row(
        children: [
          const CircleAvatar(
            backgroundColor: Color(0xFFEFF6FF),
            child: Icon(Icons.inventory_2_outlined, color: _primary),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  product['name']?.toString() ?? 'Produk',
                  style: const TextStyle(fontWeight: FontWeight.w700),
                ),
                Text(
                  '$qty × ${_currency(price)}',
                  style: const TextStyle(fontSize: 12, color: Colors.black54),
                ),
              ],
            ),
          ),
          Text(
            _currency(price * qty),
            style: const TextStyle(fontWeight: FontWeight.w800),
          ),
        ],
      ),
    );
  }

  Widget _section(String title, List<Widget> children) => Container(
    padding: const EdgeInsets.all(16),
    decoration: BoxDecoration(
      color: Colors.white,
      borderRadius: BorderRadius.circular(18),
      border: Border.all(color: Colors.grey.shade200),
    ),
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          title,
          style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w900),
        ),
        const Divider(height: 24),
        ...children,
      ],
    ),
  );

  Widget _row(String label, String value, {bool strong = false}) => Padding(
    padding: const EdgeInsets.symmetric(vertical: 5),
    child: Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SizedBox(
          width: 112,
          child: Text(
            label,
            style: const TextStyle(fontSize: 12, color: Colors.black54),
          ),
        ),
        Expanded(
          child: Text(
            value,
            textAlign: TextAlign.right,
            style: TextStyle(
              fontSize: strong ? 14 : 12.5,
              fontWeight: strong ? FontWeight.w900 : FontWeight.w600,
            ),
          ),
        ),
      ],
    ),
  );

  Widget _actionBar() {
    final state = _data!['payment_state']?.toString() ?? 'waiting_payment';
    final canReview = state == 'proof_submitted';
    final canCancel = ![
      'payment_approved',
      'canceled',
      'expired',
    ].contains(state);
    if (!canReview && !canCancel) return const SizedBox.shrink();
    return SafeArea(
      child: Container(
        padding: const EdgeInsets.fromLTRB(14, 10, 14, 10),
        decoration: BoxDecoration(
          color: Colors.white,
          boxShadow: [
            BoxShadow(color: Colors.black.withOpacity(.08), blurRadius: 12),
          ],
        ),
        child: Row(
          children: [
            if (canCancel)
              IconButton.filledTonal(
                onPressed: _processing ? null : _cancel,
                icon: const Icon(Icons.cancel_outlined, color: Colors.red),
                tooltip: 'Batalkan order',
              ),
            if (canReview) ...[
              const SizedBox(width: 8),
              Expanded(
                child: OutlinedButton(
                  onPressed: _processing ? null : _reject,
                  child: const Text('Tolak Bukti'),
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: FilledButton(
                  onPressed: _processing ? null : _approve,
                  style: FilledButton.styleFrom(backgroundColor: Colors.green),
                  child: _processing
                      ? const SizedBox(
                          width: 18,
                          height: 18,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            color: Colors.white,
                          ),
                        )
                      : const Text('Terima'),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  Future<void> _approve() async {
    final confirmed = await _confirm(
      'Terima pembayaran?',
      'Pastikan nominal, rekening pengirim, dan bukti transfer sudah sesuai. Tindakan ini menandai order sebagai dibayar.',
    );
    if (!confirmed) return;
    await _runAction(
      () => ManualPaymentApiService.approve(widget.orderId),
      'Pembayaran berhasil diterima.',
    );
  }

  Future<void> _showProof(String proofUrl) {
    return showDialog<void>(
      context: context,
      builder: (context) => Dialog.fullscreen(
        backgroundColor: Colors.black,
        child: SafeArea(
          child: Stack(
            children: [
              Center(
                child: InteractiveViewer(
                  minScale: .5,
                  maxScale: 5,
                  child: Image.network(
                    proofUrl,
                    headers: ManualPaymentApiService.authenticatedImageHeaders,
                    fit: BoxFit.contain,
                  ),
                ),
              ),
              Positioned(
                top: 8,
                right: 8,
                child: IconButton.filled(
                  onPressed: () => Navigator.pop(context),
                  icon: const Icon(Icons.close_rounded),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Future<void> _reject() async {
    final result = await _reasonDialog(
      title: 'Tolak bukti pembayaran',
      hint: 'Tuliskan alasan agar user dapat memperbaiki bukti.',
      allowExtension: true,
    );
    if (result == null) return;
    await _runAction(
      () => ManualPaymentApiService.reject(
        widget.orderId,
        result.reason,
        extendDeadline: result.extendDeadline,
      ),
      'Bukti ditolak dan user dapat mengirim ulang.',
    );
  }

  Future<void> _cancel() async {
    final result = await _reasonDialog(
      title: 'Batalkan order',
      hint: 'Order akan dibatalkan dan stok dikembalikan.',
      allowExtension: false,
    );
    if (result == null) return;
    await _runAction(
      () => ManualPaymentApiService.cancel(widget.orderId, result.reason),
      'Order berhasil dibatalkan.',
    );
  }

  Future<void> _runAction(
    Future<bool> Function() action,
    String successMessage,
  ) async {
    setState(() => _processing = true);
    final ok = await action();
    if (!mounted) return;
    setState(() => _processing = false);
    _snack(
      ok
          ? successMessage
          : ManualPaymentApiService.lastError ?? 'Tindakan gagal diproses.',
      error: !ok,
    );
    if (ok) await _load();
  }

  Future<bool> _confirm(String title, String message) async {
    return await showDialog<bool>(
          context: context,
          builder: (context) => AlertDialog(
            title: Text(title),
            content: Text(message),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context, false),
                child: const Text('Batal'),
              ),
              FilledButton(
                onPressed: () => Navigator.pop(context, true),
                child: const Text('Ya, Lanjutkan'),
              ),
            ],
          ),
        ) ??
        false;
  }

  Future<_ReasonResult?> _reasonDialog({
    required String title,
    required String hint,
    required bool allowExtension,
  }) async {
    final controller = TextEditingController();
    var extend = true;
    final result = await showDialog<_ReasonResult>(
      context: context,
      builder: (dialogContext) => StatefulBuilder(
        builder: (context, setDialogState) => AlertDialog(
          title: Text(title),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(hint),
              const SizedBox(height: 12),
              TextField(
                controller: controller,
                maxLines: 3,
                decoration: const InputDecoration(
                  labelText: 'Alasan',
                  border: OutlineInputBorder(),
                ),
              ),
              if (allowExtension)
                SwitchListTile(
                  contentPadding: EdgeInsets.zero,
                  title: const Text(
                    'Beri waktu 24 jam jika tenggat sudah lewat',
                  ),
                  value: extend,
                  onChanged: (value) => setDialogState(() => extend = value),
                ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(dialogContext),
              child: const Text('Batal'),
            ),
            FilledButton(
              onPressed: () {
                if (controller.text.trim().length < 5) return;
                Navigator.pop(
                  dialogContext,
                  _ReasonResult(controller.text.trim(), extend),
                );
              },
              child: const Text('Konfirmasi'),
            ),
          ],
        ),
      ),
    );
    controller.dispose();
    return result;
  }

  String _currency(dynamic value) => NumberFormat.currency(
    locale: 'id_ID',
    symbol: 'Rp ',
    decimalDigits: 0,
  ).format(double.tryParse(value?.toString() ?? '0') ?? 0);

  String _date(dynamic value) {
    if (value == null || value.toString().isEmpty) return '-';
    try {
      return DateFormat(
        'dd MMM yyyy, HH:mm',
        'id_ID',
      ).format(DateTime.parse(value.toString()).toLocal());
    } catch (_) {
      return value.toString();
    }
  }

  Color _stateColor(String state) => switch (state) {
    'proof_submitted' => Colors.orange,
    'proof_rejected' => Colors.redAccent,
    'payment_approved' => Colors.green,
    'expired' || 'canceled' => Colors.red,
    _ => Colors.blueGrey,
  };

  IconData _stateIcon(String state) => switch (state) {
    'proof_submitted' => Icons.fact_check_outlined,
    'proof_rejected' => Icons.highlight_off_rounded,
    'payment_approved' => Icons.verified_rounded,
    'expired' => Icons.timer_off_outlined,
    'canceled' => Icons.cancel_outlined,
    _ => Icons.schedule_rounded,
  };

  String _stateLabel(String state) => switch (state) {
    'proof_submitted' => 'Menunggu Verifikasi',
    'proof_rejected' => 'Bukti Ditolak',
    'payment_approved' => 'Pembayaran Diterima',
    'expired' => 'Pembayaran Kedaluwarsa',
    'canceled' => 'Order Dibatalkan',
    _ => 'Belum Dibayar',
  };

  void _snack(String message, {bool error = false}) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: error ? Colors.red : null,
        behavior: SnackBarBehavior.floating,
      ),
    );
  }
}

class _ReasonResult {
  const _ReasonResult(this.reason, this.extendDeadline);

  final String reason;
  final bool extendDeadline;
}

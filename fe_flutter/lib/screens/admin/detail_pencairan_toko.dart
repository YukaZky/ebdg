import 'package:flutter/material.dart';

import '../../services/store_income_api_service.dart';

class DetailPencairanTokoScreen extends StatefulWidget {
  final int payoutId;
  final String? initialAmount;
  final String? initialDate;

  const DetailPencairanTokoScreen({
    Key? key,
    required this.payoutId,
    this.initialAmount,
    this.initialDate,
  }) : super(key: key);

  @override
  State<DetailPencairanTokoScreen> createState() =>
      _DetailPencairanTokoScreenState();
}

class _DetailPencairanTokoScreenState
    extends State<DetailPencairanTokoScreen> {
  static const Color _primary = Color(0xFF1E3A8A);
  static const Color _success = Color(0xFF15803D);

  bool loading = true;
  Map<String, dynamic> detail = {};

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() => loading = true);
    final result =
        await StoreIncomeApiService.sellerPayoutDetail(widget.payoutId);
    if (!mounted) return;
    setState(() {
      detail = result ?? {};
      loading = false;
    });
  }

  Map<String, dynamic> _map(dynamic value) {
    if (value is Map<String, dynamic>) return value;
    if (value is Map) return Map<String, dynamic>.from(value);
    return <String, dynamic>{};
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
    if (parts.length == 3) {
      return '${parts[2]}/${parts[1]}/${parts[0]}';
    }
    return text;
  }

  String _dateTime(dynamic value) {
    final raw = value?.toString().trim() ?? '';
    if (raw.isEmpty) return '-';
    try {
      final date = DateTime.parse(raw).toLocal();
      String two(int n) => n.toString().padLeft(2, '0');
      return '${two(date.day)}/${two(date.month)}/${date.year} '
          '${two(date.hour)}:${two(date.minute)}';
    } catch (_) {
      return raw;
    }
  }

  Widget _infoRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 120,
            child: Text(
              label,
              style: TextStyle(fontSize: 12, color: Colors.grey[600]),
            ),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              value,
              style: const TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w700,
                color: Colors.black87,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _section({required Widget child}) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: const Color(0xFFE2E8F0)),
      ),
      child: child,
    );
  }

  Widget _proofSection() {
    final proofUrl = detail['proof_url']?.toString().trim() ?? '';

    return _section(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Row(
            children: [
              Icon(Icons.receipt_long_outlined, color: _primary),
              SizedBox(width: 9),
              Text(
                'Bukti Transfer',
                style: TextStyle(fontSize: 15, fontWeight: FontWeight.w900),
              ),
            ],
          ),
          const SizedBox(height: 14),
          if (proofUrl.isEmpty)
            Container(
              height: 140,
              width: double.infinity,
              alignment: Alignment.center,
              decoration: BoxDecoration(
                color: const Color(0xFFF8FAFC),
                borderRadius: BorderRadius.circular(14),
              ),
              child: const Text('Bukti transfer tidak tersedia.'),
            )
          else
            ClipRRect(
              borderRadius: BorderRadius.circular(14),
              child: Image.network(
                proofUrl,
                headers: StoreIncomeApiService.authenticatedImageHeaders,
                width: double.infinity,
                height: 260,
                fit: BoxFit.contain,
                loadingBuilder: (context, child, progress) {
                  if (progress == null) return child;
                  return Container(
                    height: 220,
                    alignment: Alignment.center,
                    color: const Color(0xFFF8FAFC),
                    child: const CircularProgressIndicator(color: _primary),
                  );
                },
                errorBuilder: (_, __, ___) => Container(
                  height: 150,
                  alignment: Alignment.center,
                  color: const Color(0xFFF8FAFC),
                  child: const Text('Bukti transfer gagal dimuat.'),
                ),
              ),
            ),
        ],
      ),
    );
  }

  Widget _ordersSection() {
    final rawOrders = detail['orders'] is List
        ? detail['orders'] as List
        : <dynamic>[];

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            const Text(
              'Order yang Dicairkan',
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.w900),
            ),
            Text(
              '${rawOrders.length} order',
              style: TextStyle(
                fontSize: 12,
                color: Colors.grey[600],
                fontWeight: FontWeight.w700,
              ),
            ),
          ],
        ),
        const SizedBox(height: 10),
        if (rawOrders.isEmpty)
          _section(
            child: const Center(
              child: Padding(
                padding: EdgeInsets.symmetric(vertical: 14),
                child: Text('Detail order tidak tersedia.'),
              ),
            ),
          )
        else
          ...rawOrders.map((rawOrder) {
            final order = _map(rawOrder);
            final items = order['items'] is List
                ? order['items'] as List
                : <dynamic>[];

            return Card(
              margin: const EdgeInsets.only(bottom: 10),
              elevation: 0,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(17),
                side: const BorderSide(color: Color(0xFFE2E8F0)),
              ),
              child: ExpansionTile(
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(17),
                ),
                collapsedShape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(17),
                ),
                leading: Container(
                  width: 43,
                  height: 43,
                  decoration: BoxDecoration(
                    color: _success.withOpacity(0.09),
                    borderRadius: BorderRadius.circular(13),
                  ),
                  child: const Icon(
                    Icons.shopping_bag_outlined,
                    color: _success,
                  ),
                ),
                title: Text(
                  order['order_number']?.toString() ??
                      '#${order['id'] ?? '-'}',
                  style: const TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w900,
                  ),
                ),
                subtitle: Padding(
                  padding: const EdgeInsets.only(top: 4),
                  child: Text(
                    '${order['buyer_name'] ?? '-'} • ${order['status'] ?? '-'}',
                    style: TextStyle(fontSize: 11, color: Colors.grey[600]),
                  ),
                ),
                trailing: Text(
                  _currency(order['amount']),
                  style: const TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w900,
                    color: _success,
                  ),
                ),
                children: [
                  Container(
                    width: double.infinity,
                    margin: const EdgeInsets.fromLTRB(14, 0, 14, 14),
                    padding: const EdgeInsets.all(13),
                    decoration: BoxDecoration(
                      color: const Color(0xFFF8FAFC),
                      borderRadius: BorderRadius.circular(13),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        _infoRow('Pembeli', order['buyer_name']?.toString() ?? '-'),
                        _infoRow('Status order', order['status']?.toString() ?? '-'),
                        _infoRow('Status bayar', order['payment_status']?.toString() ?? '-'),
                        _infoRow(
                          'Approved',
                          _dateTime(order['payment_approved_at']),
                        ),
                        _infoRow(
                          'Tanggal income',
                          _date(order['income_date']),
                        ),
                        const Divider(height: 20),
                        const Text(
                          'Produk dalam order ini',
                          style: TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.w900,
                          ),
                        ),
                        const SizedBox(height: 8),
                        if (items.isEmpty)
                          Text(
                            'Detail produk tidak tersedia.',
                            style: TextStyle(
                              fontSize: 11,
                              color: Colors.grey[600],
                            ),
                          )
                        else
                          ...items.map((rawItem) {
                            final item = _map(rawItem);
                            return Padding(
                              padding: const EdgeInsets.only(bottom: 7),
                              child: Row(
                                children: [
                                  Expanded(
                                    child: Text(
                                      '${item['product_name'] ?? 'Produk'} × ${item['quantity'] ?? 0}',
                                      style: const TextStyle(fontSize: 11.5),
                                    ),
                                  ),
                                  Text(
                                    _currency(item['line_total']),
                                    style: const TextStyle(
                                      fontSize: 11.5,
                                      fontWeight: FontWeight.w800,
                                    ),
                                  ),
                                ],
                              ),
                            );
                          }),
                        const Divider(height: 20),
                        Row(
                          children: [
                            const Expanded(
                              child: Text(
                                'Nominal dicairkan untuk order',
                                style: TextStyle(
                                  fontSize: 12,
                                  fontWeight: FontWeight.w800,
                                ),
                              ),
                            ),
                            Text(
                              _currency(order['amount']),
                              style: const TextStyle(
                                fontSize: 13,
                                fontWeight: FontWeight.w900,
                                color: _success,
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            );
          }),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    final amount = detail.isNotEmpty
        ? detail['amount']
        : widget.initialAmount;
    final payoutDate = detail.isNotEmpty
        ? detail['payout_date']
        : widget.initialDate;
    final processor = _map(detail['processed_by']);

    return Scaffold(
      backgroundColor: const Color(0xFFF4F6F9),
      appBar: AppBar(
        title: const Text(
          'Detail Pencairan',
          style: TextStyle(fontWeight: FontWeight.w900),
        ),
        backgroundColor: Colors.white,
        foregroundColor: Colors.black87,
        elevation: 0,
        actions: [
          IconButton(onPressed: _load, icon: const Icon(Icons.refresh_rounded)),
        ],
      ),
      body: loading
          ? const Center(
              child: CircularProgressIndicator(color: _primary),
            )
          : detail.isEmpty
              ? Center(
                  child: Padding(
                    padding: const EdgeInsets.all(24),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Icon(
                          Icons.error_outline_rounded,
                          size: 44,
                          color: Colors.grey,
                        ),
                        const SizedBox(height: 12),
                        Text(
                          StoreIncomeApiService.lastError ??
                              'Detail pencairan tidak dapat dimuat.',
                          textAlign: TextAlign.center,
                        ),
                        const SizedBox(height: 14),
                        ElevatedButton(
                          onPressed: _load,
                          child: const Text('Coba Lagi'),
                        ),
                      ],
                    ),
                  ),
                )
              : RefreshIndicator(
                  onRefresh: _load,
                  child: ListView(
                    physics: const AlwaysScrollableScrollPhysics(),
                    padding: const EdgeInsets.all(16),
                    children: [
                      Container(
                        padding: const EdgeInsets.all(20),
                        decoration: BoxDecoration(
                          gradient: const LinearGradient(
                            colors: [Color(0xFF15803D), Color(0xFF22C55E)],
                          ),
                          borderRadius: BorderRadius.circular(22),
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text(
                              'TOTAL DICAIRKAN',
                              style: TextStyle(
                                color: Colors.white70,
                                fontSize: 11,
                                fontWeight: FontWeight.w800,
                                letterSpacing: 0.8,
                              ),
                            ),
                            const SizedBox(height: 7),
                            Text(
                              _currency(amount),
                              style: const TextStyle(
                                color: Colors.white,
                                fontSize: 30,
                                fontWeight: FontWeight.w900,
                              ),
                            ),
                            const SizedBox(height: 8),
                            Text(
                              'Dicairkan ${_date(payoutDate)} • ${detail['order_count'] ?? 0} order',
                              style: const TextStyle(
                                color: Colors.white70,
                                fontSize: 12,
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 14),
                      _section(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text(
                              'Informasi Pencairan',
                              style: TextStyle(
                                fontSize: 15,
                                fontWeight: FontWeight.w900,
                              ),
                            ),
                            const SizedBox(height: 14),
                            _infoRow('Tanggal', _date(detail['payout_date'])),
                            _infoRow(
                              'Status',
                              detail['status']?.toString() == 'paid'
                                  ? 'Sudah dicairkan'
                                  : detail['status']?.toString() ?? '-',
                            ),
                            _infoRow(
                              'Diproses oleh',
                              processor['name']?.toString() ?? '-',
                            ),
                            _infoRow(
                              'Rekening',
                              '${detail['bank_provider'] ?? '-'} • ${detail['account_number'] ?? '-'}',
                            ),
                            _infoRow(
                              'Atas nama',
                              detail['account_name']?.toString().trim().isNotEmpty == true
                                  ? detail['account_name'].toString()
                                  : '-',
                            ),
                            const Divider(height: 20),
                            Text(
                              'Deskripsi',
                              style: TextStyle(
                                fontSize: 11.5,
                                color: Colors.grey[600],
                              ),
                            ),
                            const SizedBox(height: 5),
                            Text(
                              detail['description']?.toString().trim().isNotEmpty == true
                                  ? detail['description'].toString()
                                  : '-',
                              style: const TextStyle(
                                fontSize: 12.5,
                                height: 1.45,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 14),
                      _proofSection(),
                      const SizedBox(height: 20),
                      _ordersSection(),
                      const SizedBox(height: 28),
                    ],
                  ),
                ),
    );
  }
}

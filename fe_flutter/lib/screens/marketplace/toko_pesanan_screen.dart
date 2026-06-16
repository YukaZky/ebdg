import 'package:flutter/material.dart';
import '../../services/marketplace_api_service.dart';

class TokoPesananScreen extends StatefulWidget {
  const TokoPesananScreen({Key? key}) : super(key: key);

  @override
  State<TokoPesananScreen> createState() => _TokoPesananScreenState();
}

class _TokoPesananScreenState extends State<TokoPesananScreen> {
  List<dynamic> orders = [];
  bool loading = true;

  @override
  void initState() {
    super.initState();
    loadOrders();
  }

  Future<void> loadOrders() async {
    final result = await MarketplaceApiService.sellerOrders();
    if (!mounted) return;
    setState(() {
      orders = result;
      loading = false;
    });
  }

  Future<void> updateStatus(int orderId, String status) async {
    final ok = await MarketplaceApiService.updateOrderStatus(orderId, status);
    if (!mounted) return;

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(ok ? 'Status pesanan berhasil diperbarui' : 'Gagal memperbarui status pesanan')),
    );

    if (ok) loadOrders();
  }

  String _labelStatus(dynamic status) {
    switch (status?.toString()) {
      case 'ordered':
        return 'Pesanan Baru';
      case 'processing':
        return 'Diproses';
      case 'shipped':
        return 'Dikirim';
      case 'delivered':
        return 'Selesai';
      case 'canceled':
        return 'Dibatalkan';
      default:
        return status?.toString() ?? '-';
    }
  }

  Color _statusColor(dynamic status) {
    switch (status?.toString()) {
      case 'ordered':
        return Colors.orange;
      case 'processing':
        return Colors.blue;
      case 'shipped':
        return Colors.indigo;
      case 'delivered':
        return Colors.green;
      case 'canceled':
        return Colors.red;
      default:
        return Colors.grey;
    }
  }

  Widget _statusButton(int orderId, String status, String label) {
    return OutlinedButton(
      onPressed: () => updateStatus(orderId, status),
      style: OutlinedButton.styleFrom(
        foregroundColor: _statusColor(status),
        side: BorderSide(color: _statusColor(status).withOpacity(0.5)),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(999)),
      ),
      child: Text(label),
    );
  }

  Widget _orderCard(dynamic order) {
    final orderId = int.tryParse(order['id']?.toString() ?? '0') ?? 0;
    final status = order['status'];
    final items = order['items'] as List? ?? [];

    return Container(
      margin: const EdgeInsets.only(bottom: 14),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.04),
            blurRadius: 12,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  'Pesanan #$orderId',
                  style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                decoration: BoxDecoration(
                  color: _statusColor(status).withOpacity(0.12),
                  borderRadius: BorderRadius.circular(999),
                ),
                child: Text(
                  _labelStatus(status),
                  style: TextStyle(color: _statusColor(status), fontSize: 12, fontWeight: FontWeight.bold),
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          Text('Pembeli: ${order['name'] ?? '-'}'),
          Text('No HP: ${order['phone'] ?? '-'}'),
          Text('Total: Rp ${order['total'] ?? 0}'),
          if (items.isNotEmpty) ...[
            const SizedBox(height: 10),
            Text('${items.length} produk di pesanan ini', style: TextStyle(color: Colors.grey.shade700)),
          ],
          const SizedBox(height: 14),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              _statusButton(orderId, 'processing', 'Proses'),
              _statusButton(orderId, 'shipped', 'Kirim'),
              _statusButton(orderId, 'delivered', 'Selesai'),
              _statusButton(orderId, 'canceled', 'Batalkan'),
            ],
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF6F7FB),
      appBar: AppBar(
        title: const Text('Pesanan Toko'),
        backgroundColor: Colors.white,
        foregroundColor: Colors.black87,
        elevation: 0.5,
      ),
      body: loading
          ? const Center(child: CircularProgressIndicator())
          : RefreshIndicator(
              onRefresh: loadOrders,
              child: orders.isEmpty
                  ? ListView(
                      children: const [
                        SizedBox(height: 180),
                        Icon(Icons.receipt_long_outlined, size: 72, color: Colors.grey),
                        SizedBox(height: 12),
                        Center(child: Text('Belum ada pesanan masuk.')),
                      ],
                    )
                  : ListView.builder(
                      padding: const EdgeInsets.all(16),
                      itemCount: orders.length,
                      itemBuilder: (context, index) => _orderCard(orders[index]),
                    ),
            ),
    );
  }
}

import 'package:flutter/material.dart';
import 'main_screen.dart';

class OrderConfirmationScreen extends StatelessWidget {
  final Map<String, dynamic> order;

  const OrderConfirmationScreen({Key? key, required this.order})
      : super(key: key);

  @override // Perbaikan di baris ini (sebelumnya @main)
  Widget build(BuildContext context) {
    List items = order['items'] ?? [];

    return Scaffold(
      backgroundColor: const Color(0xFFF5F7FA),
      appBar: AppBar(
        title: const Text("Konfirmasi Pesanan",
            style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
        backgroundColor: Colors.blue[700],
        automaticallyImplyLeading:
            false, // Menghapus tombol back agar user tidak checkout ulang
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Banner Sukses
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                  color: Colors.white, borderRadius: BorderRadius.circular(16)),
              child: Column(
                children: [
                  const Icon(Icons.check_circle, color: Colors.green, size: 64),
                  const SizedBox(height: 12),
                  const Text("Pesanan Berhasil Dibuat!",
                      style:
                          TextStyle(fontWeight: FontWeight.bold, fontSize: 20)),
                  const SizedBox(height: 8),
                  Text("ID Pesanan: #ORDER-${order['id']}",
                      style: const TextStyle(
                          color: Colors.grey, fontWeight: FontWeight.bold)),
                  const SizedBox(height: 4),
                  const Text(
                      "Silahkan selesaikan pembayaran pada browser Anda.",
                      style: TextStyle(color: Colors.grey, fontSize: 13),
                      textAlign: TextAlign.center),
                ],
              ),
            ),
            const SizedBox(height: 16),

            // Detail Pengiriman
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                  color: Colors.white, borderRadius: BorderRadius.circular(16)),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text("Detail Pengiriman",
                      style:
                          TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                  const Divider(height: 24),
                  Text("Nama Penerima: ${order['name']}",
                      style: const TextStyle(fontWeight: FontWeight.w600)),
                  const SizedBox(height: 6),
                  Text("No HP: ${order['phone']}"),
                  const SizedBox(height: 6),
                  Text(
                      "Alamat: ${order['address']}, ${order['city']}, ${order['state']}"),
                  const SizedBox(height: 6),
                  Text(
                      "Ekspedisi: ${order['mode_pengiriman']} (${order['jenis_pengiriman']})"),
                ],
              ),
            ),
            const SizedBox(height: 16),

            // Daftar Barang yang Dibeli
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                  color: Colors.white, borderRadius: BorderRadius.circular(16)),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text("Rincian Produk",
                      style:
                          TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                  const Divider(height: 24),
                  ...items.map((item) {
                    var product = item['product'];
                    return Padding(
                      padding: const EdgeInsets.only(bottom: 12.0),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Expanded(
                            child: Text(
                              "${item['quantity']}x  ${product != null ? product['name'] : 'Produk'}",
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                          Text(
                              "Rp ${double.tryParse(item['price'].toString())?.toStringAsFixed(0)}"),
                        ],
                      ),
                    );
                  }).toList(),
                  const Divider(),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text("Ongkos Kirim",
                          style: TextStyle(color: Colors.grey)),
                      Text(
                          "Rp ${double.tryParse(order['ongkir'].toString())?.toStringAsFixed(0)}"),
                    ],
                  ),
                  const SizedBox(height: 6),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text("Total Pembayaran",
                          style: TextStyle(
                              fontWeight: FontWeight.bold, fontSize: 16)),
                      Text(
                        "Rp ${double.tryParse(order['total'].toString())?.toStringAsFixed(0)}",
                        style: TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 18,
                            color: Colors.blue[700]),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            const SizedBox(height: 40),

            // Tombol kembali ke Beranda
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: () {
                  Navigator.pushAndRemoveUntil(
                    context,
                    MaterialPageRoute(builder: (context) => const MainScreen()),
                    (route) => false,
                  );
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.blue[700],
                  padding: const EdgeInsets.symmetric(vertical: 14),
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12)),
                ),
                child: const Text("KEMBALI KE BERANDA",
                    style: TextStyle(
                        color: Colors.white, fontWeight: FontWeight.bold)),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

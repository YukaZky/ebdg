import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';
import '../services/api_service.dart';
import 'main_screen.dart';

class CheckoutScreen extends StatefulWidget {
  final double totalAmount;
  
  const CheckoutScreen({Key? key, required this.totalAmount}) : super(key: key);

  @override
  State<CheckoutScreen> createState() => _CheckoutScreenState();
}

class _CheckoutScreenState extends State<CheckoutScreen> {
  final _addressController = TextEditingController();
  final _phoneController = TextEditingController();
  bool _isLoading = false;

  void _processCheckout() async {
    if (_addressController.text.isEmpty || _phoneController.text.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Alamat dan No HP wajib diisi!")),
      );
      return;
    }

    setState(() => _isLoading = true);

    String? paymentUrl = await ApiService.checkout(
      _addressController.text,
      _phoneController.text,
    );

    setState(() => _isLoading = false);

    if (paymentUrl != null) {
      // Buka URL Midtrans di Browser bawaan HP
      final Uri url = Uri.parse(paymentUrl);
      if (!await launchUrl(url, mode: LaunchMode.externalApplication)) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text("Gagal membuka halaman pembayaran")),
        );
      } else {
        // Setelah membuka browser, arahkan user kembali ke Beranda (karena keranjang sudah kosong)
        if (mounted) {
          Navigator.pushAndRemoveUntil(
            context,
            MaterialPageRoute(builder: (context) => const MainScreen()),
            (route) => false,
          );
        }
      }
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Gagal melakukan checkout!")),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("Checkout")),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text("Total Tagihan: Rp ${widget.totalAmount.toStringAsFixed(0)}", 
                style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: Colors.green)),
            const SizedBox(height: 24),
            const Text("Detail Pengiriman", style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
            const SizedBox(height: 12),
            TextField(
              controller: _addressController,
              decoration: const InputDecoration(
                labelText: "Alamat Lengkap",
                border: OutlineInputBorder(),
              ),
              maxLines: 3,
            ),
            const SizedBox(height: 16),
            TextField(
              controller: _phoneController,
              keyboardType: TextInputType.phone,
              decoration: const InputDecoration(
                labelText: "Nomor Handphone",
                border: OutlineInputBorder(),
              ),
            ),
            const Spacer(),
            _isLoading 
              ? const Center(child: CircularProgressIndicator())
              : ElevatedButton(
                  onPressed: _processCheckout,
                  style: ElevatedButton.styleFrom(
                    minimumSize: const Size.fromHeight(50),
                    backgroundColor: Colors.blue,
                  ),
                  child: const Text("BAYAR SEKARANG", style: TextStyle(color: Colors.white, fontSize: 16)),
                )
          ],
        ),
      ),
    );
  }
}
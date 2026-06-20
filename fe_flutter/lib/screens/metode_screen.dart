import 'package:flutter/material.dart';
import '../models/payment_method_model.dart';
import '../services/api_service.dart';

class MetodeScreen extends StatefulWidget {
  const MetodeScreen({Key? key}) : super(key: key);

  @override
  State<MetodeScreen> createState() => _MetodeScreenState();
}

class _MetodeScreenState extends State<MetodeScreen> {
  // Variabel untuk menampung future agar API tidak terpanggil berulang kali saat layar di-rebuild
  late Future<List<PaymentMethodModel>> _paymentMethodsFuture;

  @override
  void initState() {
    super.initState();
    // Memanggil fungsi dari ApiService yang dibuat pada Fase 3
    _paymentMethodsFuture = ApiService().getPaymentMethods();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey.shade100,
      appBar: AppBar(
        title: const Text(
          'Pilih Metode Pembayaran', 
          style: TextStyle(color: Colors.black, fontSize: 18, fontWeight: FontWeight.bold)
        ),
        backgroundColor: Colors.white,
        elevation: 1,
        iconTheme: const IconThemeData(color: Colors.black),
      ),
      body: FutureBuilder<List<PaymentMethodModel>>(
        future: _paymentMethodsFuture,
        builder: (context, snapshot) {
          // 1. Kondisi Loading
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator(color: Color(0xFFE65100)));
          } 
          // 2. Kondisi Error
          else if (snapshot.hasError) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(Icons.error_outline, color: Colors.red, size: 60),
                  const SizedBox(height: 16),
                  Text('Gagal memuat data:\n${snapshot.error}', textAlign: TextAlign.center),
                  const SizedBox(height: 16),
                  ElevatedButton(
                    onPressed: () {
                      setState(() {
                        _paymentMethodsFuture = ApiService().getPaymentMethods();
                      });
                    },
                    style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFFE65100)),
                    child: const Text('Coba Lagi', style: TextStyle(color: Colors.white)),
                  )
                ],
              ),
            );
          } 
          // 3. Kondisi Data Kosong
          else if (!snapshot.hasData || snapshot.data!.isEmpty) {
            return const Center(child: Text('Belum ada metode pembayaran yang aktif.'));
          }

          // 4. Kondisi Sukses (Render List)
          final methods = snapshot.data!;

          return ListView.separated(
            padding: const EdgeInsets.all(16),
            itemCount: methods.length,
            separatorBuilder: (context, index) => const SizedBox(height: 12),
            itemBuilder: (context, index) {
              final method = methods[index];
              return InkWell(
                onTap: () {
                  // MENGEMBALIKAN DATA KE CHECKOUT SCREEN SAAT DIKLIK
                  Navigator.pop(context, method);
                },
                borderRadius: BorderRadius.circular(12),
                child: Container(
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(12),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.grey.withOpacity(0.1),
                        spreadRadius: 2,
                        blurRadius: 5,
                        offset: const Offset(0, 2),
                      )
                    ],
                  ),
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
                  child: Row(
                    children: [
                      // Menampilkan ikon gambar dari URL Laravel
                      Container(
                        width: 60,
                        height: 40,
                        decoration: BoxDecoration(
                          color: Colors.grey.shade50,
                          borderRadius: BorderRadius.circular(6),
                        ),
                        child: Image.network(
                          method.iconUrl,
                          fit: BoxFit.contain,
                          // Error handler jika gambar di server gagal dimuat/hilang
                          errorBuilder: (context, error, stackTrace) {
                            return const Icon(Icons.account_balance_wallet, color: Colors.grey);
                          },
                        ),
                      ),
                      const SizedBox(width: 16),
                      Expanded(
                        child: Text(
                          method.name,
                          style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
                        ),
                      ),
                      const Icon(Icons.chevron_right, color: Colors.grey),
                    ],
                  ),
                ),
              );
            },
          );
        },
      ),
    );
  }
}
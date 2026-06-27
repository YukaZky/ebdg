import 'package:flutter/material.dart';
import '../models/payment_method_model.dart';
import '../services/api_service.dart';

class MetodeScreen extends StatefulWidget {
  const MetodeScreen({Key? key}) : super(key: key);

  @override
  State<MetodeScreen> createState() => _MetodeScreenState();
}

class _MetodeScreenState extends State<MetodeScreen> {
  static const Color _primary = Color(0xFF0C2442);
  static const Color _accent = Color(0xFFF39C12);
  static const Color _purple = Color(0xFF6C4DFF);
  static const Color _surface = Color(0xFFF7F8FC);
  static const Color _muted = Color(0xFF64748B);

  late Future<List<PaymentMethodModel>> _paymentMethodsFuture;

  @override
  void initState() {
    super.initState();
    _paymentMethodsFuture = ApiService().getPaymentMethods();
  }

  void _reloadPaymentMethods() {
    setState(() {
      _paymentMethodsFuture = ApiService().getPaymentMethods();
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: _surface,
      body: Column(
        children: [
          _header(context),
          Expanded(
            child: FutureBuilder<List<PaymentMethodModel>>(
              future: _paymentMethodsFuture,
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Center(child: CircularProgressIndicator(color: _primary));
                }

                if (snapshot.hasError) {
                  return _stateView(
                    icon: Icons.error_outline_rounded,
                    title: 'Gagal memuat metode',
                    message: 'Terjadi kendala saat mengambil data pembayaran. Silakan coba lagi.',
                    buttonText: 'Coba Lagi',
                    onPressed: _reloadPaymentMethods,
                    iconColor: Colors.red,
                  );
                }

                if (!snapshot.hasData || snapshot.data!.isEmpty) {
                  return _stateView(
                    icon: Icons.account_balance_wallet_outlined,
                    title: 'Belum ada metode aktif',
                    message: 'Metode pembayaran belum tersedia. Coba kembali beberapa saat lagi.',
                    buttonText: 'Muat Ulang',
                    onPressed: _reloadPaymentMethods,
                  );
                }

                final methods = snapshot.data!;

                return RefreshIndicator(
                  onRefresh: () async => _reloadPaymentMethods(),
                  child: ListView.separated(
                    physics: const AlwaysScrollableScrollPhysics(parent: BouncingScrollPhysics()),
                    padding: const EdgeInsets.fromLTRB(16, 16, 16, 28),
                    itemCount: methods.length,
                    separatorBuilder: (context, index) => const SizedBox(height: 12),
                    itemBuilder: (context, index) => _paymentMethodTile(methods[index]),
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _header(BuildContext context) {
    return Container(
      decoration: const BoxDecoration(
        gradient: LinearGradient(colors: [_primary, Color(0xFF123A68)], begin: Alignment.topLeft, end: Alignment.bottomRight),
        borderRadius: BorderRadius.vertical(bottom: Radius.circular(30)),
      ),
      child: SafeArea(
        bottom: false,
        child: Padding(
          padding: const EdgeInsets.fromLTRB(18, 16, 18, 24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  _circleAction(Icons.arrow_back_rounded, () => Navigator.pop(context)),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 7),
                    decoration: BoxDecoration(
                      color: Colors.white.withOpacity(0.14),
                      borderRadius: BorderRadius.circular(99),
                      border: Border.all(color: Colors.white.withOpacity(0.12)),
                    ),
                    child: const Text('Aman & cepat', style: TextStyle(color: Colors.white, fontSize: 12, fontWeight: FontWeight.w800)),
                  ),
                ],
              ),
              const SizedBox(height: 18),
              Container(
                padding: const EdgeInsets.all(14),
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.12),
                  borderRadius: BorderRadius.circular(26),
                  border: Border.all(color: Colors.white.withOpacity(0.16)),
                ),
                child: Row(
                  children: [
                    Container(
                      width: 62,
                      height: 62,
                      decoration: const BoxDecoration(color: Colors.white, shape: BoxShape.circle),
                      child: const Icon(Icons.account_balance_wallet_rounded, color: _primary, size: 34),
                    ),
                    const SizedBox(width: 14),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text('Pilih Metode Pembayaran', style: TextStyle(color: Colors.white, fontSize: 20, fontWeight: FontWeight.w900)),
                          const SizedBox(height: 5),
                          Text(
                            'Gunakan Virtual Account, QRIS, atau e-wallet yang tersedia.',
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                            style: TextStyle(color: Colors.white.withOpacity(0.84), fontSize: 13, height: 1.35),
                          ),
                        ],
                      ),
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

  Widget _circleAction(IconData icon, VoidCallback? onTap) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(999),
      child: Container(
        width: 42,
        height: 42,
        decoration: BoxDecoration(
          color: Colors.white.withOpacity(0.14),
          shape: BoxShape.circle,
          border: Border.all(color: Colors.white.withOpacity(0.12)),
        ),
        child: Icon(icon, color: Colors.white, size: 21),
      ),
    );
  }

  Widget _paymentMethodTile(PaymentMethodModel method) {
    return InkWell(
      onTap: () => Navigator.pop(context, method),
      borderRadius: BorderRadius.circular(22),
      child: Container(
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(22),
          border: Border.all(color: const Color(0xFFE2E8F0)),
          boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.04), blurRadius: 14, offset: const Offset(0, 6))],
        ),
        child: Row(
          children: [
            Container(
              width: 62,
              height: 48,
              padding: const EdgeInsets.all(8),
              clipBehavior: Clip.antiAlias,
              decoration: BoxDecoration(
                color: _purple.withOpacity(0.08),
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: const Color(0xFFE2E8F0)),
              ),
              child: Image.network(
                method.iconUrl,
                fit: BoxFit.contain,
                errorBuilder: (context, error, stackTrace) => const Icon(Icons.account_balance_wallet_rounded, color: _primary, size: 24),
              ),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(method.name, maxLines: 1, overflow: TextOverflow.ellipsis, style: const TextStyle(fontSize: 15, color: Color(0xFF111827), fontWeight: FontWeight.w900)),
                  const SizedBox(height: 4),
                  const Text('Tap untuk memilih metode ini', style: TextStyle(fontSize: 11.5, color: _muted, fontWeight: FontWeight.w500)),
                ],
              ),
            ),
            Container(
              width: 34,
              height: 34,
              decoration: BoxDecoration(color: _accent.withOpacity(0.14), shape: BoxShape.circle),
              child: const Icon(Icons.chevron_right_rounded, color: _primary, size: 22),
            ),
          ],
        ),
      ),
    );
  }

  Widget _stateView({
    required IconData icon,
    required String title,
    required String message,
    required String buttonText,
    required VoidCallback onPressed,
    Color iconColor = _primary,
  }) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(28),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 86,
              height: 86,
              decoration: BoxDecoration(color: iconColor.withOpacity(0.10), shape: BoxShape.circle),
              child: Icon(icon, color: iconColor, size: 42),
            ),
            const SizedBox(height: 16),
            Text(title, textAlign: TextAlign.center, style: const TextStyle(fontSize: 18, color: _primary, fontWeight: FontWeight.w900)),
            const SizedBox(height: 6),
            Text(message, textAlign: TextAlign.center, style: const TextStyle(fontSize: 13, color: _muted, height: 1.4)),
            const SizedBox(height: 18),
            ElevatedButton(
              onPressed: onPressed,
              style: ElevatedButton.styleFrom(
                backgroundColor: _primary,
                foregroundColor: Colors.white,
                elevation: 0,
                padding: const EdgeInsets.symmetric(horizontal: 22, vertical: 12),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
              ),
              child: Text(buttonText, style: const TextStyle(fontWeight: FontWeight.w900)),
            ),
          ],
        ),
      ),
    );
  }
}

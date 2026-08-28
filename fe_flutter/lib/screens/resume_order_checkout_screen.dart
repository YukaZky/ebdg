import 'dart:async';
import 'dart:convert';
import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:image_picker/image_picker.dart';

import '../services/checkout_api_service.dart';
import '../services/manual_payment_api_service.dart';
import 'order_confirmation_screen.dart';

class ResumeOrderCheckoutScreen extends StatefulWidget {
  final Map<String, dynamic> order;
  const ResumeOrderCheckoutScreen({Key? key, required this.order})
    : super(key: key);
  @override
  State<ResumeOrderCheckoutScreen> createState() =>
      _ResumeOrderCheckoutScreenState();
}

class _ResumeOrderCheckoutScreenState extends State<ResumeOrderCheckoutScreen> {
  static const Color navy = Color(0xFF0C2442);
  static const Color danger = Color(0xFFB91C1C);
  static const Color dangerDark = Color(0xFF7F1D1D);
  static const Color surface = Color(0xFFF7F8FC);
  static const Color muted = Color(0xFF64748B);

  Timer? timer;
  bool loading = false;
  late Map<String, dynamic> order;
  Duration left = Duration.zero;
  XFile? proofFile;
  Map<String, dynamic>? latestConfirmation;
  final senderNameController = TextEditingController();
  final senderBankController = TextEditingController();
  final senderAccountController = TextEditingController();
  final noteController = TextEditingController();

  @override
  void initState() {
    super.initState();
    order = Map<String, dynamic>.from(widget.order);
    latestConfirmation = order['latest_confirmation'] is Map
        ? Map<String, dynamic>.from(order['latest_confirmation'])
        : null;
    syncTimer();
    WidgetsBinding.instance.addPostFrameCallback((_) => refreshStatus());
    timer = Timer.periodic(const Duration(seconds: 1), (_) {
      if (!mounted || isCanceled || proofSubmitted || paid) return;
      setState(() {
        if (left.inSeconds > 1) {
          left -= const Duration(seconds: 1);
        } else {
          left = Duration.zero;
          timer?.cancel();
          Future.microtask(refreshStatus);
        }
      });
    });
  }

  @override
  void dispose() {
    timer?.cancel();
    senderNameController.dispose();
    senderBankController.dispose();
    senderAccountController.dispose();
    noteController.dispose();
    super.dispose();
  }

  Map<String, dynamic> map(dynamic v) => v is Map<String, dynamic>
      ? v
      : v is Map
      ? Map<String, dynamic>.from(v)
      : {};
  Map<String, dynamic> decode(dynamic v) {
    if (v is Map<String, dynamic>) return v;
    if (v is Map) return Map<String, dynamic>.from(v);
    if (v is String && v.isNotEmpty) {
      try {
        final d = jsonDecode(v);
        if (d is Map<String, dynamic>) return d;
      } catch (_) {}
    }
    return {};
  }

  List items() => order['items'] is List ? order['items'] as List : [];
  num numOf(dynamic v) => v is num ? v : num.tryParse(v?.toString() ?? '') ?? 0;
  String money(dynamic v) => 'Rp ${numOf(v).toStringAsFixed(0)}';
  Map<String, dynamic> get trx => map(order['transaction']);
  Map<String, dynamic> get details => decode(trx['payment_details']);
  Map<String, dynamic> get info => map(details['payment_info']);
  bool get paid =>
      ['approved', 'settlement', 'capture'].contains(trx['status']?.toString());
  String get paymentState =>
      order['payment_state']?.toString() ??
      details['stage']?.toString() ??
      'waiting_payment';
  bool get proofSubmitted => paymentState == 'proof_submitted';
  bool get proofRejected => paymentState == 'proof_rejected';
  bool get isCanceled {
    final raw =
        order['frontend_status']?.toString().toLowerCase() ??
        order['status']?.toString().toLowerCase() ??
        '';
    return raw == 'canceled' || raw == 'cancelled';
  }

  Color get mainColor => isCanceled ? danger : navy;
  Color get gradientEnd => isCanceled ? dangerDark : const Color(0xFF123A68);
  String? get va => (info['account_number'] ?? info['va_number'])?.toString();
  String? get destinationBank => info['bank_name']?.toString();
  String? get destinationName => info['account_name']?.toString();

  void syncTimer() {
    try {
      left = DateTime.parse(info['expiry_time'].toString())
          .difference(DateTime.now());
      if (left.isNegative) left = Duration.zero;
    } catch (_) {
      left = Duration.zero;
    }
  }

  String get timerText {
    if (isCanceled) return 'Pesanan sudah dibatalkan';
    if (paid) return 'Pembayaran sudah diterima';
    if (proofSubmitted) return 'Bukti sedang diverifikasi';
    if (left.inSeconds <= 0) return 'Waktu pembayaran habis';
    return '${left.inHours.toString().padLeft(2, '0')} : ${left.inMinutes.remainder(60).toString().padLeft(2, '0')} : ${left.inSeconds.remainder(60).toString().padLeft(2, '0')}';
  }

  Future<void> refreshStatus() async {
    final id = order['id']?.toString();
    if (id == null || isCanceled) return;
    setState(() => loading = true);
    final status = await CheckoutApiService.checkOrderStatus(id);
    final response = await CheckoutApiService.getOrder(id);
    if (!mounted) return;
    if (response != null &&
        response['success'] == true &&
        response['order'] != null) {
      order = Map<String, dynamic>.from(response['order']);
      if (status != null) {
        order['payment_state'] = status['payment_state'];
        order['rejection_reason'] = status['rejection_reason'];
        latestConfirmation = status['latest_confirmation'] is Map
            ? Map<String, dynamic>.from(status['latest_confirmation'])
            : latestConfirmation;
      }
      syncTimer();
    }
    setState(() => loading = false);
    final state = status?['payment_state']?.toString();
    final message = state == 'payment_approved'
        ? 'Pembayaran sudah diterima.'
        : state == 'proof_submitted'
        ? 'Bukti sedang diverifikasi admin.'
        : state == 'proof_rejected'
        ? 'Bukti ditolak. Silakan kirim ulang.'
        : 'Pembayaran masih menunggu bukti.';
    ScaffoldMessenger.of(context)
        .showSnackBar(SnackBar(content: Text(message)));
  }

  Future<void> pickProof() async {
    final file = await ImagePicker().pickImage(
      source: ImageSource.gallery,
      imageQuality: 82,
      maxWidth: 1800,
    );
    if (!mounted || file == null) return;
    setState(() => proofFile = file);
  }

  Future<void> submitProof() async {
    final id = int.tryParse(order['id']?.toString() ?? '');
    if (id == null) return;
    if (senderNameController.text.trim().isEmpty ||
        senderBankController.text.trim().isEmpty ||
        senderAccountController.text.trim().isEmpty ||
        proofFile == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Lengkapi data pengirim dan pilih bukti pembayaran.'),
        ),
      );
      return;
    }
    setState(() => loading = true);
    final response = await ManualPaymentApiService.submitProof(
      orderId: id,
      senderName: senderNameController.text,
      senderBank: senderBankController.text,
      senderAccountNumber: senderAccountController.text,
      transferredAmount: numOf(order['total']).toDouble(),
      proof: proofFile!,
      note: noteController.text,
    );
    if (!mounted) return;
    setState(() {
      loading = false;
      if (response?['success'] == true) {
        order['payment_state'] = 'proof_submitted';
        latestConfirmation = response?['confirmation'] is Map
            ? Map<String, dynamic>.from(response!['confirmation'])
            : null;
        proofFile = null;
        timer?.cancel();
      }
    });
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          response?['success'] == true
              ? 'Bukti terkirim dan menunggu verifikasi admin.'
              : response?['message']?.toString() ??
                    ManualPaymentApiService.lastError ??
                    'Bukti gagal dikirim.',
        ),
      ),
    );
  }

  Future<void> completeCheckout() async {
    final id = order['id']?.toString();
    if (id == null || isCanceled) return;
    setState(() => loading = true);
    final response = await CheckoutApiService.completeCheckout(id);
    if (!mounted) return;
    setState(() => loading = false);
    if (response != null &&
        response['success'] == true &&
        response['order'] != null) {
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(
          builder: (_) => OrderConfirmationScreen(
            order: Map<String, dynamic>.from(response['order']),
          ),
        ),
      );
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Checkout akhir belum bisa diselesaikan.'),
        ),
      );
    }
  }

  Future<void> cancelOrder() async {
    final id = order['id']?.toString();
    if (id == null || loading || isCanceled) return;
    final ok = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text(
          'Batalkan pesanan?',
          style: TextStyle(fontSize: 16, fontWeight: FontWeight.w900),
        ),
        content: const Text(
          'Pesanan ini akan dipindahkan ke status canceled.',
          style: TextStyle(fontSize: 13),
        ),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Tidak'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            style: ElevatedButton.styleFrom(
              backgroundColor: danger,
              foregroundColor: Colors.white,
            ),
            child: const Text('Batalkan'),
          ),
        ],
      ),
    );
    if (ok != true || !mounted) return;
    setState(() => loading = true);
    final response = await CheckoutApiService.cancelOrder(id);
    if (!mounted) return;
    setState(() => loading = false);
    if (response != null && response['success'] == true) {
      ScaffoldMessenger.of(context)
          .showSnackBar(const SnackBar(content: Text('Pesanan dibatalkan.')));
      Navigator.pop(context, true);
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            response?['message']?.toString() ?? 'Gagal membatalkan pesanan.',
          ),
        ),
      );
    }
  }

  void copyVa() {
    if (va == null) return;
    Clipboard.setData(ClipboardData(text: va!));
    ScaffoldMessenger.of(context)
        .showSnackBar(const SnackBar(content: Text('Nomor VA disalin.')));
  }

  @override
  Widget build(BuildContext context) => Scaffold(
    backgroundColor: surface,
    body: SingleChildScrollView(
      physics: const BouncingScrollPhysics(),
      padding: const EdgeInsets.only(bottom: 130),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          header(),
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 16, 16, 0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                paymentCard(),
                section('Konfirmasi Pembayaran'),
                proofCard(),
                section('Daftar Barang'),
                productCard(),
                section('Total Order'),
                totalCard(),
              ],
            ),
          ),
        ],
      ),
    ),
    bottomSheet: bottomActions(),
  );

  Widget header() => Container(
    decoration: BoxDecoration(
      gradient: LinearGradient(
        colors: [mainColor, gradientEnd],
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
      ),
      borderRadius: const BorderRadius.vertical(bottom: Radius.circular(30)),
    ),
    child: SafeArea(
      bottom: false,
      child: Padding(
        padding: const EdgeInsets.fromLTRB(18, 16, 18, 22),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                circle(Icons.arrow_back_rounded, () => Navigator.pop(context)),
                chip(
                  isCanceled
                      ? 'Canceled'
                      : paid
                      ? 'Dibayar'
                      : proofSubmitted
                      ? 'Verifikasi'
                      : proofRejected
                      ? 'Bukti Ditolak'
                      : 'Pending',
                ),
              ],
            ),
            const SizedBox(height: 16),
            Container(
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                color: Colors.white.withOpacity(.12),
                borderRadius: BorderRadius.circular(24),
                border: Border.all(color: Colors.white.withOpacity(.16)),
              ),
              child: Row(
                children: [
                  Container(
                    width: 56,
                    height: 56,
                    decoration: const BoxDecoration(
                      color: Colors.white,
                      shape: BoxShape.circle,
                    ),
                    child: Icon(
                      isCanceled
                          ? Icons.cancel_rounded
                          : Icons.receipt_long_rounded,
                      color: mainColor,
                      size: 30,
                    ),
                  ),
                  const SizedBox(width: 14),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          isCanceled
                              ? 'Checkout Canceled'
                              : 'Lanjutkan Checkout',
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 17,
                            fontWeight: FontWeight.w900,
                          ),
                        ),
                        const SizedBox(height: 5),
                        Text(
                          isCanceled
                              ? 'Pesanan ini tidak bisa dilanjutkan karena sudah dibatalkan.'
                              : 'Pantau instruksi pembayaran dan selesaikan checkout.',
                          style: TextStyle(
                            color: Colors.white.withOpacity(.84),
                            fontSize: 12.5,
                            height: 1.35,
                          ),
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

  Widget circle(IconData icon, VoidCallback onTap) => InkWell(
    onTap: onTap,
    borderRadius: BorderRadius.circular(999),
    child: Container(
      width: 42,
      height: 42,
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(.14),
        shape: BoxShape.circle,
        border: Border.all(color: Colors.white.withOpacity(.12)),
      ),
      child: Icon(icon, color: Colors.white, size: 21),
    ),
  );
  Widget chip(String text) => Container(
    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 7),
    decoration: BoxDecoration(
      color: Colors.white.withOpacity(.14),
      borderRadius: BorderRadius.circular(99),
      border: Border.all(color: Colors.white.withOpacity(.12)),
    ),
    child: Text(
      text,
      style: const TextStyle(
        color: Colors.white,
        fontSize: 12,
        fontWeight: FontWeight.w800,
      ),
    ),
  );

  Widget bottomActions() => Container(
    padding: const EdgeInsets.fromLTRB(16, 12, 16, 16),
    decoration: BoxDecoration(
      color: Colors.white,
      boxShadow: [
        BoxShadow(
          color: Colors.black.withOpacity(.08),
          blurRadius: 16,
          offset: const Offset(0, -5),
        ),
      ],
    ),
    child: SafeArea(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (isCanceled)
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: () => Navigator.pop(context),
                style: btn(),
                child: const Text(
                  'KEMBALI',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 13,
                    fontWeight: FontWeight.w900,
                  ),
                ),
              ),
            )
          else
            SizedBox(
              width: double.infinity,
              child: paid
                  ? ElevatedButton(
                      onPressed: loading ? null : completeCheckout,
                      style: btn(),
                      child: const Text(
                        'SELESAIKAN CHECKOUT',
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 13,
                          fontWeight: FontWeight.w900,
                        ),
                      ),
                    )
                  : OutlinedButton.icon(
                      onPressed: loading ? null : refreshStatus,
                      icon: const Icon(Icons.refresh_rounded),
                      label: const Text('CEK STATUS'),
                      style: OutlinedButton.styleFrom(
                        foregroundColor: mainColor,
                        side: BorderSide(color: mainColor),
                        padding: const EdgeInsets.symmetric(vertical: 13),
                        textStyle: const TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.w900,
                        ),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(14),
                        ),
                      ),
                    ),
            ),
          if (!isCanceled) ...[
            const SizedBox(height: 8),
            SizedBox(
              width: double.infinity,
              child: TextButton.icon(
                onPressed: loading ? null : cancelOrder,
                icon: const Icon(Icons.cancel_outlined, size: 18),
                label: const Text(
                  'BATALKAN PESANAN',
                  style: TextStyle(fontSize: 12.5, fontWeight: FontWeight.w900),
                ),
                style: TextButton.styleFrom(foregroundColor: danger),
              ),
            ),
          ],
        ],
      ),
    ),
  );

  ButtonStyle btn() => ElevatedButton.styleFrom(
    backgroundColor: mainColor,
    padding: const EdgeInsets.symmetric(vertical: 13),
    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
  );
  Widget section(String t) => Padding(
    padding: const EdgeInsets.fromLTRB(0, 14, 0, 8),
    child: Text(
      t,
      style: TextStyle(
        fontSize: 13,
        color: mainColor,
        fontWeight: FontWeight.w900,
      ),
    ),
  );
  BoxDecoration box() => BoxDecoration(
    color: Colors.white,
    borderRadius: BorderRadius.circular(22),
    border: Border.all(
      color: isCanceled ? const Color(0xFFFCA5A5) : const Color(0xFFE2E8F0),
    ),
    boxShadow: [
      BoxShadow(
        color: Colors.black.withOpacity(.04),
        blurRadius: 14,
        offset: const Offset(0, 6),
      ),
    ],
  );

  Widget paymentCard() => Container(
    width: double.infinity,
    padding: const EdgeInsets.all(16),
    decoration: BoxDecoration(
      gradient: LinearGradient(
        colors: [mainColor, gradientEnd],
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
      ),
      borderRadius: BorderRadius.circular(24),
    ),
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          isCanceled
              ? 'PESANAN DIBATALKAN'
              : paid
              ? 'PEMBAYARAN DITERIMA'
              : proofSubmitted
              ? 'MENUNGGU VERIFIKASI'
              : proofRejected
              ? 'BUKTI DITOLAK'
              : 'MENUNGGU PEMBAYARAN',
          style: const TextStyle(
            color: Colors.white,
            fontSize: 11,
            fontWeight: FontWeight.w900,
          ),
        ),
        const SizedBox(height: 12),
        Text(
          timerText,
          style: const TextStyle(
            color: Colors.white,
            fontSize: 20,
            fontWeight: FontWeight.w900,
          ),
        ),
        const SizedBox(height: 14),
        Container(
          width: double.infinity,
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(18),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              if (va != null && !isCanceled) ...[
                Text(
                  destinationBank ?? 'Rekening / Virtual Account',
                  style: const TextStyle(
                    fontSize: 11,
                    color: muted,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                Row(
                  children: [
                    Expanded(
                      child: SelectableText(
                        va!,
                        style: TextStyle(
                          fontSize: 18,
                          color: mainColor,
                          fontWeight: FontWeight.w900,
                        ),
                      ),
                    ),
                    IconButton(
                      onPressed: copyVa,
                      icon: Icon(Icons.copy_rounded, color: mainColor),
                    ),
                  ],
                ),
                if (destinationName != null)
                  Text(
                    'a.n. $destinationName',
                    style: const TextStyle(fontSize: 12, color: muted),
                  ),
              ],
              if (isCanceled)
                const Text(
                  'Instruksi pembayaran tidak ditampilkan karena order sudah canceled.',
                  style: TextStyle(fontSize: 12, color: Color(0xFF475569)),
                ),
              if (!isCanceled && va == null)
                const Text(
                  'Detail pembayaran belum tersedia. Tekan cek status atau hubungi admin.',
                  style: TextStyle(fontSize: 12, color: Color(0xFF475569)),
                ),
            ],
          ),
        ),
      ],
    ),
  );

  Widget proofCard() {
    if (paid)
      return Container(
        width: double.infinity,
        padding: const EdgeInsets.all(14),
        decoration: box(),
        child: const Text(
          'Pembayaran sudah diverifikasi.',
          style: TextStyle(color: Colors.green, fontWeight: FontWeight.w800),
        ),
      );
    if (isCanceled)
      return Container(
        width: double.infinity,
        padding: const EdgeInsets.all(14),
        decoration: box(),
        child: const Text(
          'Form pembayaran sudah ditutup.',
          style: TextStyle(color: danger, fontWeight: FontWeight.w800),
        ),
      );
    if (proofSubmitted)
      return Container(
        width: double.infinity,
        padding: const EdgeInsets.all(14),
        decoration: box(),
        child: const Text(
          'Bukti pembayaran sudah terkirim. Order tidak kedaluwarsa selama menunggu verifikasi Super Admin.',
          style: TextStyle(
            color: Colors.orange,
            fontWeight: FontWeight.w700,
            height: 1.4,
          ),
        ),
      );
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(14),
      decoration: box(),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (proofRejected)
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(10),
              margin: const EdgeInsets.only(bottom: 12),
              decoration: BoxDecoration(
                color: const Color(0xFFFEF2F2),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Text(
                'Bukti ditolak: ${order['rejection_reason'] ?? latestConfirmation?['rejection_reason'] ?? 'Silakan kirim ulang.'}',
                style: const TextStyle(
                  color: danger,
                  fontSize: 12,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ),
          TextField(
            controller: senderNameController,
            decoration: const InputDecoration(
              labelText: 'Nama Pemilik Rekening Pengirim',
              border: OutlineInputBorder(),
            ),
          ),
          const SizedBox(height: 10),
          TextField(
            controller: senderBankController,
            decoration: const InputDecoration(
              labelText: 'Bank Pengirim',
              border: OutlineInputBorder(),
            ),
          ),
          const SizedBox(height: 10),
          TextField(
            controller: senderAccountController,
            keyboardType: TextInputType.number,
            decoration: const InputDecoration(
              labelText: 'Nomor Rekening Pengirim',
              border: OutlineInputBorder(),
            ),
          ),
          const SizedBox(height: 10),
          TextField(
            controller: noteController,
            maxLines: 2,
            decoration: const InputDecoration(
              labelText: 'Catatan (opsional)',
              border: OutlineInputBorder(),
            ),
          ),
          const SizedBox(height: 10),
          InkWell(
            onTap: loading ? null : pickProof,
            child: Container(
              width: double.infinity,
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: surface,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: const Color(0xFFCBD5E1)),
              ),
              child: proofFile == null
                  ? const Row(
                      children: [
                        Icon(Icons.upload_file_rounded, color: navy),
                        SizedBox(width: 8),
                        Text('Pilih bukti pembayaran'),
                      ],
                    )
                  : FutureBuilder<Uint8List>(
                      future: proofFile!.readAsBytes(),
                      builder: (_, snapshot) => Row(
                        children: [
                          if (snapshot.hasData)
                            Image.memory(
                              snapshot.data!,
                              width: 50,
                              height: 50,
                              fit: BoxFit.cover,
                            ),
                          const SizedBox(width: 8),
                          Expanded(
                            child: Text(
                              proofFile!.name,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                        ],
                      ),
                    ),
            ),
          ),
          const SizedBox(height: 10),
          SizedBox(
            width: double.infinity,
            child: ElevatedButton.icon(
              onPressed: loading ? null : submitProof,
              icon: const Icon(Icons.send_rounded),
              label: const Text('KIRIM PEMBAYARAN'),
              style: ElevatedButton.styleFrom(
                backgroundColor: mainColor,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(vertical: 13),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget productCard() => Container(
    width: double.infinity,
    padding: const EdgeInsets.all(14),
    decoration: box(),
    child: Column(
      children: items().map((raw) {
        final item = map(raw);
        final product = map(item['product']);
        final qty = numOf(item['quantity']);
        final price = numOf(item['price']);
        return Padding(
          padding: const EdgeInsets.only(bottom: 10),
          child: Row(
            children: [
              Expanded(
                child: Text(
                  '${qty.toInt()}x ${product['name'] ?? 'Produk'}',
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    fontSize: 12.5,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
              Text(
                money(price * qty),
                style: TextStyle(
                  fontSize: 12,
                  color: mainColor,
                  fontWeight: FontWeight.w900,
                ),
              ),
            ],
          ),
        );
      }).toList(),
    ),
  );
  Widget totalCard() => Container(
    width: double.infinity,
    padding: const EdgeInsets.all(14),
    decoration: box(),
    child: Column(
      children: [
        row('Subtotal Produk', money(order['subtotal'])),
        const SizedBox(height: 7),
        row('Ongkir', money(order['ongkir'])),
        const Divider(height: 22),
        row('Total Order', money(order['total']), strong: true),
      ],
    ),
  );
  Widget row(String l, String v, {bool strong = false}) => Row(
    mainAxisAlignment: MainAxisAlignment.spaceBetween,
    children: [
      Text(
        l,
        style: TextStyle(
          fontSize: strong ? 14 : 12,
          color: strong ? mainColor : muted,
          fontWeight: strong ? FontWeight.w900 : FontWeight.w500,
        ),
      ),
      Text(
        v,
        style: TextStyle(
          fontSize: strong ? 18 : 12.5,
          color: strong ? mainColor : const Color(0xFF111827),
          fontWeight: FontWeight.w900,
        ),
      ),
    ],
  );
}

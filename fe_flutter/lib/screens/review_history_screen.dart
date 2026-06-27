import 'package:flutter/material.dart';
import '../services/marketplace_api_service.dart';

class ReviewHistoryScreen extends StatefulWidget {
  const ReviewHistoryScreen({Key? key}) : super(key: key);

  @override
  State<ReviewHistoryScreen> createState() => _ReviewHistoryScreenState();
}

class _ReviewHistoryScreenState extends State<ReviewHistoryScreen> {
  static const Color _primary = Color(0xFF0C2442);
  static const Color _surface = Color(0xFFF7F8FC);
  static const Color _bubble = Color(0xFFF8FBFF);
  static const Color _bubbleBorder = Color(0xFFD8E7F8);
  static const Color _muted = Color(0xFF64748B);
  static const Color _danger = Color(0xFFB91C1C);

  bool _loading = true;
  List<dynamic> _reviews = [];

  @override
  void initState() {
    super.initState();
    _loadReviews();
  }

  Future<void> _loadReviews() async {
    setState(() => _loading = true);
    final data = await MarketplaceApiService.myReviews();
    if (!mounted) return;
    setState(() {
      _reviews = data;
      _loading = false;
    });
  }

  Map<String, dynamic> _map(dynamic value) {
    if (value is Map<String, dynamic>) return value;
    if (value is Map) return Map<String, dynamic>.from(value);
    return <String, dynamic>{};
  }

  DateTime? _date(dynamic value) {
    final raw = value?.toString() ?? '';
    if (raw.isEmpty || raw == 'null') return null;
    return DateTime.tryParse(raw.replaceFirst(' ', 'T'))?.toLocal();
  }

  String _timeText(dynamic value) {
    final date = _date(value);
    if (date == null) return '-';
    final hour = date.hour.toString().padLeft(2, '0');
    final minute = date.minute.toString().padLeft(2, '0');
    return '$hour:$minute';
  }

  String _dateText(dynamic value) {
    final date = _date(value);
    if (date == null) return '-';
    const months = ['Jan', 'Feb', 'Mar', 'Apr', 'Mei', 'Jun', 'Jul', 'Agu', 'Sep', 'Okt', 'Nov', 'Des'];
    return '${date.day} ${months[date.month - 1]} ${date.year}';
  }

  String _groupKey(dynamic review) {
    final date = _date(_map(review)['created_at']);
    if (date == null) return 'older';
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final reviewDay = DateTime(date.year, date.month, date.day);
    if (reviewDay == today) return 'today';
    if (today.difference(reviewDay).inDays < 7) return 'week';
    if (date.year == now.year) return 'year';
    return 'older';
  }

  List<dynamic> _grouped(String key) => _reviews.where((review) => _groupKey(review) == key).toList();

  Widget _stars(num rating) => Row(mainAxisSize: MainAxisSize.min, children: List.generate(5, (index) => Icon(index < rating.round() ? Icons.star_rounded : Icons.star_border_rounded, color: Colors.amber, size: 15)));

  Future<void> _deleteReview(dynamic rawReview) async {
    final review = _map(rawReview);
    final id = int.tryParse(review['id']?.toString() ?? '') ?? 0;
    final type = review['type']?.toString() ?? 'product';
    if (id <= 0) return;

    final confirm = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('Hapus Ulasan'),
        content: const Text('Ulasan ini akan dihapus dari daftar ulasan kamu.'),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context, false), child: const Text('Batal')),
          TextButton(onPressed: () => Navigator.pop(context, true), child: const Text('Hapus', style: TextStyle(color: _danger, fontWeight: FontWeight.w900))),
        ],
      ),
    );
    if (confirm != true) return;

    final ok = await MarketplaceApiService.deleteReview(type: type, id: id);
    if (!mounted) return;
    if (ok) {
      setState(() => _reviews.removeWhere((item) => _map(item)['id']?.toString() == id.toString() && (_map(item)['type']?.toString() ?? 'product') == type));
    }
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(ok ? 'Ulasan berhasil dihapus.' : MarketplaceApiService.lastError ?? 'Gagal menghapus ulasan.')));
  }

  Widget _reviewBubble(dynamic rawReview) {
    final review = _map(rawReview);
    final type = review['type']?.toString() == 'store' ? 'Toko' : 'Produk';
    final targetName = review['target_name']?.toString() ?? type;
    final rating = num.tryParse(review['rating']?.toString() ?? '0') ?? 0;
    final comment = review['review']?.toString() ?? '';
    final createdAt = review['created_at'];

    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Container(width: 36, height: 36, decoration: BoxDecoration(color: _primary.withOpacity(.10), shape: BoxShape.circle), child: Icon(type == 'Toko' ? Icons.storefront_rounded : Icons.shopping_bag_rounded, color: _primary, size: 19)),
        const SizedBox(width: 9),
        Expanded(
          child: Container(
            padding: const EdgeInsets.all(13),
            decoration: BoxDecoration(color: _bubble, borderRadius: BorderRadius.circular(18), border: Border.all(color: _bubbleBorder), boxShadow: [BoxShadow(color: _primary.withOpacity(.035), blurRadius: 10, offset: const Offset(0, 5))]),
            child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
                Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                  Text('$type • $targetName', maxLines: 1, overflow: TextOverflow.ellipsis, style: const TextStyle(color: _primary, fontSize: 13, fontWeight: FontWeight.w900)),
                  const SizedBox(height: 3),
                  Row(children: [_stars(rating), const SizedBox(width: 7), Text('${rating.toStringAsFixed(0)}/5', style: const TextStyle(fontSize: 11, color: _muted, fontWeight: FontWeight.w700))]),
                ])),
                const SizedBox(width: 8),
                Text(_timeText(createdAt), style: const TextStyle(fontSize: 11, color: _muted, fontWeight: FontWeight.w700)),
                const SizedBox(width: 2),
                IconButton(onPressed: () => _deleteReview(review), constraints: const BoxConstraints(minWidth: 30, minHeight: 30), padding: EdgeInsets.zero, visualDensity: VisualDensity.compact, icon: const Icon(Icons.delete_outline_rounded, color: _danger, size: 19)),
              ]),
              const SizedBox(height: 9),
              Text(comment.isEmpty ? 'Tidak ada komentar.' : comment, style: const TextStyle(fontSize: 13, height: 1.45, color: Color(0xFF1F2937), fontWeight: FontWeight.w500)),
              const SizedBox(height: 8),
              Align(alignment: Alignment.centerRight, child: Text(_dateText(createdAt), style: const TextStyle(fontSize: 10.5, color: _muted))),
            ]),
          ),
        ),
      ]),
    );
  }

  Widget _section(String title, String key) {
    final items = _grouped(key);
    if (items.isEmpty) return const SizedBox.shrink();
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 8, 16, 10),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Padding(padding: const EdgeInsets.only(bottom: 10, left: 2), child: Text(title, style: const TextStyle(color: _primary, fontSize: 14, fontWeight: FontWeight.w900))),
        ...items.map(_reviewBubble),
      ]),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: _surface,
      appBar: AppBar(title: const Text('Penilaian Saya'), backgroundColor: Colors.white, foregroundColor: _primary, elevation: 0),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : RefreshIndicator(
              onRefresh: _loadReviews,
              child: _reviews.isEmpty
                  ? ListView(padding: const EdgeInsets.all(28), children: [const SizedBox(height: 120), Icon(Icons.rate_review_outlined, size: 70, color: Colors.grey.shade400), const SizedBox(height: 12), const Center(child: Text('Belum ada ulasan yang kamu berikan.', style: TextStyle(color: _muted, fontWeight: FontWeight.w700)))])
                  : ListView(children: [_section('Today', 'today'), _section('This Week', 'week'), _section('This Year', 'year'), _section('Lebih Lama', 'older'), const SizedBox(height: 20)]),
            ),
    );
  }
}

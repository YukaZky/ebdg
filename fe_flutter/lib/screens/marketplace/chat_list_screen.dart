import 'package:flutter/material.dart';
import '../../services/marketplace_api_service.dart';
import 'chat_room_screen.dart';

class ChatListScreen extends StatefulWidget {
  final String title;
  final String emptyText;
  final String? role;

  const ChatListScreen({
    Key? key,
    this.title = 'Chat',
    this.emptyText = 'Belum ada chat.',
    this.role,
  }) : super(key: key);

  @override
  State<ChatListScreen> createState() => _ChatListScreenState();
}

class _ChatListScreenState extends State<ChatListScreen> {
  List<dynamic> chats = [];
  bool loading = true;

  @override
  void initState() {
    super.initState();
    loadChats();
  }

  Future<void> loadChats() async {
    final data = await MarketplaceApiService.conversations(role: widget.role);
    if (!mounted) return;
    setState(() {
      chats = data;
      loading = false;
    });
  }

  Map<String, dynamic>? _asMap(dynamic value) {
    if (value is Map) return Map<String, dynamic>.from(value);
    return null;
  }

  String _clean(dynamic value) {
    final text = value?.toString().trim() ?? '';
    if (text.isEmpty || text == 'null') return '';
    return text;
  }

  String _conversationTitle(Map<String, dynamic> chat) {
    final displayName = _clean(chat['display_name']);
    if (displayName.isNotEmpty) return displayName;

    final counterpart = _asMap(chat['counterpart']);
    final counterpartName = _clean(counterpart?['name']);
    if (counterpartName.isNotEmpty) return counterpartName;

    final store = _asMap(chat['store']);
    final storeName = _clean(store?['name']);
    if (storeName.isNotEmpty) return storeName;

    final seller = _asMap(chat['seller']);
    final sellerName = _clean(seller?['name']);
    if (sellerName.isNotEmpty) return sellerName;

    final buyer = _asMap(chat['buyer']);
    final buyerName = _clean(buyer?['name']);
    if (buyerName.isNotEmpty) return buyerName;

    return 'Chat #${chat['id'] ?? ''}';
  }

  String _conversationSubtitle(Map<String, dynamic> chat) {
    final subtitle = _clean(chat['display_subtitle']);
    final product = _asMap(chat['product_context']) ?? _asMap(chat['product']);
    final productName = _clean(product?['name']);

    if (subtitle.isNotEmpty && productName.isNotEmpty) return '$subtitle • $productName';
    if (subtitle.isNotEmpty) return subtitle;
    if (productName.isNotEmpty) return productName;
    return '';
  }

  String _lastMessage(Map<String, dynamic> chat) {
    final message = _clean(chat['last_message_text']).isNotEmpty ? _clean(chat['last_message_text']) : _clean(chat['last_message']);
    if (message.isNotEmpty) return message;
    return 'Mulai percakapan dengan mengirim pesan.';
  }

  Widget _unreadBadge(int count) {
    if (count <= 0) return const Icon(Icons.chevron_right, color: Colors.grey);
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(color: Colors.deepOrange, borderRadius: BorderRadius.circular(999)),
      child: Text(count > 99 ? '99+' : count.toString(), style: const TextStyle(color: Colors.white, fontSize: 11, fontWeight: FontWeight.bold)),
    );
  }

  Widget _emptyState() {
    return ListView(
      physics: const AlwaysScrollableScrollPhysics(),
      children: [
        const SizedBox(height: 180),
        Icon(Icons.chat_bubble_outline, size: 70, color: Colors.grey.shade400),
        const SizedBox(height: 12),
        Center(child: Text(widget.emptyText, style: TextStyle(color: Colors.grey.shade700))),
        const SizedBox(height: 6),
        Center(child: Text('Chat toko akan muncul di sini.', style: TextStyle(color: Colors.grey.shade500, fontSize: 12))),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF6F7FB),
      appBar: AppBar(
        title: Text(widget.title),
        backgroundColor: Colors.white,
        foregroundColor: Colors.black87,
      ),
      body: loading
          ? const Center(child: CircularProgressIndicator())
          : RefreshIndicator(
              onRefresh: loadChats,
              child: chats.isEmpty
                  ? _emptyState()
                  : ListView.builder(
                      physics: const AlwaysScrollableScrollPhysics(),
                      padding: const EdgeInsets.all(16),
                      itemCount: chats.length,
                      itemBuilder: (context, index) {
                        final chat = Map<String, dynamic>.from(chats[index] as Map);
                        final id = int.tryParse(chat['id']?.toString() ?? '') ?? 0;
                        final title = _conversationTitle(chat);
                        final subtitle = _conversationSubtitle(chat);
                        final lastMessage = _lastMessage(chat);
                        final unreadCount = int.tryParse(chat['unread_count']?.toString() ?? '0') ?? 0;
                        final initial = title.isNotEmpty ? title[0].toUpperCase() : 'C';

                        return Card(
                          elevation: 0,
                          margin: const EdgeInsets.only(bottom: 12),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16), side: BorderSide(color: Colors.grey.shade200)),
                          child: ListTile(
                            contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                            leading: CircleAvatar(
                              backgroundColor: Colors.deepOrange.shade50,
                              child: Text(initial, style: const TextStyle(color: Colors.deepOrange, fontWeight: FontWeight.bold)),
                            ),
                            title: Text(title, style: const TextStyle(fontWeight: FontWeight.bold), maxLines: 1, overflow: TextOverflow.ellipsis),
                            subtitle: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                if (subtitle.isNotEmpty)
                                  Padding(
                                    padding: const EdgeInsets.only(top: 2, bottom: 2),
                                    child: Text(subtitle, style: TextStyle(fontSize: 12, color: Colors.grey.shade700), maxLines: 1, overflow: TextOverflow.ellipsis),
                                  ),
                                Text(lastMessage, maxLines: 1, overflow: TextOverflow.ellipsis, style: TextStyle(color: unreadCount > 0 ? Colors.black87 : Colors.grey.shade700, fontWeight: unreadCount > 0 ? FontWeight.w700 : FontWeight.normal)),
                              ],
                            ),
                            trailing: _unreadBadge(unreadCount),
                            onTap: () {
                              if (id <= 0) return;
                              Navigator.push(
                                context,
                                MaterialPageRoute(builder: (_) => ChatRoomScreen(conversationId: id, title: title, initialConversation: chat)),
                              ).then((_) => loadChats());
                            },
                          ),
                        );
                      },
                    ),
            ),
    );
  }
}

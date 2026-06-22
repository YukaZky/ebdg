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

  String _conversationTitle(Map<String, dynamic> chat) {
    final counterpart = _asMap(chat['counterpart']);
    final counterpartName = counterpart?['name']?.toString().trim() ?? '';
    if (counterpartName.isNotEmpty && counterpartName != 'null') return counterpartName;

    final seller = _asMap(chat['seller']);
    final sellerName = seller?['name']?.toString().trim() ?? '';
    if (sellerName.isNotEmpty && sellerName != 'null') return sellerName;

    final buyer = _asMap(chat['buyer']);
    final buyerName = buyer?['name']?.toString().trim() ?? '';
    if (buyerName.isNotEmpty && buyerName != 'null') return buyerName;

    return 'Chat #${chat['id'] ?? ''}';
  }

  String _productName(Map<String, dynamic> chat) {
    final product = _asMap(chat['product']);
    final name = product?['name']?.toString().trim() ?? '';
    return name == 'null' ? '' : name;
  }

  String _lastMessage(Map<String, dynamic> chat) {
    final message = chat['last_message']?.toString().trim() ?? '';
    if (message.isNotEmpty && message != 'null') return message;
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
                  ? ListView(
                      physics: const AlwaysScrollableScrollPhysics(),
                      children: [
                        const SizedBox(height: 180),
                        const Icon(Icons.chat_bubble_outline, size: 70, color: Colors.grey),
                        const SizedBox(height: 12),
                        Center(child: Text(widget.emptyText)),
                      ],
                    )
                  : ListView.builder(
                      physics: const AlwaysScrollableScrollPhysics(),
                      padding: const EdgeInsets.all(16),
                      itemCount: chats.length,
                      itemBuilder: (context, index) {
                        final chat = Map<String, dynamic>.from(chats[index] as Map);
                        final id = int.tryParse(chat['id'].toString()) ?? 0;
                        final title = _conversationTitle(chat);
                        final productName = _productName(chat);
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
                                if (productName.isNotEmpty)
                                  Padding(
                                    padding: const EdgeInsets.only(top: 2, bottom: 2),
                                    child: Text(productName, style: TextStyle(fontSize: 12, color: Colors.grey.shade700), maxLines: 1, overflow: TextOverflow.ellipsis),
                                  ),
                                Text(lastMessage, maxLines: 1, overflow: TextOverflow.ellipsis),
                              ],
                            ),
                            trailing: _unreadBadge(unreadCount),
                            onTap: () {
                              Navigator.push(
                                context,
                                MaterialPageRoute(builder: (_) => ChatRoomScreen(conversationId: id, title: title)),
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

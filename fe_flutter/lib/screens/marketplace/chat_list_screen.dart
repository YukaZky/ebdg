import 'package:flutter/material.dart';
import '../../services/marketplace_api_service.dart';
import 'chat_room_screen.dart';

class ChatListScreen extends StatefulWidget {
  const ChatListScreen({Key? key}) : super(key: key);

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
    final data = await MarketplaceApiService.conversations();
    if (!mounted) return;
    setState(() {
      chats = data;
      loading = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF6F7FB),
      appBar: AppBar(
        title: const Text('Chat'),
        backgroundColor: Colors.white,
        foregroundColor: Colors.black87,
      ),
      body: loading
          ? const Center(child: CircularProgressIndicator())
          : RefreshIndicator(
              onRefresh: loadChats,
              child: chats.isEmpty
                  ? ListView(
                      children: const [
                        SizedBox(height: 180),
                        Icon(Icons.chat_bubble_outline, size: 70, color: Colors.grey),
                        SizedBox(height: 12),
                        Center(child: Text('Belum ada chat.')),
                      ],
                    )
                  : ListView.builder(
                      padding: const EdgeInsets.all(16),
                      itemCount: chats.length,
                      itemBuilder: (context, index) {
                        final chat = chats[index];
                        final id = int.tryParse(chat['id'].toString()) ?? 0;
                        final lastMessage = chat['last_message']?.toString() ?? 'Mulai percakapan';
                        return Card(
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                          child: ListTile(
                            leading: const CircleAvatar(child: Icon(Icons.person)),
                            title: Text('Chat #$id', style: const TextStyle(fontWeight: FontWeight.bold)),
                            subtitle: Text(lastMessage, maxLines: 1, overflow: TextOverflow.ellipsis),
                            trailing: const Icon(Icons.chevron_right),
                            onTap: () {
                              Navigator.push(
                                context,
                                MaterialPageRoute(builder: (_) => ChatRoomScreen(conversationId: id)),
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

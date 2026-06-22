import 'package:flutter/material.dart';
import '../../services/api_service.dart';
import '../../services/marketplace_api_service.dart';

class ChatRoomScreen extends StatefulWidget {
  final int conversationId;
  final String? title;

  const ChatRoomScreen({Key? key, required this.conversationId, this.title}) : super(key: key);

  @override
  State<ChatRoomScreen> createState() => _ChatRoomScreenState();
}

class _ChatRoomScreenState extends State<ChatRoomScreen> {
  final TextEditingController messageController = TextEditingController();
  List<dynamic> messages = [];
  int? currentUserId;
  bool loading = true;
  bool sending = false;

  @override
  void initState() {
    super.initState();
    loadMessages();
  }

  @override
  void dispose() {
    messageController.dispose();
    super.dispose();
  }

  Future<void> _ensureCurrentUser() async {
    if (currentUserId != null) return;
    final profile = await ApiService.getUserProfile();
    currentUserId = int.tryParse(profile?['id']?.toString() ?? '');
  }

  Future<void> loadMessages() async {
    await _ensureCurrentUser();
    final data = await MarketplaceApiService.messages(widget.conversationId);
    if (!mounted) return;
    setState(() {
      messages = data;
      loading = false;
    });
  }

  Future<void> sendMessage() async {
    final text = messageController.text.trim();
    if (text.isEmpty) return;

    setState(() => sending = true);
    final ok = await MarketplaceApiService.sendMessage(widget.conversationId, text);
    if (!mounted) return;
    setState(() => sending = false);

    if (ok) {
      messageController.clear();
      await loadMessages();
    } else {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Gagal mengirim pesan.')));
    }
  }

  Map<String, dynamic>? _asMap(dynamic value) {
    if (value is Map) return Map<String, dynamic>.from(value);
    return null;
  }

  Widget _messageBubble(Map<String, dynamic> item) {
    final text = item['message']?.toString() ?? '';
    final fromId = int.tryParse(item['sender_id']?.toString() ?? '');
    final isMine = fromId != null && fromId == currentUserId;
    final sender = _asMap(item['sender']);
    final senderName = sender?['name']?.toString() ?? 'Pengguna';

    return Align(
      alignment: isMine ? Alignment.centerRight : Alignment.centerLeft,
      child: Container(
        constraints: BoxConstraints(maxWidth: MediaQuery.of(context).size.width * 0.78),
        margin: const EdgeInsets.only(bottom: 10),
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
        decoration: BoxDecoration(
          color: isMine ? Colors.deepOrange : Colors.white,
          borderRadius: BorderRadius.only(
            topLeft: const Radius.circular(16),
            topRight: const Radius.circular(16),
            bottomLeft: Radius.circular(isMine ? 16 : 4),
            bottomRight: Radius.circular(isMine ? 4 : 16),
          ),
          boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.04), blurRadius: 8, offset: const Offset(0, 3))],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (!isMine)
              Padding(
                padding: const EdgeInsets.only(bottom: 3),
                child: Text(senderName, style: const TextStyle(fontSize: 11, color: Colors.deepOrange, fontWeight: FontWeight.bold)),
              ),
            Text(text, style: TextStyle(color: isMine ? Colors.white : Colors.black87, height: 1.35)),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF6F7FB),
      appBar: AppBar(
        title: Text(widget.title?.isNotEmpty == true ? widget.title! : 'Ruang Chat'),
        backgroundColor: Colors.white,
        foregroundColor: Colors.black87,
      ),
      body: Column(
        children: [
          Expanded(
            child: loading
                ? const Center(child: CircularProgressIndicator())
                : RefreshIndicator(
                    onRefresh: loadMessages,
                    child: messages.isEmpty
                        ? ListView(
                            physics: const AlwaysScrollableScrollPhysics(),
                            children: const [
                              SizedBox(height: 180),
                              Icon(Icons.chat_bubble_outline, color: Colors.grey, size: 64),
                              SizedBox(height: 12),
                              Center(child: Text('Belum ada pesan. Tulis pesan pertama Anda.')),
                            ],
                          )
                        : ListView.builder(
                            physics: const AlwaysScrollableScrollPhysics(),
                            padding: const EdgeInsets.all(16),
                            itemCount: messages.length,
                            itemBuilder: (context, index) {
                              final item = Map<String, dynamic>.from(messages[index] as Map);
                              return _messageBubble(item);
                            },
                          ),
                  ),
          ),
          SafeArea(
            child: Container(
              padding: const EdgeInsets.fromLTRB(12, 10, 12, 12),
              color: Colors.white,
              child: Row(
                children: [
                  Expanded(
                    child: TextField(
                      controller: messageController,
                      minLines: 1,
                      maxLines: 4,
                      textInputAction: TextInputAction.send,
                      onSubmitted: (_) {
                        if (!sending) sendMessage();
                      },
                      decoration: InputDecoration(
                        hintText: 'Tulis pesan...',
                        filled: true,
                        fillColor: const Color(0xFFF6F7FB),
                        border: OutlineInputBorder(borderRadius: BorderRadius.circular(18), borderSide: BorderSide.none),
                        contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Material(
                    color: Colors.deepOrange,
                    shape: const CircleBorder(),
                    child: IconButton(
                      onPressed: sending ? null : sendMessage,
                      icon: sending
                          ? const SizedBox(width: 18, height: 18, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                          : const Icon(Icons.send, color: Colors.white),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../supabase_config.dart';

class ChatDetailScreen extends StatefulWidget {
  final String productId;
  final String productName;
  const ChatDetailScreen({super.key, required this.productId, required this.productName});

  @override
  State<ChatDetailScreen> createState() => _ChatDetailScreenState();
}

class _ChatDetailScreenState extends State<ChatDetailScreen> {
  final TextEditingController _controller = TextEditingController();
  List<Map<String, dynamic>> _messages = [];
  RealtimeChannel? _channel;

  @override
  void initState() {
    super.initState();
    _fetchMessages();
    _subscribeToMessages();
  }

  Future<void> _fetchMessages() async {
    final user = SupabaseConfig.client.auth.currentUser!;
    final response = await SupabaseConfig.client
        .from('chats')
        .select()
        .eq('user_id', user.id)
        .eq('product_id', widget.productId)
        .order('created_at');
    setState(() => _messages = List<Map<String, dynamic>>.from(response));
  }

  void _subscribeToMessages() {
    final user = SupabaseConfig.client.auth.currentUser!;
    _channel = SupabaseConfig.client
        .channel('chats:product_id=eq.${widget.productId}')
        .onPostgresChanges(
          event: PostgresChangeEvent.insert,
          schema: 'public',
          table: 'chats',
          callback: (payload) => _fetchMessages(),
        )
        .subscribe();
  }

  Future<void> _sendMessage() async {
    final text = _controller.text.trim();
    if (text.isEmpty) return;
    final user = SupabaseConfig.client.auth.currentUser!;
    await SupabaseConfig.client.from('chats').insert({
      'user_id': user.id,
      'product_id': widget.productId,
      'message': text,
      'is_admin': false,
    });
    _controller.clear();
  }

  @override
  void dispose() {
    _channel?.unsubscribe();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text('Chat about ${widget.productName}'), centerTitle: true),
      body: Column(
        children: [
          Expanded(
            child: ListView.builder(
              reverse: true,
              itemCount: _messages.length,
              itemBuilder: (ctx, i) {
                final msg = _messages[_messages.length - 1 - i];
                final isUser = !msg['is_admin'];
                return Align(
                  alignment: isUser ? Alignment.centerRight : Alignment.centerLeft,
                  child: Container(
                    margin: const EdgeInsets.symmetric(vertical: 4, horizontal: 8),
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                    decoration: BoxDecoration(
                      color: isUser ? const Color(0xFF0097A7) : Colors.grey.shade300,
                      borderRadius: BorderRadius.circular(16),
                    ),
                    child: Text(msg['message'], style: TextStyle(color: isUser ? Colors.white : Colors.black)),
                  ),
                );
              },
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(8.0),
            child: Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: _controller,
                    decoration: InputDecoration(hintText: 'Type your message...', border: OutlineInputBorder(borderRadius: BorderRadius.circular(30))),
                  ),
                ),
                const SizedBox(width: 8),
                IconButton(onPressed: _sendMessage, icon: const Icon(Icons.send, color: Color(0xFF0097A7))),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
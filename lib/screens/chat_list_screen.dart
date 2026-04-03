import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../supabase_config.dart';
import 'chat_detail_screen.dart';

class ChatListScreen extends StatefulWidget {
  const ChatListScreen({super.key});

  @override
  State<ChatListScreen> createState() => _ChatListScreenState();
}

class _ChatListScreenState extends State<ChatListScreen> {
  List<Map<String, dynamic>> _chats = [];
  RealtimeChannel? _channel;

  @override
  void initState() {
    super.initState();
    _fetchChats();
    _subscribeToChats();
  }

  Future<void> _fetchChats() async {
    final user = SupabaseConfig.client.auth.currentUser!;
    final response = await SupabaseConfig.client
        .from('chats')
        .select('*, products(name, id)')
        .eq('user_id', user.id)
        .order('created_at', ascending: false);
    // Group by product
    final Map<String, Map<String, dynamic>> grouped = {};
    for (var msg in response) {
      final productId = msg['products']['id'];
      if (!grouped.containsKey(productId)) {
        grouped[productId] = {
          'product': msg['products'],
          'last_message': msg['message'],
          'last_time': msg['created_at'],
        };
      }
    }
    setState(() => _chats = grouped.values.toList());
  }

  void _subscribeToChats() {
    final user = SupabaseConfig.client.auth.currentUser!;
    _channel = SupabaseConfig.client
        .channel('chats:user_id=eq.$user.id')
        .onPostgresChanges(
          event: PostgresChangeEvent.insert,
          schema: 'public',
          table: 'chats',
          callback: (payload) => _fetchChats(),
        )
        .subscribe();
  }

  @override
  void dispose() {
    _channel?.unsubscribe();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Support Chats'), centerTitle: true),
      body: _chats.isEmpty
          ? const Center(child: Text('No conversations yet'))
          : ListView.builder(
              itemCount: _chats.length,
              itemBuilder: (ctx, i) {
                final chat = _chats[i];
                final product = chat['product'];
                return ListTile(
                  leading: const Icon(Icons.chat, color: Color(0xFF0097A7)),
                  title: Text(product['name']),
                  subtitle: Text(chat['last_message']),
                  trailing: Text(_formatTime(chat['last_time'])),
                  onTap: () => Navigator.push(
                    context,
                    MaterialPageRoute(builder: (_) => ChatDetailScreen(productId: product['id'], productName: product['name'])),
                  ),
                );
              },
            ),
    );
  }

  String _formatTime(String time) {
    final dt = DateTime.parse(time);
    final now = DateTime.now();
    if (now.difference(dt).inDays > 0) return '${dt.day}/${dt.month}';
    return '${dt.hour}:${dt.minute.toString().padLeft(2, '0')}';
  }
}
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/chat_provider.dart';
import '../models/product.dart';
import 'chat_detail_screen.dart';
import 'home_screen.dart'; // for products list

class ChatScreen extends StatelessWidget {
  const ChatScreen({super.key});

  @override
  Widget build(BuildContext context) {
    // Get all conversations
    final chatProvider = Provider.of<ChatProvider>(context);
    final conversations = products.where((p) => chatProvider.getMessages(p).isNotEmpty).toList();

    if (conversations.isEmpty) {
      return const Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.chat_bubble_outline, size: 60, color: Colors.grey),
            SizedBox(height: 16),
            Text('No conversations yet', style: TextStyle(color: Colors.grey)),
            SizedBox(height: 8),
            Text('Start a chat from any product page', style: TextStyle(color: Colors.grey)),
          ],
        ),
      );
    }

    return ListView.builder(
      padding: const EdgeInsets.all(8),
      itemCount: conversations.length,
      itemBuilder: (context, index) {
        final product = conversations[index];
        final messages = chatProvider.getMessages(product);
        final lastMessage = messages.isNotEmpty ? messages.last : null;
        return ListTile(
          leading: ClipRRect(
            borderRadius: BorderRadius.circular(8),
            child: Image.network(product.imageUrl, width: 50, height: 50, fit: BoxFit.cover, errorBuilder: (_, __, ___) => Container(color: Colors.grey, width: 50, height: 50)),
          ),
          title: Text(product.name),
          subtitle: lastMessage != null ? Text(lastMessage.text, maxLines: 1, overflow: TextOverflow.ellipsis) : const Text('Tap to start conversation'),
          trailing: lastMessage != null ? Text(_formatTime(lastMessage.timestamp)) : null,
          onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => ChatDetailScreen(product: product))),
        );
      },
    );
  }

  String _formatTime(DateTime time) {
    final now = DateTime.now();
    if (now.difference(time).inDays > 0) {
      return '${time.day}/${time.month}';
    } else {
      return '${time.hour.toString().padLeft(2, '0')}:${time.minute.toString().padLeft(2, '0')}';
    }
  }
}
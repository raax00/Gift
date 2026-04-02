import 'package:flutter/material.dart';
import '../models/message.dart';
import '../models/product.dart';

class ChatProvider extends ChangeNotifier {
  // Map: productId -> List<Message>
  final Map<String, List<Message>> _conversations = {};

  List<Message> getMessages(Product product) {
    return _conversations[product.id] ?? [];
  }

  void sendMessage(Product product, String text) {
    final message = Message(
      id: DateTime.now().millisecondsSinceEpoch.toString(),
      text: text,
      isUser: true,
      timestamp: DateTime.now(),
    );
    _conversations.putIfAbsent(product.id, () => []).add(message);
    notifyListeners();

    // Simulate a reply (for demo)
    Future.delayed(const Duration(seconds: 1), () {
      final reply = Message(
        id: DateTime.now().millisecondsSinceEpoch.toString(),
        text: "Thanks for your interest in ${product.name}. How can I help you?",
        isUser: false,
        timestamp: DateTime.now(),
      );
      _conversations[product.id]?.add(reply);
      notifyListeners();
    });
  }
}
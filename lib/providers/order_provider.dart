import 'package:flutter/material.dart';
import '../models/game_product.dart';

class OrderProvider extends ChangeNotifier {
  List<Map<String, dynamic>> _orders = [];

  List<Map<String, dynamic>> get orders => _orders;

  void placeOrder(GameProduct product, String gameId, String paymentMethod, double total) {
    final order = {
      'id': DateTime.now().millisecondsSinceEpoch.toString(),
      'product': product.name,
      'gameId': gameId,
      'amount': product.amount,
      'price': total,
      'paymentMethod': paymentMethod,
      'date': DateTime.now(),
      'status': 'pending',
    };
    _orders.insert(0, order);
    notifyListeners();
  }
}
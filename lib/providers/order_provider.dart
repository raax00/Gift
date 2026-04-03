import 'package:flutter/material.dart';
import '../models/game_product.dart';

class OrderProvider extends ChangeNotifier {
  List<Map<String, dynamic>> _orders = [];

  List<Map<String, dynamic>> get orders => _orders;

  void placeOrder(GameProduct product, String gameId, String paymentMethod, double total,
      {String? utr, String? screenshotUrl}) {
    final order = {
      'id': DateTime.now().millisecondsSinceEpoch.toString(),
      'product': product.name,
      'gameId': gameId,
      'amount': product.amount,
      'price': total,
      'paymentMethod': paymentMethod,
      'date': DateTime.now(),
      'status': utr != null ? 'confirmed' : 'pending',
      'utr': utr,
      'screenshotUrl': screenshotUrl,
    };
    _orders.insert(0, order);
    notifyListeners();
  }

  void updateOrderStatus(String orderId, String utr, String screenshotUrl) {
    final index = _orders.indexWhere((order) => order['id'] == orderId);
    if (index != -1) {
      _orders[index]['utr'] = utr;
      _orders[index]['screenshotUrl'] = screenshotUrl;
      _orders[index]['status'] = 'confirmed';
      notifyListeners();
    }
  }
}
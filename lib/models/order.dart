import 'cart_item.dart';

class Order {
  final String id;
  final List<CartItem> items;
  final double total;
  final DateTime date;
  final String status; // 'pending', 'confirmed', 'shipped', 'delivered'

  Order({
    required this.id,
    required this.items,
    required this.total,
    required this.date,
    this.status = 'pending',
  });
}
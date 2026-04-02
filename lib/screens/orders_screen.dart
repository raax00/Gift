import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/order_provider.dart';

class OrdersScreen extends StatelessWidget {
  const OrdersScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final orders = Provider.of<OrderProvider>(context).orders;
    return Scaffold(
      appBar: AppBar(title: const Text('My Orders'), centerTitle: true),
      body: orders.isEmpty
          ? const Center(child: Text('No orders yet'))
          : ListView.builder(
              padding: const EdgeInsets.all(12),
              itemCount: orders.length,
              itemBuilder: (ctx, i) {
                final order = orders[i];
                return Card(
                  margin: const EdgeInsets.only(bottom: 12),
                  child: ListTile(
                    title: Text(order['product']),
                    subtitle: Text('Game ID: ${order['gameId']} | ${order['amount']} units'),
                    trailing: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Text('₹${order['price']}', style: const TextStyle(fontWeight: FontWeight.bold, color: Color(0xFF0097A7))),
                        Text(order['status'], style: const TextStyle(fontSize: 12)),
                      ],
                    ),
                  ),
                );
              },
            ),
    );
  }
}
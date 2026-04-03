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
                  child: ExpansionTile(
                    title: Text(order['product']),
                    subtitle: Text('Status: ${order['status']}'),
                    trailing: Text('₹${order['price']}', style: const TextStyle(fontWeight: FontWeight.bold, color: Color(0xFF0097A7))),
                    children: [
                      ListTile(title: Text('Game ID: ${order['gameId']}')),
                      if (order['utr'] != null) ListTile(title: Text('UTR: ${order['utr']}')),
                      if (order['screenshotUrl'] != null)
                        ListTile(
                          title: const Text('Payment Screenshot'),
                          trailing: const Icon(Icons.open_in_new),
                          onTap: () {
                            // Open image in browser or show dialog
                            showDialog(
                              context: context,
                              builder: (_) => Dialog(
                                child: Column(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    Image.network(order['screenshotUrl']),
                                    TextButton(
                                      onPressed: () => Navigator.pop(context),
                                      child: const Text('Close'),
                                    ),
                                  ],
                                ),
                              ),
                            );
                          },
                        ),
                    ],
                  ),
                );
              },
            ),
    );
  }
}
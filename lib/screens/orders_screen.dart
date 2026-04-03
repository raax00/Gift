import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../supabase_config.dart';

class OrdersScreen extends StatefulWidget {
  const OrdersScreen({super.key});

  @override
  State<OrdersScreen> createState() => _OrdersScreenState();
}

class _OrdersScreenState extends State<OrdersScreen> {
  List<Map<String, dynamic>> _orders = [];
  RealtimeChannel? _channel;

  @override
  void initState() {
    super.initState();
    _fetchOrders();
    _subscribeToOrders();
  }

  Future<void> _fetchOrders() async {
    final user = SupabaseConfig.client.auth.currentUser!;
    final response = await SupabaseConfig.client
        .from('orders')
        .select('*, products(name, amount)')
        .eq('user_id', user.id)
        .order('created_at', ascending: false);
    setState(() => _orders = List<Map<String, dynamic>>.from(response));
  }

  void _subscribeToOrders() {
    final user = SupabaseConfig.client.auth.currentUser!;
    _channel = SupabaseConfig.client
        .channel('orders:user_id=eq.$user.id')
        .onPostgresChanges(
          event: PostgresChangeEvent.update,
          schema: 'public',
          table: 'orders',
          callback: (payload) {
            _fetchOrders();
          },
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
      appBar: AppBar(title: const Text('My Orders'), centerTitle: true),
      body: _orders.isEmpty
          ? const Center(child: Text('No orders yet'))
          : ListView.builder(
              padding: const EdgeInsets.all(12),
              itemCount: _orders.length,
              itemBuilder: (ctx, i) {
                final order = _orders[i];
                final product = order['products'];
                return Card(
                  margin: const EdgeInsets.only(bottom: 12),
                  child: ExpansionTile(
                    title: Text(product['name']),
                    subtitle: Text('Status: ${order['status']}'),
                    trailing: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Text('₹${order['price']}', style: const TextStyle(fontWeight: FontWeight.bold, color: Color(0xFF0097A7))),
                        _buildStatusChip(order['status']),
                      ],
                    ),
                    children: [
                      ListTile(title: Text('Game ID: ${order['game_id']}')),
                      ListTile(title: Text('UTR: ${order['utr'] ?? 'N/A'}')),
                      if (order['screenshot_url'] != null)
                        ListTile(
                          title: const Text('Screenshot'),
                          trailing: const Icon(Icons.open_in_new),
                          onTap: () => showDialog(
                            context: context,
                            builder: (_) => Dialog(child: Image.network(order['screenshot_url'])),
                          ),
                        ),
                      const Divider(),
                      Padding(
                        padding: const EdgeInsets.all(12),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text('Tracking', style: TextStyle(fontWeight: FontWeight.bold)),
                            const SizedBox(height: 8),
                            LinearProgressIndicator(
                              value: _getProgress(order['status']),
                              backgroundColor: Colors.grey.shade300,
                              color: const Color(0xFF0097A7),
                            ),
                            const SizedBox(height: 8),
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: const [
                                Text('Pending'),
                                Text('Confirmed'),
                                Text('Processing'),
                                Text('Delivered'),
                              ],
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                );
              },
            ),
    );
  }

  double _getProgress(String status) {
    switch (status) {
      case 'pending': return 0.0;
      case 'confirmed': return 0.33;
      case 'processing': return 0.66;
      case 'delivered': return 1.0;
      default: return 0.0;
    }
  }

  Widget _buildStatusChip(String status) {
    Color color;
    switch (status) {
      case 'pending': color = Colors.orange; break;
      case 'confirmed': color = Colors.blue; break;
      case 'processing': color = Colors.purple; break;
      case 'delivered': color = Colors.green; break;
      default: color = Colors.grey;
    }
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
      decoration: BoxDecoration(color: color.withOpacity(0.2), borderRadius: BorderRadius.circular(12)),
      child: Text(status, style: TextStyle(color: color, fontSize: 12)),
    );
  }
}
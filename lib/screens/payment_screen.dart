import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/cart_provider.dart';
import 'home_screen.dart';

class PaymentScreen extends StatefulWidget {
  const PaymentScreen({super.key});

  @override
  State<PaymentScreen> createState() => _PaymentScreenState();
}

class _PaymentScreenState extends State<PaymentScreen> {
  bool _isProcessing = false;

  @override
  Widget build(BuildContext context) {
    final cart = Provider.of<CartProvider>(context);
    return Scaffold(
      appBar: AppBar(title: const Text('Payment'), centerTitle: true),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            Expanded(
              child: ListView(
                children: [
                  Card(
                    child: Padding(
                      padding: const EdgeInsets.all(16),
                      child: Column(
                        children: [
                          const Text('Total Amount', style: TextStyle(fontSize: 16)),
                          const SizedBox(height: 8),
                          Text('₹ ${cart.totalPrice}', style: const TextStyle(fontSize: 32, fontWeight: FontWeight.bold, color: Color(0xFF0097A7))),
                          const Divider(height: 32),
                          const Text('Select Payment Method', style: TextStyle(fontWeight: FontWeight.bold)),
                          const SizedBox(height: 12),
                          RadioListTile(
                            title: const Text('Credit Card'),
                            value: 'card',
                            groupValue: 'card',
                            onChanged: (value) {},
                            secondary: const Icon(Icons.credit_card),
                          ),
                          RadioListTile(
                            title: const Text('UPI'),
                            value: 'upi',
                            groupValue: 'upi',
                            onChanged: (value) {},
                            secondary: const Icon(Icons.qr_code),
                          ),
                          RadioListTile(
                            title: const Text('Net Banking'),
                            value: 'netbanking',
                            groupValue: 'netbanking',
                            onChanged: (value) {},
                            secondary: const Icon(Icons.account_balance),
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),
            SizedBox(
              width: double.infinity,
              height: 50,
              child: ElevatedButton(
                onPressed: _isProcessing ? null : () async {
                  setState(() => _isProcessing = true);
                  await Future.delayed(const Duration(seconds: 2)); // simulate payment
                  cart.clearCart();
                  if (mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Payment Successful! Order Placed.')));
                    Navigator.pushAndRemoveUntil(context, MaterialPageRoute(builder: (_) => const HomeScreen()), (route) => false);
                  }
                },
                style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFF0097A7), foregroundColor: Colors.white, shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12))),
                child: _isProcessing ? const CircularProgressIndicator(color: Colors.white) : const Text('Pay Now'),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
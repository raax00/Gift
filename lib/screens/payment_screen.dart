import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:qr_flutter/qr_flutter.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:provider/provider.dart';
import '../models/game_product.dart';
import '../providers/order_provider.dart';

class PaymentScreen extends StatefulWidget {
  final GameProduct product;
  final String gameId;
  const PaymentScreen({super.key, required this.product, required this.gameId});

  @override
  State<PaymentScreen> createState() => _PaymentScreenState();
}

class _PaymentScreenState extends State<PaymentScreen> {
  String _selectedMethod = 'upi'; // 'upi' or 'wallet'
  final String upiId = 'paynearby.8406962570@indus';
  final String upiName = 'Dream Store';
  final double amount = 0; // will be set from product

  @override
  void initState() {
    super.initState();
  }

  Future<void> _payWithUPI() async {
    final uri = Uri.parse(
        'upi://pay?pa=$upiId&pn=$upiName&am=${widget.product.price}&cu=INR&tn=Payment for ${widget.product.name}');
    if (await canLaunchUrl(uri)) {
      await launchUrl(uri, mode: LaunchMode.externalApplication);
      // After returning, simulate order placement
      _confirmOrder('UPI');
    } else {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('No UPI app found. Please scan QR code.')));
    }
  }

  void _confirmOrder(String method) {
    Provider.of<OrderProvider>(context, listen: false).placeOrder(
      widget.product,
      widget.gameId,
      method,
      widget.product.price.toDouble(),
    );
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: const Text('Order Placed!'),
        content: Text('Your ${widget.product.name} will be delivered to ID ${widget.gameId} shortly.'),
        actions: [
          TextButton(
            onPressed: () {
              Navigator.pop(ctx);
              Navigator.popUntil(context, (route) => route.isFirst);
            },
            child: const Text('OK'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Payment'), centerTitle: true),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        const Text('Product:', style: TextStyle(fontWeight: FontWeight.bold)),
                        Text(widget.product.name),
                      ],
                    ),
                    const SizedBox(height: 8),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        const Text('Game ID:', style: TextStyle(fontWeight: FontWeight.bold)),
                        Text(widget.gameId),
                      ],
                    ),
                    const Divider(height: 24),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        const Text('Total Amount:', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                        Text('₹${widget.product.price}', style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: Color(0xFF0097A7))),
                      ],
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 24),
            const Text('Choose Payment Method', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
            const SizedBox(height: 12),
            Row(
              children: [
                Expanded(
                  child: ChoiceChip(
                    label: const Text('UPI'),
                    selected: _selectedMethod == 'upi',
                    onSelected: (s) => setState(() => _selectedMethod = 'upi'),
                    selectedColor: const Color(0xFF0097A7),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: ChoiceChip(
                    label: const Text('Wallet'),
                    selected: _selectedMethod == 'wallet',
                    onSelected: (s) => setState(() => _selectedMethod = 'wallet'),
                    selectedColor: const Color(0xFF0097A7),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 24),
            if (_selectedMethod == 'upi') ...[
              const Text('Scan QR Code with any UPI App', style: TextStyle(fontWeight: FontWeight.bold)),
              const SizedBox(height: 16),
              Center(
                child: Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(16)),
                  child: QrImageView(
                    data: 'upi://pay?pa=$upiId&pn=$upiName&am=${widget.product.price}&cu=INR',
                    version: QrVersions.auto,
                    size: 200,
                  ),
                ),
              ),
              const SizedBox(height: 16),
              Center(
                child: Text('UPI ID: $upiId', style: const TextStyle(fontSize: 14)),
              ),
              const SizedBox(height: 16),
              SizedBox(
                width: double.infinity,
                height: 50,
                child: ElevatedButton.icon(
                  onPressed: _payWithUPI,
                  icon: const Icon(Icons.qr_code_scanner),
                  label: const Text('Pay with UPI App'),
                  style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFF0097A7), shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12))),
                ),
              ),
            ] else ...[
              // Wallet placeholder (demo)
              Card(
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    children: [
                      const Text('Wallet Balance: ₹0', style: TextStyle(fontSize: 16)),
                      const SizedBox(height: 12),
                      ElevatedButton(
                        onPressed: () {
                          ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Add money to wallet feature coming soon')));
                        },
                        child: const Text('Add Money'),
                      ),
                    ],
                  ),
                ),
              ),
            ],
            const Spacer(),
            if (_selectedMethod == 'wallet')
              SizedBox(
                width: double.infinity,
                height: 50,
                child: ElevatedButton(
                  onPressed: () {
                    ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Insufficient balance. Please add money.')));
                  },
                  style: ElevatedButton.styleFrom(backgroundColor: Colors.grey),
                  child: const Text('Pay with Wallet'),
                ),
              ),
          ],
        ),
      ),
    );
  }
}
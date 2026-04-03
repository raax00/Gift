import 'dart:io';
import 'package:flutter/material.dart';
import 'package:qr_flutter/qr_flutter.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:provider/provider.dart';
import '../models/game_product.dart';
import '../providers/order_provider.dart';
import '../providers/wallet_provider.dart';
import 'utr_confirmation_screen.dart';

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
  bool _isProcessing = false;

  Future<void> _payWithUPI() async {
    final uri = Uri.parse(
        'upi://pay?pa=$upiId&pn=$upiName&am=${widget.product.price}&cu=INR&tn=Payment for ${widget.product.name}');
    if (await canLaunchUrl(uri)) {
      await launchUrl(uri, mode: LaunchMode.externalApplication);
      // After returning from UPI app, ask for UTR & screenshot
      if (mounted) {
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(
            builder: (_) => UtrConfirmationScreen(
              product: widget.product,
              gameId: widget.gameId,
              amount: widget.product.price.toDouble(),
              paymentMethod: 'UPI',
            ),
          ),
        );
      }
    } else {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('No UPI app found. Please scan QR code.')));
    }
  }

  Future<void> _payWithWallet() async {
    final wallet = Provider.of<WalletProvider>(context, listen: false);
    final success = await wallet.deductMoney(widget.product.price.toDouble());
    if (success) {
      // Order placed directly (no UTR needed for wallet)
      Provider.of<OrderProvider>(context, listen: false).placeOrder(
        widget.product,
        widget.gameId,
        'Wallet',
        widget.product.price.toDouble(),
      );
      showDialog(
        context: context,
        barrierDismissible: false,
        builder: (ctx) => AlertDialog(
          title: const Text('Payment Successful'),
          content: Text('${widget.product.name} purchased using wallet.'),
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
    } else {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Insufficient wallet balance. Please add money.')));
      _showAddMoneyDialog();
    }
  }

  void _showAddMoneyDialog() {
    final amountController = TextEditingController();
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Add Money to Wallet'),
        content: TextField(
          controller: amountController,
          keyboardType: TextInputType.number,
          decoration: const InputDecoration(hintText: 'Enter amount (₹)'),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Cancel')),
          TextButton(
            onPressed: () async {
              final amount = double.tryParse(amountController.text) ?? 0;
              if (amount > 0) {
                await Provider.of<WalletProvider>(context, listen: false).addMoney(amount);
                Navigator.pop(ctx);
                ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('₹$amount added to wallet')));
              }
            },
            child: const Text('Add'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final walletBalance = Provider.of<WalletProvider>(context).balance;
    return Scaffold(
      appBar: AppBar(title: const Text('Payment'), centerTitle: true),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  children: [
                    Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
                      const Text('Product:', style: TextStyle(fontWeight: FontWeight.bold)),
                      Text(widget.product.name),
                    ]),
                    const SizedBox(height: 8),
                    Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
                      const Text('Game ID:', style: TextStyle(fontWeight: FontWeight.bold)),
                      Text(widget.gameId),
                    ]),
                    const Divider(height: 24),
                    Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
                      const Text('Total Amount:', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                      Text('₹${widget.product.price}', style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: Color(0xFF0097A7))),
                    ]),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 24),
            const Text('Choose Payment Method', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
            const SizedBox(height: 12),
            Row(children: [
              Expanded(child: ChoiceChip(label: const Text('UPI'), selected: _selectedMethod == 'upi', onSelected: (s) => setState(() => _selectedMethod = 'upi'), selectedColor: const Color(0xFF0097A7))),
              const SizedBox(width: 12),
              Expanded(child: ChoiceChip(label: const Text('Wallet'), selected: _selectedMethod == 'wallet', onSelected: (s) => setState(() => _selectedMethod = 'wallet'), selectedColor: const Color(0xFF0097A7))),
            ]),
            if (_selectedMethod == 'wallet') ...[
              const SizedBox(height: 12),
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(color: Colors.grey.shade100, borderRadius: BorderRadius.circular(12)),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Text('Wallet Balance:', style: TextStyle(fontWeight: FontWeight.bold)),
                    Text('₹$walletBalance', style: const TextStyle(color: Color(0xFF0097A7), fontWeight: FontWeight.bold)),
                  ],
                ),
              ),
              const SizedBox(height: 12),
              SizedBox(
                width: double.infinity,
                child: OutlinedButton(
                  onPressed: _showAddMoneyDialog,
                  child: const Text('Add Money to Wallet'),
                ),
              ),
            ],
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
              Center(child: Text('UPI ID: $upiId', style: const TextStyle(fontSize: 14))),
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
            ],
            if (_selectedMethod == 'wallet')
              const SizedBox(height: 16),
            if (_selectedMethod == 'wallet')
              SizedBox(
                width: double.infinity,
                height: 50,
                child: ElevatedButton(
                  onPressed: _payWithWallet,
                  style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFF0097A7), shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12))),
                  child: const Text('Pay with Wallet'),
                ),
              ),
          ],
        ),
      ),
    );
  }
}
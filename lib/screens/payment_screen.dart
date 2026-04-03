import 'dart:io';
import 'package:flutter/material.dart';
import 'package:qr_flutter/qr_flutter.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:image_picker/image_picker.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:provider/provider.dart';
import '../models/game_product.dart';
import '../supabase_config.dart';
import '../providers/wallet_provider.dart';

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

  // UPI payment flow (UTR + screenshot)
  final TextEditingController _utrController = TextEditingController();
  File? _screenshot;
  bool _isProcessing = false;
  final ImagePicker _picker = ImagePicker();

  @override
  void dispose() {
    _utrController.dispose();
    super.dispose();
  }

  // ==================== UPI FLOW ====================
  Future<void> _payWithUPI() async {
    final uri = Uri.parse(
        'upi://pay?pa=$upiId&pn=$upiName&am=${widget.product.price}&cu=INR&tn=Payment for ${widget.product.name}');
    if (await canLaunchUrl(uri)) {
      await launchUrl(uri, mode: LaunchMode.externalApplication);
      // After returning from UPI app, ask for UTR & screenshot
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Please enter UTR and upload screenshot to confirm payment')),
        );
      }
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('No UPI app found. Please scan QR code and pay manually.')),
      );
    }
  }

  Future<void> _pickScreenshot() async {
    final XFile? image = await _picker.pickImage(source: ImageSource.gallery);
    if (image != null) setState(() => _screenshot = File(image.path));
  }

  Future<void> _submitUpiConfirmation() async {
    final utr = _utrController.text.trim();
    if (utr.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Please enter UTR number')));
      return;
    }
    if (_screenshot == null) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Please upload payment screenshot')));
      return;
    }

    setState(() => _isProcessing = true);

    try {
      // Upload screenshot to Supabase Storage
      final fileExt = _screenshot!.path.split('.').last;
      final fileName = '${DateTime.now().millisecondsSinceEpoch}.$fileExt';
      final fileBytes = await _screenshot!.readAsBytes();
      await SupabaseConfig.client.storage
          .from('payment_screenshots')
          .uploadBinary(fileName, fileBytes);
      final screenshotUrl = SupabaseConfig.client.storage
          .from('payment_screenshots')
          .getPublicUrl(fileName);

      final user = SupabaseConfig.client.auth.currentUser!;
      await SupabaseConfig.client.from('orders').insert({
        'user_id': user.id,
        'product_id': widget.product.id,
        'game_id': widget.gameId,
        'amount': widget.product.amount,
        'price': widget.product.price,
        'payment_method': 'UPI',
        'utr': utr,
        'screenshot_url': screenshotUrl,
        'status': 'pending', // admin will confirm
      });

      if (mounted) {
        showDialog(
          context: context,
          barrierDismissible: false,
          builder: (ctx) => AlertDialog(
            title: const Text('Payment Submitted'),
            content: const Text('Your UTR and screenshot have been submitted. Admin will verify and complete your order shortly.'),
            actions: [
              TextButton(
                onPressed: () => Navigator.popUntil(ctx, (route) => route.isFirst),
                child: const Text('OK'),
              ),
            ],
          ),
        );
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Error: $e')));
    } finally {
      if (mounted) setState(() => _isProcessing = false);
    }
  }

  // ==================== WALLET FLOW ====================
  Future<void> _payWithWallet() async {
    final wallet = Provider.of<WalletProvider>(context, listen: false);
    final balance = wallet.balance;
    if (balance >= widget.product.price) {
      setState(() => _isProcessing = true);
      // Deduct immediately (admin can adjust later if needed)
      await wallet.deductMoney(widget.product.price.toDouble());
      final user = SupabaseConfig.client.auth.currentUser!;
      await SupabaseConfig.client.from('orders').insert({
        'user_id': user.id,
        'product_id': widget.product.id,
        'game_id': widget.gameId,
        'amount': widget.product.amount,
        'price': widget.product.price,
        'payment_method': 'Wallet',
        'utr': null,
        'screenshot_url': null,
        'status': 'confirmed', // wallet payment is instant
      });
      setState(() => _isProcessing = false);
      if (mounted) {
        showDialog(
          context: context,
          barrierDismissible: false,
          builder: (ctx) => AlertDialog(
            title: const Text('Payment Successful'),
            content: Text('₹${widget.product.price} deducted from wallet. Your order is confirmed.'),
            actions: [
              TextButton(
                onPressed: () => Navigator.popUntil(ctx, (route) => route.isFirst),
                child: const Text('OK'),
              ),
            ],
          ),
        );
      }
    } else {
      _showAddMoneyDialog();
    }
  }

  void _showAddMoneyDialog() {
    final amountController = TextEditingController();
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Insufficient Balance'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text('Your wallet balance is low. Add money to continue.'),
            const SizedBox(height: 12),
            TextField(
              controller: amountController,
              keyboardType: TextInputType.number,
              decoration: const InputDecoration(hintText: 'Amount (₹)', border: OutlineInputBorder()),
            ),
          ],
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
                // Retry payment
                _payWithWallet();
              }
            },
            child: const Text('Add Money'),
          ),
        ],
      ),
    );
  }

  // ==================== UI ====================
  @override
  Widget build(BuildContext context) {
    final walletBalance = Provider.of<WalletProvider>(context).balance;
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Payment Gateway'),
        centerTitle: true,
        backgroundColor: const Color(0xFF0097A7),
        foregroundColor: Colors.white,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Order summary card
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  children: [
                    _infoRow('Product', widget.product.name),
                    const SizedBox(height: 8),
                    _infoRow('Game ID', widget.gameId),
                    const Divider(height: 24),
                    _infoRow('Total Amount', '₹${widget.product.price}', isTotal: true),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 24),

            // Payment method selector
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
                    backgroundColor: isDark ? Colors.grey.shade800 : Colors.grey.shade200,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: ChoiceChip(
                    label: const Text('Wallet'),
                    selected: _selectedMethod == 'wallet',
                    onSelected: (s) => setState(() => _selectedMethod = 'wallet'),
                    selectedColor: const Color(0xFF0097A7),
                    backgroundColor: isDark ? Colors.grey.shade800 : Colors.grey.shade200,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 24),

            // Payment method specific UI
            if (_selectedMethod == 'upi') ...[
              // QR Code
              const Text('Scan QR Code with any UPI App', style: TextStyle(fontWeight: FontWeight.bold)),
              const SizedBox(height: 12),
              Center(
                child: Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(16),
                    boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.1), blurRadius: 8)],
                  ),
                  child: QrImageView(
                    data: 'upi://pay?pa=$upiId&pn=$upiName&am=${widget.product.price}&cu=INR',
                    version: QrVersions.auto,
                    size: 200,
                  ),
                ),
              ),
              const SizedBox(height: 12),
              Center(child: Text('UPI ID: $upiId', style: const TextStyle(fontSize: 14))),
              const SizedBox(height: 16),

              // Pay with UPI App button
              SizedBox(
                width: double.infinity,
                height: 50,
                child: ElevatedButton.icon(
                  onPressed: _payWithUPI,
                  icon: const Icon(Icons.qr_code_scanner),
                  label: const Text('Pay with UPI App'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF0097A7),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  ),
                ),
              ),
              const SizedBox(height: 24),

              // UTR + Screenshot (only after payment)
              const Divider(),
              const SizedBox(height: 16),
              const Text('After Payment, Confirm with UTR & Screenshot', style: TextStyle(fontWeight: FontWeight.bold)),
              const SizedBox(height: 12),
              TextField(
                controller: _utrController,
                decoration: InputDecoration(
                  hintText: 'Enter UTR number',
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                ),
              ),
              const SizedBox(height: 12),
              GestureDetector(
                onTap: _pickScreenshot,
                child: Container(
                  height: 120,
                  width: double.infinity,
                  decoration: BoxDecoration(
                    border: Border.all(color: Colors.grey.shade300),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: _screenshot == null
                      ? const Center(
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [Icon(Icons.cloud_upload), Text('Tap to upload screenshot')],
                          ),
                        )
                      : ClipRRect(
                          borderRadius: BorderRadius.circular(12),
                          child: Image.file(_screenshot!, fit: BoxFit.cover),
                        ),
                ),
              ),
              const SizedBox(height: 16),
              SizedBox(
                width: double.infinity,
                height: 50,
                child: ElevatedButton(
                  onPressed: _isProcessing ? null : _submitUpiConfirmation,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.green,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  ),
                  child: _isProcessing
                      ? const CircularProgressIndicator(color: Colors.white)
                      : const Text('Submit UTR & Screenshot'),
                ),
              ),
            ] else ...[
              // Wallet UI
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: isDark ? Colors.grey.shade800 : Colors.grey.shade100,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Text('Wallet Balance', style: TextStyle(fontWeight: FontWeight.bold)),
                    Text('₹$walletBalance', style: const TextStyle(color: Color(0xFF0097A7), fontWeight: FontWeight.bold)),
                  ],
                ),
              ),
              const SizedBox(height: 16),
              SizedBox(
                width: double.infinity,
                height: 50,
                child: ElevatedButton(
                  onPressed: _isProcessing ? null : _payWithWallet,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF0097A7),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  ),
                  child: _isProcessing
                      ? const CircularProgressIndicator(color: Colors.white)
                      : const Text('Pay with Wallet'),
                ),
              ),
              const SizedBox(height: 12),
              Center(
                child: TextButton(
                  onPressed: _showAddMoneyDialog,
                  child: const Text('Add Money to Wallet', style: TextStyle(color: Colors.orange)),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _infoRow(String label, String value, {bool isTotal = false}) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(label, style: TextStyle(fontWeight: isTotal ? FontWeight.bold : FontWeight.normal)),
        Text(
          value,
          style: TextStyle(
            fontSize: isTotal ? 18 : 16,
            fontWeight: isTotal ? FontWeight.bold : FontWeight.normal,
            color: isTotal ? const Color(0xFF0097A7) : null,
          ),
        ),
      ],
    );
  }
}
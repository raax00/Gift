import 'dart:io';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../models/game_product.dart';
import '../supabase_config.dart';

class PaymentScreen extends StatefulWidget {
  final GameProduct product;
  final String gameId;
  const PaymentScreen({super.key, required this.product, required this.gameId});

  @override
  State<PaymentScreen> createState() => _PaymentScreenState();
}

class _PaymentScreenState extends State<PaymentScreen> {
  final TextEditingController _utrController = TextEditingController();
  File? _screenshot;
  bool _isUploading = false;
  final ImagePicker _picker = ImagePicker();

  Future<void> _pickScreenshot() async {
    final XFile? image = await _picker.pickImage(source: ImageSource.gallery);
    if (image != null) setState(() => _screenshot = File(image.path));
  }

  Future<void> _confirmOrder() async {
    if (_utrController.text.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Please enter UTR number')));
      return;
    }
    if (_screenshot == null) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Please upload payment screenshot')));
      return;
    }
    setState(() => _isUploading = true);

    final fileExt = _screenshot!.path.split('.').last;
    final fileName = '${DateTime.now().millisecondsSinceEpoch}.$fileExt';
    final fileBytes = await _screenshot!.readAsBytes();
    await SupabaseConfig.client.storage.from('payment_screenshots').uploadBinary(fileName, fileBytes);
    final screenshotUrl = SupabaseConfig.client.storage.from('payment_screenshots').getPublicUrl(fileName);

    final user = SupabaseConfig.client.auth.currentUser!;
    await SupabaseConfig.client.from('orders').insert({
      'user_id': user.id,
      'product_id': widget.product.id,
      'game_id': widget.gameId,
      'amount': widget.product.amount,
      'price': widget.product.price,
      'payment_method': 'UPI',
      'utr': _utrController.text.trim(),
      'screenshot_url': screenshotUrl,
      'status': 'pending',
    });

    setState(() => _isUploading = false);
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (ctx) => AlertDialog(
        title: const Text('Order Placed'),
        content: const Text('Your order is pending admin confirmation. You will receive the items shortly.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.popUntil(context, (route) => route.isFirst),
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
            const Text('UTR Number', style: TextStyle(fontWeight: FontWeight.bold)),
            const SizedBox(height: 8),
            TextField(controller: _utrController, decoration: InputDecoration(hintText: 'Enter UTR from bank/UPI app', border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)))),
            const SizedBox(height: 16),
            const Text('Payment Screenshot', style: TextStyle(fontWeight: FontWeight.bold)),
            const SizedBox(height: 8),
            GestureDetector(
              onTap: _pickScreenshot,
              child: Container(
                height: 150,
                width: double.infinity,
                decoration: BoxDecoration(border: Border.all(color: Colors.grey.shade300), borderRadius: BorderRadius.circular(12)),
                child: _screenshot == null
                    ? const Center(child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [Icon(Icons.cloud_upload), Text('Tap to upload screenshot')]))
                    : ClipRRect(borderRadius: BorderRadius.circular(12), child: Image.file(_screenshot!, fit: BoxFit.cover)),
              ),
            ),
            const SizedBox(height: 24),
            SizedBox(
              width: double.infinity,
              height: 50,
              child: ElevatedButton(
                onPressed: _isUploading ? null : _confirmOrder,
                style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFF0097A7), shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12))),
                child: _isUploading ? const CircularProgressIndicator(color: Colors.white) : const Text('Confirm Payment'),
              ),
            ),
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
        Text(value, style: TextStyle(fontSize: isTotal ? 18 : 16, fontWeight: isTotal ? FontWeight.bold : FontWeight.normal, color: isTotal ? const Color(0xFF0097A7) : null)),
      ],
    );
  }
}
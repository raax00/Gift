import 'dart:io';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:provider/provider.dart';
import '../services/cloudinary_service.dart';
import '../providers/order_provider.dart';
import '../models/game_product.dart';

class UtrConfirmationScreen extends StatefulWidget {
  final GameProduct product;
  final String gameId;
  final double amount;
  final String paymentMethod;

  const UtrConfirmationScreen({
    super.key,
    required this.product,
    required this.gameId,
    required this.amount,
    required this.paymentMethod,
  });

  @override
  State<UtrConfirmationScreen> createState() => _UtrConfirmationScreenState();
}

class _UtrConfirmationScreenState extends State<UtrConfirmationScreen> {
  final TextEditingController _utrController = TextEditingController();
  File? _screenshot;
  bool _isUploading = false;
  final ImagePicker _picker = ImagePicker();

  Future<void> _pickScreenshot() async {
    final XFile? image = await _picker.pickImage(source: ImageSource.gallery);
    if (image != null) {
      setState(() => _screenshot = File(image.path));
    }
  }

  Future<void> _submitConfirmation() async {
    if (_utrController.text.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Please enter UTR number')));
      return;
    }
    if (_screenshot == null) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Please upload payment screenshot')));
      return;
    }

    setState(() => _isUploading = true);

    // Upload screenshot to Cloudinary
    final screenshotUrl = await CloudinaryService.uploadImage(_screenshot!);
    if (screenshotUrl == null) {
      setState(() => _isUploading = false);
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Failed to upload screenshot. Try again.')));
      return;
    }

    // Save order with UTR and screenshot
    final orderProvider = Provider.of<OrderProvider>(context, listen: false);
    orderProvider.placeOrder(
      widget.product,
      widget.gameId,
      widget.paymentMethod,
      widget.amount,
      utr: _utrController.text.trim(),
      screenshotUrl: screenshotUrl,
    );

    setState(() => _isUploading = false);

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (ctx) => AlertDialog(
        title: const Text('Payment Confirmed'),
        content: const Text('Your order has been confirmed. You will receive the items shortly.'),
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
      appBar: AppBar(title: const Text('Payment Confirmation'), centerTitle: true),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
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
                    const SizedBox(height: 8),
                    _infoRow('Amount', '₹${widget.amount}'),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 24),
            const Text('UTR Number (Unique Transaction Reference)', style: TextStyle(fontWeight: FontWeight.bold)),
            const SizedBox(height: 8),
            TextField(
              controller: _utrController,
              decoration: InputDecoration(
                hintText: 'Enter UTR from your bank/UPI app',
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
              ),
            ),
            const SizedBox(height: 24),
            const Text('Upload Payment Screenshot', style: TextStyle(fontWeight: FontWeight.bold)),
            const SizedBox(height: 8),
            GestureDetector(
              onTap: _pickScreenshot,
              child: Container(
                height: 150,
                width: double.infinity,
                decoration: BoxDecoration(
                  border: Border.all(color: Colors.grey.shade300),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: _screenshot == null
                    ? Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(Icons.cloud_upload, size: 40, color: Colors.grey.shade600),
                          const SizedBox(height: 8),
                          Text('Tap to upload screenshot', style: TextStyle(color: Colors.grey.shade600)),
                        ],
                      )
                    : ClipRRect(
                        borderRadius: BorderRadius.circular(12),
                        child: Image.file(_screenshot!, fit: BoxFit.cover, width: double.infinity),
                      ),
              ),
            ),
            const SizedBox(height: 32),
            SizedBox(
              width: double.infinity,
              height: 50,
              child: ElevatedButton(
                onPressed: _isUploading ? null : _submitConfirmation,
                style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFF0097A7), shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12))),
                child: _isUploading ? const CircularProgressIndicator(color: Colors.white) : const Text('Confirm Payment'),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _infoRow(String label, String value) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(label, style: const TextStyle(fontWeight: FontWeight.bold)),
        Text(value),
      ],
    );
  }
}
import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:image_picker/image_picker.dart';
import '../models/game_product.dart';
import '../supabase_config.dart';
import '../providers/wallet_provider.dart';
import 'package:provider/provider.dart';

class PaymentScreen extends StatefulWidget {
  final GameProduct product;
  final String gameId;
  const PaymentScreen({super.key, required this.product, required this.gameId});

  @override
  State<PaymentScreen> createState() => _PaymentScreenState();
}

class _PaymentScreenState extends State<PaymentScreen> {
  String _promoCode = '';
  double _discount = 0;
  double _finalPrice = 0;
  bool _applyingPromo = false;
  String _promoMessage = '';

  final TextEditingController _utrController = TextEditingController();
  File? _screenshot;
  bool _isUploading = false;
  final ImagePicker _picker = ImagePicker();

  @override
  void initState() {
    super.initState();
    _finalPrice = widget.product.price.toDouble();
  }

  Future<void> _applyPromo() async {
    if (_promoCode.isEmpty) return;
    setState(() => _applyingPromo = true);
    final response = await SupabaseConfig.client
        .from('promo_codes')
        .select()
        .eq('code', _promoCode)
        .eq('is_active', true)
        .maybeSingle();
    if (response == null) {
      _promoMessage = 'Invalid or expired promo code';
    } else {
      final expiry = DateTime.parse(response['expires_at']);
      if (expiry.isBefore(DateTime.now())) {
        _promoMessage = 'Promo code expired';
      } else {
        double discount = 0;
        if (response['discount_type'] == 'percentage') {
          discount = _finalPrice * (response['discount_value'] / 100);
          if (response['max_discount'] != null && discount > response['max_discount']) {
            discount = response['max_discount'].toDouble();
          }
        } else {
          discount = response['discount_value'].toDouble();
        }
        if (discount > _finalPrice) discount = _finalPrice;
        _discount = discount;
        _finalPrice = _finalPrice - discount;
        _promoMessage = 'Promo applied! You saved ₹${discount.toStringAsFixed(2)}';
      }
    }
    setState(() => _applyingPromo = false);
  }

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

    // Upload to Supabase Storage
    final fileExt = _screenshot!.path.split('.').last;
    final fileName = '${DateTime.now().millisecondsSinceEpoch}.$fileExt';
    final fileBytes = await _screenshot!.readAsBytes();
    await SupabaseConfig.client.storage.from('payment_screenshots').uploadBinary(fileName, fileBytes);
    final screenshotUrl = SupabaseConfig.client.storage.from('payment_screenshots').getPublicUrl(fileName);

    // Save order to Supabase
    final user = SupabaseConfig.client.auth.currentUser!;
    await SupabaseConfig.client.from('orders').insert({
      'user_id': user.id,
      'product_id': widget.product.id,
      'game_id': widget.gameId,
      'amount': widget.product.amount,
      'price': _finalPrice,
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
    final wallet = Provider.of<WalletProvider>(context);
    return Scaffold(
      appBar: AppBar(title: const Text('Payment Gateway'), centerTitle: true),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // PayU-style header
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(color: const Color(0xFF0097A7), borderRadius: BorderRadius.circular(12)),
              child: Column(
                children: [
                  const Text('Pay Using', style: TextStyle(color: Colors.white, fontSize: 18)),
                  const SizedBox(height: 8),
                  Text('₹${_finalPrice.toStringAsFixed(2)}', style: const TextStyle(color: Colors.white, fontSize: 32, fontWeight: FontWeight.bold)),
                  const SizedBox(height: 8),
                  Text('Order ID: ${DateTime.now().millisecondsSinceEpoch}', style: const TextStyle(color: Colors.white70)),
                ],
              ),
            ),
            const SizedBox(height: 20),
            // Promo code
            Card(
              child: Padding(
                padding: const EdgeInsets.all(12),
                child: Column(
                  children: [
                    Row(
                      children: [
                        Expanded(
                          child: TextField(
                            onChanged: (v) => _promoCode = v,
                            decoration: const InputDecoration(hintText: 'Promo Code', border: OutlineInputBorder()),
                          ),
                        ),
                        const SizedBox(width: 8),
                        ElevatedButton(
                          onPressed: _applyingPromo ? null : _applyPromo,
                          style: ElevatedButton.styleFrom(backgroundColor: Colors.orange),
                          child: const Text('Apply'),
                        ),
                      ],
                    ),
                    if (_promoMessage.isNotEmpty)
                      Padding(
                        padding: const EdgeInsets.only(top: 8),
                        child: Text(_promoMessage, style: TextStyle(color: _discount > 0 ? Colors.green : Colors.red)),
                      ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 16),
            // Order summary
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  children: [
                    _summaryRow('Product', widget.product.name),
                    _summaryRow('Game ID', widget.gameId),
                    _summaryRow('Amount', widget.product.amount.toString()),
                    const Divider(),
                    _summaryRow('Subtotal', '₹${widget.product.price}'),
                    if (_discount > 0) _summaryRow('Discount', '-₹${_discount.toStringAsFixed(2)}', isDiscount: true),
                    const Divider(),
                    _summaryRow('Total', '₹${_finalPrice.toStringAsFixed(2)}', isTotal: true),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 16),
            // UTR & screenshot (for UPI)
            const Text('UTR Number', style: TextStyle(fontWeight: FontWeight.bold)),
            TextField(controller: _utrController, decoration: const InputDecoration(hintText: 'Enter UTR from bank/UPI app')),
            const SizedBox(height: 12),
            const Text('Payment Screenshot', style: TextStyle(fontWeight: FontWeight.bold)),
            GestureDetector(
              onTap: _pickScreenshot,
              child: Container(
                height: 120,
                width: double.infinity,
                decoration: BoxDecoration(border: Border.all(color: Colors.grey.shade300), borderRadius: BorderRadius.circular(12)),
                child: _screenshot == null
                    ? const Center(child: Text('Tap to upload screenshot'))
                    : ClipRRect(borderRadius: BorderRadius.circular(12), child: Image.file(_screenshot!, fit: BoxFit.cover)),
              ),
            ),
            const SizedBox(height: 24),
            SizedBox(
              width: double.infinity,
              height: 50,
              child: ElevatedButton(
                onPressed: _isUploading ? null : _confirmOrder,
                style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFF0097A7)),
                child: _isUploading ? const CircularProgressIndicator(color: Colors.white) : const Text('Confirm & Pay'),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _summaryRow(String label, String value, {bool isDiscount = false, bool isTotal = false}) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label, style: TextStyle(fontWeight: isTotal ? FontWeight.bold : FontWeight.normal)),
          Text(value, style: TextStyle(color: isDiscount ? Colors.green : (isTotal ? const Color(0xFF0097A7) : null), fontWeight: isTotal ? FontWeight.bold : null)),
        ],
      ),
    );
  }
}
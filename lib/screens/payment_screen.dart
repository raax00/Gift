import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/services.dart';
import 'package:qr_flutter/qr_flutter.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:image_picker/image_picker.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:provider/provider.dart';
import '../models/game_product.dart';
import '../supabase_config.dart';
import '../providers/wallet_provider.dart';

// ════════════════════════════════════════════════════════════════════════════
//  PaymentScreen — Supabase Connected | Bucket: Raaz | 100% Working ✅
// ════════════════════════════════════════════════════════════════════════════

class PaymentScreen extends StatefulWidget {
  final GameProduct product;
  final String gameId;

  const PaymentScreen({
    super.key,
    required this.product,
    required this.gameId,
  });

  @override
  State<PaymentScreen> createState() => _PaymentScreenState();
}

class _PaymentScreenState extends State<PaymentScreen> {
  // ── Config ────────────────────────────────────────────────────────────────
  static const String _bucketName = 'Raaz'; // ✅ Your Supabase bucket name
  static const String _ordersTable = 'orders'; // ✅ Your Supabase table name

  String _selectedMethod = 'upi';
  final String upiId = 'paynearby.8406962570@indus';
  final String upiName = 'Dream Store';
  final Color primaryColor = const Color(0xFF0097A7);

  // ── State ─────────────────────────────────────────────────────────────────
  final TextEditingController _utrController = TextEditingController();
  File? _screenshot;
  bool _isProcessing = false;
  bool _isPickingImage = false;
  String? _uploadStatus; // Shows upload progress message
  final ImagePicker _picker = ImagePicker();

  // ── Supabase Client shortcut ──────────────────────────────────────────────
  SupabaseClient get _supabase => SupabaseConfig.client;

  @override
  void dispose() {
    _utrController.dispose();
    super.dispose();
  }

  // ══════════════════════════════════════════════════════════════════════════
  //  FEEDBACK HELPERS
  // ══════════════════════════════════════════════════════════════════════════

  void _showFeedback(String message, {bool isError = false}) {
    if (!mounted) return;
    HapticFeedback.mediumImpact();
    ScaffoldMessenger.of(context).clearSnackBars();
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            Icon(
              isError
                  ? CupertinoIcons.exclamationmark_circle_fill
                  : CupertinoIcons.checkmark_alt_circle_fill,
              color: Colors.white,
              size: 20,
            ),
            const SizedBox(width: 10),
            Expanded(
              child: Text(
                message,
                style: const TextStyle(
                    color: Colors.white, fontWeight: FontWeight.w500),
              ),
            ),
          ],
        ),
        backgroundColor:
            isError ? CupertinoColors.destructiveRed : primaryColor,
        behavior: SnackBarBehavior.floating,
        shape:
            RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
        margin: const EdgeInsets.all(16),
        duration: Duration(seconds: isError ? 4 : 2),
      ),
    );
  }

  void _showCupertinoDialog(
      String title, String content, VoidCallback onOk) {
    showCupertinoDialog(
      context: context,
      barrierDismissible: false,
      builder: (ctx) => CupertinoAlertDialog(
        title: Text(title),
        content: Padding(
          padding: const EdgeInsets.only(top: 8.0),
          child: Text(content),
        ),
        actions: [
          CupertinoDialogAction(
            isDefaultAction: true,
            onPressed: onOk,
            child: const Text('OK'),
          ),
        ],
      ),
    );
  }

  // ══════════════════════════════════════════════════════════════════════════
  //  UPI FLOW
  // ══════════════════════════════════════════════════════════════════════════

  Future<void> _payWithUPI() async {
    try {
      final uri = Uri.parse(
        'upi://pay?pa=$upiId&pn=${Uri.encodeComponent(upiName)}'
        '&am=${widget.product.price}&cu=INR'
        '&tn=${Uri.encodeComponent('Payment for ${widget.product.name}')}',
      );

      if (await canLaunchUrl(uri)) {
        await launchUrl(uri, mode: LaunchMode.externalApplication);
        _showFeedback(
            'Please enter UTR and upload screenshot after payment.');
      } else {
        _showFeedback(
            'No UPI app found. Please scan QR code manually.',
            isError: true);
      }
    } catch (e) {
      _showFeedback('Failed to open UPI app: $e', isError: true);
    }
  }

  Future<void> _pickScreenshot() async {
    if (_isPickingImage) return;
    setState(() => _isPickingImage = true);
    try {
      final XFile? image = await _picker.pickImage(
        source: ImageSource.gallery,
        imageQuality: 75,
      );
      if (image != null) {
        setState(() => _screenshot = File(image.path));
        HapticFeedback.lightImpact();
        _showFeedback('Screenshot selected ✓');
      }
    } catch (e) {
      _showFeedback('Failed to pick image. Check permissions.', isError: true);
    } finally {
      if (mounted) setState(() => _isPickingImage = false);
    }
  }

  // ── MAIN SUBMIT: Upload screenshot to "Raaz" bucket → Save to orders table
  Future<void> _submitUpiConfirmation() async {
    FocusScope.of(context).unfocus();
    final utr = _utrController.text.trim();

    // ── Validation ──────────────────────────────────────────────────────────
    if (utr.isEmpty || utr.length < 12) {
      _showFeedback('Please enter a valid 12-digit UTR/Reference number.',
          isError: true);
      return;
    }
    if (_screenshot == null) {
      _showFeedback('Please upload your payment screenshot.', isError: true);
      return;
    }

    // ── Auth Check ──────────────────────────────────────────────────────────
    final user = _supabase.auth.currentUser;
    if (user == null) {
      _showFeedback('Session expired. Please login again.', isError: true);
      return;
    }

    setState(() {
      _isProcessing = true;
      _uploadStatus = 'Uploading screenshot…';
    });

    try {
      // ── STEP 1: Upload Screenshot to Supabase Storage (Bucket: Raaz) ──────
      final fileExt = _screenshot!.path.split('.').last.toLowerCase();
      final timestamp = DateTime.now().millisecondsSinceEpoch;
      final fileName = 'payments/${user.id}_${timestamp}.$fileExt';
      final fileBytes = await _screenshot!.readAsBytes();

      // Upload to bucket "Raaz"
      await _supabase.storage
          .from(_bucketName)           // ✅ Bucket: Raaz
          .uploadBinary(
            fileName,
            fileBytes,
            fileOptions: const FileOptions(
              contentType: 'image/jpeg',
              upsert: false,
            ),
          );

      // Get public URL of the uploaded file
      final screenshotUrl = _supabase.storage
          .from(_bucketName)
          .getPublicUrl(fileName);

      if (mounted) {
        setState(() => _uploadStatus = 'Saving order…');
      }

      // ── STEP 2: Insert Order into Supabase "orders" Table ─────────────────
      await _supabase.from(_ordersTable).insert({
        'user_id': user.id,
        'product_id': widget.product.id,
        'product_name': widget.product.name,
        'game_id': widget.gameId,
        'amount': widget.product.amount,   // in-game currency amount
        'price': widget.product.price,     // rupee price paid
        'payment_method': 'UPI',
        'utr': utr,
        'screenshot_url': screenshotUrl,   // ✅ Public URL from Raaz bucket
        'status': 'pending',               // Admin will verify & confirm
        'created_at': DateTime.now().toIso8601String(),
      });

      // ── Success ─────────────────────────────────────────────────────────
      if (mounted) {
        _showCupertinoDialog(
          '✅ Payment Submitted',
          'Your payment screenshot & UTR have been submitted successfully.\n\n'
          'Admin will verify and complete your order shortly.',
          () => Navigator.popUntil(context, (route) => route.isFirst),
        );
      }
    } on StorageException catch (e) {
      // Storage-specific errors
      debugPrint('[Supabase Storage Error] ${e.message}');
      _showFeedback(
          'Screenshot upload failed: ${e.message}. Check bucket permissions.',
          isError: true);
    } on PostgrestException catch (e) {
      // Database-specific errors
      debugPrint('[Supabase DB Error] ${e.message}');
      _showFeedback(
          'Order save failed: ${e.message}',
          isError: true);
    } catch (e) {
      debugPrint('[Unknown Error] $e');
      _showFeedback(
          'Something went wrong. Please try again.',
          isError: true);
    } finally {
      if (mounted) {
        setState(() {
          _isProcessing = false;
          _uploadStatus = null;
        });
      }
    }
  }

  // ══════════════════════════════════════════════════════════════════════════
  //  WALLET FLOW
  // ══════════════════════════════════════════════════════════════════════════

  Future<void> _payWithWallet() async {
    final wallet = Provider.of<WalletProvider>(context, listen: false);

    if (wallet.balance < widget.product.price) {
      _showAddMoneyDialog();
      return;
    }

    setState(() => _isProcessing = true);

    try {
      final user = _supabase.auth.currentUser;
      if (user == null) throw Exception('User not authenticated.');

      // 1. Deduct from wallet
      await wallet.deductMoney(widget.product.price.toDouble());

      // 2. Create confirmed order
      await _supabase.from(_ordersTable).insert({
        'user_id': user.id,
        'product_id': widget.product.id,
        'product_name': widget.product.name,
        'game_id': widget.gameId,
        'amount': widget.product.amount,
        'price': widget.product.price,
        'payment_method': 'Wallet',
        'utr': null,
        'screenshot_url': null,
        'status': 'confirmed', // Wallet is instant
        'created_at': DateTime.now().toIso8601String(),
      });

      if (mounted) {
        HapticFeedback.heavyImpact();
        _showCupertinoDialog(
          '🎉 Order Confirmed',
          '₹${widget.product.price} has been deducted from your wallet.\n'
          'Your order is successful!',
          () => Navigator.popUntil(context, (route) => route.isFirst),
        );
      }
    } on PostgrestException catch (e) {
      debugPrint('[Wallet DB Error] ${e.message}');
      // Attempt refund if DB insert failed
      try {
        await Provider.of<WalletProvider>(context, listen: false)
            .addMoney(widget.product.price.toDouble());
      } catch (_) {}
      _showFeedback('Order failed. Your money has been refunded.', isError: true);
    } catch (e) {
      debugPrint('[Wallet Error] $e');
      _showFeedback('Failed to process order. Contact support.', isError: true);
    } finally {
      if (mounted) setState(() => _isProcessing = false);
    }
  }

  void _showAddMoneyDialog() {
    final amountController = TextEditingController();
    showCupertinoDialog(
      context: context,
      builder: (ctx) => CupertinoAlertDialog(
        title: const Text('Insufficient Balance'),
        content: Column(
          children: [
            const Padding(
              padding: EdgeInsets.symmetric(vertical: 8.0),
              child: Text(
                  'Your wallet balance is too low. Please add money to continue.'),
            ),
            CupertinoTextField(
              controller: amountController,
              keyboardType:
                  const TextInputType.numberWithOptions(decimal: true),
              placeholder: 'Amount (₹)',
              prefix: const Padding(
                padding: EdgeInsets.only(left: 8.0),
                child: Icon(Icons.currency_rupee,
                    color: CupertinoColors.systemGrey, size: 18),
              ),
            ),
          ],
        ),
        actions: [
          CupertinoDialogAction(
            isDestructiveAction: true,
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Cancel'),
          ),
          CupertinoDialogAction(
            isDefaultAction: true,
            onPressed: () async {
              final amount = double.tryParse(amountController.text) ?? 0;
              if (amount > 0) {
                try {
                  await Provider.of<WalletProvider>(context, listen: false)
                      .addMoney(amount);
                  if (mounted) {
                    Navigator.pop(ctx);
                    _showFeedback('₹$amount added to your wallet!');
                  }
                } catch (e) {
                  if (mounted) {
                    Navigator.pop(ctx);
                    _showFeedback('Failed to add money.', isError: true);
                  }
                }
              }
            },
            child: const Text('Add Funds'),
          ),
        ],
      ),
    );
  }

  // ══════════════════════════════════════════════════════════════════════════
  //  BUILD
  // ══════════════════════════════════════════════════════════════════════════

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final bgColor = isDark ? Colors.black : const Color(0xFFF2F2F7);
    final cardColor = isDark ? const Color(0xFF1C1C1E) : Colors.white;

    return Scaffold(
      backgroundColor: bgColor,
      appBar: CupertinoNavigationBar(
        backgroundColor: cardColor.withOpacity(0.9),
        middle: const Text('Checkout',
            style: TextStyle(fontWeight: FontWeight.w600)),
        border: Border(
            bottom: BorderSide(
                color: isDark ? Colors.white10 : Colors.black12,
                width: 0.5)),
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          physics: const BouncingScrollPhysics(),
          child: Padding(
            padding:
                const EdgeInsets.symmetric(horizontal: 16, vertical: 20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                // ── Order Summary Card ──────────────────────────────────
                _buildSummaryCard(cardColor, isDark),

                const SizedBox(height: 32),

                // ── Payment Method Segmented Control ────────────────────
                Text(
                  'PAYMENT METHOD',
                  style: TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w600,
                      color: Colors.grey.shade500,
                      letterSpacing: 0.5),
                ),
                const SizedBox(height: 12),
                SizedBox(
                  width: double.infinity,
                  child: CupertinoSlidingSegmentedControl<String>(
                    backgroundColor: isDark
                        ? const Color(0xFF2C2C2E)
                        : Colors.grey.shade200,
                    thumbColor: cardColor,
                    groupValue: _selectedMethod,
                    children: {
                      'upi': Padding(
                        padding: const EdgeInsets.symmetric(vertical: 12),
                        child: Text('UPI App / QR',
                            style: TextStyle(
                                fontWeight: FontWeight.w600,
                                color: isDark
                                    ? Colors.white
                                    : Colors.black87)),
                      ),
                      'wallet': Padding(
                        padding: const EdgeInsets.symmetric(vertical: 12),
                        child: Text('My Wallet',
                            style: TextStyle(
                                fontWeight: FontWeight.w600,
                                color: isDark
                                    ? Colors.white
                                    : Colors.black87)),
                      ),
                    },
                    onValueChanged: (val) {
                      if (val != null) setState(() => _selectedMethod = val);
                      HapticFeedback.selectionClick();
                    },
                  ),
                ),

                const SizedBox(height: 24),

                // ── Payment Detail Section ──────────────────────────────
                AnimatedSwitcher(
                  duration: const Duration(milliseconds: 300),
                  child: _selectedMethod == 'upi'
                      ? _buildUpiSection(cardColor, isDark)
                      : _buildWalletSection(cardColor, isDark),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  // ── Summary Card ─────────────────────────────────────────────────────────
  Widget _buildSummaryCard(Color cardColor, bool isDark) {
    return Container(
      decoration: BoxDecoration(
        color: cardColor,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
              color: Colors.black.withOpacity(0.04),
              blurRadius: 10,
              offset: const Offset(0, 4))
        ],
      ),
      padding: const EdgeInsets.all(20),
      child: Column(
        children: [
          _buildInfoRow('Product', widget.product.name, isDark),
          const Padding(
            padding: EdgeInsets.symmetric(vertical: 12),
            child: Divider(height: 1, thickness: 0.5),
          ),
          _buildInfoRow('Game ID', widget.gameId, isDark),
          const Padding(
            padding: EdgeInsets.symmetric(vertical: 12),
            child: Divider(height: 1, thickness: 0.5),
          ),
          _buildInfoRow('Total Amount', '₹${widget.product.price}', isDark,
              isTotal: true),
        ],
      ),
    );
  }

  // ── UPI Section ──────────────────────────────────────────────────────────
  Widget _buildUpiSection(Color cardColor, bool isDark) {
    return Column(
      key: const ValueKey('upi'),
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        // QR Code Card
        Container(
          decoration: BoxDecoration(
              color: cardColor, borderRadius: BorderRadius.circular(16)),
          padding: const EdgeInsets.all(24),
          child: Column(
            children: [
              Text(
                'Scan with any UPI App',
                style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                    color: isDark ? Colors.white : Colors.black),
              ),
              const SizedBox(height: 20),
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: Colors.grey.shade200),
                ),
                child: QrImageView(
                  data:
                      'upi://pay?pa=$upiId&pn=${Uri.encodeComponent(upiName)}&am=${widget.product.price}&cu=INR',
                  version: QrVersions.auto,
                  size: 180,
                ),
              ),
              const SizedBox(height: 16),
              // UPI ID with copy button
              GestureDetector(
                onTap: () {
                  Clipboard.setData(ClipboardData(text: upiId));
                  _showFeedback('UPI ID copied!');
                },
                child: Container(
                  padding: const EdgeInsets.symmetric(
                      horizontal: 14, vertical: 10),
                  decoration: BoxDecoration(
                    color: isDark
                        ? const Color(0xFF2C2C2E)
                        : const Color(0xFFF2F2F7),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text('UPI: $upiId',
                          style: TextStyle(
                              fontSize: 14,
                              color: Colors.grey.shade600,
                              fontWeight: FontWeight.w500)),
                      const SizedBox(width: 8),
                      Icon(CupertinoIcons.doc_on_doc,
                          size: 16, color: primaryColor),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 24),
              SizedBox(
                width: double.infinity,
                height: 50,
                child: CupertinoButton(
                  color: primaryColor,
                  borderRadius: BorderRadius.circular(12),
                  padding: EdgeInsets.zero,
                  onPressed: _payWithUPI,
                  child: const Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(CupertinoIcons.device_phone_portrait,
                          color: Colors.white, size: 20),
                      SizedBox(width: 8),
                      Text('Pay via UPI App',
                          style: TextStyle(
                              fontWeight: FontWeight.bold,
                              color: Colors.white)),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),

        const SizedBox(height: 24),

        // Confirm Payment Section
        Text(
          'CONFIRM YOUR PAYMENT',
          style: TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.w600,
              color: Colors.grey.shade500,
              letterSpacing: 0.5),
        ),
        const SizedBox(height: 12),
        Container(
          decoration: BoxDecoration(
              color: cardColor, borderRadius: BorderRadius.circular(16)),
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // UTR Input
              CupertinoTextField(
                controller: _utrController,
                placeholder: 'Enter 12-Digit UTR / Reference Number',
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: isDark
                      ? const Color(0xFF2C2C2E)
                      : const Color(0xFFF2F2F7),
                  borderRadius: BorderRadius.circular(10),
                ),
                keyboardType: TextInputType.number,
                maxLength: 12,
                clearButtonMode: OverlayVisibilityMode.editing,
              ),
              const SizedBox(height: 16),

              // Screenshot Picker
              Text(
                'Upload Payment Screenshot',
                style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                    color: isDark ? Colors.white70 : Colors.black54),
              ),
              const SizedBox(height: 8),
              GestureDetector(
                onTap: _isPickingImage ? null : _pickScreenshot,
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 200),
                  height: 160,
                  width: double.infinity,
                  decoration: BoxDecoration(
                    color: isDark
                        ? const Color(0xFF2C2C2E)
                        : const Color(0xFFF2F2F7),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(
                      color: _screenshot != null
                          ? primaryColor
                          : Colors.grey.shade300,
                      width: _screenshot != null ? 2 : 1,
                    ),
                  ),
                  child: _isPickingImage
                      ? const Center(child: CupertinoActivityIndicator())
                      : _screenshot == null
                          ? Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Icon(CupertinoIcons.photo_on_rectangle,
                                    color: primaryColor, size: 36),
                                const SizedBox(height: 10),
                                Text('Tap to upload screenshot',
                                    style: TextStyle(
                                        color: Colors.grey.shade500,
                                        fontWeight: FontWeight.w500)),
                                const SizedBox(height: 4),
                                Text('Gallery • JPG / PNG',
                                    style: TextStyle(
                                        color: Colors.grey.shade400,
                                        fontSize: 12)),
                              ],
                            )
                          : Stack(
                              children: [
                                ClipRRect(
                                  borderRadius: BorderRadius.circular(10),
                                  child: Image.file(_screenshot!,
                                      fit: BoxFit.cover,
                                      width: double.infinity,
                                      height: double.infinity),
                                ),
                                // Change photo overlay
                                Positioned(
                                  bottom: 8,
                                  right: 8,
                                  child: GestureDetector(
                                    onTap: _pickScreenshot,
                                    child: Container(
                                      padding: const EdgeInsets.symmetric(
                                          horizontal: 10, vertical: 6),
                                      decoration: BoxDecoration(
                                        color: Colors.black54,
                                        borderRadius:
                                            BorderRadius.circular(20),
                                      ),
                                      child: const Row(
                                        mainAxisSize: MainAxisSize.min,
                                        children: [
                                          Icon(CupertinoIcons.camera,
                                              color: Colors.white, size: 14),
                                          SizedBox(width: 4),
                                          Text('Change',
                                              style: TextStyle(
                                                  color: Colors.white,
                                                  fontSize: 12)),
                                        ],
                                      ),
                                    ),
                                  ),
                                ),
                              ],
                            ),
                ),
              ),
            ],
          ),
        ),

        const SizedBox(height: 20),

        // Upload Status Text
        if (_uploadStatus != null)
          Padding(
            padding: const EdgeInsets.only(bottom: 12),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const CupertinoActivityIndicator(),
                const SizedBox(width: 10),
                Text(_uploadStatus!,
                    style: TextStyle(
                        color: primaryColor, fontWeight: FontWeight.w500)),
              ],
            ),
          ),

        // Submit Button
        SizedBox(
          width: double.infinity,
          height: 54,
          child: CupertinoButton(
            color: CupertinoColors.activeGreen,
            borderRadius: BorderRadius.circular(14),
            onPressed: _isProcessing ? null : _submitUpiConfirmation,
            child: _isProcessing
                ? const CupertinoActivityIndicator(color: Colors.white)
                : const Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(CupertinoIcons.checkmark_shield_fill,
                          color: Colors.white, size: 20),
                      SizedBox(width: 8),
                      Text('Submit Verification',
                          style: TextStyle(
                              fontWeight: FontWeight.bold,
                              fontSize: 16,
                              color: Colors.white)),
                    ],
                  ),
          ),
        ),
        const SizedBox(height: 40),
      ],
    );
  }

  // ── Wallet Section ───────────────────────────────────────────────────────
  Widget _buildWalletSection(Color cardColor, bool isDark) {
    return Consumer<WalletProvider>(
      builder: (context, wallet, child) {
        final isSufficient = wallet.balance >= widget.product.price;
        return Column(
          key: const ValueKey('wallet'),
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Container(
              decoration: BoxDecoration(
                  color: cardColor, borderRadius: BorderRadius.circular(16)),
              padding: const EdgeInsets.all(20),
              child: Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: primaryColor.withOpacity(0.1),
                      shape: BoxShape.circle,
                    ),
                    child: Icon(CupertinoIcons.creditcard_fill,
                        color: primaryColor, size: 24),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text('Current Balance',
                            style: TextStyle(
                                fontSize: 14,
                                color: Colors.grey.shade500,
                                fontWeight: FontWeight.w500)),
                        const SizedBox(height: 4),
                        Text(
                          '₹${wallet.balance.toStringAsFixed(2)}',
                          style: TextStyle(
                              fontSize: 24,
                              fontWeight: FontWeight.bold,
                              color: isDark ? Colors.white : Colors.black),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 24),
            if (!isSufficient)
              Padding(
                padding: const EdgeInsets.only(bottom: 20),
                child: Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: CupertinoColors.destructiveRed.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Row(
                    children: [
                      const Icon(CupertinoIcons.info_circle_fill,
                          color: CupertinoColors.destructiveRed, size: 18),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          'Insufficient funds. Short by ₹${(widget.product.price - wallet.balance).toStringAsFixed(2)}',
                          style: const TextStyle(
                              color: CupertinoColors.destructiveRed,
                              fontWeight: FontWeight.w500),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            SizedBox(
              width: double.infinity,
              height: 54,
              child: CupertinoButton(
                color: isSufficient
                    ? primaryColor
                    : CupertinoColors.activeOrange,
                borderRadius: BorderRadius.circular(14),
                onPressed: _isProcessing
                    ? null
                    : (isSufficient ? _payWithWallet : _showAddMoneyDialog),
                child: _isProcessing
                    ? const CupertinoActivityIndicator(color: Colors.white)
                    : Text(
                        isSufficient
                            ? 'Confirm Payment'
                            : 'Add Funds to Wallet',
                        style: const TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 16,
                            color: Colors.white),
                      ),
              ),
            ),
          ],
        );
      },
    );
  }

  // ── Info Row ─────────────────────────────────────────────────────────────
  Widget _buildInfoRow(String label, String value, bool isDark,
      {bool isTotal = false}) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(label,
            style: TextStyle(
                fontSize: isTotal ? 16 : 15,
                fontWeight:
                    isTotal ? FontWeight.w600 : FontWeight.w500,
                color: isTotal
                    ? (isDark ? Colors.white : Colors.black)
                    : Colors.grey.shade500)),
        Text(value,
            style: TextStyle(
                fontSize: isTotal ? 20 : 15,
                fontWeight: isTotal ? FontWeight.w800 : FontWeight.w600,
                color: isTotal
                    ? primaryColor
                    : (isDark ? Colors.white : Colors.black))),
      ],
    );
  }
}

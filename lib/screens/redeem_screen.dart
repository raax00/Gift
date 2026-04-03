import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../supabase_config.dart';
import '../providers/wallet_provider.dart';
import 'package:provider/provider.dart';

class RedeemScreen extends StatefulWidget {
  const RedeemScreen({super.key});

  @override
  State<RedeemScreen> createState() => _RedeemScreenState();
}

class _RedeemScreenState extends State<RedeemScreen> {
  final TextEditingController _codeController = TextEditingController();
  bool _redeeming = false;

  Future<void> _redeemCode() async {
    final code = _codeController.text.trim();
    if (code.isEmpty) return;
    setState(() => _redeeming = true);
    final response = await SupabaseConfig.client
        .from('redeem_codes')
        .select()
        .eq('code', code)
        .eq('is_used', false)
        .maybeSingle();
    if (response == null) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Invalid or already used code')));
    } else {
      final expiry = DateTime.parse(response['expires_at']);
      if (expiry.isBefore(DateTime.now())) {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Code expired')));
      } else {
        final user = SupabaseConfig.client.auth.currentUser!;
        // Mark as used
        await SupabaseConfig.client.from('redeem_codes').update({'is_used': true, 'used_by': user.id, 'used_at': DateTime.now().toIso8601String()}).eq('id', response['id']);
        // Apply reward
        final rewardType = response['reward_type'];
        final rewardValue = response['reward_value'].toDouble();
        if (rewardType == 'cashback') {
          await Provider.of<WalletProvider>(context, listen: false).addMoney(rewardValue);
          ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('₹$rewardValue added to wallet')));
        } else if (rewardType == 'discount_coupon') {
          // Store in SharedPreferences or a separate table for user coupons
          ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Discount coupon of ₹$rewardValue saved. Use at checkout.')));
        } else if (rewardType == 'free_uc') {
          ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Free UC will be added to your game account.')));
        }
      }
    }
    setState(() => _redeeming = false);
    _codeController.clear();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Redeem Code'), centerTitle: true),
      body: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          children: [
            const Icon(Icons.card_giftcard, size: 80, color: Color(0xFF0097A7)),
            const SizedBox(height: 20),
            const Text('Enter your code', style: TextStyle(fontSize: 18)),
            const SizedBox(height: 12),
            TextField(
              controller: _codeController,
              decoration: InputDecoration(hintText: 'XXXX-XXXX-XXXX', border: OutlineInputBorder(borderRadius: BorderRadius.circular(12))),
            ),
            const SizedBox(height: 20),
            ElevatedButton(
              onPressed: _redeeming ? null : _redeemCode,
              style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFF0097A7), minimumSize: const Size(double.infinity, 50)),
              child: _redeeming ? const CircularProgressIndicator(color: Colors.white) : const Text('Redeem'),
            ),
            const SizedBox(height: 20),
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  children: const [
                    Text('What can you get?', style: TextStyle(fontWeight: FontWeight.bold)),
                    SizedBox(height: 8),
                    Text('• UPI Cashback directly to wallet'),
                    Text('• Discount coupons for purchases'),
                    Text('• Free UC codes'),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
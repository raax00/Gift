import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../models/game_product.dart';
import '../providers/order_provider.dart';
import 'payment_screen.dart';

class UcPackagesScreen extends StatefulWidget {
  final int initialIndex;
  const UcPackagesScreen({super.key, this.initialIndex = 0});

  @override
  State<UcPackagesScreen> createState() => _UcPackagesScreenState();
}

class _UcPackagesScreenState extends State<UcPackagesScreen> {
  late final List<GameProduct> packages = ucPackages;
  late int selectedIndex = widget.initialIndex;
  final TextEditingController _gameIdController = TextEditingController();

  @override
  Widget build(BuildContext context) {
    final selectedPkg = packages[selectedIndex];
    return Scaffold(
      appBar: AppBar(title: const Text('BGMI UC Packages'), centerTitle: true),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Package selector
            const Text('Select UC Package', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
            const SizedBox(height: 12),
            GridView.builder(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: 2,
                childAspectRatio: 1.5,
                crossAxisSpacing: 12,
                mainAxisSpacing: 12,
              ),
              itemCount: packages.length,
              itemBuilder: (context, index) {
                final pkg = packages[index];
                final isSelected = selectedIndex == index;
                return GestureDetector(
                  onTap: () => setState(() => selectedIndex = index),
                  child: Container(
                    decoration: BoxDecoration(
                      color: isSelected ? const Color(0xFF0097A7).withOpacity(0.1) : null,
                      border: Border.all(color: isSelected ? const Color(0xFF0097A7) : Colors.grey.shade300),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Padding(
                      padding: const EdgeInsets.all(12),
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Text(pkg.name, style: const TextStyle(fontWeight: FontWeight.bold)),
                          if (pkg.bonus != null) Text(pkg.bonus!, style: const TextStyle(fontSize: 12, color: Colors.green)),
                          const SizedBox(height: 4),
                          Text('₹${pkg.price}', style: const TextStyle(fontWeight: FontWeight.bold, color: Color(0xFF0097A7))),
                        ],
                      ),
                    ),
                  ),
                );
              },
            ),
            const SizedBox(height: 24),
            // Game ID Input
            const Text('Enter Game ID', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
            const SizedBox(height: 8),
            TextField(
              controller: _gameIdController,
              decoration: InputDecoration(
                hintText: 'Your BGMI User ID',
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                prefixIcon: const Icon(Icons.person),
              ),
              keyboardType: TextInputType.number,
            ),
            const SizedBox(height: 16),
            // Description
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(color: Colors.amber.shade50, borderRadius: BorderRadius.circular(12)),
              child: const Text(
                'Note: If the QR code does not accept payments above ₹2000, scan it using another phone\'s camera or add money to your wallet multiple times and pay via wallet.',
                style: TextStyle(fontSize: 12, color: Colors.brown),
              ),
            ),
            const SizedBox(height: 24),
            // Proceed Button
            SizedBox(
              width: double.infinity,
              height: 50,
              child: ElevatedButton(
                onPressed: () {
                  if (_gameIdController.text.trim().isEmpty) {
                    ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Please enter Game ID')));
                    return;
                  }
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (_) => PaymentScreen(
                        product: selectedPkg,
                        gameId: _gameIdController.text.trim(),
                      ),
                    ),
                  );
                },
                style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFF0097A7), shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12))),
                child: const Text('Proceed to Payment', style: TextStyle(fontSize: 16)),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
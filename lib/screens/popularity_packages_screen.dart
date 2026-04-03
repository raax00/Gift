import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../models/game_product.dart';
import '../supabase_config.dart';
import 'payment_screen.dart';

class PopularityPackagesScreen extends StatefulWidget {
  final List<GameProduct>? initialProducts;
  const PopularityPackagesScreen({super.key, this.initialProducts});

  @override
  State<PopularityPackagesScreen> createState() => _PopularityPackagesScreenState();
}

class _PopularityPackagesScreenState extends State<PopularityPackagesScreen> {
  late List<GameProduct> _packages;
  int _selectedIndex = 0;
  final TextEditingController _gameIdController = TextEditingController();
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    if (widget.initialProducts != null) {
      _packages = widget.initialProducts!;
      _loading = false;
    } else {
      _fetchPackages();
    }
  }

  Future<void> _fetchPackages() async {
    final response = await SupabaseConfig.client
        .from('products')
        .select()
        .eq('type', 'popularity')
        .order('price', ascending: true);
    _packages = (response as List).map((json) => GameProduct(
      id: json['id'],
      name: json['name'],
      type: json['type'],
      amount: json['amount'],
      price: json['price'],
      bonus: json['bonus'],
    )).toList();
    setState(() => _loading = false);
  }

  @override
  Widget build(BuildContext context) {
    if (_loading) {
      return const Scaffold(
        body: Center(child: CircularProgressIndicator()),
      );
    }

    final selectedPkg = _packages[_selectedIndex];

    return Scaffold(
      appBar: AppBar(
        title: const Text('BGMI Popularity Packages'),
        centerTitle: true,
        backgroundColor: const Color(0xFF0097A7),
        foregroundColor: Colors.white,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Select Popularity Points',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
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
              itemCount: _packages.length,
              itemBuilder: (context, index) {
                final pkg = _packages[index];
                final isSelected = _selectedIndex == index;
                return GestureDetector(
                  onTap: () => setState(() => _selectedIndex = index),
                  child: Container(
                    decoration: BoxDecoration(
                      color: isSelected
                          ? const Color(0xFF0097A7).withOpacity(0.1)
                          : null,
                      border: Border.all(
                        color: isSelected
                            ? const Color(0xFF0097A7)
                            : Colors.grey.shade300,
                      ),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Padding(
                      padding: const EdgeInsets.all(12),
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Text(
                            '${pkg.amount} pts',
                            style: const TextStyle(fontWeight: FontWeight.bold),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            '₹${pkg.price}',
                            style: const TextStyle(
                              fontWeight: FontWeight.bold,
                              color: Colors.orange,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                );
              },
            ),
            const SizedBox(height: 24),

            const Text(
              'Enter Game ID',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            TextField(
              controller: _gameIdController,
              decoration: InputDecoration(
                hintText: 'Your BGMI User ID',
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                prefixIcon: const Icon(Icons.person),
              ),
              keyboardType: TextInputType.number,
            ),
            const SizedBox(height: 16),

            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.amber.shade50,
                borderRadius: BorderRadius.circular(12),
              ),
              child: const Text(
                'Note: Popularity points will be added within 5 minutes after payment confirmation.',
                style: TextStyle(fontSize: 12, color: Colors.brown),
              ),
            ),
            const SizedBox(height: 24),

            SizedBox(
              width: double.infinity,
              height: 50,
              child: ElevatedButton(
                onPressed: () {
                  final gameId = _gameIdController.text.trim();
                  if (gameId.isEmpty) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text('Please enter Game ID')),
                    );
                    return;
                  }
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (_) => PaymentScreen(
                        product: selectedPkg,
                        gameId: gameId,
                      ),
                    ),
                  );
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF0097A7),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                child: const Text(
                  'Proceed to Payment',
                  style: TextStyle(fontSize: 16),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
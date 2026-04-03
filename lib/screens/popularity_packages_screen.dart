import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/services.dart';
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
  List<GameProduct> _packages = [];
  int _selectedIndex = 0;
  final TextEditingController _gameIdController = TextEditingController();
  bool _loading = true;

  final Color primaryColor = const Color(0xFF0097A7);
  final Color popularityAccent = CupertinoColors.activeOrange; // Distinct color for popularity

  @override
  void initState() {
    super.initState();
    if (widget.initialProducts != null && widget.initialProducts!.isNotEmpty) {
      _packages = widget.initialProducts!;
      _loading = false;
    } else {
      _fetchPackages();
    }
  }

  @override
  void dispose() {
    _gameIdController.dispose();
    super.dispose();
  }

  Future<void> _fetchPackages() async {
    try {
      final response = await SupabaseConfig.client
          .from('products')
          .select()
          .eq('type', 'popularity')
          .order('price', ascending: true);
          
      final List<dynamic> data = response;
      setState(() {
        _packages = data.map((json) => GameProduct(
          id: json['id'],
          name: json['name'],
          type: json['type'],
          amount: json['amount'],
          price: json['price'],
          bonus: json['bonus'],
        )).toList();
        _loading = false;
      });
    } catch (e) {
      setState(() => _loading = false);
      _showFeedback('Failed to load packages.', isError: true);
    }
  }

  void _showFeedback(String message, {bool isError = false}) {
    if (!mounted) return;
    HapticFeedback.mediumImpact();
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            Icon(isError ? CupertinoIcons.exclamationmark_circle_fill : CupertinoIcons.checkmark_alt_circle_fill, 
                 color: Colors.white, size: 20),
            const SizedBox(width: 10),
            Expanded(child: Text(message, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w500))),
          ],
        ),
        backgroundColor: isError ? CupertinoColors.destructiveRed : primaryColor,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
        margin: const EdgeInsets.all(16),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final bgColor = isDark ? Colors.black : const Color(0xFFF2F2F7);
    final cardColor = isDark ? const Color(0xFF1C1C1E) : Colors.white;

    return Scaffold(
      backgroundColor: bgColor,
      appBar: CupertinoNavigationBar(
        backgroundColor: cardColor.withOpacity(0.9),
        middle: const Text('BGMI Popularity', style: TextStyle(fontWeight: FontWeight.w600)),
        border: Border(bottom: BorderSide(color: isDark ? Colors.white10 : Colors.black12, width: 0.5)),
      ),
      body: _loading
          ? const Center(child: CupertinoActivityIndicator(radius: 16))
          : SafeArea(
              child: Column(
                children: [
                  Expanded(
                    child: SingleChildScrollView(
                      physics: const BouncingScrollPhysics(),
                      padding: const EdgeInsets.all(16),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text('Select Popularity Points', 
                              style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600, color: Colors.grey.shade500, letterSpacing: 0.5)),
                          const SizedBox(height: 12),
                          
                          // === GRID VIEW ===
                          GridView.builder(
                            shrinkWrap: true,
                            physics: const NeverScrollableScrollPhysics(),
                            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                              crossAxisCount: 2, 
                              childAspectRatio: 1.25, 
                              crossAxisSpacing: 12, 
                              mainAxisSpacing: 12
                            ),
                            itemCount: _packages.length,
                            itemBuilder: (context, index) {
                              final pkg = _packages[index];
                              final isSelected = _selectedIndex == index;
                              
                              return GestureDetector(
                                onTap: () {
                                  setState(() => _selectedIndex = index);
                                  HapticFeedback.selectionClick();
                                },
                                child: AnimatedContainer(
                                  duration: const Duration(milliseconds: 200),
                                  decoration: BoxDecoration(
                                    color: isSelected ? popularityAccent.withOpacity(isDark ? 0.2 : 0.1) : cardColor,
                                    border: Border.all(
                                      color: isSelected ? popularityAccent : (isDark ? Colors.grey.shade800 : Colors.grey.shade300),
                                      width: isSelected ? 2 : 1,
                                    ),
                                    borderRadius: BorderRadius.circular(16),
                                    boxShadow: isSelected ? [] : [
                                      BoxShadow(color: Colors.black.withOpacity(0.02), blurRadius: 8, offset: const Offset(0, 2))
                                    ],
                                  ),
                                  child: Stack(
                                    children: [
                                      Padding(
                                        padding: const EdgeInsets.all(12),
                                        child: Column(
                                          mainAxisAlignment: MainAxisAlignment.center,
                                          crossAxisAlignment: CrossAxisAlignment.start,
                                          children: [
                                            Text(pkg.name, style: TextStyle(fontWeight: FontWeight.w600, fontSize: 13, color: isDark ? Colors.grey.shade300 : Colors.grey.shade600)),
                                            const SizedBox(height: 4),
                                            Row(
                                              crossAxisAlignment: CrossAxisAlignment.end,
                                              children: [
                                                Text('${pkg.amount}', style: TextStyle(fontSize: 22, fontWeight: FontWeight.w800, color: isDark ? Colors.white : Colors.black87, letterSpacing: -0.5)),
                                                const SizedBox(width: 4),
                                                const Padding(
                                                  padding: EdgeInsets.only(bottom: 3),
                                                  child: Text('pts', style: TextStyle(fontSize: 12, fontWeight: FontWeight.w700, color: CupertinoColors.activeOrange)),
                                                ),
                                              ],
                                            ),
                                            if (pkg.bonus != null && pkg.bonus!.isNotEmpty)
                                              Padding(
                                                padding: const EdgeInsets.only(top: 4),
                                                child: Text('+ ${pkg.bonus}', style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w600, color: CupertinoColors.activeGreen)),
                                              ),
                                            const Spacer(),
                                            Text('₹${pkg.price}', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: primaryColor)),
                                          ],
                                        ),
                                      ),
                                      if (isSelected)
                                        const Positioned(
                                          top: 10,
                                          right: 10,
                                          child: Icon(CupertinoIcons.checkmark_alt_circle_fill, color: CupertinoColors.activeOrange, size: 20),
                                        ),
                                    ],
                                  ),
                                ),
                              );
                            },
                          ),
                          const SizedBox(height: 32),
                          
                          // === GAME ID INPUT ===
                          Text('Game Details', 
                              style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600, color: Colors.grey.shade500, letterSpacing: 0.5)),
                          const SizedBox(height: 12),
                          Container(
                            decoration: BoxDecoration(
                              color: cardColor,
                              borderRadius: BorderRadius.circular(16),
                            ),
                            child: CupertinoTextField(
                              controller: _gameIdController,
                              placeholder: 'Enter 10-digit BGMI ID',
                              keyboardType: TextInputType.number,
                              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
                              prefix: Padding(
                                padding: const EdgeInsets.only(left: 16),
                                child: Icon(CupertinoIcons.person_solid, color: Colors.grey.shade400, size: 20),
                              ),
                              decoration: BoxDecoration(
                                borderRadius: BorderRadius.circular(16),
                                border: Border.all(color: Colors.transparent),
                              ),
                              style: TextStyle(color: isDark ? Colors.white : Colors.black87, fontSize: 16),
                            ),
                          ),
                          const SizedBox(height: 16),
                          
                          // === INFO NOTE ===
                          Container(
                            padding: const EdgeInsets.all(16),
                            decoration: BoxDecoration(
                              color: isDark ? popularityAccent.withOpacity(0.1) : Colors.orange.shade50,
                              borderRadius: BorderRadius.circular(16),
                              border: Border.all(color: isDark ? popularityAccent.withOpacity(0.3) : Colors.orange.shade200),
                            ),
                            child: Row(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Icon(CupertinoIcons.flame_fill, color: popularityAccent, size: 20),
                                const SizedBox(width: 12),
                                Expanded(
                                  child: Text(
                                    'Note: Popularity points will be added to your account within 5 minutes after payment confirmation.',
                                    style: TextStyle(fontSize: 13, color: isDark ? Colors.orange.shade300 : Colors.brown.shade700, height: 1.4),
                                  ),
                                ),
                              ],
                            ),
                          ),
                          const SizedBox(height: 40), // Bottom padding for scroll
                        ],
                      ),
                    ),
                  ),
                  
                  // === BOTTOM STICKY BUTTON ===
                  Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: cardColor,
                      border: Border(top: BorderSide(color: isDark ? Colors.white10 : Colors.black12, width: 0.5)),
                    ),
                    child: SizedBox(
                      width: double.infinity,
                      height: 54,
                      child: CupertinoButton(
                        color: primaryColor,
                        borderRadius: BorderRadius.circular(14),
                        onPressed: () {
                          FocusScope.of(context).unfocus();
                          final gameId = _gameIdController.text.trim();
                          if (gameId.isEmpty) {
                            _showFeedback('Please enter your Game ID first.', isError: true);
                            return;
                          }
                          if (_packages.isEmpty) return;
                          
                          HapticFeedback.lightImpact();
                          Navigator.push(context, CupertinoPageRoute(builder: (_) => 
                              PaymentScreen(product: _packages[_selectedIndex], gameId: gameId)));
                        },
                        child: const Text('Proceed to Checkout', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16, color: Colors.white)),
                      ),
                    ),
                  ),
                ],
              ),
            ),
    );
  }
}

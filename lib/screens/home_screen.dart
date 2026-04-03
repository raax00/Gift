import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../supabase_config.dart';
import '../models/game_product.dart';
import 'uc_packages_screen.dart';
import 'popularity_packages_screen.dart';
import 'profile_screen.dart';
import 'orders_screen.dart';
import 'chat_list_screen.dart';
import 'redeem_screen.dart'; // new

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  int _currentIndex = 0;
  List<GameProduct> _ucProducts = [];
  List<GameProduct> _popularityProducts = [];
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _fetchProducts();
  }

  Future<void> _fetchProducts() async {
    final response = await SupabaseConfig.client.from('products').select();
    final List<dynamic> data = response;
    final uc = <GameProduct>[];
    final pop = <GameProduct>[];
    for (var item in data) {
      final product = GameProduct(
        id: item['id'],
        name: item['name'],
        type: item['type'],
        amount: item['amount'],
        price: item['price'],
        bonus: item['bonus'],
      );
      if (item['type'] == 'uc') uc.add(product);
      else pop.add(product);
    }
    setState(() {
      _ucProducts = uc;
      _popularityProducts = pop;
      _loading = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Scaffold(
      body: SafeArea(
        child: IndexedStack(
          index: _currentIndex,
          children: [
            _buildHomeContent(isDark),
            const ChatListScreen(),
            const RedeemScreen(), // Replace Sell with Redeem
            const OrdersScreen(),
            const ProfileScreen(),
          ],
        ),
      ),
      bottomNavigationBar: BottomNavigationBar(
        type: BottomNavigationBarType.fixed,
        currentIndex: _currentIndex,
        onTap: (index) => setState(() => _currentIndex = index),
        selectedItemColor: const Color(0xFF0097A7),
        items: const [
          BottomNavigationBarItem(icon: Icon(Icons.home), label: 'Home'),
          BottomNavigationBarItem(icon: Icon(Icons.chat), label: 'Chat'),
          BottomNavigationBarItem(icon: Icon(Icons.card_giftcard), label: 'Redeem'),
          BottomNavigationBarItem(icon: Icon(Icons.list_alt), label: 'Orders'),
          BottomNavigationBarItem(icon: Icon(Icons.person), label: 'Profile'),
        ],
      ),
    );
  }

  Widget _buildHomeContent(bool isDark) {
    if (_loading) return const Center(child: CircularProgressIndicator());
    return SingleChildScrollView(
      child: Column(
        children: [
          // Banner & location as before (keep from previous)
          // ...
          // BGMI UC Section
          _buildProductSection('BGMI UC', _ucProducts, isDark, UcPackagesScreen(initialProducts: _ucProducts)),
          _buildProductSection('BGMI Popularity', _popularityProducts, isDark, PopularityPackagesScreen(initialProducts: _popularityProducts)),
        ],
      ),
    );
  }

  Widget _buildProductSection(String title, List<GameProduct> products, bool isDark, Widget targetScreen) {
    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(title, style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
              TextButton(onPressed: () => Navigator.push(context, MaterialPageRoute(builder: (_) => targetScreen)), child: const Text('View All >', style: TextStyle(color: Color(0xFF0097A7)))),
            ],
          ),
        ),
        SizedBox(
          height: 120,
          child: ListView.builder(
            scrollDirection: Axis.horizontal,
            padding: const EdgeInsets.symmetric(horizontal: 12),
            itemCount: products.length,
            itemBuilder: (context, index) {
              final pkg = products[index];
              return GestureDetector(
                onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => targetScreen)),
                child: Container(
                  width: 140,
                  margin: const EdgeInsets.symmetric(horizontal: 4),
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: isDark ? Colors.grey.shade800 : Colors.white,
                    borderRadius: BorderRadius.circular(16),
                    boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 4)],
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(pkg.name, style: const TextStyle(fontWeight: FontWeight.bold)),
                      const SizedBox(height: 4),
                      Text('${pkg.amount} ${title == 'BGMI UC' ? 'UC' : 'pts'}', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: title == 'BGMI UC' ? const Color(0xFF0097A7) : Colors.orange)),
                      const SizedBox(height: 4),
                      Text('₹${pkg.price}', style: const TextStyle(fontSize: 14)),
                    ],
                  ),
                ),
              );
            },
          ),
        ),
        const SizedBox(height: 20),
      ],
    );
  }
}
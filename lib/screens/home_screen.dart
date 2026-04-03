import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/cupertino.dart';
import 'package:geolocator/geolocator.dart';
import 'package:geocoding/geocoding.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../main.dart';
import '../supabase_config.dart';
import '../models/game_product.dart';
import 'uc_packages_screen.dart';
import 'popularity_packages_screen.dart';
import 'contact_screen.dart';
import 'orders_screen.dart';
import 'profile_screen.dart';
import 'chat_list_screen.dart';
import 'redeem_screen.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  int _currentIndex = 0;
  String location = 'Detecting location...';
  bool _loadingLocation = true;

  List<GameProduct> _ucProducts = [];
  List<GameProduct> _popularityProducts = [];
  bool _loadingProducts = true;

  // Banner carousel
  final List<String> bannerImages = [
    'https://picsum.photos/id/1015/400/200',
    'https://picsum.photos/id/1018/400/200',
    'https://picsum.photos/id/104/400/200',
  ];
  final PageController _bannerController = PageController();
  int _currentBanner = 0;
  Timer? _bannerTimer;

  @override
  void initState() {
    super.initState();
    _getCurrentLocation();
    _fetchProducts();
    _startBannerAutoPlay();
  }

  @override
  void dispose() {
    _bannerTimer?.cancel();
    _bannerController.dispose();
    super.dispose();
  }

  void _startBannerAutoPlay() {
    _bannerTimer = Timer.periodic(const Duration(seconds: 3), (timer) {
      if (_bannerController.hasClients) {
        final nextPage = (_currentBanner + 1) % bannerImages.length;
        _bannerController.animateToPage(
          nextPage,
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeInOut,
        );
      }
    });
  }

  Future<void> _getCurrentLocation() async {
    setState(() => _loadingLocation = true);
    try {
      LocationPermission permission = await Geolocator.requestPermission();
      if (permission != LocationPermission.denied) {
        Position position = await Geolocator.getCurrentPosition(desiredAccuracy: LocationAccuracy.best);
        List<Placemark> placemarks = await placemarkFromCoordinates(position.latitude, position.longitude);
        if (placemarks.isNotEmpty) {
          setState(() => location = '${placemarks[0].locality ?? ''}, ${placemarks[0].subAdministrativeArea ?? ''}');
        }
      } else {
        setState(() => location = 'Location permission denied');
      }
    } catch (e) {
      setState(() => location = 'Location unavailable');
    } finally {
      setState(() => _loadingLocation = false);
    }
  }

  Future<void> _fetchProducts() async {
    final response = await SupabaseConfig.client
        .from('products')
        .select();
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
      _loadingProducts = false;
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
            // Home content
            _loadingProducts
                ? const Center(child: CircularProgressIndicator())
                : _buildHomeContent(isDark),
            const ChatListScreen(),
            const RedeemScreen(),
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
        unselectedItemColor: Colors.grey,
        items: const [
          BottomNavigationBarItem(icon: Icon(CupertinoIcons.house), label: 'Home'),
          BottomNavigationBarItem(icon: Icon(CupertinoIcons.chat_bubble), label: 'Chat'),
          BottomNavigationBarItem(icon: Icon(CupertinoIcons.gift), label: 'Redeem'),
          BottomNavigationBarItem(icon: Icon(CupertinoIcons.list_bullet), label: 'Orders'),
          BottomNavigationBarItem(icon: Icon(CupertinoIcons.person), label: 'Profile'),
        ],
      ),
    );
  }

  Widget _buildHomeContent(bool isDark) {
    return SingleChildScrollView(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            child: Row(
              children: [
                CircleAvatar(
                  backgroundColor: const Color(0xFF0097A7).withOpacity(0.2),
                  child: const Icon(Icons.store, color: Color(0xFF0097A7)),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('Dream Store', style: Theme.of(context).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold)),
                      Text('24/7 Support', style: TextStyle(color: Colors.grey.shade600)),
                    ],
                  ),
                ),
                IconButton(
                  icon: Icon(isDark ? Icons.light_mode : Icons.dark_mode),
                  onPressed: () async {
                    themeNotifier.value = !themeNotifier.value;
                    final prefs = await SharedPreferences.getInstance();
                    await prefs.setBool('isDark', themeNotifier.value);
                  },
                ),
              ],
            ),
          ),
          // Location
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
              decoration: BoxDecoration(
                color: isDark ? Colors.grey.shade800 : Colors.grey.shade100,
                borderRadius: BorderRadius.circular(12),
              ),
              child: Row(
                children: [
                  const Icon(Icons.location_on_outlined, size: 18),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      _loadingLocation ? 'Updating...' : location,
                      style: const TextStyle(fontSize: 13),
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                  IconButton(
                    icon: const Icon(Icons.refresh, size: 18),
                    onPressed: _getCurrentLocation,
                    padding: EdgeInsets.zero,
                    constraints: const BoxConstraints(),
                  ),
                ],
              ),
            ),
          ),
          // Banner Carousel
          SizedBox(
            height: 180,
            child: Stack(
              alignment: Alignment.bottomCenter,
              children: [
                PageView.builder(
                  controller: _bannerController,
                  onPageChanged: (index) => setState(() => _currentBanner = index),
                  itemCount: bannerImages.length,
                  itemBuilder: (context, index) => ClipRRect(
                    borderRadius: BorderRadius.circular(16),
                    child: Image.network(
                      bannerImages[index],
                      fit: BoxFit.cover,
                      width: double.infinity,
                      errorBuilder: (_, __, ___) => Container(color: Colors.grey),
                    ),
                  ),
                ),
                Positioned(
                  bottom: 8,
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: List.generate(
                      bannerImages.length,
                      (index) => AnimatedContainer(
                        duration: const Duration(milliseconds: 200),
                        margin: const EdgeInsets.symmetric(horizontal: 4),
                        width: _currentBanner == index ? 20 : 8,
                        height: 8,
                        decoration: BoxDecoration(
                          color: _currentBanner == index ? const Color(0xFF0097A7) : Colors.grey.withOpacity(0.6),
                          borderRadius: BorderRadius.circular(4),
                        ),
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 20),
          // BGMI UC Section
          _buildProductSection('BGMI UC', _ucProducts, isDark),
          const SizedBox(height: 20),
          // BGMI Popularity Section
          _buildProductSection('BGMI Popularity', _popularityProducts, isDark),
          const SizedBox(height: 20),
          // Contact Card
          Card(
            margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
            child: ListTile(
              leading: const Icon(Icons.headset_mic, color: Color(0xFF0097A7)),
              title: const Text('Contact Us'),
              subtitle: const Text('24/7 Support - Dream Store'),
              trailing: const Icon(Icons.chevron_right),
              onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const ContactScreen())),
            ),
          ),
          const SizedBox(height: 20),
        ],
      ),
    );
  }

  Widget _buildProductSection(String title, List<GameProduct> products, bool isDark) {
    if (products.isEmpty) return const SizedBox.shrink();
    final isUc = title == 'BGMI UC';
    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(title, style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
              TextButton(
                onPressed: () {
                  if (isUc) {
                    Navigator.push(
                      context,
                      MaterialPageRoute(builder: (_) => UcPackagesScreen(initialProducts: products)),
                    );
                  } else {
                    Navigator.push(
                      context,
                      MaterialPageRoute(builder: (_) => PopularityPackagesScreen(initialProducts: products)),
                    );
                  }
                },
                child: const Text('View All >', style: TextStyle(color: Color(0xFF0097A7))),
              ),
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
                onTap: () {
                  if (isUc) {
                    Navigator.push(
                      context,
                      MaterialPageRoute(builder: (_) => UcPackagesScreen(initialProducts: products)),
                    );
                  } else {
                    Navigator.push(
                      context,
                      MaterialPageRoute(builder: (_) => PopularityPackagesScreen(initialProducts: products)),
                    );
                  }
                },
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
                      Text(
                        '${pkg.amount} ${isUc ? 'UC' : 'pts'}',
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                          color: isUc ? const Color(0xFF0097A7) : Colors.orange,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text('₹${pkg.price}', style: const TextStyle(fontSize: 14)),
                    ],
                  ),
                ),
              );
            },
          ),
        ),
      ],
    );
  }
}

// Placeholder ContactScreen (create if missing)
class ContactScreen extends StatelessWidget {
  const ContactScreen({super.key});
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Contact Us'), centerTitle: true),
      body: const Center(child: Text('Contact info here')),
    );
  }
}
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
    'https://picsum.photos/id/1015/800/400',
    'https://picsum.photos/id/1018/800/400',
    'https://picsum.photos/id/104/800/400',
  ];
  final PageController _bannerController = PageController();
  int _currentBanner = 0;
  Timer? _bannerTimer;

  // Brand Color
  final Color primaryColor = const Color(0xFF0097A7);

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
    _bannerTimer = Timer.periodic(const Duration(seconds: 4), (timer) {
      if (_bannerController.hasClients) {
        final nextPage = (_currentBanner + 1) % bannerImages.length;
        _bannerController.animateToPage(
          nextPage,
          duration: const Duration(milliseconds: 600),
          curve: Curves.fastOutSlowIn,
        );
      }
    });
  }

  Future<void> _getCurrentLocation() async {
    setState(() => _loadingLocation = true);
    try {
      LocationPermission permission = await Geolocator.requestPermission();
      if (permission != LocationPermission.denied) {
        Position position = await Geolocator.getCurrentPosition(
            desiredAccuracy: LocationAccuracy.best);
        List<Placemark> placemarks = await placemarkFromCoordinates(
            position.latitude, position.longitude);
        if (placemarks.isNotEmpty) {
          setState(() => location =
              '${placemarks[0].locality ?? ''}, ${placemarks[0].subAdministrativeArea ?? ''}');
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
    // Simulated fetch or actual Supabase fetch
    try {
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
        if (item['type'] == 'uc') {
          uc.add(product);
        } else {
          pop.add(product);
        }
      }
      setState(() {
        _ucProducts = uc;
        _popularityProducts = pop;
        _loadingProducts = false;
      });
    } catch (e) {
      setState(() => _loadingProducts = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    
    // iOS System Background Colors
    final bgColor = isDark ? Colors.black : const Color(0xFFF2F2F7);

    return Scaffold(
      backgroundColor: bgColor,
      body: IndexedStack(
        index: _currentIndex,
        children: [
          _loadingProducts
              ? const Center(child: CupertinoActivityIndicator(radius: 16))
              : _buildHomeContent(isDark),
          const ChatListScreen(),
          const RedeemScreen(),
          const OrdersScreen(),
          const ProfileScreen(),
        ],
      ),
      bottomNavigationBar: Container(
        decoration: BoxDecoration(
          color: isDark ? const Color(0xFF1C1C1E) : Colors.white,
          border: Border(
            top: BorderSide(
              color: isDark ? Colors.white10 : Colors.black.withOpacity(0.05),
              width: 0.5,
            ),
          ),
        ),
        child: SafeArea(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 8.0, vertical: 4),
            child: BottomNavigationBar(
              elevation: 0,
              backgroundColor: Colors.transparent,
              type: BottomNavigationBarType.fixed,
              currentIndex: _currentIndex,
              onTap: (index) => setState(() => _currentIndex = index),
              selectedItemColor: primaryColor,
              unselectedItemColor: Colors.grey.shade500,
              selectedFontSize: 11,
              unselectedFontSize: 11,
              selectedLabelStyle: const TextStyle(fontWeight: FontWeight.w600),
              items: const [
                BottomNavigationBarItem(
                  icon: Padding(
                    padding: EdgeInsets.only(bottom: 4),
                    child: Icon(CupertinoIcons.house_fill),
                  ),
                  activeIcon: Padding(
                    padding: EdgeInsets.only(bottom: 4),
                    child: Icon(CupertinoIcons.house_fill),
                  ),
                  label: 'Home',
                ),
                BottomNavigationBarItem(
                  icon: Padding(
                    padding: EdgeInsets.only(bottom: 4),
                    child: Icon(CupertinoIcons.chat_bubble_2),
                  ),
                  activeIcon: Padding(
                    padding: EdgeInsets.only(bottom: 4),
                    child: Icon(CupertinoIcons.chat_bubble_2_fill),
                  ),
                  label: 'Chat',
                ),
                BottomNavigationBarItem(
                  icon: Padding(
                    padding: EdgeInsets.only(bottom: 4),
                    child: Icon(CupertinoIcons.gift),
                  ),
                  activeIcon: Padding(
                    padding: EdgeInsets.only(bottom: 4),
                    child: Icon(CupertinoIcons.gift_fill),
                  ),
                  label: 'Redeem',
                ),
                BottomNavigationBarItem(
                  icon: Padding(
                    padding: EdgeInsets.only(bottom: 4),
                    child: Icon(CupertinoIcons.doc_text),
                  ),
                  activeIcon: Padding(
                    padding: EdgeInsets.only(bottom: 4),
                    child: Icon(CupertinoIcons.doc_text_fill),
                  ),
                  label: 'Orders',
                ),
                BottomNavigationBarItem(
                  icon: Padding(
                    padding: EdgeInsets.only(bottom: 4),
                    child: Icon(CupertinoIcons.person_crop_circle),
                  ),
                  activeIcon: Padding(
                    padding: EdgeInsets.only(bottom: 4),
                    child: Icon(CupertinoIcons.person_crop_circle_fill),
                  ),
                  label: 'Profile',
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildHomeContent(bool isDark) {
    return SafeArea(
      bottom: false,
      child: SingleChildScrollView(
        physics: const BouncingScrollPhysics(), // Important for iOS feel
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const SizedBox(height: 10),
            // Custom Premium Header
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
              child: Row(
                children: [
                  Container(
                    width: 48,
                    height: 48,
                    decoration: BoxDecoration(
                      color: primaryColor.withOpacity(0.15),
                      borderRadius: BorderRadius.circular(14), // Squircle
                    ),
                    child: Icon(CupertinoIcons.game_controller_solid,
                        color: primaryColor, size: 26),
                  ),
                  const SizedBox(width: 14),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Dream Store',
                          style: TextStyle(
                            fontSize: 22,
                            fontWeight: FontWeight.w800,
                            letterSpacing: -0.5,
                            color: isDark ? Colors.white : Colors.black87,
                          ),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          'Premium Gaming Needs',
                          style: TextStyle(
                            fontSize: 13,
                            fontWeight: FontWeight.w500,
                            color: Colors.grey.shade500,
                          ),
                        ),
                      ],
                    ),
                  ),
                  GestureDetector(
                    onTap: () async {
                      themeNotifier.value = !themeNotifier.value;
                      final prefs = await SharedPreferences.getInstance();
                      await prefs.setBool('isDark', themeNotifier.value);
                    },
                    child: Container(
                      padding: const EdgeInsets.all(10),
                      decoration: BoxDecoration(
                        color: isDark ? Colors.grey.shade900 : Colors.white,
                        shape: BoxShape.circle,
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withOpacity(0.04),
                            blurRadius: 10,
                            offset: const Offset(0, 4),
                          )
                        ],
                      ),
                      child: Icon(
                        isDark ? CupertinoIcons.sun_max_fill : CupertinoIcons.moon_stars_fill,
                        size: 20,
                        color: isDark ? Colors.amber : primaryColor,
                      ),
                    ),
                  ),
                ],
              ),
            ),
            
            // Location Pill (Sleek iOS style)
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                decoration: BoxDecoration(
                  color: isDark ? const Color(0xFF1C1C1E) : Colors.white,
                  borderRadius: BorderRadius.circular(30),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.03),
                      blurRadius: 8,
                      offset: const Offset(0, 2),
                    )
                  ],
                ),
                child: Row(
                  children: [
                    Icon(CupertinoIcons.location_solid, 
                        size: 18, color: primaryColor.withOpacity(0.8)),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Text(
                        _loadingLocation ? 'Detecting your location...' : location,
                        style: TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.w500,
                          color: isDark ? Colors.grey.shade300 : Colors.grey.shade700,
                        ),
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                    GestureDetector(
                      onTap: _getCurrentLocation,
                      child: _loadingLocation 
                        ? const SizedBox(
                            width: 16, 
                            height: 16, 
                            child: CupertinoActivityIndicator(radius: 8))
                        : Icon(CupertinoIcons.arrow_2_circlepath, 
                            size: 18, color: Colors.grey.shade500),
                    ),
                  ],
                ),
              ),
            ),

            const SizedBox(height: 10),

            // Banner Carousel
            SizedBox(
              height: 170,
              child: Stack(
                alignment: Alignment.bottomCenter,
                children: [
                  PageView.builder(
                    controller: _bannerController,
                    physics: const BouncingScrollPhysics(),
                    onPageChanged: (index) => setState(() => _currentBanner = index),
                    itemCount: bannerImages.length,
                    itemBuilder: (context, index) => Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 20),
                      child: Container(
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(20),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withOpacity(0.08),
                              blurRadius: 15,
                              offset: const Offset(0, 8),
                            )
                          ],
                        ),
                        child: ClipRRect(
                          borderRadius: BorderRadius.circular(20),
                          child: Image.network(
                            bannerImages[index],
                            fit: BoxFit.cover,
                            width: double.infinity,
                            errorBuilder: (_, __, ___) => Container(
                                color: isDark ? Colors.grey.shade800 : Colors.grey.shade300),
                          ),
                        ),
                      ),
                    ),
                  ),
                  Positioned(
                    bottom: 12,
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
                      decoration: BoxDecoration(
                        color: Colors.black.withOpacity(0.3),
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: List.generate(
                          bannerImages.length,
                          (index) => AnimatedContainer(
                            duration: const Duration(milliseconds: 300),
                            margin: const EdgeInsets.symmetric(horizontal: 3),
                            width: _currentBanner == index ? 16 : 6,
                            height: 6,
                            decoration: BoxDecoration(
                              color: _currentBanner == index ? Colors.white : Colors.white54,
                              borderRadius: BorderRadius.circular(10),
                            ),
                          ),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 28),

            // BGMI UC Section
            _buildProductSection('BGMI UC', _ucProducts, isDark),
            
            const SizedBox(height: 24),
            
            // BGMI Popularity Section
            _buildProductSection('BGMI Popularity', _popularityProducts, isDark),
            
            const SizedBox(height: 24),

            // Contact Card (iOS Grouped Style)
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              child: Container(
                decoration: BoxDecoration(
                  color: isDark ? const Color(0xFF1C1C1E) : Colors.white,
                  borderRadius: BorderRadius.circular(20),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.03),
                      blurRadius: 10,
                      offset: const Offset(0, 4),
                    )
                  ],
                ),
                child: Material(
                  color: Colors.transparent,
                  child: InkWell(
                    borderRadius: BorderRadius.circular(20),
                    onTap: () => Navigator.push(context, 
                        CupertinoPageRoute(builder: (_) => const ContactScreen())),
                    child: Padding(
                      padding: const EdgeInsets.all(16),
                      child: Row(
                        children: [
                          Container(
                            padding: const EdgeInsets.all(10),
                            decoration: BoxDecoration(
                              color: primaryColor.withOpacity(0.1),
                              shape: BoxShape.circle,
                            ),
                            child: Icon(CupertinoIcons.headphones, color: primaryColor),
                          ),
                          const SizedBox(width: 16),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  '24/7 Premium Support',
                                  style: TextStyle(
                                    fontSize: 16,
                                    fontWeight: FontWeight.w600,
                                    color: isDark ? Colors.white : Colors.black87,
                                  ),
                                ),
                                const SizedBox(height: 4),
                                Text(
                                  'Get help with your orders anytime',
                                  style: TextStyle(
                                    fontSize: 13,
                                    color: Colors.grey.shade500,
                                  ),
                                ),
                              ],
                            ),
                          ),
                          Icon(CupertinoIcons.chevron_forward, 
                              color: Colors.grey.shade400, size: 20),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
            ),
            const SizedBox(height: 40),
          ],
        ),
      ),
    );
  }

  Widget _buildProductSection(String title, List<GameProduct> products, bool isDark) {
    if (products.isEmpty) return const SizedBox.shrink();
    final isUc = title == 'BGMI UC';
    
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 20),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text(
                title, 
                style: TextStyle(
                  fontSize: 20, 
                  fontWeight: FontWeight.w700,
                  letterSpacing: -0.5,
                  color: isDark ? Colors.white : Colors.black87,
                )
              ),
              GestureDetector(
                onTap: () {
                  final screen = isUc 
                      ? UcPackagesScreen(initialProducts: products)
                      : PopularityPackagesScreen(initialProducts: products);
                  Navigator.push(context, CupertinoPageRoute(builder: (_) => screen));
                },
                child: Text(
                  'See All', 
                  style: TextStyle(
                    fontSize: 14, 
                    fontWeight: FontWeight.w600, 
                    color: primaryColor
                  )
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 16),
        SizedBox(
          height: 145,
          child: ListView.builder(
            physics: const BouncingScrollPhysics(),
            scrollDirection: Axis.horizontal,
            padding: const EdgeInsets.symmetric(horizontal: 14),
            itemCount: products.length,
            itemBuilder: (context, index) {
              final pkg = products[index];
              return GestureDetector(
                onTap: () {
                  final screen = isUc 
                      ? UcPackagesScreen(initialProducts: products)
                      : PopularityPackagesScreen(initialProducts: products);
                  Navigator.push(context, CupertinoPageRoute(builder: (_) => screen));
                },
                child: Container(
                  width: 140,
                  margin: const EdgeInsets.symmetric(horizontal: 6, vertical: 4),
                  decoration: BoxDecoration(
                    color: isDark ? const Color(0xFF1C1C1E) : Colors.white,
                    borderRadius: BorderRadius.circular(20),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.04),
                        blurRadius: 10,
                        offset: const Offset(0, 4),
                      )
                    ],
                  ),
                  child: Stack(
                    children: [
                      Padding(
                        padding: const EdgeInsets.all(16),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                              decoration: BoxDecoration(
                                color: isDark ? Colors.grey.shade800 : const Color(0xFFF2F2F7),
                                borderRadius: BorderRadius.circular(8),
                              ),
                              child: Text(
                                pkg.name, 
                                style: TextStyle(
                                  fontSize: 11,
                                  fontWeight: FontWeight.w600,
                                  color: isDark ? Colors.grey.shade300 : Colors.grey.shade700,
                                ),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                            const Spacer(),
                            Row(
                              crossAxisAlignment: CrossAxisAlignment.end,
                              children: [
                                Text(
                                  '${pkg.amount}',
                                  style: TextStyle(
                                    fontSize: 22,
                                    fontWeight: FontWeight.w800,
                                    letterSpacing: -1,
                                    color: isUc ? primaryColor : Colors.orange.shade600,
                                  ),
                                ),
                                const SizedBox(width: 4),
                                Padding(
                                  padding: const EdgeInsets.only(bottom: 3),
                                  child: Text(
                                    isUc ? 'UC' : 'pts',
                                    style: TextStyle(
                                      fontSize: 12,
                                      fontWeight: FontWeight.w600,
                                      color: isUc ? primaryColor : Colors.orange.shade600,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 4),
                            Text(
                              '₹${pkg.price}', 
                              style: TextStyle(
                                fontSize: 16, 
                                fontWeight: FontWeight.w700,
                                color: isDark ? Colors.white : Colors.black87,
                              ),
                            ),
                          ],
                        ),
                      ),
                      // Optional: A subtle gradient or icon overlay in the corner could go here
                      Positioned(
                        right: -10,
                        bottom: -10,
                        child: Icon(
                          isUc ? CupertinoIcons.money_dollar_circle_fill : CupertinoIcons.flame_fill,
                          size: 70,
                          color: (isUc ? primaryColor : Colors.orange).withOpacity(0.05),
                        ),
                      )
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
      appBar: CupertinoNavigationBar(
        middle: const Text('Contact Us'),
        backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      ),
      body: const Center(child: Text('Premium Contact Support')),
    );
  }
}

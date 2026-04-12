import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/services.dart';
import 'package:geolocator/geolocator.dart';
import 'package:geocoding/geocoding.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../main.dart';
import '../supabase_config.dart';
import '../models/game_product.dart';
import 'uc_packages_screen.dart';
import 'popularity_packages_screen.dart';
import 'contact_screen.dart';   // ✅ Real ContactScreen import
import 'orders_screen.dart';
import 'profile_screen.dart';
import 'chat_list_screen.dart';
import 'redeem_screen.dart';

// ════════════════════════════════════════════════════════════════════════════
//  HomeScreen — Fully Improved | Supabase Connected | All Features Working ✅
// ════════════════════════════════════════════════════════════════════════════

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen>
    with SingleTickerProviderStateMixin {
  // ── Nav ───────────────────────────────────────────────────────────────────
  int _currentIndex = 0;

  // ── Theme ─────────────────────────────────────────────────────────────────
  final Color primaryColor = const Color(0xFF0097A7);

  // ── Location ──────────────────────────────────────────────────────────────
  String _location = 'Detecting location…';
  bool _loadingLocation = true;

  // ── Products ──────────────────────────────────────────────────────────────
  List<GameProduct> _ucProducts = [];
  List<GameProduct> _popularityProducts = [];
  bool _loadingProducts = true;
  bool _hasProductError = false;

  // ── Banner Carousel ───────────────────────────────────────────────────────
  final List<Map<String, String>> _banners = [
    {
      'url': 'https://picsum.photos/id/1015/800/400',
      'label': '🎮 Top Up UC Instantly',
    },
    {
      'url': 'https://picsum.photos/id/1018/800/400',
      'label': '🔥 New Popularity Packs',
    },
    {
      'url': 'https://picsum.photos/id/104/800/400',
      'label': '⚡ 24/7 Premium Support',
    },
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

  // ══════════════════════════════════════════════════════════════════════════
  //  BANNER AUTO-PLAY
  // ══════════════════════════════════════════════════════════════════════════

  void _startBannerAutoPlay() {
    _bannerTimer = Timer.periodic(const Duration(seconds: 4), (_) {
      if (!mounted || !_bannerController.hasClients) return;
      final next = (_currentBanner + 1) % _banners.length;
      _bannerController.animateToPage(
        next,
        duration: const Duration(milliseconds: 600),
        curve: Curves.fastOutSlowIn,
      );
    });
  }

  // ══════════════════════════════════════════════════════════════════════════
  //  LOCATION
  // ══════════════════════════════════════════════════════════════════════════

  Future<void> _getCurrentLocation() async {
    if (!mounted) return;
    setState(() => _loadingLocation = true);
    try {
      // Check service enabled
      final serviceEnabled = await Geolocator.isLocationServiceEnabled();
      if (!serviceEnabled) {
        if (mounted) setState(() => _location = 'Location service off');
        return;
      }

      LocationPermission permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
      }
      if (permission == LocationPermission.deniedForever ||
          permission == LocationPermission.denied) {
        if (mounted) setState(() => _location = 'Location permission denied');
        return;
      }

      final position = await Geolocator.getCurrentPosition(
        desiredAccuracy: LocationAccuracy.medium,
        timeLimit: const Duration(seconds: 10),
      );

      final placemarks = await placemarkFromCoordinates(
        position.latitude,
        position.longitude,
      );

      if (mounted && placemarks.isNotEmpty) {
        final p = placemarks.first;
        final city = p.locality ?? p.subAdministrativeArea ?? '';
        final state = p.administrativeArea ?? '';
        setState(() =>
            _location = [city, state].where((s) => s.isNotEmpty).join(', '));
      }
    } catch (_) {
      if (mounted) setState(() => _location = 'Location unavailable');
    } finally {
      if (mounted) setState(() => _loadingLocation = false);
    }
  }

  // ══════════════════════════════════════════════════════════════════════════
  //  SUPABASE — FETCH PRODUCTS
  // ══════════════════════════════════════════════════════════════════════════

  Future<void> _fetchProducts() async {
    if (!mounted) return;
    setState(() {
      _loadingProducts = true;
      _hasProductError = false;
    });

    try {
      final response = await SupabaseConfig.client
          .from('products')
          .select()
          .order('price', ascending: true); // Cheapest first

      final List<dynamic> data = response as List<dynamic>;
      final uc = <GameProduct>[];
      final pop = <GameProduct>[];

      for (final item in data) {
        final product = GameProduct(
          id: item['id']?.toString() ?? '',
          name: item['name']?.toString() ?? '',
          type: item['type']?.toString() ?? '',
          amount: (item['amount'] as num?)?.toInt() ?? 0,
          price: (item['price'] as num?)?.toDouble() ?? 0.0,
          bonus: (item['bonus'] as num?)?.toInt() ?? 0,
        );
        if (item['type'] == 'uc') {
          uc.add(product);
        } else {
          pop.add(product);
        }
      }

      if (mounted) {
        setState(() {
          _ucProducts = uc;
          _popularityProducts = pop;
          _loadingProducts = false;
        });
      }
    } catch (e) {
      debugPrint('[Supabase Products Error] $e');
      if (mounted) {
        setState(() {
          _loadingProducts = false;
          _hasProductError = true;
        });
      }
    }
  }

  // ══════════════════════════════════════════════════════════════════════════
  //  BUILD
  // ══════════════════════════════════════════════════════════════════════════

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final bgColor = isDark ? Colors.black : const Color(0xFFF2F2F7);
    final navBarColor = isDark ? const Color(0xFF1C1C1E) : Colors.white;

    return AnnotatedRegion<SystemUiOverlayStyle>(
      value: isDark
          ? SystemUiOverlayStyle.light
          : SystemUiOverlayStyle.dark,
      child: Scaffold(
        backgroundColor: bgColor,
        body: IndexedStack(
          index: _currentIndex,
          children: [
            _buildHomeTab(isDark),
            const ChatListScreen(),
            const RedeemScreen(),
            const OrdersScreen(),
            const ProfileScreen(),
          ],
        ),
        bottomNavigationBar: _buildBottomNav(navBarColor, isDark),
      ),
    );
  }

  // ── Bottom Navigation Bar ─────────────────────────────────────────────────
  Widget _buildBottomNav(Color navBarColor, bool isDark) {
    return Container(
      decoration: BoxDecoration(
        color: navBarColor,
        border: Border(
          top: BorderSide(
            color: isDark ? Colors.white10 : Colors.black.withOpacity(0.06),
            width: 0.5,
          ),
        ),
      ),
      child: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
          child: BottomNavigationBar(
            elevation: 0,
            backgroundColor: Colors.transparent,
            type: BottomNavigationBarType.fixed,
            currentIndex: _currentIndex,
            onTap: (i) {
              if (i != _currentIndex) {
                HapticFeedback.selectionClick();
                setState(() => _currentIndex = i);
              }
            },
            selectedItemColor: primaryColor,
            unselectedItemColor: Colors.grey.shade500,
            selectedFontSize: 11,
            unselectedFontSize: 11,
            selectedLabelStyle:
                const TextStyle(fontWeight: FontWeight.w600),
            items: const [
              BottomNavigationBarItem(
                icon: Padding(
                  padding: EdgeInsets.only(bottom: 4),
                  child: Icon(CupertinoIcons.house),
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
    );
  }

  // ══════════════════════════════════════════════════════════════════════════
  //  HOME TAB CONTENT
  // ══════════════════════════════════════════════════════════════════════════

  Widget _buildHomeTab(bool isDark) {
    return SafeArea(
      bottom: false,
      child: RefreshIndicator(
        color: primaryColor,
        onRefresh: () async {
          HapticFeedback.mediumImpact();
          await Future.wait([_fetchProducts(), _getCurrentLocation()]);
        },
        child: _loadingProducts
            ? const Center(child: CupertinoActivityIndicator(radius: 16))
            : _hasProductError
                ? _buildErrorState(isDark)
                : _buildHomeContent(isDark),
      ),
    );
  }

  // ── Error State ───────────────────────────────────────────────────────────
  Widget _buildErrorState(bool isDark) {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(CupertinoIcons.wifi_slash,
              size: 52, color: Colors.grey.shade400),
          const SizedBox(height: 16),
          Text('Failed to load products',
              style: TextStyle(
                  fontSize: 17,
                  fontWeight: FontWeight.w600,
                  color: isDark ? Colors.white : Colors.black87)),
          const SizedBox(height: 8),
          Text('Pull down to refresh',
              style: TextStyle(fontSize: 14, color: Colors.grey.shade500)),
          const SizedBox(height: 24),
          CupertinoButton.filled(
            onPressed: _fetchProducts,
            child: const Text('Try Again'),
          ),
        ],
      ),
    );
  }

  // ── Main Home Content ─────────────────────────────────────────────────────
  Widget _buildHomeContent(bool isDark) {
    final cardColor = isDark ? const Color(0xFF1C1C1E) : Colors.white;

    return SingleChildScrollView(
      physics: const AlwaysScrollableScrollPhysics(
        parent: BouncingScrollPhysics(),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const SizedBox(height: 10),

          // ── Header ───────────────────────────────────────────────────────
          _buildHeader(isDark),

          // ── Location Pill ─────────────────────────────────────────────────
          _buildLocationPill(isDark),

          const SizedBox(height: 10),

          // ── Banner Carousel ───────────────────────────────────────────────
          _buildBannerCarousel(isDark),

          const SizedBox(height: 28),

          // ── UC Products ───────────────────────────────────────────────────
          if (_ucProducts.isNotEmpty)
            _buildProductSection('BGMI UC', _ucProducts, isDark),

          if (_ucProducts.isNotEmpty) const SizedBox(height: 24),

          // ── Popularity Products ───────────────────────────────────────────
          if (_popularityProducts.isNotEmpty)
            _buildProductSection(
                'BGMI Popularity', _popularityProducts, isDark),

          if (_popularityProducts.isNotEmpty) const SizedBox(height: 24),

          // ── Empty State ───────────────────────────────────────────────────
          if (_ucProducts.isEmpty && _popularityProducts.isEmpty)
            _buildEmptyProductsState(isDark),

          // ── Support Card (Navigates to ContactScreen) ─────────────────────
          _buildSupportCard(cardColor, isDark),

          const SizedBox(height: 40),
        ],
      ),
    );
  }

  // ── Header ────────────────────────────────────────────────────────────────
  Widget _buildHeader(bool isDark) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
      child: Row(
        children: [
          // App Logo
          Container(
            width: 48,
            height: 48,
            decoration: BoxDecoration(
              color: primaryColor.withOpacity(0.15),
              borderRadius: BorderRadius.circular(14),
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
          // Dark / Light Mode Toggle
          GestureDetector(
            onTap: () async {
              HapticFeedback.lightImpact();
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
                    color: Colors.black.withOpacity(0.05),
                    blurRadius: 10,
                    offset: const Offset(0, 4),
                  )
                ],
              ),
              child: Icon(
                isDark
                    ? CupertinoIcons.sun_max_fill
                    : CupertinoIcons.moon_stars_fill,
                size: 20,
                color: isDark ? Colors.amber : primaryColor,
              ),
            ),
          ),
        ],
      ),
    );
  }

  // ── Location Pill ─────────────────────────────────────────────────────────
  Widget _buildLocationPill(bool isDark) {
    return Padding(
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
                size: 16, color: primaryColor.withOpacity(0.8)),
            const SizedBox(width: 10),
            Expanded(
              child: Text(
                _location,
                style: TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w500,
                  color: isDark
                      ? Colors.grey.shade300
                      : Colors.grey.shade700,
                ),
                overflow: TextOverflow.ellipsis,
              ),
            ),
            const SizedBox(width: 8),
            GestureDetector(
              onTap: _getCurrentLocation,
              child: _loadingLocation
                  ? const SizedBox(
                      width: 16,
                      height: 16,
                      child: CupertinoActivityIndicator(radius: 8))
                  : Icon(CupertinoIcons.arrow_2_circlepath,
                      size: 16, color: Colors.grey.shade500),
            ),
          ],
        ),
      ),
    );
  }

  // ── Banner Carousel ───────────────────────────────────────────────────────
  Widget _buildBannerCarousel(bool isDark) {
    return SizedBox(
      height: 175,
      child: Stack(
        alignment: Alignment.bottomCenter,
        children: [
          PageView.builder(
            controller: _bannerController,
            physics: const BouncingScrollPhysics(),
            onPageChanged: (i) => setState(() => _currentBanner = i),
            itemCount: _banners.length,
            itemBuilder: (_, i) => Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              child: Container(
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(20),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.09),
                      blurRadius: 15,
                      offset: const Offset(0, 8),
                    )
                  ],
                ),
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(20),
                  child: Stack(
                    fit: StackFit.expand,
                    children: [
                      Image.network(
                        _banners[i]['url']!,
                        fit: BoxFit.cover,
                        errorBuilder: (_, __, ___) => Container(
                          color: isDark
                              ? Colors.grey.shade800
                              : Colors.grey.shade200,
                          child: const Center(
                              child: Icon(CupertinoIcons.photo,
                                  size: 32, color: Colors.grey)),
                        ),
                      ),
                      // Gradient overlay
                      Positioned(
                        bottom: 0,
                        left: 0,
                        right: 0,
                        child: Container(
                          padding: const EdgeInsets.fromLTRB(16, 24, 16, 14),
                          decoration: const BoxDecoration(
                            gradient: LinearGradient(
                              begin: Alignment.bottomCenter,
                              end: Alignment.topCenter,
                              colors: [
                                Colors.black54,
                                Colors.transparent,
                              ],
                            ),
                          ),
                          child: Text(
                            _banners[i]['label']!,
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 15,
                              fontWeight: FontWeight.w700,
                              shadows: [
                                Shadow(blurRadius: 4, color: Colors.black38)
                              ],
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
          // Dot Indicators
          Positioned(
            bottom: 10,
            right: 30,
            child: Row(
              children: List.generate(
                _banners.length,
                (i) => AnimatedContainer(
                  duration: const Duration(milliseconds: 300),
                  margin: const EdgeInsets.symmetric(horizontal: 3),
                  width: _currentBanner == i ? 18 : 6,
                  height: 6,
                  decoration: BoxDecoration(
                    color: _currentBanner == i
                        ? Colors.white
                        : Colors.white54,
                    borderRadius: BorderRadius.circular(10),
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  // ── Empty Products State ──────────────────────────────────────────────────
  Widget _buildEmptyProductsState(bool isDark) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 40, horizontal: 20),
      child: Center(
        child: Column(
          children: [
            Icon(CupertinoIcons.cube_box,
                size: 48, color: Colors.grey.shade400),
            const SizedBox(height: 12),
            Text(
              'No products available',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w600,
                color: isDark ? Colors.white70 : Colors.black54,
              ),
            ),
            const SizedBox(height: 6),
            Text(
              'Check back soon!',
              style:
                  TextStyle(fontSize: 13, color: Colors.grey.shade500),
            ),
          ],
        ),
      ),
    );
  }

  // ── Support Card → ContactScreen ✅ ───────────────────────────────────────
  Widget _buildSupportCard(Color cardColor, bool isDark) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20),
      child: Container(
        decoration: BoxDecoration(
          color: cardColor,
          borderRadius: BorderRadius.circular(20),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.04),
              blurRadius: 10,
              offset: const Offset(0, 4),
            )
          ],
        ),
        child: Material(
          color: Colors.transparent,
          borderRadius: BorderRadius.circular(20),
          child: InkWell(
            borderRadius: BorderRadius.circular(20),
            // ✅ Navigates to real ContactScreen from contact_screen.dart
            onTap: () {
              HapticFeedback.lightImpact();
              Navigator.push(
                context,
                CupertinoPageRoute(
                  builder: (_) => const ContactScreen(),
                ),
              );
            },
            child: Padding(
              padding: const EdgeInsets.all(18),
              child: Row(
                children: [
                  // Icon
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: primaryColor.withOpacity(0.12),
                      shape: BoxShape.circle,
                    ),
                    child: Icon(CupertinoIcons.headphones,
                        color: primaryColor, size: 24),
                  ),
                  const SizedBox(width: 16),
                  // Text
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
                  // Chevron
                  Container(
                    padding: const EdgeInsets.all(6),
                    decoration: BoxDecoration(
                      color: isDark
                          ? Colors.white.withOpacity(0.06)
                          : Colors.grey.shade100,
                      shape: BoxShape.circle,
                    ),
                    child: Icon(CupertinoIcons.chevron_forward,
                        color: Colors.grey.shade400, size: 16),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  // ══════════════════════════════════════════════════════════════════════════
  //  PRODUCT SECTION
  // ══════════════════════════════════════════════════════════════════════════

  Widget _buildProductSection(
      String title, List<GameProduct> products, bool isDark) {
    final isUc = title == 'BGMI UC';

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Section Header
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 20),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Row(
                children: [
                  Container(
                    width: 4,
                    height: 18,
                    decoration: BoxDecoration(
                      color: isUc ? primaryColor : Colors.orange.shade600,
                      borderRadius: BorderRadius.circular(2),
                    ),
                  ),
                  const SizedBox(width: 10),
                  Text(
                    title,
                    style: TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.w700,
                      letterSpacing: -0.5,
                      color: isDark ? Colors.white : Colors.black87,
                    ),
                  ),
                ],
              ),
              GestureDetector(
                onTap: () {
                  HapticFeedback.lightImpact();
                  final screen = isUc
                      ? UcPackagesScreen(initialProducts: products)
                      : PopularityPackagesScreen(initialProducts: products);
                  Navigator.push(
                      context, CupertinoPageRoute(builder: (_) => screen));
                },
                child: Row(
                  children: [
                    Text(
                      'See All',
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                        color: primaryColor,
                      ),
                    ),
                    const SizedBox(width: 2),
                    Icon(CupertinoIcons.chevron_right,
                        size: 14, color: primaryColor),
                  ],
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 16),

        // Product Cards Horizontal List
        SizedBox(
          height: 148,
          child: ListView.builder(
            physics: const BouncingScrollPhysics(),
            scrollDirection: Axis.horizontal,
            padding: const EdgeInsets.symmetric(horizontal: 14),
            itemCount: products.length,
            itemBuilder: (_, index) =>
                _buildProductCard(products[index], isUc, isDark, products),
          ),
        ),
      ],
    );
  }

  // ── Product Card ──────────────────────────────────────────────────────────
  Widget _buildProductCard(
    GameProduct pkg,
    bool isUc,
    bool isDark,
    List<GameProduct> allProducts,
  ) {
    final accentColor = isUc ? primaryColor : Colors.orange.shade600;

    return GestureDetector(
      onTap: () {
        HapticFeedback.lightImpact();
        final screen = isUc
            ? UcPackagesScreen(initialProducts: allProducts)
            : PopularityPackagesScreen(initialProducts: allProducts);
        Navigator.push(
            context, CupertinoPageRoute(builder: (_) => screen));
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
              padding: const EdgeInsets.all(14),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Package name badge
                  Container(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 8, vertical: 4),
                    decoration: BoxDecoration(
                      color: accentColor.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Text(
                      pkg.name,
                      style: TextStyle(
                        fontSize: 10,
                        fontWeight: FontWeight.w600,
                        color: accentColor,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                  const Spacer(),
                  // Amount
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
                      Text(
                        '${pkg.amount}',
                        style: TextStyle(
                          fontSize: 24,
                          fontWeight: FontWeight.w800,
                          letterSpacing: -1,
                          color: accentColor,
                        ),
                      ),
                      const SizedBox(width: 3),
                      Padding(
                        padding: const EdgeInsets.only(bottom: 3),
                        child: Text(
                          isUc ? 'UC' : 'pts',
                          style: TextStyle(
                            fontSize: 11,
                            fontWeight: FontWeight.w600,
                            color: accentColor,
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 2),
                  // Price
                  Text(
                    '₹${pkg.price % 1 == 0 ? pkg.price.toInt() : pkg.price}',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w700,
                      color: isDark ? Colors.white : Colors.black87,
                    ),
                  ),
                  // Bonus tag
                  if ((pkg.bonus ?? 0) > 0)
                    Padding(
                      padding: const EdgeInsets.only(top: 4),
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 6, vertical: 2),
                        decoration: BoxDecoration(
                          color: Colors.green.shade400.withOpacity(0.15),
                          borderRadius: BorderRadius.circular(6),
                        ),
                        child: Text(
                          '+${pkg.bonus} Bonus',
                          style: TextStyle(
                            fontSize: 10,
                            fontWeight: FontWeight.w600,
                            color: Colors.green.shade600,
                          ),
                        ),
                      ),
                    ),
                ],
              ),
            ),
            // Decorative background icon
            Positioned(
              right: -10,
              bottom: -10,
              child: Icon(
                isUc
                    ? CupertinoIcons.money_dollar_circle_fill
                    : CupertinoIcons.flame_fill,
                size: 70,
                color: accentColor.withOpacity(0.05),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

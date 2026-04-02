import 'package:flutter/material.dart';
import 'package:geolocator/geolocator.dart';
import 'package:geocoding/geocoding.dart';
import 'package:provider/provider.dart';
import '../models/product.dart';
import '../providers/cart_provider.dart';
import 'product_detail_screen.dart';
import 'cart_screen.dart';
import 'chat_screen.dart';
import 'profile_screen.dart';

List<Product> products = [
  Product(
    id: '1',
    name: 'Maruti Suzuki Swift',
    price: 436000,
    description: 'The Maruti Suzuki Swift is a popular hatchback known for its sporty design, fuel efficiency, and peppy engine.',
    imageUrl: 'https://picsum.photos/id/111/300/200',
    category: 'Hatchback',
  ),
  Product(
    id: '2',
    name: 'Hyundai i20',
    price: 520000,
    description: 'Premium hatchback with stylish design, feature-rich interior, and refined engine options.',
    imageUrl: 'https://picsum.photos/id/112/300/200',
    category: 'Hatchback',
  ),
  Product(
    id: '3',
    name: 'Honda City',
    price: 1100000,
    description: 'The Honda City is a class-leading sedan with a spacious cabin, comfortable ride, and reliable performance.',
    imageUrl: 'https://picsum.photos/id/113/300/200',
    category: 'Sedan',
  ),
  Product(
    id: '4',
    name: 'Mahindra Thar',
    price: 1350000,
    description: 'Rugged off-road SUV with iconic design, powerful engine, and unmatched capability.',
    imageUrl: 'https://picsum.photos/id/114/300/200',
    category: 'SUV',
  ),
  Product(
    id: '5',
    name: 'Tata Nexon',
    price: 820000,
    description: 'Compact SUV with bold design, 5-star safety rating, and excellent driving dynamics.',
    imageUrl: 'https://picsum.photos/id/115/300/200',
    category: 'SUV',
  ),
  Product(
    id: '6',
    name: 'Kia Seltos',
    price: 980000,
    description: 'Feature-packed compact SUV with striking looks, premium interior, and multiple engine choices.',
    imageUrl: 'https://picsum.photos/id/116/300/200',
    category: 'SUV',
  ),
];

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  int _currentIndex = 0;
  String location = 'Detecting location...';
  bool _loadingLocation = true;

  @override
  void initState() {
    super.initState();
    _getCurrentLocation();
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

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final screenWidth = MediaQuery.of(context).size.width;
    final crossAxisCount = screenWidth > 600 ? 3 : 2;

    return Scaffold(
      body: SafeArea(
        child: Column(
          children: [
            // Header
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              child: Row(
                children: [
                  CircleAvatar(backgroundColor: const Color(0xFF0097A7).withOpacity(0.2), child: const Icon(Icons.person, color: Color(0xFF0097A7))),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text('Hello, Shamir!', style: Theme.of(context).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold)),
                        Text('Welcome back', style: TextStyle(color: Colors.grey.shade600)),
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
                decoration: BoxDecoration(color: isDark ? Colors.grey.shade800 : Colors.grey.shade100, borderRadius: BorderRadius.circular(12)),
                child: Row(
                  children: [
                    const Icon(Icons.location_on_outlined, size: 18),
                    const SizedBox(width: 8),
                    Expanded(child: Text(_loadingLocation ? 'Updating...' : location, style: const TextStyle(fontSize: 13), overflow: TextOverflow.ellipsis)),
                    IconButton(icon: const Icon(Icons.refresh, size: 18), onPressed: _getCurrentLocation, padding: EdgeInsets.zero, constraints: const BoxConstraints()),
                  ],
                ),
              ),
            ),
            // Main content based on index
            Expanded(
              child: IndexedStack(
                index: _currentIndex,
                children: [
                  // Home - Product Grid
                  GridView.builder(
                    padding: const EdgeInsets.all(16),
                    gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                      crossAxisCount: crossAxisCount,
                      childAspectRatio: 0.75,
                      crossAxisSpacing: 12,
                      mainAxisSpacing: 12,
                    ),
                    itemCount: products.length,
                    itemBuilder: (context, index) {
                      final product = products[index];
                      return _ProductCard(product: product);
                    },
                  ),
                  // Chat
                  const ChatScreen(),
                  // Sell (placeholder)
                  const Center(child: Text('Sell Screen - Coming Soon')),
                  // Listings (placeholder)
                  const Center(child: Text('My Listings - Coming Soon')),
                  // Profile
                  const ProfileScreen(),
                ],
              ),
            ),
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
          BottomNavigationBarItem(icon: Icon(CupertinoIcons.add), label: 'Sell'),
          BottomNavigationBarItem(icon: Icon(CupertinoIcons.list_bullet), label: 'Listings'),
          BottomNavigationBarItem(icon: Icon(CupertinoIcons.person), label: 'Profile'),
        ],
      ),
    );
  }
}

class _ProductCard extends StatelessWidget {
  final Product product;
  const _ProductCard({required this.product});

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return GestureDetector(
      onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => ProductDetailScreen(product: product))),
      child: Container(
        decoration: BoxDecoration(
          color: isDark ? Colors.grey.shade800 : Colors.white,
          borderRadius: BorderRadius.circular(20),
          boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 8, offset: const Offset(0, 2))],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(
              child: ClipRRect(
                borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
                child: Image.network(product.imageUrl, fit: BoxFit.cover, width: double.infinity, errorBuilder: (_, __, ___) => Container(color: Colors.grey.shade200, child: const Icon(Icons.image_not_supported, size: 50))),
              ),
            ),
            Padding(
              padding: const EdgeInsets.all(10),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(product.name, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16), maxLines: 1, overflow: TextOverflow.ellipsis),
                  const SizedBox(height: 4),
                  Text('₹ ${product.price.toStringAsFixed(0)}', style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Color(0xFF0097A7))),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
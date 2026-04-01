import 'dart:io';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  // Get saved theme preference
  final prefs = await SharedPreferences.getInstance();
  final isDarkMode = prefs.getBool('isDarkMode') ?? false;

  runApp(MyApp(isDarkMode: isDarkMode));
}

// Global Notifier to change theme from anywhere
final ValueNotifier<bool> themeNotifier = ValueNotifier(false);

class MyApp extends StatefulWidget {
  final bool isDarkMode;
  const MyApp({super.key, required this.isDarkMode});

  @override
  State<MyApp> createState() => _MyAppState();
}

class _MyAppState extends State<MyApp> {
  @override
  void initState() {
    super.initState();
    themeNotifier.value = widget.isDarkMode;
  }

  @override
  Widget build(BuildContext context) {
    return ValueListenableBuilder<bool>(
      valueListenable: themeNotifier,
      builder: (context, isDark, child) {
        return MaterialApp(
          title: 'Share App',
          debugShowCheckedModeBanner: false,
          themeMode: isDark ? ThemeMode.dark : ThemeMode.light,
          
          // LIGHT THEME
          theme: ThemeData(
            primaryColor: const Color(0xFF6558F5),
            scaffoldBackgroundColor: const Color(0xFFF8F9FA),
            appBarTheme: const AppBarTheme(
              backgroundColor: Color(0xFFF8F9FA),
              foregroundColor: Colors.black,
              elevation: 0,
            ),
            colorScheme: ColorScheme.fromSeed(
              seedColor: const Color(0xFF6558F5),
              brightness: Brightness.light,
            ),
            useMaterial3: true,
          ),

          // DARK THEME
          darkTheme: ThemeData(
            primaryColor: const Color(0xFF6558F5),
            scaffoldBackgroundColor: const Color(0xFF121212),
            appBarTheme: const AppBarTheme(
              backgroundColor: Color(0xFF121212),
              foregroundColor: Colors.white,
              elevation: 0,
            ),
            colorScheme: ColorScheme.fromSeed(
              seedColor: const Color(0xFF6558F5),
              brightness: Brightness.dark,
            ),
            useMaterial3: true,
          ),
          home: const SplashScreen(),
        );
      },
    );
  }
}

// ==========================================
// 1. SPLASH SCREEN
// ==========================================
class SplashScreen extends StatelessWidget {
  const SplashScreen({super.key});

  @override
  Widget build(BuildContext context) {
    bool isDark = Theme.of(context).brightness == Brightness.dark;
    return Scaffold(
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Spacer(),
              Container(
                height: 200,
                decoration: BoxDecoration(
                  color: isDark ? Colors.grey.shade800 : Colors.grey.shade100,
                  shape: BoxShape.circle,
                ),
                child: const Center(
                  child: Icon(Icons.gamepad, size: 80, color: Color(0xFF6558F5)),
                ),
              ),
              const SizedBox(height: 40),
              Text(
                'Welcome To\nGame Store',
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 28,
                  fontWeight: FontWeight.bold,
                  color: isDark ? Colors.white : const Color(0xFF2D2D4A),
                ),
              ),
              const Spacer(),
              SizedBox(
                width: double.infinity,
                height: 55,
                child: ElevatedButton(
                  onPressed: () {
                    Navigator.pushReplacement(
                      context,
                      MaterialPageRoute(builder: (context) => const MainLayout()),
                    );
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF6558F5),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                  ),
                  child: const Text('Get Started', style: TextStyle(fontSize: 18, color: Colors.white, fontWeight: FontWeight.bold)),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// ==========================================
// MAIN LAYOUT (BOTTOM NAV BAR)
// ==========================================
class MainLayout extends StatefulWidget {
  const MainLayout({super.key});

  @override
  State<MainLayout> createState() => _MainLayoutState();
}

class _MainLayoutState extends State<MainLayout> {
  int _currentIndex = 0;
  final List<Widget> _screens = [const HomeScreen(), const UploadScreen()];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: _screens[_currentIndex],
      bottomNavigationBar: Container(
        decoration: const BoxDecoration(
          color: Color(0xFF6558F5),
          borderRadius: BorderRadius.only(topLeft: Radius.circular(20), topRight: Radius.circular(20)),
        ),
        child: BottomNavigationBar(
          backgroundColor: Colors.transparent,
          elevation: 0,
          selectedItemColor: Colors.white,
          unselectedItemColor: Colors.white54,
          currentIndex: _currentIndex,
          type: BottomNavigationBarType.fixed,
          onTap: (index) => setState(() => _currentIndex = index),
          items: const [
            BottomNavigationBarItem(icon: Icon(Icons.home_outlined), label: 'Home'),
            BottomNavigationBarItem(icon: Icon(Icons.cloud_upload_outlined), label: 'Upload'),
          ],
        ),
      ),
    );
  }
}

// ==========================================
// 2. HOME SCREEN (WITH BGMI PACKAGES)
// ==========================================
class HomeScreen extends StatelessWidget {
  const HomeScreen({super.key});

  // Toggle Theme Function
  void _toggleTheme() async {
    final prefs = await SharedPreferences.getInstance();
    themeNotifier.value = !themeNotifier.value;
    prefs.setBool('isDarkMode', themeNotifier.value);
  }

  // Show Package Details in Bottom Sheet
  void _showPackageBottomSheet(BuildContext context, String title, List<Map<String, String>> packages) {
    bool isDark = Theme.of(context).brightness == Brightness.dark;
    
    showModalBottomSheet(
      context: context,
      backgroundColor: isDark ? const Color(0xFF1E1E2C) : Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (context) {
        return Padding(
          padding: const EdgeInsets.all(20.0),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Center(
                child: Container(width: 50, height: 5, decoration: BoxDecoration(color: Colors.grey.shade400, borderRadius: BorderRadius.circular(10))),
              ),
              const SizedBox(height: 20),
              Text(title, style: const TextStyle(fontSize: 22, fontWeight: FontWeight.bold)),
              const SizedBox(height: 16),
              
              // List of Packages
              Expanded(
                child: ListView.builder(
                  shrinkWrap: true,
                  itemCount: packages.length,
                  itemBuilder: (context, index) {
                    final pkg = packages[index];
                    return Container(
                      margin: const EdgeInsets.only(bottom: 12),
                      decoration: BoxDecoration(
                        color: isDark ? const Color(0xFF2C2C3E) : const Color(0xFFF3E8FF),
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(color: const Color(0xFF6558F5).withOpacity(0.3)),
                      ),
                      child: ListTile(
                        leading: const Icon(Icons.local_fire_department, color: Color(0xFF6558F5), size: 30),
                        title: Text(pkg['amount']!, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                        subtitle: Text(pkg['price']!, style: TextStyle(color: Colors.grey.shade600)),
                        trailing: ElevatedButton(
                          onPressed: () {},
                          style: ElevatedButton.styleFrom(
                            backgroundColor: const Color(0xFF6558F5),
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                          ),
                          child: const Text('Buy', style: TextStyle(color: Colors.white)),
                        ),
                      ),
                    );
                  },
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    bool isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      appBar: AppBar(
        title: const Text('What Do You Want ...', style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
        leading: const Icon(Icons.menu),
        actions: [
          // Light/Dark Mode Toggle Icon
          IconButton(
            icon: Icon(isDark ? Icons.wb_sunny : Icons.nightlight_round),
            onPressed: _toggleTheme,
            color: isDark ? Colors.amber : Colors.black87,
          ),
          // Cart Icon
          const Padding(
            padding: EdgeInsets.only(right: 16.0),
            child: Icon(Icons.shopping_cart_outlined),
          ),
        ],
      ),
      body: GridView.count(
        padding: const EdgeInsets.all(16),
        crossAxisCount: 2,
        crossAxisSpacing: 16,
        mainAxisSpacing: 16,
        childAspectRatio: 0.8,
        children: [
          // BGMI Popularity Card
          _buildItemCard(
            context: context,
            title: 'BGMI\nPopularity',
            subtitle: 'Epic Win',
            icon: Icons.local_fire_department,
            isDark: isDark,
            onTap: () {
              _showPackageBottomSheet(context, 'BGMI Popularity Packages', [
                {'amount': '100K Popularity', 'price': '₹100'},
                {'amount': '500K Popularity', 'price': '₹450'},
                {'amount': '1M Popularity', 'price': '₹800'},
              ]);
            },
          ),
          // BGMI UC Card
          _buildItemCard(
            context: context,
            title: 'BGMI UC',
            subtitle: 'Top Up',
            icon: Icons.monetization_on,
            isDark: isDark,
            onTap: () {
              _showPackageBottomSheet(context, 'BGMI UC Packages', [
                {'amount': '60 UC', 'price': '₹75'},
                {'amount': '325 UC', 'price': '₹380'},
                {'amount': '660 UC', 'price': '₹750'},
              ]);
            },
          ),
          // FreeFire Card
          _buildItemCard(context: context, title: 'FreeFire Shot', subtitle: 'Booyah!', icon: Icons.sports_esports, isDark: isDark, onTap: () {}),
          // COD Mobile Card
          _buildItemCard(context: context, title: 'COD Mobile', subtitle: 'MVP', icon: Icons.stars, isDark: isDark, onTap: () {}),
        ],
      ),
    );
  }

  // Exact Card shape matching your screenshot
  Widget _buildItemCard({
    required BuildContext context,
    required String title,
    required String subtitle,
    required IconData icon,
    required bool isDark,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        decoration: BoxDecoration(
          color: isDark ? const Color(0xFF2C2C3E) : const Color(0xFFF4EBFF), // Matching screenshot background
          borderRadius: BorderRadius.circular(24),
        ),
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Align(
                alignment: Alignment.topRight,
                child: Icon(Icons.favorite_border, color: const Color(0xFF9E77ED), size: 24),
              ),
              Expanded(
                child: Center(
                  child: Icon(icon, size: 65, color: const Color(0xFF6558F5)),
                ),
              ),
              Text(
                title,
                style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16, height: 1.2),
              ),
              const SizedBox(height: 4),
              Text(
                subtitle,
                style: TextStyle(color: isDark ? Colors.grey.shade400 : Colors.grey.shade600, fontSize: 13),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// ==========================================
// 3. UPLOAD SCREEN
// ==========================================
class UploadScreen extends StatefulWidget {
  const UploadScreen({super.key});

  @override
  State<UploadScreen> createState() => _UploadScreenState();
}

class _UploadScreenState extends State<UploadScreen> {
  File? _imageFile;
  final ImagePicker _picker = ImagePicker();

  Future<void> _pickImage() async {
    final XFile? pickedFile = await _picker.pickImage(source: ImageSource.gallery);
    if (pickedFile != null) {
      setState(() {
        _imageFile = File(pickedFile.path);
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    bool isDark = Theme.of(context).brightness == Brightness.dark;
    
    return Scaffold(
      appBar: AppBar(
        backgroundColor: const Color(0xFF6558F5),
        title: const Text('Upload Screenshot', style: TextStyle(color: Colors.white, fontSize: 18)),
        centerTitle: true,
        iconTheme: const IconThemeData(color: Colors.white),
      ),
      body: SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              const SizedBox(height: 20),
              Text(
                'Upload Your Game Screenshot\nTo Share With Friends',
                textAlign: TextAlign.center,
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: isDark ? Colors.white : Colors.black),
              ),
              const SizedBox(height: 40),
              
              GestureDetector(
                onTap: _pickImage,
                child: Container(
                  height: 300,
                  width: double.infinity,
                  decoration: BoxDecoration(
                    color: isDark ? const Color(0xFF2C2C3E) : const Color(0xFFFFF0E6),
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(color: const Color(0xFF6558F5).withOpacity(0.5), width: 2, style: BorderStyle.dash),
                  ),
                  child: _imageFile != null
                      ? ClipRRect(
                          borderRadius: BorderRadius.circular(14),
                          child: Image.file(_imageFile!, fit: BoxFit.cover),
                        )
                      : Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            const Icon(Icons.cloud_upload_outlined, size: 60, color: Color(0xFF6558F5)),
                            const SizedBox(height: 16),
                            Text('Tap to Upload Screenshot', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16, color: isDark ? Colors.white : Colors.black)),
                            const SizedBox(height: 8),
                            Text('Browse Gallery', style: TextStyle(color: Colors.grey.shade600, fontSize: 12)),
                          ],
                        ),
                ),
              ),
              const SizedBox(height: 40),
              
              SizedBox(
                width: double.infinity,
                height: 55,
                child: ElevatedButton(
                  onPressed: _pickImage,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF6558F5),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  ),
                  child: const Text('Browse Files', style: TextStyle(fontSize: 16, color: Colors.white, fontWeight: FontWeight.bold)),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
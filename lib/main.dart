import 'dart:io';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  final prefs = await SharedPreferences.getInstance();
  final isDarkMode = prefs.getBool('isDarkMode') ?? false;
  runApp(MyApp(isDarkMode: isDarkMode));
}

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
          title: 'Game Store',
          debugShowCheckedModeBanner: false,
          themeMode: isDark ? ThemeMode.dark : ThemeMode.light,
          theme: ThemeData(
            primaryColor: const Color(0xFF6558F5),
            scaffoldBackgroundColor: const Color(0xFFF8F9FA),
            appBarTheme: const AppBarTheme(backgroundColor: Color(0xFFF8F9FA), foregroundColor: Colors.black, elevation: 0),
            colorScheme: ColorScheme.fromSeed(seedColor: const Color(0xFF6558F5), brightness: Brightness.light),
            useMaterial3: true,
          ),
          darkTheme: ThemeData(
            primaryColor: const Color(0xFF6558F5),
            scaffoldBackgroundColor: const Color(0xFF121212),
            appBarTheme: const AppBarTheme(backgroundColor: Color(0xFF121212), foregroundColor: Colors.white, elevation: 0),
            colorScheme: ColorScheme.fromSeed(seedColor: const Color(0xFF6558F5), brightness: Brightness.dark),
            useMaterial3: true,
          ),
          home: const SplashScreen(),
        );
      },
    );
  }
}

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
              Container(height: 200, decoration: BoxDecoration(color: isDark ? Colors.grey.shade800 : Colors.grey.shade100, shape: BoxShape.circle), child: const Center(child: Icon(Icons.gamepad, size: 80, color: Color(0xFF6558F5)))),
              const SizedBox(height: 40),
              Text('Welcome To\nGame Store', textAlign: TextAlign.center, style: TextStyle(fontSize: 28, fontWeight: FontWeight.bold, color: isDark ? Colors.white : const Color(0xFF2D2D4A))),
              const Spacer(),
              SizedBox(width: double.infinity, height: 55, child: ElevatedButton(onPressed: () => Navigator.pushReplacement(context, MaterialPageRoute(builder: (context) => const MainLayout())), style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFF6558F5), shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16))), child: const Text('Get Started', style: TextStyle(fontSize: 18, color: Colors.white, fontWeight: FontWeight.bold)))),
            ],
          ),
        ),
      ),
    );
  }
}

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
        decoration: const BoxDecoration(color: Color(0xFF6558F5), borderRadius: BorderRadius.only(topLeft: Radius.circular(20), topRight: Radius.circular(20))),
        child: BottomNavigationBar(
          backgroundColor: Colors.transparent, elevation: 0, selectedItemColor: Colors.white, unselectedItemColor: Colors.white54, currentIndex: _currentIndex, type: BottomNavigationBarType.fixed,
          onTap: (index) => setState(() => _currentIndex = index),
          items: const [BottomNavigationBarItem(icon: Icon(Icons.home_outlined), label: 'Home'), BottomNavigationBarItem(icon: Icon(Icons.cloud_upload_outlined), label: 'Upload')],
        ),
      ),
    );
  }
}

class HomeScreen extends StatelessWidget {
  const HomeScreen({super.key});
  void _toggleTheme() async {
    final prefs = await SharedPreferences.getInstance();
    themeNotifier.value = !themeNotifier.value;
    prefs.setBool('isDarkMode', themeNotifier.value);
  }

  void _showPackageBottomSheet(BuildContext context, String title, List<Map<String, String>> packages) {
    bool isDark = Theme.of(context).brightness == Brightness.dark;
    showModalBottomSheet(
      context: context, backgroundColor: isDark ? const Color(0xFF1E1E2C) : Colors.white,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(24))),
      builder: (context) => Padding(
        padding: const EdgeInsets.all(20.0),
        child: Column(mainAxisSize: MainAxisSize.min, children: [
          Container(width: 50, height: 5, decoration: BoxDecoration(color: Colors.grey.shade400, borderRadius: BorderRadius.circular(10))),
          const SizedBox(height: 20),
          Text(title, style: const TextStyle(fontSize: 22, fontWeight: FontWeight.bold)),
          const SizedBox(height: 16),
          Expanded(child: ListView.builder(shrinkWrap: true, itemCount: packages.length, itemBuilder: (context, index) {
            final pkg = packages[index];
            return Container(
              margin: const EdgeInsets.only(bottom: 12),
              decoration: BoxDecoration(color: isDark ? const Color(0xFF2C2C3E) : const Color(0xFFF3E8FF), borderRadius: BorderRadius.circular(16), border: Border.all(color: const Color(0xFF6558F5).withOpacity(0.3))),
              child: ListTile(
                leading: const Icon(Icons.local_fire_department, color: Color(0xFF6558F5), size: 30),
                title: Text(pkg['amount']!, style: const TextStyle(fontWeight: FontWeight.bold)),
                subtitle: Text(pkg['price']!),
                trailing: ElevatedButton(onPressed: () {}, style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFF6558F5), shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8))), child: const Text('Buy', style: TextStyle(color: Colors.white))),
              ),
            );
          })),
        ]),
      ),
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
          IconButton(icon: Icon(isDark ? Icons.wb_sunny : Icons.nightlight_round), onPressed: _toggleTheme, color: isDark ? Colors.amber : Colors.black87),
          const Padding(padding: EdgeInsets.only(right: 16.0), child: Icon(Icons.shopping_cart_outlined)),
        ],
      ),
      body: GridView.count(
        padding: const EdgeInsets.all(16), crossAxisCount: 2, crossAxisSpacing: 16, mainAxisSpacing: 16, childAspectRatio: 0.8,
        children: [
          _buildItemCard(context: context, title: 'BGMI\nPopularity', subtitle: 'Epic Win', icon: Icons.local_fire_department, isDark: isDark, onTap: () => _showPackageBottomSheet(context, 'Popularity Packages', [{'amount': '100K Popularity', 'price': '₹100'}, {'amount': '500K Popularity', 'price': '₹450'}])),
          _buildItemCard(context: context, title: 'BGMI UC', subtitle: 'Top Up', icon: Icons.monetization_on, isDark: isDark, onTap: () => _showPackageBottomSheet(context, 'UC Packages', [{'amount': '60 UC', 'price': '₹75'}, {'amount': '325 UC', 'price': '₹380'}])),
          _buildItemCard(context: context, title: 'FreeFire', subtitle: 'Booyah!', icon: Icons.sports_esports, isDark: isDark, onTap: () {}),
          _buildItemCard(context: context, title: 'COD Mobile', subtitle: 'MVP', icon: Icons.stars, isDark: isDark, onTap: () {}),
        ],
      ),
    );
  }

  Widget _buildItemCard({required BuildContext context, required String title, required String subtitle, required IconData icon, required bool isDark, required VoidCallback onTap}) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        decoration: BoxDecoration(color: isDark ? const Color(0xFF2C2C3E) : const Color(0xFFF4EBFF), borderRadius: BorderRadius.circular(24)),
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            const Align(alignment: Alignment.topRight, child: Icon(Icons.favorite_border, color: Color(0xFF9E77ED))),
            Expanded(child: Center(child: Icon(icon, size: 65, color: const Color(0xFF6558F5)))),
            Text(title, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16, height: 1.2)),
            const SizedBox(height: 4),
            Text(subtitle, style: TextStyle(color: isDark ? Colors.grey.shade400 : Colors.grey.shade600, fontSize: 13)),
          ]),
        ),
      ),
    );
  }
}

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
    if (pickedFile != null) setState(() => _imageFile = File(pickedFile.path));
  }

  @override
  Widget build(BuildContext context) {
    bool isDark = Theme.of(context).brightness == Brightness.dark;
    return Scaffold(
      appBar: AppBar(backgroundColor: const Color(0xFF6558F5), title: const Text('Upload', style: TextStyle(color: Colors.white)), centerTitle: true, iconTheme: const IconThemeData(color: Colors.white)),
      body: SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.all(24.0),
          child: Column(children: [
            const SizedBox(height: 20),
            Text('Upload Your Screenshot', textAlign: TextAlign.center, style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: isDark ? Colors.white : Colors.black)),
            const SizedBox(height: 40),
            GestureDetector(
              onTap: _pickImage,
              child: Container(
                height: 300, width: double.infinity,
                decoration: BoxDecoration(
                  color: isDark ? const Color(0xFF2C2C3E) : const Color(0xFFFFF0E6),
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: const Color(0xFF6558F5).withOpacity(0.5), width: 2, style: BorderStyle.solid), // FIXED: dash to solid ✅
                ),
                child: _imageFile != null ? ClipRRect(borderRadius: BorderRadius.circular(14), child: Image.file(_imageFile!, fit: BoxFit.cover)) : const Center(child: Icon
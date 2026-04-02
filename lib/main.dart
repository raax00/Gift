import 'dart:io';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  final prefs = await SharedPreferences.getInstance();
  final isDark = prefs.getBool('isDarkMode') ?? false;
  runApp(MyApp(isDarkMode: isDark));
}

final ValueNotifier<bool> themeNotifier = ValueNotifier(false);

class MyApp extends StatelessWidget {
  final bool isDarkMode;
  MyApp({super.key, required this.isDarkMode}) {
    themeNotifier.value = isDarkMode;
  }

  @override
  Widget build(BuildContext context) {
    return ValueListenableBuilder<bool>(
      valueListenable: themeNotifier,
      builder: (_, isDark, __) {
        return MaterialApp(
          debugShowCheckedModeBanner: false,
          themeMode: isDark ? ThemeMode.dark : ThemeMode.light,
          theme: ThemeData(
            useMaterial3: true,
            primaryColor: const Color(0xFF6558F5),
            colorSchemeSeed: const Color(0xFF6558F5),
            brightness: Brightness.light,
            scaffoldBackgroundColor: const Color(0xFFF8F9FA),
          ),
          darkTheme: ThemeData(
            useMaterial3: true,
            primaryColor: const Color(0xFF6558F5),
            colorSchemeSeed: const Color(0xFF6558F5),
            brightness: Brightness.dark,
            scaffoldBackgroundColor: const Color(0xFF121212),
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
    return Scaffold(
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.bolt, size: 100, color: Color(0xFF6558F5)),
            const SizedBox(height: 20),
            const Text('GAME STORE', style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold)),
            const SizedBox(height: 50),
            ElevatedButton(
              style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFF6558F5), foregroundColor: Colors.white),
              onPressed: () => Navigator.pushReplacement(context, MaterialPageRoute(builder: (_) => const MainLayout())),
              child: const Text('Get Started'),
            )
          ],
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
  int _idx = 0;
  final _tabs = [const HomeScreen(), const UploadScreen()];
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: _tabs[_idx],
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: _idx,
        backgroundColor: const Color(0xFF6558F5),
        selectedItemColor: Colors.white,
        unselectedItemColor: Colors.white60,
        onTap: (i) => setState(() => _idx = i),
        items: const [
          BottomNavigationBarItem(icon: Icon(Icons.home), label: 'Home'),
          BottomNavigationBarItem(icon: Icon(Icons.upload), label: 'Upload'),
        ],
      ),
    );
  }
}

class HomeScreen extends StatelessWidget {
  const HomeScreen({super.key});

  void _showSheet(BuildContext ctx, String title, List<String> items) {
    showModalBottomSheet(
      context: ctx,
      builder: (_) => Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(title, style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
            const Divider(),
            ...items.map((e) => ListTile(title: Text(e), trailing: const Icon(Icons.chevron_right))),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Scaffold(
      appBar: AppBar(
        title: const Text('Store'),
        actions: [
          IconButton(
            icon: Icon(isDark ? Icons.light_mode : Icons.dark_mode),
            onPressed: () async {
              themeNotifier.value = !themeNotifier.value;
              final p = await SharedPreferences.getInstance();
              p.setBool('isDarkMode', themeNotifier.value);
            },
          )
        ],
      ),
      body: GridView.count(
        padding: const EdgeInsets.all(15),
        crossAxisCount: 2,
        mainAxisSpacing: 15,
        crossAxisSpacing: 15,
        children: [
          _card(context, 'BGMI Pop', Icons.fireplace, () => _showSheet(context, 'Popularity', ['100k - ₹100', '500k - ₹450'])),
          _card(context, 'BGMI UC', Icons.currency_bitcoin, () => _showSheet(context, 'UC Store', ['60 UC - ₹75', '325 UC - ₹380'])),
          _card(context, 'FreeFire', Icons.diamond, () {}),
          _card(context, 'Others', Icons.games, () {}),
        ],
      ),
    );
  }

  Widget _card(BuildContext ctx, String t, IconData i, VoidCallback fn) {
    final isDark = Theme.of(ctx).brightness == Brightness.dark;
    return GestureDetector(
      onTap: fn,
      child: Container(
        decoration: BoxDecoration(
          color: isDark ? Colors.white10 : const Color(0xFFF4EBFF),
          borderRadius: BorderRadius.circular(20),
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(i, size: 50, color: const Color(0xFF6558F5)),
            const SizedBox(height: 10),
            Text(t, style: const TextStyle(fontWeight: FontWeight.bold)),
          ],
        ),
      ),
    );
  }
}

class UploadScreen extends StatefulWidget {
  const UploadScreen({super.key});
  @override
  State<UploadScreen> createState() => _UploadState();
}

class _UploadState extends State<UploadScreen> {
  File? _img;
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Upload')),
      body: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          children: [
            GestureDetector(
              onTap: () async {
                final x = await ImagePicker().pickImage(source: ImageSource.gallery);
                if (x != null) setState(() => _img = File(x.path));
              },
              child: Container(
                height: 300,
                width: double.infinity,
                decoration: BoxDecoration(
                  border: Border.all(color: Colors.grey),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: _img == null 
                    ? const Icon(Icons.add_a_photo, size: 50) 
                    : ClipRRect(borderRadius: BorderRadius.circular(20), child: Image.file(_img!, fit: BoxFit.cover)),
              ),
            ),
            const SizedBox(height: 20),
            const Text('Tap box to select screenshot'),
          ],
        ),
      ),
    );
  }
}
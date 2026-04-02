import 'dart:io';
import 'package:flutter/material.dart';
import 'package:geolocator/geolocator.dart';
import 'package:geocoding/geocoding.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:smooth_page_indicator/smooth_page_indicator.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  final p = await SharedPreferences.getInstance();
  runApp(XSaleApp(isDark: p.getBool('isDark') ?? false));
}

final themeNotifier = ValueNotifier(false);

class XSaleApp extends StatelessWidget {
  final bool isDark;
  XSaleApp({super.key, required this.isDark}) { themeNotifier.value = isDark; }

  @override
  Widget build(BuildContext context) {
    return ValueListenableBuilder<bool>(
      valueListenable: themeNotifier,
      builder: (_, dark, __) => MaterialApp(
        debugShowCheckedModeBanner: false,
        themeMode: dark ? ThemeMode.dark : ThemeMode.light,
        theme: ThemeData(useMaterial3: true, colorSchemeSeed: const Color(0xFF0097A7), brightness: Brightness.light),
        darkTheme: ThemeData(useMaterial3: true, colorSchemeSeed: const Color(0xFF0097A7), brightness: Brightness.dark),
        home: const OnboardingScreen(),
      ),
    );
  }
}

class OnboardingScreen extends StatefulWidget {
  const OnboardingScreen({super.key});
  @override
  State<OnboardingScreen> createState() => _OnboardingState();
}

class _OnboardingState extends State<OnboardingScreen> {
  final controller = PageController();
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Column(children: [
        Expanded(child: PageView(controller: controller, children: [
          _page("DISCOVER", "Find your nearest Shell charging station", Icons.map),
          _page("SELECT AND PAY", "Add money to your wallet easily", Icons.payment),
        ])),
        const SizedBox(height: 10),
        SmoothPageIndicator(controller: controller, count: 2, effect: const ExpandingDotsEffect(activeDotColor: Color(0xFF0097A7))),
        Padding(padding: const EdgeInsets.all(25), child: SizedBox(width: double.infinity, height: 55, child: ElevatedButton(
          onPressed: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const SubscriptionScreen())),
          style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFF0097A7), foregroundColor: Colors.white, shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12))),
          child: const Text("Get Started", style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
        ))),
      ]),
    );
  }
  Widget _page(String t, String s, IconData i) => Column(mainAxisAlignment: MainAxisAlignment.center, children: [
    const Icon(Icons.bolt, color: Colors.amber, size: 60), // Shell style logo placeholder
    const Text("Shell Recharge", style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold, color: Color(0xFF0097A7))),
    const SizedBox(height: 50), Icon(i, size: 100, color: const Color(0xFF0097A7)),
    const SizedBox(height: 40), Text(t, style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold)),
    Padding(padding: const EdgeInsets.symmetric(horizontal: 40, vertical: 10), child: Text(s, textAlign: TextAlign.center, style: const TextStyle(color: Colors.grey))),
  ]);
}

class SubscriptionScreen extends StatelessWidget {
  const SubscriptionScreen({super.key});
  @override
  Widget build(BuildContext context) {
    final dark = Theme.of(context).brightness == Brightness.dark;
    return Scaffold(
      appBar: AppBar(title: const Text("Subscription Plan")),
      body: Padding(padding: const EdgeInsets.all(20), child: Column(children: [
        Container(padding: const EdgeInsets.all(25), decoration: BoxDecoration(color: dark ? Colors.white10 : Colors.black87, borderRadius: BorderRadius.circular(20), border: Border.all(color: const Color(0xFF0097A7), width: 2)),
          child: Column(children: [
            const Icon(Icons.verified, color: Colors.green, size: 50),
            const SizedBox(height: 10),
            const Text("Free launch package", style: TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold)),
            const Divider(color: Colors.white24, height: 30),
            _list("99 Ads Listing"), _list("30 Days Validity"),
            const SizedBox(height: 30),
            const Text("Free", style: TextStyle(color: Colors.white, fontSize: 35, fontWeight: FontWeight.bold)),
          ])),
        const Spacer(),
        ElevatedButton(onPressed: () => Navigator.pushReplacement(context, MaterialPageRoute(builder: (_) => const HomeScreen())), 
          style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFF0097A7), foregroundColor: Colors.white, minimumSize: const Size(double.infinity, 55), shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12))),
          child: const Text("Activate Now")),
      ])),
    );
  }
  Widget _list(String t) => Row(children: [const Icon(Icons.check_circle, color: Colors.green, size: 20), const SizedBox(width: 10), Text(t, style: const TextStyle(color: Colors.white))]);
}

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});
  @override
  State<HomeScreen> createState() => _HomeState();
}

class _HomeState extends State<HomeScreen> {
  String loc = "Detecting Location...";
  @override
  void initState() { super.initState(); _getLoc(); }

  _getLoc() async {
    try {
      LocationPermission p = await Geolocator.requestPermission();
      if (p != LocationPermission.denied) {
        Position pos = await Geolocator.getCurrentPosition();
        List<Placemark> pm = await placemarkFromCoordinates(pos.latitude, pos.longitude);
        setState(() => loc = "${pm[0].locality}, ${pm[0].subAdministrativeArea}");
      }
    } catch (e) { setState(() => loc = "Location Unavailable"); }
  }

  @override
  Widget build(BuildContext context) {
    final dark = Theme.of(context).brightness == Brightness.dark;
    return Scaffold(
      body: SafeArea(child: Column(children: [
        ListTile(title: const Text("Hey Shamir", style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18)), subtitle: const Text("Welcome", style: TextStyle(color: Colors.red)), 
          trailing: IconButton(icon: Icon(dark ? Icons.light_mode : Icons.dark_mode), onPressed: () async {
            themeNotifier.value = !themeNotifier.value;
            (await SharedPreferences.getInstance()).setBool('isDark', themeNotifier.value);
          })),
        Container(margin: const EdgeInsets.symmetric(horizontal: 15), padding: const EdgeInsets.all(12), decoration: BoxDecoration(color: Colors.grey.withOpacity(0.1), borderRadius: BorderRadius.circular(10), border: Border.all(color: Colors.grey.shade300)),
          child: Row(children: [const Icon(Icons.location_on_outlined, size: 20), const SizedBox(width: 10), Expanded(child: Text(loc, style: const TextStyle(fontSize: 12), overflow: TextOverflow.ellipsis))])),
        Expanded(child: GridView.builder(padding: const EdgeInsets.all(15), gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(crossAxisCount: 2, childAspectRatio: 0.75, crossAxisSpacing: 12, mainAxisSpacing: 12), 
          itemCount: 4, itemBuilder: (_, i) => Container(decoration: BoxDecoration(border: Border.all(color: Colors.grey.shade300), borderRadius: BorderRadius.circular(15)),
            child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Expanded(child: Container(decoration: BoxDecoration(color: Colors.grey.shade200, borderRadius: const BorderRadius.vertical(top: Radius.circular(15))), child: const Center(child: Icon(Icons.image, color: Colors.grey)))),
              const Padding(padding: EdgeInsets.all(8.0), child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                Text("Maruti Suzuki Swift", style: TextStyle(fontWeight: FontWeight.bold), maxLines: 1),
                Text("₹ 4,36,000", style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Color(0xFF0097A7))),
              ]))])))),
      ])),
      bottomNavigationBar: BottomNavigationBar(type: BottomNavigationBarType.fixed, selectedItemColor: const Color(0xFF0097A7), items: const [BottomNavigationBarItem(icon: Icon(Icons.home), label: ""), BottomNavigationBarItem(icon: Icon(Icons.chat_outlined), label: ""), BottomNavigationBarItem(icon: Icon(Icons.add_circle, size: 45, color: Colors.black), label: ""), BottomNavigationBarItem(icon: Icon(Icons.list_alt), label: ""), BottomNavigationBarItem(icon: Icon(Icons.person_outline), label: "")]),
    );
  }
}
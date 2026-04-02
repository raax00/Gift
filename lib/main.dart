import 'package:flutter/material.dart';
import 'package:geolocator/geolocator.dart';
import 'package:geocoding/geocoding.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:smooth_page_indicator/smooth_page_indicator.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  final prefs = await SharedPreferences.getInstance();
  runApp(XSaleApp(isDark: prefs.getBool('isDark') ?? false));
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
        theme: ThemeData(
          useMaterial3: true,
          primaryColor: const Color(0xFF0097A7), // Teal color from Shell
          brightness: Brightness.light,
          scaffoldBackgroundColor: Colors.white,
        ),
        darkTheme: ThemeData(
          useMaterial3: true,
          primaryColor: const Color(0xFF0097A7),
          brightness: Brightness.dark,
          scaffoldBackgroundColor: const Color(0xFF121212),
        ),
        home: const OnboardingScreen(),
      ),
    );
  }
}

// ==========================================
// 1. ONBOARDING SCREEN (Shell Recharge Style)
// ==========================================
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
      body: Column(
        children: [
          Expanded(
            child: PageView(
              controller: controller,
              children: [
                _onboardPage("DISCOVER", "Find your nearest Shell charging station on the map", Icons.electric_car),
                _onboardPage("SELECT AND PAY", "Select charger and add money to your wallet", Icons.account_balance_wallet),
                _onboardPage("RECHARGE", "Plug in and start charging your vehicle easily", Icons.ev_station),
              ],
            ),
          ),
          SmoothPageIndicator(
            controller: controller, count: 3,
            effect: const ExpandingDotsEffect(activeDotColor: Color(0xFF0097A7), dotHeight: 8, dotWidth: 8),
          ),
          const SizedBox(height: 30),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 20),
            child: SizedBox(
              width: double.infinity, height: 55,
              child: ElevatedButton(
                onPressed: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const SubscriptionScreen())),
                style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFF0097A7), foregroundColor: Colors.white, shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10))),
                child: const Text("Get Started", style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _onboardPage(String t, String s, IconData i) {
    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Row(mainAxisAlignment: MainAxisAlignment.center, children: [
          const Icon(Icons.遣, color: Colors.red, size: 40), // Placeholder for Shell Logo
          const SizedBox(width: 10),
          Column(crossAxisAlignment: CrossAxisAlignment.start, children: const [
            Text("Shell", style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold, color: Colors.red)),
            Text("Recharge", style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold, color: Color(0xFF0097A7))),
          ]),
        ]),
        const SizedBox(height: 50),
        Icon(i, size: 150, color: Colors.yellow.shade700),
        const SizedBox(height: 50),
        Text(t, style: const TextStyle(fontSize: 22, fontWeight: FontWeight.bold, letterSpacing: 1.5)),
        const SizedBox(height: 15),
        Padding(padding: const EdgeInsets.symmetric(horizontal: 40), child: Text(s, textAlign: TextAlign.center, style: const TextStyle(color: Colors.grey))),
      ],
    );
  }
}

// ==========================================
// 2. SUBSCRIPTION PLAN SCREEN
// ==========================================
class SubscriptionScreen extends StatelessWidget {
  const SubscriptionScreen({super.key});
  @override
  Widget build(BuildContext context) {
    final dark = Theme.of(context).brightness == Brightness.dark;
    return DefaultTabController(
      length: 2,
      child: Scaffold(
        appBar: AppBar(
          title: const Text("Subscription Plan"),
          bottom: const TabBar(
            indicatorColor: Color(0xFF0097A7),
            labelColor: Color(0xFF0097A7),
            tabs: [Tab(text: "Ads Listing"), Tab(text: "Featured")],
          ),
        ),
        body: Padding(
          padding: const EdgeInsets.all(20),
          child: Column(
            children: [
              Container(
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  color: dark ? Colors.black : Colors.grey.shade900,
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(color: const Color(0xFF0097A7), width: 2),
                ),
                child: Column(
                  children: [
                    Align(alignment: Alignment.topRight, child: Container(padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5), decoration: BoxDecoration(color: const Color(0xFF0097A7), borderRadius: BorderRadius.circular(20)), child: const Text("Active Plan", style: TextStyle(color: Colors.white, fontSize: 12)))),
                    const Icon(Icons.hexagon, size: 60, color: Colors.red),
                    const SizedBox(height: 20),
                    const Text("Free launch package", style: TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold)),
                    const SizedBox(height: 20),
                    _checkItem("99 Ads Listing"),
                    _checkItem("30 Days"),
                    const Text("- Multiple images & video", style: TextStyle(color: Colors.grey)),
                    const SizedBox(height: 40),
                    const Text("Free", style: TextStyle(color: Colors.white, fontSize: 30, fontWeight: FontWeight.bold)),
                  ],
                ),
              ),
              const Spacer(),
              ElevatedButton(
                onPressed: () => Navigator.pushReplacement(context, MaterialPageRoute(builder: (_) => const HomeScreen())),
                style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFF0097A7), foregroundColor: Colors.white, minimumSize: const Size(double.infinity, 50)),
                child: const Text("Continue to Home"),
              )
            ],
          ),
        ),
      ),
    );
  }

  Widget _checkItem(String t) => Row(children: [const Icon(Icons.check_circle, color: Colors.green), const SizedBox(width: 10), Text(t, style: const TextStyle(color: Colors.white))]);
}

// ==========================================
// 3. HOME SCREEN (XSale marketplace)
// ==========================================
class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});
  @override
  State<HomeScreen> createState() => _HomeState();
}

class _HomeState extends State<HomeScreen> {
  String location = "Detecting location...";

  @override
  void initState() {
    super.initState();
    _determinePosition();
  }

  Future<void> _determinePosition() async {
    bool serviceEnabled = await Geolocator.isLocationServiceEnabled();
    if (!serviceEnabled) return;
    LocationPermission permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
      if (permission == LocationPermission.denied) return;
    }
    Position position = await Geolocator.getCurrentPosition();
    List<Placemark> placemarks = await placemarkFromCoordinates(position.latitude, position.longitude);
    setState(() {
      location = "${placemarks[0].locality}, ${placemarks[0].administrativeArea} ${placemarks[0].postalCode}";
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: Column(
          children: [
            _header(),
            _locationBar(),
            const SizedBox(height: 10),
            _categories(),
            Expanded(child: _productGrid()),
          ],
        ),
      ),
      bottomNavigationBar: BottomNavigationBar(
        type: BottomNavigationBarType.fixed,
        selectedItemColor: const Color(0xFF0097A7),
        items: const [
          BottomNavigationBarItem(icon: Icon(Icons.home), label: ""),
          BottomNavigationBarItem(icon: Icon(Icons.chat_bubble_outline), label: ""),
          BottomNavigationBarItem(icon: CircleAvatar(backgroundColor: Colors.black, child: Icon(Icons.add, color: Colors.white)), label: ""),
          BottomNavigationBarItem(icon: Icon(Icons.ad_units_outlined), label: ""),
          BottomNavigationBarItem(icon: Icon(Icons.person_outline), label: ""),
        ],
      ),
    );
  }

  Widget _header() => Padding(
    padding: const EdgeInsets.all(15),
    child: Row(children: [
      const CircleAvatar(backgroundColor: Color(0xFF0097A7), child: Text("X", style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold))),
      const SizedBox(width: 10),
      Column(crossAxisAlignment: CrossAxisAlignment.start, children: const [
        Text("Hey Shamir", style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
        Text("Welcome", style: TextStyle(color: Colors.red)),
      ]),
      const Spacer(),
      IconButton(icon: const Icon(Icons.dark_mode), onPressed: () async {
        themeNotifier.value = !themeNotifier.value;
        (await SharedPreferences.getInstance()).setBool('isDark', themeNotifier.value);
      }),
    ]),
  );

  Widget _locationBar() => Container(
    margin: const EdgeInsets.symmetric(horizontal: 15),
    padding: const EdgeInsets.all(10),
    decoration: BoxDecoration(color: Colors.grey.withOpacity(0.1), borderRadius: BorderRadius.circular(10), border: Border.all(color: Colors.grey.shade300)),
    child: Row(children: [
      const Icon(Icons.location_on_outlined),
      const SizedBox(width: 10),
      Expanded(child: Text(location, style: const TextStyle(fontSize: 12), overflow: TextOverflow.ellipsis)),
      const Icon(Icons.chevron_right),
    ]),
  );

  Widget _categories() => SizedBox(
    height: 100,
    child: ListView(
      scrollDirection: Axis.horizontal,
      children: [
        _catItem("Vehicle", Icons.directions_car),
        _catItem("Property", Icons.home),
        _catItem("Mobile", Icons.phone_android),
        _catItem("Bike", Icons.motorcycle),
        _catItem("Electronics", Icons.tv),
      ],
    ),
  );

  Widget _catItem(String t, IconData i) => Padding(
    padding: const EdgeInsets.all(10),
    child: Column(children: [
      CircleAvatar(backgroundColor: Colors.grey.shade200, child: Icon(i, color: Colors.black54)),
      const SizedBox(height: 5),
      Text(t, style: const TextStyle(fontSize: 12)),
    ]),
  );

  Widget _productGrid() => GridView.builder(
    padding: const EdgeInsets.all(10),
    gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(crossAxisCount: 2, childAspectRatio: 0.75, crossAxisSpacing: 10, mainAxisSpacing: 10),
    itemCount: 4,
    itemBuilder: (context, index) => _productCard(),
  );

  Widget _productCard() => Container(
    decoration: BoxDecoration(border: Border.all(color: Colors.grey.shade300), borderRadius: BorderRadius.circular(15)),
    child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      ClipRRect(borderRadius: const BorderRadius.vertical(top: Radius.circular(15)), child: Container(height: 120, color: Colors.grey.shade300, child: const Center(child: Icon(Icons.image)))),
      Padding(padding: const EdgeInsets.all(8), child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        const Text("Maruti Suzuki Swift", style: TextStyle(fontWeight: FontWeight.bold), maxLines: 1),
        const Text("₹ 4,36,000", style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
        Row(children: const [Icon(Icons.location_on, size: 12), Text(" Ranchi", style: TextStyle(fontSize: 10))]),
      ])),
    ]),
  );
}
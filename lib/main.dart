import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'supabase_config.dart';
import 'providers/cart_provider.dart';
import 'providers/chat_provider.dart';
import 'providers/order_provider.dart';
import 'providers/wallet_provider.dart';
import 'screens/splash_screen.dart';

ValueNotifier<bool> themeNotifier = ValueNotifier(false);
ValueNotifier<bool> maintenanceMode = ValueNotifier(false);

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await SupabaseConfig.initialize();
  final prefs = await SharedPreferences.getInstance();
  themeNotifier.value = prefs.getBool('isDark') ?? false;
  await _checkMaintenanceMode();
  runApp(MyApp(prefs: prefs));
}

Future<void> _checkMaintenanceMode() async {
  try {
    final response = await SupabaseConfig.client
        .from('app_settings')
        .select('value')
        .eq('key', 'maintenance_mode')
        .maybeSingle();
    maintenanceMode.value = response != null && response['value'] == 'true';
  } catch (e) {
    maintenanceMode.value = false;
  }
}

class MyApp extends StatelessWidget {
  final SharedPreferences prefs;
  const MyApp({super.key, required this.prefs});

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => CartProvider()),
        ChangeNotifierProvider(create: (_) => ChatProvider()),
        ChangeNotifierProvider(create: (_) => OrderProvider()),
        ChangeNotifierProvider(create: (_) => WalletProvider()),
      ],
      child: ValueListenableBuilder<bool>(
        valueListenable: themeNotifier,
        builder: (_, isDark, __) {
          return ValueListenableBuilder<bool>(
            valueListenable: maintenanceMode,
            builder: (_, isMaintenance, __) {
              return MaterialApp(
                debugShowCheckedModeBanner: false,
                title: 'Dream Store',
                themeMode: isDark ? ThemeMode.dark : ThemeMode.light,
                theme: ThemeData(
                  useMaterial3: true,
                  colorScheme: ColorScheme.fromSeed(
                    seedColor: const Color(0xFF0097A7),
                    brightness: Brightness.light,
                  ),
                ),
                darkTheme: ThemeData(
                  useMaterial3: true,
                  colorScheme: ColorScheme.fromSeed(
                    seedColor: const Color(0xFF0097A7),
                    brightness: Brightness.dark,
                  ),
                ),
                home: isMaintenance
                    ? const MaintenanceScreen()
                    : SplashScreen(prefs: prefs),
              );
            },
          );
        },
      ),
    );
  }
}

class MaintenanceScreen extends StatelessWidget {
  const MaintenanceScreen({super.key});
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.build, size: 80, color: Colors.orange),
            const SizedBox(height: 20),
            const Text('Under Maintenance', style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold)),
            const SizedBox(height: 10),
            const Text('We are improving your experience. Please check back soon.'),
          ],
        ),
      ),
    );
  }
}
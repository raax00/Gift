import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:upgrader/upgrader.dart';
import 'package:shared_preferences/shared_preferences.dart';
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
  final response = await SupabaseConfig.client
      .from('app_settings')
      .select('value')
      .eq('key', 'maintenance_mode')
      .single();
  maintenanceMode.value = response['value'] == 'true';
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
                    : UpgradeAlert(
                        upgrader: Upgrader(
                          appCastUrl: 'https://your-domain.com/appcast.xml',
                          debugLogging: true,
                        ),
                        child: SplashScreen(prefs: prefs),
                      ),
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
            Icon(Icons.build, size: 80, color: Colors.orange),
            SizedBox(height: 20),
            Text('Under Maintenance', style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold)),
            SizedBox(height: 10),
            Text('We are improving your experience. Please check back soon.'),
          ],
        ),
      ),
    );
  }
}
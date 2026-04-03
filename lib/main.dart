import 'package:flutter/material.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'supabase_config.dart';

// Import your providers and screens here
import 'providers/cart_provider.dart';
import 'providers/chat_provider.dart';
import 'providers/order_provider.dart';
import 'providers/wallet_provider.dart';
import 'screens/splash_screen.dart';

ValueNotifier<bool> themeNotifier = ValueNotifier(false);
ValueNotifier<bool> maintenanceMode = ValueNotifier(false);

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  
  // Set preferred orientations for better mobile experience
  SystemChrome.setPreferredOrientations([DeviceOrientation.portraitUp]);
  
  try {
    await SupabaseConfig.initialize();
  } catch (e) {
    debugPrint("Supabase Init Error: $e");
  }

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
          // iOS Status Bar Style
          SystemChrome.setSystemUIOverlayStyle(SystemUiOverlayStyle(
            statusBarBrightness: isDark ? Brightness.dark : Brightness.light,
            statusBarIconBrightness: isDark ? Brightness.light : Brightness.dark,
            statusBarColor: Colors.transparent,
          ));

          return ValueListenableBuilder<bool>(
            valueListenable: maintenanceMode,
            builder: (_, isMaintenance, __) {
              return MaterialApp(
                debugShowCheckedModeBanner: false,
                title: 'Dream Store',
                themeMode: isDark ? ThemeMode.dark : ThemeMode.light,
                theme: ThemeData(
                  useMaterial3: true,
                  scaffoldBackgroundColor: const Color(0xFFF2F2F7),
                  colorScheme: ColorScheme.fromSeed(seedColor: const Color(0xFF0097A7), brightness: Brightness.light),
                  pageTransitionsTheme: const PageTransitionsTheme(
                    builders: {
                      TargetPlatform.android: CupertinoPageTransitionsBuilder(), // iOS transition on Android
                      TargetPlatform.iOS: CupertinoPageTransitionsBuilder(),
                    },
                  ),
                ),
                darkTheme: ThemeData(
                  useMaterial3: true,
                  scaffoldBackgroundColor: Colors.black,
                  colorScheme: ColorScheme.fromSeed(seedColor: const Color(0xFF0097A7), brightness: Brightness.dark),
                  pageTransitionsTheme: const PageTransitionsTheme(
                    builders: {
                      TargetPlatform.android: CupertinoPageTransitionsBuilder(),
                      TargetPlatform.iOS: CupertinoPageTransitionsBuilder(),
                    },
                  ),
                ),
                home: isMaintenance ? const MaintenanceScreen() : SplashScreen(prefs: prefs),
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
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Scaffold(
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(32),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Container(
                padding: const EdgeInsets.all(24),
                decoration: BoxDecoration(
                  color: Colors.orange.withOpacity(0.1),
                  shape: BoxShape.circle,
                ),
                child: const Icon(CupertinoIcons.wrench_fill, size: 60, color: Colors.orange),
              ),
              const SizedBox(height: 32),
              Text(
                'Under Maintenance',
                style: TextStyle(fontSize: 24, fontWeight: FontWeight.w800, color: isDark ? Colors.white : Colors.black87),
              ),
              const SizedBox(height: 12),
              Text(
                'We are upgrading our servers for a better experience. Please check back shortly.',
                textAlign: TextAlign.center,
                style: TextStyle(fontSize: 15, color: Colors.grey.shade500, height: 1.5),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

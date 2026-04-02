import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'providers/cart_provider.dart';
import 'providers/chat_provider.dart';
import 'screens/splash_screen.dart';

// Global theme notifier (public so it can be accessed from other files)
ValueNotifier<bool> themeNotifier = ValueNotifier(false);

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  final prefs = await SharedPreferences.getInstance();
  runApp(MyApp(prefs: prefs));
}

class MyApp extends StatelessWidget {  // Removed const from constructor
  final SharedPreferences prefs;
  MyApp({super.key, required this.prefs}) {
    themeNotifier.value = prefs.getBool('isDark') ?? false;
  }

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => CartProvider()),
        ChangeNotifierProvider(create: (_) => ChatProvider()),
      ],
      child: ValueListenableBuilder<bool>(
        valueListenable: themeNotifier,
        builder: (_, isDark, __) {
          return MaterialApp(
            debugShowCheckedModeBanner: false,
            title: 'XSale',
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
            home: SplashScreen(prefs: prefs),
          );
        },
      ),
    );
  }
}
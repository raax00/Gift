import 'package:supabase_flutter/supabase_flutter.dart';

class SupabaseConfig {
  static const String url = 'https://your-project.supabase.co'; // Replace
  static const String anonKey = 'your-anon-key';               // Replace

  static Future<void> initialize() async {
    await Supabase.initialize(url: url, anonKey: anonKey);
  }

  static SupabaseClient get client => Supabase.instance.client;
}
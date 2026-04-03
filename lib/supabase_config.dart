import 'package:supabase_flutter/supabase_flutter.dart';

class SupabaseConfig {
  // Replace with your Supabase project URL and anon key
  static const String url = 'https://your-project.supabase.co';
  static const String anonKey = 'your-anon-key';

  static Future<void> initialize() async {
    await Supabase.initialize(url: url, anonKey: anonKey);
  }

  static SupabaseClient get client => Supabase.instance.client;
}
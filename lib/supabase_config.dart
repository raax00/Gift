import 'package:supabase_flutter/supabase_flutter.dart';

class SupabaseConfig {
  // Replace with your Supabase project URL and anon key
  static const String url = 'https://nwglgjyclxgxngedexws.supabase.co';
  static const String anonKey = 'eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6Im53Z2xnanljbHhneG5nZWRleHdzIiwicm9sZSI6ImFub24iLCJpYXQiOjE3NzUyMDEyODAsImV4cCI6MjA5MDc3NzI4MH0.TYJ7ysVhzy5chPBxfxpKeYZCLuuwVVCehJplq96iw7o';

  static Future<void> initialize() async {
    await Supabase.initialize(url: url, anonKey: anonKey);
  }

  static SupabaseClient get client => Supabase.instance.client;
}
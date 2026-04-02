// Same as provided earlier but with minor adjustments
import 'package:flutter/material.dart';
import 'package:flutter/cupertino.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../main.dart';

class ProfileScreen extends StatefulWidget {
  const ProfileScreen({super.key});

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  String _name = 'Shamir';
  String _email = 'shamir@example.com';
  String _phone = '+91 9876543210';
  bool _notifications = true;
  bool _darkMode = false;

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    final prefs = await SharedPreferences.getInstance();
    setState(() {
      _name = prefs.getString('user_name') ?? 'Shamir';
      _email = prefs.getString('user_email') ?? 'shamir@example.com';
      _phone = prefs.getString('user_phone') ?? '+91 9876543210';
      _notifications = prefs.getBool('notifications') ?? true;
      _darkMode = prefs.getBool('isDark') ?? false;
    });
  }

  @override
  Widget build(BuildContext context) {
    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        const CircleAvatar(radius: 50, backgroundColor: Color(0xFF0097A7), child: Icon(Icons.person, size: 50, color: Colors.white)),
        const SizedBox(height: 16),
        Card(
          child: ListTile(title: Text('Name: $_name'), leading: const Icon(Icons.person), onTap: () {}),
        ),
        Card(
          child: ListTile(title: Text('Email: $_email'), leading: const Icon(Icons.email), onTap: () {}),
        ),
        Card(
          child: ListTile(title: Text('Phone: $_phone'), leading: const Icon(Icons.phone), onTap: () {}),
        ),
        SwitchListTile(title: const Text('Dark Mode'), value: _darkMode, onChanged: (val) async {
          setState(() => _darkMode = val);
          themeNotifier.value = val;
          final prefs = await SharedPreferences.getInstance();
          await prefs.setBool('isDark', val);
        }),
        SwitchListTile(title: const Text('Notifications'), value: _notifications, onChanged: (val) async {
          setState(() => _notifications = val);
          final prefs = await SharedPreferences.getInstance();
          await prefs.setBool('notifications', val);
        }),
        const SizedBox(height: 20),
        OutlinedButton.icon(onPressed: () async {
          final prefs = await SharedPreferences.getInstance();
          await prefs.clear();
          Navigator.pushReplacementNamed(context, '/');
        }, icon: const Icon(Icons.logout), label: const Text('Logout'), style: OutlinedButton.styleFrom(foregroundColor: Colors.red)),
      ],
    );
  }
}
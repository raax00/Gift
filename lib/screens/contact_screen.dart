import 'package:flutter/material.dart';

class ContactScreen extends StatelessWidget {
  const ContactScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Contact Us'), centerTitle: true),
      body: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          children: [
            const Icon(Icons.support_agent, size: 80, color: Color(0xFF0097A7)),
            const SizedBox(height: 20),
            const Text('24/7 Customer Support', style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold)),
            const SizedBox(height: 10),
            const Text('We are here to help you 24/7', textAlign: TextAlign.center),
            const SizedBox(height: 30),
            ListTile(
              leading: const Icon(Icons.phone, color: Color(0xFF0097A7)),
              title: const Text('+91 8406962570'),
              onTap: () {},
            ),
            ListTile(
              leading: const Icon(Icons.email, color: Color(0xFF0097A7)),
              title: const Text('support@dreamstore.com'),
              onTap: () {},
            ),
            ListTile(
              leading: const Icon(Icons.chat, color: Color(0xFF0097A7)),
              title: const Text('Live Chat'),
              onTap: () {},
            ),
          ],
        ),
      ),
    );
  }
}
import 'package:flutter/material.dart';
import 'package:smooth_page_indicator/smooth_page_indicator.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'subscription_screen.dart';

class OnboardingScreen extends StatefulWidget {
  const OnboardingScreen({super.key});

  @override
  State<OnboardingScreen> createState() => _OnboardingState();
}

class _OnboardingState extends State<OnboardingScreen> {
  final PageController _controller = PageController();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: Column(
          children: [
            Expanded(
              child: PageView(
                controller: _controller,
                children: [
                  _onboardingPage(
                    title: 'Discover',
                    description: 'Find your nearest Shell charging station',
                    icon: Icons.map,
                  ),
                  _onboardingPage(
                    title: 'Select & Pay',
                    description: 'Add money to your wallet easily',
                    icon: Icons.payment,
                  ),
                ],
              ),
            ),
            const SizedBox(height: 20),
            SmoothPageIndicator(
              controller: _controller,
              count: 2,
              effect: const ExpandingDotsEffect(activeDotColor: Color(0xFF0097A7)),
            ),
            const SizedBox(height: 30),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 24),
              child: SizedBox(
                width: double.infinity,
                height: 55,
                child: ElevatedButton(
                  onPressed: () async {
                    final prefs = await SharedPreferences.getInstance();
                    await prefs.setBool('onboarded', true);
                    if (mounted) {
                      Navigator.pushReplacement(context, MaterialPageRoute(builder: (_) => const SubscriptionScreen()));
                    }
                  },
                  style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFF0097A7), foregroundColor: Colors.white, shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16))),
                  child: const Text('Get Started', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                ),
              ),
            ),
            const SizedBox(height: 30),
          ],
        ),
      ),
    );
  }

  Widget _onboardingPage({required String title, required String description, required IconData icon}) {
    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        const Icon(Icons.bolt, color: Colors.amber, size: 60),
        const SizedBox(height: 20),
        const Text('XSale', style: TextStyle(fontSize: 26, fontWeight: FontWeight.bold, color: Color(0xFF0097A7))),
        const SizedBox(height: 50),
        Icon(icon, size: 100, color: const Color(0xFF0097A7)),
        const SizedBox(height: 40),
        Text(title, style: const TextStyle(fontSize: 28, fontWeight: FontWeight.bold)),
        const SizedBox(height: 12),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 40),
          child: Text(description, textAlign: TextAlign.center, style: TextStyle(color: Colors.grey.shade600)),
        ),
      ],
    );
  }
}
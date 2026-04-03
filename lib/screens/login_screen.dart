import 'package:flutter/material.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/services.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../supabase_config.dart';
import 'home_screen.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  bool _isLoading = false;
  bool _isLogin = true;

  final Color primaryColor = const Color(0xFF0097A7);

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  void _showError(String message) {
    if (!mounted) return;
    HapticFeedback.mediumImpact();
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            const Icon(CupertinoIcons.exclamationmark_circle_fill, color: Colors.white, size: 20),
            const SizedBox(width: 10),
            Expanded(child: Text(message, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w500))),
          ],
        ),
        backgroundColor: CupertinoColors.destructiveRed,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
        margin: const EdgeInsets.all(16),
      ),
    );
  }

  Future<void> _submit() async {
    FocusScope.of(context).unfocus(); // Hide keyboard
    final email = _emailController.text.trim();
    final password = _passwordController.text.trim();

    if (email.isEmpty || password.isEmpty) {
      _showError('Please fill in all fields.');
      return;
    }

    setState(() => _isLoading = true);
    try {
      if (_isLogin) {
        await SupabaseConfig.client.auth.signInWithPassword(
          email: email,
          password: password,
        );
      } else {
        await SupabaseConfig.client.auth.signUp(
          email: email,
          password: password,
        );
      }
      
      if (mounted) {
        HapticFeedback.heavyImpact();
        Navigator.pushReplacement(context, CupertinoPageRoute(builder: (_) => const HomeScreen()));
      }
    } on AuthException catch (e) {
      _showError(e.message);
    } catch (e) {
      _showError('Something went wrong. Please try again.');
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final bgColor = isDark ? Colors.black : const Color(0xFFF2F2F7);
    final cardColor = isDark ? const Color(0xFF1C1C1E) : Colors.white;

    return Scaffold(
      backgroundColor: bgColor,
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            physics: const BouncingScrollPhysics(),
            padding: const EdgeInsets.all(24),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                // === LOGO & HERO TEXT ===
                Center(
                  child: Container(
                    padding: const EdgeInsets.all(20),
                    decoration: BoxDecoration(
                      color: primaryColor.withOpacity(0.1),
                      shape: BoxShape.circle,
                    ),
                    child: Icon(CupertinoIcons.game_controller_solid, size: 60, color: primaryColor),
                  ),
                ),
                const SizedBox(height: 32),
                
                Text(
                  _isLogin ? 'Welcome Back!' : 'Create Account',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontSize: 28,
                    fontWeight: FontWeight.w800,
                    letterSpacing: -0.5,
                    color: isDark ? Colors.white : Colors.black87,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  _isLogin ? 'Sign in to continue to Dream Store' : 'Sign up to start buying premium packages',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontSize: 15,
                    color: Colors.grey.shade500,
                  ),
                ),
                const SizedBox(height: 40),

                // === INPUT FIELDS ===
                Container(
                  decoration: BoxDecoration(
                    color: cardColor,
                    borderRadius: BorderRadius.circular(16),
                    boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.03), blurRadius: 10, offset: const Offset(0, 4))],
                  ),
                  child: Column(
                    children: [
                      CupertinoTextField(
                        controller: _emailController,
                        placeholder: 'Email Address',
                        keyboardType: TextInputType.emailAddress,
                        padding: const EdgeInsets.all(18),
                        prefix: Padding(
                          padding: const EdgeInsets.only(left: 18),
                          child: Icon(CupertinoIcons.mail_solid, color: Colors.grey.shade400, size: 20),
                        ),
                        decoration: const BoxDecoration(color: Colors.transparent),
                        style: TextStyle(color: isDark ? Colors.white : Colors.black87),
                      ),
                      Divider(height: 1, thickness: 0.5, color: isDark ? Colors.white10 : Colors.black12, indent: 18, endIndent: 18),
                      CupertinoTextField(
                        controller: _passwordController,
                        placeholder: 'Password',
                        obscureText: true,
                        padding: const EdgeInsets.all(18),
                        prefix: Padding(
                          padding: const EdgeInsets.only(left: 18),
                          child: Icon(CupertinoIcons.lock_fill, color: Colors.grey.shade400, size: 20),
                        ),
                        decoration: const BoxDecoration(color: Colors.transparent),
                        style: TextStyle(color: isDark ? Colors.white : Colors.black87),
                      ),
                    ],
                  ),
                ),
                
                const SizedBox(height: 32),

                // === SUBMIT BUTTON ===
                SizedBox(
                  height: 54,
                  child: CupertinoButton(
                    color: primaryColor,
                    borderRadius: BorderRadius.circular(14),
                    onPressed: _isLoading ? null : _submit,
                    child: _isLoading
                        ? const CupertinoActivityIndicator(color: Colors.white)
                        : Text(
                            _isLogin ? 'Sign In' : 'Sign Up',
                            style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16, color: Colors.white),
                          ),
                  ),
                ),
                
                const SizedBox(height: 24),

                // === TOGGLE LOGIN/SIGNUP ===
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text(
                      _isLogin ? "Don't have an account? " : "Already have an account? ",
                      style: TextStyle(color: Colors.grey.shade500, fontSize: 14),
                    ),
                    GestureDetector(
                      onTap: () {
                        setState(() => _isLogin = !_isLogin);
                        HapticFeedback.selectionClick();
                      },
                      child: Text(
                        _isLogin ? 'Sign Up' : 'Log In',
                        style: TextStyle(color: primaryColor, fontWeight: FontWeight.bold, fontSize: 14),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

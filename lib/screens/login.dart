import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../providers/authentication_provider.dart';
import '../utilities/authentication_validation.dart';
import 'auth_background.dart';
import 'signup.dart';

class LoginScreen extends ConsumerStatefulWidget {
  const LoginScreen({super.key});

  @override
  ConsumerState<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends ConsumerState<LoginScreen> {
  final _formKey   = GlobalKey<FormState>();
  final _emailCtrl = TextEditingController();
  final _passCtrl  = TextEditingController();
  bool _obscure    = true;

  @override
  void dispose() {
    _emailCtrl.dispose();
    _passCtrl.dispose();
    super.dispose();
  }

  Future<void> _handleLogin() async {
    if (!_formKey.currentState!.validate()) return;
    final auth = ref.read(authProviderProvider);
    final ok = await auth.login(
      email: _emailCtrl.text.trim(),
      password: _passCtrl.text,
    );
    if (!mounted) return;
    if (!ok && auth.error != null) _err(auth.error!);
  }

  Future<void> _handleGuest() async {
    final auth = ref.read(authProviderProvider);
    final ok = await auth.signInAsGuest();
    if (!mounted) return;
    if (!ok && auth.error != null) _err(auth.error!);
  }

  void _err(String msg) {
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(
      content: Text(msg),
      backgroundColor: Colors.red.shade700,
      behavior: SnackBarBehavior.floating,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
    ));
  }

  @override
  Widget build(BuildContext context) {
    final auth = ref.watch(authProviderProvider);
    final size = MediaQuery.of(context).size;

    return Scaffold(
      backgroundColor: const Color(0xFF082028),
      resizeToAvoidBottomInset: true,
      body: Stack(
        children: [
          const Positioned.fill(child: AuthBackground()),
          SafeArea(
            child: SingleChildScrollView(
              padding: EdgeInsets.only(
                bottom: MediaQuery.of(context).viewInsets.bottom + 24,
              ),
              child: ConstrainedBox(
                constraints: BoxConstraints(
                  minHeight: size.height
                      - MediaQuery.of(context).padding.top
                      - MediaQuery.of(context).padding.bottom,
                ),
                child: IntrinsicHeight(
                  child: Column(
                    children: [
                      // ── Hero ───────────────────────────────────────────────
                      const SizedBox(height: 64),
                      Image.asset('assets/logo/appIcon.png',
                          width: 130, height: 130, fit: BoxFit.contain),
                      const SizedBox(height: 20),
                      const Text(
                        'بحّار',
                        style: TextStyle(
                          fontSize: 44,
                          fontWeight: FontWeight.bold,
                          color: Colors.white,
                        ),
                      ),
                      const SizedBox(height: 6),
                      Text(
                        'Your Smart Fishing Companion.',
                        style: TextStyle(
                          fontSize: 13,
                          color: Colors.white.withValues(alpha: 0.55),
                          letterSpacing: 0.4,
                        ),
                      ),
                      const SizedBox(height: 52),

                      // ── Form ───────────────────────────────────────────────
                      Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 24),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.stretch,
                          children: [
                            Form(
                              key: _formKey,
                              child: Column(
                                children: [
                                  AuthField(
                                    controller: _emailCtrl,
                                    label: 'Email',
                                    icon: Icons.email_outlined,
                                    keyboardType: TextInputType.emailAddress,
                                    validator: AuthenticationValidation.validateEmail,
                                  ),
                                  const SizedBox(height: 14),
                                  AuthField(
                                    controller: _passCtrl,
                                    label: 'Password',
                                    icon: Icons.lock_outline,
                                    obscure: _obscure,
                                    validator: AuthenticationValidation.validatePassword,
                                    suffixIcon: IconButton(
                                      icon: Icon(
                                        _obscure
                                            ? Icons.visibility_off_outlined
                                            : Icons.visibility_outlined,
                                        size: 18,
                                        color: const Color.fromARGB(255, 33, 28, 66),
                                      ),
                                      onPressed: () => setState(
                                          () => _obscure = !_obscure),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            const SizedBox(height: 26),
                            AuthGradientButton(
                              label: 'Sign In',
                              icon: Icons.login_rounded,
                              isLoading: auth.isLoading,
                              onPressed: auth.isLoading ? null : _handleLogin,
                            ),
                            const SizedBox(height: 14),
                            SizedBox(
                              height: 50,
                              child: OutlinedButton.icon(
                                onPressed:
                                    auth.isLoading ? null : _handleGuest,
                                icon: const Icon(Icons.person_outline,
                                    size: 16, color: Colors.white60),
                                label: const Text('Continue as Guest',
                                    style: TextStyle(
                                        fontSize: 14,
                                        color: Colors.white70)),
                                style: OutlinedButton.styleFrom(
                                  side: BorderSide(
                                      color: Colors.white
                                          .withValues(alpha: 0.18)),
                                  shape: RoundedRectangleBorder(
                                      borderRadius:
                                          BorderRadius.circular(14)),
                                ),
                              ),
                            ),
                            const SizedBox(height: 28),
                            Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Text("Don't have an account? ",
                                    style: TextStyle(
                                        fontSize: 13,
                                        color: Colors.white
                                            .withValues(alpha: 0.40))),
                                GestureDetector(
                                  onTap: () => Navigator.push(
                                      context,
                                      MaterialPageRoute(
                                          builder: (_) =>
                                              const SignUpScreen())),
                                  child: const Text('Sign Up',
                                      style: TextStyle(
                                          fontSize: 13,
                                          color: kAuthTeal,
                                          fontWeight: FontWeight.bold)),
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 24),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

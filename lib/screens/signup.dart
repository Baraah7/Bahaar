import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../providers/authentication_provider.dart';
import '../utilities/authentication_validation.dart';
import 'auth_background.dart';

class SignUpScreen extends ConsumerStatefulWidget {
  const SignUpScreen({super.key});

  @override
  ConsumerState<SignUpScreen> createState() => _SignUpScreenState();
}

class _SignUpScreenState extends ConsumerState<SignUpScreen> {
  final _formKey             = GlobalKey<FormState>();
  final _firstNameCtrl       = TextEditingController();
  final _lastNameCtrl        = TextEditingController();
  final _usernameCtrl        = TextEditingController();
  final _emailCtrl           = TextEditingController();
  final _passCtrl            = TextEditingController();
  final _confirmPassCtrl     = TextEditingController();
  bool _obscurePass          = true;
  bool _obscureConfirm       = true;

  @override
  void dispose() {
    _firstNameCtrl.dispose();
    _lastNameCtrl.dispose();
    _usernameCtrl.dispose();
    _emailCtrl.dispose();
    _passCtrl.dispose();
    _confirmPassCtrl.dispose();
    super.dispose();
  }

  Future<void> _handleSignUp() async {
    if (!_formKey.currentState!.validate()) return;
    final auth = ref.read(authProviderProvider);
    await auth.register(
      firstName: _firstNameCtrl.text.trim(),
      lastName:  _lastNameCtrl.text.trim(),
      userName:  _usernameCtrl.text.trim(),
      email:     _emailCtrl.text.trim(),
      password:  _passCtrl.text,
    );
    if (!mounted) return;
    if (auth.error != null) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
        content: Text(auth.error!),
        backgroundColor: Colors.red.shade700,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      ));
    } else {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
        content: const Text('Registration successful!'),
        backgroundColor: Colors.green.shade700,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      ));
    }
  }

  void _comingSoon() {
    ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
      content: Text('Social sign-up coming soon'),
      behavior: SnackBarBehavior.floating,
    ));
  }

  @override
  Widget build(BuildContext context) {
    final auth = ref.watch(authProviderProvider);

    return Scaffold(
      backgroundColor: const Color(0xFF082028),
      resizeToAvoidBottomInset: true,
      body: Stack(
        children: [
          // ── Mesh gradient background ──────────────────────────────────────
          const Positioned.fill(child: AuthBackground()),

          // ── Content ───────────────────────────────────────────────────────
          SafeArea(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [

                // ── Top bar ─────────────────────────────────────────────────
                Padding(
                  padding: const EdgeInsets.fromLTRB(20, 12, 20, 0),
                  child: Row(
                    children: [
                      GestureDetector(
                        onTap: () => Navigator.pop(context),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(Icons.arrow_back_ios_new_rounded,
                                size: 14,
                                color: Colors.white.withValues(alpha: 0.70)),
                            const SizedBox(width: 4),
                            Text(
                              'Back',
                              style: TextStyle(
                                fontSize: 14,
                                color: Colors.white.withValues(alpha: 0.70),
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),

                // ── Scrollable form ──────────────────────────────────────────
                Expanded(
                  child: SingleChildScrollView(
                    padding: EdgeInsets.only(
                      bottom: MediaQuery.of(context).viewInsets.bottom + 32,
                    ),
                    child: Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 28),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [

                          // ── Header ────────────────────────────────────────
                          const SizedBox(height: 20),
                          Image.asset('assets/logo/appIcon.png',
                              width: 64, height: 64, fit: BoxFit.contain),
                          const SizedBox(height: 16),
                          const Text(
                            'Create Your Account',
                            style: TextStyle(
                              fontSize: 30,
                              fontWeight: FontWeight.bold,
                              color: Colors.white,
                              letterSpacing: -0.3,
                            ),
                          ),
                          const SizedBox(height: 6),
                          Text(
                            "We're here to help you reach the peaks\nof fishing. Are you ready?",
                            style: TextStyle(
                              fontSize: 13,
                              color: Colors.white.withValues(alpha: 0.50),
                              height: 1.6,
                            ),
                          ),
                          const SizedBox(height: 28),

                          // ── Form ──────────────────────────────────────────
                          Form(
                            key: _formKey,
                            child: Column(
                              children: [
                                // First & Last name side by side
                                Row(
                                  children: [
                                    Expanded(
                                      child: AuthField(
                                        controller: _firstNameCtrl,
                                        label: 'First name',
                                        validator: AuthenticationValidation.validateName,
                                      ),
                                    ),
                                    const SizedBox(width: 12),
                                    Expanded(
                                      child: AuthField(
                                        controller: _lastNameCtrl,
                                        label: 'Last name',
                                        validator: AuthenticationValidation.validateName,
                                      ),
                                    ),
                                  ],
                                ),
                                const SizedBox(height: 14),
                                AuthField(
                                  controller: _usernameCtrl,
                                  label: 'Username',
                                  validator: AuthenticationValidation.validateUsername,
                                ),
                                const SizedBox(height: 14),
                                AuthField(
                                  controller: _emailCtrl,
                                  label: 'Enter email',
                                  keyboardType: TextInputType.emailAddress,
                                  validator: AuthenticationValidation.validateEmail,
                                ),
                                const SizedBox(height: 14),
                                AuthField(
                                  controller: _passCtrl,
                                  label: 'Enter password',
                                  obscure: _obscurePass,
                                  validator: AuthenticationValidation.validatePassword,
                                  suffixIcon: IconButton(
                                    icon: Icon(
                                      _obscurePass
                                          ? Icons.visibility_off_outlined
                                          : Icons.visibility_outlined,
                                      size: 18,
                                      color: const Color(0xFF4A7A80),
                                    ),
                                    onPressed: () => setState(
                                        () => _obscurePass = !_obscurePass),
                                  ),
                                ),
                                const SizedBox(height: 14),
                                AuthField(
                                  controller: _confirmPassCtrl,
                                  label: 'Confirm password',
                                  obscure: _obscureConfirm,
                                  validator: (val) {
                                    if (val == null || val.isEmpty) {
                                      return 'Please confirm your password';
                                    }
                                    if (val != _passCtrl.text) {
                                      return 'Passwords do not match';
                                    }
                                    return null;
                                  },
                                  suffixIcon: IconButton(
                                    icon: Icon(
                                      _obscureConfirm
                                          ? Icons.visibility_off_outlined
                                          : Icons.visibility_outlined,
                                      size: 18,
                                      color: const Color(0xFF4A7A80),
                                    ),
                                    onPressed: () => setState(
                                        () => _obscureConfirm = !_obscureConfirm),
                                  ),
                                ),
                              ],
                            ),
                          ),

                          // ── Forgot password link ───────────────────────────
                          const SizedBox(height: 10),
                          Align(
                            alignment: Alignment.centerRight,
                            child: Text(
                              'Forgot password?',
                              style: TextStyle(
                                fontSize: 12.5,
                                color: kAuthTeal.withValues(alpha: 0.85),
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ),

                          const SizedBox(height: 28),

                          // ── Get Started button ────────────────────────────
                          AuthGradientButton(
                            label: 'Get Started',
                            isLoading: auth.isLoading,
                            onPressed: auth.isLoading ? null : _handleSignUp,
                          ),

                          const SizedBox(height: 22),

                          // ── OR divider ────────────────────────────────────
                          Row(children: [
                            Expanded(child: Divider(color: Colors.white.withValues(alpha: 0.14))),
                            Padding(
                              padding: const EdgeInsets.symmetric(horizontal: 14),
                              child: Text(
                                'OR',
                                style: TextStyle(
                                  color: Colors.white.withValues(alpha: 0.75),
                                  fontSize: 12,
                                ),
                              ),
                            ),
                            Expanded(child: Divider(color: Colors.white.withValues(alpha: 0.14))),
                          ]),

                          const SizedBox(height: 18),

                          // ── Login link ────────────────────────────────────
                          Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Text(
                                'Already have an account? ',
                                style: TextStyle(
                                  fontSize: 13,
                                  color: Colors.white.withValues(alpha: 0.38),
                                ),
                              ),
                              GestureDetector(
                                onTap: () => Navigator.pop(context),
                                child: const Text(
                                  'Log In',
                                  style: TextStyle(
                                    fontSize: 13,
                                    color: kAuthTeal,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 16),
                        ],
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

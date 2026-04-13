import 'package:bahaar/core/constants/app_colors.dart';
import 'package:bahaar/l10n/app_localizations.dart';
import 'package:bahaar/providers/authentication/authentication_provider.dart';
import 'package:bahaar/utilities/authentication/authentication_validation.dart';
import 'package:bahaar/widgets/common/app_snackbar.dart';
import 'package:bahaar/widgets/common/language_toggle.dart';
import 'package:bahaar/widgets/profile/auth_background.dart';
import 'package:bahaar/widgets/profile/auth_background.dart' as widgets;
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
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

  Future<void> _handleForgotPassword() async {
    final l10n = AppLocalizations.of(context)!;
    final lang = l10n.localeName;
    final emailCtrl = TextEditingController();

    final submitted = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: AppColors.tan.withValues(alpha: 0.80),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Text(
          l10n.forgotPassword,
          style: const TextStyle(color: Color.fromARGB(255, 65, 53, 39), fontSize: 18, fontWeight: FontWeight.bold),
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              l10n.forgotPasswordHint,
              style: TextStyle(color: Color.fromARGB(255, 65, 53, 39), fontSize: 13, height: 1.5),
            ),
            const SizedBox(height: 16),
            TextField(
              controller: emailCtrl,
              keyboardType: TextInputType.emailAddress,
              style: const TextStyle(color: Color.fromARGB(255, 99, 81, 59)),
              decoration: InputDecoration(
                hintText: l10n.enterEmail,
                hintStyle: TextStyle(color: const Color.fromARGB(255, 99, 81, 59).withValues(alpha: 0.45)),
                filled: true,
                fillColor: Colors.white.withValues(alpha: 0.08),
                contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(10),
                  borderSide: BorderSide.none,
                ),
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: Text(l10n.cancel, style: TextStyle(color: Color.fromARGB(255, 65, 53, 39).withValues(alpha: 0.6))),
          ),
          TextButton(
            onPressed: () => Navigator.pop(ctx, true),
            child: Text(l10n.sendResetLink, style: const TextStyle(color: Color.fromARGB(255, 99, 81, 59), fontWeight: FontWeight.bold)),
          ),
        ],
      ),
    );

    if (submitted != true || !mounted) return;
    final email = emailCtrl.text.trim();
    if (email.isEmpty) return;

    final auth = ref.read(authProviderProvider);
    final ok = await auth.resetPassword(email, languageCode: lang);
    if (!mounted) return;
    showAppSnackBar(context, ok ? l10n.resetLinkSent : l10n.resetLinkFailed,
        isError: !ok);
  }

  Future<void> _handleGuest() async {
    final auth = ref.read(authProviderProvider);
    final ok = await auth.signInAsGuest();
    if (!mounted) return;
    if (!ok && auth.error != null) _err(auth.error!);
  }

  void _err(String msg) {
    showAppSnackBar(context, msg, isError: true);
  }
  
  @override
  Widget build(BuildContext context) {
    final auth = ref.watch(authProviderProvider);
    final l10n = AppLocalizations.of(context)!;
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
                bottom: MediaQuery.of(context).viewInsets.bottom + 32,
              ),
              child: ConstrainedBox(
                constraints: BoxConstraints(
                  minHeight: size.height
                      - MediaQuery.of(context).padding.top
                      - MediaQuery.of(context).padding.bottom,
                ),
                child: IntrinsicHeight(
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 28),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [

                        // ── Hero ─────────────────────────────────────────────
                        const SizedBox(height: 65),
                        Center(
                          child: Image.asset(
                            'assets/logo/appIcon.png',
                            width: 82, height: 82, fit: BoxFit.contain,
                          ),
                        ),
                        const SizedBox(height: 22),
                        Center(
                          child: Text(
                            l10n.appName,
                            style: const TextStyle(
                              fontFamily: 'Zain',
                              fontSize: 34,
                              fontWeight: FontWeight.bold,
                              color: AppColors.cream,
                              letterSpacing: -0.5,
                            ),
                          ),
                        ),
                        const SizedBox(height: 8),
                        Center(
                          child: Text(
                            'Ready to continue your journey?\nYour path is right here.',
                            textAlign: TextAlign.center,
                            style: TextStyle(
                              fontFamily: 'Zain',
                              fontSize: 15,
                              color: Colors.white.withValues(alpha: 0.70),
                              height: 1.6,
                            ),
                          ),
                        ),
                        const SizedBox(height: 42),

                        // ── Form ─────────────────────────────────────────────
                        Form(
                          key: _formKey,
                          child: Column(
                            children: [
                              widgets.AuthField(
                                controller: _emailCtrl,
                                label: 'Enter email',
                                keyboardType: TextInputType.emailAddress,
                                validator: AuthenticationValidation.validateEmail,
                              ),
                              const SizedBox(height: 14),
                              widgets.AuthField(
                                controller: _passCtrl,
                                label: 'Password',
                                obscure: _obscure,
                                validator: AuthenticationValidation.validatePassword,
                                suffixIcon: IconButton(
                                  icon: Icon(
                                    _obscure
                                        ? Icons.visibility_off_outlined
                                        : Icons.visibility_outlined,
                                    size: 18,
                                    color: Colors.grey.shade700,
                                  ),
                                  onPressed: () =>
                                      setState(() => _obscure = !_obscure),
                                ),
                              ),
                            ],
                          ),
                        ),

                        // ── Forgot password ───────────────────────────────────
                        const SizedBox(height: 10),
                        Align(
                          alignment: Alignment.centerRight,
                          child: GestureDetector(
                            onTap: () => ScaffoldMessenger.of(context)
                                .showSnackBar(const SnackBar(
                              content: Text('Password reset coming soon'),
                              behavior: SnackBarBehavior.floating,
                            )),
                            child: Text(
                              'Forgot password?',
                              style: TextStyle(
                                fontFamily: 'Zain',
                                fontSize: 14,
                                color: Colors.white.withValues(alpha: 0.70),
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ),
                        ),

                        const SizedBox(height: 30),

                        // ── Log In button ─────────────────────────────────────
                        AuthGradientButton(
                          label: 'Log In',
                          isLoading: auth.isLoading,
                          onPressed: auth.isLoading ? null : _handleLogin,
                        ),

                        const SizedBox(height: 22),

                        // ── OR divider ────────────────────────────────────────
                        Row(children: [
                          Expanded(child: Divider(color: Colors.white.withValues(alpha: 0.14))),
                          Padding(
                            padding: const EdgeInsets.symmetric(horizontal: 14),
                            child: Text(
                              'OR',
                              style: TextStyle(
                                fontFamily: 'Zain',
                                color: Colors.white.withValues(alpha: 0.75),
                                fontSize: 14,
                              ),
                            ),
                          ),
                          Expanded(child: Divider(color: Colors.white.withValues(alpha: 0.14))),
                        ]),

                        const SizedBox(height: 18),

                        // ── Continue as Guest ─────────────────────────────────
                        Center(
                          child: GestureDetector(
                            onTap: auth.isLoading ? null : _handleGuest,
                            child: Text(
                              'Continue as Guest',
                              style: TextStyle(
                                fontFamily: 'Zain',
                                fontSize: 14,
                                color: Colors.white.withValues(alpha: 0.75),
                                decoration: TextDecoration.underline,
                                decorationColor: Colors.white,
                              ),
                            ),
                          ),
                        ),

                        const SizedBox(height: 16),

                        // ── Sign up link ──────────────────────────────────────
                        Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Text(
                              "Don't have an account? ",
                              style: TextStyle(
                                fontFamily: 'Zain',
                                fontSize: 14,
                                color: Colors.white.withValues(alpha: 0.75),
                              ),
                            ),
                            GestureDetector(
                              onTap: () => Navigator.push(
                                context,
                                MaterialPageRoute(
                                    builder: (_) => const SignUpScreen()),
                              ),
                              child: Text(
                                'Sign Up',
                                style: TextStyle(
                                  fontFamily: 'Zain',
                                  fontSize: 14,
                                  color: AppColors.tan.withValues(alpha: 0.85),
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 24),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ),
          Positioned(
            top: MediaQuery.of(context).padding.top + 12,
            right: 16,
            child: const LanguageToggle(),
          ),
        ],
      ),
    );
  }
}

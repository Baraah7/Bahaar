import 'package:bahaar/constants/app_colors.dart';
import 'package:bahaar/l10n/app/app_localization.dart';
import 'package:bahaar/l10n/profile/profile_localizations.dart';
import 'package:bahaar/providers/authentication/authentication_provider.dart';
import 'package:bahaar/utilities/authentication/authentication_validation.dart';
import 'package:bahaar/widgets/common/app_snackbar.dart';
import 'package:bahaar/widgets/common/language_toggle.dart';
import 'package:bahaar/widgets/profile/auth_background.dart' as widgets;
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'signup_screen.dart';

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
    final l10n = ProfileLocalizations.of(context);
    final app = AppLocalization.of(context);
    final lang = app.localeName;
    final emailCtrl = TextEditingController();

    final submitted = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: AppColors.tan,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Text(
          l10n.forgotPassword,
          style: const TextStyle(
            color: Color.fromARGB(255, 65, 53, 39), 
            fontSize: 18, 
            fontWeight: FontWeight.bold
          ),
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              l10n.forgotPasswordHint,
              style: TextStyle(
                color: Color.fromARGB(255, 65, 53, 39), 
                fontSize: 16, 
                height: 1.5
              ),
            ),
            const SizedBox(height: 16),
            TextField(
              controller: emailCtrl,
              keyboardType: TextInputType.emailAddress,
              style: const TextStyle(color: Color.fromARGB(255, 99, 81, 59)),
              decoration: InputDecoration(
                hintText: l10n.enterEmail,
                hintStyle: TextStyle(color: const Color.fromARGB(255, 99, 81, 59).withValues(alpha: 0.55)),
                filled: true,
                fillColor: Colors.white.withValues(alpha: 0.2),
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
            child: Text(app.cancel, 
            style: TextStyle(
              fontSize: 16,
              color: Color.fromARGB(255, 65, 53, 39).withValues(alpha: 0.6)
              )),
          ),
          TextButton(
            onPressed: () => Navigator.pop(ctx, true),
            child: Text(l10n.sendResetLink, 
            style: const TextStyle(
              fontSize: 16,
              color: Color.fromARGB(255, 99, 81, 59), 
              fontWeight: FontWeight.bold
            )),
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
    final app = AppLocalization.of(context);
    final l10n = ProfileLocalizations.of(context);
    final size = MediaQuery.of(context).size;

    return Scaffold(
      backgroundColor: const Color(0xFF082028),
      resizeToAvoidBottomInset: true,
      body: Stack(
        children: [
          const Positioned.fill(child: widgets.AuthBackground()),
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
                        const SizedBox(height: 120),
                        Center(
                          child: Image.asset(
                            'assets/logo/appIcon.png',
                            width: 82, height: 82, fit: BoxFit.contain,
                          ),
                        ),
                        const SizedBox(height: 50),
                        Center(
                          child: Text(
                            app.appName,
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
                            l10n.loginSubtitle,
                            textAlign: TextAlign.center,
                            style: TextStyle(
                              fontFamily: 'Zain',
                              fontSize: 16,
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
                                label: l10n.enterEmail,
                                keyboardType: TextInputType.emailAddress,
                                validator: AuthenticationValidation.validateEmail,
                              ),
                              const SizedBox(height: 14),
                              widgets.AuthField(
                                controller: _passCtrl,
                                label: l10n.password,
                                obscure: _obscure,
                                validator: AuthenticationValidation.validatePassword,
                                suffixIcon: IconButton(
                                  icon: Icon(
                                    _obscure
                                        ? Icons.visibility_off_outlined
                                        : Icons.visibility_outlined,
                                    size: 18,
                                    color: Colors.white.withValues(alpha: 0.6),
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
                            onTap: _handleForgotPassword,
                            child: Text(
                              l10n.forgotPassword,
                              style: TextStyle(
                                fontFamily: 'Zain',
                                fontSize: 16,
                                color: Colors.white.withValues(alpha: 0.70),
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ),
                        ),

                        const SizedBox(height: 30),

                        // ── Log In button ─────────────────────────────────────
                        widgets.AuthGradientButton(
                          label: l10n.logIn,
                          isLoading: auth.isLoading,
                          onPressed: auth.isLoading ? null : _handleLogin,
                        ),

                        const SizedBox(height: 30),

                        // ── OR divider ────────────────────────────────────────
                        Row(children: [
                          Expanded(child: Divider(color: Colors.white.withValues(alpha: 0.14))),
                          Padding(
                            padding: const EdgeInsets.symmetric(horizontal: 14),
                            child: Text(
                              l10n.orDivider,
                              style: TextStyle(
                                fontFamily: 'Zain',
                                color: Colors.white.withValues(alpha: 0.75),
                                fontSize: 16,
                              ),
                            ),
                          ),
                          Expanded(child: Divider(color: Colors.white.withValues(alpha: 0.14))),
                        ]),

                        const SizedBox(height: 30),

                        // ── Continue as Guest ─────────────────────────────────
                        Center(
                          child: GestureDetector(
                            onTap: auth.isLoading ? null : _handleGuest,
                            child: Text(
                              l10n.continueAsGuest,
                              style: TextStyle(
                                fontFamily: 'Zain',
                                fontSize: 16,
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
                              l10n.dontHaveAccount,
                              style: TextStyle(
                                fontFamily: 'Zain',
                                fontSize: 16,
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
                                l10n.signUp,
                                style: TextStyle(
                                  fontFamily: 'Zain',
                                  fontSize: 16,
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

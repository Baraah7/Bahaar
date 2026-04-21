import 'package:bahaar/core/constants/app_colors.dart';
import 'package:bahaar/l10n/app/app_localization.dart';
import 'package:bahaar/l10n/profile/profile_localizations.dart';
import 'package:bahaar/providers/authentication/authentication_provider.dart';
import 'package:bahaar/utilities/authentication/authentication_validation.dart';
import 'package:bahaar/widgets/common/app_snackbar.dart';
import 'package:bahaar/widgets/common/language_toggle.dart';
import 'package:bahaar/widgets/profile/auth_background.dart';
import 'package:bahaar/widgets/profile/auth_background.dart' as widgets;
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

class SignUpScreen extends ConsumerStatefulWidget {
  const SignUpScreen({super.key});

  @override
  ConsumerState<SignUpScreen> createState() => _SignUpScreenState();
}

class _SignUpScreenState extends ConsumerState<SignUpScreen> {
  final _formKey         = GlobalKey<FormState>();
  final _firstNameCtrl   = TextEditingController();
  final _lastNameCtrl    = TextEditingController();
  final _usernameCtrl    = TextEditingController();
  final _emailCtrl       = TextEditingController();
  final _passCtrl        = TextEditingController();
  final _confirmPassCtrl = TextEditingController();
  bool _obscurePass      = true;
  bool _obscureConfirm   = true;

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
    final l10n = ProfileLocalizations.of(context);
    if (auth.error != null) {
      showAppSnackBar(context, auth.error!, isError: true);
    } else {
      showAppSnackBar(context, l10n.registrationSuccessful);
    }
  }

  @override
  Widget build(BuildContext context) {
    final auth = ref.watch(authProviderProvider);
    final l10n = ProfileLocalizations.of(context);
    final app = AppLocalization.of(context);
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

                        // ── Hero ───────────────────────────────────────────────
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
                            l10n.signupSubtitle,
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

                        // ── Form ───────────────────────────────────────────────
                        Form(
                          key: _formKey,
                          child: Column(
                            children: [
                              // First & Last name side by side
                              Row(
                                children: [
                                  Expanded(
                                    child: widgets.AuthField(
                                      controller: _firstNameCtrl,
                                      label: l10n.firstName,
                                      validator: AuthenticationValidation.validateName,
                                    ),
                                  ),
                                  const SizedBox(width: 12),
                                  Expanded(
                                    child: widgets.AuthField(
                                      controller: _lastNameCtrl,
                                      label: l10n.lastName,
                                      validator: AuthenticationValidation.validateName,
                                    ),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 14),
                              widgets.AuthField(
                                controller: _usernameCtrl,
                                label: l10n.usernameField,
                                validator: AuthenticationValidation.validateUsername,
                              ),
                              const SizedBox(height: 14),
                              widgets.AuthField(
                                controller: _emailCtrl,
                                label: l10n.enterEmail,
                                keyboardType: TextInputType.emailAddress,
                                validator: AuthenticationValidation.validateEmail,
                              ),
                              const SizedBox(height: 14),
                              widgets.AuthField(
                                controller: _passCtrl,
                                label: l10n.enterPassword,
                                obscure: _obscurePass,
                                validator: AuthenticationValidation.validatePassword,
                                suffixIcon: IconButton(
                                  icon: Icon(
                                    _obscurePass
                                        ? Icons.visibility_off_outlined
                                        : Icons.visibility_outlined,
                                    size: 18,
                                    color: Colors.white.withValues(alpha: 0.70),
                                  ),
                                  onPressed: () =>
                                      setState(() => _obscurePass = !_obscurePass),
                                ),
                              ),
                              const SizedBox(height: 14),
                              widgets.AuthField(
                                controller: _confirmPassCtrl,
                                label: l10n.confirmPasswordField,
                                obscure: _obscureConfirm,
                                validator: AuthenticationValidation.validateConfirmPassword(
                                    _passCtrl.text),
                                suffixIcon: IconButton(
                                  icon: Icon(
                                    _obscureConfirm
                                        ? Icons.visibility_off_outlined
                                        : Icons.visibility_outlined,
                                    size: 18,
                                    color: Colors.white.withValues(alpha: 0.70),
                                  ),
                                  onPressed: () =>
                                      setState(() => _obscureConfirm = !_obscureConfirm),
                                ),
                              ),
                            ],
                          ),
                        ),

                        const SizedBox(height: 30),

                        // ── Get Started button ─────────────────────────────────
                        widgets.AuthGradientButton(
                          label: l10n.getStarted,
                          isLoading: auth.isLoading,
                          onPressed: auth.isLoading ? null : _handleSignUp,
                        ),

                        const SizedBox(height: 22),

                        // ── OR divider ─────────────────────────────────────────
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

                        const SizedBox(height: 18),

                        // ── Login link ─────────────────────────────────────────
                        Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Text(
                              l10n.alreadyHaveAccount,
                              style: TextStyle(
                                fontFamily: 'Zain',
                                fontSize: 16,
                                color: Colors.white.withValues(alpha: 0.75),
                              ),
                            ),
                            GestureDetector(
                              onTap: () => Navigator.pop(context),
                              child: Text(
                                app.logIn,
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

          // ── Language toggle ────────────────────────────────────────────────
          Positioned(
            top: MediaQuery.of(context).padding.top + 12,
            right: 16,
            child: const LanguageToggle(),
          ),

          // ── Back button ────────────────────────────────────────────────────
          Positioned(
            top: MediaQuery.of(context).padding.top + 12,
            left: 16,
            child: GestureDetector(
              onTap: () => Navigator.pop(context),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(Icons.arrow_back_ios_new_rounded,
                      size: 16,
                      color: Colors.white.withValues(alpha: 0.70)),
                  const SizedBox(width: 4),
                  Text(
                    l10n.backButton,
                    style: TextStyle(
                      fontFamily: 'Zain',
                      fontSize: 16,
                      color: Colors.white.withValues(alpha: 0.70),
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

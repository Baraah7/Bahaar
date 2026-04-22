import 'package:bahaar/core/constants/app_colors.dart';
import 'package:bahaar/l10n/app/app_localization.dart';
import 'package:bahaar/providers/language/language_provider.dart';
import 'package:bahaar/screens/authentication/login.dart';
import 'package:bahaar/screens/authentication/profile_screen.dart';
import 'package:bahaar/widgets/common/app_card.dart';
import 'package:bahaar/widgets/common/card_divider.dart';
import 'package:bahaar/widgets/common/gradient_screen.dart';
import 'package:bahaar/widgets/common/section_label.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:firebase_auth/firebase_auth.dart';

class SettingsScreen extends ConsumerWidget {
  const SettingsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final locale = ref.watch(languageProvider);
    final l10n = AppLocalization.of(context);
    final firebaseUser = FirebaseAuth.instance.currentUser;
    final email = firebaseUser?.email;
    final isGuest = firebaseUser?.isAnonymous ?? true;

    return GradientScreen(
      expandedHeight: 140,
      flexContent: SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(24, 60, 24, 20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisAlignment: MainAxisAlignment.end,
            children: [
              Text(
                l10n.settings,
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 26,
                  fontWeight: FontWeight.w800,
                ),
              ),
              const SizedBox(height: 3),
              Text(
                isGuest ? l10n.guestMode : (email ?? ''),
                style: TextStyle(
                  color: Colors.white.withValues(alpha: 0.7),
                  fontSize: 13,
                  fontWeight: FontWeight.w400,
                ),
              ),
            ],
          ),
        ),
      ),
      body: Padding(
        padding: EdgeInsets.fromLTRB(
            16, 28, 16, MediaQuery.of(context).padding.bottom + 40),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // ── Language ───────────────────────────────────────────
            SectionLabel(l10n.language),
            _LanguageToggle(
              currentCode: locale.languageCode,
              englishLabel: "English",
              arabicLabel: l10n.arabic,
              onSelect: (code) => ref
                  .read(languageProvider.notifier)
                  .setLanguage(Locale(code)),
            ),

            const SizedBox(height: 28),

            // ── Account ────────────────────────────────────────────
            SectionLabel(l10n.account),
            AppCard(
              child: Column(children: [
                _SettingsTile(
                  icon: isGuest
                      ? Icons.person_outline_rounded
                      : Icons.verified_user_outlined,
                  iconBg: AppColors.primary.withValues(alpha: 0.10),
                  iconColor: AppColors.primary,
                  title: isGuest ? l10n.guest : (email ?? ''),
                  subtitle: isGuest ? l10n.guestMode : l10n.signedIn,
                  trailing: const Icon(Icons.chevron_right,
                      color: Colors.grey, size: 20),
                  onTap: () => Navigator.push(context,
                      MaterialPageRoute(
                          builder: (_) => const ProfileScreen())),
                ),
              ]),
            ),

            const SizedBox(height: 28),

            // ── About ──────────────────────────────────────────────
            SectionLabel(l10n.about),
            AppCard(
              child: Column(children: [
                _SettingsTile(
                  icon: Icons.anchor_rounded,
                  iconBg: AppColors.accent.withValues(alpha: 0.12),
                  iconColor: AppColors.accent,
                  title: l10n.appName,
                  subtitle: '${l10n.version} 1.0.0',
                ),
                const CardDivider(),
                _SettingsTile(
                  icon: Icons.shield_outlined,
                  iconBg: AppColors.tan.withValues(alpha: 0.30),
                  iconColor: AppColors.brown,
                  title: l10n.privacyPolicy,
                  trailing: const Icon(Icons.chevron_right,
                      color: Colors.grey, size: 20),
                  onTap: () => _showPrivacyPolicy(context, l10n),
                ),
              ]),
            ),

            const SizedBox(height: 36),

            // ── Sign In / Sign Out ────────────────────────────────
            _SignOutButton(
              isSignIn: isGuest,
              label: isGuest ? l10n.signIn : l10n.signOut,
              onTap: isGuest
                  ? () => Navigator.push(
                        context,
                        MaterialPageRoute(
                            builder: (_) => const LoginScreen()),
                      )
                  : () => _confirmSignOut(context, ref, l10n),
            ),
          ],
        ),
      ),
    );
  }

  void _confirmSignOut(
      BuildContext context, WidgetRef ref, AppLocalization l10n) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: Colors.white,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: AppColors.red.withValues(alpha: 0.10),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Icon(Icons.logout_rounded, color: AppColors.red, size: 22),
            ),
            const SizedBox(width: 12),
            Text(l10n.signOut,
                style: const TextStyle(
                    fontSize: 17, fontWeight: FontWeight.w700)),
          ],
        ),
        content: Text(l10n.areYouSureSignOut,
            style: const TextStyle(color: Colors.grey)),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text(l10n.cancel,
                style: const TextStyle(color: AppColors.primary)),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(context);
              FirebaseAuth.instance.signOut();
              Navigator.of(context).popUntil((route) => route.isFirst);
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.red,
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(10)),
            ),
            child: Text(l10n.signOut),
          ),
        ],
      ),
    );
  }

  void _showPrivacyPolicy(BuildContext context, AppLocalization l10n) {
    showDialog(
      context: context,
      builder: (_) => Dialog(
        backgroundColor: Colors.white,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(20),
              decoration: const BoxDecoration(
                gradient: LinearGradient(
                  colors: [AppColors.tan, AppColors.brown],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                borderRadius: BorderRadius.only(
                  topLeft: Radius.circular(20),
                  topRight: Radius.circular(20),
                ),
              ),
              child: Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: Colors.white.withValues(alpha: 0.2),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: const Icon(Icons.shield_outlined,
                        color: Colors.white, size: 20),
                  ),
                  const SizedBox(width: 12),
                  Text(
                    l10n.privacyPolicy,
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 18,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ],
              ),
            ),
            SizedBox(
              height: 320,
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(20),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _PolicySection(title: l10n.policyDataCollection, body: l10n.policyDataCollectionBody),
                    _PolicySection(title: l10n.policyLocation, body: l10n.policyLocationBody),
                    _PolicySection(title: l10n.policyFishRecognition, body: l10n.policyFishRecognitionBody),
                    _PolicySection(title: l10n.policyAuthentication, body: l10n.policyAuthenticationBody),
                    _PolicySection(title: l10n.policyRetention, body: l10n.policyRetentionBody),
                    _PolicySection(title: l10n.policyContactSection, body: l10n.policyContactSectionBody),
                  ],
                ),
              ),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 0, 20, 20),
              child: SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: () => Navigator.pop(context),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.brown,
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12)),
                    padding: const EdgeInsets.symmetric(vertical: 14),
                  ),
                  child: Text(l10n.gotIt,
                      style: const TextStyle(fontWeight: FontWeight.w600)),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _PolicySection extends StatelessWidget {
  final String title;
  final String body;
  const _PolicySection({required this.title, required this.body});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: const TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.w700,
              color: AppColors.brown,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            body,
            style: const TextStyle(
              fontSize: 13,
              color: Color(0xFF555555),
              height: 1.5,
            ),
          ),
        ],
      ),
    );
  }
}

// ── Language toggle pill ──────────────────────────────────────────────────────

class _LanguageToggle extends StatelessWidget {
  final String currentCode;
  final String englishLabel;
  final String arabicLabel;
  final void Function(String) onSelect;

  const _LanguageToggle({
    required this.currentCode,
    required this.englishLabel,
    required this.arabicLabel,
    required this.onSelect,
  });

  @override
  Widget build(BuildContext context) {
    return AppCard(
      padding: const EdgeInsets.all(6),
      child: Row(
        children: [
          _LangOption(
            label: englishLabel,
            selected: currentCode == 'en',
            onTap: () => onSelect('en'),
          ),
          _LangOption(
            label: arabicLabel,
            selected: currentCode == 'ar',
            onTap: () => onSelect('ar'),
          ),
        ],
      ),
    );
  }
}

class _LangOption extends StatelessWidget {
  final String label;
  final bool selected;
  final VoidCallback onTap;

  const _LangOption({
    required this.label,
    required this.selected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: GestureDetector(
        onTap: onTap,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          padding: const EdgeInsets.symmetric(vertical: 14),
          decoration: BoxDecoration(
            color: selected ? AppColors.primary : Colors.transparent,
            borderRadius: BorderRadius.circular(12),
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text(
                label,
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                  color: selected ? Colors.white : const Color(0xFF1A1A2E),
                ),
              ),
              if (selected) ...[
                const SizedBox(width: 6),
                const Icon(Icons.check_circle_rounded,
                    color: Colors.white, size: 16),
              ],
            ],
          ),
        ),
      ),
    );
  }
}

// ── Sign out button ───────────────────────────────────────────────────────────

class _SignOutButton extends StatelessWidget {
  final VoidCallback onTap;
  final String label;
  final bool isSignIn;

  const _SignOutButton({
    required this.onTap,
    required this.label,
    this.isSignIn = false,
  });

  @override
  Widget build(BuildContext context) {
    final color = isSignIn ? AppColors.primary : AppColors.red;
    final icon = isSignIn ? Icons.login_rounded : Icons.logout_rounded;

    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.symmetric(vertical: 16),
        decoration: BoxDecoration(
          color: color.withValues(alpha: 0.10),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: color.withValues(alpha: 0.25)),
          boxShadow: [
            BoxShadow(
              color: color.withValues(alpha: 0.08),
              blurRadius: 12,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, color: color, size: 20),
            const SizedBox(width: 10),
            Text(
              label,
              style: TextStyle(
                color: color,
                fontSize: 15,
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ── Settings tile ─────────────────────────────────────────────────────────────

class _SettingsTile extends StatelessWidget {
  final IconData? icon;
  final Color? iconBg;
  final Color? iconColor;
  final String title;
  final String? subtitle;
  final Widget? trailing;
  final VoidCallback? onTap;

  const _SettingsTile({
    this.icon,
    this.iconBg,
    this.iconColor,
    required this.title,
    this.subtitle,
    this.trailing,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(16),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        child: Row(
          children: [
            Container(
              width: 42,
              height: 42,
              decoration: BoxDecoration(
                color: iconBg ?? Colors.grey.shade100,
                borderRadius: BorderRadius.circular(12),
              ),
              child: Icon(icon, color: iconColor ?? Colors.grey, size: 20),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: const TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.w500,
                      color: Color(0xFF1A1A2E),
                    ),
                  ),
                  if (subtitle != null) ...[
                    const SizedBox(height: 2),
                    Text(subtitle!,
                        style: const TextStyle(
                            fontSize: 12, color: Colors.grey)),
                  ],
                ],
              ),
            ),
            if (trailing != null) trailing!,
          ],
        ),
      ),
    );
  }
}

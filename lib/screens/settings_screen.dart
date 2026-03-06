import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../providers/language_provider.dart';
import '../l10n/app_localizations.dart';
import 'package:Bahaar/core/constants/app_colors.dart';

class SettingsScreen extends ConsumerWidget {
  const SettingsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final locale = ref.watch(languageProvider);
    final l10n = AppLocalizations.of(context)!;
    final email = FirebaseAuth.instance.currentUser?.email;
    final isSignedIn = email != null;

    return AnnotatedRegion<SystemUiOverlayStyle>(
      value: SystemUiOverlayStyle.light,
      child: Scaffold(
        backgroundColor: AppColors.cream,
        body: Column(
          children: [
            // ── Gradient header ──────────────────────────────────────────────
            _SettingsHeader(title: l10n.settings),

            // ── Scrollable body ──────────────────────────────────────────────
            Expanded(
              child: ListView(
                padding: const EdgeInsets.fromLTRB(16, 24, 16, 48),
                children: [
                  // Language
                  _SectionLabel(l10n.language),
                  const SizedBox(height: 10),
                  _SettingsCard(children: [
                    _SettingsTile(
                      iconWidget:
                          const Text('🇺🇸', style: TextStyle(fontSize: 20)),
                      iconBg: const Color(0xFFE8F0FE),
                      title: 'English',
                      trailing: locale.languageCode == 'en'
                          ? const Icon(Icons.check_circle_rounded,
                              color: AppColors.accent, size: 22)
                          : const Icon(Icons.radio_button_unchecked,
                              color: Colors.grey, size: 22),
                      onTap: () => ref
                          .read(languageProvider.notifier)
                          .setLanguage(const Locale('en')),
                    ),
                    const _TileDivider(),
                    _SettingsTile(
                      iconWidget:
                          const Text('🇸🇦', style: TextStyle(fontSize: 20)),
                      iconBg: const Color(0xFFE8F5E9),
                      title: 'العربية',
                      trailing: locale.languageCode == 'ar'
                          ? const Icon(Icons.check_circle_rounded,
                              color: AppColors.accent, size: 22)
                          : const Icon(Icons.radio_button_unchecked,
                              color: Colors.grey, size: 22),
                      onTap: () => ref
                          .read(languageProvider.notifier)
                          .setLanguage(const Locale('ar')),
                    ),
                  ]),

                  const SizedBox(height: 28),

                  // Account
                  _SectionLabel(l10n.account),
                  const SizedBox(height: 10),
                  _SettingsCard(children: [
                    _SettingsTile(
                      icon: Icons.person_outline_rounded,
                      iconBg: AppColors.primary.withValues(alpha: 0.10),
                      iconColor: AppColors.primary,
                      title: email ?? l10n.guest,
                      subtitle:
                          isSignedIn ? l10n.signedIn : l10n.guestMode,
                    ),
                    const _TileDivider(),
                    _SettingsTile(
                      icon: Icons.logout_rounded,
                      iconBg: const Color(0xFFFFEBEE),
                      iconColor: Colors.red,
                      title: l10n.signOut,
                      titleColor: Colors.red,
                      trailing: const Icon(Icons.chevron_right,
                          color: Colors.red, size: 20),
                      onTap: () => _confirmSignOut(context, ref, l10n),
                    ),
                  ]),

                  const SizedBox(height: 28),

                  // About
                  _SectionLabel(l10n.about),
                  const SizedBox(height: 10),
                  _SettingsCard(children: [
                    _SettingsTile(
                      icon: Icons.anchor_rounded,
                      iconBg: AppColors.accent.withValues(alpha: 0.10),
                      iconColor: AppColors.accent,
                      title: l10n.appName,
                      subtitle: '${l10n.version} 1.0.0',
                    ),
                    const _TileDivider(),
                    _SettingsTile(
                      icon: Icons.shield_outlined,
                      iconBg: AppColors.tan.withValues(alpha: 0.30),
                      iconColor: AppColors.brown,
                      title: 'Privacy Policy',
                      trailing: const Icon(Icons.chevron_right,
                          color: Colors.grey, size: 20),
                      onTap: () {},
                    ),
                  ]),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _confirmSignOut(
      BuildContext context, WidgetRef ref, AppLocalizations l10n) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        shape:
            RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: const Color(0xFFFFEBEE),
                borderRadius: BorderRadius.circular(10),
              ),
              child: const Icon(Icons.logout_rounded,
                  color: Colors.red, size: 22),
            ),
            const SizedBox(width: 12),
            Text(l10n.signOut),
          ],
        ),
        content: Text(l10n.areYouSureSignOut),
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
              backgroundColor: Colors.red,
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
}

// ── Settings Header ───────────────────────────────────────────────────────────

class _SettingsHeader extends StatelessWidget {
  final String title;
  const _SettingsHeader({required this.title});

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        // Gradient background
        Container(
          decoration: const BoxDecoration(
            gradient: LinearGradient(
              colors: [AppColors.primary, AppColors.accent],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
          ),
          child: SafeArea(
            bottom: false,
            child: Padding(
              padding: const EdgeInsets.fromLTRB(4, 4, 16, 36),
              child: Row(
                children: [
                  IconButton(
                    icon: const Icon(Icons.arrow_back_ios_new_rounded,
                        color: Colors.white, size: 20),
                    onPressed: () => Navigator.of(context).pop(),
                  ),
                  const SizedBox(width: 4),
                  Text(
                    title,
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 22,
                      fontWeight: FontWeight.w700,
                      letterSpacing: -0.3,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
        // Curved cream bottom
        Positioned(
          bottom: -1,
          left: 0,
          right: 0,
          child: Container(
            height: 32,
            decoration: const BoxDecoration(
              color: AppColors.cream,
              borderRadius: BorderRadius.only(
                topLeft: Radius.circular(28),
                topRight: Radius.circular(28),
              ),
            ),
          ),
        ),
      ],
    );
  }
}

// ── Section label ─────────────────────────────────────────────────────────────

class _SectionLabel extends StatelessWidget {
  final String text;
  const _SectionLabel(this.text);

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(left: 4),
      child: Text(
        text.toUpperCase(),
        style: const TextStyle(
          fontSize: 11,
          fontWeight: FontWeight.w700,
          color: AppColors.primary,
          letterSpacing: 1.2,
        ),
      ),
    );
  }
}

// ── Settings card ─────────────────────────────────────────────────────────────

class _SettingsCard extends StatelessWidget {
  final List<Widget> children;
  const _SettingsCard({required this.children});

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.055),
            blurRadius: 14,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(children: children),
    );
  }
}

// ── Settings tile ─────────────────────────────────────────────────────────────

class _SettingsTile extends StatelessWidget {
  final IconData? icon;
  final Widget? iconWidget;
  final Color? iconBg;
  final Color? iconColor;
  final String title;
  final Color? titleColor;
  final String? subtitle;
  final Widget? trailing;
  final VoidCallback? onTap;

  const _SettingsTile({
    this.icon,
    this.iconWidget,
    this.iconBg,
    this.iconColor,
    required this.title,
    this.titleColor,
    this.subtitle,
    this.trailing,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final iconBox = Container(
      width: 40,
      height: 40,
      decoration: BoxDecoration(
        color: iconBg ?? Colors.grey.shade100,
        borderRadius: BorderRadius.circular(11),
      ),
      child: iconWidget != null
          ? Center(child: iconWidget)
          : Icon(icon, color: iconColor ?? Colors.grey, size: 20),
    );

    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(16),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 13),
        child: Row(
          children: [
            iconBox,
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.w500,
                      color: titleColor ?? const Color(0xFF1A1A2E),
                    ),
                  ),
                  if (subtitle != null) ...[
                    const SizedBox(height: 2),
                    Text(
                      subtitle!,
                      style: const TextStyle(
                          fontSize: 12, color: Colors.grey),
                    ),
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

// ── Tile divider ──────────────────────────────────────────────────────────────

class _TileDivider extends StatelessWidget {
  const _TileDivider();

  @override
  Widget build(BuildContext context) {
    return const Divider(
        height: 1, indent: 70, endIndent: 16, color: Color(0xFFEEEEEE));
  }
}

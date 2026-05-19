import 'package:bahaar/constants/app_colors.dart';
import 'package:bahaar/l10n/app/app_localization.dart';
import 'package:bahaar/l10n/profile/profile_localizations.dart';
import 'package:bahaar/models/registration/user.dart' as app_user;
import 'package:bahaar/providers/authentication/authentication_provider.dart';
import 'package:bahaar/widgets/common/app_card.dart';
import 'package:bahaar/widgets/common/card_divider.dart';
import 'package:bahaar/widgets/common/gradient_screen.dart';
import 'package:bahaar/widgets/common/section_label.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'edit_profile_screen.dart';

class ProfileScreen extends ConsumerWidget {
  const ProfileScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = ProfileLocalizations.of(context);
    final user = ref.watch(authProviderProvider).currentAppUser;

    if (user == null) {
      return const Scaffold(
        body: Center(child: CircularProgressIndicator(color: AppColors.accent)),
      );
    }

    final fullName = user.isGuest
        ? l10n.guestUser
        : '${user.firstName ?? ''} ${user.lastName ?? ''}'.trim();

    final subtitle = user.isGuest
        ? l10n.guestAccount
        : (user.email ?? '');

    return GradientScreen(
      expandedHeight: 220,
      actions: [
        if (!user.isGuest)
          IconButton(
            icon: const Icon(Icons.edit_outlined, color: Colors.white),
            tooltip: l10n.editProfile,
            onPressed: () => Navigator.push(
              context,
              MaterialPageRoute(builder: (_) => const EditProfileScreen()),
            ),
          ),
        const SizedBox(width: 4),
      ],
      flexContent: SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(24, 60, 24, 20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisAlignment: MainAxisAlignment.end,
            children: [
              _AvatarCircle(user: user, fullName: fullName),
              const SizedBox(height: 12),
              Text(
                fullName.isEmpty ? l10n.profile : fullName,
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 22,
                  fontWeight: FontWeight.w800,
                ),
              ),
              const SizedBox(height: 3),
              Text(
                subtitle,
                style: TextStyle(
                  color: Colors.white.withValues(alpha: 0.7),
                  fontSize: 12,
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
            // ── Contact Information ────────────────────────────────
            SectionLabel(l10n.contactInformation),
            AppCard(
              child: Column(children: [
                _ProfileTile(
                  icon: Icons.email_outlined,
                  iconBg: AppColors.accent.withValues(alpha: 0.12),
                  iconColor: AppColors.accent,
                  label: l10n.email,
                  value: user.email,
                ),
                const CardDivider(),
                _ProfileTile(
                  icon: Icons.phone_outlined,
                  iconBg: AppColors.brown.withValues(alpha: 0.12),
                  iconColor: AppColors.brown,
                  label: l10n.phone,
                  value: user.phone,
                ),
                const CardDivider(),
                _ProfileTile(
                  icon: Icons.location_on_outlined,
                  iconBg: AppColors.red.withValues(alpha: 0.10),
                  iconColor: AppColors.red,
                  label: l10n.location,
                  value: user.location,
                ),
              ]),
            ),

            // ── Account ────────────────────────────────────────────
            if (!user.isGuest) ...[
              const SizedBox(height: 28),
              SectionLabel(l10n.account),
              AppCard(
                child: Column(children: [
                  _ProfileTile(
                    icon: Icons.alternate_email,
                    iconBg: AppColors.primary.withValues(alpha: 0.10),
                    iconColor: AppColors.primary,
                    label: l10n.username,
                    value: user.userName != null ? '${user.userName}' : null,
                  ),
                ]),
              ),
            ],

            // ── Guest banner ───────────────────────────────────────
            if (user.isGuest) ...[
              const SizedBox(height: 28),
              SectionLabel(l10n.accountStatus),
              _GuestBanner(message: l10n.guestBannerMessage),
            ],
          ],
        ),
      ),
    );
  }
}

// ── Avatar circle ─────────────────────────────────────────────────────────────

class _AvatarCircle extends StatelessWidget {
  final app_user.User user;
  final String fullName;
  const _AvatarCircle({required this.user, required this.fullName});

  String get _initials {
    final first =
        user.firstName?.isNotEmpty == true ? user.firstName![0] : '';
    final last = user.lastName?.isNotEmpty == true ? user.lastName![0] : '';
    final combined = '$first$last'.toUpperCase();
    return combined.isEmpty ? (user.isGuest ? 'G' : '?') : combined;
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        border: Border.all(
            color: Colors.white.withValues(alpha: 0.6), width: 2.5),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.18),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: CircleAvatar(
        radius: 34,
        backgroundColor: AppColors.primary,
        child: Text(
          _initials,
          style: const TextStyle(
            color: Colors.white,
            fontSize: 22,
            fontWeight: FontWeight.bold,
          ),
        ),
      ),
    );
  }
}

// ── Profile tile ──────────────────────────────────────────────────────────────

class _ProfileTile extends StatelessWidget {
  final IconData icon;
  final Color iconBg;
  final Color iconColor;
  final String label;
  final String? value;

  const _ProfileTile({
    required this.icon,
    required this.iconBg,
    required this.iconColor,
    required this.label,
    this.value,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      child: Row(
        children: [
          Container(
            width: 42,
            height: 42,
            decoration: BoxDecoration(
              color: iconBg,
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(icon, color: iconColor, size: 20),
          ),
          const SizedBox(width: 14),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                label.toUpperCase(),
                style: const TextStyle(
                  fontSize: 10,
                  color: Colors.grey,
                  fontWeight: FontWeight.w600,
                ),
              ),
              const SizedBox(height: 3),
              Text(
                value?.isNotEmpty == true ? value! : '—',
                style: const TextStyle(
                  fontSize: 15,
                  color: Color(0xFF1A1A2E),
                  fontWeight: FontWeight.w500,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

// ── Guest banner ──────────────────────────────────────────────────────────────

class _GuestBanner extends StatelessWidget {
  final String message;
  const _GuestBanner({required this.message});

  @override
  Widget build(BuildContext context) {
    final app = AppLocalization.of(context);
    return AppCard(
      padding: const EdgeInsets.all(16),
      child: Row(
        children: [
          Container(
            width: 42,
            height: 42,
            decoration: BoxDecoration(
              color: AppColors.primary.withValues(alpha: 0.10),
              borderRadius: BorderRadius.circular(12),
            ),
            child: const Icon(Icons.lock_open_outlined,
                color: AppColors.primary, size: 20),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  app.guestMode,
                  style: const TextStyle(
                    color: Color(0xFF1A1A2E),
                    fontWeight: FontWeight.w600,
                    fontSize: 14,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  message,
                  style: const TextStyle(color: Colors.grey, fontSize: 12),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

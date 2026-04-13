import 'package:bahaar/core/constants/app_colors.dart';
import 'package:bahaar/l10n/app_localizations.dart';
import 'package:bahaar/providers/authentication/authentication_provider.dart';
import 'package:bahaar/widgets/common/app_card.dart';
import 'package:bahaar/widgets/common/card_divider.dart';
import 'package:bahaar/widgets/common/gradient_screen.dart';
import 'package:bahaar/widgets/common/section_label.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

class EditProfileScreen extends ConsumerStatefulWidget {
  const EditProfileScreen({super.key});

  @override
  ConsumerState<EditProfileScreen> createState() => _EditProfileScreenState();
}

class _EditProfileScreenState extends ConsumerState<EditProfileScreen> {
  final _formKey = GlobalKey<FormState>();
  late final TextEditingController _firstName;
  late final TextEditingController _lastName;
  late final TextEditingController _userName;
  late final TextEditingController _phone;
  late final TextEditingController _location;
  bool _saving = false;

  @override
  void initState() {
    super.initState();
    final user = ref.read(authProviderProvider).currentAppUser;
    _firstName = TextEditingController(text: user?.firstName ?? '');
    _lastName  = TextEditingController(text: user?.lastName ?? '');
    _userName  = TextEditingController(text: user?.userName ?? '');
    _phone     = TextEditingController(text: user?.phone ?? '');
    _location  = TextEditingController(text: user?.location ?? '');
  }

  @override
  void dispose() {
    _firstName.dispose();
    _lastName.dispose();
    _userName.dispose();
    _phone.dispose();
    _location.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _saving = true);
    try {
      await ref.read(authProviderProvider).updateProfile(
            firstName: _firstName.text.trim(),
            lastName:  _lastName.text.trim(),
            userName:  _userName.text.trim(),
            phone:     _phone.text.trim(),
            location:  _location.text.trim(),
          );
      if (mounted) Navigator.pop(context);
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final user = ref.watch(authProviderProvider).currentAppUser;
    final fullName =
        '${user?.firstName ?? ''} ${user?.lastName ?? ''}'.trim();

    return Form(
      key: _formKey,
      child: GradientScreen(
        expandedHeight: 200,
        actions: [
          TextButton(
            onPressed: _saving ? null : _save,
            child: _saving
                ? const SizedBox(
                    width: 18,
                    height: 18,
                    child: CircularProgressIndicator(
                        strokeWidth: 2, color: Colors.white),
                  )
                : Text(
                    l10n.save,
                    style: const TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.w700,
                      fontSize: 15,
                    ),
                  ),
          ),
          const SizedBox(width: 4),
        ],
        flexContent: SafeArea(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(24, 0, 24, 20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                // Avatar with edit badge
                Stack(
                  children: [
                    Container(
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        border: Border.all(
                            color: Colors.white.withValues(alpha: 0.6),
                            width: 2.5),
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
                          _initials(user?.firstName, user?.lastName),
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 22,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    ),
                    Positioned(
                      bottom: 0,
                      right: 0,
                      child: Container(
                        width: 22,
                        height: 22,
                        decoration: BoxDecoration(
                          color: Colors.white,
                          shape: BoxShape.circle,
                          border: Border.all(
                              color: AppColors.accent, width: 1.5),
                        ),
                        child: const Icon(Icons.edit_rounded,
                            size: 12, color: AppColors.accent),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                Text(
                  fullName.isEmpty ? l10n.editProfile : fullName,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 22,
                    fontWeight: FontWeight.w800,
                  ),
                ),
                const SizedBox(height: 3),
                Text(
                  user?.email ?? '',
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
              // ── Personal Info ──────────────────────────────────
              SectionLabel(l10n.profile),
              AppCard(
                child: Column(children: [
                  _EditTile(
                    controller: _firstName,
                    icon: Icons.person_outlined,
                    iconBg: AppColors.accent.withValues(alpha: 0.12),
                    iconColor: AppColors.accent,
                    label: l10n.firstName,
                  ),
                  const CardDivider(),
                  _EditTile(
                    controller: _lastName,
                    icon: Icons.person_outline,
                    iconBg: AppColors.primary.withValues(alpha: 0.10),
                    iconColor: AppColors.primary,
                    label: l10n.lastName,
                  ),
                ]),
              ),

              const SizedBox(height: 28),

              // ── Contact ────────────────────────────────────────
              SectionLabel(l10n.contactInformation),
              AppCard(
                child: Column(children: [
                  _EditTile(
                    controller: _phone,
                    icon: Icons.phone_outlined,
                    iconBg: AppColors.brown.withValues(alpha: 0.12),
                    iconColor: AppColors.brown,
                    label: l10n.phone,
                    keyboardType: TextInputType.phone,
                  ),
                  const CardDivider(),
                  _EditTile(
                    controller: _location,
                    icon: Icons.location_on_outlined,
                    iconBg: AppColors.red.withValues(alpha: 0.10),
                    iconColor: AppColors.red,
                    label: l10n.location,
                  ),
                ]),
              ),

              const SizedBox(height: 28),

              // ── Account ────────────────────────────────────────
              SectionLabel(l10n.account),
              AppCard(
                child: Column(children: [
                  _EditTile(
                    controller: _userName,
                    icon: Icons.alternate_email,
                    iconBg: AppColors.primary.withValues(alpha: 0.10),
                    iconColor: AppColors.primary,
                    label: l10n.username,
                  ),
                ]),
              ),

              const SizedBox(height: 32),

              // ── Save button ────────────────────────────────────
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: _saving ? null : _save,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.primary,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(16)),
                    elevation: 0,
                  ),
                  child: _saving
                      ? const SizedBox(
                          height: 20,
                          width: 20,
                          child: CircularProgressIndicator(
                              strokeWidth: 2, color: Colors.white),
                        )
                      : Text(
                          l10n.saveChanges,
                          style: const TextStyle(
                              fontSize: 16, fontWeight: FontWeight.w700),
                        ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  String _initials(String? first, String? last) {
    final f = first?.isNotEmpty == true ? first![0] : '';
    final l = last?.isNotEmpty == true ? last![0] : '';
    final combined = '$f$l'.toUpperCase();
    return combined.isEmpty ? '?' : combined;
  }
}

// ── Edit tile ─────────────────────────────────────────────────────────────────

class _EditTile extends StatelessWidget {
  final TextEditingController controller;
  final IconData icon;
  final Color iconBg;
  final Color iconColor;
  final String label;
  final TextInputType keyboardType;

  const _EditTile({
    required this.controller,
    required this.icon,
    required this.iconBg,
    required this.iconColor,
    required this.label,
    this.keyboardType = TextInputType.text,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
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
          Expanded(
            child: TextFormField(
              controller: controller,
              keyboardType: keyboardType,
              style: const TextStyle(
                fontSize: 15,
                color: Color(0xFF1A1A2E),
                fontWeight: FontWeight.w500,
              ),
              decoration: InputDecoration(
                labelText: label,
                labelStyle: const TextStyle(
                  fontSize: 11,
                  color: Colors.grey,
                  fontWeight: FontWeight.w600,
                ),
                border: InputBorder.none,
                isDense: true,
                contentPadding: EdgeInsets.zero,
                floatingLabelBehavior: FloatingLabelBehavior.always,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

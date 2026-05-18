import 'package:bahaar/constants/app_colors.dart';
import 'package:bahaar/l10n/settings/settings_localizations.dart';
import 'package:bahaar/widgets/map/sos_button.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

class EmergencyScreen extends StatelessWidget {
  const EmergencyScreen({super.key});

  static const _contacts = [
    _EmergencyContact(labelKey: 'coastGuard', number: '17700000', icon: Icons.anchor),
    _EmergencyContact(labelKey: 'marineRescue', number: '999', icon: Icons.directions_boat),
    _EmergencyContact(labelKey: 'police', number: '999', icon: Icons.local_police),
    _EmergencyContact(labelKey: 'ambulance', number: '998', icon: Icons.medical_services),
  ];

  static const _rules = [
    ('rule1Title', 'rule1Body'),
    ('rule2Title', 'rule2Body'),
    ('rule3Title', 'rule3Body'),
    ('rule4Title', 'rule4Body'),
    ('rule5Title', 'rule5Body'),
    ('rule6Title', 'rule6Body'),
  ];

  void _copyNumber(BuildContext context, String number, SettingsLocalizations l10n) {
    Clipboard.setData(ClipboardData(text: number));
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(
      content: Text(l10n.phoneNumberCopied),
      backgroundColor: AppColors.tan,
      duration: const Duration(seconds: 2),
    ));
  }

  @override
  Widget build(BuildContext context) {
    final l10n = SettingsLocalizations.of(context);

    return Scaffold(
      backgroundColor: AppColors.white,
      appBar: AppBar(
        title: Text(l10n.emergency,
            style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 18)),
        centerTitle: true,
        backgroundColor: AppColors.red,
        foregroundColor: Colors.white,
        elevation: 0,
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          // SOS section
          _SectionHeader(title: 'SOS'),
          const SizedBox(height: 8),
          Card(
            elevation: 0,
            color: Colors.red.shade50,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(16),
              side: BorderSide(color: Colors.red.shade200),
            ),
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Row(
                children: [
                  const SosButton(),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          l10n.sosLongPressHint,
                          style: TextStyle(
                              color: Colors.red.shade800,
                              fontWeight: FontWeight.w600,
                              fontSize: 13),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          l10n.emergencyChannelHint,
                          style: TextStyle(
                              color: Colors.red.shade600, fontSize: 12),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),

          const SizedBox(height: 20),

          // Emergency contacts
          _SectionHeader(title: l10n.emergencyContacts),
          const SizedBox(height: 8),
          Card(
            elevation: 0,
            color: AppColors.cream,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(16),
              side: BorderSide(color: AppColors.tan),
            ),
            child: Column(
              children: _contacts.asMap().entries.map((entry) {
                final i = entry.key;
                final c = entry.value;
                final label = _localizedContactLabel(l10n, c.labelKey);
                return Column(
                  children: [
                    ListTile(
                      leading: Container(
                        padding: const EdgeInsets.all(8),
                        decoration: BoxDecoration(
                          color: AppColors.brown.withValues(alpha: 0.2),
                          shape: BoxShape.circle,
                        ),
                        child: Icon(c.icon, color: AppColors.brown, size: 20),
                      ),
                      title: Text(label,
                          style: const TextStyle(
                              fontWeight: FontWeight.w600, fontSize: 14)),
                      trailing: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Text(c.number,
                              style: TextStyle(
                                  color: Colors.brown,
                                  fontSize: 14,
                                  fontWeight: FontWeight.w500)),
                          const SizedBox(width: 8),
                          GestureDetector(
                            onTap: () => _copyNumber(context, c.number, l10n),
                            child: Container(
                              padding: const EdgeInsets.all(6),
                              decoration: BoxDecoration(
                                color: AppColors.brown.withValues(alpha: 0.7),
                                shape: BoxShape.circle,
                              ),
                              child: const Icon(Icons.copy,
                                  color: Colors.white, size: 16),
                            ),
                          ),
                        ],
                      ),
                      onTap: () => _copyNumber(context, c.number, l10n),
                    ),
                    if (i < _contacts.length - 1)
                      Divider(
                          indent: 56,
                          endIndent: 16,
                          height: 1,
                          color: AppColors.tan.withValues(alpha: 0.2)),
                  ],
                );
              }).toList(),
            ),
          ),

          const SizedBox(height: 20),

          // Fishing rules
          _SectionHeader(title: l10n.fishingRules),
          const SizedBox(height: 8),
          ..._rules.map((r) => _RuleTile(
                title: _localizedRuleTitle(l10n, r.$1),
                body: _localizedRuleBody(l10n, r.$2),
              )),

          const SizedBox(height: 32),
        ],
      ),
    );
  }

  String _localizedContactLabel(SettingsLocalizations l10n, String key) {
    switch (key) {
      case 'coastGuard': return l10n.coastGuard;
      case 'marineRescue': return l10n.marineRescue;
      case 'police': return l10n.police;
      case 'ambulance': return l10n.ambulance;
      default: return key;
    }
  }

  String _localizedRuleTitle(SettingsLocalizations l10n, String key) {
    switch (key) {
      case 'rule1Title': return l10n.rule1Title;
      case 'rule2Title': return l10n.rule2Title;
      case 'rule3Title': return l10n.rule3Title;
      case 'rule4Title': return l10n.rule4Title;
      case 'rule5Title': return l10n.rule5Title;
      case 'rule6Title': return l10n.rule6Title;
      default: return key;
    }
  }

  String _localizedRuleBody(SettingsLocalizations l10n, String key) {
    switch (key) {
      case 'rule1Body': return l10n.rule1Body;
      case 'rule2Body': return l10n.rule2Body;
      case 'rule3Body': return l10n.rule3Body;
      case 'rule4Body': return l10n.rule4Body;
      case 'rule5Body': return l10n.rule5Body;
      case 'rule6Body': return l10n.rule6Body;
      default: return key;
    }
  }
}

class _SectionHeader extends StatelessWidget {
  final String title;
  const _SectionHeader({required this.title});

  @override
  Widget build(BuildContext context) {
    return Text(
      title.toUpperCase(),
      style: const TextStyle(
        fontSize: 14,
        fontWeight: FontWeight.w700,
        color: Colors.black,
      ),
    );
  }
}

class _RuleTile extends StatefulWidget {
  final String title;
  final String body;
  const _RuleTile({required this.title, required this.body});

  @override
  State<_RuleTile> createState() => _RuleTileState();
}

class _RuleTileState extends State<_RuleTile> {
  bool _expanded = false;

  @override
  Widget build(BuildContext context) {
    return Card(
      elevation: 0,
      margin: const EdgeInsets.only(bottom: 8, right: 4, left: 4),
      color: AppColors.cream,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(14),
        side: BorderSide(color: AppColors.tan),
      ),
      child: InkWell(
        onTap: () => setState(() => _expanded = !_expanded),
        borderRadius: BorderRadius.circular(14),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                margin: const EdgeInsets.only(top: 2),
                padding: const EdgeInsets.all(6),
                decoration: BoxDecoration(
                  color: AppColors.tan.withValues(alpha: 0.2),
                  shape: BoxShape.circle,
                ),
                child: const Icon(Icons.gavel, color: AppColors.brown, size: 16),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(widget.title,
                        style: const TextStyle(
                            fontWeight: FontWeight.w600, fontSize: 14)),
                    if (_expanded) ...[
                      const SizedBox(height: 6),
                      Text(widget.body,
                          style: TextStyle(
                              color: AppColors.brown,
                              fontSize: 13,
                              height: 1.4)),
                    ],
                  ],
                ),
              ),
              Icon(
                _expanded ? Icons.expand_less : Icons.expand_more,
                color: AppColors.brown,
                size: 20,
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _EmergencyContact {
  final String labelKey;
  final String number;
  final IconData icon;
  const _EmergencyContact(
      {required this.labelKey, required this.number, required this.icon});
}

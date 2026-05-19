import 'package:bahaar/constants/app_colors.dart';
import 'package:bahaar/l10n/map/map_localizations.dart';
import 'package:flutter/material.dart';

class NavModeOption extends StatelessWidget {
  final IconData icon;
  final String title;
  final String subtitle;
  final VoidCallback onTap;

  const NavModeOption({
    super.key,
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.onTap,
  });

  /// Shows the nav mode selection bottom sheet.
  static void show(
    BuildContext context, {
    required VoidCallback onLandToSea,
    required VoidCallback onSeaToSea,
    required VoidCallback onSeaToLand,
  }) {
    final l10n = MapLocalizations.of(context);
    showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
      ),
      builder: (ctx) => DraggableScrollableSheet(
        expand: false,
        initialChildSize: 0.42,
        minChildSize: 0.28,
        maxChildSize: 0.75,
        builder: (_, scrollController) => Column(
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 12, 8, 0),
              child: Row(
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.center,
                      children: [
                        Center(
                          child: Container(
                            width: 40,
                            height: 4,
                            margin: const EdgeInsets.only(bottom: 12),
                            decoration: BoxDecoration(
                              color: Colors.grey[400],
                              borderRadius: BorderRadius.circular(2),
                            ),
                          ),
                        ),
                        Text(
                          l10n.chooseNavType,
                          style: const TextStyle(
                              fontSize: 16, fontWeight: FontWeight.bold),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            Expanded(
              child: ListView(
                controller: scrollController,
                padding:
                    const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                children: [
                  NavModeOption(
                    icon: Icons.directions_boat,
                    title: l10n.landToSea,
                    subtitle: l10n.landToSeaSubtitle,
                    onTap: () {
                      Navigator.pop(ctx);
                      onLandToSea();
                    },
                  ),
                  const SizedBox(height: 8),
                  NavModeOption(
                    icon: Icons.waves,
                    title: l10n.seaToSea,
                    subtitle: l10n.seaToSeaSubtitle,
                    onTap: () {
                      Navigator.pop(ctx);
                      onSeaToSea();
                    },
                  ),
                  const SizedBox(height: 8),
                  NavModeOption(
                    icon: Icons.home,
                    title: l10n.returnSeaToLand,
                    subtitle: l10n.returnSeaToLandSubtitle,
                    onTap: () {
                      Navigator.pop(ctx);
                      onSeaToLand();
                    },
                  ),
                  const SizedBox(height: 8),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(14),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 13),
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: [
              AppColors.brown.withValues(alpha: 0.06),
              AppColors.tan.withValues(alpha: 0.03),
            ],
            begin: Alignment.centerLeft,
            end: Alignment.centerRight,
          ),
          border: Border.all(color: AppColors.brown.withValues(alpha: 0.2)),
          borderRadius: BorderRadius.circular(14),
        ),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(10),
              decoration: const BoxDecoration(
                gradient: LinearGradient(
                  colors: [AppColors.brown, AppColors.tan],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                shape: BoxShape.circle,
              ),
              child: Icon(icon, color: Colors.white, size: 22),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(title,
                      style: const TextStyle(
                          fontWeight: FontWeight.w600,
                          fontSize: 14,
                          color: Color.fromARGB(255, 83, 68, 52))),
                  const SizedBox(height: 3),
                  Text(subtitle,
                      style: TextStyle(fontSize: 12, color: Colors.grey.shade600)),
                ],
              ),
            ),
            Icon(Icons.chevron_right_rounded,
                color: AppColors.brown.withValues(alpha: 0.5), size: 20),
          ],
        ),
      ),
    );
  }
}

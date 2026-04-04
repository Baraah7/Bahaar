import 'package:flutter/material.dart';
import 'package:Bahaar/models/fishing/trip_model.dart';
import 'package:Bahaar/l10n/app_localizations.dart';
import 'package:intl/intl.dart';

class TripCard extends StatelessWidget {
  final Trip trip;
  final VoidCallback? onTap;
  final VoidCallback? onDelete;
  final VoidCallback? onEditTitle;

  const TripCard({
    super.key,
    required this.trip,
    this.onTap,
    this.onDelete,
    this.onEditTitle,
  });

  String _n(String value, String lang) {
    if (lang != 'ar') return value;
    const digits = ['٠', '١', '٢', '٣', '٤', '٥', '٦', '٧', '٨', '٩'];
    return value.replaceAllMapped(
        RegExp(r'[0-9]'), (m) => digits[int.parse(m.group(0)!)]);
  }

  String _formatDurationLocale(Duration d, String lang) {
    final isAr = lang == 'ar';
    if (d.inHours > 0) {
      final h = d.inHours;
      final m = d.inMinutes.remainder(60);
      final hStr = _n('$h', lang);
      final mStr = _n('$m', lang);
      if (isAr) return m == 0 ? '${hStr}س' : '${hStr}س ${mStr}د';
      return m == 0 ? '${hStr}h' : '${hStr}h ${mStr}m';
    }
    final m = d.inMinutes;
    final mStr = _n('$m', lang);
    return isAr ? '${mStr}د' : '${mStr}m';
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final lang = l10n.localeName;
    final locale = lang == 'ar' ? 'ar' : 'en';
    final dateStr = DateFormat('EEE d MMM yyyy', locale).format(trip.startTime.toLocal());
    final timeStr = DateFormat('HH:mm').format(trip.startTime.toLocal());
    final duration = trip.duration;
    final durationStr = _formatDurationLocale(duration, lang);
    final totalWeight = trip.totalWeightKg;

    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            Colors.white.withValues(alpha: 0.15),
            Colors.white.withValues(alpha: 0.05),
          ],
        ),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: Colors.white.withValues(alpha: 0.20)),
      ),
      child: Material(
        color: Colors.transparent,
        borderRadius: BorderRadius.circular(14),
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(14),
          child: Padding(
          padding: const EdgeInsets.all(14),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  const Icon(Icons.anchor, color: Colors.white70, size: 18),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        if (trip.title != null && trip.title!.isNotEmpty)
                          Text(
                            trip.title!,
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 15,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                        Text(
                          dateStr,
                          style: TextStyle(
                            color: trip.title != null
                                ? Colors.white70
                                : Colors.white,
                            fontSize: trip.title != null ? 12 : 15,
                            fontWeight: trip.title != null
                                ? FontWeight.w400
                                : FontWeight.w600,
                          ),
                        ),
                      ],
                    ),
                  ),
                  if (trip.isActive)
                    Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 8, vertical: 3),
                      decoration: BoxDecoration(
                        color: Colors.green.withValues(alpha: 0.3),
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(
                            color: Colors.green.withValues(alpha: 0.6)),
                      ),
                      child: Text(
                        l10n.tripActiveLabel,
                        style: const TextStyle(
                          color: Colors.greenAccent,
                          fontSize: 11,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                  if (onEditTitle != null)
                    IconButton(
                      icon: const Icon(Icons.edit_outlined,
                          color: Colors.white38, size: 16),
                      onPressed: onEditTitle,
                      padding: EdgeInsets.zero,
                      constraints: const BoxConstraints(),
                      tooltip: l10n.editTitleTooltip,
                    ),
                  if (onDelete != null && !trip.isActive)
                    IconButton(
                      icon: const Icon(Icons.delete_outline,
                          color: Colors.white38, size: 18),
                      onPressed: onDelete,
                      padding: EdgeInsets.zero,
                      constraints: const BoxConstraints(),
                    ),
                ],
              ),
              const SizedBox(height: 10),
              Row(
                children: [
                  _Stat(
                    icon: Icons.access_time,
                    label: l10n.tripStartedLabel,
                    value: timeStr,
                  ),
                  const SizedBox(width: 20),
                  _Stat(
                    icon: Icons.timer_outlined,
                    label: l10n.tripDurationLabel,
                    value: durationStr,
                  ),
                  const SizedBox(width: 20),
                  _Stat(
                    icon: Icons.set_meal,
                    label: l10n.tripCatchesLabel,
                    value: _n('${trip.catches.length}', lang),
                  ),
                  if (totalWeight > 0) ...[
                    const SizedBox(width: 20),
                    _Stat(
                      icon: Icons.scale,
                      label: l10n.weight,
                      value: '${_n(totalWeight.toStringAsFixed(1), lang)} ${l10n.kgUnit}',
                    ),
                  ],
                ],
              ),
              if (trip.notes != null && trip.notes!.isNotEmpty) ...[
                const SizedBox(height: 8),
                Text(
                  trip.notes!,
                  style: TextStyle(
                    color: Colors.white.withValues(alpha: 0.6),
                    fontSize: 12,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ],
          ),
        ),
      ),
    ),
  );
  }

}

class _Stat extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;

  const _Stat({
    required this.icon,
    required this.label,
    required this.value,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Icon(icon, color: Colors.white38, size: 12),
            const SizedBox(width: 3),
            Text(
              label,
              style: const TextStyle(color: Colors.white38, fontSize: 10),
            ),
          ],
        ),
        const SizedBox(height: 2),
        Text(
          value,
          style: const TextStyle(
            color: Colors.white,
            fontSize: 13,
            fontWeight: FontWeight.w600,
          ),
        ),
      ],
    );
  }
}

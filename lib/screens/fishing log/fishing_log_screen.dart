import 'dart:async';
import 'dart:developer';
import 'package:intl/intl.dart';
import 'package:bahaar/core/constants/app_colors.dart';
import 'package:bahaar/l10n/fishing_log/fishing_log_localizations.dart';
import 'package:bahaar/models/fishing/trip_model.dart';
import 'package:bahaar/providers/authentication/authentication_provider.dart';
import 'package:bahaar/screens/fishing%20log/trip_detail_screen.dart';
import 'package:bahaar/services/fishing%20log/trip_service.dart';
import 'package:bahaar/utilities/cn/localization_helper.dart';
import 'package:bahaar/widgets/common/app_empty_state.dart';
import 'package:bahaar/widgets/common/app_snackbar.dart';
import 'package:bahaar/widgets/fishing_log/trip_card.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:location/location.dart';
import 'package:latlong2/latlong.dart';
import 'package:firebase_auth/firebase_auth.dart';

class FishingLogScreen extends ConsumerStatefulWidget {
  const FishingLogScreen({super.key});

  @override
  ConsumerState<FishingLogScreen> createState() => _FishingLogScreenState();
}

class _FishingLogScreenState extends ConsumerState<FishingLogScreen> {
  final _service = TripService.instance;
  List<Trip> _trips = [];
  bool _loading = true;
  Timer? _ticker;
  final _searchCtrl = TextEditingController();
  String _searchQuery = '';

  @override
  void initState() {
    super.initState();
    _init();
  }

  @override
  void dispose() {
    _ticker?.cancel();
    _searchCtrl.dispose();
    super.dispose();
  }

  List<Trip> get _filteredTrips {
    if (_searchQuery.isEmpty) return _trips;
    final q = _searchQuery.toLowerCase();
    return _trips.where((t) {
      if ((t.title ?? '').toLowerCase().contains(q)) return true;
      final date = t.startTime.toLocal();
      // Match "21/4/2026", "21 Apr 2026", "April 2026", "2026-04-21"
      final formats = [
        DateFormat('d/M/yyyy').format(date),
        DateFormat('dd/MM/yyyy').format(date),
        DateFormat('d MMM yyyy').format(date),
        DateFormat('d MMMM yyyy').format(date),
        DateFormat('MMMM yyyy').format(date),
        DateFormat('yyyy-MM-dd').format(date),
      ];
      return formats.any((f) => f.toLowerCase().contains(q));
    }).toList();
  }

  Future<void> _init() async {
    final uid = FirebaseAuth.instance.currentUser?.uid;
    await _service.initialize(uid: uid);
    await _loadTrips();
    _startTicker();
  }

  /// Ticks every second to refresh the live duration on the banner.
  void _startTicker() {
    _ticker?.cancel();
    _ticker = Timer.periodic(const Duration(seconds: 1), (_) {
      if (_service.activeTrip != null && mounted) setState(() {});
    });
  }

  Future<void> _loadTrips() async {
    setState(() => _loading = true);
    try {
      final trips = await _service.getAllTrips();
      if (mounted) setState(() { _trips = trips; _loading = false; });
    } catch (e) {
      log('FishingLogScreen: load error — $e');
      if (mounted) setState(() => _loading = false);
    }
  }

  Future<LatLng?> _currentLocation() async {
    try {
      final loc = Location();
      final data = await loc.getLocation();
      if (data.latitude != null && data.longitude != null) {
        return LatLng(data.latitude!, data.longitude!);
      }
    } catch (_) {}
    return null;
  }

  Future<void> _startTrip() async {
    try {
      final trip = await _service.startTrip();
      // Immediately reflect the new active trip in the UI before the DB reload.
      if (mounted) setState(() {});
      await _loadTrips();
      _startTicker();
      // Update start location in background once GPS resolves.
      _currentLocation().then((loc) async {
        if (loc == null) return;
        await _service.updateTripStartLocation(trip.id, loc);
        if (mounted) await _loadTrips();
      });
    } catch (e) {
      log('FishingLogScreen: startTrip error — $e');
      if (mounted) {
        showAppSnackBar(context, 'Error starting trip: $e');
      }
    }
  }

  Trip? get _todayEndedTrip {
    final today = DateTime.now();
    for (final t in _trips) {
      if (!t.isActive && t.endTime != null) {
        final end = t.endTime!.toLocal();
        if (end.year == today.year && end.month == today.month && end.day == today.day) {
          return t;
        }
      }
    }
    return null;
  }

  Future<void> _resumeTrip(Trip trip) async {
    if (_service.hasActiveTrip) {
      if (mounted) {
        showAppSnackBar(context, FishingLogLocalizations.of(context).endActiveTripFirst);
      }
      return;
    }
    await _service.resumeTrip(trip);
    await _loadTrips();
    _startTicker();
    if (mounted) {
      showAppSnackBar(context, FishingLogLocalizations.of(context).tripResumed);
    }
  }

  Future<void> _endTrip() async {
    final l10n = FishingLogLocalizations.of(context);
    final confirm = await _confirmDialog(
      title: l10n.endTrip,
      content: l10n.endCurrentTrip,
      confirmLabel: l10n.endButtonLabel,
      confirmColor: AppColors.red,
    );
    if (confirm != true) return;
    await _service.endTrip();
    _ticker?.cancel();
    await _loadTrips();
    if (mounted) {
      showAppSnackBar(context, FishingLogLocalizations.of(context).tripEndedAndSaved);
    }
  }

  Future<void> _logCatch() async {
    final activeTrip = _service.activeTrip;
    if (activeTrip == null) return;
    try {
      final result = await showModalBottomSheet<CatchEditResult>(
        context: context,
        isScrollControlled: true,
        backgroundColor: Colors.transparent,
        builder: (_) => const CatchEditSheet(entry: null),
      );
      if (result == null || !mounted) return;
      final loc = result.location
          ?? activeTrip.startLocation
          ?? const LatLng(26.2154, 50.5832);
      await _service.logCatch(
        tripId: activeTrip.id,
        species: result.species,
        location: loc,
        weightKg: result.weightKg,
        notes: result.notes,
      );
      await _loadTrips();
      if (mounted) {
        showAppSnackBar(context, '${result.species} ${FishingLogLocalizations.of(context).logCatch.toLowerCase()}!');
      }
    } catch (e) {
      log('FishingLogScreen: logCatch error — $e');
      if (mounted) showAppSnackBar(context, 'Error: $e');
    }
  }

  Future<void> _deleteTrip(Trip trip) async {
    final l10n = FishingLogLocalizations.of(context);
    final confirm = await _confirmDialog(
      title: l10n.deleteTrip,
      content: l10n.deleteTripConfirmFinished(trip.title ?? ''),
      confirmLabel: l10n.delete,
      confirmColor: AppColors.red,
    );
    if (confirm != true) return;
    await _service.deleteTrip(trip.id);
    await _loadTrips();
  }

  Future<void> _deleteActiveTrip() async {
    final activeTrip = _service.activeTrip;
    if (activeTrip == null) return;
    final l10n = FishingLogLocalizations.of(context);
    final confirm = await _confirmDialog(
      title: l10n.deleteActiveTrip,
      content: l10n.deleteTripConfirm,
      confirmLabel: l10n.delete,
      confirmColor: AppColors.red,
    );
    if (confirm != true || !mounted) return;
    await _service.deleteTrip(activeTrip.id);
    _ticker?.cancel();
    await _loadTrips();
    if (mounted) {
      showAppSnackBar(context, FishingLogLocalizations.of(context).tripDeleted);
    }
  }

  Future<void> _editTitle(Trip trip) async {
    final ctrl = TextEditingController(text: trip.title ?? '');
    final result = await showDialog<String>(
      context: context,
      builder: (ctx) {
        final dl10n = FishingLogLocalizations.of(ctx);
        return AlertDialog(
          backgroundColor: const Color.fromARGB(255, 237, 226, 214),
          title: Text(dl10n.editTripTitle,
              style: const TextStyle(color: AppColors.brown, fontSize: 16, fontWeight: FontWeight.w700 )),
          content: TextField(
            controller: ctrl,
            autofocus: true,
            style: const TextStyle(color: AppColors.brown),
            decoration: InputDecoration(
              hintText: dl10n.tripNameHint,
              hintStyle: TextStyle(color: AppColors.brown.withValues(alpha: 0.4)),
              enabledBorder: const UnderlineInputBorder(
                  borderSide: BorderSide(color: AppColors.brown)),
              focusedBorder: const UnderlineInputBorder(
                  borderSide: BorderSide(color: AppColors.brown)),
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(ctx),
              child: Text(dl10n.cancel,
                  style: const TextStyle(color: Color.fromARGB(255, 173, 148, 119))),
            ),
            ElevatedButton(
              onPressed: () => Navigator.pop(ctx, ctrl.text),
              style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.primary),
              child: Text(dl10n.save,
                  style: const TextStyle(color: Colors.white)),
            ),
          ],
        );
      },
    );
    if (result == null) return;
    await _service.updateTripTitle(trip.id, result);
    await _loadTrips();
  }

  Future<bool?> _confirmDialog({
    required String title,
    required String content,
    required String confirmLabel,
    required Color confirmColor,
  }) {
    return showDialog<bool>(
      context: context,
      builder: (ctx) {
        final dl10n = FishingLogLocalizations.of(ctx);
        return AlertDialog(
          backgroundColor: const Color.fromARGB(255, 237, 226, 214),
          title: Text(title,
              style: const TextStyle(color: AppColors.brown, fontSize: 16, fontWeight: FontWeight.w700 )),
          content: Text(content,
              style: const TextStyle(color: AppColors.brown, fontSize: 14, height: 1.4)),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(ctx, false),
              child: Text(dl10n.cancel,
                  style: const TextStyle(color: Color.fromARGB(255, 173, 148, 119))),
            ),
            ElevatedButton(
              onPressed: () => Navigator.pop(ctx, true),
              style: ElevatedButton.styleFrom(backgroundColor: confirmColor),
              child: Text(confirmLabel,
                  style: const TextStyle(color: Colors.white)),
            ),
          ],
        );
      },
    );
  }

  String _formatDuration(Duration d) {
    final l10n = FishingLogLocalizations.of(context);
    final locale = l10n.localeName;
    final isAr = locale == 'ar';
    final h = d.inHours;
    final m = d.inMinutes.remainder(60);
    final s = d.inSeconds.remainder(60);
    String num(int n) => arabicN('$n', locale);
    if (h > 0) return isAr ? '${num(h)}س ${num(m)}د' : '${h}h ${m}m';
    if (m > 0) return isAr ? '${num(m)}د ${num(s)}ث' : '${m}m ${s}s';
    return isAr ? '${num(s)}ث' : '${s}s';
  }

  @override
  Widget build(BuildContext context) {
    final isGuest = ref.watch(authProviderProvider).isGuest;
    final l10n = FishingLogLocalizations.of(context);

    if (isGuest) {
      return AnnotatedRegion<SystemUiOverlayStyle>(
        value: SystemUiOverlayStyle.light,
        child: Scaffold(
          body: Container(
            decoration: const BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: [AppColors.primary, AppColors.accent, AppColors.primary],
              ),
            ),
            child: SafeArea(
              child: Center(
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 40),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Container(
                        padding: const EdgeInsets.all(20),
                        decoration: BoxDecoration(
                          color: Colors.white.withValues(alpha: 0.15),
                          shape: BoxShape.circle,
                        ),
                        child: const Icon(Icons.lock_outline_rounded,
                            size: 48, color: Colors.white),
                      ),
                      const SizedBox(height: 20),
                      Text(
                        l10n.signInToSell,
                        textAlign: TextAlign.center,
                        style: const TextStyle(
                          fontSize: 15,
                          color: Colors.white70,
                          height: 1.5,
                        ),
                      ),
                      const SizedBox(height: 24),
                      SizedBox(
                        width: double.infinity,
                        child: ElevatedButton(
                          onPressed: () =>
                              ref.read(authProviderProvider).logout(),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.white.withValues(alpha: 0.85),
                            foregroundColor: AppColors.primary,
                            padding: const EdgeInsets.symmetric(vertical: 14),
                            shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(20)),
                          ),
                          child: Text(
                            l10n.logIn,
                            style: const TextStyle(
                                fontSize: 15, fontWeight: FontWeight.w700),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ),
      );
    }

    final activeTrip = _service.activeTrip;

    return AnnotatedRegion<SystemUiOverlayStyle>(
      value: SystemUiOverlayStyle.light,
      child: Scaffold(
        body: Container(
          decoration: const BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
              colors: [AppColors.primary, AppColors.accent, AppColors.primary],
            ),
          ),
          child: SafeArea(
            child: _loading
                ? const Center(
                    child: CircularProgressIndicator(color: Colors.white))
                : Column(
                    children: [
                      // ── Search bar ──────────────────────────────────────
                      Padding(
                        padding: const EdgeInsets.fromLTRB(16, 0, 16, 10),
                        child: Container(
                          decoration: BoxDecoration(
                            color: Colors.white.withValues(alpha: 0.15),
                            borderRadius: BorderRadius.circular(14),
                            border: Border.all(
                                color: Colors.white.withValues(alpha: 0.25)),
                          ),
                          child: TextField(
                            controller: _searchCtrl,
                            style: const TextStyle(
                                color: Colors.white, fontSize: 14),
                            decoration: InputDecoration(
                              hintText: l10n.searchTrips,
                              hintStyle: TextStyle(
                                  color: Colors.white.withValues(alpha: 0.6),
                                  fontSize: 14),
                              prefixIcon: Icon(Icons.search_rounded,
                                  color: Colors.white.withValues(alpha: 0.7),
                                  size: 20),
                              suffixIcon: _searchQuery.isNotEmpty
                                  ? IconButton(
                                      icon: Icon(Icons.clear_rounded,
                                          color: Colors.white
                                              .withValues(alpha: 0.7),
                                          size: 18),
                                      onPressed: () => setState(() {
                                        _searchCtrl.clear();
                                        _searchQuery = '';
                                      }),
                                    )
                                  : null,
                              border: InputBorder.none,
                              contentPadding:
                                  const EdgeInsets.symmetric(vertical: 12),
                            ),
                            onChanged: (v) =>
                                setState(() => _searchQuery = v),
                          ),
                        ),
                      ),

                      // ── Active banner ────────────────────────────────────
                      if (activeTrip != null) _buildActiveBanner(activeTrip),

                      // ── Trip list ────────────────────────────────────────
                      Expanded(
                        child: _filteredTrips.isEmpty
                            ? AppEmptyState(
                                icon: Icons.anchor,
                                title: _searchQuery.isNotEmpty
                                    ? l10n.noTripsYet
                                    : FishingLogLocalizations.of(context).noTripsYet,
                                message: _searchQuery.isNotEmpty
                                    ? l10n.tapStartTrip
                                    : FishingLogLocalizations.of(context).tapStartTrip,
                                iconColor: Colors.white.withValues(alpha: 0.5),
                              )
                            : RefreshIndicator(
                                onRefresh: _loadTrips,
                                child: ListView.builder(
                                  itemCount: _filteredTrips.length,
                                  padding:
                                      const EdgeInsets.symmetric(vertical: 8),
                                  itemBuilder: (ctx, i) {
                                    final trip = _filteredTrips[i];
                                    return TripCard(
                                      trip: trip,
                                      onTap: () => _showTripDetail(trip),
                                      onDelete: trip.isActive
                                          ? null
                                          : () => _deleteTrip(trip),
                                      onEditTitle: () => _editTitle(trip),
                                    );
                                  },
                                ),
                              ),
                      ),

                      // ── Bottom action buttons ─────────────────────────────
                      Padding(
                        padding: const EdgeInsets.fromLTRB(16, 8, 16, 16),
                        child: activeTrip != null
                            ? Row(
                                children: [
                                  _ActionButton(
                                    onPressed: _endTrip,
                                    color: const Color(0xFF6b0911),
                                    icon: Icons.stop_rounded,
                                    label: l10n.endTrip,
                                  ),
                                  const SizedBox(width: 10),
                                  Expanded(
                                    child: _ActionButton(
                                      onPressed: _logCatch,
                                      color: AppColors.accent,
                                      icon: Icons.add_rounded,
                                      label: l10n.logCatch,
                                      expand: true,
                                    ),
                                  ),
                                ],
                              )
                            : Column(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  if (_todayEndedTrip != null) ...[
                                    SizedBox(
                                      width: double.infinity,
                                      child: _ActionButton(
                                        onPressed: () => _resumeTrip(_todayEndedTrip!),
                                        color: AppColors.cream.withValues(alpha: 0.5),
                                        icon: Icons.play_arrow_rounded,
                                        label: l10n.resumeTrip,
                                        expand: true,
                                      ),
                                    ),
                                    const SizedBox(height: 10),
                                  ],
                                  SizedBox(
                                    width: double.infinity,
                                    child: _ActionButton(
                                      onPressed: _startTrip,
                                      color: const Color.fromARGB(255, 1, 66, 84),
                                      icon: Icons.anchor_rounded,
                                      label: l10n.startTrip,
                                      expand: true,
                                    ),
                                  ),
                                ],
                              ),
                      ),
                    ],
                  ),
          ),
        ),
      ),
    );
  }

  Widget _buildActiveBanner(Trip trip) {
    final l10n = FishingLogLocalizations.of(context);
    final dur = trip.duration;
    final dStr = _formatDuration(dur);
    final catchCount = trip.catches.length;
    final catchCountStr = arabicN('$catchCount', l10n.localeName);

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
      color: Colors.black.withValues(alpha: 0.25),
      child: Row(
        children: [
          const Icon(Icons.circle, color: Colors.greenAccent, size: 10),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              '${l10n.tripInProgress} — $dStr  ·  $catchCountStr ${catchCount == 1 ? l10n.catchWord : l10n.catches}',
              style: const TextStyle(color: Colors.white, fontSize: 13),
            ),
          ),
          IconButton(
            icon: const Icon(Icons.edit_outlined,
                color: Colors.white60, size: 18),
            onPressed: () => _editTitle(trip),
            tooltip: l10n.editTitleTooltip,
            padding: EdgeInsets.zero,
            constraints: const BoxConstraints(),
          ),
          const SizedBox(width: 8),
          IconButton(
            icon: const Icon(Icons.delete_outline,
                color: Colors.white38, size: 18),
            onPressed: _deleteActiveTrip,
            tooltip: l10n.deleteTripTooltip,
            padding: EdgeInsets.zero,
            constraints: const BoxConstraints(),
          ),
        ],
      ),
    );
  }

  Future<void> _showTripDetail(Trip trip) async {
    await TripDetailScreen.open(context, trip);
    await _loadTrips();
  }
}

class _ActionButton extends StatelessWidget {
  final VoidCallback onPressed;
  final Color color;
  final IconData icon;
  final String label;
  final bool expand;

  const _ActionButton({
    required this.onPressed,
    required this.color,
    required this.icon,
    required this.label,
    this.expand = false,
  });

  @override
  Widget build(BuildContext context) {
    return ElevatedButton.icon(
      onPressed: onPressed,
      icon: Icon(icon, color: Colors.white, size: 20),
      label: Text(label, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w600)),
      style: ElevatedButton.styleFrom(
        backgroundColor: color,
        padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 20),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
        minimumSize: expand ? const Size(double.infinity, 48) : const Size(0, 48),
      ),
    );
  }
}

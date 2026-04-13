import 'dart:async';
import 'dart:developer';
import 'package:bahaar/core/constants/app_colors.dart';
import 'package:bahaar/l10n/app_localizations.dart';
import 'package:bahaar/models/fishing/trip_model.dart';
import 'package:bahaar/providers/authentication/authentication_provider.dart';
import 'package:bahaar/screens/fishing%20log/trip_detail_screen.dart';
import 'package:bahaar/services/fishing/trip_service.dart';
import 'package:bahaar/utilities/cn/localization_helper.dart';
import 'package:bahaar/widgets/common/app_empty_state.dart';
import 'package:bahaar/widgets/common/app_snackbar.dart';
import 'package:bahaar/widgets/fishing_log/catch_form.dart';
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

  @override
  void initState() {
    super.initState();
    _init();
  }

  @override
  void dispose() {
    _ticker?.cancel();
    super.dispose();
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
    if (_service.hasActiveTrip) {
      if (mounted) {
        showAppSnackBar(context, AppLocalizations.of(context)!.tripAlreadyActive);
      }
      return;
    }
    final loc = await _currentLocation();
    await _service.startTrip(location: loc);
    await _loadTrips();
    _startTicker();
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
        showAppSnackBar(context, AppLocalizations.of(context)!.endActiveTripFirst);
      }
      return;
    }
    await _service.resumeTrip(trip);
    await _loadTrips();
    _startTicker();
    if (mounted) {
      showAppSnackBar(context, AppLocalizations.of(context)!.tripResumed);
    }
  }

  Future<void> _endTrip() async {
    final l10n = AppLocalizations.of(context)!;
    final confirm = await _confirmDialog(
      title: l10n.endTrip,
      content: l10n.endCurrentTrip,
      confirmLabel: l10n.endButtonLabel,
      confirmColor: const Color(0xFF4597a8),
    );
    if (confirm != true) return;
    await _service.endTrip();
    _ticker?.cancel();
    await _loadTrips();
    if (mounted) {
      showAppSnackBar(context, AppLocalizations.of(context)!.tripEndedAndSaved);
    }
  }

  Future<void> _logCatch() async {
    final activeTrip = _service.activeTrip;
    if (activeTrip == null) return;
    final result = await CatchForm.show(context);
    if (result == null) return;
    final loc = result.location ?? await _currentLocation();
    await _service.logCatch(
      tripId: activeTrip.id,
      species: result.species,
      location: loc ?? const LatLng(26.2154, 50.5832),
      weightKg: result.weightKg,
      notes: result.notes,
    );
    await _loadTrips();
    if (mounted) {
      showAppSnackBar(context, '${result.species} ${AppLocalizations.of(context)!.logCatch.toLowerCase()}!');
    }
  }

  Future<void> _deleteTrip(Trip trip) async {
    final l10n = AppLocalizations.of(context)!;
    final confirm = await _confirmDialog(
      title: l10n.deleteTrip,
      content: l10n.deleteTripConfirmFinished(trip.title ?? ''),
      confirmLabel: l10n.delete,
      confirmColor: const Color(0xFF6b0911),
    );
    if (confirm != true) return;
    await _service.deleteTrip(trip.id);
    await _loadTrips();
  }

  Future<void> _deleteActiveTrip() async {
    final activeTrip = _service.activeTrip;
    if (activeTrip == null) return;
    final l10n = AppLocalizations.of(context)!;
    final confirm = await _confirmDialog(
      title: l10n.deleteActiveTrip,
      content: l10n.deleteTripConfirm,
      confirmLabel: l10n.delete,
      confirmColor: const Color(0xFF6b0911),
    );
    if (confirm != true || !mounted) return;
    await _service.deleteTrip(activeTrip.id);
    _ticker?.cancel();
    await _loadTrips();
    if (mounted) {
      showAppSnackBar(context, AppLocalizations.of(context)!.tripDeleted);
    }
  }

  Future<void> _editTitle(Trip trip) async {
    final ctrl = TextEditingController(text: trip.title ?? '');
    final result = await showDialog<String>(
      context: context,
      builder: (ctx) {
        final dl10n = AppLocalizations.of(ctx)!;
        return AlertDialog(
          backgroundColor: AppColors.cream,
          title: Text(dl10n.editTripTitle,
              style: const TextStyle(color: AppColors.primary, fontSize: 15)),
          content: TextField(
            controller: ctrl,
            autofocus: true,
            style: const TextStyle(color: AppColors.primary),
            decoration: InputDecoration(
              hintText: dl10n.tripNameHint,
              hintStyle: TextStyle(color: AppColors.primary.withValues(alpha: 0.4)),
              enabledBorder: const UnderlineInputBorder(
                  borderSide: BorderSide(color: Color(0xFF4597a8))),
              focusedBorder: const UnderlineInputBorder(
                  borderSide: BorderSide(color: AppColors.primary)),
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(ctx),
              child: Text(dl10n.cancel,
                  style: const TextStyle(color: Color(0xFFfaf7e8))),
            ),
            ElevatedButton(
              onPressed: () => Navigator.pop(ctx, ctrl.text),
              style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF4597a8)),
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
        final dl10n = AppLocalizations.of(ctx)!;
        return AlertDialog(
          backgroundColor: AppColors.cream,
          title: Text(title,
              style: const TextStyle(color: AppColors.primary, fontSize: 15)),
          content: Text(content,
              style: const TextStyle(color: AppColors.primary, fontSize: 13)),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(ctx, false),
              child: Text(dl10n.cancel,
                  style: const TextStyle(color: AppColors.cream)),
            ),
            ElevatedButton(
              onPressed: () => Navigator.pop(ctx, true),
              style: ElevatedButton.styleFrom(backgroundColor: confirmColor),
              child: Text(confirmLabel,
                  style: const TextStyle(color: AppColors.primary)),
            ),
          ],
        );
      },
    );
  }

  String _formatDuration(Duration d) {
    final l10n = AppLocalizations.of(context)!;
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
    final l10n = AppLocalizations.of(context)!;

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
                            backgroundColor: Colors.white,
                            foregroundColor: AppColors.primary,
                            padding: const EdgeInsets.symmetric(vertical: 14),
                            shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(14)),
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
                      // ── Header ──────────────────────────────────────────
                      Padding(
                        padding: const EdgeInsets.fromLTRB(16, 12, 16, 8),
                        child: Row(
                          children: [
                            Text(
                              l10n.fishingLog,
                              style: const TextStyle(
                                color: Colors.white,
                                fontSize: 20,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            const Spacer(),
                          ],
                        ),
                      ),

                      // ── Active banner ────────────────────────────────────
                      if (activeTrip != null) _buildActiveBanner(activeTrip),

                      // ── Trip list ────────────────────────────────────────
                      Expanded(
                        child: _trips.isEmpty
                            ? AppEmptyState(
                                icon: Icons.anchor,
                                title: AppLocalizations.of(context)!.noTripsYet,
                                message: AppLocalizations.of(context)!.tapStartTrip,
                                iconColor: Colors.white.withValues(alpha: 0.5),
                              )
                            : RefreshIndicator(
                                onRefresh: _loadTrips,
                                child: ListView.builder(
                                  itemCount: _trips.length,
                                  padding:
                                      const EdgeInsets.symmetric(vertical: 8),
                                  itemBuilder: (ctx, i) {
                                    final trip = _trips[i];
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
                    ],
                  ),
          ),
        ),
        floatingActionButton: activeTrip != null
            ? Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  FloatingActionButton.small(
                    heroTag: 'end_trip',
                    backgroundColor: const Color(0xFF6b0911),
                    onPressed: _endTrip,
                    tooltip: l10n.endTrip,
                    child: const Icon(Icons.stop, color: Colors.white),
                  ),
                  const SizedBox(height: 8),
                  FloatingActionButton.extended(
                    heroTag: 'log_catch',
                    backgroundColor: const Color(0xFF4597a8),
                    onPressed: _logCatch,
                    icon: const Icon(Icons.add, color: Colors.white),
                    label: Text(l10n.logCatch,
                        style: const TextStyle(color: Colors.white)),
                  ),
                ],
              )
            : Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  if (_todayEndedTrip != null) ...[
                    FloatingActionButton.extended(
                      heroTag: 'resume_trip',
                      backgroundColor: const Color(0xFF8e7355),
                      onPressed: () => _resumeTrip(_todayEndedTrip!),
                      icon: const Icon(Icons.play_arrow, color: Colors.white),
                      label: Text(l10n.resumeTrip,
                          style: const TextStyle(color: Colors.white)),
                    ),
                    const SizedBox(height: 8),
                  ],
                  FloatingActionButton.extended(
                    heroTag: 'start_trip',
                    backgroundColor: AppColors.primary,
                    onPressed: _startTrip,
                    icon: const Icon(Icons.anchor, color: Colors.white),
                    label: Text(l10n.startTrip,
                        style: const TextStyle(color: Colors.white)),
                  ),
                ],
              ),
      ),
    );
  }

  Widget _buildActiveBanner(Trip trip) {
    final l10n = AppLocalizations.of(context)!;
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
    final changed = await TripDetailScreen.open(context, trip);
    if (changed) await _loadTrips();
  }
}

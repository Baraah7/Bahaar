import 'dart:developer';
import 'package:Bahaar/app_start.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:location/location.dart';
import 'package:latlong2/latlong.dart';
import 'package:Bahaar/models/fishing/trip_model.dart';
import 'package:Bahaar/services/fishing/trip_service.dart';
import 'package:Bahaar/widgets/fishing_log/trip_card.dart';
import 'package:Bahaar/widgets/fishing_log/catch_form.dart';
import 'package:Bahaar/screens/trip_detail_screen.dart';
import 'package:Bahaar/core/constants/app_colors.dart';
import 'package:Bahaar/providers/authentication_provider.dart';

class FishingLogScreen extends ConsumerStatefulWidget {
  const FishingLogScreen({super.key});

  @override
  ConsumerState<FishingLogScreen> createState() => _FishingLogScreenState();
}

class _FishingLogScreenState extends ConsumerState<FishingLogScreen> {
  final _service = TripService.instance;
  List<Trip> _trips = [];
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _init();
  }

  Future<void> _init() async {
    await _service.initialize();
    await _loadTrips();
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
    final loc = await _currentLocation();
    await _service.startTrip(location: loc);
    await _loadTrips();
  }

  /// Returns the most recent trip that ended today, if any.
  Trip? get _todayEndedTrip {
    final today = DateTime.now();
    for (final t in _trips) {
      if (!t.isActive && t.endTime != null) {
        final end = t.endTime!.toLocal();
        if (end.year == today.year &&
            end.month == today.month &&
            end.day == today.day) {
          return t;
        }
      }
    }
    return null;
  }

  Future<void> _resumeTrip(Trip trip) async {
    await _service.resumeTrip(trip);
    await _loadTrips();
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Trip resumed.')),
      );
    }
  }

  Future<void> _endTrip() async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: const Color(0xFF0D2E31),
        title: const Text('End Trip',
            style: TextStyle(color: Colors.white)),
        content: const Text('End your current fishing trip?',
            style: TextStyle(color: Colors.white70)),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Cancel',
                style: TextStyle(color: Colors.white54)),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(ctx, true),
            style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.accent),
            child:
                const Text('End Trip', style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );
    if (confirm != true) return;

    await _service.endTrip();
    await _loadTrips();
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Trip ended and saved.')),
      );
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
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('${result.species} logged!')),
      );
    }
  }

  Future<void> _deleteTrip(String tripId) async {
    await _service.deleteTrip(tripId);
    await _loadTrips();
  }

  Future<void> _deleteActiveTrip() async {
    final activeTrip = _service.activeTrip;
    if (activeTrip == null) return;

    final confirm = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: const Color(0xFF0D2E31),
        title: const Text('Delete Active Trip?',
            style: TextStyle(color: Colors.white)),
        content: Text(
          'This will permanently delete the current trip and all '
          '${activeTrip.catches.length} catch${activeTrip.catches.length == 1 ? '' : 'es'} logged so far. '
          'This cannot be undone.',
          style: const TextStyle(color: Colors.white70),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Cancel',
                style: TextStyle(color: Colors.white54)),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(ctx, true),
            style: ElevatedButton.styleFrom(
                backgroundColor: Colors.redAccent),
            child: const Text('Delete',
                style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );
    if (confirm != true || !mounted) return;

    await _service.deleteTrip(activeTrip.id);
    await _loadTrips();
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Trip deleted.')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final isGuest = ref.watch(authProviderProvider).isGuest;

    if (isGuest) {
      return AnnotatedRegion<SystemUiOverlayStyle>(
        value: SystemUiOverlayStyle.light,
        child: Scaffold(
          backgroundColor: AppColors.primary,
          body: Center(
            child: Padding(
              padding: const EdgeInsets.all(36),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(Icons.lock_outline,
                      size: 72, color: Colors.white.withValues(alpha: 0.7)),
                  const SizedBox(height: 24),
                  const Text(
                    'Sign In Required',
                    style: TextStyle(
                      fontSize: 22,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                    ),
                  ),
                  const SizedBox(height: 12),
                  Text(
                    'The fishing log is only available to registered users. Sign in to track your trips and catches.',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      fontSize: 14,
                      color: Colors.white.withValues(alpha: 0.75),
                      height: 1.6,
                    ),
                  ),
                  const SizedBox(height: 30),
                  ElevatedButton(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF0D4F54),
                      foregroundColor: Colors.white,
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                    ),
                    onPressed: () async {
                      final nav = Navigator.of(context);
                      await FirebaseAuth.instance.signOut();
                      nav.pushAndRemoveUntil(
                        MaterialPageRoute(builder: (_) => const AppStart()),
                        (_) => false,
                      );
                    },
                    child: const Text('Sign In'),
                  ),
                ],
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
        extendBodyBehindAppBar: true,
        appBar: AppBar(
          backgroundColor: Colors.transparent,
          elevation: 0,
          title: const Text(
            'Fishing Log',
            style: TextStyle(
              fontWeight: FontWeight.w600,
              fontSize: 20,
              color: Colors.white,
            ),
          ),
          centerTitle: true,
          actions: [
            IconButton(
              icon: const Icon(Icons.refresh, color: Colors.white),
              onPressed: _loadTrips,
              tooltip: 'Refresh',
            ),
          ],
        ),
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
                      if (activeTrip != null) _buildActiveBanner(activeTrip),
                      Expanded(
                        child: _trips.isEmpty
                            ? _buildEmpty()
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
                                          : () => _deleteTrip(trip.id),
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
                  backgroundColor: Colors.redAccent,
                  onPressed: _endTrip,
                  tooltip: 'End Trip',
                  child: const Icon(Icons.stop, color: Colors.white),
                ),
                const SizedBox(height: 8),
                FloatingActionButton.extended(
                  heroTag: 'log_catch',
                  backgroundColor: AppColors.accent,
                  onPressed: _logCatch,
                  icon: const Icon(Icons.add, color: Colors.white),
                  label: const Text('Log Catch',
                      style: TextStyle(color: Colors.white)),
                ),
              ],
            )
          : Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                if (_todayEndedTrip != null) ...[
                  FloatingActionButton.extended(
                    heroTag: 'resume_trip',
                    backgroundColor: AppColors.primary,
                    onPressed: () => _resumeTrip(_todayEndedTrip!),
                    icon: const Icon(Icons.play_arrow, color: Colors.white),
                    label: const Text('Resume Trip',
                        style: TextStyle(color: Colors.white)),
                  ),
                  const SizedBox(height: 8),
                ],
                FloatingActionButton.extended(
                  heroTag: 'start_trip',
                  backgroundColor: AppColors.primary,
                  onPressed: _startTrip,
                  icon: const Icon(Icons.anchor, color: Colors.white),
                  label: const Text('Start Trip',
                      style: TextStyle(color: Colors.white)),
                ),
              ],
            ),
      ),
    );
  }

  Widget _buildActiveBanner(Trip trip) {
    final duration = trip.duration;
    final h = duration.inHours;
    final m = duration.inMinutes.remainder(60);
    final dStr = h > 0 ? '${h}h ${m}m' : '${m}m';

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
      color: AppColors.primary,
      child: Row(
        children: [
          const Icon(Icons.circle, color: Colors.greenAccent, size: 10),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              'Trip in progress — $dStr  ·  ${trip.catches.length} catch${trip.catches.length == 1 ? '' : 'es'}',
              style: const TextStyle(color: Colors.white, fontSize: 13),
            ),
          ),
          IconButton(
            icon: const Icon(Icons.delete_outline,
                color: Colors.white54, size: 20),
            onPressed: _deleteActiveTrip,
            tooltip: 'Delete trip',
            padding: EdgeInsets.zero,
            constraints: const BoxConstraints(),
          ),
        ],
      ),
    );
  }

  Widget _buildEmpty() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.anchor, size: 64, color: Colors.white.withValues(alpha: 0.5)),
          const SizedBox(height: 16),
          Text(
            'No trips yet',
            style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.w600,
                color: Colors.white.withValues(alpha: 0.9)),
          ),
          const SizedBox(height: 8),
          Text(
            'Tap "Start Trip" to begin logging your catches.',
            style: TextStyle(color: Colors.white.withValues(alpha: 0.6), fontSize: 13),
            textAlign: TextAlign.center,
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

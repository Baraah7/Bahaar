import 'dart:developer';
import 'package:flutter/material.dart';
import 'package:location/location.dart';
import 'package:latlong2/latlong.dart';
<<<<<<< HEAD
import 'package:intl/intl.dart';
=======
>>>>>>> origin/exp
import 'package:Bahaar/models/fishing/trip_model.dart';
import 'package:Bahaar/services/fishing/trip_service.dart';
import 'package:Bahaar/widgets/fishing_log/trip_card.dart';
import 'package:Bahaar/widgets/fishing_log/catch_form.dart';
<<<<<<< HEAD
=======
import 'package:Bahaar/screens/trip_detail_screen.dart';
>>>>>>> origin/exp

class FishingLogScreen extends StatefulWidget {
  const FishingLogScreen({super.key});

  @override
  State<FishingLogScreen> createState() => _FishingLogScreenState();
}

class _FishingLogScreenState extends State<FishingLogScreen> {
  final _service = TripService.instance;
  List<Trip> _trips = [];
  bool _loading = true;

  @override
  void initState() {
    super.initState();
<<<<<<< HEAD
    _loadTrips();
=======
    _init();
  }

  Future<void> _init() async {
    await _service.initialize();
    await _loadTrips();
>>>>>>> origin/exp
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

<<<<<<< HEAD
=======
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

>>>>>>> origin/exp
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
                backgroundColor: const Color(0xFF0E7490)),
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

<<<<<<< HEAD
=======
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

>>>>>>> origin/exp
  @override
  Widget build(BuildContext context) {
    final activeTrip = _service.activeTrip;

    return Scaffold(
      backgroundColor: const Color(0xFFF5F7FA),
      appBar: AppBar(
        title: const Text('Fishing Log',
            style: TextStyle(fontWeight: FontWeight.bold, fontSize: 20)),
        backgroundColor: const Color(0xFF0D4F54),
        foregroundColor: Colors.white,
        centerTitle: true,
        elevation: 0,
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _loadTrips,
            tooltip: 'Refresh',
          ),
        ],
      ),
      body: _loading
          ? const Center(
              child: CircularProgressIndicator(color: Color(0xFF0D4F54)))
          : Column(
              children: [
                // Active trip banner
                if (activeTrip != null) _buildActiveBanner(activeTrip),

                // Trip list
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
                  backgroundColor: const Color(0xFF0E7490),
                  onPressed: _logCatch,
                  icon: const Icon(Icons.add, color: Colors.white),
                  label: const Text('Log Catch',
                      style: TextStyle(color: Colors.white)),
                ),
              ],
            )
<<<<<<< HEAD
          : FloatingActionButton.extended(
              heroTag: 'start_trip',
              backgroundColor: const Color(0xFF0D4F54),
              onPressed: _startTrip,
              icon: const Icon(Icons.anchor, color: Colors.white),
              label: const Text('Start Trip',
                  style: TextStyle(color: Colors.white)),
=======
          : Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                if (_todayEndedTrip != null) ...[
                  FloatingActionButton.extended(
                    heroTag: 'resume_trip',
                    backgroundColor: const Color(0xFF1A5C62),
                    onPressed: () => _resumeTrip(_todayEndedTrip!),
                    icon: const Icon(Icons.play_arrow, color: Colors.white),
                    label: const Text('Resume Trip',
                        style: TextStyle(color: Colors.white)),
                  ),
                  const SizedBox(height: 8),
                ],
                FloatingActionButton.extended(
                  heroTag: 'start_trip',
                  backgroundColor: const Color(0xFF0D4F54),
                  onPressed: _startTrip,
                  icon: const Icon(Icons.anchor, color: Colors.white),
                  label: const Text('Start Trip',
                      style: TextStyle(color: Colors.white)),
                ),
              ],
>>>>>>> origin/exp
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
      color: const Color(0xFF0D4F54),
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
<<<<<<< HEAD
=======
          IconButton(
            icon: const Icon(Icons.delete_outline,
                color: Colors.white54, size: 20),
            onPressed: _deleteActiveTrip,
            tooltip: 'Delete trip',
            padding: EdgeInsets.zero,
            constraints: const BoxConstraints(),
          ),
>>>>>>> origin/exp
        ],
      ),
    );
  }

  Widget _buildEmpty() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.anchor, size: 64, color: Colors.grey.shade400),
          const SizedBox(height: 16),
          Text(
            'No trips yet',
            style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.w600,
                color: Colors.grey.shade600),
          ),
          const SizedBox(height: 8),
          Text(
            'Tap "Start Trip" to begin logging your catches.',
            style: TextStyle(color: Colors.grey.shade500, fontSize: 13),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

<<<<<<< HEAD
  void _showTripDetail(Trip trip) {
    showModalBottomSheet(
      context: context,
      backgroundColor: const Color(0xFF0D2E31),
      shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
      isScrollControlled: true,
      builder: (_) => _TripDetailSheet(trip: trip),
    );
  }
}

class _TripDetailSheet extends StatelessWidget {
  final Trip trip;
  const _TripDetailSheet({required this.trip});

  @override
  Widget build(BuildContext context) {
    final dateStr = DateFormat('EEE d MMM yyyy · HH:mm')
        .format(trip.startTime.toLocal());

    return DraggableScrollableSheet(
      expand: false,
      initialChildSize: 0.6,
      maxChildSize: 0.92,
      builder: (_, ctrl) => Container(
        decoration: const BoxDecoration(
          color: Color(0xFF0D2E31),
          borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
        ),
        child: Column(
          children: [
            // Handle
            const SizedBox(height: 12),
            Center(
              child: Container(
                width: 36,
                height: 4,
                decoration: BoxDecoration(
                  color: Colors.white24,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
            ),
            const SizedBox(height: 12),
            // Header
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              child: Row(
                children: [
                  const Icon(Icons.anchor, color: Colors.white70),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(dateStr,
                            style: const TextStyle(
                                color: Colors.white,
                                fontSize: 15,
                                fontWeight: FontWeight.bold)),
                        Text(
                          '${trip.catches.length} catch${trip.catches.length == 1 ? '' : 'es'} · ${trip.totalWeightKg.toStringAsFixed(1)} kg total',
                          style: const TextStyle(
                              color: Colors.white54, fontSize: 12),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            const Divider(color: Colors.white12, height: 24),
            // Catches list
            Expanded(
              child: trip.catches.isEmpty
                  ? const Center(
                      child: Text('No catches logged.',
                          style: TextStyle(color: Colors.white38)))
                  : ListView.separated(
                      controller: ctrl,
                      padding: const EdgeInsets.symmetric(horizontal: 20),
                      itemCount: trip.catches.length,
                      separatorBuilder: (_, __) =>
                          const Divider(color: Colors.white10),
                      itemBuilder: (_, i) {
                        final c = trip.catches[i];
                        final timeStr = DateFormat('HH:mm')
                            .format(c.timestamp.toLocal());
                        return Padding(
                          padding: const EdgeInsets.symmetric(vertical: 8),
                          child: Row(
                            children: [
                              const Icon(Icons.set_meal,
                                  color: Color(0xFF4FC3F7), size: 20),
                              const SizedBox(width: 12),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment:
                                      CrossAxisAlignment.start,
                                  children: [
                                    Text(c.species,
                                        style: const TextStyle(
                                            color: Colors.white,
                                            fontWeight: FontWeight.w600)),
                                    if (c.notes != null)
                                      Text(c.notes!,
                                          style: const TextStyle(
                                              color: Colors.white38,
                                              fontSize: 12)),
                                  ],
                                ),
                              ),
                              Column(
                                crossAxisAlignment: CrossAxisAlignment.end,
                                children: [
                                  if (c.weightKg != null)
                                    Text('${c.weightKg!.toStringAsFixed(1)} kg',
                                        style: const TextStyle(
                                            color: Colors.white70,
                                            fontSize: 13)),
                                  Text(timeStr,
                                      style: const TextStyle(
                                          color: Colors.white38,
                                          fontSize: 11)),
                                ],
                              ),
                            ],
                          ),
                        );
                      },
                    ),
            ),
          ],
        ),
      ),
    );
=======
  Future<void> _showTripDetail(Trip trip) async {
    final changed = await TripDetailScreen.open(context, trip);
    if (changed) await _loadTrips();
>>>>>>> origin/exp
  }
}

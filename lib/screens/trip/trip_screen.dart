import 'dart:async';
import 'package:flutter/material.dart';
import 'package:bahaar/core/constants/app_colors.dart';
import 'package:bahaar/navigation/dead_reckoning.dart';
import 'package:bahaar/navigation/trip_database.dart';
import 'package:bahaar/navigation/trip_recorder.dart';
import 'package:bahaar/navigation/port_router.dart';
import 'package:bahaar/screens/trip/port_manager_screen.dart';

class TripScreen extends StatefulWidget {
  const TripScreen({super.key});

  @override
  State<TripScreen> createState() => _TripScreenState();
}

class _TripScreenState extends State<TripScreen> {
  final _recorder = TripRecorder.instance;

  // DR tick timer — refreshes uncertainty display every 30 s while GPS is lost
  Timer? _drTimer;

  // Elapsed trip time display
  Timer? _clockTimer;
  DateTime? _tripStart;

  @override
  void initState() {
    super.initState();
    _recorder.addListener(_onRecorderUpdate);
    _startTimers();
    // Purge any waypoints orphaned by a previous crash
    TripDatabase.instance.purgeOrphanedWaypoints();
  }

  @override
  void dispose() {
    _recorder.removeListener(_onRecorderUpdate);
    _drTimer?.cancel();
    _clockTimer?.cancel();
    super.dispose();
  }

  void _onRecorderUpdate() {
    if (mounted) setState(() {});
  }

  void _startTimers() {
    _clockTimer = Timer.periodic(const Duration(seconds: 1), (_) {
      if (mounted) setState(() {});
    });
    _drTimer = Timer.periodic(const Duration(seconds: 30), (_) {
      _recorder.tickDr();
    });
  }

  // ── Start trip flow ──────────────────────────────────────────────────────

  Future<void> _startTripFlow() async {
    final ports = await TripDatabase.instance.getAllPorts();

    if (!mounted) return;

    if (ports.isEmpty) {
      final goAdd = await showDialog<bool>(
        context: context,
        builder: (ctx) => AlertDialog(
          title: const Text('No Ports Saved'),
          content: const Text(
            'You need to save at least one departure port before '
            'starting a trip.\n\nWould you like to add a port now?',
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(ctx, false),
              child: const Text('Cancel'),
            ),
            ElevatedButton(
              style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.primary,
                  foregroundColor: Colors.white),
              onPressed: () => Navigator.pop(ctx, true),
              child: const Text('Add Port'),
            ),
          ],
        ),
      );
      if (goAdd == true && mounted) {
        await Navigator.push(
          context,
          MaterialPageRoute(builder: (_) => const PortManagerScreen()),
        );
      }
      return;
    }

    // Let user pick departure port
    if (!mounted) return;
    final departure = await showDialog<Port>(
      context: context,
      builder: (ctx) => _PortPickerDialog(ports: ports),
    );
    if (departure == null || !mounted) return;

    // Consent dialog — MANDATORY
    final consented = await showDialog<bool>(
      context: context,
      barrierDismissible: false,
      builder: (ctx) => AlertDialog(
        icon: const Icon(Icons.privacy_tip_outlined,
            color: AppColors.primary, size: 32),
        title: const Text('Start Recording Trip?'),
        content: Text(
          'This trip recorder will save your GPS position every '
          '5 minutes until you return to port.\n\n'
          '• All waypoints are stored ONLY on this device.\n'
          '• All waypoints are permanently deleted when the trip ends.\n'
          '• No location data is ever sent to any server.\n\n'
          'Departure port: ${departure.name}',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.primary,
                foregroundColor: Colors.white),
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('Start Trip'),
          ),
        ],
      ),
    );

    if (consented == true) {
      try {
        await _recorder.startTrip(departure);
        _tripStart = DateTime.now();
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(SnackBar(
            backgroundColor: AppColors.red,
            content: Text('Failed to start trip: $e',
                style: const TextStyle(color: Colors.white)),
          ));
        }
      }
    }
  }

  // ── End trip flow ────────────────────────────────────────────────────────

  Future<void> _endTripFlow() async {
    final confirmed = await showDialog<bool>(
      context: context,
      barrierDismissible: false,
      builder: (ctx) => AlertDialog(
        icon: const Icon(Icons.warning_amber_rounded,
            color: Colors.orange, size: 32),
        title: const Text('End Trip?'),
        content: const Text(
          'This will stop recording and PERMANENTLY DELETE all '
          'waypoints recorded during this trip.\n\n'
          'This action cannot be undone.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Keep Recording'),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
                backgroundColor: Colors.red.shade700,
                foregroundColor: Colors.white),
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('End Trip & Delete Waypoints'),
          ),
        ],
      ),
    );

    if (confirmed == true) {
      await _recorder.endTrip();
      _tripStart = null;
    }
  }

  // ── Build ────────────────────────────────────────────────────────────────

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.cream,
      appBar: AppBar(
        backgroundColor: AppColors.primary,
        foregroundColor: Colors.white,
        title: const Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.route, size: 20),
            SizedBox(width: 8),
            Text('Trip Recorder',
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
          ],
        ),
        centerTitle: true,
        actions: [
          IconButton(
            icon: const Icon(Icons.anchor),
            tooltip: 'Manage Ports',
            onPressed: () => Navigator.push(
              context,
              MaterialPageRoute(builder: (_) => const PortManagerScreen()),
            ),
          ),
        ],
      ),
      body: switch (_recorder.status) {
        TripStatus.idle  => _IdleView(onStart: _startTripFlow),
        TripStatus.ended => _IdleView(onStart: _startTripFlow),
        TripStatus.active ||
        TripStatus.gpsLost => _ActiveTripView(
            recorder:   _recorder,
            tripStart:  _tripStart,
            onEndTrip:  _endTripFlow,
          ),
      },
    );
  }
}

// ─── Idle (no active trip) ────────────────────────────────────────────────────

class _IdleView extends StatelessWidget {
  final VoidCallback onStart;
  const _IdleView({required this.onStart});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.directions_boat_outlined,
                size: 72, color: AppColors.primary.withValues(alpha: 0.6)),
            const SizedBox(height: 20),
            const Text(
              'No Active Trip',
              style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            const Text(
              'Start a trip to record your route and enable '
              'offline port-based return navigation.',
              textAlign: TextAlign.center,
              style: TextStyle(fontSize: 14, color: Colors.black54),
            ),
            const SizedBox(height: 28),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton.icon(
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.primary,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 14),
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12)),
                ),
                icon: const Icon(Icons.play_circle_outline),
                label: const Text('Start New Trip',
                    style: TextStyle(fontSize: 16)),
                onPressed: onStart,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ─── Active trip dashboard ────────────────────────────────────────────────────

class _ActiveTripView extends StatelessWidget {
  final TripRecorder  recorder;
  final DateTime?     tripStart;
  final VoidCallback  onEndTrip;

  const _ActiveTripView({
    required this.recorder,
    required this.tripStart,
    required this.onEndTrip,
  });

  @override
  Widget build(BuildContext context) {
    final pos    = recorder.currentPosition;
    final drFix  = recorder.drFix;
    final routes = recorder.portRoutes;
    final depPort = recorder.departurePort;

    return ListView(
      padding: const EdgeInsets.all(12),
      children: [
        // ── GPS lost banner ───────────────────────────────────────────────
        if (recorder.status == TripStatus.gpsLost)
          _GpsLostBanner(drFix: drFix),

        // ── Status header ─────────────────────────────────────────────────
        _SectionCard(
          title: 'Trip Status',
          icon:  Icons.timer_outlined,
          children: [
            _Row('Departure', depPort?.name ?? '—'),
            _Row('Elapsed',   _fmtElapsed(tripStart)),
            _Row('Waypoints saved', '${recorder.waypoints.length}'),
            _Row('Fix source',
                pos?.source.label ?? '—',
                valueColor: _sourceColor(pos?.source)),
            if (pos != null)
              _Row('Position accuracy',
                  '±${pos.accuracyNm.toStringAsFixed(2)} NM'),
          ],
        ),
        const SizedBox(height: 10),

        // ── Current position ──────────────────────────────────────────────
        if (pos != null)
          _SectionCard(
            title: 'Current Position',
            icon:  Icons.my_location,
            children: [
              _Row('Latitude',
                  '${pos.position.latitude.toStringAsFixed(5)}°'),
              _Row('Longitude',
                  '${pos.position.longitude.toStringAsFixed(5)}°'),
              if (pos.headingDeg != null)
                _Row('Heading',
                    '${pos.headingDeg!.toStringAsFixed(1)}° true'),
              if (pos.speedKn != null)
                _Row('Speed', '${pos.speedKn!.toStringAsFixed(1)} kn'),
              if (drFix != null) ...[
                const Divider(height: 10),
                _Row('DR elapsed', _fmtDuration(drFix.elapsed)),
                _Row('DR distance',
                    '${drFix.distanceTraveledNm.toStringAsFixed(1)} NM'),
                _Row(
                  'DR uncertainty',
                  '±${drFix.uncertaintyNm.toStringAsFixed(1)} NM',
                  valueColor: _reliabilityColor(drFix.reliability),
                ),
              ],
            ],
          ),
        const SizedBox(height: 10),

        // ── Return to port routing ────────────────────────────────────────
        if (routes.isNotEmpty)
          Builder(builder: (context) {
            final depRoutes = routes
                .where((r) => r.port.id == depPort?.id)
                .toList();
            final otherRoutes = routes
                .where((r) => r.port.id != depPort?.id)
                .toList();
            return _SectionCard(
              title: 'Return Navigation',
              icon:  Icons.navigation_outlined,
              children: [
                if (depPort != null) ...[
                  const _SubHeader('Departure Port'),
                  if (depRoutes.isNotEmpty)
                    ...depRoutes.map((r) => _RouteRow(route: r))
                  else
                    const Padding(
                      padding: EdgeInsets.only(left: 4, bottom: 4),
                      child: Text(
                        'Departure port not in routing range.',
                        style: TextStyle(fontSize: 11, color: Colors.black45),
                      ),
                    ),
                ],
                if (otherRoutes.isNotEmpty) ...[
                  const _SubHeader('Nearest Alternatives'),
                  ...otherRoutes.map((r) => _RouteRow(route: r)),
                ],
              ],
            );
          }),
        const SizedBox(height: 10),

        // ── Recent waypoints ──────────────────────────────────────────────
        if (recorder.waypoints.isNotEmpty)
          _SectionCard(
            title: 'Recent Waypoints',
            icon:  Icons.location_history,
            children: [
              ...recorder.waypoints.reversed
                  .take(5)
                  .map((w) => _WaypointRow(wp: w)),
              if (recorder.waypoints.length > 5)
                Padding(
                  padding: const EdgeInsets.only(top: 4),
                  child: Text(
                    '+ ${recorder.waypoints.length - 5} earlier',
                    style: const TextStyle(
                        fontSize: 11, color: Colors.black45),
                  ),
                ),
            ],
          ),
        const SizedBox(height: 16),

        // ── End trip ──────────────────────────────────────────────────────
        SizedBox(
          width: double.infinity,
          child: OutlinedButton.icon(
            style: OutlinedButton.styleFrom(
              foregroundColor:  Colors.red.shade700,
              side: BorderSide(color: Colors.red.shade700),
              padding: const EdgeInsets.symmetric(vertical: 14),
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12)),
            ),
            icon: const Icon(Icons.stop_circle_outlined),
            label: const Text('End Trip & Delete Waypoints',
                style: TextStyle(fontSize: 15)),
            onPressed: onEndTrip,
          ),
        ),
        const SizedBox(height: 24),
      ],
    );
  }

  static String _fmtElapsed(DateTime? start) {
    if (start == null) return '—';
    return _fmtDuration(DateTime.now().difference(start));
  }

  static String _fmtDuration(Duration d) {
    final h = d.inHours;
    final m = d.inMinutes.remainder(60);
    final s = d.inSeconds.remainder(60);
    if (h > 0) return '${h}h ${m.toString().padLeft(2, '0')}m';
    return '${m}m ${s.toString().padLeft(2, '0')}s';
  }

  static Color? _sourceColor(FixType? t) {
    if (t == null) return null;
    switch (t) {
      case FixType.gps:          return Colors.green.shade700;
      case FixType.celestial:    return const Color(0xFF7C4DFF);
      case FixType.deadReckoning: return Colors.orange.shade700;
    }
  }

  static Color _reliabilityColor(DrReliability r) {
    switch (r) {
      case DrReliability.good:     return Colors.green.shade700;
      case DrReliability.warning:  return Colors.orange.shade700;
      case DrReliability.exceeded: return Colors.red.shade700;
    }
  }
}

// ─── GPS Lost banner ──────────────────────────────────────────────────────────

class _GpsLostBanner extends StatelessWidget {
  final DeadReckoningFix? drFix;
  const _GpsLostBanner({this.drFix});

  @override
  Widget build(BuildContext context) {
    final exceeded = drFix?.reliability == DrReliability.exceeded;
    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: exceeded ? Colors.red.shade700 : Colors.orange.shade700,
        borderRadius: BorderRadius.circular(10),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(
                exceeded
                    ? Icons.gps_off
                    : Icons.gps_not_fixed,
                color: Colors.white,
              ),
              const SizedBox(width: 8),
              Text(
                exceeded
                    ? 'GPS LOST — DR UNRELIABLE'
                    : 'GPS LOST — Using Dead Reckoning',
                style: const TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                    fontSize: 13),
              ),
            ],
          ),
          if (drFix != null && drFix!.advisory.isNotEmpty) ...[
            const SizedBox(height: 6),
            Text(
              drFix!.advisory,
              style: const TextStyle(color: Colors.white, fontSize: 12),
            ),
          ],
          if (exceeded) ...[
            const SizedBox(height: 8),
            const Text(
              'RECOMMENDATION: Heave to and attempt a celestial '
              'observation before continuing.',
              style: TextStyle(
                  color: Colors.white,
                  fontSize: 12,
                  fontStyle: FontStyle.italic),
            ),
          ],
        ],
      ),
    );
  }
}

// ─── Route row ────────────────────────────────────────────────────────────────

class _RouteRow extends StatelessWidget {
  final RouteToPort route;
  const _RouteRow({required this.route});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(
                route.isDeparture ? Icons.anchor : Icons.place_outlined,
                size: 16,
                color: route.isDeparture
                    ? AppColors.primary
                    : AppColors.accent,
              ),
              const SizedBox(width: 6),
              Expanded(
                child: Text(
                  route.port.name,
                  style: TextStyle(
                    fontWeight: route.isDeparture
                        ? FontWeight.bold
                        : FontWeight.normal,
                    fontSize: 13,
                  ),
                ),
              ),
            ],
          ),
          Padding(
            padding: const EdgeInsets.only(left: 22),
            child: Text(
              route.instruction,
              style: const TextStyle(
                  fontFamily: 'monospace',
                  fontSize: 12,
                  color: Colors.black87),
            ),
          ),
          if (route.warning != null)
            Padding(
              padding: const EdgeInsets.only(left: 22, top: 2),
              child: Text(
                route.warning!,
                style: TextStyle(
                    fontSize: 11, color: Colors.orange.shade700),
              ),
            ),
        ],
      ),
    );
  }
}

// ─── Waypoint row ─────────────────────────────────────────────────────────────

class _WaypointRow extends StatelessWidget {
  final Waypoint wp;
  const _WaypointRow({required this.wp});

  @override
  Widget build(BuildContext context) {
    final time = wp.recordedAt.toLocal();
    final label =
        '${time.hour.toString().padLeft(2, '0')}:'
        '${time.minute.toString().padLeft(2, '0')}  '
        '${wp.lat.toStringAsFixed(4)}°, ${wp.lng.toStringAsFixed(4)}°';

    final badgeColor = switch (wp.fixType) {
      FixType.gps          => Colors.green,
      FixType.celestial    => const Color(0xFF7C4DFF),
      FixType.deadReckoning => Colors.orange,
    };

    return Padding(
      padding: const EdgeInsets.only(bottom: 4),
      child: Row(
        children: [
          Container(
            padding:
                const EdgeInsets.symmetric(horizontal: 5, vertical: 2),
            decoration: BoxDecoration(
              color: badgeColor.withValues(alpha: 0.15),
              border:
                  Border.all(color: badgeColor.withValues(alpha: 0.5)),
              borderRadius: BorderRadius.circular(4),
            ),
            child: Text(
              wp.fixType.label,
              style: TextStyle(
                  fontSize: 9,
                  color: badgeColor,
                  fontWeight: FontWeight.bold),
            ),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Text(label,
                style: const TextStyle(fontSize: 11)),
          ),
          Text('±${wp.accuracyNm.toStringAsFixed(1)} NM',
              style: const TextStyle(
                  fontSize: 10, color: Colors.black45)),
        ],
      ),
    );
  }
}

// ─── Reusable layout ──────────────────────────────────────────────────────────

class _SectionCard extends StatelessWidget {
  final String       title;
  final IconData     icon;
  final List<Widget> children;

  const _SectionCard({
    required this.title,
    required this.icon,
    required this.children,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      elevation: 2,
      color: Colors.white,
      shape:
          RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(14),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(children: [
              Icon(icon, size: 18, color: AppColors.primary),
              const SizedBox(width: 8),
              Text(title,
                  style: const TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 14,
                      color: AppColors.primary)),
            ]),
            const Divider(height: 14),
            ...children,
          ],
        ),
      ),
    );
  }
}

class _Row extends StatelessWidget {
  final String  label;
  final String  value;
  final Color?  valueColor;

  const _Row(this.label, this.value, {this.valueColor});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 2),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label,
              style: const TextStyle(fontSize: 12, color: Colors.black54)),
          Text(value,
              style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                  color: valueColor)),
        ],
      ),
    );
  }
}

class _SubHeader extends StatelessWidget {
  final String text;
  const _SubHeader(this.text);

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(top: 4, bottom: 6),
      child: Text(text,
          style: const TextStyle(
              fontSize: 11,
              fontWeight: FontWeight.bold,
              color: Colors.black45,
              letterSpacing: 0.8)),
    );
  }
}

// ─── Port picker ──────────────────────────────────────────────────────────────

class _PortPickerDialog extends StatelessWidget {
  final List<Port> ports;
  const _PortPickerDialog({required this.ports});

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('Select Departure Port'),
      content: SizedBox(
        width: double.maxFinite,
        child: ListView.separated(
          shrinkWrap: true,
          itemCount: ports.length,
          separatorBuilder: (_, __) => const Divider(height: 1),
          itemBuilder: (ctx, i) {
            final p = ports[i];
            return ListTile(
              leading: const Icon(Icons.anchor, color: AppColors.primary),
              title:    Text(p.name),
              subtitle: Text(
                '${p.lat.toStringAsFixed(4)}°, ${p.lng.toStringAsFixed(4)}°',
                style:
                    const TextStyle(fontSize: 11, color: Colors.black54),
              ),
              onTap: () => Navigator.pop(ctx, p),
            );
          },
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text('Cancel'),
        ),
      ],
    );
  }
}

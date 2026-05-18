import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:bahaar/constants/app_colors.dart';
import 'package:bahaar/models/navigation/navigation_session_model.dart';
import 'package:bahaar/models/navigation/waypoint_model.dart';
import 'package:bahaar/services/map/navigation_voice_service.dart';
import 'package:bahaar/widgets/map/sos_button.dart';
import 'package:latlong2/latlong.dart';

class ActiveNavigationOverlay extends StatefulWidget {
  final NavigationSession session;
  final VoidCallback? onEndNavigation;
  final VoidCallback? onRecenter;
  final bool isRecalculating;
  final bool isFollowing;
  final VoidCallback? onToggleFollow;

  const ActiveNavigationOverlay({
    super.key,
    required this.session,
    this.onEndNavigation,
    this.onRecenter,
    this.isRecalculating = false,
    this.isFollowing = false,
    this.onToggleFollow,
  });

  @override
  State<ActiveNavigationOverlay> createState() =>
      _ActiveNavigationOverlayState();
}

class _ActiveNavigationOverlayState extends State<ActiveNavigationOverlay> {
  final NavigationVoiceService _voice = NavigationVoiceService();
  int? _lastAnnouncedWaypointIndex;
  bool? _lastRecalculating;

  NavigationSession get session => widget.session;
  bool get isRecalculating => widget.isRecalculating;

  @override
  void initState() {
    super.initState();
    _voice.init();
  }

  @override
  void didUpdateWidget(ActiveNavigationOverlay oldWidget) {
    super.didUpdateWidget(oldWidget);

    if (widget.isRecalculating && _lastRecalculating != true) {
      _voice.speak('Recalculating route');
    }
    _lastRecalculating = widget.isRecalculating;

    final idx = widget.session.currentWaypointIndex;
    if (_lastAnnouncedWaypointIndex != idx) {
      _lastAnnouncedWaypointIndex = idx;
      _voice.resetApproach();
      final next = widget.session.nextWaypoint;
      if (next != null) {
        final instruction =
            _directionInstruction(next, widget.session.currentLocation);
        _voice.speak(instruction);
      }
    }
  }

  @override
  void dispose() {
    _voice.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    // The arrival dialog is shown by integrated_map.dart — nothing to render
    // for this overlay once the session is completed.
    if (session.state == NavigationState.completed) {
      return const SizedBox.shrink();
    }

    return Stack(
      fit: StackFit.expand,
      children: [
        // ── Instruction card (full width) ─────────────────────────
        Positioned(
          top: 16,
          left: 16,
          right: 16,
          child: SafeArea(child: _buildInstructionCard(context)),
        ),

        // ── Recalculating overlay ─────────────────────────────────
        if (isRecalculating)
          Positioned(
            top: 140,
            left: 0,
            right: 0,
            child: Center(
              child: Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                decoration: BoxDecoration(
                  color: Colors.orange,
                  borderRadius: BorderRadius.circular(8),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withValues(alpha: 0.2),
                      blurRadius: 8,
                    ),
                  ],
                ),
                child: const Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    SizedBox(
                      width: 16,
                      height: 16,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        valueColor:
                            AlwaysStoppedAnimation<Color>(Colors.white),
                      ),
                    ),
                    SizedBox(width: 12),
                    Text(
                      'Recalculating route...',
                      style: TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),

        // ── Follow-location toggle (above the bottom bar, right side) ──
        if (widget.onToggleFollow != null)
          Positioned(
            bottom: 108,
            right: 16,
            child: GestureDetector(
              onTap: widget.onToggleFollow,
              child: Container(
                width: 44,
                height: 44,
                decoration: BoxDecoration(
                  color: widget.isFollowing ? AppColors.primary : Colors.white,
                  shape: BoxShape.circle,
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withValues(alpha: 0.22),
                      blurRadius: 8,
                      offset: const Offset(0, 2),
                    ),
                  ],
                ),
                child: Icon(
                  Icons.navigation_rounded,
                  size: 22,
                  color: widget.isFollowing
                      ? Colors.white
                      : Colors.grey.shade600,
                ),
              ),
            ),
          ),

        // ── Unified navigation bottom bar ─────────────────────────
        Positioned(
            bottom: 24,
            left: 16,
            right: 16,
            child: _buildNavBottomBar(context),
          ),
      ],
    );
  }

  // ── Instruction card ───────────────────────────────────────────────────────

  Widget _buildInstructionCard(BuildContext context) {
    final nextWaypoint = session.nextWaypoint;

    if (nextWaypoint == null) {
      final loc = session.currentLocation;
      final dest = session.route.destination;
      final compass =
          loc != null ? _bearingToCompass(_computeBearing(loc, dest)) : null;
      final distToDest = loc != null
          ? _calculateDistanceToPoint(loc, dest)
          : session.distanceRemaining;
      final instruction = compass != null
          ? 'Head $compass toward destination'
          : 'Continue toward destination';

      return Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
        decoration: _cardDecoration(),
        child: Row(
          children: [
            _directionIconBox(Icons.navigation_rounded, AppColors.accent),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    _formatDistance(distToDest),
                    style: const TextStyle(
                      fontSize: 22,
                      fontWeight: FontWeight.bold,
                      color: AppColors.accent,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    instruction,
                    style: const TextStyle(fontSize: 13, color: Colors.black87),
                  ),
                ],
              ),
            ),
          ],
        ),
      );
    }

    final distanceToWaypoint = _calculateDistanceToWaypoint(nextWaypoint);
    final color = _getSegmentColor(nextWaypoint.segmentType);
    final directionText =
        _directionInstruction(nextWaypoint, session.currentLocation);
    final icon = _getDirectionIcon(nextWaypoint.type, directionText);

    _voice.announceApproach(nextWaypoint.id, directionText, distanceToWaypoint);

    return Container(
      padding: const EdgeInsets.all(14),
      decoration: _cardDecoration(),
      child: Row(
        children: [
          _directionIconBox(icon, color),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  _formatDistance(distanceToWaypoint),
                  style: TextStyle(
                    fontSize: 22,
                    fontWeight: FontWeight.bold,
                    color: color,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  directionText,
                  style:
                      const TextStyle(fontSize: 13, color: Colors.black87),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _directionIconBox(IconData icon, Color color) {
    return Container(
      width: 52,
      height: 52,
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.15),
        borderRadius: BorderRadius.circular(10),
      ),
      child: Icon(icon, color: color, size: 30),
    );
  }

  // ── Unified navigation bottom bar ──────────────────────────────────────────

  Widget _buildNavBottomBar(BuildContext context) {
    final timeRemaining = session.timeRemaining;
    final distanceRemaining = session.distanceRemaining;
    final eta = DateTime.now().add(Duration(seconds: timeRemaining));
    final etaStr =
        '${eta.hour.toString().padLeft(2, '0')}:${eta.minute.toString().padLeft(2, '0')}';

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.18),
            blurRadius: 10,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          // SOS button
          const SosButton(),

          // Metrics
          Expanded(
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [
                _navMetric(
                  _formatDuration(timeRemaining),
                  'Time',
                  Colors.orange,
                ),
                _vertDivider(),
                _navMetric(
                  _formatDistance(distanceRemaining),
                  'Dist',
                  AppColors.primary,
                ),
                _vertDivider(),
                _navMetric(etaStr, 'ETA', AppColors.accent),
              ],
            ),
          ),

          // End trip button
          GestureDetector(
            onTap: widget.onEndNavigation,
            child: Container(
              padding:
                  const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
              decoration: BoxDecoration(
                color: Colors.red.shade600,
                borderRadius: BorderRadius.circular(14),
              ),
              child: const Icon(Icons.close_rounded,
                  color: Colors.white, size: 22),
            ),
          ),
        ],
      ),
    );
  }

  Widget _navMetric(String value, String label, Color color) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(
          value,
          style: TextStyle(
            fontSize: 13,
            fontWeight: FontWeight.bold,
            color: color,
          ),
        ),
        Text(
          label,
          style: TextStyle(fontSize: 10, color: Colors.grey.shade500),
        ),
      ],
    );
  }

  Widget _vertDivider() {
    return Container(width: 1, height: 28, color: Colors.grey.shade200);
  }

  // ── Helper decorations ─────────────────────────────────────────────────────

  BoxDecoration _cardDecoration() {
    return BoxDecoration(
      color: Colors.white,
      borderRadius: BorderRadius.circular(12),
      boxShadow: [
        BoxShadow(
          color: Colors.black.withValues(alpha: 0.2),
          blurRadius: 8,
          offset: const Offset(0, 2),
        ),
      ],
    );
  }

  // ── Direction helpers ──────────────────────────────────────────────────────

  /// Returns the correct directional icon by parsing the instruction text.
  /// This avoids always showing turn_right regardless of actual direction.
  IconData _getDirectionIcon(WaypointType type, String instruction) {
    switch (type) {
      case WaypointType.start:
        return Icons.play_arrow_rounded;
      case WaypointType.end:
        return Icons.flag_rounded;
      case WaypointType.marinaEntry:
        return Icons.directions_boat_rounded;
      case WaypointType.marinaExit:
        return Icons.directions_car_rounded;
      default:
        final lower = instruction.toLowerCase();
        if (lower.contains('slight left')) return Icons.turn_slight_left;
        if (lower.contains('slight right')) return Icons.turn_slight_right;
        if (lower.contains('sharp left')) return Icons.turn_sharp_left;
        if (lower.contains('sharp right')) return Icons.turn_sharp_right;
        if (lower.contains('turn left') ||
            lower.contains('keep left') ||
            lower.contains('bear left')) {
          return Icons.turn_left;
        }
        if (lower.contains('turn right') ||
            lower.contains('keep right') ||
            lower.contains('bear right')) {
          return Icons.turn_right;
        }
        if (lower.contains('u-turn') || lower.contains('uturn')) {
          return Icons.u_turn_left;
        }
        if (lower.contains('straight') || lower.contains('continue')) {
          return Icons.straight;
        }
        return Icons.navigation_rounded;
    }
  }

  String _directionInstruction(Waypoint waypoint, LatLng? fromLocation) {
    switch (waypoint.type) {
      case WaypointType.marinaEntry:
        return waypoint.instruction ?? 'Head to the marina';
      case WaypointType.marinaExit:
        return waypoint.instruction ?? 'Dock at the marina';
      case WaypointType.end:
        if (fromLocation != null) {
          final compass = _bearingToCompass(
              _computeBearing(fromLocation, waypoint.location));
          return 'Head $compass toward destination';
        }
        return 'Head toward destination';
      default:
        final raw = waypoint.instruction;
        if (raw != null &&
            raw != 'Start navigation' &&
            raw != 'Arrived at destination' &&
            raw != 'Continue') {
          return raw;
        }
        if (fromLocation != null) {
          final compass = _bearingToCompass(
              _computeBearing(fromLocation, waypoint.location));
          return 'Head $compass';
        }
        return 'Continue straight';
    }
  }


  // ── Geometry helpers ───────────────────────────────────────────────────────

  double _computeBearing(LatLng from, LatLng to) {
    final lat1 = from.latitude * math.pi / 180;
    final lat2 = to.latitude * math.pi / 180;
    final dLon = (to.longitude - from.longitude) * math.pi / 180;
    final y = math.sin(dLon) * math.cos(lat2);
    final x = math.cos(lat1) * math.sin(lat2) -
        math.sin(lat1) * math.cos(lat2) * math.cos(dLon);
    return (math.atan2(y, x) * 180 / math.pi + 360) % 360;
  }

  String _bearingToCompass(double bearing) {
    const dirs = [
      'North', 'North-East', 'East', 'South-East',
      'South', 'South-West', 'West', 'North-West'
    ];
    return dirs[((bearing + 22.5) / 45).floor() % 8];
  }

  double _calculateDistanceToPoint(LatLng from, LatLng to) {
    const r = 6371000.0;
    final lat1 = from.latitude * math.pi / 180;
    final lat2 = to.latitude * math.pi / 180;
    final dLat = (to.latitude - from.latitude) * math.pi / 180;
    final dLon = (to.longitude - from.longitude) * math.pi / 180;
    final a = math.sin(dLat / 2) * math.sin(dLat / 2) +
        math.cos(lat1) *
            math.cos(lat2) *
            math.sin(dLon / 2) *
            math.sin(dLon / 2);
    return r * 2 * math.atan2(math.sqrt(a), math.sqrt(1 - a));
  }

  double _calculateDistanceToWaypoint(Waypoint waypoint) {
    final loc = session.currentLocation;
    if (loc == null) {
      return (waypoint.distanceFromStart - session.metrics.distanceTraveled)
          .clamp(0, double.infinity);
    }
    const r = 6371000.0;
    final lat1 = loc.latitude * math.pi / 180;
    final lat2 = waypoint.location.latitude * math.pi / 180;
    final dLat =
        (waypoint.location.latitude - loc.latitude) * math.pi / 180;
    final dLon =
        (waypoint.location.longitude - loc.longitude) * math.pi / 180;
    final a = math.sin(dLat / 2) * math.sin(dLat / 2) +
        math.cos(lat1) *
            math.cos(lat2) *
            math.sin(dLon / 2) *
            math.sin(dLon / 2);
    return r * 2 * math.atan2(math.sqrt(a), math.sqrt(1 - a));
  }

  Color _getSegmentColor(RouteSegmentType type) {
    switch (type) {
      case RouteSegmentType.land:
        return AppColors.primary;
      case RouteSegmentType.marine:
        return AppColors.accent;
      case RouteSegmentType.transition:
        return Colors.orange;
    }
  }

  String _formatDistance(double meters) {
    if (meters < 1000) {
      return '${meters.round()} m';
    } else {
      return '${(meters / 1000).toStringAsFixed(1)} km';
    }
  }

  String _formatDuration(int seconds) {
    if (seconds < 60) {
      return '$seconds sec';
    } else if (seconds < 3600) {
      final minutes = (seconds / 60).round();
      return '$minutes min';
    } else {
      final hours = seconds ~/ 3600;
      final minutes = (seconds % 3600) ~/ 60;
      return '${hours}h ${minutes}m';
    }
  }
}

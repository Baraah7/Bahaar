import 'package:flutter/material.dart';
import 'package:bahaar/core/constants/app_colors.dart';
import 'package:bahaar/models/navigation/navigation_session_model.dart';
import 'package:bahaar/models/navigation/waypoint_model.dart';
import 'package:bahaar/utilities/map/navigation_constants.dart';

/// Active navigation overlay showing turn-by-turn instructions and progress
///
/// Features:
/// - Top instruction card with next waypoint
/// - Bottom progress card with metrics
/// - Recalculating indicator
/// - End navigation button
class ActiveNavigationOverlay extends StatelessWidget {
  final NavigationSession session;
  final VoidCallback? onEndNavigation;
  final VoidCallback? onRecenter;
  final bool isRecalculating;

  const ActiveNavigationOverlay({
    super.key,
    required this.session,
    this.onEndNavigation,
    this.onRecenter,
    this.isRecalculating = false,
  });

  @override
  Widget build(BuildContext context) {
    final isArriving = session.nextWaypoint == null;

    return Stack(
      children: [
        // Arrival banner — full-width at very top, only at final destination
        if (isArriving)
          Positioned(
            top: 0,
            left: 0,
            right: 0,
            child: SafeArea(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(16, 8, 16, 0),
                child: _buildArrivalCard(context),
              ),
            ),
          ),

        // Instruction card — shown only while en-route
        if (!isArriving)
          Positioned(
            top: 16,
            left: 16,
            right: 16,
            child: SafeArea(child: _buildInstructionCard(context)),
          ),

        // Compact metrics strip — fits between SOS (left) and zoom controls (right)
        Positioned(
          bottom: 24,
          left: 80,
          right: 80,
          child: _buildProgressCard(context),
        ),

        // Recalculating overlay
        if (isRecalculating)
          Positioned(
            top: 130,
            left: 0,
            right: 0,
            child: Center(
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
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
                        valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
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
      ],
    );
  }

  /// Instruction card — shown while navigating toward the next waypoint
  Widget _buildInstructionCard(BuildContext context) {
    final nextWaypoint = session.nextWaypoint!;
    final distanceToWaypoint = _calculateDistanceToWaypoint(nextWaypoint);
    final icon = _getWaypointIcon(nextWaypoint.type);
    final color = _getSegmentColor(nextWaypoint.segmentType);

    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.2),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Row(
        children: [
          Container(
            width: 52,
            height: 52,
            decoration: BoxDecoration(
              color: color.withValues(alpha: 0.15),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(icon, color: color, size: 30),
          ),
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
                  nextWaypoint.instruction ?? _defaultInstruction(nextWaypoint.type),
                  style: const TextStyle(fontSize: 13, color: Colors.black87),
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

  /// Arrival banner — shown at top only when reaching the final destination
  Widget _buildArrivalCard(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      decoration: BoxDecoration(
        color: const Color(0xFF1B5E20),
        borderRadius: BorderRadius.circular(14),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.25),
            blurRadius: 10,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.2),
              shape: BoxShape.circle,
            ),
            child: const Icon(Icons.flag_rounded, color: Colors.white, size: 28),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'You have arrived',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  'You have reached your destination',
                  style: TextStyle(
                    fontSize: 13,
                    color: Colors.white.withValues(alpha: 0.85),
                  ),
                ),
              ],
            ),
          ),
          if (onEndNavigation != null)
            TextButton(
              onPressed: onEndNavigation,
              style: TextButton.styleFrom(
                foregroundColor: Colors.white,
                backgroundColor: Colors.white.withValues(alpha: 0.15),
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8)),
                padding:
                    const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              ),
              child: const Text('Done',
                  style: TextStyle(fontWeight: FontWeight.bold)),
            ),
        ],
      ),
    );
  }

  /// Compact metrics strip that fits between SOS and zoom controls
  Widget _buildProgressCard(BuildContext context) {
    final distanceRemaining = session.distanceRemaining;
    final timeRemaining = session.timeRemaining;
    final currentSpeed = session.currentSpeed ?? 0;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(24),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.18),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
        children: [
          _buildCompactMetric(
              _formatDistance(distanceRemaining), AppColors.primary),
          _buildDivider(),
          _buildCompactMetric(_formatDuration(timeRemaining), Colors.orange),
          _buildDivider(),
          _buildCompactMetric(
              NavigationConstants.formatSpeed(currentSpeed), AppColors.accent),
        ],
      ),
    );
  }

  Widget _buildCompactMetric(String value, Color color) {
    return Text(
      value,
      style: TextStyle(
        fontSize: 13,
        fontWeight: FontWeight.bold,
        color: color,
      ),
    );
  }

  Widget _buildDivider() {
    return Container(
      width: 1,
      height: 16,
      color: Colors.grey.shade300,
    );
  }

  String _defaultInstruction(WaypointType type) {
    switch (type) {
      case WaypointType.marinaEntry:
        return 'Head to the marina';
      case WaypointType.marinaExit:
        return 'Leave the marina';
      case WaypointType.end:
        return 'Arriving at destination';
      default:
        return 'Continue straight';
    }
  }

  // ============================================================
  // Helper Methods
  // ============================================================

  double _calculateDistanceToWaypoint(Waypoint waypoint) {
    if (session.currentLocation == null) {
      return waypoint.distanceFromStart - session.metrics.distanceTraveled;
    }
    // Approximate - actual distance would need haversine calculation
    return (waypoint.distanceFromStart - session.metrics.distanceTraveled).clamp(0, double.infinity);
  }

  IconData _getWaypointIcon(WaypointType type) {
    switch (type) {
      case WaypointType.start:
        return Icons.play_arrow;
      case WaypointType.end:
        return Icons.flag;
      case WaypointType.turn:
        return Icons.turn_right;
      case WaypointType.marinaEntry:
        return Icons.directions_boat;
      case WaypointType.marinaExit:
        return Icons.directions_car;
      case WaypointType.intermediate:
        return Icons.navigation;
    }
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

import 'package:bahaar/constants/app_colors.dart';
import 'package:bahaar/services/map/navigation_mask.dart';
import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import 'package:location/location.dart';

/// Full-screen map picker. Returns the tapped [LatLng] via [Navigator.pop],
/// or null if the user cancels.
class LocationPickerScreen extends StatefulWidget {
  final LatLng? initialPosition;

  const LocationPickerScreen({super.key, this.initialPosition});

  /// Push this screen and await the result.
  static Future<LatLng?> open(
    BuildContext context, {
    LatLng? initial,
  }) {
    return Navigator.of(context).push<LatLng?>(
      MaterialPageRoute(
        builder: (_) => LocationPickerScreen(initialPosition: initial),
      ),
    );
  }

  @override
  State<LocationPickerScreen> createState() => _LocationPickerScreenState();
}

class _LocationPickerScreenState extends State<LocationPickerScreen> {
  static const _defaultCenter = LatLng(26.2154, 50.5832); // Gulf default

  final NavigationMask _mask = NavigationMask();
  final MapController _mapController = MapController();

  bool _maskReady = false;
  LatLng? _myLocation;
  LatLng? _pinned;

  @override
  void initState() {
    super.initState();
    _initMask();
    _fetchMyLocation();
  }

  Future<void> _initMask() async {
    try {
      await _mask.initialize();
      if (mounted) setState(() => _maskReady = true);
    } catch (_) {
      if (mounted) setState(() => _maskReady = true);
    }
  }

  Future<void> _fetchMyLocation() async {
    try {
      final loc = Location();
      final data = await loc.getLocation();
      if (data.latitude != null && data.longitude != null && mounted) {
        final pos = LatLng(data.latitude!, data.longitude!);
        setState(() => _myLocation = pos);
        // Only center on GPS if no initial position was provided
        if (widget.initialPosition == null) {
          _mapController.move(pos, 13);
        }
      }
    } catch (_) {}
  }

  void _centerOnMe() {
    if (_myLocation != null) {
      _mapController.move(_myLocation!, 14);
    }
  }

  void _onTap(LatLng point) {
    if (!_maskReady) return;

    if (_mask.isInitialized && !_mask.isPointNavigable(point)) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Catches must be on water — tap a water location.'),
          duration: Duration(seconds: 2),
          backgroundColor: Color(0xFF0D2E31),
        ),
      );
      return;
    }

    setState(() => _pinned = point);
  }

  @override
  Widget build(BuildContext context) {
    final center = widget.initialPosition ?? _defaultCenter;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Pick Catch Location'),
        backgroundColor: AppColors.primary,
        foregroundColor: Colors.white,
        leading: BackButton(
          onPressed: () => Navigator.of(context).pop(null),
        ),
      ),
      body: Stack(
        children: [
          FlutterMap(
            mapController: _mapController,
            options: MapOptions(
              initialCenter: center,
              initialZoom: 13,
              onTap: (_, point) => _onTap(point),
            ),
            children: [
              TileLayer(
                urlTemplate:
                    'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
                userAgentPackageName: 'com.bahaar.app',
              ),
              // Current location blue dot
              if (_myLocation != null)
                MarkerLayer(
                  markers: [
                    Marker(
                      point: _myLocation!,
                      width: 20,
                      height: 20,
                      child: Container(
                        decoration: BoxDecoration(
                          color: Colors.blue,
                          shape: BoxShape.circle,
                          border: Border.all(color: Colors.white, width: 2.5),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.blue.withValues(alpha: 0.4),
                              blurRadius: 8,
                              spreadRadius: 2,
                            ),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
              // Pinned catch location
              if (_pinned != null)
                MarkerLayer(
                  markers: [
                    Marker(
                      point: _pinned!,
                      width: 40,
                      height: 40,
                      child: const Icon(
                        Icons.location_pin,
                        color: Colors.redAccent,
                        size: 40,
                      ),
                    ),
                  ],
                ),
            ],
          ),

          // Mask loading overlay
          if (!_maskReady)
            const Center(
              child: CircularProgressIndicator(color: Colors.teal),
            ),

          // My location FAB
          Positioned(
            right: 16,
            bottom: 110,
            child: FloatingActionButton.small(
              onPressed: _myLocation != null ? _centerOnMe : null,
              backgroundColor: _myLocation != null
                  ? Colors.white
                  : Colors.white38,
              child: Icon(
                Icons.my_location,
                color: _myLocation != null
                    ? const Color(0xFF0D4F54)
                    : Colors.white54,
              ),
            ),
          ),

          // Bottom action bar
          Positioned(
            left: 0,
            right: 0,
            bottom: 0,
            child: Container(
              padding: const EdgeInsets.fromLTRB(20, 14, 20, 28),
              decoration: const BoxDecoration(
                color: Color(0xFF0D2E31),
                borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
              ),
              child: Row(
                children: [
                  Expanded(
                    child: Text(
                      _pinned == null
                          ? 'Tap on the water to set catch location'
                          : '${_pinned!.latitude.toStringAsFixed(5)}, '
                              '${_pinned!.longitude.toStringAsFixed(5)}',
                      style: TextStyle(
                        color: _pinned == null ? Colors.white54 : Colors.white,
                        fontSize: 13,
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  ElevatedButton(
                    onPressed: _pinned == null
                        ? null
                        : () => Navigator.of(context).pop(_pinned),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF0E7490),
                      disabledBackgroundColor: Colors.white12,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(
                          horizontal: 24, vertical: 12),
                      shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(10)),
                    ),
                    child: const Text('Confirm'),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

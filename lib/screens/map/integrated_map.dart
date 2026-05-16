import 'dart:async';
import 'dart:convert';
import 'dart:developer';
import 'dart:math' as math;
import 'package:bahaar/core/constants/app_colors.dart';
import 'package:bahaar/l10n/map/map_localizations.dart';
import 'package:bahaar/models/navigation/marina_model.dart';
import 'package:bahaar/models/navigation/navigation_session_model.dart';
import 'package:bahaar/models/navigation/route_model.dart';
import 'package:bahaar/models/navigation/waypoint_model.dart';
import 'package:bahaar/models/weather/marine_weather_model.dart';
import 'package:bahaar/navigation/celestial_fix_notifier.dart';
import 'package:bahaar/screens/celestial%20navigation/celestial_navigation_screen.dart';
import 'package:bahaar/screens/fish%20recognition/prediction_screen.dart';
import 'package:bahaar/services/fishRecognition/fish_probability_service.dart';
import 'package:bahaar/services/fishing%20log/trip_service.dart';
import 'package:bahaar/services/map/exclusion_zone_service.dart';
import 'package:bahaar/services/map/hybrid_route_coordinator.dart';
import 'package:bahaar/services/map/map_layer_manager.dart';
import 'package:bahaar/services/map/marina_data_service.dart';
import 'package:bahaar/services/map/marine_pathfinding_service.dart';
import 'package:bahaar/services/map/navigation_mask.dart';
import 'package:bahaar/services/map/navigation_session_manager.dart';
import 'package:bahaar/services/map/osrm_routing_service.dart';
import 'package:bahaar/services/map/outline_edit_service.dart';
import 'package:bahaar/services/marine_weather_service.dart';
import 'package:bahaar/services/offline/connectivity_service.dart';
import 'package:bahaar/utilities/cn/geometry_utils.dart';
import 'package:bahaar/utilities/map/map_constants.dart';
import 'package:bahaar/screens/fishing%20log/trip_detail_screen.dart';
import 'package:bahaar/widgets/map/bahaar_overlay_layer.dart';
import 'package:bahaar/widgets/map/celestial_fix_overlay.dart';
import 'package:bahaar/widgets/map/trip_track_layer.dart';
import 'package:bahaar/widgets/map/depth_soundings_layer.dart';
import 'package:bahaar/widgets/map/enhanced_depth_layer.dart';
import 'package:bahaar/widgets/map/exclusion_zone_layer.dart';
import 'package:bahaar/widgets/map/fish_probability_layer.dart';
import 'package:bahaar/widgets/map/geojson_layers.dart';
import 'package:bahaar/widgets/map/layer_control_panel.dart';
import 'package:bahaar/widgets/map/sos_button.dart';
import 'package:bahaar/widgets/map/territorial_mask_layer.dart';
import 'package:bahaar/widgets/map/territorial_outline_editor.dart';
import 'package:bahaar/models/map/nav_mode.dart';
import 'package:bahaar/models/map/port_point.dart';
import 'package:bahaar/widgets/map/map_left_toolbar.dart';
import 'package:bahaar/widgets/map/nav_instructions_panel.dart';
import 'package:bahaar/widgets/map/nav_mode_option.dart';
import 'package:bahaar/widgets/map/navigation_status_indicator.dart';
import 'package:bahaar/widgets/map/offline_banner.dart';
import 'package:bahaar/widgets/map/route_calculating_overlay.dart';
import 'package:bahaar/widgets/map/zoom_controls.dart';
import 'package:bahaar/widgets/navigation/active_navigation_overlay.dart';
import 'package:bahaar/widgets/navigation/marina_marker_layer.dart';
import 'package:bahaar/widgets/navigation/route_polyline_layer.dart';
import 'package:bahaar/widgets/navigation/weather_alert_overlay.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:latlong2/latlong.dart';
import 'package:location/location.dart';
import 'package:flutter_map/flutter_map.dart';

/// Integrated map with clean architecture and enhanced depth visualization
///
/// Features:
/// - Multi-layer depth visualization (bathymetric colors, nautical charts, combined)
/// - GeoJSON overlays (fishing zones, shipping lanes, protected areas)
/// - Navigation mask validation
/// - Organized layer management
/// - Clean separation of concerns
class IntegratedMap extends StatefulWidget {
  const IntegratedMap({super.key});

  @override
  State<IntegratedMap> createState() => _IntegratedMapState();
}

class _IntegratedMapState extends State<IntegratedMap>
    with AutomaticKeepAliveClientMixin<IntegratedMap> {
  @override
  bool get wantKeepAlive => true;
  // Controllers and services
  final MapController _mapController = MapController();
  final Location _location = Location();
  final NavigationMask _navigationMask = NavigationMask();
  final MarinaDataService _marinaService = MarinaDataService();
  late final MapLayerManager _layerManager;

  // Routing services
  late final OsrmRoutingService _osrmService;
  late final MarinePathfindingService _marineService;
  late final HybridRouteCoordinator _routeCoordinator;
  late final MarineWeatherService _weatherService;
  late final FishProbabilityService _fishProbabilityService;
 // final FeatureEditService _featureEditService = FeatureEditService();
 // final FeatureEditState _featureEditState = FeatureEditState();
  NavigationSessionManager? _navigationManager;

  // Feature edit state
 // List<EditableMapFeature> _firestoreMapFeatures = [];
  Map<String, dynamic>? _rawAssetGeoJson;

  // Weather state
  List<WeatherSafetyAssessment> _activeWeatherWarnings = [];
  bool _weatherAlertDismissed = false;

  // Exclusion zone state
  final ExclusionZoneService _exclusionZoneService = ExclusionZoneService();
  ExclusionZoneViolation? _activeExclusionViolation;
  ExclusionZone? _approachingExclusionZone;
  double _approachingExclusionZoneDistance = 0;
  bool _exclusionAlertDismissed = false;

  // Outline edit state
  final OutlineEditService _outlineEditService = OutlineEditService();
  bool _isOutlineEditMode = false;
  OutlineBrushMode _outlineBrushMode = OutlineBrushMode.erase;
  double _outlineBrushRadius = 0.003; // ~333 m
  LatLng? _outlinePaintPreview;

  // State
  bool _mapReady = false;
  bool _serviceEnabled = false;
  PermissionStatus _permissionStatus = PermissionStatus.denied;
  LocationData? _locationData;
  StreamSubscription<LocationData>? _locationSubscription;
  bool _maskInitialized = false;
  bool _showDepthLegend = false;
  double _currentZoom = MapConstants.defaultZoom;

  // Outside-mask warning — shown when the user's location or a tapped point
  // falls outside the territorial water boundary.
  String? _outsideMaskWarning;
  bool _outsideMaskWarningDismissed = false;

  // Admin edit state - track painted cells with their brush type for visualization
  final Map<({int row, int col}), AdminBrushType> _paintedCells = {};

  // GeoJSON data
  GeoJsonLayerBuilder? _geoJsonBuilder;

  // Marina data
  Marina? _selectedMarina;
  final bool _showMarinas = true;

  // Navigation state
  NavigationRoute? _currentRoute;
  LatLng? _originPoint;
  LatLng? _destinationPoint;
  bool _isCalculatingRoute = false;
  bool _isFollowingNavigation = false;
  NavigationState? _lastNavState;

  // Ports loaded from seaports.json
  List<PortPoint> _availablePorts = [];

  // Selected port and destination
  PortPoint? _selectedPort;
  LatLng? _seaDestination;
  bool _showPortSelection = false;

  // Navigation mode
  NavMode? _navMode;

  // Sea-to-sea state
  LatLng? _seaOrigin; // first tap in sea→sea mode

  // Sea-to-land state
  LatLng? _seaToLandOrigin; // sea departure point for return trip
  LatLng? _customLandDestination; // land destination for return trip
  PortPoint? _returnPort; // port used for the outbound trip (saved)

  // Custom land origin (replaces GPS for land→port→sea)
  LatLng? _customLandOrigin;

  @override
  void initState() {
    super.initState();
    _layerManager = MapLayerManager();
    _fishProbabilityService = FishProbabilityService();
    _fishProbabilityService.initialize().then((_) {
      if (mounted) setState(() {});
    });
    _initLocation();
    _initNavigationMask();
    _loadGeoJson();
    _loadSeaports();
    _initMarinas();
    _initRoutingServices();
   // _loadFirestoreFeatures();
   // _featureEditState.addListener(_onFeatureEditUpdate);

    final tripUid = FirebaseAuth.instance.currentUser?.uid;
    TripService.instance.initialize(uid: tripUid).then((_) {
      TripService.instance.syncPendingToFirestore();
    });

    // Sync pending offline data when connectivity is restored
    ConnectivityService.instance.onConnectivityChanged.listen((online) {
      if (online) TripService.instance.syncPendingToFirestore();
    });
  }

  Future<void> _initRoutingServices() async {
    try {
      // Wait for dependencies to initialize
      while (!_maskInitialized || !_marinaService.isInitialized || _geoJsonBuilder == null) {
        await Future.delayed(const Duration(milliseconds: 100));
      }

      // Initialize weather service
      _weatherService = MarineWeatherService();
      await _weatherService.initialize();
      log('Weather service initialized');

      // Update weather warnings
      _updateWeatherWarnings();

      _osrmService = OsrmRoutingService();
      _marineService = MarinePathfindingService(
        _navigationMask,
        weatherService: _weatherService,
      );
      _routeCoordinator = HybridRouteCoordinator(
        osrmService: _osrmService,
        marineService: _marineService,
        marinaService: _marinaService,
        navigationMask: _navigationMask,
        geoJsonBuilder: _geoJsonBuilder!,
        weatherService: _weatherService,
      );
      // Exclusion zones are always hard-blocked during routing
      _routeCoordinator.extraRestrictedAreas =
          _exclusionZoneService.buildExclusionPolygons();

      // Initialize navigation session manager
      _navigationManager = NavigationSessionManager(
        location: _location,
        routeCoordinator: _routeCoordinator,
        weatherService: _weatherService,
      );

      // Listen to navigation state changes
      _navigationManager!.addListener(_onNavigationUpdate);

      log('Routing services initialized successfully');
    } catch (e) {
      log('Error initializing routing services: $e');
    }
  }

  void _onNavigationUpdate() {
    if (!mounted) return;
    final session = _navigationManager?.session;
    final navLocation = session?.currentLocation;
    final newState = session?.state;

    // Detect arrival: transition into completed fires the dialog exactly once.
    if (newState == NavigationState.completed &&
        _lastNavState != NavigationState.completed) {
      _lastNavState = newState;
      WidgetsBinding.instance
          .addPostFrameCallback((_) => _showArrivalDialog());
      return;
    }
    _lastNavState = newState;

    setState(() {
      if (navLocation != null) {
        // Mirror live position into _locationData so the marker and other
        // consumers (AIS CPA, exclusion zones) stay in sync.
        _locationData = LocationData.fromMap({
          'latitude': navLocation.latitude,
          'longitude': navLocation.longitude,
          'accuracy': _locationData?.accuracy,
          'altitude': _locationData?.altitude,
          'speed': session?.currentSpeed,
          'speed_accuracy': null,
          'heading': session?.currentBearing,
          'time': DateTime.now().millisecondsSinceEpoch.toDouble(),
          'isMock': false,
          'verticalAccuracy': null,
          'headingAccuracy': null,
          'elapsedRealtimeNanos': null,
          'elapsedRealtimeUncertaintyNanos': null,
          'satelliteNumber': null,
          'provider': null,
        });
      }

      // Keep the polyline layer in sync when the session recalculates a new
      // route after an off-route event.
      if (session != null && _currentRoute != null &&
          session.route.id != _currentRoute!.id) {
        _currentRoute = session.route;
      }
    });

    // Auto-follow: keep the map centered on the user while follow mode is on.
    if (_isFollowingNavigation && navLocation != null && _mapReady) {
      _mapController.move(navLocation, _mapController.camera.zoom);
    }
  }

  void _showArrivalDialog() {
    if (!mounted) return;
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (ctx) => Dialog(
        shape:
            RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
        child: Padding(
          padding: const EdgeInsets.fromLTRB(24, 32, 24, 24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 80,
                height: 80,
                decoration: BoxDecoration(
                  color: Colors.green.shade50,
                  shape: BoxShape.circle,
                ),
                child: Icon(Icons.flag_rounded,
                    size: 44, color: Colors.green.shade700),
              ),
              const SizedBox(height: 20),
              const Text(
                'You have reached\nyour destination!',
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                  height: 1.3,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                'You have successfully arrived.',
                textAlign: TextAlign.center,
                style: TextStyle(fontSize: 14, color: Colors.grey.shade600),
              ),
              const SizedBox(height: 28),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton.icon(
                  onPressed: () {
                    Navigator.pop(ctx);
                    _endNavigation();
                  },
                  icon: const Icon(Icons.close_rounded, size: 18),
                  label: const Text('End Trip',
                      style: TextStyle(
                          fontWeight: FontWeight.bold, fontSize: 15)),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.primary,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(14)),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _onFeatureEditUpdate() {
    if (mounted) {
      setState(() {});
    }
  }

  // Future<void> _loadFirestoreFeatures() async {
  //   try {
  //     final features = await _featureEditService.loadMapFeatures();
  //     if (mounted) {
  //       setState(() {
  //         _firestoreMapFeatures = features;
  //       });
  //       _rebuildGeoJsonWithFirestore();
  //     }
  //   } catch (e) {
  //     log('Error loading Firestore features: $e');
  //   }
  // }

  // void _rebuildGeoJsonWithFirestore() {
  //   if (_rawAssetGeoJson != null) {
  //     setState(() {
  //       _geoJsonBuilder = GeoJsonLayerBuilder.withFirestoreFeatures(
  //         _rawAssetGeoJson!,
  //         _firestoreMapFeatures,
  //       );
  //     });
  //   }
  // }

  @override
  void dispose() {
    _locationSubscription?.cancel();
    _navigationManager?.removeListener(_onNavigationUpdate);
    _navigationManager?.dispose();
   // _featureEditState.removeListener(_onFeatureEditUpdate);
   // _featureEditState.dispose();
    _fishProbabilityService.dispose();
    _layerManager.dispose();
    super.dispose();
  }

  // ============================================================
  // Initialization Methods
  // ============================================================

  Future<void> _initNavigationMask() async {
    try {
      await _navigationMask.initialize();
      if (mounted) {
        setState(() => _maskInitialized = true);
        log('Navigation mask initialized successfully');
        // Drop any exclusion zones that ended up on land.
        // Use a 5-cell neighbourhood search so a zone whose exact centre
        // rounds to a land cell (grid rounding) is still kept if water
        // exists nearby.
        await _exclusionZoneService.initialize();
        _exclusionZoneService.filterByWater(
          (p) => _navigationMask.findNearestWaterPoint(p, maxSearchRadius: 5) != null,
        );
      }
    } catch (e) {
      log('Error initializing navigation mask: $e');
    }
  }

  Future<void> _initMarinas() async {
    try {
      // Wait for navigation mask to initialize first
      while (!_maskInitialized) {
        await Future.delayed(const Duration(milliseconds: 100));
      }

      await _marinaService.initialize(_navigationMask);
      if (mounted) {
        setState(() {});
        log('Marina service initialized: ${_marinaService.marinaCount} marinas loaded');
      }
    } catch (e) {
      log('Error initializing marina service: $e');
    }
  }

  Future<void> _initLocation() async {
    try {
      _serviceEnabled = await _location.serviceEnabled();
      if (!_serviceEnabled) {
        _serviceEnabled = await _location.requestService();
        if (!_serviceEnabled) {
          log('User denied location service');
          if (mounted) setState(() {});
          return;
        }
      }

      _permissionStatus = await _location.hasPermission();
      if (_permissionStatus == PermissionStatus.denied) {
        _permissionStatus = await _location.requestPermission();
        if (_permissionStatus != PermissionStatus.granted) {
          log('User denied location permission');
          if (mounted) setState(() {});
          return;
        }
      }

      _locationData = await _location.getLocation();
      log('Location fetched: ${_locationData.toString()}');
      if (mounted) {
        setState(() {});
        _moveToLocationIfReady();
        if (_locationData?.latitude != null && _locationData?.longitude != null) {
          _checkExclusionZones(LatLng(
            _locationData!.latitude!,
            _locationData!.longitude!,
          ));
        }
      }

      // Continuously update position so the user marker stays live
      _locationSubscription = _location.onLocationChanged.listen((data) {
        if (!mounted) return;
        setState(() => _locationData = data);
        if (data.latitude != null && data.longitude != null) {
          _checkExclusionZones(LatLng(data.latitude!, data.longitude!));
        }
      });
    } catch (e) {
      log('Error getting location: $e');
      if (mounted) setState(() {});
    }
  }

  Future<void> _loadSeaports() async {
    try {
      final String jsonString = await rootBundle.loadString(
        'assets/data/seaports.json',
      );
      final List<dynamic> data = json.decode(jsonString) as List<dynamic>;
      if (mounted) {
        setState(() {
          _availablePorts = data.asMap().entries.map((entry) {
            final port = entry.value as Map<String, dynamic>;
            final name = port['name'] as String;
            return PortPoint(
              id: 'port_${entry.key}',
              name: _toTitleCase(name),
              location: LatLng(
                port['y_latitude'] as double,
                port['x_longitude'] as double,
              ),
              description: port['l_sm'] as String? ?? '',
            );
          }).toList();
        });
        log('Seaports loaded: ${_availablePorts.length} ports');
      }
    } catch (e) {
      log('Error loading seaports: $e');
    }
  }

  String _toTitleCase(String text) {
    return text
        .toLowerCase()
        .split(' ')
        .map((word) => word.isEmpty ? '' : '${word[0].toUpperCase()}${word.substring(1)}')
        .join(' ');
  }

  Future<void> _loadGeoJson() async {
    try {
      final String jsonString = await rootBundle.loadString(
        'assets/data/gulf_test_features.geojson'
      );
      final data = json.decode(jsonString) as Map<String, dynamic>;
      _rawAssetGeoJson = data;
      // setState(() {

      //   if (_firestoreMapFeatures.isNotEmpty) {
      //     _geoJsonBuilder = GeoJsonLayerBuilder.withFirestoreFeatures(
      //       data,
      //       _firestoreMapFeatures,
      //     );
          
      //   } else {
      //     _geoJsonBuilder = GeoJsonLayerBuilder(data);
      //   }
      // });
      log('GeoJSON loaded successfully');
    } catch (e) {
      log('Error loading GeoJSON: $e');
    }
  }

  // ============================================================
  // Map Interaction Methods
  // ============================================================

  void _moveToLocationIfReady() {
    if (_mapReady && _locationData != null) {
      final targetLocation = LatLng(
        _locationData!.latitude ?? MapConstants.defaultLatitude,
        _locationData!.longitude ?? MapConstants.defaultLongitude,
      );

      if (_maskInitialized) {
        final isNavigable = _navigationMask.isPointNavigable(targetLocation);
        log('Location validated: ${isNavigable ? "on navigable water" : "on land / outside bounds"}');
      }

      _mapController.move(targetLocation, 12);
    }
  }

  void _onMapReady() {
    setState(() => _mapReady = true);
    _moveToLocationIfReady();
  }

  void _handleMapTap(TapPosition tapPosition, LatLng point) {
    if (!_maskInitialized) return;
    final l10n = MapLocalizations.of(context);

    // Handle feature edit mode
    // if (_layerManager.isFeatureEditMode) {
    //   _handleFeatureEditTap(point);
    //   return;
    // }

    // // Handle admin edit mode
    // if (_layerManager.isAdminEditMode) {
    //   _handleAdminPaint(point);
    //   return;
    // }

    // If there's already a route, tapping doesn't do anything
    if (_currentRoute != null) return;

    final isNavigable = _navigationMask.isPointNavigable(point);

    final isOutsideBounds = point.longitude < _navigationMask.minLon ||
        point.longitude > _navigationMask.maxLon ||
        point.latitude < _navigationMask.minLat ||
        point.latitude > _navigationMask.maxLat;

    log('Tapped (${point.latitude.toStringAsFixed(4)}, ${point.longitude.toStringAsFixed(4)}): '
        '${isNavigable ? "navigable water" : isOutsideBounds ? "outside territorial bounds" : "land"}');

    // ── Sea→Sea mode ─────────────────────────────────────────────────────────
    if (_navMode == NavMode.seaToSea) {
      if (!isNavigable) {
        final msg = isOutsideBounds
            ? l10n.outsideTerritorialWaters
            : l10n.tapOnSea;
        setState(() {
          _outsideMaskWarning = msg;
          _outsideMaskWarningDismissed = false;
        });
        return;
      }
      if (_outsideMaskWarning != null) setState(() => _outsideMaskWarning = null);

      final violation = _exclusionZoneService.checkViolation(point);
      if (violation != null) { _showExclusionDialog(violation); return; }
      final areaName = _getProtectedAreaAt(point);
      if (areaName != null) { _showProtectedAreaDialog(areaName); return; }

      if (_seaOrigin == null) {
        setState(() => _seaOrigin = point);
        _showMessage(l10n.departureSet, Colors.blue);
      } else {
        setState(() => _seaDestination = point);
        _calculateSeaToSeaRoute();
      }
      return;
    }

    // ── Sea→Land mode ─────────────────────────────────────────────────────────
    if (_navMode == NavMode.seaToLand) {
      // Port taps (land) are handled via proximity detection
      if (_showPortSelection && !isNavigable) {
        final tapScreen = tapPosition.relative;
        if (tapScreen != null) {
          const tapRadius = 45.0;
          for (final port in _availablePorts) {
            final portScreen = _mapController.camera.getOffsetFromOrigin(port.location);
            if ((tapScreen - portScreen).distance <= tapRadius) {
              _handlePortSelected(port);
              return;
            }
          }
        }
        // Land tap outside a port: could be custom land destination
        if (_seaToLandOrigin != null && _selectedPort != null) {
          setState(() => _customLandDestination = point);
          _calculateSeaToLandRoute();
        }
        return;
      }

      if (!isNavigable) {
        // If sea origin and port are set, land tap = land destination
        if (_seaToLandOrigin != null && _selectedPort != null) {
          setState(() => _customLandDestination = point);
          _calculateSeaToLandRoute();
          return;
        }
        final msg = isOutsideBounds
            ? l10n.outsideTerritorialWaters
            : l10n.tapOnSea;
        setState(() {
          _outsideMaskWarning = msg;
          _outsideMaskWarningDismissed = false;
        });
        return;
      }
      if (_outsideMaskWarning != null) setState(() => _outsideMaskWarning = null);

      final violation = _exclusionZoneService.checkViolation(point);
      if (violation != null) { _showExclusionDialog(violation); return; }
      final areaName = _getProtectedAreaAt(point);
      if (areaName != null) { _showProtectedAreaDialog(areaName); return; }

      if (_seaToLandOrigin == null) {
        setState(() => _seaToLandOrigin = point);
        _showMessage(l10n.seaDepartureSet, Colors.blue);
      }
      return;
    }

    // ── Land→Sea mode (port selection) ───────────────────────────────────────
    // GestureDetector inside Marker.child is unreliable in flutter_map v8 —
    // detect a port tap here via screen-space proximity.
    if (_showPortSelection && !isNavigable) {
      final tapScreen = tapPosition.relative;
      if (tapScreen != null) {
        const tapRadius = 45.0;
        for (final port in _availablePorts) {
          final portScreen = _mapController.camera.getOffsetFromOrigin(port.location);
          if ((tapScreen - portScreen).distance <= tapRadius) {
            _handlePortSelected(port);
            return;
          }
        }
      }
      // Land tap: allow setting a custom land origin
      if (_navMode == NavMode.landToSea) {
        final areaName = _getProtectedAreaAt(point);
        if (areaName != null) {
          _showMessage('${l10n.startPointInProtectedArea}: $areaName', Colors.red);
          return;
        }
        setState(() => _customLandOrigin = point);
        _showMessage(l10n.customOriginSet, Colors.blue);
      }
      return;
    }

    if (!isNavigable) {
      final msg = isOutsideBounds
          ? l10n.outsideTerritorialWaters
          : l10n.tapOnSea;
      setState(() {
        _outsideMaskWarning = msg;
        _outsideMaskWarningDismissed = false;
      });
    } else {
      if (_outsideMaskWarning != null) setState(() => _outsideMaskWarning = null);
    }

    final violation = _exclusionZoneService.checkViolation(point);
    if (violation != null) { _showExclusionDialog(violation); return; }

    if (_showPortSelection) {
      final areaName = _getProtectedAreaAt(point);
      if (areaName != null) { _showProtectedAreaDialog(areaName); return; }

      if (!isNavigable) return;

      setState(() => _seaDestination = point);

      if (_selectedPort != null) {
        _calculatePortToSeaRoute();
      } else {
        _showMessage(l10n.stepTapPort, Colors.blue);
      }
      return;
    }
  }

  void _showExclusionDialog(ExclusionZoneViolation violation) {
    showDialog<void>(
      context: context,
      builder: (ctx) => AlertDialog(
        icon: const Icon(Icons.oil_barrel, color: Colors.red, size: 40),
        title: const Text('Exclusion Zone'),
        content: Text(
          'This location is inside the ${violation.zone.name} safety exclusion zone '
          '(${violation.distanceMeters.round()} m from platform).\n\n'
          'Destinations inside the 500 m UNCLOS safety buffer are not permitted.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(),
            child: const Text('Choose Another Location'),
          ),
        ],
      ),
    );
  }

  void _showProtectedAreaDialog(String areaName) {
    showDialog<void>(
      context: context,
      builder: (ctx) => AlertDialog(
        icon: const Icon(Icons.shield_outlined, color: Colors.orange, size: 40),
        title: const Text('Protected Area'),
        content: Text(
          'This location is inside "$areaName".\n\nDestinations inside protected areas are not permitted.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(),
            child: const Text('Choose Another Location'),
          ),
        ],
      ),
    );
  }

  void _handleAdminPaint(LatLng point) {
    // Water = 1, Land/Eraser = 0
    final brushType = _layerManager.brushType;
    final value = brushType == AdminBrushType.water ? 1 : 0;
    final painted = _navigationMask.paintBrush(
      point.longitude,
      point.latitude,
      _layerManager.brushRadius,
      value,
    );

    if (painted.isNotEmpty) {
      setState(() {
        // Store each cell with its brush type
        for (final cell in painted) {
          _paintedCells[cell] = brushType;
        }
      });
    }
  }

  // ============================================================
  // Feature Edit Mode Handling
  // ============================================================

  // // void _handleFeatureEditTap(LatLng point) {
  // //   switch (_featureEditState.interaction) {
  // //     case FeatureEditInteraction.addPoint:
  // //       _addPointFeature(point);
  // //       break;
  // //     case FeatureEditInteraction.addPolygon:
  // //     case FeatureEditInteraction.addPolyline:
  // //       _featureEditState.addVertex(point);
  // //       break;
  // //     case FeatureEditInteraction.select:
  // //       _hitTestFeatures(point);
  // //       break;
  // //     case FeatureEditInteraction.moveFeature:
  // //       _moveSelectedFeature(point);
  // //       break;
  // //     case FeatureEditInteraction.browse:
  // //       break;
  // //   }
  // // }

  // Future<void> _addPointFeature(LatLng point) async {
  //   final type = _featureEditState.selectedFeatureType;
  //   if (type == null) return;

  //   final feature = EditableMapFeature(
  //     featureType: type,
  //     name: '${type.displayName} ${DateTime.now().millisecondsSinceEpoch}',
  //     coordinates: [point],
  //   );

  //   // await _featureEditService.addMapFeature(feature);
  //   // _showMessage('${type.displayName} added', Colors.green);
  //   // await _loadFirestoreFeatures();
  // }

  // Future<void> _confirmAndSaveDrawing() async {
  //   final type = _featureEditState.selectedFeatureType;
  //   if (type == null) return;

  //   final vertices = _featureEditState.confirmDrawing();
  //   if (vertices.isEmpty) return;

  //   // Close polygon if needed
  //   final coords = List<LatLng>.from(vertices);
  //   if (type.geometryType == GeometryType.polygon &&
  //       coords.length >= 3 &&
  //       coords.first != coords.last) {
  //     coords.add(coords.first);
  //   }

  //   final feature = EditableMapFeature(
  //     featureType: type,
  //     name: '${type.displayName} ${DateTime.now().millisecondsSinceEpoch}',
  //     coordinates: coords,
  //   );

  //   // await _featureEditService.addMapFeature(feature);
  //   // _showMessage('${type.displayName} added', Colors.green);
  //   // await _loadFirestoreFeatures();
  // }

  // void _hitTestFeatures(LatLng point) {
  //   // Threshold in degrees (~500m at Bahrain latitude)
  //   const pointThreshold = 0.005;
  //   const lineThreshold = 0.003;

  //   EditableMapFeature? closest;
  //   double closestDist = double.infinity;

  //   for (final feature in _firestoreMapFeatures) {
  //     switch (feature.geometryType) {
  //       case GeometryType.point:
  //         final dist =
  //             GeometryUtils.distanceBetween(point, feature.coordinates.first);
  //         if (dist < pointThreshold && dist < closestDist) {
  //           closestDist = dist;
  //           closest = feature;
  //         }
  //         break;
  //       case GeometryType.lineString:
  //         final dist = GeometryUtils.distanceToLineString(
  //             point, feature.coordinates);
  //         if (dist < lineThreshold && dist < closestDist) {
  //           closestDist = dist;
  //           closest = feature;
  //         }
  //         break;
  //       case GeometryType.polygon:
  //         if (GeometryUtils.isPointInPolygon(point, feature.coordinates)) {
  //           // For polygons, use distance to centroid as tiebreaker
  //           final centroid =
  //               GeometryUtils.computeCentroid(feature.coordinates);
  //           final dist = GeometryUtils.distanceBetween(point, centroid);
  //           if (dist < closestDist) {
  //             closestDist = dist;
  //             closest = feature;
  //           }
  //         }
  //         break;
  //     }
  //   }

  //   // Also hit-test asset features from GeoJsonBuilder
  //   if (closest == null && _geoJsonBuilder != null) {
  //     final allFeatures =
  //         _geoJsonBuilder!.geoJsonData['features'] as List? ?? [];
  //     for (final f in allFeatures) {
  //       try {
  //         final editableFeature = EditableMapFeature.fromGeoJsonFeature(
  //             f as Map<String, dynamic>);
  //         switch (editableFeature.geometryType) {
  //           case GeometryType.point:
  //             final dist = GeometryUtils.distanceBetween(
  //                 point, editableFeature.coordinates.first);
  //             if (dist < pointThreshold && dist < closestDist) {
  //               closestDist = dist;
  //               closest = editableFeature;
  //             }
  //             break;
  //           case GeometryType.lineString:
  //             final dist = GeometryUtils.distanceToLineString(
  //                 point, editableFeature.coordinates);
  //             if (dist < lineThreshold && dist < closestDist) {
  //               closestDist = dist;
  //               closest = editableFeature;
  //             }
  //             break;
  //           case GeometryType.polygon:
  //             if (GeometryUtils.isPointInPolygon(
  //                 point, editableFeature.coordinates)) {
  //               final centroid =
  //                   GeometryUtils.computeCentroid(editableFeature.coordinates);
  //               final dist = GeometryUtils.distanceBetween(point, centroid);
  //               if (dist < closestDist) {
  //                 closestDist = dist;
  //                 closest = editableFeature;
  //               }
  //             }
  //             break;
  //         }
  //       } catch (_) {}
  //     }
  //   }

  //   if (closest != null) {
  //     _featureEditState.selectFeature(closest);
  //     _showMessage('Selected: ${closest.name.isNotEmpty ? closest.name : closest.featureType.displayName}', Colors.blue);
  //   } else {
  //     _featureEditState.deselectFeature();
  //   }
  // }

  // Future<void> _moveSelectedFeature(LatLng newPosition) async {
  //   final feature = _featureEditState.selectedFeature;
  //   if (feature == null) return;

  //   List<LatLng> newCoords;
  //   if (feature.geometryType == GeometryType.point) {
  //     newCoords = [newPosition];
  //   } else {
  //     final centroid = GeometryUtils.computeCentroid(feature.coordinates);
  //     newCoords = GeometryUtils.translateGeometry(
  //         feature.coordinates, centroid, newPosition);
  //   }

  //   if (feature.id != null) {
  //     // Firestore feature — update in place
  //     final updated = feature.copyWith(
  //       coordinates: newCoords,
  //       updatedAt: DateTime.now(),
  //     );
  //   //  await _featureEditService.updateMapFeature(updated);
  //   } else {
  //     // Asset feature — create a new Firestore copy at the new position
  //     final newFeature = feature.copyWith(
  //       id: null,
  //       coordinates: newCoords,
  //     );
  //     // await _featureEditService.addMapFeature(newFeature);
  //   }

  //   _featureEditState.startSelectMode();
  //   _showMessage('Feature moved', Colors.green);
  //   // await _loadFirestoreFeatures();
  // }

  // Future<void> _deleteSelectedFeature() async {
  //   final feature = _featureEditState.selectedFeature;
  //   if (feature == null) return;

  //   final confirm = await showDialog<bool>(
  //     context: context,
  //     builder: (context) => AlertDialog(
  //       title: const Text('Delete Feature'),
  //       content: Text(
  //           'Delete "${feature.name.isNotEmpty ? feature.name : feature.featureType.displayName}"?'),
  //       actions: [
  //         TextButton(
  //           onPressed: () => Navigator.pop(context, false),
  //           child: const Text('Cancel'),
  //         ),
  //         TextButton(
  //           onPressed: () => Navigator.pop(context, true),
  //           child: const Text('Delete', style: TextStyle(color: Colors.red)),
  //         ),
  //       ],
  //     ),
  //   );

  //   if (confirm == true) {
  //     if (feature.id != null) {
  //    //   await _featureEditService.deleteMapFeature(feature.id!);
  //     }
  //     _featureEditState.deselectFeature();
  //     _showMessage('Feature deleted', Colors.green);
  //    // await _loadFirestoreFeatures();
  //   }
  // }

  // void _enterFeatureEditMode() {
  //   setState(() {
  //     _layerManager.isFeatureEditMode = true;
  //     _featureEditState.enterEditMode();
  //   });
  // }

  // void _exitFeatureEditMode() {
  //   setState(() {
  //     _layerManager.isFeatureEditMode = false;
  //     _featureEditState.exitEditMode();
  //   });
  // }

  // /// Convert screen position to LatLng for drag painting
  // LatLng? _screenToLatLng(Offset screenPosition) {
  //   if (!_mapReady) return null;
  //   try {
  //     // Use flutter_map's offset to latlng conversion
  //     return _mapController.camera.offsetToCrs(screenPosition);
  //   } catch (e) {
  //     return null;
  //   }
  // }

  // void _handleMarinaTapped(Marina marina) {
  //   setState(() {
  //     _selectedMarina = marina;
  //   });
  //   log('Marina tapped: ${marina.name}');

  //   // Center map on marina
  //   _mapController.move(marina.location, 15.0);
  // }

  // ============================================================
  // Route Calculation Methods
  // ============================================================

  Future<void> _calculateRoute(LatLng destination) async {
    if (_locationData == null) {
      _showMessage('Location not available', Colors.orange);
      return;
    }

    setState(() {
      _isCalculatingRoute = true;
      _destinationPoint = destination;
      _currentRoute = null;
    });

    try {
      final origin = LatLng(
        _locationData!.latitude ?? MapConstants.defaultLatitude,
        _locationData!.longitude ?? MapConstants.defaultLongitude,
      );

      log('Calculating route from $origin to $destination');

      final route = await _routeCoordinator.calculateRoute(
        origin: origin,
        destination: destination,
      );

      if (route != null) {
        log('Route details: ${route.segments.length} segments, ${route.geometry.length} points');
        for (int i = 0; i < route.segments.length; i++) {
          final seg = route.segments[i];
          log('  Segment $i: ${seg.type.name} - ${seg.geometry.length} points, ${seg.distance}m');
        }

        setState(() {
          _currentRoute = route;
          _isCalculatingRoute = false;
        });

        _showMessage('Route calculated: ${_formatDistance(route.totalDistance)}', Colors.green);

        // Fit route bounds
        _fitRouteBounds(route);
      } else {
        setState(() {
          _isCalculatingRoute = false;
        });
        _showMessage('Could not find a route', Colors.red);
      }
    } catch (e) {
      log('Error calculating route: $e');
      setState(() {
        _isCalculatingRoute = false;
      });
      _showMessage('Error calculating route: $e', Colors.red);
    }
  }

  Future<void> _calculatePortToSeaRoute() async {
    if (_selectedPort == null || _seaDestination == null) {
      final l10n = MapLocalizations.of(context);
      _showMessage(l10n.stepTapPort, Colors.orange);
      return;
    }

    // Use custom land origin if set, otherwise fall back to GPS (only if on land)
    LatLng? gpsLocation;
    if (_locationData != null) {
      final candidate = LatLng(
        _locationData!.latitude ?? MapConstants.defaultLatitude,
        _locationData!.longitude ?? MapConstants.defaultLongitude,
      );
      // Only use GPS as land origin if it is actually on land (not navigable water)
      if (!_maskInitialized || !_navigationMask.isPointNavigable(candidate)) {
        gpsLocation = candidate;
      }
    }
    final landOrigin = _customLandOrigin ?? gpsLocation;

    if (landOrigin == null) {
      final l10n = MapLocalizations.of(context);
      _showMessage(l10n.currentLocationOnLandRequired, Colors.orange);
      return;
    }

    // Reject if the land origin is actually on water
    if (_maskInitialized && _navigationMask.isPointNavigable(landOrigin)) {
      _showMessage('Starting point must be on land, not on water.', Colors.orange);
      return;
    }

    setState(() {
      _isCalculatingRoute = true;
      _currentRoute = null;
    });

    try {
      final currentLocation = landOrigin;

      log('Calculating land-to-port-to-sea route');
      log('  Origin: $currentLocation${_customLandOrigin != null ? " (custom)" : " (GPS)"}');
      log('  Selected port: ${_selectedPort!.name} at ${_selectedPort!.location}');
      log('  Sea destination: $_seaDestination');

      // Calculate land route to port using OSRM
      final landSegment = await _osrmService.getRoute(
        origin: currentLocation,
        destination: _selectedPort!.location,
      );

      if (landSegment == null) {
        setState(() => _isCalculatingRoute = false);
        _showMessage('Could not find land route to port', Colors.red);
        return;
      }

      // Calculate marine route from port to sea destination,
      // blocking all protected zones, restricted areas, and exclusion zones.
      final marineSegment = await _marineService.findMarineRoute(
        origin: _selectedPort!.location,
        destination: _seaDestination!,
        restrictedAreas: [
          if (_geoJsonBuilder != null) ...[
            ..._geoJsonBuilder!.buildRestrictedAreas(isVisible: true),
            ..._geoJsonBuilder!.buildProtectedZones(isVisible: true),
          ],
          ..._exclusionZoneService.buildExclusionPolygons(),
        ],
      );

      if (marineSegment == null) {
        setState(() => _isCalculatingRoute = false);
        _showMessage('Could not find marine route from port', Colors.red);
        return;
      }

      // Combine routes
      final combinedGeometry = [...landSegment.geometry, ...marineSegment.geometry];
      final segments = [landSegment, marineSegment];

      final totalDistance = segments.fold<double>(
        0,
        (sum, segment) => sum + segment.distance,
      );

      final totalDuration = segments.fold<int>(
        0,
        (sum, segment) => sum + segment.duration,
      );

      final combinedRoute = NavigationRoute(
        id: 'route_${DateTime.now().millisecondsSinceEpoch}',
        origin: currentLocation,
        destination: _seaDestination!,
        geometry: combinedGeometry,
        segments: segments,
        waypoints: _buildRouteWaypoints(segments),
        totalDistance: totalDistance,
        estimatedDuration: totalDuration,
        validation: RouteValidation(
          isValid: true,
          totalPoints: combinedGeometry.length,
          waterPoints: marineSegment.geometry.length,
          landPoints: landSegment.geometry.length,
          landPointIndices: [],
        ),
        createdAt: DateTime.now(),
        metrics: RouteMetrics(
          landDistance: landSegment.distance,
          marineDistance: marineSegment.distance,
          landDuration: landSegment.duration,
          marineDuration: marineSegment.duration,
        ),
      );

      log('Route calculated successfully');
      log('  Land segment: ${landSegment.geometry.length} points, ${landSegment.distance}m');
      log('  Marine segment: ${marineSegment.geometry.length} points, ${marineSegment.distance}m');
      log('  Total distance: ${totalDistance}m');

      // Refresh weather warnings after route calculation
      _updateWeatherWarnings();

      setState(() {
        _currentRoute = combinedRoute;
        _isCalculatingRoute = false;
        _showPortSelection = false;
      });

      _showMessage('Route calculated: ${_formatDistance(totalDistance)}', Colors.green);
      _fitRouteBounds(combinedRoute);

    } catch (e) {
      log('Error calculating route: $e');
      setState(() {
        _isCalculatingRoute = false;
      });
      _showMessage('Error calculating route: $e', Colors.red);
    }
  }

  /// Generate waypoints from route segments for the navigation overlay.
  /// Inserts OSRM turn waypoints for land segments and compass-heading
  /// intermediate waypoints for marine segments so the overlay always has
  /// something meaningful to display.
  List<Waypoint> _buildRouteWaypoints(List<RouteSegment> segments) {
    if (segments.isEmpty) return [];

    final waypoints = <Waypoint>[];
    double distAcc = 0;
    int timeAcc = 0;

    final firstSegType = segments.first.type == SegmentType.land
        ? RouteSegmentType.land
        : RouteSegmentType.marine;

    // Start waypoint (index 0 — skipped by nextWaypoint getter)
    waypoints.add(Waypoint(
      id: 'wp_start',
      location: segments.first.geometry.first,
      type: WaypointType.start,
      distanceFromStart: 0,
      instruction: 'Start navigation',
      segmentType: firstSegType,
    ));

    for (int i = 0; i < segments.length; i++) {
      final segment = segments[i];
      final isLast = i == segments.length - 1;

      if (segment.type == SegmentType.marine && segment.geometry.length >= 2) {
        // Sample intermediate compass-heading waypoints every 500 m along the
        // marine segment so the overlay shows directional progress at sea.
        const sampleInterval = 500.0; // metres
        double accumulated = 0.0;
        double nextSample = sampleInterval;
        int wpIdx = 0;
        for (int g = 0; g < segment.geometry.length - 1; g++) {
          final from = segment.geometry[g];
          final to = segment.geometry[g + 1];
          final segLen = _haversineMeters(from, to);
          accumulated += segLen;
          if (accumulated >= nextSample) {
            final bearing = _bearingBetween(from, to);
            final compass = _compassFromBearing(bearing);
            final frac = accumulated / segment.distance;
            final t = (timeAcc + frac * segment.duration).round();
            waypoints.add(Waypoint(
              id: 'wp_marine_${i}_$wpIdx',
              location: to,
              type: WaypointType.intermediate,
              distanceFromStart: distAcc + accumulated,
              instruction: 'Head $compass',
              estimatedTime: t,
              segmentType: RouteSegmentType.marine,
            ));
            wpIdx++;
            nextSample += sampleInterval;
          }
        }
      }

      if (segment.type == SegmentType.land && segment.steps.isNotEmpty) {
        // Insert turn-by-turn waypoints from OSRM steps.
        // Skip steps that are less than 30 m from the last waypoint to
        // prevent GPS drift from rapidly cycling through very close turns.
        double stepDistAcc = 0;
        for (int s = 0; s < segment.steps.length; s++) {
          final step = segment.steps[s];
          final type = step.maneuverType;
          if (type == 'depart' || type == 'arrive') {
            stepDistAcc += step.distance;
            continue;
          }
          // Filter out waypoints that are too close to the previous one.
          if (waypoints.isNotEmpty) {
            final prev = waypoints.last;
            final dLat = step.location.latitude - prev.location.latitude;
            final dLon = step.location.longitude - prev.location.longitude;
            final distSq = dLat * dLat + dLon * dLon;
            // 30 m ≈ 0.00027 degrees → 0.00027² ≈ 7.3e-8
            if (distSq < 7.3e-8) {
              stepDistAcc += step.distance;
              continue;
            }
          }
          final instruction = _buildStepInstruction(step);
          final stepTime = (segment.duration > 0 && segment.distance > 0)
              ? (stepDistAcc / segment.distance * segment.duration).round()
              : 0;
          waypoints.add(Waypoint(
            id: 'wp_step_${i}_$s',
            location: step.location,
            type: WaypointType.turn,
            distanceFromStart: distAcc + stepDistAcc,
            instruction: instruction,
            estimatedTime: timeAcc + stepTime,
            segmentType: RouteSegmentType.land,
          ));
          stepDistAcc += step.distance;
        }
      }

      if (!isLast) {
        distAcc += segment.distance;
        timeAcc += segment.duration;

        // Marina-transition waypoint between adjacent segments
        final toSea = segments[i + 1].type == SegmentType.marine;
        waypoints.add(Waypoint(
          id: 'wp_transition_$i',
          location: segment.geometry.last,
          type: toSea ? WaypointType.marinaEntry : WaypointType.marinaExit,
          distanceFromStart: distAcc,
          instruction: toSea ? 'Launch boat at port' : 'Dock at port',
          estimatedTime: timeAcc,
          segmentType: RouteSegmentType.transition,
        ));
      } else {
        distAcc += segment.distance;
        timeAcc += segment.duration;
      }
    }

    // End waypoint
    final lastSegType = segments.last.type == SegmentType.land
        ? RouteSegmentType.land
        : RouteSegmentType.marine;
    waypoints.add(Waypoint(
      id: 'wp_end',
      location: segments.last.geometry.last,
      type: WaypointType.end,
      distanceFromStart: distAcc,
      instruction: 'Arrived at destination',
      estimatedTime: timeAcc,
      segmentType: lastSegType,
    ));

    return waypoints;
  }

  /// Converts an OSRM step's maneuver into a human-readable instruction.
  String _buildStepInstruction(OsrmStep step) {
    final type = step.maneuverType ?? '';
    final modifier = step.maneuverModifier ?? '';
    final street = step.streetName != null ? ' onto ${step.streetName}' : '';

    switch (type) {
      case 'turn':
        if (modifier == 'left') return 'Turn left$street';
        if (modifier == 'right') return 'Turn right$street';
        if (modifier == 'sharp left') return 'Turn sharply left$street';
        if (modifier == 'sharp right') return 'Turn sharply right$street';
        if (modifier == 'slight left') return 'Keep left$street';
        if (modifier == 'slight right') return 'Keep right$street';
        return 'Turn$street';
      case 'new name':
        return 'Continue$street';
      case 'merge':
        if (modifier == 'left') return 'Merge left$street';
        if (modifier == 'right') return 'Merge right$street';
        return 'Merge$street';
      case 'on ramp':
        return 'Take the ramp$street';
      case 'off ramp':
        return 'Take the exit$street';
      case 'fork':
        if (modifier == 'left') return 'Keep left at the fork$street';
        if (modifier == 'right') return 'Keep right at the fork$street';
        return 'Take the fork$street';
      case 'end of road':
        if (modifier == 'left') return 'Turn left at the end of the road$street';
        if (modifier == 'right') return 'Turn right at the end of the road$street';
        return 'At the end of the road$street';
      case 'roundabout':
      case 'rotary':
        if (modifier.isNotEmpty) return 'Take the roundabout, exit $modifier$street';
        return 'Take the roundabout$street';
      case 'roundabout turn':
        if (modifier == 'left') return 'At the roundabout, turn left$street';
        if (modifier == 'right') return 'At the roundabout, turn right$street';
        return 'Continue through the roundabout$street';
      case 'continue':
        return 'Continue straight$street';
      default:
        if (street.isNotEmpty) return 'Continue$street';
        return 'Continue straight';
    }
  }

  double _haversineMeters(LatLng a, LatLng b) {
    const r = 6371000.0;
    final lat1 = a.latitude * math.pi / 180;
    final lat2 = b.latitude * math.pi / 180;
    final dLat = (b.latitude - a.latitude) * math.pi / 180;
    final dLon = (b.longitude - a.longitude) * math.pi / 180;
    final x = math.sin(dLat / 2) * math.sin(dLat / 2) +
        math.cos(lat1) * math.cos(lat2) *
            math.sin(dLon / 2) * math.sin(dLon / 2);
    return r * 2 * math.atan2(math.sqrt(x), math.sqrt(1 - x));
  }

  double _bearingBetween(LatLng from, LatLng to) {
    final lat1 = from.latitude * math.pi / 180;
    final lat2 = to.latitude * math.pi / 180;
    final dLon = (to.longitude - from.longitude) * math.pi / 180;
    final y = math.sin(dLon) * math.cos(lat2);
    final x = math.cos(lat1) * math.sin(lat2) -
        math.sin(lat1) * math.cos(lat2) * math.cos(dLon);
    return (math.atan2(y, x) * 180 / math.pi + 360) % 360;
  }

  String _compassFromBearing(double bearing) {
    const dirs = [
      'North', 'North-East', 'East', 'South-East',
      'South', 'South-West', 'West', 'North-West'
    ];
    return dirs[((bearing + 22.5) / 45).floor() % 8];
  }

  void _clearRoute() {
    setState(() {
      _currentRoute = null;
      _selectedMarina = null;
      _selectedPort = null;
      _seaDestination = null;
      _showPortSelection = false;
      _navMode = null;
      _seaOrigin = null;
      _seaToLandOrigin = null;
      _customLandDestination = null;
      _returnPort = null;
      _customLandOrigin = null;
    });
  }

  void _startLandToSeaMode() {
    setState(() {
      _navMode = NavMode.landToSea;
      _showPortSelection = true;
      _currentRoute = null;
      _selectedPort = null;
      _seaDestination = null;
      _customLandOrigin = null;
    });
  }

  void _startSeaToSeaMode() {
    LatLng? gpsSeaOrigin;
    if (_locationData != null && _maskInitialized) {
      final candidate = LatLng(
        _locationData!.latitude ?? MapConstants.defaultLatitude,
        _locationData!.longitude ?? MapConstants.defaultLongitude,
      );
      if (_navigationMask.isPointNavigable(candidate)) {
        gpsSeaOrigin = candidate;
      }
    }

    setState(() {
      _navMode = NavMode.seaToSea;
      _showPortSelection = false;
      _currentRoute = null;
      _seaOrigin = gpsSeaOrigin;
      _seaDestination = null;
    });

    if (gpsSeaOrigin != null) {
      _showMessage('Departure set to your location. Now tap your destination.', Colors.blue);
    } else {
      _showMessage(MapLocalizations.of(context).tapSeaDeparture, Colors.blue);
    }
  }

  void _startSeaToLandMode() {
    setState(() {
      _navMode = NavMode.seaToLand;
      _showPortSelection = true;
      _currentRoute = null;
      _selectedPort = _returnPort; // pre-select saved port if available
      _seaToLandOrigin = null;
      _customLandDestination = null;
    });
  }

  void _handlePortSelected(PortPoint port) {
    setState(() {
      _selectedPort = port;
      if (_navMode == NavMode.landToSea) {
        _returnPort = port; // save for possible return trip
      }
    });
    _showMessage('Port selected: ${port.name}', Colors.blue);

    // Trigger route calculation when all inputs are ready
    if (_navMode == NavMode.landToSea && _seaDestination != null) {
      _calculatePortToSeaRoute();
    } else if (_navMode == NavMode.seaToLand &&
        _seaToLandOrigin != null &&
        _customLandDestination != null) {
      _calculateSeaToLandRoute();
    }
  }

  // ============================================================
  // Sea-to-Sea Route Calculation
  // ============================================================

  Future<void> _calculateSeaToSeaRoute() async {
    if (_seaOrigin == null || _seaDestination == null) return;

    setState(() {
      _isCalculatingRoute = true;
      _currentRoute = null;
    });

    try {
      final marineSegment = await _marineService.findMarineRoute(
        origin: _seaOrigin!,
        destination: _seaDestination!,
        restrictedAreas: [
          if (_geoJsonBuilder != null) ...[
            ..._geoJsonBuilder!.buildRestrictedAreas(isVisible: true),
            ..._geoJsonBuilder!.buildProtectedZones(isVisible: true),
          ],
          ..._exclusionZoneService.buildExclusionPolygons(),
        ],
      );

      if (marineSegment == null) {
        setState(() => _isCalculatingRoute = false);
        _showMessage('Could not find sea route', Colors.red);
        return;
      }

      final seaSegments = [marineSegment];
      final route = NavigationRoute(
        id: 'route_${DateTime.now().millisecondsSinceEpoch}',
        origin: _seaOrigin!,
        destination: _seaDestination!,
        geometry: marineSegment.geometry,
        segments: seaSegments,
        waypoints: _buildRouteWaypoints(seaSegments),
        totalDistance: marineSegment.distance,
        estimatedDuration: marineSegment.duration,
        validation: RouteValidation(
          isValid: true,
          totalPoints: marineSegment.geometry.length,
          waterPoints: marineSegment.geometry.length,
          landPoints: 0,
          landPointIndices: [],
        ),
        createdAt: DateTime.now(),
        metrics: RouteMetrics(
          landDistance: 0,
          marineDistance: marineSegment.distance,
          landDuration: 0,
          marineDuration: marineSegment.duration,
        ),
      );

      _updateWeatherWarnings();

      setState(() {
        _currentRoute = route;
        _isCalculatingRoute = false;
        _navMode = null;
      });

      _showMessage('Route calculated: ${_formatDistance(route.totalDistance)}', Colors.green);
      _fitRouteBounds(route);
    } catch (e) {
      log('Error calculating sea-to-sea route: $e');
      setState(() => _isCalculatingRoute = false);
      _showMessage('Error calculating route: $e', Colors.red);
    }
  }

  // ============================================================
  // Sea-to-Land Route Calculation
  // ============================================================

  Future<void> _calculateSeaToLandRoute() async {
    if (_seaToLandOrigin == null || _selectedPort == null || _customLandDestination == null) {
      _showMessage('Please select sea origin, port, and land destination', Colors.orange);
      return;
    }

    setState(() {
      _isCalculatingRoute = true;
      _currentRoute = null;
    });

    try {
      // Marine segment: sea origin → port
      final marineSegment = await _marineService.findMarineRoute(
        origin: _seaToLandOrigin!,
        destination: _selectedPort!.location,
        restrictedAreas: [
          if (_geoJsonBuilder != null) ...[
            ..._geoJsonBuilder!.buildRestrictedAreas(isVisible: true),
            ..._geoJsonBuilder!.buildProtectedZones(isVisible: true),
          ],
          ..._exclusionZoneService.buildExclusionPolygons(),
        ],
      );

      if (marineSegment == null) {
        setState(() => _isCalculatingRoute = false);
        _showMessage('Could not find marine route to port', Colors.red);
        return;
      }

      // Land segment: port → land destination
      final landSegment = await _osrmService.getRoute(
        origin: _selectedPort!.location,
        destination: _customLandDestination!,
      );

      if (landSegment == null) {
        setState(() => _isCalculatingRoute = false);
        _showMessage('Could not find land route from port', Colors.red);
        return;
      }

      final combinedGeometry = [...marineSegment.geometry, ...landSegment.geometry];
      final segments = [marineSegment, landSegment];
      final totalDistance = marineSegment.distance + landSegment.distance;
      final totalDuration = marineSegment.duration + landSegment.duration;

      final route = NavigationRoute(
        id: 'route_${DateTime.now().millisecondsSinceEpoch}',
        origin: _seaToLandOrigin!,
        destination: _customLandDestination!,
        geometry: combinedGeometry,
        segments: segments,
        waypoints: _buildRouteWaypoints(segments),
        totalDistance: totalDistance,
        estimatedDuration: totalDuration,
        validation: RouteValidation(
          isValid: true,
          totalPoints: combinedGeometry.length,
          waterPoints: marineSegment.geometry.length,
          landPoints: landSegment.geometry.length,
          landPointIndices: [],
        ),
        createdAt: DateTime.now(),
        metrics: RouteMetrics(
          landDistance: landSegment.distance,
          marineDistance: marineSegment.distance,
          landDuration: landSegment.duration,
          marineDuration: marineSegment.duration,
        ),
      );

      _updateWeatherWarnings();

      setState(() {
        _currentRoute = route;
        _isCalculatingRoute = false;
        _showPortSelection = false;
        _navMode = null;
      });

      _showMessage('Route calculated: ${_formatDistance(totalDistance)}', Colors.green);
      _fitRouteBounds(route);
    } catch (e) {
      log('Error calculating sea-to-land route: $e');
      setState(() => _isCalculatingRoute = false);
      _showMessage('Error calculating route: $e', Colors.red);
    }
  }


  void _fitRouteBounds(NavigationRoute route) {
    final points = route.geometry;
    if (points.isEmpty) return;

    double minLat = points.first.latitude;
    double maxLat = points.first.latitude;
    double minLon = points.first.longitude;
    double maxLon = points.first.longitude;

    for (final point in points) {
      if (point.latitude < minLat) minLat = point.latitude;
      if (point.latitude > maxLat) maxLat = point.latitude;
      if (point.longitude < minLon) minLon = point.longitude;
      if (point.longitude > maxLon) maxLon = point.longitude;
    }

    _mapController.fitCamera(
      CameraFit.bounds(
        bounds: LatLngBounds(
          LatLng(minLat, minLon),
          LatLng(maxLat, maxLon),
        ),
        padding: const EdgeInsets.all(50),
      ),
    );
  }

  void _updateWeatherWarnings() {
    final warnings = _weatherService.getActiveWarnings();
    if (mounted) {
      setState(() {
        _activeWeatherWarnings = warnings;
        _weatherAlertDismissed = false;
      });
    }
  }

  void _checkExclusionZones(LatLng position) {
    if (!_exclusionZoneService.isInitialized) return;

    final violation = _exclusionZoneService.checkViolation(position);
    ExclusionZone? approaching;
    double approachDist = 0;

    if (violation == null) {
      approaching = _exclusionZoneService.checkApproach(
        position,
        warningMeters: 2000,
      );
      if (approaching != null) {
        approachDist = _exclusionZoneService.distanceTo(position, approaching);
      }
    }

    if (mounted) {
      setState(() {
        _activeExclusionViolation = violation;
        _approachingExclusionZone = approaching;
        _approachingExclusionZoneDistance = approachDist;
        if (violation != null) _exclusionAlertDismissed = false;
      });
    }
  }

  void _showMessage(String message, Color color) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: color,
        duration: const Duration(seconds: 3),
      ),
    );
  }

  /// Returns the name of the protected or restricted area that contains [point],
  /// or null if the point is not inside any such area.
  String? _getProtectedAreaAt(LatLng point) {
    if (_geoJsonBuilder == null) return null;

    for (final type in ['protected_zone', 'restricted_area']) {
      for (final feature in _geoJsonBuilder!.getFeaturesByType(type)) {
        try {
          final coords = feature['geometry']['coordinates'][0] as List;
          final polygon = coords
              .map((c) => LatLng(
                    (c[1] as num).toDouble(),
                    (c[0] as num).toDouble(),
                  ))
              .toList();
          if (GeometryUtils.isPointInPolygon(point, polygon)) {
            return feature['properties']['name'] as String? ?? 'Protected Area';
          }
        } catch (_) {}
      }
    }
    return null;
  }

  String _formatDistance(double meters) {
    if (meters < 1000) {
      return '${meters.round()} m';
    } else {
      return '${(meters / 1000).toStringAsFixed(1)} km';
    }
  }

  // ============================================================
  // Navigation Session Methods
  // ============================================================

  Future<void> _startNavigation() async {
    if (_currentRoute == null || _navigationManager == null) return;

    try {
      log('Starting navigation session');
      await _navigationManager!.startNavigation(_currentRoute!);
      _showMessage('Navigation started', Colors.green);

      // Enable follow mode and reset arrival tracker for this new trip.
      setState(() {
        _isFollowingNavigation = true;
        _lastNavState = null;
      });
      if (_locationData != null) {
        _mapController.move(
          LatLng(
            _locationData!.latitude ?? MapConstants.defaultLatitude,
            _locationData!.longitude ?? MapConstants.defaultLongitude,
          ),
          16,
        );
      }
    } catch (e) {
      log('Error starting navigation: $e');
      _showMessage('Failed to start navigation: $e', Colors.red);
    }
  }

  void _endNavigation() {
    if (_navigationManager == null) return;

    log('Ending navigation session');
    _navigationManager!.cancelNavigation();
    setState(() => _isFollowingNavigation = false);
    _clearRoute();
  }

  void _recenterOnLocation() {
    if (_navigationManager?.session?.currentLocation != null) {
      _mapController.move(
        _navigationManager!.session!.currentLocation!,
        16,
      );
    } else if (_locationData != null) {
      _mapController.move(
        LatLng(
          _locationData!.latitude ?? MapConstants.defaultLatitude,
          _locationData!.longitude ?? MapConstants.defaultLongitude,
        ),
        16,
      );
    }
  }

  // ============================================================
  // Admin Edit Methods
  // ============================================================

  void _enterAdminEditMode() {
    setState(() {
      _layerManager.isAdminEditMode = true;
      _layerManager.showMaskOverlay = true;
      _paintedCells.clear();
    });
  }

  // ============================================================
  // Outline Edit Methods
  // ============================================================

  void _enterOutlineEditMode() {
    setState(() {
      _isOutlineEditMode = true;
      _layerManager.showMaskOverlay = true;
    });
  }

  void _exitOutlineEditMode() {
    setState(() {
      _isOutlineEditMode = false;
      _outlinePaintPreview = null;
    });
  }

  Future<void> _handleOutlinePaint(LatLng point) async {
    setState(() => _outlinePaintPreview = point);
    try {
      await _outlineEditService.addEdit(OutlineEdit(
        point: point,
        radiusDegrees: _outlineBrushRadius,
        isErase: _outlineBrushMode == OutlineBrushMode.erase,
        createdAt: DateTime.now(),
      ));
    } catch (e) {
      _showMessage('Failed to save outline edit', Colors.red);
    }
  }

  Future<void> _resetOutlineEdits() async {
    try {
      await _outlineEditService.resetAllEdits();
      _showMessage('Outline reset to original', Colors.green);
    } catch (e) {
      _showMessage('Failed to reset outline', Colors.red);
    }
  }

  // ============================================================
  // UI Builder Methods
  // ============================================================

  Widget _buildMap() {
    final isAdminMode = _layerManager.isAdminEditMode;
    final isFeatureEditMode = _layerManager.isFeatureEditMode;
    final isOutlineMode = _isOutlineEditMode;

    return FlutterMap(
      mapController: _mapController,
      options: MapOptions(
        initialCenter: const LatLng(
          MapConstants.defaultLatitude,
          MapConstants.defaultLongitude,
        ),
        initialZoom: MapConstants.defaultZoom,
        onMapReady: _onMapReady,
        onTap: _handleMapTap,
        onPositionChanged: (position, hasGesture) {
          if (position.zoom != _currentZoom) {
            setState(() => _currentZoom = position.zoom);
          }
          // User panned manually — disengage follow mode
          if (hasGesture && _isFollowingNavigation) {
            setState(() => _isFollowingNavigation = false);
          }
        },
        // Disable map gestures in admin/outline edit mode to allow painting
        interactionOptions: InteractionOptions(
          flags: isAdminMode || isOutlineMode
              ? InteractiveFlag.none
              : isFeatureEditMode
                  ? InteractiveFlag.all & ~InteractiveFlag.doubleTapZoom
                  : InteractiveFlag.all,
        ),
      ),
      children: [
        // Base map layer
        if (_layerManager.showBaseMap)
          TileLayer(
            urlTemplate: MapConstants.osmBaseUrl,
            userAgentPackageName: MapConstants.userAgent,
            maxZoom: MapConstants.osmMaxZoom.toDouble(),
            subdomains: MapConstants.osmSubdomains,
          ),

        // GEBCO depth soundings layer (toggled from layer panel)
        if (_layerManager.showDepthSoundings)
          const DepthSoundingsLayer(),

        // Enhanced depth layer with multiple visualization types
        ListenableBuilder(
          listenable: _layerManager,
          builder: (context, _) {
            return EnhancedDepthLayer(
              isVisible: _layerManager.showDepthLayer,
              opacity: _layerManager.depthLayerOpacity,
              visualizationType: _layerManager.depthVisualizationType,
            );
          },
        ),

        // GeoJSON layers (protected zones)
        if (_geoJsonBuilder != null)
          ListenableBuilder(
            listenable: _layerManager,
            builder: (context, _) {
              if (!_layerManager.showProtectedZones) {
                return const SizedBox.shrink();
              }
              return GeoJsonMapLayers(
                builder: _geoJsonBuilder!,
                showProtectedZones: true,
              );
            },
          ),

        // Fish probability heatmap layer
        if (_fishProbabilityService.isInitialized)
          ListenableBuilder(
            listenable: _layerManager,
            builder: (context, _) {
              if (!_layerManager.showFishProbabilityHeatmap) {
                return const SizedBox.shrink();
              }
              return FishProbabilityLayer(
                service: _fishProbabilityService,
                selectedSpecies: _layerManager.selectedSpecies,
                currentZoom: _currentZoom,
              );
            },
          ),

        // Offshore oil/gas platform exclusion zones (500m UNCLOS buffer)
        ListenableBuilder(
          listenable: _layerManager,
          builder: (context, _) => ExclusionZoneLayer(
            service: _exclusionZoneService,
            isVisible: _layerManager.showExclusionZones,
          ),
        ),

        // Territorial water boundary — live-editable outline layer.
        // When outline-edit mode is active the edited version is shown
        // (streams Firestore edits in real time so all users see changes).
        // Otherwise falls back to the static boundary layer.
        if (_maskInitialized)
          _isOutlineEditMode
              ? EditedTerritorialOutlineLayer(
                  navigationMask: _navigationMask,
                  editService: _outlineEditService,
                  isVisible: true,
                )
              : TerritorialMaskLayer(
                  navigationMask: _navigationMask,
                  isVisible: _layerManager.showMaskOverlay,
                ),

        // Paint preview circle while admin drags in outline-edit mode
        if (_isOutlineEditMode)
          OutlinePaintPreviewLayer(
            center: _outlinePaintPreview,
            radiusDegrees: _outlineBrushRadius,
            mode: _outlineBrushMode,
          ),

        // Painted cells visualization (admin edit mode)
        if (_layerManager.isAdminEditMode && _paintedCells.isNotEmpty)
          PolygonLayer(
            polygons: _buildPaintedCellsOverlay(),
          ),

        // // Feature drawing layer (feature edit mode)
        // if (_layerManager.isFeatureEditMode)
        //   FeatureDrawingLayer(
        //     editState: _featureEditState,
        //   ),

        // // Marina markers — hidden during active navigation
        // if (_marinaService.isInitialized && _showMarinas &&
        //     !(_navigationManager?.isNavigating ?? false))
        //   MarinaMarkerLayer(
        //     marinas: _marinaService.getAllMarinas(),
        //     highlightedMarinaId: _selectedMarina?.id,
        //     onMarinaTapped: _handleMarinaTapped,
        //   ),

        // Route visualization (show active segment if navigating)
        if (_currentRoute != null)
          RoutePolylineLayer(
            route: _currentRoute!,
            activeSegmentIndex: _navigationManager?.session?.currentSegmentIndex,
            showMarkers: true,
            userLocation: _navigationManager?.isNavigating == true
                ? _navigationManager?.session?.currentLocation
                : null,
          ),

        // Breadcrumb trail (during active navigation)
        if (_navigationManager?.session != null &&
            _navigationManager!.session!.breadcrumbs.length > 1)
          PolylineLayer(
            polylines: [
              Polyline(
                points: _navigationManager!.session!.breadcrumbs,
                strokeWidth: 3.0,
                color: Colors.teal.withValues(alpha: 0.6),
              ),
            ],
          ),

        // Custom origin marker (when using destination picker)
        if (_originPoint != null && _currentRoute == null)
          MarkerLayer(
            markers: [
              Marker(
                point: _originPoint!,
                width: 40,
                height: 40,
                child: Container(
                  decoration: BoxDecoration(
                    color: Colors.green,
                    shape: BoxShape.circle,
                    border: Border.all(color: Colors.white, width: 3),
                  ),
                  child: const Icon(
                    Icons.radio_button_checked,
                    color: Colors.white,
                    size: 24,
                  ),
                ),
              ),
            ],
          ),

        // Destination marker
        if (_destinationPoint != null && _currentRoute == null)
          MarkerLayer(
            markers: [
              Marker(
                point: _destinationPoint!,
                width: 40,
                height: 40,
                child: Container(
                  decoration: BoxDecoration(
                    color: Colors.red,
                    shape: BoxShape.circle,
                    border: Border.all(color: Colors.white, width: 3),
                  ),
                  child: const Icon(
                    Icons.place,
                    color: Colors.white,
                    size: 24,
                  ),
                ),
              ),
            ],
          ),

        // Port markers (visible when port selection is active or a port is selected, hidden during navigation)
        if (!(_navigationManager?.isNavigating ?? false) &&
            (_showPortSelection || _selectedPort != null || _navMode == NavMode.seaToLand))
          MarkerLayer(
            markers: _availablePorts.map((port) {
              final isSelected = _selectedPort?.id == port.id;
              return Marker(
                point: port.location,
                width: 52,
                height: 52,
                child: GestureDetector(
                  onTap: () => _handlePortSelected(port),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Container(
                        width: 32,
                        height: 32,
                        decoration: BoxDecoration(
                          color: isSelected ? Colors.green : AppColors.red,
                          shape: BoxShape.circle,
                          border: Border.all(
                            color: Colors.white,
                            width: isSelected ? 2.5 : 1.5,
                          ),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withValues(alpha: 0.4),
                              blurRadius: 4,
                            ),
                          ],
                        ),
                        child: const Icon(
                          Icons.anchor,
                          color: Colors.white,
                          size: 16,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Container(
                        constraints: const BoxConstraints(maxWidth: 52),
                        padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 1),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(3),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withValues(alpha: 0.3),
                              blurRadius: 3,
                            ),
                          ],
                        ),
                        child: Text(
                          port.name.split(' ').first,
                          style: const TextStyle(
                            fontSize: 8,
                            fontWeight: FontWeight.bold,
                          ),
                          overflow: TextOverflow.ellipsis,
                          maxLines: 1,
                        ),
                      ),
                    ],
                  ),
                ),
              );
            }).toList(),
          ),

        // Sea destination marker (when set)
        if (_seaDestination != null && _currentRoute == null)
          MarkerLayer(
            markers: [
              Marker(
                point: _seaDestination!,
                width: 40,
                height: 40,
                child: Container(
                  decoration: BoxDecoration(
                    color: Colors.blue,
                    shape: BoxShape.circle,
                    border: Border.all(color: Colors.white, width: 3),
                  ),
                  child: const Icon(Icons.place, color: Colors.white, size: 24),
                ),
              ),
            ],
          ),

        // Sea origin marker (sea→sea departure point)
        if (_seaOrigin != null && _currentRoute == null)
          MarkerLayer(
            markers: [
              Marker(
                point: _seaOrigin!,
                width: 40,
                height: 40,
                child: Container(
                  decoration: BoxDecoration(
                    color: Colors.teal,
                    shape: BoxShape.circle,
                    border: Border.all(color: Colors.white, width: 3),
                  ),
                  child: const Icon(Icons.radio_button_checked, color: Colors.white, size: 24),
                ),
              ),
            ],
          ),

        // Sea→land departure marker
        if (_seaToLandOrigin != null && _currentRoute == null)
          MarkerLayer(
            markers: [
              Marker(
                point: _seaToLandOrigin!,
                width: 40,
                height: 40,
                child: Container(
                  decoration: BoxDecoration(
                    color: Colors.teal,
                    shape: BoxShape.circle,
                    border: Border.all(color: Colors.white, width: 3),
                  ),
                  child: const Icon(Icons.directions_boat, color: Colors.white, size: 22),
                ),
              ),
            ],
          ),

        // Custom land origin marker (land→sea with overridden start)
        if (_customLandOrigin != null && _currentRoute == null)
          MarkerLayer(
            markers: [
              Marker(
                point: _customLandOrigin!,
                width: 40,
                height: 40,
                child: Container(
                  decoration: BoxDecoration(
                    color: Colors.orange,
                    shape: BoxShape.circle,
                    border: Border.all(color: Colors.white, width: 3),
                  ),
                  child: const Icon(Icons.home, color: Colors.white, size: 22),
                ),
              ),
            ],
          ),

        // Custom land destination marker (sea→land)
        if (_customLandDestination != null && _currentRoute == null)
          MarkerLayer(
            markers: [
              Marker(
                point: _customLandDestination!,
                width: 40,
                height: 40,
                child: Container(
                  decoration: BoxDecoration(
                    color: Colors.deepOrange,
                    shape: BoxShape.circle,
                    border: Border.all(color: Colors.white, width: 3),
                  ),
                  child: const Icon(Icons.home, color: Colors.white, size: 22),
                ),
              ),
            ],
          ),

        // Bahaar fishing zones, MPA circles, and confirmed spot markers
        ListenableBuilder(
          listenable: _layerManager,
          builder: (context, _) => _layerManager.showFishingSpots
              ? BahaarOverlayLayer(
                  onGetPrediction: _navigateToPrediction,
                  showMpaCircles: _layerManager.showProtectedZones,
                )
              : const SizedBox.shrink(),
        ),

        // Catch markers — visible during an active trip
        if (TripService.instance.hasActiveTrip)
          CatchMarkerLayer(
            catches: TripService.instance.activeTrip!.catches,
          ),

        // User location marker — arrow during active navigation, dot otherwise
        if (_locationData != null && !(_navigationManager?.isNavigating ?? false))
          MarkerLayer(
            markers: [_buildUserLocationMarker()],
          ),

        // Navigation arrow marker — replaces the dot while navigating
        if (_navigationManager?.isNavigating == true &&
            _navigationManager?.session?.currentLocation != null)
          MarkerLayer(
            markers: [_buildNavigationArrowMarker()],
          ),

        // DS-1 celestial fix uncertainty circle + marker
        const CelestialFixLayer(),

        // Trip recorder — live track, port markers, DR uncertainty circle
        const TripTrackLayer(),
      ],
    );
  }

  void _navigateToPrediction(LatLng latLng, String speciesId) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => PredictionScreen(
          initialLatLng: latLng,
          initialSpeciesId: speciesId,
        ),
      ),
    );
  }

  Future<void> _logCatchFromMap() async {
    final result = await showModalBottomSheet<CatchEditResult>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => const CatchEditSheet(entry: null),
    );
    if (result == null || !mounted) return;

    // Resolve catch location: prefer form location, fall back to current GPS
    LatLng? loc = result.location;
    if (loc == null && _locationData?.latitude != null && _locationData?.longitude != null) {
      loc = LatLng(_locationData!.latitude!, _locationData!.longitude!);
    }
    if (loc == null) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('تعذّر تحديد الموقع — يرجى تفعيل GPS أو تحديد الموقع يدوياً'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    if (_maskInitialized && !_navigationMask.isNavigable(loc.longitude, loc.latitude)) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('يجب تسجيل الصيدة في البحر'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    final trip = TripService.instance.activeTrip;
    if (trip == null) return;

    await TripService.instance.logCatch(
      tripId: trip.id,
      species: result.species,
      location: loc,
      weightKg: result.weightKg,
      notes: result.notes,
    );

    if (mounted) {
      setState(() {}); // refresh catch markers on map
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('تم تسجيل الصيدة بنجاح'),
          backgroundColor: Colors.teal,
        ),
      );
    }
  }


  List<Polygon> _buildPaintedCellsOverlay() {
    final polygons = <Polygon>[];
    final resolution = _navigationMask.resolution;
    final halfRes = resolution / 2;

    for (final entry in _paintedCells.entries) {
      final cell = entry.key;
      final brushType = entry.value;

      // Determine color based on the brush type used when painting this cell
      Color fillColor;
      Color borderColor;
      switch (brushType) {
        case AdminBrushType.water:
          fillColor = Colors.blue.withValues(alpha: 0.5);
          borderColor = Colors.blue.withValues(alpha: 0.8);
          break;
        case AdminBrushType.land:
          fillColor = Colors.brown.withValues(alpha: 0.5);
          borderColor = Colors.brown.withValues(alpha: 0.8);
          break;
        case AdminBrushType.eraser:
          fillColor = Colors.grey.withValues(alpha: 0.5);
          borderColor = Colors.grey.withValues(alpha: 0.8);
          break;
      }

      final center = _navigationMask.gridToCoords(cell.row, cell.col);
      polygons.add(
        Polygon(
          points: [
            LatLng(center.latitude - halfRes, center.longitude - halfRes),
            LatLng(center.latitude + halfRes, center.longitude - halfRes),
            LatLng(center.latitude + halfRes, center.longitude + halfRes),
            LatLng(center.latitude - halfRes, center.longitude + halfRes),
          ],
          color: fillColor,
          borderStrokeWidth: 1.0,
          borderColor: borderColor,
        ),
      );
    }
    return polygons;
  }

  Marker _buildUserLocationMarker() {
    final lat = _locationData!.latitude ?? MapConstants.defaultLatitude;
    final lon = _locationData!.longitude ?? MapConstants.defaultLongitude;
    final isOnWater = _maskInitialized && _navigationMask.isNavigable(lon, lat);

    return Marker(
      point: LatLng(lat, lon),
      width: 40,
      height: 40,
      child: Icon(
        Icons.my_location,
        color: isOnWater ? Colors.blue : Colors.orange,
        size: 30,
        shadows: const [
          Shadow(
            color: Colors.black54,
            blurRadius: 4,
          ),
        ],
      ),
    );
  }

  Marker _buildNavigationArrowMarker() {
    final session = _navigationManager!.session!;
    final pos = session.currentLocation!;
    final bearing = session.currentBearing ?? 0.0;

    return Marker(
      point: pos,
      width: 48,
      height: 48,
      rotate: false,
      child: Transform.rotate(
        angle: bearing * 3.14159265358979 / 180.0,
        child: Container(
          decoration: BoxDecoration(
            color: Colors.blue,
            shape: BoxShape.circle,
            border: Border.all(color: Colors.white, width: 2),
            boxShadow: const [
              BoxShadow(color: Colors.black38, blurRadius: 4, offset: Offset(0, 2)),
            ],
          ),
          child: const Icon(Icons.navigation, color: Colors.white, size: 26),
        ),
      ),
    );
  }

  // ============================================================
  // Main Build Method
  // ============================================================


  @override
  Widget build(BuildContext context) {
    super.build(context); // required by AutomaticKeepAliveClientMixin
    final l10n = MapLocalizations.of(context);

    return Scaffold(
      body: Stack(
        children: [
          // // Main map with gesture detector for admin painting
          // GestureDetector(
          //   behavior: _layerManager.isAdminEditMode ||
          //           _layerManager.isFeatureEditMode ||
          //           _isOutlineEditMode
          //       ? HitTestBehavior.opaque
          //       : HitTestBehavior.translucent,
          //   onTapDown: _layerManager.isAdminEditMode
          //       ? (details) {
          //           final latLng = _screenToLatLng(details.localPosition);
          //           if (latLng != null) _handleAdminPaint(latLng);
          //         }
          //       : _isOutlineEditMode
          //           ? (details) {
          //               final latLng =
          //                   _screenToLatLng(details.localPosition);
          //               if (latLng != null) _handleOutlinePaint(latLng);
          //             }
          //           : null,
          //   onPanStart: _layerManager.isAdminEditMode
          //       ? (details) {
          //           final latLng = _screenToLatLng(details.localPosition);
          //           if (latLng != null) _handleAdminPaint(latLng);
          //         }
          //       : _isOutlineEditMode
          //           ? (details) {
          //               final latLng =
          //                   _screenToLatLng(details.localPosition);
          //               if (latLng != null) _handleOutlinePaint(latLng);
          //             }
          //           : null,
          //   onPanUpdate: _layerManager.isAdminEditMode
          //       ? (details) {
          //           final latLng = _screenToLatLng(details.localPosition);
          //           if (latLng != null) _handleAdminPaint(latLng);
          //         }
          //       : _isOutlineEditMode
          //           ? (details) {
          //               final latLng =
          //                   _screenToLatLng(details.localPosition);
          //               if (latLng != null) _handleOutlinePaint(latLng);
          //             }
          //           : null,
          //   onPanEnd: _isOutlineEditMode
          //       ? (_) => setState(() => _outlinePaintPreview = null)
          //       : null,
          //   child: _buildMap(),
          // ),

          // Navigation status indicator (top right) — hidden during navigation
          if (!(_navigationManager?.isNavigating ?? false))
            Positioned(
              top: 50,
              right: 10,
              child: NavigationStatusIndicator(isReady: _maskInitialized, l10n: l10n),
            ),

          // Layer controls panel (top right, with outside-tap dismissal)
          ListenableBuilder(
            listenable: _layerManager,
            builder: (context, _) {
              if (_layerManager.showLayerControls) {
                return Stack(
                  children: [
                    // Transparent barrier to dismiss on outside tap
                    Positioned.fill(
                      child: GestureDetector(
                        onTap: () => _layerManager.showLayerControls = false,
                        behavior: HitTestBehavior.translucent,
                        child: const SizedBox.expand(),
                      ),
                    ),
                    Positioned(
                      top: 10,
                      right: 10,
                      child: LayerControlPanel(
                        layerManager: _layerManager,
                        geoJsonBuilder: _geoJsonBuilder,
                        maskInitialized: _maskInitialized,
                        onClose: () => _layerManager.showLayerControls = false,
                        onEnterAdminEdit: _enterAdminEditMode,
                      //  onEnterFeatureEdit: _enterFeatureEditMode,
                        onEnterOutlineEdit: _enterOutlineEditMode,
                        onOpenPrediction: () => Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (_) => const PredictionScreen(),
                          ),
                        ),
                      ),
                    ),
                  ],
                );
              }
              return const SizedBox.shrink();
            },
          ),

          // Outline editor toolbar (when in outline edit mode)
          if (_isOutlineEditMode && _maskInitialized)
            Positioned(
              top: 50,
              left: 10,
              child: TerritorialOutlineEditorToolbar(
                brushMode: _outlineBrushMode,
                brushRadius: _outlineBrushRadius,
                onBrushModeChanged: (mode) =>
                    setState(() => _outlineBrushMode = mode),
                onBrushRadiusChanged: (r) =>
                    setState(() => _outlineBrushRadius = r),
                onClose: _exitOutlineEditMode,
                onReset: _resetOutlineEdits,
              ),
            ),

          // Feature edit toolbar (when in feature edit mode)
          // ListenableBuilder(
          //   listenable: _featureEditState,
          //   builder: (context, _) {
          //     if (_layerManager.isFeatureEditMode) {
          //       return Positioned(
          //         top: 50,
          //         left: 10,
          //         child: FeatureEditToolbar(
          //           editState: _featureEditState,
          //           onClose: _exitFeatureEditMode,
          //           onStartAdd: (type) {
          //             _featureEditState.startAddFeature(type);
          //           },
          //           onStartSelect: () {
          //             _featureEditState.startSelectMode();
          //           },
          //           onConfirmDrawing: _confirmAndSaveDrawing,
          //           onCancelDrawing: () {
          //             _featureEditState.cancelDrawing();
          //           },
          //           onUndoVertex: () {
          //             _featureEditState.undoLastVertex();
          //           },
          //           onMoveFeature: () {
          //             _featureEditState.startMoveFeature();
          //           },
          //           onDeleteFeature: _deleteSelectedFeature,
          //         ),
          //       );
          //     }
          //     return const SizedBox.shrink();
          //   },
          // ),

          // Left toolbar (layers, legend, navigate) — hidden during edit modes
          ListenableBuilder(
            listenable: _layerManager,
            builder: (context, _) {
              if (_layerManager.isAdminEditMode ||
                  _layerManager.isFeatureEditMode ||
                  _isOutlineEditMode) {
                return const SizedBox.shrink();
              }
              return MapLeftToolbar(
                showLayerControls: _layerManager.showLayerControls,
                showDepthLegend: _showDepthLegend,
                hasRoute: _currentRoute != null,
                hasNavMode: _navMode != null,
                maskInitialized: _maskInitialized,
                celestialFixActive: CelestialFixNotifier.instance.fix != null,
                isNavigating: _navigationManager?.isNavigating ?? false,
                onToggleLayers: () => _layerManager.showLayerControls =
                    !_layerManager.showLayerControls,
                onToggleLegend: () =>
                    setState(() => _showDepthLegend = !_showDepthLegend),
                onOpenCelestial: () => Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (_) => const CelestialNavigationScreen(),
                  ),
                ),
                onToggleNav: () {
                  if (_currentRoute != null || _navMode != null) {
                    _clearRoute();
                  } else {
                    NavModeOption.show(
                      context,
                      onLandToSea: _startLandToSeaMode,
                      onSeaToSea: _startSeaToSeaMode,
                      onSeaToLand: _startSeaToLandMode,
                    );
                  }
                },
              );
            },
          ),

          // Depth legend (when visible, bottom left)
          if (_showDepthLegend && _layerManager.showDepthLayer)
            Positioned(
              bottom: 110,
              left: 12,
              child: DepthLegend(),
            ),

          // Marina info card (when marina is selected)
          if (_selectedMarina != null && _currentRoute == null)
            Positioned(
              bottom: 80,
              left: 16,
              right: 16,
              child: MarinaInfoCard(
                marina: _selectedMarina!,
                onClose: () => setState(() => _selectedMarina = null),
                onNavigate: () {
                  _calculateRoute(_selectedMarina!.location);
                },
              ),
            ),

          // Active navigation overlay (when navigating)
          if (_navigationManager != null)
            Positioned.fill(
              child: ListenableBuilder(
                listenable: _navigationManager!,
                builder: (context, _) {
                  final session = _navigationManager!.session;
                  if (session == null || session.state == NavigationState.cancelled) {
                    return const SizedBox.shrink();
                  }
                  return ActiveNavigationOverlay(
                    session: session,
                    onEndNavigation: _endNavigation,
                    onRecenter: _recenterOnLocation,
                    isRecalculating: _navigationManager!.isRecalculating,
                    isFollowing: _isFollowingNavigation,
                    onToggleFollow: () => setState(() {
                      _isFollowingNavigation = !_isFollowingNavigation;
                      if (_isFollowingNavigation) _recenterOnLocation();
                    }),
                  );
                },
              ),
            ),

          // Navigation instructions panel (shown during any active nav mode)
          if (_navMode != null && _currentRoute == null)
            NavInstructionsPanel(
              navMode: _navMode!,
              l10n: l10n,
              seaOrigin: _seaOrigin,
              seaDestination: _seaDestination,
              seaToLandOrigin: _seaToLandOrigin,
              selectedPort: _selectedPort,
              returnPort: _returnPort,
              customLandDestination: _customLandDestination,
              customLandOrigin: _customLandOrigin,
            ),


          // Outside-territorial-boundary warning
          if (_outsideMaskWarning != null && !_outsideMaskWarningDismissed)
            Positioned(
              top: 50,
              left: 60,
              right: 60,
              child: OutsideMaskWarning(
                message: _outsideMaskWarning!,
                onDismiss: () => setState(() => _outsideMaskWarningDismissed = true),
              ),
            ),

          // Exclusion zone violation alert (inside 500m buffer)
          if (_activeExclusionViolation != null && !_exclusionAlertDismissed)
            ExclusionZoneAlert(
              zone: _activeExclusionViolation!.zone,
              distanceMeters: _activeExclusionViolation!.distanceMeters,
              isViolation: true,
              onDismiss: () => setState(() => _exclusionAlertDismissed = true),
            ),

          // Exclusion zone approach warning (within 2km, not yet inside)
          if (_activeExclusionViolation == null &&
              _approachingExclusionZone != null &&
              !_exclusionAlertDismissed)
            ExclusionZoneAlert(
              zone: _approachingExclusionZone!,
              distanceMeters: _approachingExclusionZoneDistance,
              isViolation: false,
              onDismiss: () => setState(() => _exclusionAlertDismissed = true),
            ),

          // Weather alert overlay
          if (_activeWeatherWarnings.isNotEmpty && !_weatherAlertDismissed)
            WeatherAlertOverlay(
              warnings: _activeWeatherWarnings,
              onDismiss: () {
                setState(() {
                  _weatherAlertDismissed = true;
                });
              },
            ),

          // DS-1 GPS spoofing alert (shown when celestial fix diverges > 2 NM)
          const CelestialSpoofingAlert(),

          // Route calculation loading indicator
          if (_isCalculatingRoute)
            RouteCalculatingOverlay(label: l10n.calculatingRoute),

          // Offline indicator banner (top centre)
          if (!ConnectivityService.instance.isOnline)
            OfflineBanner(label: l10n.offlineMapCached),

          // Route stats card — top of screen, above all other overlays
          if (_currentRoute != null && !(_navigationManager?.isNavigating ?? false))
            Positioned(
              top: 80,
              left: 16,
              right: 16,
              child: RouteStatsCard(
                route: _currentRoute!,
                onCancel: _clearRoute,
                onStartNavigation: _startNavigation,
              ),
            ),

          // SOS button (bottom left) — hidden during active navigation (lives in the nav bar instead)
          if (!(_navigationManager?.isNavigating ?? false))
            Positioned(
              bottom: 16,
              left: 16,
              child: const SosButton(),
            ),

          // Zoom controls (bottom right) — hidden during active navigation
          if (!(_navigationManager?.isNavigating ?? false))
            Positioned(
              bottom: 16,
              right: 16,
              child: MapZoomControls(
              onZoomIn: _mapReady
                  ? () => _mapController.move(
                        _mapController.camera.center,
                        _mapController.camera.zoom + 1,
                      )
                  : null,
              onZoomOut: _mapReady
                  ? () => _mapController.move(
                        _mapController.camera.center,
                        _mapController.camera.zoom - 1,
                      )
                  : null,
              onMyLocation: _mapReady && _locationData != null
                  ? () => _mapController.move(
                        LatLng(
                          _locationData!.latitude ?? MapConstants.defaultLatitude,
                          _locationData!.longitude ?? MapConstants.defaultLongitude,
                        ),
                        14,
                      )
                  : null,
              onLogCatch: TripService.instance.hasActiveTrip
                  ? _logCatchFromMap
                  : null,
            ),
          ),
        ],
      ),
    );
  }
}


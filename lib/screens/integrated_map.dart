import 'dart:convert';
import 'dart:developer';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:latlong2/latlong.dart';
import 'package:location/location.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:Bahaar/services/map/navigation_mask.dart';
import 'package:Bahaar/services/map/map_layer_manager.dart';
import 'package:Bahaar/services/map/marina_data_service.dart';
import 'package:Bahaar/services/map/osrm_routing_service.dart';
import 'package:Bahaar/services/map/marine_pathfinding_service.dart';
import 'package:Bahaar/services/map/hybrid_route_coordinator.dart';
import 'package:Bahaar/services/map/navigation_session_manager.dart';
import 'package:Bahaar/models/navigation/marina_model.dart';
import 'package:Bahaar/models/navigation/route_model.dart';
import 'package:Bahaar/widgets/map/enhanced_depth_layer.dart';
import 'package:Bahaar/widgets/map/territorial_mask_layer.dart';
import 'package:Bahaar/widgets/map/geojson_layers.dart';
import 'package:Bahaar/widgets/map/layer_control_panel.dart';
import 'package:Bahaar/widgets/navigation/marina_marker_layer.dart';
import 'package:Bahaar/widgets/navigation/route_polyline_layer.dart';
import 'package:Bahaar/widgets/navigation/active_navigation_overlay.dart';
import 'package:Bahaar/widgets/navigation/weather_alert_overlay.dart';
import 'package:Bahaar/services/fish_probability_service.dart';
import 'package:Bahaar/widgets/map/fish_probability_layer.dart';
import 'package:Bahaar/services/marine_weather_service.dart';
import 'package:Bahaar/models/weather/marine_weather_model.dart';
import 'package:Bahaar/utilities/map_constants.dart';
import 'package:Bahaar/widgets/map/admin_edit_toolbar.dart';
import 'package:Bahaar/widgets/map/feature_edit_toolbar.dart';
import 'package:Bahaar/widgets/map/feature_drawing_layer.dart';
import 'package:Bahaar/services/feature_edit_service.dart';
import 'package:Bahaar/models/map/editable_map_feature.dart';
import 'package:Bahaar/models/map/feature_edit_state.dart';
import 'package:Bahaar/utilities/geometry_utils.dart';
import 'package:Bahaar/l10n/app_localizations.dart';
import 'package:Bahaar/services/map/exclusion_zone_service.dart';
import 'package:Bahaar/widgets/map/exclusion_zone_layer.dart';
import 'package:Bahaar/services/map/outline_edit_service.dart';
import 'package:Bahaar/widgets/map/territorial_outline_editor.dart';
import 'package:Bahaar/services/ais_service.dart';
import 'package:Bahaar/models/ais_model.dart';
import 'package:Bahaar/widgets/map/ais_vessel_layer.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:Bahaar/widgets/map/depth_soundings_layer.dart';
import 'package:Bahaar/services/offline/connectivity_service.dart';
import 'package:Bahaar/services/fishing/trip_service.dart';
import 'package:Bahaar/widgets/map/bahaar_overlay_layer.dart';
import 'package:Bahaar/screens/prediction_screen.dart';

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

class _IntegratedMapState extends State<IntegratedMap> {
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
  final FeatureEditService _featureEditService = FeatureEditService();
  final FeatureEditState _featureEditState = FeatureEditState();
  NavigationSessionManager? _navigationManager;

  // Feature edit state
  List<EditableMapFeature> _firestoreMapFeatures = [];
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

  // AIS state
  late final AisService _aisService;
  CpaResult? _topCpaAlert;
  bool _aisAlertDismissed = false;

  // State
  bool _mapReady = false;
  bool _serviceEnabled = false;
  PermissionStatus _permissionStatus = PermissionStatus.denied;
  LocationData? _locationData;
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

  // Ports loaded from seaports.json
  List<PortPoint> _availablePorts = [];

  // Selected port and destination
  PortPoint? _selectedPort;
  LatLng? _seaDestination;
  bool _showPortSelection = false;

  // Navigation mode
  _NavMode? _navMode;

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
    _loadFirestoreFeatures();
    _featureEditState.addListener(_onFeatureEditUpdate);
    _aisService = AisService(
      aishubUsername: dotenv.env['AISHUB_USERNAME'] ?? '',
    );
    _aisService.addListener(_onAisUpdate);
    _aisService.initialize();

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
    if (mounted) {
      setState(() {});
    }
  }

  void _onAisUpdate() {
    if (!mounted) return;
    // Pick the highest-risk CPA alert to show in the banner
    final alerts = _aisService.cpaAlerts;
    setState(() {
      _topCpaAlert = alerts.isNotEmpty ? alerts.first : null;
      if (_topCpaAlert != null) _aisAlertDismissed = false;
    });

    // Also feed own position into the CPA calculator whenever AIS updates
    final lat = _locationData?.latitude;
    final lon = _locationData?.longitude;
    if (lat != null && lon != null) {
      _aisService.updateOwnPosition(
        lat: lat,
        lon: lon,
        sogKnots: 0,  // stationary until we have own-vessel SOG/COG
        cogDeg: 0,
      );
    }
  }

  void _onFeatureEditUpdate() {
    if (mounted) {
      setState(() {});
    }
  }

  Future<void> _loadFirestoreFeatures() async {
    try {
      final features = await _featureEditService.loadMapFeatures();
      if (mounted) {
        setState(() {
          _firestoreMapFeatures = features;
        });
        _rebuildGeoJsonWithFirestore();
      }
    } catch (e) {
      log('Error loading Firestore features: $e');
    }
  }

  void _rebuildGeoJsonWithFirestore() {
    if (_rawAssetGeoJson != null) {
      setState(() {
        _geoJsonBuilder = GeoJsonLayerBuilder.withFirestoreFeatures(
          _rawAssetGeoJson!,
          _firestoreMapFeatures,
        );
      });
    }
  }

  @override
  void dispose() {
    _navigationManager?.removeListener(_onNavigationUpdate);
    _navigationManager?.dispose();
    _featureEditState.removeListener(_onFeatureEditUpdate);
    _featureEditState.dispose();
    _fishProbabilityService.dispose();
    _layerManager.dispose();
    _aisService.removeListener(_onAisUpdate);
    _aisService.dispose();
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
      setState(() {
        if (_firestoreMapFeatures.isNotEmpty) {
          _geoJsonBuilder = GeoJsonLayerBuilder.withFirestoreFeatures(
            data,
            _firestoreMapFeatures,
          );
        } else {
          _geoJsonBuilder = GeoJsonLayerBuilder(data);
        }
      });
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
        if (!isNavigable) {
          final isOutside = targetLocation.longitude < _navigationMask.minLon ||
              targetLocation.longitude > _navigationMask.maxLon ||
              targetLocation.latitude < _navigationMask.minLat ||
              targetLocation.latitude > _navigationMask.maxLat;
          final msg = isOutside
              ? 'Your location is outside the territorial water boundary'
              : 'Your location appears to be on land';
          log('Warning: $msg');
          setState(() {
            _outsideMaskWarning = msg;
            _outsideMaskWarningDismissed = false;
          });
        } else {
          log('Location validated: on navigable water');
        }
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

    // Handle feature edit mode
    if (_layerManager.isFeatureEditMode) {
      _handleFeatureEditTap(point);
      return;
    }

    // Handle admin edit mode
    if (_layerManager.isAdminEditMode) {
      _handleAdminPaint(point);
      return;
    }

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
    if (_navMode == _NavMode.seaToSea) {
      if (!isNavigable) {
        final msg = isOutsideBounds
            ? 'Outside territorial waters — tap on the sea'
            : 'Tap on the sea, not on land';
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
        _showMessage('Departure set. Now tap your sea destination.', Colors.blue);
      } else {
        setState(() => _seaDestination = point);
        _calculateSeaToSeaRoute();
      }
      return;
    }

    // ── Sea→Land mode ─────────────────────────────────────────────────────────
    if (_navMode == _NavMode.seaToLand) {
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
            ? 'Outside territorial waters'
            : _seaToLandOrigin == null ? 'Tap on the sea first' : 'Tap on the sea';
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
        _showMessage('Departure set. Select a port, then tap your land destination.', Colors.blue);
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
      if (_navMode == _NavMode.landToSea) {
        setState(() => _customLandOrigin = point);
        _showMessage('Land origin updated. Now tap a port and sea destination.', Colors.blue);
      }
      return;
    }

    if (!isNavigable) {
      final msg = isOutsideBounds
          ? 'Outside territorial waters — cannot pin a destination here'
          : 'Cannot pin a destination on land';
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
        _showMessage('Destination set. Now tap a port on the map to start from.', Colors.blue);
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

  void _handleFeatureEditTap(LatLng point) {
    switch (_featureEditState.interaction) {
      case FeatureEditInteraction.addPoint:
        _addPointFeature(point);
        break;
      case FeatureEditInteraction.addPolygon:
      case FeatureEditInteraction.addPolyline:
        _featureEditState.addVertex(point);
        break;
      case FeatureEditInteraction.select:
        _hitTestFeatures(point);
        break;
      case FeatureEditInteraction.moveFeature:
        _moveSelectedFeature(point);
        break;
      case FeatureEditInteraction.browse:
        break;
    }
  }

  Future<void> _addPointFeature(LatLng point) async {
    final type = _featureEditState.selectedFeatureType;
    if (type == null) return;

    final feature = EditableMapFeature(
      featureType: type,
      name: '${type.displayName} ${DateTime.now().millisecondsSinceEpoch}',
      coordinates: [point],
    );

    await _featureEditService.addMapFeature(feature);
    _showMessage('${type.displayName} added', Colors.green);
    await _loadFirestoreFeatures();
  }

  Future<void> _confirmAndSaveDrawing() async {
    final type = _featureEditState.selectedFeatureType;
    if (type == null) return;

    final vertices = _featureEditState.confirmDrawing();
    if (vertices.isEmpty) return;

    // Close polygon if needed
    final coords = List<LatLng>.from(vertices);
    if (type.geometryType == GeometryType.polygon &&
        coords.length >= 3 &&
        coords.first != coords.last) {
      coords.add(coords.first);
    }

    final feature = EditableMapFeature(
      featureType: type,
      name: '${type.displayName} ${DateTime.now().millisecondsSinceEpoch}',
      coordinates: coords,
    );

    await _featureEditService.addMapFeature(feature);
    _showMessage('${type.displayName} added', Colors.green);
    await _loadFirestoreFeatures();
  }

  void _hitTestFeatures(LatLng point) {
    // Threshold in degrees (~500m at Bahrain latitude)
    const pointThreshold = 0.005;
    const lineThreshold = 0.003;

    EditableMapFeature? closest;
    double closestDist = double.infinity;

    for (final feature in _firestoreMapFeatures) {
      switch (feature.geometryType) {
        case GeometryType.point:
          final dist =
              GeometryUtils.distanceBetween(point, feature.coordinates.first);
          if (dist < pointThreshold && dist < closestDist) {
            closestDist = dist;
            closest = feature;
          }
          break;
        case GeometryType.lineString:
          final dist = GeometryUtils.distanceToLineString(
              point, feature.coordinates);
          if (dist < lineThreshold && dist < closestDist) {
            closestDist = dist;
            closest = feature;
          }
          break;
        case GeometryType.polygon:
          if (GeometryUtils.isPointInPolygon(point, feature.coordinates)) {
            // For polygons, use distance to centroid as tiebreaker
            final centroid =
                GeometryUtils.computeCentroid(feature.coordinates);
            final dist = GeometryUtils.distanceBetween(point, centroid);
            if (dist < closestDist) {
              closestDist = dist;
              closest = feature;
            }
          }
          break;
      }
    }

    // Also hit-test asset features from GeoJsonBuilder
    if (closest == null && _geoJsonBuilder != null) {
      final allFeatures =
          _geoJsonBuilder!.geoJsonData['features'] as List? ?? [];
      for (final f in allFeatures) {
        try {
          final editableFeature = EditableMapFeature.fromGeoJsonFeature(
              f as Map<String, dynamic>);
          switch (editableFeature.geometryType) {
            case GeometryType.point:
              final dist = GeometryUtils.distanceBetween(
                  point, editableFeature.coordinates.first);
              if (dist < pointThreshold && dist < closestDist) {
                closestDist = dist;
                closest = editableFeature;
              }
              break;
            case GeometryType.lineString:
              final dist = GeometryUtils.distanceToLineString(
                  point, editableFeature.coordinates);
              if (dist < lineThreshold && dist < closestDist) {
                closestDist = dist;
                closest = editableFeature;
              }
              break;
            case GeometryType.polygon:
              if (GeometryUtils.isPointInPolygon(
                  point, editableFeature.coordinates)) {
                final centroid =
                    GeometryUtils.computeCentroid(editableFeature.coordinates);
                final dist = GeometryUtils.distanceBetween(point, centroid);
                if (dist < closestDist) {
                  closestDist = dist;
                  closest = editableFeature;
                }
              }
              break;
          }
        } catch (_) {}
      }
    }

    if (closest != null) {
      _featureEditState.selectFeature(closest);
      _showMessage('Selected: ${closest.name.isNotEmpty ? closest.name : closest.featureType.displayName}', Colors.blue);
    } else {
      _featureEditState.deselectFeature();
    }
  }

  Future<void> _moveSelectedFeature(LatLng newPosition) async {
    final feature = _featureEditState.selectedFeature;
    if (feature == null) return;

    List<LatLng> newCoords;
    if (feature.geometryType == GeometryType.point) {
      newCoords = [newPosition];
    } else {
      final centroid = GeometryUtils.computeCentroid(feature.coordinates);
      newCoords = GeometryUtils.translateGeometry(
          feature.coordinates, centroid, newPosition);
    }

    if (feature.id != null) {
      // Firestore feature — update in place
      final updated = feature.copyWith(
        coordinates: newCoords,
        updatedAt: DateTime.now(),
      );
      await _featureEditService.updateMapFeature(updated);
    } else {
      // Asset feature — create a new Firestore copy at the new position
      final newFeature = feature.copyWith(
        id: null,
        coordinates: newCoords,
      );
      await _featureEditService.addMapFeature(newFeature);
    }

    _featureEditState.startSelectMode();
    _showMessage('Feature moved', Colors.green);
    await _loadFirestoreFeatures();
  }

  Future<void> _deleteSelectedFeature() async {
    final feature = _featureEditState.selectedFeature;
    if (feature == null) return;

    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete Feature'),
        content: Text(
            'Delete "${feature.name.isNotEmpty ? feature.name : feature.featureType.displayName}"?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Delete', style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );

    if (confirm == true) {
      if (feature.id != null) {
        await _featureEditService.deleteMapFeature(feature.id!);
      }
      _featureEditState.deselectFeature();
      _showMessage('Feature deleted', Colors.green);
      await _loadFirestoreFeatures();
    }
  }

  void _enterFeatureEditMode() {
    setState(() {
      _layerManager.isFeatureEditMode = true;
      _featureEditState.enterEditMode();
    });
  }

  void _exitFeatureEditMode() {
    setState(() {
      _layerManager.isFeatureEditMode = false;
      _featureEditState.exitEditMode();
    });
  }

  /// Convert screen position to LatLng for drag painting
  LatLng? _screenToLatLng(Offset screenPosition) {
    if (!_mapReady) return null;
    try {
      // Use flutter_map's offset to latlng conversion
      return _mapController.camera.offsetToCrs(screenPosition);
    } catch (e) {
      return null;
    }
  }

  void _handleMarinaTapped(Marina marina) {
    setState(() {
      _selectedMarina = marina;
    });
    log('Marina tapped: ${marina.name}');

    // Center map on marina
    _mapController.move(marina.location, 15.0);
  }

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
      _showMessage('Please select both port and sea destination', Colors.orange);
      return;
    }

    // Use custom land origin if set, otherwise fall back to GPS
    final LatLng? gpsLocation = _locationData == null
        ? null
        : LatLng(
            _locationData!.latitude ?? MapConstants.defaultLatitude,
            _locationData!.longitude ?? MapConstants.defaultLongitude,
          );
    final landOrigin = _customLandOrigin ?? gpsLocation;

    if (landOrigin == null) {
      _showMessage('Current location not available', Colors.orange);
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
        waypoints: [],
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

  /// Show bottom sheet to let user choose which navigation mode to start.
  void _openNavModeSelection() {
    showModalBottomSheet<void>(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
      ),
      builder: (ctx) => SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 20),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'Choose Navigation Type',
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 16),
              _NavModeOption(
                icon: Icons.directions_boat,
                title: 'Land → Port → Sea',
                subtitle: 'Drive to a port, then navigate to a sea destination',
                onTap: () {
                  Navigator.pop(ctx);
                  _startLandToSeaMode();
                },
              ),
              const SizedBox(height: 8),
              _NavModeOption(
                icon: Icons.waves,
                title: 'Sea → Sea',
                subtitle: 'Navigate directly between two sea points',
                onTap: () {
                  Navigator.pop(ctx);
                  _startSeaToSeaMode();
                },
              ),
              const SizedBox(height: 8),
              _NavModeOption(
                icon: Icons.home,
                title: 'Return: Sea → Port → Land',
                subtitle: 'Return from sea, dock at a port, navigate home',
                onTap: () {
                  Navigator.pop(ctx);
                  _startSeaToLandMode();
                },
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _startLandToSeaMode() {
    setState(() {
      _navMode = _NavMode.landToSea;
      _showPortSelection = true;
      _currentRoute = null;
      _selectedPort = null;
      _seaDestination = null;
      _customLandOrigin = null;
    });
  }

  void _startSeaToSeaMode() {
    setState(() {
      _navMode = _NavMode.seaToSea;
      _showPortSelection = false;
      _currentRoute = null;
      _seaOrigin = null;
      _seaDestination = null;
    });
    _showMessage('Tap your departure point on the sea', Colors.blue);
  }

  void _startSeaToLandMode() {
    setState(() {
      _navMode = _NavMode.seaToLand;
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
      if (_navMode == _NavMode.landToSea) {
        _returnPort = port; // save for possible return trip
      }
    });
    _showMessage('Port selected: ${port.name}', Colors.blue);

    // Trigger route calculation when all inputs are ready
    if (_navMode == _NavMode.landToSea && _seaDestination != null) {
      _calculatePortToSeaRoute();
    } else if (_navMode == _NavMode.seaToLand &&
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

      final route = NavigationRoute(
        id: 'route_${DateTime.now().millisecondsSinceEpoch}',
        origin: _seaOrigin!,
        destination: _seaDestination!,
        geometry: marineSegment.geometry,
        segments: [marineSegment],
        waypoints: [],
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
        waypoints: [],
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

      // Center on current location
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

  Future<void> _handleSaveMask() async {
    final success = await _navigationMask.saveChanges();
    if (success) {
      _showMessage('Mask saved successfully', Colors.green);
      setState(() {});
    } else {
      _showMessage('Failed to save mask', Colors.red);
    }
  }

  Future<void> _handleResetMask() async {
    final l10n = AppLocalizations.of(context)!;
    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(l10n.resetMask),
        content: Text(l10n.resetMaskConfirmation),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: Text(l10n.cancel),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: Text(l10n.reset, style: const TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );

    if (confirm == true) {
      final success = await _navigationMask.resetToOriginal();
      if (success) {
        setState(() {
          _paintedCells.clear();
        });
        _showMessage(l10n.maskResetToOriginal, Colors.green);
      } else {
        _showMessage(l10n.failedToResetMask, Colors.red);
      }
    }
  }

  void _exitAdminEditMode() {
    setState(() {
      _layerManager.isAdminEditMode = false;
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

        // AIS vessels with projected paths
        AisVesselLayer(
          service: _aisService,
          isVisible: true,
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

        // Feature drawing layer (feature edit mode)
        if (_layerManager.isFeatureEditMode)
          FeatureDrawingLayer(
            editState: _featureEditState,
          ),

        // Marina markers
        if (_marinaService.isInitialized && _showMarinas)
          MarinaMarkerLayer(
            marinas: _marinaService.getAllMarinas(),
            highlightedMarinaId: _selectedMarina?.id,
            onMarinaTapped: _handleMarinaTapped,
          ),

        // Route visualization (show active segment if navigating)
        if (_currentRoute != null)
          RoutePolylineLayer(
            route: _currentRoute!,
            activeSegmentIndex: _navigationManager?.session?.currentSegmentIndex,
            showMarkers: true,
          ),

        // Breadcrumb trail (during active navigation)
        if (_navigationManager?.session != null &&
            _navigationManager!.session!.breadcrumbs.length > 1)
          PolylineLayer(
            polylines: [
              Polyline(
                points: _navigationManager!.session!.breadcrumbs,
                strokeWidth: 3.0,
                color: Colors.purple.withValues(alpha: 0.6),
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

        // Port markers (visible when port selection is active or a port is selected)
        if (_showPortSelection || _selectedPort != null || _navMode == _NavMode.seaToLand)
          MarkerLayer(
            markers: _availablePorts.map((port) {
              final isSelected = _selectedPort?.id == port.id;
              return Marker(
                point: port.location,
                width: 60,
                height: 80,
                child: GestureDetector(
                  onTap: () => _handlePortSelected(port),
                  child: Column(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(10),
                        decoration: BoxDecoration(
                          color: isSelected ? Colors.green : Colors.deepPurple,
                          shape: BoxShape.circle,
                          border: Border.all(
                            color: Colors.white,
                            width: isSelected ? 3 : 2,
                          ),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withValues(alpha: 0.4),
                              blurRadius: 6,
                            ),
                          ],
                        ),
                        child: const Icon(
                          Icons.anchor,
                          color: Colors.white,
                          size: 24,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(4),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withValues(alpha: 0.3),
                              blurRadius: 4,
                            ),
                          ],
                        ),
                        child: Text(
                          port.name.split(' ').first, // Show first word
                          style: const TextStyle(
                            fontSize: 10,
                            fontWeight: FontWeight.bold,
                          ),
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

        // User location marker
        if (_locationData != null)
          MarkerLayer(
            markers: [_buildUserLocationMarker()],
          ),
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

  Widget _buildNavigationStatusIndicator(AppLocalizations l10n) {
    final ready = _maskInitialized;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
      decoration: BoxDecoration(
        color: ready ? Colors.green.shade600 : Colors.grey.shade500,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.2),
            blurRadius: 4,
            offset: const Offset(0, 1),
          ),
        ],
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 6,
            height: 6,
            decoration: const BoxDecoration(
              color: Colors.white,
              shape: BoxShape.circle,
            ),
          ),
          const SizedBox(width: 6),
          Text(
            ready ? l10n.navigationReady : l10n.loading,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 11,
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMapIconButton({
    required IconData icon,
    required String tooltip,
    VoidCallback? onPressed,
    bool isActive = false,
    Color activeColor = Colors.blue,
  }) {
    final iconColor = onPressed == null
        ? Colors.grey.shade400
        : isActive
            ? activeColor
            : Colors.blueGrey.shade700;
    return Tooltip(
      message: tooltip,
      child: InkWell(
        onTap: onPressed,
        borderRadius: BorderRadius.circular(8),
        child: SizedBox(
          width: 44,
          height: 44,
          child: Center(
            child: Icon(icon, size: 22, color: iconColor),
          ),
        ),
      ),
    );
  }

  Widget _buildButtonGroup(List<Widget> buttons) {
    final children = <Widget>[];
    for (int i = 0; i < buttons.length; i++) {
      children.add(buttons[i]);
      if (i < buttons.length - 1) {
        children.add(Divider(
          height: 1,
          thickness: 0.5,
          color: Colors.grey.shade200,
        ));
      }
    }
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.15),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(12),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: children,
        ),
      ),
    );
  }

  Widget _buildStepChip(IconData icon, String label) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 4),
      decoration: BoxDecoration(
        color: Colors.green.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(4),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 13, color: Colors.green),
          const SizedBox(width: 4),
          Text(label, style: const TextStyle(fontSize: 11, color: Colors.green)),
        ],
      ),
    );
  }

  Widget _buildZoomControls() {
    return _buildButtonGroup([
      _buildMapIconButton(
        icon: Icons.add,
        tooltip: 'Zoom in',
        onPressed: _mapReady
            ? () => _mapController.move(
                  _mapController.camera.center,
                  _mapController.camera.zoom + 1,
                )
            : null,
      ),
      _buildMapIconButton(
        icon: Icons.remove,
        tooltip: 'Zoom out',
        onPressed: _mapReady
            ? () => _mapController.move(
                  _mapController.camera.center,
                  _mapController.camera.zoom - 1,
                )
            : null,
      ),
      _buildMapIconButton(
        icon: Icons.my_location,
        tooltip: 'My location',
        onPressed: _mapReady && _locationData != null
            ? () => _mapController.move(
                  LatLng(
                    _locationData!.latitude ?? MapConstants.defaultLatitude,
                    _locationData!.longitude ?? MapConstants.defaultLongitude,
                  ),
                  14,
                )
            : null,
      ),
    ]);
  }

  // ============================================================
  // Main Build Method
  // ============================================================


  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;

    return Scaffold(
      body: Stack(
        children: [
          // Main map with gesture detector for admin painting
          GestureDetector(
            behavior: _layerManager.isAdminEditMode ||
                    _layerManager.isFeatureEditMode ||
                    _isOutlineEditMode
                ? HitTestBehavior.opaque
                : HitTestBehavior.translucent,
            onTapDown: _layerManager.isAdminEditMode
                ? (details) {
                    final latLng = _screenToLatLng(details.localPosition);
                    if (latLng != null) _handleAdminPaint(latLng);
                  }
                : _isOutlineEditMode
                    ? (details) {
                        final latLng =
                            _screenToLatLng(details.localPosition);
                        if (latLng != null) _handleOutlinePaint(latLng);
                      }
                    : null,
            onPanStart: _layerManager.isAdminEditMode
                ? (details) {
                    final latLng = _screenToLatLng(details.localPosition);
                    if (latLng != null) _handleAdminPaint(latLng);
                  }
                : _isOutlineEditMode
                    ? (details) {
                        final latLng =
                            _screenToLatLng(details.localPosition);
                        if (latLng != null) _handleOutlinePaint(latLng);
                      }
                    : null,
            onPanUpdate: _layerManager.isAdminEditMode
                ? (details) {
                    final latLng = _screenToLatLng(details.localPosition);
                    if (latLng != null) _handleAdminPaint(latLng);
                  }
                : _isOutlineEditMode
                    ? (details) {
                        final latLng =
                            _screenToLatLng(details.localPosition);
                        if (latLng != null) _handleOutlinePaint(latLng);
                      }
                    : null,
            onPanEnd: _isOutlineEditMode
                ? (_) => setState(() => _outlinePaintPreview = null)
                : null,
            child: _buildMap(),
          ),

          // Navigation status indicator (top right)
          Positioned(
            top: 50,
            right: 10,
            child: _buildNavigationStatusIndicator(l10n),
          ),

          // Layer controls panel (top left, when visible)
          ListenableBuilder(
            listenable: _layerManager,
            builder: (context, _) {
              if (_layerManager.showLayerControls) {
                return Positioned(
                  top: 10,
                  left: 10,
                  child: LayerControlPanel(
                    layerManager: _layerManager,
                    geoJsonBuilder: _geoJsonBuilder,
                    maskInitialized: _maskInitialized,
                    onClose: () => _layerManager.showLayerControls = false,
                    onEnterAdminEdit: _enterAdminEditMode,
                    onEnterFeatureEdit: _enterFeatureEditMode,
                    onEnterOutlineEdit: _enterOutlineEditMode,
                    onOpenPrediction: () => Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) => const PredictionScreen(),
                      ),
                    ),
                  ),
                );
              }
              return const SizedBox.shrink();
            },
          ),

          // Admin edit toolbar (when in edit mode)
          ListenableBuilder(
            listenable: _layerManager,
            builder: (context, _) {
              if (_layerManager.isAdminEditMode && _maskInitialized) {
                return Positioned(
                  top: 50,
                  left: 10,
                  child: AdminEditToolbar(
                    layerManager: _layerManager,
                    navigationMask: _navigationMask,
                    onSave: _handleSaveMask,
                    onReset: _handleResetMask,
                    onClose: _exitAdminEditMode,
                    onZoomIn: () {
                      _mapController.move(
                        _mapController.camera.center,
                        _mapController.camera.zoom + 1,
                      );
                    },
                    onZoomOut: () {
                      _mapController.move(
                        _mapController.camera.center,
                        _mapController.camera.zoom - 1,
                      );
                    },
                  ),
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
          ListenableBuilder(
            listenable: _featureEditState,
            builder: (context, _) {
              if (_layerManager.isFeatureEditMode) {
                return Positioned(
                  top: 50,
                  left: 10,
                  child: FeatureEditToolbar(
                    editState: _featureEditState,
                    onClose: _exitFeatureEditMode,
                    onStartAdd: (type) {
                      _featureEditState.startAddFeature(type);
                    },
                    onStartSelect: () {
                      _featureEditState.startSelectMode();
                    },
                    onConfirmDrawing: _confirmAndSaveDrawing,
                    onCancelDrawing: () {
                      _featureEditState.cancelDrawing();
                    },
                    onUndoVertex: () {
                      _featureEditState.undoLastVertex();
                    },
                    onMoveFeature: () {
                      _featureEditState.startMoveFeature();
                    },
                    onDeleteFeature: _deleteSelectedFeature,
                  ),
                );
              }
              return const SizedBox.shrink();
            },
          ),

          // Left toolbar (layers, legend, navigate) — hidden during edit modes
          ListenableBuilder(
            listenable: _layerManager,
            builder: (context, _) {
              if (_layerManager.isAdminEditMode ||
                  _layerManager.isFeatureEditMode ||
                  _isOutlineEditMode) {
                return const SizedBox.shrink();
              }
              return Positioned(
                top: 90,
                left: 12,
                child: Column(
                  children: [
                    _buildButtonGroup([
                      _buildMapIconButton(
                        icon: _layerManager.showLayerControls
                            ? Icons.layers
                            : Icons.layers_outlined,
                        tooltip: 'Layers',
                        onPressed: () => _layerManager.showLayerControls =
                            !_layerManager.showLayerControls,
                        isActive: _layerManager.showLayerControls,
                      ),
                      _buildMapIconButton(
                        icon: _showDepthLegend
                            ? Icons.legend_toggle
                            : Icons.legend_toggle_outlined,
                        tooltip: 'Depth legend',
                        onPressed: () =>
                            setState(() => _showDepthLegend = !_showDepthLegend),
                        isActive: _showDepthLegend,
                      ),
                    ]),
                    const SizedBox(height: 8),
                    _buildButtonGroup([
                      _buildMapIconButton(
                        icon: _currentRoute != null || _navMode != null
                            ? Icons.close
                            : Icons.directions_boat_outlined,
                        tooltip: _currentRoute != null
                            ? 'Clear route'
                            : _navMode != null
                                ? 'Cancel navigation'
                                : 'Navigate',
                        onPressed: _maskInitialized
                            ? () {
                                if (_currentRoute != null || _navMode != null) {
                                  _clearRoute();
                                } else {
                                  _openNavModeSelection();
                                }
                              }
                            : null,
                        isActive: _currentRoute != null || _navMode != null,
                        activeColor: Colors.orange,
                      ),
                    ]),
                  ],
                ),
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

          // Route stats card (when route is calculated but not navigating)
          if (_currentRoute != null && !(_navigationManager?.isNavigating ?? false))
            Positioned(
              bottom: 80,
              left: 16,
              right: 16,
              child: RouteStatsCard(
                route: _currentRoute!,
                onCancel: _clearRoute,
                onStartNavigation: _startNavigation,
              ),
            ),

          // Active navigation overlay (when navigating)
          if (_navigationManager?.session != null)
            ActiveNavigationOverlay(
              session: _navigationManager!.session!,
              onEndNavigation: _endNavigation,
              onRecenter: _recenterOnLocation,
              isRecalculating: _navigationManager!.isRecalculating,
            ),

          // Navigation instructions panel (shown during any active nav mode)
          if (_navMode != null && _currentRoute == null)
            Positioned(
              top: 90,
              left: 68,
              right: 16,
              child: Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(8),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withValues(alpha: 0.3),
                      blurRadius: 6,
                    ),
                  ],
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Row(
                      children: [
                        const Icon(Icons.info_outline, size: 16, color: Colors.blue),
                        const SizedBox(width: 6),
                        Text(
                          _navMode == _NavMode.seaToSea
                              ? 'Sea → Sea'
                              : _navMode == _NavMode.seaToLand
                                  ? 'Return: Sea → Port → Land'
                                  : 'Land → Port → Sea',
                          style: const TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 14,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    // Dynamic step instruction
                    Text(
                      _navMode == _NavMode.seaToSea
                          ? _seaOrigin == null
                              ? '1. Tap your departure point on the sea'
                              : _seaDestination == null
                                  ? '2. Tap your sea destination'
                                  : l10n.calculatingRoute
                          : _navMode == _NavMode.seaToLand
                              ? _seaToLandOrigin == null
                                  ? '1. Tap your sea departure point'
                                  : _selectedPort == null
                                      ? '2. Tap a port (anchor icon) to dock at'
                                      : _customLandDestination == null
                                          ? '3. Tap your land destination'
                                          : l10n.calculatingRoute
                              // landToSea
                              : _selectedPort == null
                                  ? '1. Tap a port (anchor icon)\n2. Tap sea destination\n(Tap land to change your start location)'
                                  : _seaDestination == null
                                      ? '2. Tap your sea destination'
                                      : l10n.calculatingRoute,
                      style: const TextStyle(fontSize: 12),
                    ),
                    // Confirmed steps summary
                    if (_navMode == _NavMode.landToSea && _customLandOrigin != null) ...[
                      const SizedBox(height: 6),
                      _buildStepChip(Icons.location_on, 'Custom origin set'),
                    ],
                    if (_seaOrigin != null && _navMode == _NavMode.seaToSea) ...[
                      const SizedBox(height: 6),
                      _buildStepChip(Icons.radio_button_checked, 'Departure set'),
                    ],
                    if (_seaToLandOrigin != null && _navMode == _NavMode.seaToLand) ...[
                      const SizedBox(height: 6),
                      _buildStepChip(Icons.radio_button_checked, 'Sea departure set'),
                    ],
                    if (_selectedPort != null) ...[
                      const SizedBox(height: 6),
                      _buildStepChip(Icons.anchor, 'Port: ${_selectedPort!.name}'),
                    ],
                    if (_returnPort != null && _navMode == _NavMode.seaToLand && _selectedPort == null) ...[
                      const SizedBox(height: 6),
                      _buildStepChip(Icons.history, 'Last port: ${_returnPort!.name} (tap to reuse)'),
                    ],
                    if (_customLandDestination != null) ...[
                      const SizedBox(height: 6),
                      _buildStepChip(Icons.home, 'Land destination set'),
                    ],
                  ],
                ),
              ),
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

          // AIS collision alert
          if (_topCpaAlert != null && !_aisAlertDismissed)
            AisCollisionAlert(
              cpa: _topCpaAlert!,
              onDismiss: () => setState(() => _aisAlertDismissed = true),
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

          // Route calculation loading indicator
          if (_isCalculatingRoute)
            Positioned.fill(
              child: Container(
                color: Colors.black.withValues(alpha: 0.5),
                child: Center(
                  child: Card(
                    child: Padding(
                      padding: const EdgeInsets.all(20),
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          const CircularProgressIndicator(),
                          const SizedBox(height: 16),
                          Text(
                            l10n.calculatingRoute,
                            style: const TextStyle(fontSize: 16),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
            ),

          // Offline indicator banner (top centre)
          if (!ConnectivityService.instance.isOnline)
            Positioned(
              top: 8,
              left: 0,
              right: 0,
              child: Center(
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 5),
                  decoration: BoxDecoration(
                    color: Colors.red.shade700.withValues(alpha: 0.92),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: const Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(Icons.wifi_off, color: Colors.white, size: 14),
                      SizedBox(width: 6),
                      Text('Offline — map tiles cached',
                          style: TextStyle(color: Colors.white, fontSize: 12)),
                    ],
                  ),
                ),
              ),
            ),

          // Zoom controls (bottom right)
          Positioned(
            bottom: 16,
            right: 16,
            child: _buildZoomControls(),
          ),
        ],
      ),
    );
  }
}

/// Navigation mode
enum _NavMode { landToSea, seaToSea, seaToLand }

/// Option tile used in the nav-mode bottom sheet
class _NavModeOption extends StatelessWidget {
  final IconData icon;
  final String title;
  final String subtitle;
  final VoidCallback onTap;

  const _NavModeOption({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
        decoration: BoxDecoration(
          border: Border.all(color: Colors.grey.shade300),
          borderRadius: BorderRadius.circular(12),
        ),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: Colors.blue.shade50,
                shape: BoxShape.circle,
              ),
              child: Icon(icon, color: Colors.blue.shade700, size: 22),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(title,
                      style: const TextStyle(
                          fontWeight: FontWeight.w600, fontSize: 14)),
                  const SizedBox(height: 2),
                  Text(subtitle,
                      style: TextStyle(
                          fontSize: 12, color: Colors.grey.shade600)),
                ],
              ),
            ),
            Icon(Icons.chevron_right, color: Colors.grey.shade400),
          ],
        ),
      ),
    );
  }
}

/// Port point for marine navigation
class PortPoint {
  final String id;
  final String name;
  final LatLng location;
  final String description;
  final List<String> facilities;

  const PortPoint({
    required this.id,
    required this.name,
    required this.location,
    required this.description,
    this.facilities = const [],
  });
}

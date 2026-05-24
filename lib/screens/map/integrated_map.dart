import 'dart:async';
import 'dart:convert';
import 'dart:developer';
import 'dart:math' as math;
import 'package:bahaar/constants/app_colors.dart';
import 'package:bahaar/l10n/map/map_localizations.dart';
import 'package:bahaar/models/map/navigation/marina_model.dart';
import 'package:bahaar/models/map/navigation/navigation_session_model.dart';
import 'package:bahaar/models/map/navigation/route_model.dart';
import 'package:bahaar/models/map/navigation/waypoint_model.dart';
import 'package:bahaar/models/weather/marine_weather_model.dart';
import 'package:bahaar/services/celestial_navigation/celestial_fix_notifier.dart';
import 'package:bahaar/screens/map/celestial_navigation/celestial_navigation_screen.dart';
import 'package:bahaar/screens/fish_recognition/prediction_screen.dart';
import 'package:bahaar/services/fish_recognition/fish_probability_service.dart';
import 'package:bahaar/services/fishing_log/trip_service.dart';
import 'package:bahaar/services/map/hybrid_route_coordinator.dart';
import 'package:bahaar/services/map/map_layer_manager.dart';
import 'package:bahaar/services/map/marina_data_service.dart';
import 'package:bahaar/services/map/marine_pathfinding_service.dart';
import 'package:bahaar/services/map/navigation_mask.dart';
import 'package:bahaar/services/map/navigation_session_manager.dart';
import 'package:bahaar/services/map/osrm_routing_service.dart';
import 'package:bahaar/services/weather/marine_weather_service.dart';
import 'package:bahaar/services/offline/connectivity_service.dart';
import 'package:bahaar/utilities/map/celestial_navigation/geometry_utils.dart';
import 'package:bahaar/utilities/map/map_constants.dart';
import 'package:bahaar/screens/fishing_log/trip_detail_screen.dart';
import 'package:bahaar/widgets/map/bahaar_overlay_layer.dart';
import 'package:bahaar/widgets/map/celestial_fix_overlay.dart';
import 'package:bahaar/widgets/map/trip_track_layer.dart';
import 'package:bahaar/widgets/map/depth_soundings_layer.dart';
import 'package:bahaar/widgets/map/enhanced_depth_layer.dart';
import 'package:bahaar/widgets/map/fish_probability_layer.dart';
import 'package:bahaar/widgets/map/geojson_layers.dart';
import 'package:bahaar/widgets/map/layer_control_panel.dart';
import 'package:bahaar/widgets/map/sos_button.dart';
import 'package:bahaar/widgets/map/territorial_mask_layer.dart';
import 'package:bahaar/models/map/nav_mode.dart';
import 'package:bahaar/models/map/port_point.dart';
import 'package:bahaar/widgets/map/map_left_toolbar.dart';
import 'package:bahaar/widgets/map/nav_instructions_panel.dart';
import 'package:bahaar/widgets/map/nav_mode_option.dart';
import 'package:bahaar/widgets/map/navigation_status_indicator.dart';
import 'package:bahaar/widgets/map/offline_banner.dart';
import 'package:bahaar/widgets/map/route_calculating_overlay.dart';
import 'package:bahaar/widgets/map/zoom_controls.dart';
import 'package:bahaar/widgets/map/navigation/active_navigation_overlay.dart';
import 'package:bahaar/widgets/map/navigation/marina_marker_layer.dart';
import 'package:bahaar/widgets/map/navigation/route_polyline_layer.dart';
import 'package:bahaar/widgets/map/navigation/weather_alert_overlay.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:latlong2/latlong.dart';
import 'package:location/location.dart';
import 'package:flutter_map/flutter_map.dart';

part 'map_init.dart';
part 'map_routing.dart';
part 'map_navigation.dart';
part 'map_builders.dart';

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
  bool _routingInitialized = false;
  NavigationSessionManager? _navigationManager;

  Map<String, dynamic>? _rawAssetGeoJson;

  // Weather state
  List<WeatherSafetyAssessment> _activeWeatherWarnings = [];
  bool _weatherAlertDismissed = false;

  // Map state
  bool _mapReady = false;
  bool _serviceEnabled = false;
  PermissionStatus _permissionStatus = PermissionStatus.denied;
  LocationData? _locationData;
  StreamSubscription<LocationData>? _locationSubscription;
  bool _maskInitialized = false;
  bool _showDepthLegend = false;
  double _currentZoom = MapConstants.defaultZoom;
  String? _outsideMaskWarning;
  bool _outsideMaskWarningDismissed = false;

  // GeoJSON / MPA data
  GeoJsonLayerBuilder? _geoJsonBuilder;
  List<Map<String, dynamic>> _mpaPolygons = [];

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

  // Ports
  List<PortPoint> _availablePorts = [];
  PortPoint? _selectedPort;
  LatLng? _seaDestination;
  bool _showPortSelection = false;

  // Navigation mode
  NavMode? _navMode;
  LatLng? _seaOrigin;
  LatLng? _seaToLandOrigin;
  LatLng? _customLandDestination;
  PortPoint? _returnPort;
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
    _loadMpaPolygons();
    _loadSeaports();
    _initMarinas();
    _initRoutingServices();

    final tripUid = FirebaseAuth.instance.currentUser?.uid;
    TripService.instance.initialize(uid: tripUid).then((_) {
      TripService.instance.syncPendingToFirestore();
    });

    ConnectivityService.instance.onConnectivityChanged.listen((online) {
      if (online) TripService.instance.syncPendingToFirestore();
    });
  }

  @override
  void dispose() {
    _locationSubscription?.cancel();
    _navigationManager?.removeListener(_onNavigationUpdate);
    _navigationManager?.dispose();
    _fishProbabilityService.dispose();
    _layerManager.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    super.build(context);
    final l10n = MapLocalizations.of(context);
    return Scaffold(
      body: Stack(children: _buildStackChildren(l10n)),
    );
  }
}

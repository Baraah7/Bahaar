part of 'integrated_map.dart';

extension _IntegratedMapInit on _IntegratedMapState {
  Future<void> _initRoutingServices() async {
    try {
      final deadline = DateTime.now().add(const Duration(seconds: 20));
      while (!_maskInitialized || !_marinaService.isInitialized || _geoJsonBuilder == null) {
        if (DateTime.now().isAfter(deadline)) {
          log('Routing init timed out — mask:$_maskInitialized marina:${_marinaService.isInitialized} geoJson:${_geoJsonBuilder != null}');
          return;
        }
        await Future.delayed(const Duration(milliseconds: 100));
      }

      _weatherService = MarineWeatherService();
      await _weatherService.initialize();
      log('Weather service initialized');

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
      _navigationManager = NavigationSessionManager(
        location: _location,
        routeCoordinator: _routeCoordinator,
        weatherService: _weatherService,
      );

      _navigationManager!.addListener(_onNavigationUpdate);

      _routingInitialized = true;
      log('Routing services initialized successfully');
    } catch (e) {
      log('Error initializing routing services: $e');
    }
  }

  Future<void> _initNavigationMask() async {
    try {
      await _navigationMask.initialize();
      if (mounted) {
        setState(() => _maskInitialized = true);
        log('Navigation mask initialized successfully');
      }
    } catch (e) {
      log('Error initializing navigation mask: $e');
    }
  }

  Future<void> _initMarinas() async {
    try {
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
      }

      _locationSubscription = _location.onLocationChanged.listen((data) {
        if (!mounted) return;
        setState(() => _locationData = data);
      });
    } catch (e) {
      log('Error getting location: $e');
      if (mounted) setState(() {});
    }
  }

  Future<void> _loadSeaports() async {
    try {
      final String jsonString = await rootBundle.loadString('assets/data/seaports.json');
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

  Future<void> _loadMpaPolygons() async {
    try {
      final raw = await rootBundle.loadString('assets/data/protected-areas.json');
      final list = jsonDecode(raw) as List;
      if (mounted) setState(() => _mpaPolygons = list.cast<Map<String, dynamic>>());
    } catch (e) {
      log('Failed to load MPA polygons: $e');
    }
  }

  Future<void> _loadGeoJson() async {
    try {
      final String jsonString = await rootBundle.loadString(
        'assets/data/gulf_test_features.geojson',
      );
      final data = json.decode(jsonString) as Map<String, dynamic>;
      _rawAssetGeoJson = data;
      if (mounted) {
        setState(() {
          _geoJsonBuilder = GeoJsonLayerBuilder(data);
        });
      }
      log('GeoJSON loaded successfully');
    } catch (e) {
      log('Error loading GeoJSON: $e');
      if (mounted) {
        setState(() {
          _geoJsonBuilder = GeoJsonLayerBuilder({'type': 'FeatureCollection', 'features': []});
        });
      }
    }
  }

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
}

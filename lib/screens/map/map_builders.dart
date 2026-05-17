part of 'integrated_map.dart';

extension _IntegratedMapBuilders on _IntegratedMapState {
  Widget _buildMap() {
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
          if (hasGesture && _isFollowingNavigation) {
            setState(() => _isFollowingNavigation = false);
          }
        },
      ),
      children: [
        if (_layerManager.showBaseMap)
          TileLayer(
            urlTemplate: MapConstants.osmBaseUrl,
            userAgentPackageName: MapConstants.userAgent,
            maxZoom: MapConstants.osmMaxZoom.toDouble(),
            subdomains: MapConstants.osmSubdomains,
          ),

        if (_layerManager.showDepthSoundings)
          const DepthSoundingsLayer(),

        ListenableBuilder(
          listenable: _layerManager,
          builder: (context, _) => EnhancedDepthLayer(
            isVisible: _layerManager.showDepthLayer,
            opacity: _layerManager.depthLayerOpacity,
            visualizationType: _layerManager.depthVisualizationType,
          ),
        ),

        if (_geoJsonBuilder != null)
          ListenableBuilder(
            listenable: _layerManager,
            builder: (context, _) {
              if (!_layerManager.showProtectedZones) return const SizedBox.shrink();
              return GeoJsonMapLayers(builder: _geoJsonBuilder!, showProtectedZones: true);
            },
          ),

        if (_fishProbabilityService.isInitialized)
          ListenableBuilder(
            listenable: _layerManager,
            builder: (context, _) {
              if (!_layerManager.showFishProbabilityHeatmap) return const SizedBox.shrink();
              return FishProbabilityLayer(
                service: _fishProbabilityService,
                selectedSpecies: _layerManager.selectedSpecies,
                currentZoom: _currentZoom,
              );
            },
          ),

        if (_currentRoute != null)
          RoutePolylineLayer(
            route: _currentRoute!,
            activeSegmentIndex: _navigationManager?.session?.currentSegmentIndex,
            showMarkers: true,
            userLocation: _navigationManager?.isNavigating == true
                ? _navigationManager?.session?.currentLocation
                : null,
          ),

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

        if (_originPoint != null && _currentRoute == null)
          MarkerLayer(markers: [_pinMarker(_originPoint!, Colors.green, Icons.radio_button_checked)]),

        if (_destinationPoint != null && _currentRoute == null)
          MarkerLayer(markers: [_pinMarker(_destinationPoint!, Colors.red, Icons.place)]),

        if (_seaDestination != null && _currentRoute == null)
          MarkerLayer(markers: [_pinMarker(_seaDestination!, Colors.blue, Icons.place)]),

        if (_seaOrigin != null && _currentRoute == null)
          MarkerLayer(markers: [_pinMarker(_seaOrigin!, Colors.teal, Icons.radio_button_checked)]),

        if (_seaToLandOrigin != null && _currentRoute == null)
          MarkerLayer(markers: [_pinMarker(_seaToLandOrigin!, Colors.teal, Icons.directions_boat, size: 22)]),

        if (_customLandOrigin != null && _currentRoute == null)
          MarkerLayer(markers: [_pinMarker(_customLandOrigin!, Colors.orange, Icons.home, size: 22)]),

        if (_customLandDestination != null && _currentRoute == null)
          MarkerLayer(markers: [_pinMarker(_customLandDestination!, Colors.deepOrange, Icons.home, size: 22)]),

        if (!(_navigationManager?.isNavigating ?? false) &&
            (_showPortSelection || _selectedPort != null || _navMode == NavMode.seaToLand))
          MarkerLayer(markers: _buildPortMarkers()),

        ListenableBuilder(
          listenable: _layerManager,
          builder: (context, _) {
            final showMpa = _layerManager.showProtectedZones;
            final showSpots = _layerManager.showFishingSpots;
            if (!showMpa && !showSpots) return const SizedBox.shrink();
            return BahaarOverlayLayer(
              onGetPrediction: _navigateToPrediction,
              showMpaCircles: showMpa,
              showSpots: showSpots,
            );
          },
        ),

        if (TripService.instance.hasActiveTrip)
          CatchMarkerLayer(catches: TripService.instance.activeTrip!.catches),

        if (_locationData != null && !(_navigationManager?.isNavigating ?? false))
          MarkerLayer(markers: [_buildUserLocationMarker()]),

        if (_navigationManager?.isNavigating == true &&
            _navigationManager?.session?.currentLocation != null)
          MarkerLayer(markers: [_buildNavigationArrowMarker()]),

        const CelestialFixLayer(),
        const TripTrackLayer(),
      ],
    );
  }

  List<Widget> _buildStackChildren(MapLocalizations l10n) {
    return [
      _buildMap(),

      if (!(_navigationManager?.isNavigating ?? false))
        Positioned(
          top: 50,
          right: 10,
          child: NavigationStatusIndicator(isReady: _maskInitialized, l10n: l10n),
        ),

      ListenableBuilder(
        listenable: _layerManager,
        builder: (context, _) {
          if (!_layerManager.showLayerControls) return const SizedBox.shrink();
          return Stack(
            children: [
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
                  onOpenPrediction: () => Navigator.push(
                    context,
                    MaterialPageRoute(builder: (_) => const PredictionScreen()),
                  ),
                ),
              ),
            ],
          );
        },
      ),

      ListenableBuilder(
        listenable: _layerManager,
        builder: (context, _) => MapLeftToolbar(
          showLayerControls: _layerManager.showLayerControls,
          showDepthLegend: _showDepthLegend,
          depthLayerEnabled: _layerManager.showDepthLayer,
          hasRoute: _currentRoute != null,
          hasNavMode: _navMode != null,
          maskInitialized: _maskInitialized,
          celestialFixActive: CelestialFixNotifier.instance.fix != null,
          isNavigating: _navigationManager?.isNavigating ?? false,
          onToggleLayers: () =>
              _layerManager.showLayerControls = !_layerManager.showLayerControls,
          onToggleLegend: () {
            if (!_layerManager.showDepthLayer) {
              ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
                content: Text(
                    'Turn on Depth Visualization in the Layers panel to use the depth legend.'),
                duration: Duration(seconds: 3),
                behavior: SnackBarBehavior.floating,
                margin: EdgeInsets.only(bottom: 80, left: 12, right: 12),
              ));
              return;
            }
            setState(() => _showDepthLegend = !_showDepthLegend);
          },
          onOpenCelestial: () => Navigator.push(
            context,
            MaterialPageRoute(builder: (_) => const CelestialNavigationScreen()),
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
        ),
      ),

      if (_showDepthLegend && _layerManager.showDepthLayer)
        Positioned(bottom: 110, left: 12, child: DepthLegend()),

      if (_selectedMarina != null && _currentRoute == null)
        Positioned(
          bottom: 80,
          left: 16,
          right: 16,
          child: MarinaInfoCard(
            marina: _selectedMarina!,
            onClose: () => setState(() => _selectedMarina = null),
            onNavigate: () => _calculateRoute(_selectedMarina!.location),
          ),
        ),

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

      if (_activeWeatherWarnings.isNotEmpty && !_weatherAlertDismissed)
        WeatherAlertOverlay(
          warnings: _activeWeatherWarnings,
          onDismiss: () => setState(() => _weatherAlertDismissed = true),
        ),

      const CelestialSpoofingAlert(),

      if (_isCalculatingRoute)
        RouteCalculatingOverlay(label: l10n.calculatingRoute),

      if (!ConnectivityService.instance.isOnline)
        OfflineBanner(label: l10n.offlineMapCached),

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

      if (!(_navigationManager?.isNavigating ?? false))
        const Positioned(bottom: 16, left: 16, child: SosButton()),

      if (!(_navigationManager?.isNavigating ?? false))
        Positioned(
          bottom: 16,
          right: 16,
          child: MapZoomControls(
            onZoomIn: _mapReady
                ? () => _mapController.move(
                      _mapController.camera.center, _mapController.camera.zoom + 1)
                : null,
            onZoomOut: _mapReady
                ? () => _mapController.move(
                      _mapController.camera.center, _mapController.camera.zoom - 1)
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
            onLogCatch: TripService.instance.hasActiveTrip ? _logCatchFromMap : null,
          ),
        ),
    ];
  }

  // ── Marker builders ───────────────────────────────────────────

  Marker _pinMarker(LatLng point, Color color, IconData icon, {double size = 24}) {
    return Marker(
      point: point,
      width: 40,
      height: 40,
      child: Container(
        decoration: BoxDecoration(
          color: color,
          shape: BoxShape.circle,
          border: Border.all(color: Colors.white, width: 3),
        ),
        child: Icon(icon, color: Colors.white, size: size),
      ),
    );
  }

  List<Marker> _buildPortMarkers() {
    return _availablePorts.map((port) {
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
                  border: Border.all(color: Colors.white, width: isSelected ? 2.5 : 1.5),
                  boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.4), blurRadius: 4)],
                ),
                child: const Icon(Icons.anchor, color: Colors.white, size: 16),
              ),
              const SizedBox(height: 2),
              Container(
                constraints: const BoxConstraints(maxWidth: 52),
                padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 1),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(3),
                  boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.3), blurRadius: 3)],
                ),
                child: Text(
                  port.name.split(' ').first,
                  style: const TextStyle(fontSize: 8, fontWeight: FontWeight.bold),
                  overflow: TextOverflow.ellipsis,
                  maxLines: 1,
                ),
              ),
            ],
          ),
        ),
      );
    }).toList();
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
        shadows: const [Shadow(color: Colors.black54, blurRadius: 4)],
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
            boxShadow: const [BoxShadow(color: Colors.black38, blurRadius: 4, offset: Offset(0, 2))],
          ),
          child: const Icon(Icons.navigation, color: Colors.white, size: 26),
        ),
      ),
    );
  }

  // ── Navigation helpers ────────────────────────────────────────

  void _navigateToPrediction(LatLng latLng, String speciesId) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => PredictionScreen(initialLatLng: latLng, initialSpeciesId: speciesId),
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

    LatLng? loc = result.location;
    if (loc == null && _locationData?.latitude != null && _locationData?.longitude != null) {
      loc = LatLng(_locationData!.latitude!, _locationData!.longitude!);
    }
    if (loc == null) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
        content: Text('تعذّر تحديد الموقع — يرجى تفعيل GPS أو تحديد الموقع يدوياً'),
        backgroundColor: Colors.red,
      ));
      return;
    }

    if (_maskInitialized && !_navigationMask.isNavigable(loc.longitude, loc.latitude)) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
        content: Text('يجب تسجيل الصيدة في البحر'),
        backgroundColor: Colors.red,
      ));
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
      setState(() {});
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
        content: Text('تم تسجيل الصيدة بنجاح'),
        backgroundColor: Colors.teal,
      ));
    }
  }
}

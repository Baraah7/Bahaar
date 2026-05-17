part of 'integrated_map.dart';

extension _IntegratedMapRouting on _IntegratedMapState {
  // ── Route calculation ─────────────────────────────────────────

  Future<void> _calculateRoute(LatLng destination) async {
    if (!_routingInitialized) {
      _showMessage('Navigation services are still loading, please try again', Colors.orange);
      return;
    }
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
        _fitRouteBounds(route);
      } else {
        setState(() => _isCalculatingRoute = false);
        _showMessage('Could not find a route', Colors.red);
      }
    } catch (e) {
      log('Error calculating route: $e');
      setState(() => _isCalculatingRoute = false);
      _showMessage('Error calculating route: $e', Colors.red);
    }
  }

  Future<void> _calculatePortToSeaRoute() async {
    if (!_routingInitialized) {
      _showMessage('Navigation services are still loading, please try again', Colors.orange);
      return;
    }
    if (_selectedPort == null || _seaDestination == null) {
      _showMessage(MapLocalizations.of(context).stepTapPort, Colors.orange);
      return;
    }

    LatLng? gpsLocation;
    if (_locationData != null) {
      final candidate = LatLng(
        _locationData!.latitude ?? MapConstants.defaultLatitude,
        _locationData!.longitude ?? MapConstants.defaultLongitude,
      );
      if (!_maskInitialized || !_navigationMask.isPointNavigable(candidate)) {
        gpsLocation = candidate;
      }
    }
    final landOrigin = _customLandOrigin ?? gpsLocation;

    if (landOrigin == null) {
      _showMessage(MapLocalizations.of(context).currentLocationOnLandRequired, Colors.orange);
      return;
    }
    if (_maskInitialized && _navigationMask.isPointNavigable(landOrigin)) {
      _showMessage('Starting point must be on land, not on water.', Colors.orange);
      return;
    }

    setState(() {
      _isCalculatingRoute = true;
      _currentRoute = null;
    });

    try {
      log('Calculating land-to-port-to-sea route');
      log('  Origin: $landOrigin${_customLandOrigin != null ? " (custom)" : " (GPS)"}');
      log('  Selected port: ${_selectedPort!.name} at ${_selectedPort!.location}');
      log('  Sea destination: $_seaDestination');

      final landSegment = await _osrmService.getRoute(
        origin: landOrigin,
        destination: _selectedPort!.location,
      );
      if (landSegment == null) {
        setState(() => _isCalculatingRoute = false);
        _showMessage('Could not find land route to port', Colors.red);
        return;
      }

      final marineSegment = await _marineService.findMarineRoute(
        origin: _selectedPort!.location,
        destination: _seaDestination!,
        restrictedAreas: [
          if (_geoJsonBuilder != null) ...[
            ..._geoJsonBuilder!.buildRestrictedAreas(isVisible: true),
            ..._geoJsonBuilder!.buildProtectedZones(isVisible: true),
          ],
        ],
      );
      if (marineSegment == null) {
        setState(() => _isCalculatingRoute = false);
        _showMessage('Could not find marine route from port', Colors.red);
        return;
      }

      final combinedGeometry = [...landSegment.geometry, ...marineSegment.geometry];
      final segments = [landSegment, marineSegment];
      final totalDistance = segments.fold<double>(0, (s, seg) => s + seg.distance);
      final totalDuration = segments.fold<int>(0, (s, seg) => s + seg.duration);

      final combinedRoute = NavigationRoute(
        id: 'route_${DateTime.now().millisecondsSinceEpoch}',
        origin: landOrigin,
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
      log('  Land: ${landSegment.geometry.length} points, ${landSegment.distance}m');
      log('  Marine: ${marineSegment.geometry.length} points, ${marineSegment.distance}m');

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
      setState(() => _isCalculatingRoute = false);
      _showMessage('Error calculating route: $e', Colors.red);
    }
  }

  Future<void> _calculateSeaToSeaRoute() async {
    if (!_routingInitialized) {
      _showMessage('Navigation services are still loading, please try again', Colors.orange);
      return;
    }
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

  Future<void> _calculateSeaToLandRoute() async {
    if (!_routingInitialized) {
      _showMessage('Navigation services are still loading, please try again', Colors.orange);
      return;
    }
    if (_seaToLandOrigin == null || _selectedPort == null || _customLandDestination == null) {
      _showMessage('Please select sea origin, port, and land destination', Colors.orange);
      return;
    }

    setState(() {
      _isCalculatingRoute = true;
      _currentRoute = null;
    });

    try {
      final marineSegment = await _marineService.findMarineRoute(
        origin: _seaToLandOrigin!,
        destination: _selectedPort!.location,
        restrictedAreas: [
          if (_geoJsonBuilder != null) ...[
            ..._geoJsonBuilder!.buildRestrictedAreas(isVisible: true),
            ..._geoJsonBuilder!.buildProtectedZones(isVisible: true),
          ],
        ],
      );
      if (marineSegment == null) {
        setState(() => _isCalculatingRoute = false);
        _showMessage('Could not find marine route to port', Colors.red);
        return;
      }

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

  // ── Route mode management ─────────────────────────────────────

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
      if (_navigationMask.isPointNavigable(candidate)) gpsSeaOrigin = candidate;
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
      _selectedPort = _returnPort;
      _seaToLandOrigin = null;
      _customLandDestination = null;
    });
  }

  void _handlePortSelected(PortPoint port) {
    setState(() {
      _selectedPort = port;
      if (_navMode == NavMode.landToSea) _returnPort = port;
    });
    _showMessage('Port selected: ${port.name}', Colors.blue);

    if (_navMode == NavMode.landToSea && _seaDestination != null) {
      _calculatePortToSeaRoute();
    } else if (_navMode == NavMode.seaToLand &&
        _seaToLandOrigin != null &&
        _customLandDestination != null) {
      _calculateSeaToLandRoute();
    }
  }

  // ── Helpers ───────────────────────────────────────────────────

  List<Waypoint> _buildRouteWaypoints(List<RouteSegment> segments) {
    if (segments.isEmpty) return [];

    final waypoints = <Waypoint>[];
    double distAcc = 0;
    int timeAcc = 0;

    final firstSegType = segments.first.type == SegmentType.land
        ? RouteSegmentType.land
        : RouteSegmentType.marine;

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
        const sampleInterval = 500.0;
        double accumulated = 0.0;
        double nextSample = sampleInterval;
        int wpIdx = 0;
        for (int g = 0; g < segment.geometry.length - 1; g++) {
          final from = segment.geometry[g];
          final to = segment.geometry[g + 1];
          accumulated += _haversineMeters(from, to);
          if (accumulated >= nextSample) {
            final compass = _compassFromBearing(_bearingBetween(from, to));
            final frac = accumulated / segment.distance;
            waypoints.add(Waypoint(
              id: 'wp_marine_${i}_$wpIdx',
              location: to,
              type: WaypointType.intermediate,
              distanceFromStart: distAcc + accumulated,
              instruction: 'Head $compass',
              estimatedTime: (timeAcc + frac * segment.duration).round(),
              segmentType: RouteSegmentType.marine,
            ));
            wpIdx++;
            nextSample += sampleInterval;
          }
        }
      }

      if (segment.type == SegmentType.land && segment.steps.isNotEmpty) {
        double stepDistAcc = 0;
        for (int s = 0; s < segment.steps.length; s++) {
          final step = segment.steps[s];
          final type = step.maneuverType;
          if (type == 'depart' || type == 'arrive') {
            stepDistAcc += step.distance;
            continue;
          }
          if (waypoints.isNotEmpty) {
            final prev = waypoints.last;
            final dLat = step.location.latitude - prev.location.latitude;
            final dLon = step.location.longitude - prev.location.longitude;
            // 30 m ≈ 0.00027 degrees → 0.00027² ≈ 7.3e-8
            if (dLat * dLat + dLon * dLon < 7.3e-8) {
              stepDistAcc += step.distance;
              continue;
            }
          }
          final stepTime = (segment.duration > 0 && segment.distance > 0)
              ? (stepDistAcc / segment.distance * segment.duration).round()
              : 0;
          waypoints.add(Waypoint(
            id: 'wp_step_${i}_$s',
            location: step.location,
            type: WaypointType.turn,
            distanceFromStart: distAcc + stepDistAcc,
            instruction: _buildStepInstruction(step),
            estimatedTime: timeAcc + stepTime,
            segmentType: RouteSegmentType.land,
          ));
          stepDistAcc += step.distance;
        }
      }

      if (!isLast) {
        distAcc += segment.distance;
        timeAcc += segment.duration;
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
      'South', 'South-West', 'West', 'North-West',
    ];
    return dirs[((bearing + 22.5) / 45).floor() % 8];
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
        bounds: LatLngBounds(LatLng(minLat, minLon), LatLng(maxLat, maxLon)),
        padding: const EdgeInsets.all(50),
      ),
    );
  }

  void _updateWeatherWarnings() {
    if (!_routingInitialized) return;
    final warnings = _weatherService.getActiveWarnings();
    if (mounted) {
      setState(() {
        _activeWeatherWarnings = warnings;
        _weatherAlertDismissed = false;
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

  String? _getProtectedAreaAt(LatLng point) {
    if (_geoJsonBuilder != null) {
      for (final type in ['protected_zone', 'restricted_area']) {
        for (final feature in _geoJsonBuilder!.getFeaturesByType(type)) {
          try {
            final coords = feature['geometry']['coordinates'][0] as List;
            final polygon = coords
                .map((c) => LatLng((c[1] as num).toDouble(), (c[0] as num).toDouble()))
                .toList();
            if (GeometryUtils.isPointInPolygon(point, polygon)) {
              return feature['properties']['name'] as String? ?? 'Protected Area';
            }
          } catch (_) {}
        }
      }
    }

    for (final mpa in _mpaPolygons) {
      try {
        final pts = (mpa['polygon'] as List).map((p) {
          final pair = p as List;
          return LatLng((pair[0] as num).toDouble(), (pair[1] as num).toDouble());
        }).toList();
        if (GeometryUtils.isPointInPolygon(point, pts)) {
          return mpa['nameAr'] as String? ?? mpa['nameEn'] as String? ?? 'Protected Area';
        }
      } catch (_) {}
    }

    return null;
  }

  String _formatDistance(double meters) {
    if (meters < 1000) return '${meters.round()} m';
    return '${(meters / 1000).toStringAsFixed(1)} km';
  }
}

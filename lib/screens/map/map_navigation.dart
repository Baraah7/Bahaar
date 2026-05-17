part of 'integrated_map.dart';

extension _IntegratedMapNavigation on _IntegratedMapState {
  // ── Navigation session ────────────────────────────────────────

  void _onNavigationUpdate() {
    if (!mounted) return;
    final session = _navigationManager?.session;
    final navLocation = session?.currentLocation;
    final newState = session?.state;

    if (newState == NavigationState.completed &&
        _lastNavState != NavigationState.completed) {
      _lastNavState = newState;
      WidgetsBinding.instance.addPostFrameCallback((_) => _showArrivalDialog());
      return;
    }
    _lastNavState = newState;

    setState(() {
      if (navLocation != null) {
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
      if (session != null && _currentRoute != null &&
          session.route.id != _currentRoute!.id) {
        _currentRoute = session.route;
      }
    });

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
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
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
                child: Icon(Icons.flag_rounded, size: 44, color: Colors.green.shade700),
              ),
              const SizedBox(height: 20),
              const Text(
                'You have reached\nyour destination!',
                textAlign: TextAlign.center,
                style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold, height: 1.3),
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
                      style: TextStyle(fontWeight: FontWeight.bold, fontSize: 15)),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.primary,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Future<void> _startNavigation() async {
    if (_currentRoute == null || _navigationManager == null) return;
    try {
      log('Starting navigation session');
      await _navigationManager!.startNavigation(_currentRoute!);
      _showMessage('Navigation started', Colors.green);
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
      _mapController.move(_navigationManager!.session!.currentLocation!, 16);
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

  // ── Map interaction ───────────────────────────────────────────

  void _handleMapTap(TapPosition tapPosition, LatLng point) {
    if (!_maskInitialized) return;
    final l10n = MapLocalizations.of(context);
    if (_currentRoute != null) return;

    final isNavigable = _navigationMask.isPointNavigable(point);
    final isOutsideBounds = point.longitude < _navigationMask.minLon ||
        point.longitude > _navigationMask.maxLon ||
        point.latitude < _navigationMask.minLat ||
        point.latitude > _navigationMask.maxLat;

    log('Tapped (${point.latitude.toStringAsFixed(4)}, ${point.longitude.toStringAsFixed(4)}): '
        '${isNavigable ? "navigable water" : isOutsideBounds ? "outside territorial bounds" : "land"}');

    // ── Sea→Sea ──────────────────────────────────────────────────
    if (_navMode == NavMode.seaToSea) {
      if (!isNavigable) {
        setState(() {
          _outsideMaskWarning = isOutsideBounds ? l10n.outsideTerritorialWaters : l10n.tapOnSea;
          _outsideMaskWarningDismissed = false;
        });
        return;
      }
      if (_outsideMaskWarning != null) setState(() => _outsideMaskWarning = null);

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

    // ── Sea→Land ─────────────────────────────────────────────────
    if (_navMode == NavMode.seaToLand) {
      if (_showPortSelection && !isNavigable) {
        final tapScreen = tapPosition.relative;
        if (tapScreen != null) {
          for (final port in _availablePorts) {
            final portScreen = _mapController.camera.getOffsetFromOrigin(port.location);
            if ((tapScreen - portScreen).distance <= 45.0) {
              _handlePortSelected(port);
              return;
            }
          }
        }
        if (_seaToLandOrigin != null && _selectedPort != null) {
          setState(() => _customLandDestination = point);
          _calculateSeaToLandRoute();
        }
        return;
      }
      if (!isNavigable) {
        if (_seaToLandOrigin != null && _selectedPort != null) {
          setState(() => _customLandDestination = point);
          _calculateSeaToLandRoute();
          return;
        }
        setState(() {
          _outsideMaskWarning = isOutsideBounds ? l10n.outsideTerritorialWaters : l10n.tapOnSea;
          _outsideMaskWarningDismissed = false;
        });
        return;
      }
      if (_outsideMaskWarning != null) setState(() => _outsideMaskWarning = null);

      final areaName = _getProtectedAreaAt(point);
      if (areaName != null) { _showProtectedAreaDialog(areaName); return; }

      if (_seaToLandOrigin == null) {
        setState(() => _seaToLandOrigin = point);
        _showMessage(l10n.seaDepartureSet, Colors.blue);
      }
      return;
    }

    // ── Land→Sea (port selection) ─────────────────────────────────
    if (_showPortSelection && !isNavigable) {
      final tapScreen = tapPosition.relative;
      if (tapScreen != null) {
        for (final port in _availablePorts) {
          final portScreen = _mapController.camera.getOffsetFromOrigin(port.location);
          if ((tapScreen - portScreen).distance <= 45.0) {
            _handlePortSelected(port);
            return;
          }
        }
      }
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
      setState(() {
        _outsideMaskWarning = isOutsideBounds ? l10n.outsideTerritorialWaters : l10n.tapOnSea;
        _outsideMaskWarningDismissed = false;
      });
    } else {
      if (_outsideMaskWarning != null) setState(() => _outsideMaskWarning = null);
    }

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
    }
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
}

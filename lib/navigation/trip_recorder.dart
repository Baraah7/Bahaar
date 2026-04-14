import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:latlong2/latlong.dart';
import 'package:location/location.dart';
import 'celestial_fix_notifier.dart';
import 'dead_reckoning.dart';
import 'port_router.dart';
import 'trip_database.dart';

// ─────────────────────────────────────────────────────────────────────────────
// Configuration
// ─────────────────────────────────────────────────────────────────────────────

/// How often to attempt a periodic waypoint save.
const Duration _kRecordInterval = Duration(minutes: 5);

/// Minimum distance traveled (NM) before saving an extra waypoint mid-interval.
const double _kMinDistanceNm = 0.5;

/// GPS is considered "lost" after this many consecutive failures.
const int _kGpsLostThreshold = 3;

// ─────────────────────────────────────────────────────────────────────────────
// Trip status
// ─────────────────────────────────────────────────────────────────────────────

enum TripStatus {
  idle,       // no active trip
  active,     // trip running, GPS good
  gpsLost,    // trip running, using DR / celestial fallback
  ended;      // trip just ended (transient, reverts to idle)
}

// ─────────────────────────────────────────────────────────────────────────────
// Live position snapshot
// ─────────────────────────────────────────────────────────────────────────────

class LivePosition {
  final LatLng   position;
  final FixType  source;
  final double   accuracyNm;
  final double?  headingDeg;
  final double?  speedKn;
  final DateTime time;

  const LivePosition({
    required this.position,
    required this.source,
    required this.accuracyNm,
    this.headingDeg,
    this.speedKn,
    required this.time,
  });
}

// ─────────────────────────────────────────────────────────────────────────────
// TripRecorder — singleton ChangeNotifier
// ─────────────────────────────────────────────────────────────────────────────

class TripRecorder extends ChangeNotifier {
  TripRecorder._() {
    // Listen for celestial fixes from DS-1
    CelestialFixNotifier.instance.addListener(_onCelestialFix);
  }

  static final instance = TripRecorder._();

  // ── Public state ────────────────────────────────────────────────────────

  TripStatus     get status         => _status;
  TripRecord?    get activeTrip     => _trip;
  Port?          get departurePort  => _departurePort;
  LivePosition?  get currentPosition => _currentPos;
  DeadReckoningFix? get drFix       => _drFix;
  List<Waypoint> get waypoints      => List.unmodifiable(_waypoints);

  /// Routes to ports — recomputed whenever the position updates.
  List<RouteToPort> get portRoutes  => List.unmodifiable(_portRoutes);

  /// Non-null during DR mode when uncertainty is ≥ warning threshold.
  String? get drAdvisory => _drFix != null &&
      _drFix!.reliability != DrReliability.good
      ? _drFix!.advisory
      : null;

  // ── Private ─────────────────────────────────────────────────────────────

  TripStatus    _status = TripStatus.idle;
  TripRecord?   _trip;
  Port?         _departurePort;
  List<Port>    _allPorts = [];
  final List<Waypoint> _waypoints = [];
  List<RouteToPort> _portRoutes = [];

  // Live position and DR state
  LivePosition?       _currentPos;
  DeadReckoningFix?   _drFix;
  LatLng?             _lastGoodGpsPos;
  DateTime?           _lastGoodGpsTime;
  double              _lastGoodGpsAccuracyNm = 0.0;
  double              _lastHeadingDeg = 0.0;
  double              _lastSpeedKn    = 0.0;
  int                 _gpsFailCount   = 0;
  LatLng?             _lastRecordedPos;

  // Location service
  final _location = Location();
  StreamSubscription<LocationData>? _locationSub;
  Timer? _recordTimer;

  // ── Trip lifecycle ───────────────────────────────────────────────────────

  /// Starts a new trip.  Caller must pass the resolved [Port] object.
  /// Throws [StateError] if a trip is already active.
  Future<void> startTrip(Port departure) async {
    if (_status != TripStatus.idle) {
      throw StateError('A trip is already active.');
    }

    // Refresh port list for routing
    _allPorts = await TripDatabase.instance.getAllPorts();

    _trip = await TripDatabase.instance.startTrip(departure.id!);
    _departurePort = departure;
    _waypoints.clear();
    _portRoutes.clear();
    _drFix = null;
    _gpsFailCount = 0;

    _status = TripStatus.active;
    notifyListeners();

    await _startLocationStream();
    _recordTimer = Timer.periodic(_kRecordInterval, (_) => _periodicRecord());
  }

  /// Ends the active trip and IMMEDIATELY deletes all waypoints.
  /// Safe to call even if no trip is active.
  Future<void> endTrip() async {
    if (_trip == null) return;

    _recordTimer?.cancel();
    _recordTimer = null;
    await _locationSub?.cancel();
    _locationSub = null;

    final id = _trip!.id!;
    await TripDatabase.instance.endTrip(id); // purges waypoints in transaction

    _trip          = null;
    _departurePort = null;
    _waypoints.clear();
    _portRoutes.clear();
    _currentPos    = null;
    _drFix         = null;
    _status        = TripStatus.idle;
    notifyListeners();
  }

  // ── Location stream ──────────────────────────────────────────────────────

  Future<void> _startLocationStream() async {
    bool svc = await _location.serviceEnabled();
    if (!svc) svc = await _location.requestService();
    if (!svc) { _enterDrMode(); return; }

    var perm = await _location.hasPermission();
    if (perm == PermissionStatus.denied) {
      perm = await _location.requestPermission();
    }
    if (perm != PermissionStatus.granted) { _enterDrMode(); return; }

    await _location.changeSettings(
      accuracy: LocationAccuracy.high,
      interval: 10000, // 10 s polling
    );

    _locationSub = _location.onLocationChanged.listen(
      _onLocationUpdate,
      onError: (_) => _onGpsFailure(),
    );
  }

  void _onLocationUpdate(LocationData data) {
    if (_trip == null) return;

    final lat = data.latitude;
    final lng = data.longitude;

    if (lat == null || lng == null) {
      _onGpsFailure();
      return;
    }

    final pos       = LatLng(lat, lng);
    final headingDeg = data.heading ?? _lastHeadingDeg;
    final speedKn    = (data.speed ?? 0.0) * 1.94384; // m/s → knots
    // GPS accuracy from device is in metres; convert to NM
    final accNm      = ((data.accuracy ?? 50.0) / 1852.0);

    _lastGoodGpsPos        = pos;
    _lastGoodGpsTime       = DateTime.now().toUtc();
    _lastGoodGpsAccuracyNm = accNm;
    _lastHeadingDeg        = headingDeg;
    _lastSpeedKn           = speedKn;
    _gpsFailCount          = 0;
    _drFix                 = null;

    _currentPos = LivePosition(
      position:   pos,
      source:     FixType.gps,
      accuracyNm: accNm,
      headingDeg: headingDeg,
      speedKn:    speedKn,
      time:       DateTime.now().toUtc(),
    );

    if (_status == TripStatus.gpsLost) {
      _status = TripStatus.active;
    }

    _recomputeRoutes();
    _maybeSaveDistanceTrigger(pos);
    notifyListeners();
  }

  void _onGpsFailure() {
    _gpsFailCount++;
    if (_gpsFailCount >= _kGpsLostThreshold && _status == TripStatus.active) {
      _enterDrMode();
    }
  }

  void _enterDrMode() {
    _status = TripStatus.gpsLost;
    _updateDrFix();
    notifyListeners();
  }

  // ── Dead reckoning ───────────────────────────────────────────────────────

  void _updateDrFix() {
    if (_lastGoodGpsPos == null || _lastGoodGpsTime == null) return;

    _drFix = DeadReckoning.compute(
      lastPosition:      _lastGoodGpsPos!,
      lastFixTime:       _lastGoodGpsTime!,
      lastFixAccuracyNm: _lastGoodGpsAccuracyNm,
      headingDeg:        _lastHeadingDeg,
      speedKn:           _lastSpeedKn,
    );

    _currentPos = LivePosition(
      position:   _drFix!.position,
      source:     FixType.deadReckoning,
      accuracyNm: _drFix!.uncertaintyNm,
      headingDeg: _lastHeadingDeg,
      speedKn:    _lastSpeedKn,
      time:       DateTime.now().toUtc(),
    );

    _recomputeRoutes();
    notifyListeners();
  }

  // ── Celestial fix integration ────────────────────────────────────────────

  void _onCelestialFix() {
    final fix = CelestialFixNotifier.instance.fix;
    if (fix == null || _trip == null) return;

    // Celestial fix resets DR uncertainty
    final celestialAccNm = fix.uncertaintyNm;

    _lastGoodGpsPos        = fix.position;
    _lastGoodGpsTime       = fix.timestamp;
    _lastGoodGpsAccuracyNm = celestialAccNm;
    _drFix                 = null;

    _currentPos = LivePosition(
      position:   fix.position,
      source:     FixType.celestial,
      accuracyNm: celestialAccNm,
      headingDeg: _lastHeadingDeg,
      speedKn:    _lastSpeedKn,
      time:       fix.timestamp,
    );

    // Save celestial waypoint immediately
    _saveWaypoint(_currentPos!);
    _recomputeRoutes();
    notifyListeners();
  }

  // ── Periodic recording ───────────────────────────────────────────────────

  void _periodicRecord() {
    if (_trip == null || _currentPos == null) return;

    // If GPS lost, refresh DR before saving
    if (_status == TripStatus.gpsLost) _updateDrFix();

    _saveWaypoint(_currentPos!);
  }

  /// Saves an extra waypoint if the vessel has moved ≥ 0.5 NM since the
  /// last recorded position (regardless of the timer interval).
  void _maybeSaveDistanceTrigger(LatLng current) {
    if (_lastRecordedPos == null) return;
    final dist = DeadReckoning.distanceNm(_lastRecordedPos!, current);
    if (dist >= _kMinDistanceNm) _saveWaypoint(_currentPos!);
  }

  Future<void> _saveWaypoint(LivePosition pos) async {
    if (_trip == null) return;

    final wp = Waypoint(
      tripId:     _trip!.id!,
      lat:        pos.position.latitude,
      lng:        pos.position.longitude,
      fixType:    pos.source,
      accuracyNm: pos.accuracyNm,
      headingDeg: pos.headingDeg,
      speedKn:    pos.speedKn,
      recordedAt: pos.time,
    );

    final id = await TripDatabase.instance.insertWaypoint(wp);
    final saved = Waypoint(
      id:         id,
      tripId:     wp.tripId,
      lat:        wp.lat,
      lng:        wp.lng,
      fixType:    wp.fixType,
      accuracyNm: wp.accuracyNm,
      headingDeg: wp.headingDeg,
      speedKn:    wp.speedKn,
      recordedAt: wp.recordedAt,
    );

    _waypoints.add(saved);
    _lastRecordedPos = pos.position;
    notifyListeners();
  }

  // ── Port routing ─────────────────────────────────────────────────────────

  void _recomputeRoutes() {
    if (_currentPos == null || _allPorts.isEmpty) return;

    _portRoutes = PortRouter.nearestPorts(
      fromPosition:          _currentPos!.position,
      allPorts:              _allPorts,
      maxResults:            5,
      departurePortId:       _departurePort?.id,
      positionUncertaintyNm: _currentPos!.accuracyNm,
    );
  }

  /// Forces a route refresh — call after port list changes.
  Future<void> refreshPorts() async {
    _allPorts = await TripDatabase.instance.getAllPorts();
    _recomputeRoutes();
    notifyListeners();
  }

  // ── DR timer (called from UI every 30 s while GPS is lost) ──────────────

  /// Called periodically by the UI to keep the DR fix current while
  /// no GPS signal is available.
  void tickDr() {
    if (_status == TripStatus.gpsLost) _updateDrFix();
  }

  @override
  void dispose() {
    CelestialFixNotifier.instance.removeListener(_onCelestialFix);
    _recordTimer?.cancel();
    _locationSub?.cancel();
    super.dispose();
  }
}

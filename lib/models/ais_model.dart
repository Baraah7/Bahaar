import 'dart:math' as math;

/// AIS vessel types per ITU-R M.1371 ship type codes.
enum VesselType {
  cargo,
  tanker,
  fishing,
  pleasure,
  passenger,
  tug,
  unknown;

  static VesselType fromCode(int? code) {
    if (code == null) return VesselType.unknown;
    if (code >= 70 && code <= 79) return VesselType.cargo;
    if (code >= 80 && code <= 89) return VesselType.tanker;
    if (code == 30) return VesselType.fishing;
    if (code == 36 || code == 37) return VesselType.pleasure;
    if (code >= 60 && code <= 69) return VesselType.passenger;
    if (code == 21 || code == 22) return VesselType.tug;
    return VesselType.unknown;
  }
}

/// A tracked AIS vessel with position, motion, and identity data.
class AisVessel {
  /// Maritime Mobile Service Identity (unique vessel ID)
  final int mmsi;
  final String name;
  final String callSign;
  final VesselType vesselType;

  /// Current position
  final double latitude;
  final double longitude;

  /// Speed Over Ground in knots
  final double sogKnots;

  /// Course Over Ground in degrees (0–360, true north)
  final double cogDegrees;

  /// True heading in degrees (may differ from COG in crosswind/current)
  final double? headingDegrees;

  final DateTime timestamp;

  const AisVessel({
    required this.mmsi,
    required this.name,
    required this.callSign,
    required this.vesselType,
    required this.latitude,
    required this.longitude,
    required this.sogKnots,
    required this.cogDegrees,
    this.headingDegrees,
    required this.timestamp,
  });

  factory AisVessel.fromAisHubJson(Map<String, dynamic> json) {
    final typeCode = int.tryParse(json['SHIPTYPE']?.toString() ?? '');
    return AisVessel(
      mmsi: int.tryParse(json['MMSI']?.toString() ?? '0') ?? 0,
      name: json['NAME']?.toString().trim() ?? 'Unknown',
      callSign: json['CALLSIGN']?.toString().trim() ?? '',
      vesselType: VesselType.fromCode(typeCode),
      latitude: double.tryParse(json['LATITUDE']?.toString() ?? '0') ?? 0,
      longitude: double.tryParse(json['LONGITUDE']?.toString() ?? '0') ?? 0,
      sogKnots: double.tryParse(json['SPEED']?.toString() ?? '0') ?? 0,
      cogDegrees: double.tryParse(json['COURSE']?.toString() ?? '0') ?? 0,
      headingDegrees: double.tryParse(json['HEADING']?.toString() ?? ''),
      timestamp: DateTime.now(),
    );
  }

  /// Speed in meters per second
  double get sogMs => sogKnots * 0.514444;

  /// COG as radians (0 = north, clockwise)
  double get cogRad => cogDegrees * math.pi / 180.0;

  /// Velocity vector [east m/s, north m/s]
  (double vEast, double vNorth) get velocityVector => (
        sogMs * math.sin(cogRad),
        sogMs * math.cos(cogRad),
      );

  /// Project position forward by [seconds]
  (double lat, double lon) projectPosition(double seconds) {
    const metersPerDegLat = 111319.9;
    final metersPerDegLon = metersPerDegLat * math.cos(latitude * math.pi / 180);
    final (vE, vN) = velocityVector;
    return (
      latitude + (vN * seconds) / metersPerDegLat,
      longitude + (vE * seconds) / metersPerDegLon,
    );
  }

  AisVessel copyWith({double? latitude, double? longitude}) => AisVessel(
        mmsi: mmsi,
        name: name,
        callSign: callSign,
        vesselType: vesselType,
        latitude: latitude ?? this.latitude,
        longitude: longitude ?? this.longitude,
        sogKnots: sogKnots,
        cogDegrees: cogDegrees,
        headingDegrees: headingDegrees,
        timestamp: timestamp,
      );
}

/// Result of a CPA (Closest Point of Approach) calculation.
class CpaResult {
  /// The vessel being tracked
  final AisVessel vessel;

  /// Distance at CPA in nautical miles
  final double dcpaNm;

  /// Time to CPA in minutes
  final double tcpaMinutes;

  /// Risk level based on DCPA and TCPA thresholds
  final CollisionRisk risk;

  const CpaResult({
    required this.vessel,
    required this.dcpaNm,
    required this.tcpaMinutes,
    required this.risk,
  });
}

enum CollisionRisk { none, caution, danger }

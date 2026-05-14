import 'package:flutter/material.dart';

/// The four species supported by the fish classifier, also used for
/// the probability heatmap.
enum FishSpecies {
  giltHeadBream,
  horseMackerel,
  seaBass,
  shrimp,
}

extension FishSpeciesExtension on FishSpecies {
  String get englishName {
    switch (this) {
      case FishSpecies.giltHeadBream:
        return 'Gilt-Head Bream';
      case FishSpecies.horseMackerel:
        return 'Horse Mackerel';
      case FishSpecies.seaBass:
        return 'Sea Bass';
      case FishSpecies.shrimp:
        return 'Shrimp';
    }
  }

  String get arabicName {
    switch (this) {
      case FishSpecies.giltHeadBream:
        return 'دنيس';
      case FishSpecies.horseMackerel:
        return 'سكمبري';
      case FishSpecies.seaBass:
        return 'قاروص';
      case FishSpecies.shrimp:
        return 'روبيان';
    }
  }

  /// Base colour used for heatmap cells and UI indicators.
  Color get color {
    switch (this) {
      case FishSpecies.giltHeadBream:
        return Colors.teal;
      case FishSpecies.horseMackerel:
        return Colors.blue;
      case FishSpecies.seaBass:
        return Colors.indigo;
      case FishSpecies.shrimp:
        return Colors.amber;
    }
  }
}


/// this is for fish spot probability 
/// Five probability tiers for finer colour resolution than the
/// four-tier FishingIntensityLevel.
enum FishProbabilityLevel { veryLow, low, moderate, high, veryHigh }

/// A single grid cell (0.15° × 0.15°) containing the pre-computed
/// fish probability score for one species.
class FishProbabilityCell {
  /// Centre of the cell (degrees).
  final double latitude;
  final double longitude;

  /// Raw 0–1 composite score (SST 55% + Chlorophyll 45%).
  final double score;

  /// Bucketed level derived from [score].
  final FishProbabilityLevel level;

  /// Species this cell belongs to.
  final FishSpecies species;

  const FishProbabilityCell({
    required this.latitude,
    required this.longitude,
    required this.score,
    required this.level,
    required this.species,
  });

  factory FishProbabilityCell.fromJson(
      Map<String, dynamic> json, FishSpecies species) {
    final score = (json['score'] as num).toDouble();
    return FishProbabilityCell(
      latitude: (json['lat'] as num).toDouble(),
      longitude: (json['lon'] as num).toDouble(),
      score: score,
      level: levelForScore(score),
      species: species,
    );
  }

  Map<String, dynamic> toJson() => {
        'lat': latitude,
        'lon': longitude,
        'score': score,
      };

  static FishProbabilityLevel levelForScore(double s) {
    if (s >= 0.80) return FishProbabilityLevel.veryHigh;
    if (s >= 0.60) return FishProbabilityLevel.high;
    if (s >= 0.40) return FishProbabilityLevel.moderate;
    if (s >= 0.20) return FishProbabilityLevel.low;
    return FishProbabilityLevel.veryLow;
  }
}

/// Intermediate environmental data for a grid cell (package-private).
/// Used only inside FishProbabilityService.
class EnvCell {
  final double lat;
  final double lon;

  /// Sea surface temperature in °C (double.nan if unavailable).
  final double sst;

  /// Chlorophyll-a concentration in mg/m³ (double.nan if unavailable).
  final double chlorophyll;

  const EnvCell(this.lat, this.lon, this.sst, this.chlorophyll);
}

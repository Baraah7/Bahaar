import 'package:flutter/foundation.dart';
import 'package:Bahaar/models/fishing/fish_probability_model.dart';

/// Manages the state and configuration of all map layers
/// Provides a centralized way to control layer visibility, opacity, and settings
class MapLayerManager extends ChangeNotifier {
  // Base map layer
  bool _showBaseMap = true;

  // Depth layer configuration
  bool _showDepthLayer = true;
  double _depthLayerOpacity = 0.7;
  DepthVisualizationType _depthVisualizationType = DepthVisualizationType.bathymetric;

  // GeoJSON layers — only protected zones remain
  bool _showGeoJsonLayers = true;
  bool _showProtectedZones = true;

  // Fishing activity layer
  bool _showFishingActivity = false;
  bool _showFishingActivityTracks = true;
  bool _showFishingActivityEvents = true;
  bool _showFishingActivityHeatmap = true;

  // Fish probability heatmap
  bool _showFishProbabilityHeatmap = false;
  Set<FishSpecies> _selectedSpecies = {
    FishSpecies.giltHeadBream,
    FishSpecies.horseMackerel,
    FishSpecies.seaBass,
    FishSpecies.shrimp,
  };

  // Exclusion zones (oil/gas platforms)
  bool _showExclusionZones = true;

  // GEBCO depth soundings tile layer
<<<<<<< HEAD
  bool _showDepthSoundings = false;
=======
  bool _showDepthSoundings = true;
>>>>>>> origin/exp

  // Navigation mask
  bool _showMaskOverlay = false;

  // UI control
  bool _showLayerControls = false;

  // Admin edit mode (mask painting)
  bool _isAdminEditMode = false;
  AdminBrushType _brushType = AdminBrushType.water;
  int _brushRadius = 1; // 1-5 cells

  // Feature edit mode (add/move/delete features)
  bool _isFeatureEditMode = false;

  // Getters
  bool get showBaseMap => _showBaseMap;
  bool get showDepthLayer => _showDepthLayer;
  double get depthLayerOpacity => _depthLayerOpacity;
  DepthVisualizationType get depthVisualizationType => _depthVisualizationType;
  bool get showGeoJsonLayers => _showGeoJsonLayers;
  bool get showProtectedZones => _showProtectedZones;
  bool get showFishingActivity => _showFishingActivity;
  bool get showFishingActivityTracks => _showFishingActivityTracks;
  bool get showFishingActivityEvents => _showFishingActivityEvents;
  bool get showFishingActivityHeatmap => _showFishingActivityHeatmap;
  bool get showFishProbabilityHeatmap => _showFishProbabilityHeatmap;
  Set<FishSpecies> get selectedSpecies => Set.unmodifiable(_selectedSpecies);
  bool get showExclusionZones => _showExclusionZones;
  bool get showDepthSoundings => _showDepthSoundings;
  bool get showMaskOverlay => _showMaskOverlay;
  bool get showLayerControls => _showLayerControls;
  bool get isFeatureEditMode => _isFeatureEditMode;
  bool get isAdminEditMode => _isAdminEditMode;
  AdminBrushType get brushType => _brushType;
  int get brushRadius => _brushRadius;

  // Setters with notification
  set showBaseMap(bool value) {
    if (_showBaseMap != value) {
      _showBaseMap = value;
      notifyListeners();
    }
  }

  set showDepthLayer(bool value) {
    if (_showDepthLayer != value) {
      _showDepthLayer = value;
      notifyListeners();
    }
  }

  set depthLayerOpacity(double value) {
    if (_depthLayerOpacity != value) {
      _depthLayerOpacity = value.clamp(0.0, 1.0);
      notifyListeners();
    }
  }

  set depthVisualizationType(DepthVisualizationType value) {
    if (_depthVisualizationType != value) {
      _depthVisualizationType = value;
      notifyListeners();
    }
  }

  set showGeoJsonLayers(bool value) {
    if (_showGeoJsonLayers != value) {
      _showGeoJsonLayers = value;
      notifyListeners();
    }
  }

  set showProtectedZones(bool value) {
    if (_showProtectedZones != value) {
      _showProtectedZones = value;
      notifyListeners();
    }
  }

  set showFishingActivity(bool value) {
    if (_showFishingActivity != value) {
      _showFishingActivity = value;
      notifyListeners();
    }
  }

  set showFishingActivityTracks(bool value) {
    if (_showFishingActivityTracks != value) {
      _showFishingActivityTracks = value;
      notifyListeners();
    }
  }

  set showFishingActivityEvents(bool value) {
    if (_showFishingActivityEvents != value) {
      _showFishingActivityEvents = value;
      notifyListeners();
    }
  }

  set showFishingActivityHeatmap(bool value) {
    if (_showFishingActivityHeatmap != value) {
      _showFishingActivityHeatmap = value;
      notifyListeners();
    }
  }

  set showFishProbabilityHeatmap(bool value) {
    if (_showFishProbabilityHeatmap != value) {
      _showFishProbabilityHeatmap = value;
      notifyListeners();
    }
  }

  void toggleSpecies(FishSpecies species) {
    if (_selectedSpecies.contains(species)) {
      _selectedSpecies = Set.from(_selectedSpecies)..remove(species);
    } else {
      _selectedSpecies = Set.from(_selectedSpecies)..add(species);
    }
    notifyListeners();
  }

  set showExclusionZones(bool value) {
    if (_showExclusionZones != value) {
      _showExclusionZones = value;
      notifyListeners();
    }
  }

  set showDepthSoundings(bool value) {
    if (_showDepthSoundings != value) {
      _showDepthSoundings = value;
      notifyListeners();
    }
  }

  set showMaskOverlay(bool value) {
    if (_showMaskOverlay != value) {
      _showMaskOverlay = value;
      notifyListeners();
    }
  }

  set showLayerControls(bool value) {
    if (_showLayerControls != value) {
      _showLayerControls = value;
      notifyListeners();
    }
  }

  set isAdminEditMode(bool value) {
    if (_isAdminEditMode != value) {
      _isAdminEditMode = value;
      if (value && _isFeatureEditMode) {
        _isFeatureEditMode = false;
      }
      notifyListeners();
    }
  }

  set isFeatureEditMode(bool value) {
    if (_isFeatureEditMode != value) {
      _isFeatureEditMode = value;
      if (value && _isAdminEditMode) {
        _isAdminEditMode = false;
      }
      notifyListeners();
    }
  }

  set brushType(AdminBrushType value) {
    if (_brushType != value) {
      _brushType = value;
      notifyListeners();
    }
  }

  set brushRadius(int value) {
    final clamped = value.clamp(1, 5);
    if (_brushRadius != clamped) {
      _brushRadius = clamped;
      notifyListeners();
    }
  }

  /// Toggle the protected zones GeoJSON sub-layer on/off
  void toggleAllGeoJsonLayers(bool value) {
    _showProtectedZones = value;
    notifyListeners();
  }

  /// Reset all layers to default state
  void resetToDefaults() {
    _showBaseMap = true;
    _showDepthLayer = true;
    _depthLayerOpacity = 0.7;
    _depthVisualizationType = DepthVisualizationType.bathymetric;
    _showGeoJsonLayers = true;
    _showProtectedZones = true;
    _showFishingActivity = false;
    _showFishingActivityTracks = true;
    _showFishingActivityEvents = true;
    _showFishingActivityHeatmap = true;
    _showFishProbabilityHeatmap = false;
    _selectedSpecies = {
      FishSpecies.giltHeadBream,
      FishSpecies.horseMackerel,
      FishSpecies.seaBass,
      FishSpecies.shrimp,
    };
    _showExclusionZones = true;
<<<<<<< HEAD
    _showDepthSoundings = false;
=======
    _showDepthSoundings = true;
>>>>>>> origin/exp
    _showMaskOverlay = false;
    _showLayerControls = false;
    _isFeatureEditMode = false;
    notifyListeners();
  }
}

/// Types of depth visualization available
enum DepthVisualizationType {
  /// Colored bathymetric depth map (blue gradient showing depth)
  bathymetric,

  /// OpenSeaMap nautical chart (navigation symbols, buoys, contours)
  nautical,

  /// Combined: bathymetric colors + nautical symbols overlay
  combined,
}

extension DepthVisualizationTypeExtension on DepthVisualizationType {
  String get displayName {
    switch (this) {
      case DepthVisualizationType.bathymetric:
        return 'Bathymetric Colors';
      case DepthVisualizationType.nautical:
        return 'Nautical Chart';
      case DepthVisualizationType.combined:
        return 'Combined View';
    }
  }

  String get description {
    switch (this) {
      case DepthVisualizationType.bathymetric:
        return 'Colored depth visualization (shallow to deep)';
      case DepthVisualizationType.nautical:
        return 'Navigation symbols and depth contours';
      case DepthVisualizationType.combined:
        return 'Depth colors with nautical overlay';
    }
  }
}

/// Brush types for admin mask editing
enum AdminBrushType {
  /// Paint water cells (navigable, value = 1)
  water,

  /// Paint land cells (blocked, value = 0)
  land,

  /// Eraser - removes cells (sets to land/0)
  eraser,
}

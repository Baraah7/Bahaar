import 'package:flutter_test/flutter_test.dart';
import 'package:bahaar/services/map/map_layer_manager.dart';
import 'package:bahaar/models/fishing/fish_probability_model.dart';

void main() {
  // ── Default State ────────────────────────────────────────────────────────────

  group('MapLayerManager — default state', () {
    late MapLayerManager mgr;

    setUp(() => mgr = MapLayerManager());
    tearDown(() => mgr.dispose());

    test('showBaseMap is true by default', () {
      expect(mgr.showBaseMap, isTrue);
    });

    test('showDepthLayer is false by default', () {
      expect(mgr.showDepthLayer, isFalse);
    });

    test('depthLayerOpacity defaults to 0.7', () {
      expect(mgr.depthLayerOpacity, closeTo(0.7, 0.0001));
    });

    test('depthVisualizationType defaults to bathymetric', () {
      expect(mgr.depthVisualizationType, DepthVisualizationType.bathymetric);
    });

    test('showFishProbabilityHeatmap is false by default', () {
      expect(mgr.showFishProbabilityHeatmap, isFalse);
    });

    test('showFishingSpots is false by default', () {
      expect(mgr.showFishingSpots, isFalse);
    });

    test('showExclusionZones is false by default', () {
      expect(mgr.showExclusionZones, isFalse);
    });

    test('showLayerControls is false by default', () {
      expect(mgr.showLayerControls, isFalse);
    });

    test('isAdminEditMode is false by default', () {
      expect(mgr.isAdminEditMode, isFalse);
    });

    test('isFeatureEditMode is false by default', () {
      expect(mgr.isFeatureEditMode, isFalse);
    });

    test('brushRadius defaults to 1', () {
      expect(mgr.brushRadius, 1);
    });

    test('brushType defaults to water', () {
      expect(mgr.brushType, AdminBrushType.water);
    });

    test('selectedSpecies defaults to all four species', () {
      expect(mgr.selectedSpecies, containsAll([
        FishSpecies.giltHeadBream,
        FishSpecies.horseMackerel,
        FishSpecies.seaBass,
        FishSpecies.shrimp,
      ]));
      expect(mgr.selectedSpecies.length, 4);
    });
  });

  // ── Setters and notifyListeners ──────────────────────────────────────────────

  group('MapLayerManager — setters notify listeners', () {
    late MapLayerManager mgr;
    int notifyCount = 0;

    setUp(() {
      mgr = MapLayerManager();
      notifyCount = 0;
      mgr.addListener(() => notifyCount++);
    });

    tearDown(() => mgr.dispose());

    test('setting showBaseMap notifies when value changes', () {
      mgr.showBaseMap = false;
      expect(notifyCount, 1);
    });

    test('setting showBaseMap to same value does NOT notify', () {
      mgr.showBaseMap = true; // already true
      expect(notifyCount, 0);
    });

    test('setting showDepthLayer notifies on change', () {
      mgr.showDepthLayer = true;
      expect(notifyCount, 1);
    });

    test('setting showFishProbabilityHeatmap notifies on change', () {
      mgr.showFishProbabilityHeatmap = true;
      expect(notifyCount, 1);
    });

    test('setting showFishingSpots notifies on change', () {
      mgr.showFishingSpots = true;
      expect(notifyCount, 1);
    });

    test('setting showLayerControls notifies on change', () {
      mgr.showLayerControls = true;
      expect(notifyCount, 1);
    });

    test('setting depthVisualizationType notifies on change', () {
      mgr.depthVisualizationType = DepthVisualizationType.nautical;
      expect(notifyCount, 1);
    });
  });

  // ── depthLayerOpacity clamping ───────────────────────────────────────────────

  group('MapLayerManager — depthLayerOpacity clamping', () {
    late MapLayerManager mgr;
    setUp(() => mgr = MapLayerManager());
    tearDown(() => mgr.dispose());

    test('opacity below 0 is clamped to 0', () {
      mgr.depthLayerOpacity = -0.5;
      expect(mgr.depthLayerOpacity, 0.0);
    });

    test('opacity above 1 is clamped to 1', () {
      mgr.depthLayerOpacity = 1.5;
      expect(mgr.depthLayerOpacity, 1.0);
    });

    test('opacity at exact boundary 0.0 is accepted', () {
      mgr.depthLayerOpacity = 0.0;
      expect(mgr.depthLayerOpacity, 0.0);
    });

    test('opacity at exact boundary 1.0 is accepted', () {
      mgr.depthLayerOpacity = 1.0;
      expect(mgr.depthLayerOpacity, 1.0);
    });
  });

  // ── brushRadius clamping ─────────────────────────────────────────────────────

  group('MapLayerManager — brushRadius clamped to [1, 5]', () {
    late MapLayerManager mgr;
    setUp(() => mgr = MapLayerManager());
    tearDown(() => mgr.dispose());

    test('brushRadius below 1 is clamped to 1', () {
      mgr.brushRadius = 0;
      expect(mgr.brushRadius, 1);
    });

    test('brushRadius above 5 is clamped to 5', () {
      mgr.brushRadius = 10;
      expect(mgr.brushRadius, 5);
    });

    test('brushRadius 3 is accepted as-is', () {
      mgr.brushRadius = 3;
      expect(mgr.brushRadius, 3);
    });
  });

  // ── Mutual exclusion: admin and feature edit modes ───────────────────────────

  group('MapLayerManager — admin/feature edit mode mutual exclusion', () {
    late MapLayerManager mgr;
    setUp(() => mgr = MapLayerManager());
    tearDown(() => mgr.dispose());

    test('enabling adminEditMode disables featureEditMode', () {
      mgr.isFeatureEditMode = true;
      mgr.isAdminEditMode = true;
      expect(mgr.isAdminEditMode, isTrue);
      expect(mgr.isFeatureEditMode, isFalse);
    });

    test('enabling featureEditMode disables adminEditMode', () {
      mgr.isAdminEditMode = true;
      mgr.isFeatureEditMode = true;
      expect(mgr.isFeatureEditMode, isTrue);
      expect(mgr.isAdminEditMode, isFalse);
    });

    test('both modes can be false simultaneously', () {
      mgr.isAdminEditMode = false;
      mgr.isFeatureEditMode = false;
      expect(mgr.isAdminEditMode, isFalse);
      expect(mgr.isFeatureEditMode, isFalse);
    });
  });

  // ── toggleSpecies ─────────────────────────────────────────────────────────────

  group('MapLayerManager — toggleSpecies', () {
    late MapLayerManager mgr;
    setUp(() => mgr = MapLayerManager());
    tearDown(() => mgr.dispose());

    test('toggling a present species removes it', () {
      expect(mgr.selectedSpecies.contains(FishSpecies.shrimp), isTrue);
      mgr.toggleSpecies(FishSpecies.shrimp);
      expect(mgr.selectedSpecies.contains(FishSpecies.shrimp), isFalse);
    });

    test('toggling an absent species adds it', () {
      mgr.toggleSpecies(FishSpecies.shrimp); // remove
      mgr.toggleSpecies(FishSpecies.shrimp); // re-add
      expect(mgr.selectedSpecies.contains(FishSpecies.shrimp), isTrue);
    });

    test('toggleSpecies notifies listeners', () {
      int count = 0;
      mgr.addListener(() => count++);
      mgr.toggleSpecies(FishSpecies.seaBass);
      expect(count, 1);
    });

    test('selectedSpecies getter returns an unmodifiable view', () {
      expect(
        () => (mgr.selectedSpecies as dynamic).add(FishSpecies.shrimp),
        throwsUnsupportedError,
      );
    });
  });

  // ── resetToDefaults ──────────────────────────────────────────────────────────

  group('MapLayerManager — resetToDefaults', () {
    late MapLayerManager mgr;
    setUp(() => mgr = MapLayerManager());
    tearDown(() => mgr.dispose());

    test('resetToDefaults restores all fields to initial values', () {
      mgr.showDepthLayer = true;
      mgr.showFishProbabilityHeatmap = true;
      mgr.showExclusionZones = true;
      mgr.depthLayerOpacity = 0.3;
      mgr.depthVisualizationType = DepthVisualizationType.combined;
      mgr.toggleSpecies(FishSpecies.shrimp); // remove one species
      mgr.isAdminEditMode = true;
      mgr.brushRadius = 4;

      mgr.resetToDefaults();

      expect(mgr.showBaseMap, isTrue);
      expect(mgr.showDepthLayer, isFalse);
      expect(mgr.showFishProbabilityHeatmap, isFalse);
      expect(mgr.showExclusionZones, isFalse);
      expect(mgr.depthLayerOpacity, closeTo(0.7, 0.0001));
      expect(mgr.depthVisualizationType, DepthVisualizationType.bathymetric);
      expect(mgr.selectedSpecies.length, 4);
      expect(mgr.showLayerControls, isFalse);
      expect(mgr.isFeatureEditMode, isFalse);
    });

    test('resetToDefaults notifies listeners', () {
      int count = 0;
      mgr.addListener(() => count++);
      mgr.resetToDefaults();
      expect(count, 1);
    });
  });

  // ── DepthVisualizationType extension ────────────────────────────────────────

  group('DepthVisualizationType — displayName and description', () {
    test('bathymetric has non-empty displayName and description', () {
      expect(DepthVisualizationType.bathymetric.displayName, isNotEmpty);
      expect(DepthVisualizationType.bathymetric.description, isNotEmpty);
    });

    test('nautical has non-empty displayName and description', () {
      expect(DepthVisualizationType.nautical.displayName, isNotEmpty);
      expect(DepthVisualizationType.nautical.description, isNotEmpty);
    });

    test('combined has non-empty displayName and description', () {
      expect(DepthVisualizationType.combined.displayName, isNotEmpty);
      expect(DepthVisualizationType.combined.description, isNotEmpty);
    });

    test('all displayNames are distinct', () {
      final names = DepthVisualizationType.values.map((e) => e.displayName).toSet();
      expect(names.length, DepthVisualizationType.values.length);
    });
  });

  // ── AdminBrushType enum ──────────────────────────────────────────────────────

  group('AdminBrushType enum', () {
    test('has exactly three values', () {
      expect(AdminBrushType.values.length, 3);
    });

    test('contains water, land, and eraser', () {
      expect(AdminBrushType.values, containsAll([
        AdminBrushType.water,
        AdminBrushType.land,
        AdminBrushType.eraser,
      ]));
    });
  });
}

// import 'package:bahaar/models/map/editable_map_feature.dart';
// import 'package:flutter/foundation.dart';
// import 'package:latlong2/latlong.dart';

// //delete this file too

// /// Interaction modes for feature editing
// enum FeatureEditInteraction {
//   browse,
//   select,
//   addPoint,
//   addPolyline,
//   addPolygon,
//   moveFeature,
// }

// /// State machine for feature editing interactions on the map
// class FeatureEditState extends ChangeNotifier {
//   bool _isActive = false;
//   FeatureEditInteraction _interaction = FeatureEditInteraction.browse;
//   MapFeatureType? _selectedFeatureType;
//   EditableMapFeature? _selectedFeature;
//   List<LatLng> _drawingVertices = [];

//   // Getters
//   bool get isActive => _isActive;
//   FeatureEditInteraction get interaction => _interaction;
//   MapFeatureType? get selectedFeatureType => _selectedFeatureType;
//   EditableMapFeature? get selectedFeature => _selectedFeature;
//   List<LatLng> get drawingVertices => List.unmodifiable(_drawingVertices);
//   bool get isDrawing =>
//       _interaction == FeatureEditInteraction.addPolygon ||
//       _interaction == FeatureEditInteraction.addPolyline;
//   bool get hasDrawingVertices => _drawingVertices.isNotEmpty;

//   void enterEditMode() {
//     _isActive = true;
//     _interaction = FeatureEditInteraction.select;
//     _selectedFeature = null;
//     _selectedFeatureType = null;
//     _drawingVertices = [];
//     notifyListeners();
//   }

//   void exitEditMode() {
//     _isActive = false;
//     _interaction = FeatureEditInteraction.browse;
//     _selectedFeature = null;
//     _selectedFeatureType = null;
//     _drawingVertices = [];
//     notifyListeners();
//   }

//   /// Start adding a new feature of the given type.
//   /// Sets the interaction mode based on the feature's geometry type.
//   void startAddFeature(MapFeatureType type) {
//     _selectedFeatureType = type;
//     _selectedFeature = null;
//     _drawingVertices = [];

//     switch (type.geometryType) {
//       case GeometryType.point:
//         _interaction = FeatureEditInteraction.addPoint;
//         break;
//       case GeometryType.lineString:
//         _interaction = FeatureEditInteraction.addPolyline;
//         break;
//       case GeometryType.polygon:
//         _interaction = FeatureEditInteraction.addPolygon;
//         break;
//     }
//     notifyListeners();
//   }

//   void startSelectMode() {
//     _interaction = FeatureEditInteraction.select;
//     _selectedFeature = null;
//     _selectedFeatureType = null;
//     _drawingVertices = [];
//     notifyListeners();
//   }

//   void selectFeature(EditableMapFeature feature) {
//     _selectedFeature = feature;
//     _interaction = FeatureEditInteraction.select;
//     notifyListeners();
//   }

//   void deselectFeature() {
//     _selectedFeature = null;
//     notifyListeners();
//   }

//   void addVertex(LatLng point) {
//     _drawingVertices.add(point);
//     notifyListeners();
//   }

//   void undoLastVertex() {
//     if (_drawingVertices.isNotEmpty) {
//       _drawingVertices.removeLast();
//       notifyListeners();
//     }
//   }

//   /// Returns the drawn vertices and resets drawing state.
//   List<LatLng> confirmDrawing() {
//     final vertices = List<LatLng>.from(_drawingVertices);
//     _drawingVertices = [];
//     _interaction = FeatureEditInteraction.select;
//     notifyListeners();
//     return vertices;
//   }

//   void cancelDrawing() {
//     _drawingVertices = [];
//     _interaction = FeatureEditInteraction.select;
//     _selectedFeatureType = null;
//     notifyListeners();
//   }

//   void startMoveFeature() {
//     if (_selectedFeature != null) {
//       _interaction = FeatureEditInteraction.moveFeature;
//       notifyListeners();
//     }
//   }
// }

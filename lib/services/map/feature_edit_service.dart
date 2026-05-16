// import 'dart:developer';
// import 'package:bahaar/models/fishing/fishing_activity_model.dart';
// import 'package:bahaar/models/map/editable_map_feature.dart';
// import 'package:cloud_firestore/cloud_firestore.dart';

// /// Firestore CRUD service for editable map features and fishing activities
// class FeatureEditService {
//   final _db = FirebaseFirestore.instance;

//   static const String _mapFeaturesCollection = 'map_features';
//   static const String _fishingActivitiesCollection = 'fishing_activities';

//   // ============================================================
//   // Map Features CRUD
//   // ============================================================

//   /// Load all non-deleted map features from Firestore
//   Future<List<EditableMapFeature>> loadMapFeatures() async {
//     try {
//       final snapshot = await _db
//           .collection(_mapFeaturesCollection)
//           .where('deleted', isEqualTo: false)
//           .get();

//       return snapshot.docs
//           .map((doc) => EditableMapFeature.fromFirestore(doc))
//           .toList();
//     } catch (e) {
//       log('Error loading map features: $e');
//       return [];
//     }
//   }

//   /// Add a new map feature, returns the document ID
//   Future<String> addMapFeature(EditableMapFeature feature) async {
//     final doc = await _db
//         .collection(_mapFeaturesCollection)
//         .add(feature.toFirestoreMap());
//     log('Added map feature: ${doc.id} (${feature.name})');
//     return doc.id;
//   }

//   /// Update an existing map feature
//   Future<void> updateMapFeature(EditableMapFeature feature) async {
//     if (feature.id == null) return;
//     await _db
//         .collection(_mapFeaturesCollection)
//         .doc(feature.id)
//         .update(feature.toFirestoreMap());
//     log('Updated map feature: ${feature.id} (${feature.name})');
//   }

//   /// Soft-delete a map feature
//   Future<void> deleteMapFeature(String id) async {
//     await _db.collection(_mapFeaturesCollection).doc(id).update({
//       'deleted': true,
//       'updated_at': FieldValue.serverTimestamp(),
//     });
//     log('Deleted map feature: $id');
//   }

//   // ============================================================
//   // Fishing Activities CRUD
//   // ============================================================

//   /// Load all non-deleted fishing activities from Firestore
//   Future<List<VesselTrack>> loadFishingActivities() async {
//     try {
//       final snapshot = await _db
//           .collection(_fishingActivitiesCollection)
//           .where('deleted', isEqualTo: false)
//           .get();

//       return snapshot.docs.map((doc) {
//         final data = doc.data();
//         data['id'] = doc.id;
//         return VesselTrack.fromJson(data);
//       }).toList();
//     } catch (e) {
//       log('Error loading fishing activities: $e');
//       return [];
//     }
//   }

//   /// Add a new fishing activity, returns the document ID
//   Future<String> addFishingActivity(VesselTrack track) async {
//     final data = track.toJson();
//     data['created_at'] = FieldValue.serverTimestamp();
//     data['updated_at'] = FieldValue.serverTimestamp();
//     data['deleted'] = false;

//     final doc =
//         await _db.collection(_fishingActivitiesCollection).add(data);
//     log('Added fishing activity: ${doc.id} (${track.vesselName})');
//     return doc.id;
//   }

//   /// Update an existing fishing activity
//   Future<void> updateFishingActivity(String id, VesselTrack track) async {
//     final data = track.toJson();
//     data['updated_at'] = FieldValue.serverTimestamp();
//     data['deleted'] = false;

//     await _db
//         .collection(_fishingActivitiesCollection)
//         .doc(id)
//         .update(data);
//     log('Updated fishing activity: $id (${track.vesselName})');
//   }

//   /// Soft-delete a fishing activity
//   Future<void> deleteFishingActivity(String id) async {
//     await _db.collection(_fishingActivitiesCollection).doc(id).update({
//       'deleted': true,
//       'updated_at': FieldValue.serverTimestamp(),
//     });
//     log('Deleted fishing activity: $id');
//   }

//   // ============================================================
//   // Merge logic
//   // ============================================================

//   /// Merge Firestore features with asset-loaded features.
//   /// Firestore features are added on top of asset features.
//   List<EditableMapFeature> mergeFeatures(
//     List<EditableMapFeature> assetFeatures,
//     List<EditableMapFeature> firestoreFeatures,
//   ) {
//     // Start with all asset features
//     final merged = List<EditableMapFeature>.from(assetFeatures);
//     // Add all Firestore features (already filtered for deleted=false)
//     merged.addAll(firestoreFeatures);
//     return merged;
//   }
// }

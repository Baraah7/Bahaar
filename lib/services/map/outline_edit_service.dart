import 'dart:developer';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:latlong2/latlong.dart';

/// A single edit applied to the territorial outline.
/// Each edit stores a geographic point and whether it erases (false) or adds
/// (true) to the boundary. The collection is shared across all users so
/// changes are immediately visible to everyone.
class OutlineEdit {
  final String? id;
  final LatLng point;
  final double radiusDegrees; // brush radius in degrees
  final bool isErase; // true = erase boundary cells in area, false = restore
  final DateTime createdAt;

  OutlineEdit({
    this.id,
    required this.point,
    required this.radiusDegrees,
    required this.isErase,
    required this.createdAt,
  });

  Map<String, dynamic> toFirestore() => {
        'latitude': point.latitude,
        'longitude': point.longitude,
        'radius_degrees': radiusDegrees,
        'is_erase': isErase,
        'created_at': Timestamp.fromDate(createdAt),
        'deleted': false,
      };

  factory OutlineEdit.fromFirestore(DocumentSnapshot doc) {
    final d = doc.data() as Map<String, dynamic>;
    return OutlineEdit(
      id: doc.id,
      point: LatLng(
        (d['latitude'] as num).toDouble(),
        (d['longitude'] as num).toDouble(),
      ),
      radiusDegrees: (d['radius_degrees'] as num).toDouble(),
      isErase: d['is_erase'] as bool? ?? false,
      createdAt: (d['created_at'] as Timestamp?)?.toDate() ?? DateTime.now(),
    );
  }
}

/// Firestore-backed service for territorial outline edits.
/// Changes written here are immediately visible to all users via stream.
class OutlineEditService {
  static const String _collection = 'territorial_outline_edits';

  final FirebaseFirestore _db;

  OutlineEditService({FirebaseFirestore? db})
      : _db = db ?? FirebaseFirestore.instance;

  /// Live stream of all non-deleted outline edits, ordered by creation time.
  Stream<List<OutlineEdit>> watchEdits() {
    return _db
        .collection(_collection)
        .where('deleted', isEqualTo: false)
        .orderBy('created_at')
        .snapshots()
        .map((snap) => snap.docs.map(OutlineEdit.fromFirestore).toList());
  }

  /// Persist a new outline edit to Firestore.
  Future<void> addEdit(OutlineEdit edit) async {
    try {
      await _db.collection(_collection).add(edit.toFirestore());
      log('OutlineEditService: edit saved');
    } catch (e) {
      log('OutlineEditService: save failed — $e');
      rethrow;
    }
  }

  /// Soft-delete an edit (undoes a specific stroke).
  Future<void> deleteEdit(String id) async {
    try {
      await _db.collection(_collection).doc(id).update({
        'deleted': true,
        'deleted_at': FieldValue.serverTimestamp(),
      });
      log('OutlineEditService: edit $id deleted');
    } catch (e) {
      log('OutlineEditService: delete failed — $e');
    }
  }

  /// Remove ALL outline edits (full reset to original boundary).
  Future<void> resetAllEdits() async {
    try {
      final snap = await _db
          .collection(_collection)
          .where('deleted', isEqualTo: false)
          .get();
      final batch = _db.batch();
      for (final doc in snap.docs) {
        batch.update(doc.reference, {
          'deleted': true,
          'deleted_at': FieldValue.serverTimestamp(),
        });
      }
      await batch.commit();
      log('OutlineEditService: all edits reset');
    } catch (e) {
      log('OutlineEditService: reset failed — $e');
    }
  }
}

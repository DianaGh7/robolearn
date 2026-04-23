import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/child_model.dart';
import 'firebase_refs.dart';

class ChildFirestoreService {
  /// Returns all children for [uid], ordered by creation time.
  Future<List<ChildModel>> listChildren({String? uid}) async {
    // Avoid depending on `createdAt` ordering: older docs (or failed writes)
    // may not have timestamps, and `orderBy` can cause empty results/errors.
    final snap = await FirebaseRefs.childrenCol(uid).get();
    final kids = snap.docs.map((d) => ChildModel.fromFirestore(d)).toList();
    kids.sort((a, b) => a.name.toLowerCase().compareTo(b.name.toLowerCase()));
    return kids;
  }

  /// Creates a new child document and returns the saved [ChildModel]
  /// with its real Firestore [childId] populated.
  Future<ChildModel> createChild({
    String? uid,
    required ChildModel child,
  }) async {
    final col = FirebaseRefs.childrenCol(uid);
    final doc = col.doc(); // auto-generated id

    // Build the data map; toFirestore() adds createdAt + updatedAt timestamps.
    final data = child.toFirestore();

    await doc.set(data);

    // Return the model enriched with the real document id.
    return child.copyWith(childId: doc.id);
  }

  /// Merges [child] fields into an existing document (upsert).
  Future<void> saveChild({
    required String childId,
    String? uid,
    required ChildModel child,
  }) async {
    final data = child.toFirestore(includeTimestamps: false);
    data['updatedAt'] = FieldValue.serverTimestamp();

    await FirebaseRefs.childDoc(childId, uid).set(
      data,
      SetOptions(merge: true),
    );
  }

  /// Deletes a child document permanently.
  Future<void> deleteChild({
    required String childId,
    String? uid,
  }) async {
    await FirebaseRefs.childDoc(childId, uid).delete();
  }

  /// Live stream of children for [uid].
  Stream<List<ChildModel>> watchChildren({String? uid}) {
    return FirebaseRefs.childrenCol(uid).snapshots().map((snap) {
      final kids = snap.docs.map((d) => ChildModel.fromFirestore(d)).toList();
      kids.sort((a, b) => a.name.toLowerCase().compareTo(b.name.toLowerCase()));
      return kids;
    });
  }
}
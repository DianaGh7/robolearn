import 'package:cloud_firestore/cloud_firestore.dart';
import 'firebase_refs.dart';

class ParentService {
  Future<void> upsertParentProfile({
    required String uid,
    required String email,
    String? displayName,
  }) async {
    final doc = FirebaseRefs.parentDoc(uid);
    await doc.set(
      <String, dynamic>{
        'uid': uid,
        'email': email,
        'displayName': displayName,
        'updatedAt': FieldValue.serverTimestamp(),
        'createdAt': FieldValue.serverTimestamp(),
      },
      SetOptions(merge: true),
    );
  }
}


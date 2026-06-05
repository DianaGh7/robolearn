import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

class FirebaseRefs {
  static FirebaseAuth get auth => FirebaseAuth.instance;
  static FirebaseFirestore get firestore => FirebaseFirestore.instance;

  static String requireUid() {
    final uid = auth.currentUser?.uid;
    if (uid == null) {
      throw StateError('User must be signed in.');
    }
    return uid;
  }

  static DocumentReference<Map<String, dynamic>> parentDoc([String? uid]) {
    final resolvedUid = uid ?? requireUid();
    return firestore.collection('parents').doc(resolvedUid);
  }

  static CollectionReference<Map<String, dynamic>> childrenCol([String? uid]) {
    final resolvedUid = uid ?? requireUid();
    return parentDoc(resolvedUid).collection('children');
  }

  static DocumentReference<Map<String, dynamic>> childDoc(
    String childId, [
    String? uid,
  ]) {
    return childrenCol(uid).doc(childId);
  }
}


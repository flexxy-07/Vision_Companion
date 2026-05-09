import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

class HistoryRepository {
  final FirebaseFirestore _db = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;

  Future<void> saveHistory({
    required String featureType,
    required String resultSummary,
  }) async {
    final uid = _auth.currentUser?.uid;
    if (uid == null) return;
    await _db.collection('users').doc(uid).collection('history').add({
      'timestamp': FieldValue.serverTimestamp(),
      'featureType': featureType,
      'resultSummary': resultSummary,
    });
  }
}

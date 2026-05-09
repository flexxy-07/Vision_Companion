import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

class HistoryRepository {
  final FirebaseFirestore _db = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;

  String? get _uid => _auth.currentUser?.uid;

  Future<void> saveHistory({
    required String featureType,
    required String resultSummary,
  }) async {
    final uid = _uid;
    if (uid == null) return;
    await _db.collection('users').doc(uid).collection('history').add({
      'timestamp': FieldValue.serverTimestamp(),
      'featureType': featureType,
      'resultSummary': resultSummary,
    });
  }

  Stream<List<HistoryEntry>> watchHistory() {
    final uid = _uid;
    if (uid == null) return const Stream.empty();
    return _db
        .collection('users')
        .doc(uid)
        .collection('history')
        .orderBy('timestamp', descending: true)
        .limit(50)
        .snapshots()
        .map((snap) => snap.docs.map((d) => HistoryEntry.fromDoc(d)).toList());
  }
}

class HistoryEntry {
  final String id;
  final String featureType;
  final String resultSummary;
  final DateTime? timestamp;

  HistoryEntry({
    required this.id,
    required this.featureType,
    required this.resultSummary,
    this.timestamp,
  });

  factory HistoryEntry.fromDoc(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    return HistoryEntry(
      id: doc.id,
      featureType: data['featureType'] as String? ?? '',
      resultSummary: data['resultSummary'] as String? ?? '',
      timestamp: (data['timestamp'] as Timestamp?)?.toDate(),
    );
  }
}

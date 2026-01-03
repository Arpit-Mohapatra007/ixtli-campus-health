import 'package:cloud_firestore/cloud_firestore.dart';

class DoctorService {
  final FirebaseFirestore _db = FirebaseFirestore.instance;

  Stream<QuerySnapshot> getPendingAppointments() {
    return _db.collection('appointments')
        .where('status', isEqualTo: 'pending')
        .orderBy('date')
        .snapshots();
  }

  Stream<QuerySnapshot> getApprovedQueue() {
    return _db.collection('appointments')
        .where('status', isEqualTo: 'approved')
        .orderBy('token_number') 
        .snapshots();
  }

  Future<void> admitStudent(String docId) async {
    await _db.runTransaction((transaction) async {
      final now = DateTime.now();
      final todayStart = DateTime(now.year, now.month, now.day);
      final todayTimestamp = Timestamp.fromDate(todayStart);

      final querySnapshot = await _db.collection('appointments')
          .where('status', whereIn: ['approved', 'treating', 'completed'])
          .where('date', isGreaterThanOrEqualTo: todayTimestamp)
          .orderBy('date') 
          .get(); 

      int nextToken = 1;
      if (querySnapshot.docs.isNotEmpty) {
         int maxToken = 0;
        for (var doc in querySnapshot.docs) {
          final t = doc.data()['token_number'] as int? ?? 0;
          if (t > maxToken) maxToken = t;
        }
        nextToken = maxToken + 1;
      }

      final docRef = _db.collection('appointments').doc(docId);
      transaction.update(docRef, {
        'status': 'approved',
        'token_number': nextToken,
      });
    });
  }

  Future<void> callPatient(String docId) async {
    await _db.collection('appointments').doc(docId).update({
      'status': 'treating',
    });
  }
  
  Future<void> rejectStudent(String docId) async {
    await _db.collection('appointments').doc(docId).update({'status': 'rejected'});
  }
}
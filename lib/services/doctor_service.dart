import 'package:cloud_firestore/cloud_firestore.dart';

class DoctorService {
  final FirebaseFirestore _db = FirebaseFirestore.instance;

  Stream<QuerySnapshot> getPendingAppointments() {
    return _db
        .collection('appointments')
        .where('status', isEqualTo: 'pending')
        .orderBy('date', descending: false)
        .snapshots();
  }

  Future<void> updateStatus(String docId, String newStatus) async {
    await _db.collection('appointments').doc(docId).update({
      'status': newStatus,
    });
  }
}
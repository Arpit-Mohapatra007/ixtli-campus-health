import 'package:cloud_firestore/cloud_firestore.dart';
import '../utils/app_exception.dart';

class SosService {
  final FirebaseFirestore _db = FirebaseFirestore.instance;
  
  Future<void> sendSOS({
    required String studentId,
    required String name,
    required String hostel,
    required String room,
    required String contact,
    required String bloodGroup,
    required String age,
  }) async {
    final existing = await _db.collection('emergencies')
        .where('studentId', isEqualTo: studentId)
        .where('status', whereIn: ['pending', 'on_way'])
        .get();

    if (existing.docs.isNotEmpty) {
      throw AppException("Help is already active! Please wait for the ambulance.");
    }

    await _db.collection('emergencies').add({
      'studentId': studentId,
      'studentName': name,
      'hostel': hostel,
      'roomNumber': room,
      'contact': contact,
      'bloodGroup': bloodGroup,
      'age': age,
      'status': 'pending', 
      'timestamp': FieldValue.serverTimestamp(),
    });
  }

  Stream<DocumentSnapshot?> streamMyActiveEmergency(String studentId) {
    return _db.collection('emergencies')
        .where('studentId', isEqualTo: studentId)
        .where('status', whereIn: ['pending', 'on_way'])
        .limit(1)
        .snapshots()
        .map((snapshot) {
          if (snapshot.docs.isNotEmpty) return snapshot.docs.first;
          return null;
        });
  }

  Stream<QuerySnapshot> getActiveEmergencies() {
    return _db.collection('emergencies')
        .where('status', whereIn: ['pending', 'on_way'])
        .orderBy('timestamp', descending: true)
        .snapshots();
  }

  Future<void> updateStatus(String docId, String status) async {
    await _db.collection('emergencies').doc(docId).update({'status': status});
  }
}
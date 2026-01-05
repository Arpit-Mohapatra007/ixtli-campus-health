import 'package:cloud_firestore/cloud_firestore.dart';

class DoctorService {
  final FirebaseFirestore _db = FirebaseFirestore.instance;

  Stream<QuerySnapshot> getPendingAppointments(String specialization) {
    return _db.collection('appointments')
        .where('status', isEqualTo: 'pending')
        .where('category', isEqualTo: specialization)
        .orderBy('date')
        .snapshots();
  }

  Stream<QuerySnapshot> getApprovedQueue() {
    final now = DateTime.now();

    final startOfDay = DateTime.utc(now.year, now.month, now.day);

    return _db.collection('appointments')
        .where('status', isEqualTo: 'approved')
        .where('date', isGreaterThanOrEqualTo: Timestamp.fromDate(startOfDay))
        .orderBy('date')         
        .orderBy('token_number') 
        .snapshots();
  }

  Future<void> admitStudent(String docId) async {
    final docRef = _db.collection('appointments').doc(docId);

    final docSnap = await docRef.get();
    if (!docSnap.exists) return;
    
    final data = docSnap.data()!;
    final Timestamp dateTs = data['date'];
    final DateTime date = dateTs.toDate();

    final dateStr = "${date.year}-${date.month}-${date.day}";
    final counterRef = _db.collection('clinic_counters').doc('daily_counter_$dateStr');

    await _db.runTransaction((transaction) async {
      final counterSnap = await transaction.get(counterRef);
      int nextToken = 1;
      
      if (counterSnap.exists) {
        nextToken = (counterSnap.get('last_token') as int) + 1;
        transaction.update(counterRef, {'last_token': nextToken});
      } else {
        transaction.set(counterRef, {
          'last_token': 1,
          'date': Timestamp.fromDate(date)
        });
      }

      transaction.update(docRef, {
        'status': 'approved',
        'token_number': nextToken,
        'admitted_at': FieldValue.serverTimestamp(),
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

  Stream<List<Map<String, dynamic>>> getAllDoctors() {
    return _db.collection('users')
        .where('role', isEqualTo: 'doctor')
        .snapshots()
        .map((snapshot) => snapshot.docs.map((doc) => {
              ...doc.data(),
              'id': doc.id,
            }).toList());
  }
}
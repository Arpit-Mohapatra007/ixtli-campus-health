import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart'; 

class AppointmentService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  Future<void> requestAppointment({
    required String studentId,
    required String studentName,
    required String reason,
    required String hostel,
    required DateTime date,
    required String category,
    required String bloodGroup,
    required DateTime? dob,     
  }) async {
    final existing = await _firestore
        .collection('appointments')
        .where('studentId', isEqualTo: studentId)
        .where('status', whereIn: ['pending', 'approved'])
        .get();

    if (existing.docs.isNotEmpty) {
      throw Exception("You already have an active appointment.");
    }

    await _firestore.collection('appointments').add({
      'studentId': studentId,
      'studentName': studentName,
      'reason': reason,
      'hostel': hostel,
      'category': category,
      'date': Timestamp.fromDate(date),
      'status': 'pending',
      'bloodGroup': bloodGroup,
      'dob': dob != null ? Timestamp.fromDate(dob) : null, 
      'timestamp': FieldValue.serverTimestamp(),
      'token_number': null,
    });
  }

  Future<void> admitPatient(String appointmentId) async {
    final appointmentRef = _firestore.collection('appointments').doc(appointmentId);
    
    final docSnap = await appointmentRef.get();
    if (!docSnap.exists) throw Exception("Appointment not found");
    
    final data = docSnap.data() as Map<String, dynamic>;
    final Timestamp dateTs = data['date'];
    final DateTime date = dateTs.toDate();

    final dateStr = "${date.year}-${date.month}-${date.day}"; 
    final counterDocId = 'daily_counter_$dateStr';
    final counterRef = _firestore.collection('clinic_counters').doc(counterDocId);

    try {
      await _firestore.runTransaction((transaction) async {
        DocumentSnapshot counterSnap = await transaction.get(counterRef);
        
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

        transaction.update(appointmentRef, {
          'status': 'approved',
          'token_number': nextToken,
          'admitted_at': FieldValue.serverTimestamp(),
        });
      });
    } catch (e) {
      throw Exception(e.toString());
    }
  }

  Stream<int> watchCurrentServing() {
    final now = DateTime.now();
    final startOfDay = DateTime.utc(now.year, now.month, now.day);
    final endOfDay = DateTime.utc(now.year, now.month, now.day, 23, 59, 59);

    return _firestore
        .collection('appointments')
        .where('status', isEqualTo: 'approved')
        .where('date', isGreaterThanOrEqualTo: Timestamp.fromDate(startOfDay))
        .where('date', isLessThanOrEqualTo: Timestamp.fromDate(endOfDay))
        .orderBy('date')
        .orderBy('token_number')
        .limit(1)
        .snapshots()
        .map((snapshot) {
          if (snapshot.docs.isEmpty) return 0;
          return snapshot.docs.first.data()['token_number'] as int;
        });
  }

  Stream<DocumentSnapshot?> watchActiveAppointment() {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return Stream.value(null);

    return _firestore
        .collection('appointments')
        .where('studentId', isEqualTo: user.uid)
        .where('status', whereIn: ['pending', 'approved'])
        .limit(1)
        .snapshots()
        .map((snapshot) => snapshot.docs.isNotEmpty ? snapshot.docs.first : null);
  }
}
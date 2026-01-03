import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:firebase_auth/firebase_auth.dart'; 

final appointmentServiceProvider = Provider((ref) => AppointmentService());

final currentServingProvider = StreamProvider<int>((ref) {
  final service = ref.watch(appointmentServiceProvider);
  return service.watchCurrentServing();
});

final myActiveAppointmentProvider = StreamProvider<DocumentSnapshot?>((ref) {
  final service = ref.watch(appointmentServiceProvider);
  return service.watchActiveAppointment();
});

class AppointmentService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  Future<void> admitPatient(String appointmentId) async {
    final now = DateTime.now();
    final todayStr = "${now.year}-${now.month}-${now.day}"; 
    final counterDocId = 'daily_counter_$todayStr';

    final appointmentRef = _firestore.collection('appointments').doc(appointmentId);
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
            'date': Timestamp.fromDate(now)
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
    final startOfDay = DateTime(now.year, now.month, now.day);

    return _firestore
        .collection('appointments')
        .where('status', isEqualTo: 'approved')
        .where('date', isGreaterThanOrEqualTo: Timestamp.fromDate(startOfDay))
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
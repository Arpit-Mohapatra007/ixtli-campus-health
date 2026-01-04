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

  Future<void> requestAppointment({
    required String studentId,
    required String studentName,
    required String reason,
    required String hostel,
    required DateTime date,
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
      'date': Timestamp.fromDate(date),
      'status': 'pending',
      'timestamp': FieldValue.serverTimestamp(),
      'token_number': null,
    });
  }

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
        .where('admitted_at', isGreaterThanOrEqualTo: Timestamp.fromDate(startOfDay))
        .orderBy('admitted_at')
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
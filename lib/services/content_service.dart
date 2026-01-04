import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';

final contentServiceProvider = Provider<ContentService>((ref) => ContentService());

final hospitalsProvider = StreamProvider((ref) => ref.watch(contentServiceProvider).getHospitals());
final contactsProvider = StreamProvider((ref) => ref.watch(contentServiceProvider).getContacts());
final specialistScheduleProvider = StreamProvider((ref) => ref.watch(contentServiceProvider).getSpecialistSchedule());

class ContentService {
  final FirebaseFirestore _db = FirebaseFirestore.instance;

  Stream<List<Map<String, dynamic>>> getHospitals() {
    return _db.collection('hospitals').snapshots().map((snapshot) => 
      snapshot.docs.map((doc) => {...doc.data(), 'id': doc.id}).toList());
  }

  Future<void> addHospital(Map<String, dynamic> data) async {
    await _db.collection('hospitals').add(data);
  }

  Future<void> deleteHospital(String id) async {
    await _db.collection('hospitals').doc(id).delete();
  }

  Stream<List<Map<String, dynamic>>> getContacts() {
    return _db.collection('contacts').orderBy('priority').snapshots().map((snapshot) => 
      snapshot.docs.map((doc) => {...doc.data(), 'id': doc.id}).toList());
  }

  Future<void> addContact(Map<String, dynamic> data) async {
    await _db.collection('contacts').add(data);
  }

  Future<void> deleteContact(String id) async {
    await _db.collection('contacts').doc(id).delete();
  }

  Stream<List<Map<String, dynamic>>> getSpecialistSchedule() {
    final now = DateTime.now();
    final oneMonthLater = now.add(const Duration(days: 30));

    return _db.collection('specialist_schedule')
        .where('date', isGreaterThanOrEqualTo: Timestamp.fromDate(now))
        .where('date', isLessThanOrEqualTo: Timestamp.fromDate(oneMonthLater))
        .orderBy('date')
        .snapshots()
        .map((snapshot) => snapshot.docs.map((doc) => {
              ...doc.data(),
              'id': doc.id,
              'date': (doc.data()['date'] as Timestamp).toDate(),
            }).toList());
  }

  Future<void> addSpecialistVisit(DateTime date, String specialist) async {
    final cleanDate = DateTime(date.year, date.month, date.day);
    await _db.collection('specialist_schedule').add({
      'date': Timestamp.fromDate(cleanDate),
      'specialist': specialist,
    });
  }

  Future<void> deleteSpecialistVisit(String id) async {
    await _db.collection('specialist_schedule').doc(id).delete();
  }
}
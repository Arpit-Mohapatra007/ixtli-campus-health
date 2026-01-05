import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../services/doctor_service.dart';

final doctorServiceProvider = Provider<DoctorService>((ref) {
  return DoctorService();
});

final pendingAppointmentsProvider = StreamProvider.autoDispose<QuerySnapshot>((ref) {
  final service = ref.watch(doctorServiceProvider);
  return service.getPendingAppointments();
});

final approvedQueueProvider = StreamProvider.autoDispose<QuerySnapshot>((ref) {
  final service = ref.watch(doctorServiceProvider);
  return service.getApprovedQueue();
});

final allDoctorsProvider = StreamProvider.autoDispose<List<Map<String, dynamic>>>((ref) {
  return ref.watch(doctorServiceProvider).getAllDoctors();
});
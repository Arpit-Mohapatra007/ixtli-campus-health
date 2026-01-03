import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../services/doctor_service.dart';

final doctorServiceProvider = Provider<DoctorService>((ref) {
  return DoctorService();
});

final pendingAppointmentsProvider = StreamProvider<QuerySnapshot>((ref) {
  final service = ref.watch(doctorServiceProvider);
  return service.getPendingAppointments();
});
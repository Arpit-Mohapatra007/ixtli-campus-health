import 'package:cloud_firestore/cloud_firestore.dart' show DocumentSnapshot;
import 'package:hooks_riverpod/hooks_riverpod.dart';
import '../services/appointment_service.dart' show AppointmentService;

final appointmentServiceProvider = Provider((ref) => AppointmentService());

final currentServingProvider = StreamProvider.autoDispose<int>((ref) {
  final service = ref.watch(appointmentServiceProvider);
  return service.watchCurrentServing();
});

final myActiveAppointmentProvider = StreamProvider.autoDispose<DocumentSnapshot?>((ref) {
  final service = ref.watch(appointmentServiceProvider);
  return service.watchActiveAppointment();
});
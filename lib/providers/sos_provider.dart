import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../services/sos_service.dart';
import '../providers/auth_provider.dart';

final sosServiceProvider = Provider<SosService>((ref) => SosService());

final activeEmergenciesProvider = StreamProvider.autoDispose<QuerySnapshot>((ref) {
  return ref.watch(sosServiceProvider).getActiveEmergencies();
});

final myEmergencyStatusProvider = StreamProvider.autoDispose<DocumentSnapshot?>((ref) {
  final user = ref.watch(authServiceProvider).currentUser;
  if (user == null) return const Stream.empty();
  
  return ref.watch(sosServiceProvider).streamMyActiveEmergency(user.uid);
});
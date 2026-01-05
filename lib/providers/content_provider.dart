import 'package:hooks_riverpod/hooks_riverpod.dart';
import '../services/content_service.dart' show ContentService;

final contentServiceProvider = Provider<ContentService>((ref) => ContentService());
final hospitalsProvider = StreamProvider.autoDispose((ref) => ref.watch(contentServiceProvider).getHospitals());
final contactsProvider = StreamProvider.autoDispose((ref) => ref.watch(contentServiceProvider).getContacts());
final specialistScheduleProvider = StreamProvider.autoDispose((ref) => ref.watch(contentServiceProvider).getSpecialistSchedule());

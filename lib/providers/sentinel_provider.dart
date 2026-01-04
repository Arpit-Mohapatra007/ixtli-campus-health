import 'package:hooks_riverpod/hooks_riverpod.dart';
import '../services/sentinel_service.dart';

final sentinelServiceProvider = Provider<SentinelService>((ref) => SentinelService());

final outbreakAlertsProvider = StreamProvider<List<Map<String, dynamic>>>((ref) {
  return ref.watch(sentinelServiceProvider).getOutbreakAlerts();
});
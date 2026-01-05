import 'package:flutter/material.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:intl/intl.dart';
import '../../../providers/content_provider.dart';
import '../../../providers/user_provider.dart';

class ScheduleTab extends ConsumerWidget {
  const ScheduleTab({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final scheduleAsync = ref.watch(specialistScheduleProvider);
    final user = ref.watch(currentUserProfileProvider).value;

    if (user == null || user.specialization == null) {
      return const Center(child: Text("Profile info missing."));
    }

    final mySpeciality = user.specialization!;

    return Scaffold(
      backgroundColor: const Color(0xFFF5F5F5),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              "My Visit Schedule",
              style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: Colors.teal),
            ),
            const SizedBox(height: 5),
            Text(
              "Upcoming dates for $mySpeciality", 
              style: TextStyle(color: Colors.grey[600]),
            ),
            const SizedBox(height: 15),
            
            Expanded(
              child: scheduleAsync.when(
                loading: () => const Center(child: CircularProgressIndicator()),
                error: (e, _) => Center(child: Text("Error: $e")),
                data: (allSchedules) {
                  final mySchedule = allSchedules.where((item) => 
                    item['specialist'].toString().toLowerCase() == mySpeciality.toLowerCase()
                  ).toList();

                  if (mySchedule.isEmpty) {
                    return Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(Icons.event_available, size: 50, color: Colors.grey[400]),
                          const SizedBox(height: 10),
                          Text("No visits scheduled for you yet.", style: TextStyle(color: Colors.grey[600])),
                        ],
                      ),
                    );
                  }

                  return ListView.builder(
                    itemCount: mySchedule.length,
                    itemBuilder: (context, index) {
                      final item = mySchedule[index];
                      final date = item['date'] as DateTime;
                      final isToday = DateUtils.isSameDay(date, DateTime.now());

                      return Card(
                        elevation: isToday ? 4 : 1,
                        margin: const EdgeInsets.only(bottom: 12),
                        color: isToday ? Colors.teal[50] : Colors.white,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                          side: isToday ? const BorderSide(color: Colors.teal, width: 1.5) : BorderSide.none,
                        ),
                        child: ListTile(
                          contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                          leading: Container(
                            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                            decoration: BoxDecoration(
                              color: isToday ? Colors.teal : Colors.blueGrey[50],
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: Column(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Text(
                                  DateFormat('MMM').format(date).toUpperCase(),
                                  style: TextStyle(
                                    fontSize: 10, 
                                    fontWeight: FontWeight.bold,
                                    color: isToday ? Colors.white : Colors.blueGrey,
                                  ),
                                ),
                                Text(
                                  DateFormat('d').format(date),
                                  style: TextStyle(
                                    fontSize: 18, 
                                    fontWeight: FontWeight.bold,
                                    color: isToday ? Colors.white : Colors.blueGrey[800],
                                  ),
                                ),
                              ],
                            ),
                          ),
                          title: Text(
                            isToday ? "Your Visit is TODAY" : "Scheduled Visit",
                            style: TextStyle(
                              fontWeight: FontWeight.bold, 
                              fontSize: 16,
                              color: isToday ? Colors.teal[800] : Colors.black87
                            ),
                          ),
                          subtitle: Text(
                            DateFormat('EEEE').format(date),
                            style: TextStyle(color: Colors.grey[600]),
                          ),
                        ),
                      );
                    },
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
}
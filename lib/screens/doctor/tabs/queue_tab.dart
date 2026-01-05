import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:intl/intl.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:campus_health/providers/doctor_provider.dart'; 
import '../../../providers/auth_provider.dart' show authServiceProvider;
import '../../../providers/chat_provider.dart' show chatServiceProvider;
import '../../../providers/user_provider.dart'; 

class LiveQueueTab extends ConsumerWidget {
  const LiveQueueTab({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final queueAsync = ref.watch(approvedQueueProvider);
    final doctorProfile = ref.watch(currentUserProfileProvider).value;

    return queueAsync.when(
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (e, _) => Center(child: Text("Error: $e")),
      data: (snapshot) {
        if (snapshot.docs.isEmpty) {
           return Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.coffee, size: 50, color: Colors.grey[400]),
                const SizedBox(height: 10),
                const Text("Queue is empty !", style: TextStyle(color: Colors.grey)),
              ],
            ),
          );
        }

        final Map<String, List<DocumentSnapshot>> groupedQueue = {};
        for (var doc in snapshot.docs) {
          final data = doc.data() as Map<String, dynamic>;
          final Timestamp ts = data['date'];
          final date = ts.toDate();
          final dateKey = DateFormat('EEEE, MMM d, yyyy').format(date);
          
          if (!groupedQueue.containsKey(dateKey)) {
            groupedQueue[dateKey] = [];
          }
          groupedQueue[dateKey]!.add(doc);
        }

        return ListView.builder(
          padding: const EdgeInsets.all(12),
          itemCount: groupedQueue.length,
          itemBuilder: (ctx, sectionIndex) {
            final dateKey = groupedQueue.keys.elementAt(sectionIndex);
            final appointments = groupedQueue[dateKey]!;
            final isToday = dateKey == DateFormat('EEEE, MMM d, yyyy').format(DateTime.now());

            return Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 4),
                  margin: const EdgeInsets.only(top: 10),
                  child: Row(
                    children: [
                      Icon(Icons.event, color: isToday ? Colors.teal : Colors.grey),
                      const SizedBox(width: 8),
                      Text(
                        isToday ? "TODAY'S QUEUE" : dateKey.toUpperCase(),
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          color: isToday ? Colors.teal[800] : Colors.grey[700],
                          fontSize: 14,
                          letterSpacing: 1.0
                        ),
                      ),
                    ],
                  ),
                ),
                ...appointments.map((doc) {
                  final data = doc.data() as Map<String, dynamic>;
                  final token = data['token_number'] ?? '?';
                  final name = data['studentName'] ?? 'Unknown';
                  final isFirstOfToday = isToday && appointments.first.id == doc.id;

                  return Card(
                    elevation: isFirstOfToday ? 4 : 1,
                    color: isFirstOfToday ? Colors.teal[50] : Colors.white,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                      side: isFirstOfToday ? const BorderSide(color: Colors.teal, width: 2) : BorderSide.none,
                    ),
                    margin: const EdgeInsets.symmetric(vertical: 6),
                    child: ListTile(
                      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                      leading: CircleAvatar(
                        radius: 25,
                        backgroundColor: isFirstOfToday ? Colors.teal : Colors.blueGrey[100],
                        child: Text(
                          "#$token", 
                          style: TextStyle(
                            color: isFirstOfToday ? Colors.white : Colors.black54, 
                            fontWeight: FontWeight.bold,
                            fontSize: 18
                          )
                        ),
                      ),
                      title: Text(name, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16, color: Colors.black87)),
                      subtitle: Text(
                        isFirstOfToday ? "Ready for treatment" : (isToday ? "Waiting in line" : "Approved for future"), 
                        style: TextStyle(color: isFirstOfToday ? Colors.teal[700] : Colors.grey)
                      ),
                      trailing: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          IconButton(
                            icon: const Icon(Icons.message, color: Colors.blue),
                            onPressed: () async {
                              final doctor = ref.read(authServiceProvider).currentUser;
                              if (doctor == null || doctorProfile == null) return;

                              final chatId = await ref.read(chatServiceProvider).getChatRoomId(
                                studentId: data['studentId'],
                                studentName: data['studentName'],
                                doctorId: doctor.uid,
                                doctorName: doctorProfile.name,
                              );

                              if (context.mounted) {
                                context.push('/doctor/chat', extra: {
                                  'chatId': chatId,
                                  'otherUserName': data['studentName'],
                                });
                              }
                            },
                          ),
                          const SizedBox(width: 8),
                          ElevatedButton.icon(
                            onPressed: () async {
                              await ref.read(doctorServiceProvider).callPatient(doc.id);
                              
                              if (context.mounted) {
                                final result = await context.push(
                                  '/doctor/consultation', 
                                  extra: {
                                    'appointmentId': doc.id,
                                    'appointmentData': data,
                                  },
                                );
                                
                                if (result == null) {
                                  await ref.read(doctorServiceProvider).undoTreatment(doc.id);
                                }
                              }
                            },
                            icon: const Icon(Icons.medical_services, size: 18), 
                            label: const Text("Treat"), 
                            style: ElevatedButton.styleFrom(
                              backgroundColor: isFirstOfToday ? Colors.teal : Colors.grey,
                              foregroundColor: Colors.white,
                              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
                            ),
                          ),
                        ],
                      ),
                    ),
                  );
                }),
              ],
            );
          },
        );
      },
    );
  }
}
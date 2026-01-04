import 'package:flutter/material.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../providers/doctor_provider.dart';
import '../../../providers/chat_provider.dart';
import '../../../providers/auth_provider.dart';

class PendingRequestsTab extends ConsumerWidget {
  const PendingRequestsTab({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final pendingAsync = ref.watch(pendingAppointmentsProvider);
    
    return pendingAsync.when(
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (e, _) => Center(child: Text("Error: $e")),
      data: (snapshot) {
        if (snapshot.docs.isEmpty) {
          return const Center(child: Text("No pending requests.", style: TextStyle(color: Colors.grey)));
        }
        
        return ListView.builder(
          padding: const EdgeInsets.all(12),
          itemCount: snapshot.docs.length,
          itemBuilder: (ctx, i) {
            final doc = snapshot.docs[i];
            final data = doc.data() as Map<String, dynamic>;
            
            return Card(
              elevation: 2,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              margin: const EdgeInsets.symmetric(vertical: 6),
              child: Padding(
                padding: const EdgeInsets.all(12.0),
                child: Column(
                  children: [
                    ListTile(
                      contentPadding: EdgeInsets.zero,
                      title: Text(
                        "${data['studentName']}", 
                        style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16)
                      ),
                      subtitle: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const SizedBox(height: 4),
                          Text("Symptoms: ${data['reason'] ?? 'None'}", style: const TextStyle(color: Color.fromARGB(221, 241, 249, 3))),
                          const SizedBox(height: 4),
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                            decoration: BoxDecoration(color: Colors.orange[50], borderRadius: BorderRadius.circular(4)),
                            child: Text(
                              "Hostel: ${data['hostel'] ?? '?'}", 
                              style: TextStyle(color: Colors.orange[800], fontSize: 12, fontWeight: FontWeight.bold)
                            ),
                          ),
                        ],
                      ),
                      trailing: IconButton(
                        icon: const Icon(Icons.message, color: Colors.blue),
                        onPressed: () async {
                          final doctor = ref.read(authServiceProvider).currentUser;
                          if (doctor == null) return;

                          final chatId = await ref.read(chatServiceProvider).getChatRoomId(
                            studentId: data['studentId'],
                            studentName: data['studentName'],
                            doctorId: doctor.uid,
                            doctorName: "Dr. ${doctor.displayName ?? 'Staff'}",
                          );

                          if (context.mounted) {
                            context.push(
                              '/doctor/chat',
                              extra: {
                                'chatId': chatId,
                                'otherUserName': data['studentName'],
                              },
                            );
                          }
                        },
                      ),
                    ),
                    const Divider(),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.end,
                      children: [
                        TextButton.icon(
                          onPressed: () => ref.read(doctorServiceProvider).rejectStudent(doc.id),
                          icon: const Icon(Icons.close, size: 18),
                          label: const Text("Reject"),
                          style: TextButton.styleFrom(foregroundColor: Colors.red),
                        ),
                        const SizedBox(width: 8),
                        ElevatedButton.icon(
                          onPressed: () => ref.read(doctorServiceProvider).admitStudent(doc.id),
                          icon: const Icon(Icons.check, size: 18),
                          label: const Text("Admit"),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.teal, 
                            foregroundColor: Colors.white,
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20))
                          ),
                        ),
                      ],
                    )
                  ],
                ),
              ),
            );
          },
        );
      },
    );
  }
}
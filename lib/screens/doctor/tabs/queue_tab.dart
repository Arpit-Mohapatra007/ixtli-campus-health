import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:campus_health/providers/doctor_provider.dart'; 
import '../../../providers/auth_provider.dart' show authServiceProvider;
import '../../../providers/chat_provider.dart' show chatServiceProvider;

class LiveQueueTab extends ConsumerWidget {
  const LiveQueueTab({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final queueAsync = ref.watch(approvedQueueProvider);

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
                const Text("Queue is empty. Good job!", style: TextStyle(color: Colors.grey)),
              ],
            ),
          );
        }

        return ListView.builder(
          padding: const EdgeInsets.all(12),
          itemCount: snapshot.docs.length,
          itemBuilder: (ctx, i) {
            final doc = snapshot.docs[i];
            final data = doc.data() as Map<String, dynamic>;
            
            final token = data['token_number'] ?? '?';
            final name = data['studentName'] ?? 'Unknown';
            
            final isFirst = i == 0; 

            return Card(
              elevation: isFirst ? 4 : 1,
              color: isFirst ? Colors.teal[50] : Colors.white,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
                side: isFirst ? const BorderSide(color: Colors.teal, width: 2) : BorderSide.none,
              ),
              margin: const EdgeInsets.symmetric(vertical: 6),
              child: ListTile(
                contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                leading: CircleAvatar(
                  radius: 25,
                  backgroundColor: isFirst ? Colors.teal : Colors.blueGrey[100],
                  child: Text(
                    "#$token", 
                    style: TextStyle(
                      color: isFirst ? Colors.white : Colors.black54, 
                      fontWeight: FontWeight.bold,
                      fontSize: 18
                    )
                  ),
                ),
                title: Text(name, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16, color: Colors.black87)),
                subtitle: Text(
                  isFirst ? "Now Serving..." : "Waiting in line", 
                  style: TextStyle(color: isFirst ? Colors.teal[700] : Colors.grey)
                ),
                trailing: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    IconButton(
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
                    
                    const SizedBox(width: 8),

                   ElevatedButton.icon(
                      onPressed: () async {
                        await ref.read(doctorServiceProvider).callPatient(doc.id);
                        
                        if (context.mounted) {
                          context.push(
                            '/doctor/consultation', 
                            extra: {
                              'appointmentId': doc.id,
                              'appointmentData': data,
                            },
                          );
                          
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(content: Text("Opening Consultation..."), duration: Duration(milliseconds: 500))
                          );
                        }
                      },
                      icon: const Icon(Icons.notifications_active, size: 18),
                      label: const Text("Call In"),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: isFirst ? Colors.teal : Colors.grey,
                        foregroundColor: Colors.white,
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
                      ),
                    ),
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
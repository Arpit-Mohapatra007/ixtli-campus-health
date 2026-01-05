import 'package:campus_health/utils/app_constants.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import '../../providers/doctor_provider.dart' show allDoctorsProvider;
import '../../services/chat_service.dart';
import '../../providers/user_provider.dart';

class AllDoctorsScreen extends ConsumerWidget {
  const AllDoctorsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final doctorsAsync = ref.watch(allDoctorsProvider);
    final currentUser = ref.watch(currentUserProfileProvider).value;

    Future<void> startChat(String doctorId, String doctorName) async {
      if (currentUser == null) return;
      
      try {
        final chatId = await ChatService().getChatRoomId(
          studentId: currentUser.uid,
          studentName: currentUser.name,
          doctorId: doctorId,
          doctorName: doctorName,
        );
        
        if (context.mounted) {
          context.push('/student/chat', extra: {
            'chatId': chatId,
            'otherUserName': doctorName,
          });
        }
      } catch (e) {
        if (context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text("Error: $e")));
        }
      }
    }

    return Scaffold(
      appBar: AppBar(
        title: const Text("Find a Doctor"),
        backgroundColor: Colors.teal,
        foregroundColor: Colors.white,
      ),
      body: doctorsAsync.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, _) => Center(child: Text("Error: $e")),
        data: (doctors) {
          if (doctors.isEmpty) {
            return const Center(child: Text("No doctors registered yet."));
          }

          final Map<String, List<Map<String, dynamic>>> groupedDoctors = {};
          for (var doc in doctors) {
            final spec = doc['specialization'] ?? AppConstants.generalPhysician;
            if (!groupedDoctors.containsKey(spec)) {
              groupedDoctors[spec] = [];
            }
            groupedDoctors[spec]!.add(doc);
          }

          return ListView.builder(
            padding: const EdgeInsets.all(16),
            itemCount: groupedDoctors.length,
            itemBuilder: (ctx, i) {
              final spec = groupedDoctors.keys.elementAt(i);
              final specialists = groupedDoctors[spec]!;

              return Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Padding(
                    padding: const EdgeInsets.symmetric(vertical: 8.0),
                    child: Text(
                      spec.toUpperCase(),
                      style: TextStyle(
                        color: Colors.teal[800],
                        fontWeight: FontWeight.bold,
                        letterSpacing: 1.2,
                      ),
                    ),
                  ),
                  ...specialists.map((doctor) => Card(
                    elevation: 2,
                    margin: const EdgeInsets.only(bottom: 8),
                    child: ListTile(
                      leading: CircleAvatar(
                        backgroundColor: Colors.teal[100],
                        child: Text(doctor['name'][0], style: const TextStyle(color: Colors.teal)),
                      ),
                      title: Text("${doctor['name']}", style: const TextStyle(fontWeight: FontWeight.bold)),
                      subtitle: Text(doctor['email'] ?? ''),
                      trailing: IconButton(
                        icon: const Icon(Icons.chat_bubble, color: Colors.blue),
                        onPressed: () => startChat(doctor['id'], "${doctor['name']}"),
                      ),
                    ),
                  )),
                  const SizedBox(height: 10),
                ],
              );
            },
          );
        },
      ),
    );
  }
}
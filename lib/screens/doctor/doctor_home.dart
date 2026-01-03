import 'package:flutter/material.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import '../../providers/auth_provider.dart';
import '../../providers/doctor_provider.dart';

class DoctorHome extends ConsumerWidget {
  const DoctorHome({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return DefaultTabController(
      length: 2,
      child: Scaffold(
        appBar: AppBar(
          title: const Text('Doctor Dashboard'),
          bottom: const TabBar(
            tabs: [
              Tab(text: "Pending Requests"), 
              Tab(text: "Live Queue"),       
            ],
          ),
          actions: [
            IconButton(
              icon: const Icon(Icons.logout),
              onPressed: () => ref.read(authServiceProvider).signOut(),
            ),
          ],
        ),
        body: const TabBarView(
          children: [
            PendingRequestsList(),
            LiveQueueList(),
          ],
        ),
      ),
    );
  }
}

class PendingRequestsList extends ConsumerWidget {
  const PendingRequestsList({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final pendingAsync = ref.watch(pendingAppointmentsProvider);
    
    return pendingAsync.when(
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (e, _) => Center(child: Text("Error: $e")),
      data: (snapshot) {
        if (snapshot.docs.isEmpty) return const Center(child: Text("No new requests."));
        
        return ListView.builder(
          itemCount: snapshot.docs.length,
          itemBuilder: (ctx, i) {
            final doc = snapshot.docs[i];
            final data = doc.data() as Map<String, dynamic>;
            
            return Card(
              child: ListTile(
                title: Text("${data['studentName']} (${data['hostel'] ?? '?'})"),
                subtitle: Text(data['reason'] ?? ''),
                trailing: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                     IconButton(
                      icon: const Icon(Icons.close, color: Colors.red),
                      onPressed: () => ref.read(doctorServiceProvider).rejectStudent(doc.id),
                    ),
                    IconButton(
                      icon: const Icon(Icons.check, color: Colors.green),
                      onPressed: () => ref.read(doctorServiceProvider).admitStudent(doc.id), 
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

class LiveQueueList extends ConsumerWidget {
  const LiveQueueList({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final queueAsync = ref.watch(approvedQueueProvider);

    return queueAsync.when(
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (e, _) => Center(child: Text("Error: $e")),
      data: (snapshot) {
        if (snapshot.docs.isEmpty) return const Center(child: Text("Queue is empty."));

        return ListView.builder(
          itemCount: snapshot.docs.length,
          itemBuilder: (ctx, i) {
            final doc = snapshot.docs[i];
            final data = doc.data() as Map<String, dynamic>;
            final token = data['token_number'];

            return Card(
              color: i == 0 ? const Color.fromARGB(255, 249, 30, 1) : null, 
              child: ListTile(
                leading: CircleAvatar(
                  backgroundColor: Colors.blue,
                  child: Text("#$token", style: const TextStyle(color: Colors.white)),
                ),
                title: Text(data['studentName'] ?? 'Unknown'),
                subtitle: Text("Waiting..."),
                trailing: ElevatedButton(
                  onPressed: () {
                    ref.read(doctorServiceProvider).callPatient(doc.id);
                    ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("Calling Patient...")));
                  },
                  child: const Text("Call In"),
                ),
              ),
            );
          },
        );
      },
    );
  }
}
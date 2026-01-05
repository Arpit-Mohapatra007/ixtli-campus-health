import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../providers/appointment_provider.dart' show currentServingProvider, myActiveAppointmentProvider;

class LiveQueueCard extends ConsumerWidget {
  const LiveQueueCard({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final currentServingAsync = ref.watch(currentServingProvider);
    final myAppointmentAsync = ref.watch(myActiveAppointmentProvider);

    return Card(
      color: Colors.blueGrey.shade900,
      margin: const EdgeInsets.all(16),
      elevation: 4,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(20.0),
        child: Column(
          children: [
            const Text("Clinic Live Status", 
              style: TextStyle(color: Colors.white70, fontSize: 14, letterSpacing: 1.2)),
            const Divider(color: Colors.white24),
            const SizedBox(height: 10),
            
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: [
                Column(
                  children: [
                    const Text("NOW SERVING", style: TextStyle(color: Colors.tealAccent, fontSize: 12)),
                    const SizedBox(height: 5),
                    currentServingAsync.when(
                      data: (token) => Text("#$token", 
                        style: const TextStyle(fontSize: 32, fontWeight: FontWeight.bold, color: Colors.white)),
                      loading: () => const SizedBox(
                        height: 20, width: 20, 
                        child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white54)
                      ),
                      error: (err, stack) => const Text("!", style: TextStyle(color: Colors.red)),
                    ),
                  ],
                ),

                myAppointmentAsync.when(
                  data: (doc) {
                    if (doc == null) {
                      return const Text("--", style: TextStyle(color: Colors.white38)); 
                    }
                    
                    final data = doc.data() as Map<String, dynamic>;
                    final status = data['status'];
                    final token = data['token_number'] ?? -1;

                    if (status == 'pending') {
                       return const Column(
                        children: [
                          Text("YOUR STATUS", style: TextStyle(color: Colors.orangeAccent, fontSize: 12)),
                          SizedBox(height: 5),
                          Text("Pending", style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.orange)),
                        ],
                      );
                    }

                    return Column(
                      children: [
                        const Text("YOUR TOKEN", style: TextStyle(color: Colors.blueAccent, fontSize: 12)),
                        const SizedBox(height: 5),
                        Text("#$token", 
                          style: const TextStyle(fontSize: 32, fontWeight: FontWeight.bold, color: Colors.blue)),
                      ],
                    );
                  },
                  loading: () => const SizedBox(
                        height: 20, width: 20, 
                        child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white54)
                  ),
                  error: (err, stack) => const Icon(Icons.error_outline, color: Colors.red),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
import 'package:flutter/material.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:intl/intl.dart';
import '../../providers/auth_provider.dart';

final medicalHistoryProvider = StreamProvider.autoDispose<List<Map<String, dynamic>>>((ref) {
  final user = ref.watch(authServiceProvider).currentUser;
  if (user == null) return const Stream.empty();

  return FirebaseFirestore.instance
      .collection('prescriptions')
      .where('studentId', isEqualTo: user.uid)
      .orderBy('timestamp', descending: true)
      .snapshots()
      .map((snapshot) => snapshot.docs.map((doc) => doc.data()).toList());
});

class MedicalHistoryScreen extends ConsumerWidget {
  const MedicalHistoryScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final historyAsync = ref.watch(medicalHistoryProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text("Medical History"),
        backgroundColor: Colors.teal,
        foregroundColor: Colors.white,
      ),
      backgroundColor: Colors.grey[100],
      body: historyAsync.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, _) => Center(child: Text("Error: $e")),
        data: (records) {
          if (records.isEmpty) {
            return const Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.history_edu, size: 60, color: Colors.grey),
                  SizedBox(height: 10),
                  Text("No medical records found.", style: TextStyle(color: Colors.grey)),
                ],
              ),
            );
          }

          return ListView.builder(
            padding: const EdgeInsets.all(16),
            itemCount: records.length,
            itemBuilder: (context, index) {
              final record = records[index];
              final Timestamp? ts = record['timestamp'];
              final dateStr = ts != null 
                  ? DateFormat('MMM d, yyyy • h:mm a').format(ts.toDate()) 
                  : 'Unknown Date';
              
              final meds = (record['medicines'] as List<dynamic>? ?? []);

              return Card(
                elevation: 3,
                margin: const EdgeInsets.only(bottom: 16),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                child: Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Expanded(
                            child: Text(
                              record['diagnosis'] ?? 'Unknown Diagnosis',
                              style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.teal),
                            ),
                          ),
                          Text(dateStr, style: const TextStyle(fontSize: 12, color: Colors.grey)),
                        ],
                      ),
                      const SizedBox(height: 5),
                      Text("${record['doctorName'] ?? 'Unknown'}", style: const TextStyle(fontWeight: FontWeight.w500)),
                      const Divider(height: 20),

                      const Text("Prescribed Medicines:", style: TextStyle(fontSize: 12, color: Colors.grey, fontWeight: FontWeight.bold)),
                      const SizedBox(height: 5),
                      ...meds.map((m) => Padding(
                        padding: const EdgeInsets.symmetric(vertical: 2),
                        child: Row(
                          children: [
                            const Icon(Icons.medication, size: 16, color: Colors.teal),
                            const SizedBox(width: 8),
                            Text("${m['name']} (${m['type']})"),
                            const Spacer(),
                            Text("x${m['qty']}", style: const TextStyle(fontWeight: FontWeight.bold)),
                          ],
                        ),
                      )),
                    ],
                  ),
                ),
              );
            },
          );
        },
      ),
    );
  }
}
import 'package:flutter/material.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import '../../../providers/sentinel_provider.dart';

class SentinelTab extends ConsumerWidget {
  const SentinelTab({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final sentinelService = ref.watch(sentinelServiceProvider);
    
    final messagesAsync = ref.watch(outbreakMessagesProvider);

    void showBroadcastDialog() {
      final msgCtrl = TextEditingController();
      final hostelCtrl = TextEditingController(text: "Boys Hostel A");
      final wingCtrl = TextEditingController(); 
      final floorCtrl = TextEditingController(); 
      
      showDialog(
        context: context, 
        builder: (ctx) => AlertDialog(
          title: const Text("Broadcast Alert"),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextField(controller: hostelCtrl, decoration: const InputDecoration(labelText: "Hostel Name (Required)")),
                const SizedBox(height: 10),
                Row(children: [
                    Expanded(child: TextField(controller: wingCtrl, decoration: const InputDecoration(labelText: "Wing (Opt)"))),
                    const SizedBox(width: 10),
                    Expanded(child: TextField(controller: floorCtrl, decoration: const InputDecoration(labelText: "Floor (Opt)"))),
                ]),
                const SizedBox(height: 10),
                TextField(
                  controller: msgCtrl, 
                  maxLines: 3,
                  decoration: const InputDecoration(
                    labelText: "Message", 
                    hintText: "e.g., Use Mosquito Nets! Fumigation today.",
                    border: OutlineInputBorder()
                  )
                ),
              ],
            ),
          ),
          actions: [
            TextButton(onPressed: () => Navigator.pop(ctx), child: const Text("Cancel")),
            ElevatedButton.icon(
              icon: const Icon(Icons.send),
              label: const Text("SEND"),
              style: ElevatedButton.styleFrom(backgroundColor: Colors.red, foregroundColor: Colors.white),
              onPressed: () async {
                if (msgCtrl.text.isNotEmpty && hostelCtrl.text.isNotEmpty) {
                  await sentinelService.sendBroadcast(
                    hostel: hostelCtrl.text,
                    floor: floorCtrl.text.isEmpty ? "All" : floorCtrl.text,
                    wing: wingCtrl.text.isEmpty ? "All" : wingCtrl.text,
                    message: msgCtrl.text
                  );
                  if (ctx.mounted) {
                    Navigator.pop(ctx);
                    ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("Alert Broadcasted!")));
                  }
                }
              },
            )
          ],
        )
      );
    }

    return Scaffold(
      floatingActionButton: FloatingActionButton.extended(
        onPressed: showBroadcastDialog,
        backgroundColor: Colors.red,
        icon: const Icon(Icons.campaign),
        label: const Text("Broadcast"),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text("Real-Time Outbreak Analysis", style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
            const Text("Based on prescriptions from the last 48 hours", style: TextStyle(color: Colors.grey)),
            const SizedBox(height: 15),
            
            Expanded(
              child: Card(
                elevation: 4,
                color: Colors.red[50],
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                child: messagesAsync.when(
                  loading: () => const Center(child: CircularProgressIndicator()),
                  error: (err, stack) => Center(child: Text("Error: $err")),
                  data: (messages) {
                    if (messages.isEmpty || (messages.length == 1 && messages.first.contains("No active"))) {
                       return const Center(
                         child: Text("No Active Outbreaks", style: TextStyle(color: Colors.green, fontSize: 16, fontWeight: FontWeight.bold))
                       );
                    }
                    return ListView(
                      padding: const EdgeInsets.all(16),
                      children: messages.map((msg) => ListTile(
                        leading: const Icon(Icons.warning_amber_rounded, color: Colors.red, size: 30),
                        title: Text(msg, style: const TextStyle(fontWeight: FontWeight.bold, color: Colors.redAccent)),
                      )).toList(),
                    );
                  },
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
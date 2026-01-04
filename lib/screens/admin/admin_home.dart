import 'package:flutter/material.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import '../../providers/sentinel_provider.dart';
import '../../providers/auth_provider.dart';

class AdminHome extends ConsumerWidget {
  const AdminHome({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final alertsAsync = ref.watch(outbreakAlertsProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text("CAMPUS SENTINEL", style: TextStyle(fontWeight: FontWeight.bold, letterSpacing: 1.5)),
        backgroundColor: Colors.red[900], 
        foregroundColor: Colors.white,
        centerTitle: true,
        actions: [
          IconButton(
            icon: const Icon(Icons.logout),
            onPressed: () => ref.read(authServiceProvider).signOut(),
          ),
        ],
      ),
      backgroundColor: Colors.grey[100],
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              "Epidemic Monitor (Last 24h)", 
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.grey)
            ),
            const SizedBox(height: 15),
            
            Expanded(
              child: alertsAsync.when(
                loading: () => const Center(child: CircularProgressIndicator()),
                error: (e, _) => Center(child: Text("Error: $e")),
                data: (alerts) {
                  if (alerts.isEmpty) {
                    return Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(Icons.shield_outlined, size: 100, color: Colors.green[300]),
                          const SizedBox(height: 20),
                          const Text("Campus Status: SAFE", style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold, color: Colors.green)),
                          const Text("No outbreaks detected.", style: TextStyle(fontSize: 16, color: Colors.grey)),
                        ],
                      ),
                    );
                  }

                  return ListView.builder(
                    itemCount: alerts.length,
                    itemBuilder: (ctx, i) {
                      final alert = alerts[i];
                      final isCritical = alert['severity'] == 'CRITICAL';
                      
                      return Card(
                        elevation: 4,
                        color: isCritical ? Colors.red[50] : Colors.orange[50],
                        shape: RoundedRectangleBorder(
                          side: BorderSide(color: isCritical ? Colors.red : Colors.orange, width: 2),
                          borderRadius: BorderRadius.circular(15),
                        ),
                        margin: const EdgeInsets.only(bottom: 16),
                        child: Padding(
                          padding: const EdgeInsets.all(20.0),
                          child: Row(
                            children: [
                              Container(
                                padding: const EdgeInsets.all(12),
                                decoration: BoxDecoration(
                                  color: Colors.white,
                                  shape: BoxShape.circle,
                                  border: Border.all(color: isCritical ? Colors.red : Colors.orange),
                                ),
                                child: Icon(
                                  Icons.warning_amber_rounded, 
                                  size: 30, 
                                  color: isCritical ? Colors.red : Colors.orange
                                ),
                              ),
                              const SizedBox(width: 20),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      "${alert['severity']} ALERT",
                                      style: TextStyle(
                                        color: isCritical ? Colors.red[900] : Colors.orange[900],
                                        fontWeight: FontWeight.bold,
                                        letterSpacing: 1.2,
                                        fontSize: 12,
                                      ),
                                    ),
                                    const SizedBox(height: 6),
                                    Text(
                                      "${alert['diagnosis']}",
                                      style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: Colors.black87),
                                    ),
                                    const SizedBox(height: 4),
                                    Text("${alert['count']} cases in ${alert['hostel']}", style: const TextStyle(fontSize: 16)),
                                  ],
                                ),
                              ),
                            ],
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
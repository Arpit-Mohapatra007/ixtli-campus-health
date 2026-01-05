import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_hooks/flutter_hooks.dart'; 
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:url_launcher/url_launcher.dart'; 
import '../../providers/auth_provider.dart';
import '../../providers/sos_provider.dart';
import '../../providers/user_provider.dart'; 
import '../../services/notification_service.dart'; 

class DriverHome extends HookConsumerWidget {
  const DriverHome({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final userAsync = ref.watch(currentUserProfileProvider);
    final sosAsync = ref.watch(activeEmergenciesProvider);

    return userAsync.when(
      loading: () => const Scaffold(body: Center(child: CircularProgressIndicator())),
      error: (e, _) => Scaffold(body: Center(child: Text("Error: $e"))),
      data: (user) {
        useEffect(() {
          List<StreamSubscription> subs = [];
          if (user != null) {
            subs = NotificationService().listenForLocalAlerts(user);
          }
          return () {
            for (var sub in subs) {
              sub.cancel();
            }
          };
        }, []);

        return Scaffold(
          appBar: AppBar(
            title: const Text("AMBULANCE DISPATCH"),
            backgroundColor: Colors.red[900],
            foregroundColor: Colors.white,
            actions: [
              IconButton(
                icon: const Icon(Icons.logout),
                onPressed: () => ref.read(authServiceProvider).signOut(),
              )
            ],
          ),
          backgroundColor: Colors.grey[900],
          body: sosAsync.when(
            loading: () => const Center(child: CircularProgressIndicator()),
            error: (e, _) => Center(child: Text("Error: $e", style: const TextStyle(color: Colors.white))),
            data: (snapshot) {
              if (snapshot.docs.isEmpty) {
                return Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.local_hospital, size: 100, color: Colors.grey[700]),
                      const SizedBox(height: 20),
                      const Text("No active emergencies", style: TextStyle(color: Colors.grey, fontSize: 18)),
                    ],
                  ),
                );
              }

              return ListView.builder(
                padding: const EdgeInsets.all(16),
                itemCount: snapshot.docs.length,
                itemBuilder: (ctx, i) {
                  final doc = snapshot.docs[i];
                  final data = doc.data() as Map<String, dynamic>;
                  final isPending = data['status'] == 'pending';

                  return Card(
                    color: isPending ? Colors.red[50] : Colors.yellow[50],
                    margin: const EdgeInsets.only(bottom: 16),
                    child: Padding(
                      padding: const EdgeInsets.all(16.0),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Icon(Icons.warning, color: Colors.red[900], size: 30),
                              const SizedBox(width: 10),
                              Expanded(
                                child: Text(
                                  "EMERGENCY AT ${data['hostel']}", 
                                  style: TextStyle(color: Colors.red[900], fontWeight: FontWeight.bold, fontSize: 18)
                                ),
                              ),
                            ],
                          ),
                          const Divider(),
                          Text("Student: ${data['studentName']}", style: const TextStyle(fontSize: 16)),
                          Text("Room: ${data['roomNumber']}", style: const TextStyle(fontSize: 22, fontWeight: FontWeight.bold)),
                          Text("Blood Group: ${data['bloodGroup']}  •  Age: ${data['age'] ?? 'N/A'}"),       
                          const SizedBox(height: 10),
                          
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                            children: [
                              ElevatedButton.icon(
                                onPressed: () => launchUrl(Uri.parse("tel:${data['contact']}")),
                                icon: const Icon(Icons.call),
                                label: const Text("Call"),
                                style: ElevatedButton.styleFrom(backgroundColor: Colors.green, foregroundColor: Colors.white),
                              ),
                              
                              if (isPending)
                                ElevatedButton.icon(
                                  onPressed: () {
                                    ref.read(sosServiceProvider).updateStatus(doc.id, 'on_way');
                                  },
                                  icon: const Icon(Icons.directions_car),
                                  label: const Text("Accept"),
                                  style: ElevatedButton.styleFrom(backgroundColor: Colors.blue, foregroundColor: Colors.white),
                                )
                              else
                                ElevatedButton.icon(
                                  onPressed: () => ref.read(sosServiceProvider).updateStatus(doc.id, 'resolved'),
                                  icon: const Icon(Icons.check),
                                  label: const Text("Complete"),
                                  style: ElevatedButton.styleFrom(backgroundColor: Colors.grey, foregroundColor: Colors.white),
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
          ),
        );
      },
    );
  }
}
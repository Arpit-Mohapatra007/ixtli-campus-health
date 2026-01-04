import 'package:flutter/material.dart';
import 'package:flutter_hooks/flutter_hooks.dart';
import 'package:go_router/go_router.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import '../../providers/auth_provider.dart';
import '../../providers/user_provider.dart';
import '../../providers/sos_provider.dart';
import '../../services/notification_service.dart';
import '../../widgets/live_queue_card.dart';
import 'nearby_hospitals_screen.dart';
import 'authorities_contact_screen.dart';

class StudentHome extends HookConsumerWidget {
  const StudentHome({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final userAsync = ref.watch(currentUserProfileProvider);
    final myEmergencyAsync = ref.watch(myEmergencyStatusProvider);

    return userAsync.when(
      loading: () => const Scaffold(body: Center(child: CircularProgressIndicator())),
      error: (e, _) => Scaffold(body: Center(child: Text("Error: $e"))),
      data: (user) {
        useEffect(() {
          if (user != null) {
            NotificationService().listenForLocalAlerts(user);
          }
          return null;
        }, []); 

        Future<void> triggerSOS() async {
          if (user == null) return;
          try {
            await ref.read(sosServiceProvider).sendSOS(
              studentId: user.uid,
              name: user.name,
              hostel: user.hostel,
              room: user.roomNumber,
              contact: user.emergencyContact,
              bloodGroup: user.bloodGroup,
            );
            if (context.mounted) {
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text("SOS SENT! Driver Notified."), backgroundColor: Colors.red)
              );
            }
          } catch (e) {
            if (context.mounted) {
              ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(e.toString())));
            }
          }
        }

        return Scaffold(
          backgroundColor: Colors.grey[50],
          appBar: AppBar(
            title: const Text("Student Dashboard"),
            backgroundColor: Colors.teal,
            foregroundColor: Colors.white,
          ),
          drawer: Drawer(
            child: Column(
              children: [
                UserAccountsDrawerHeader(
                  decoration: const BoxDecoration(color: Colors.teal),
                  accountName: Text(user?.name ?? "Student"),
                  accountEmail: Text(user?.email ?? ""),
                  currentAccountPicture: const CircleAvatar(backgroundColor: Colors.white, child: Icon(Icons.person, color: Colors.teal)),
                ),
                ListTile(
                  leading: const Icon(Icons.calendar_month, color: Colors.teal),
                  title: const Text("Book Appointment"),
                  onTap: () => context.push('/student/bookAppointment'),
                ),
                ListTile(
                  leading: const Icon(Icons.local_hospital, color: Colors.red),
                  title: const Text("Nearby Hospitals"),
                  onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const NearbyHospitalsScreen())),
                ),
                ListTile(
                  leading: const Icon(Icons.phone_in_talk, color: Colors.orange),
                  title: const Text("Emergency Contacts"),
                  onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const AuthoritiesContactScreen())),
                ),
                ListTile(
                  leading: const Icon(Icons.chat, color: Colors.blue),
                  title: const Text("My Chats"),
                  onTap: () => context.push('/student/chats'),
                ),
                ListTile(
                  leading: const Icon(Icons.history_edu, color: Colors.indigo),
                  title: const Text("Medical History"),
                  onTap: () => context.push('/student/history'),
                ),
                const Divider(),
                ListTile(
                  leading: const Icon(Icons.logout, color: Colors.red),
                  title: const Text("Logout"),
                  onTap: () => ref.read(authServiceProvider).signOut(),
                ),
              ],
            ),
          ),
          body: Column(
            children: [
              const LiveQueueCard(),
              Expanded(
                child: Center(
                  child: myEmergencyAsync.when(
                    loading: () => const CircularProgressIndicator(),
                    error: (e, _) => Text("Error: $e"),
                    data: (emergencyDoc) {
                      bool isActive = emergencyDoc != null;
                      String status = isActive ? (emergencyDoc['status'] ?? 'pending') : '';
                      bool isHelpComing = status == 'on_way';
                      
                      return Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          GestureDetector(
                            onLongPress: isActive ? null : triggerSOS,
                            child: Container(
                              width: 200,
                              height: 200,
                              decoration: BoxDecoration(
                                shape: BoxShape.circle,
                                color: isActive 
                                    ? (isHelpComing ? Colors.orange : Colors.grey) 
                                    : Colors.red, 
                                boxShadow: [
                                  BoxShadow(
                                    color: (isActive ? Colors.grey : Colors.red),
                                    blurRadius: 20,
                                    spreadRadius: 5,
                                  )
                                ],
                              ),
                              alignment: Alignment.center,
                              child: Column(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  Icon(
                                    isActive ? (isHelpComing ? Icons.medical_services : Icons.hourglass_bottom) : Icons.sos,
                                    size: 60, 
                                    color: Colors.white
                                  ),
                                  const SizedBox(height: 10),
                                  Text(
                                    isActive 
                                      ? (isHelpComing ? "HELP ON WAY" : "REQUESTED") 
                                      : "HOLD SOS",
                                    textAlign: TextAlign.center,
                                    style: const TextStyle(
                                      color: Colors.white, 
                                      fontSize: 22, 
                                      fontWeight: FontWeight.bold
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                          const SizedBox(height: 20),
                          Text(
                            isActive 
                              ? "Driver is notified. Please stay calm." 
                              : "Hold button for 2 seconds to call ambulance",
                            style: const TextStyle(color: Colors.grey, fontSize: 16),
                          ),
                        ],
                      );
                    },
                  ),
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}
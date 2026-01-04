import 'package:flutter/material.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import '../../providers/auth_provider.dart';
import '../../providers/user_provider.dart';
import 'tabs/pending_tab.dart';
import 'tabs/queue_tab.dart';
import 'tabs/schedule_tab.dart'; 
import '../chat/chats_tab.dart';

class DoctorHome extends ConsumerWidget {
  const DoctorHome({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final userAsync = ref.watch(currentUserProfileProvider);

    return userAsync.when(
      loading: () => const Scaffold(body: Center(child: CircularProgressIndicator())),
      error: (e, _) => Scaffold(body: Center(child: Text("Error: $e"))),
      data: (user) {
        final isSpecialist = user?.specialization != null && 
                             user!.specialization!.isNotEmpty && 
                             user.specialization != 'General Physician';

        final tabCount = isSpecialist ? 4 : 3;

        return DefaultTabController(
          length: tabCount, 
          child: Scaffold(
            appBar: AppBar(
              title: Text(
                isSpecialist ? '${user.name} (${user.specialization})' : 'Doctor Dashboard',
                style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 18)
              ),
              backgroundColor: Colors.teal,
              elevation: 0,
              bottom: TabBar(
                labelColor: Colors.white,
                unselectedLabelColor: Colors.white70,
                indicatorColor: Colors.white,
                indicatorWeight: 3,
                isScrollable: isSpecialist, 
                tabs: [
                  const Tab(icon: Icon(Icons.assignment_ind_outlined), text: "Requests"),
                  const Tab(icon: Icon(Icons.people_alt_outlined), text: "Live Queue"),
                  if (isSpecialist)
                    const Tab(icon: Icon(Icons.calendar_month_outlined), text: "My Visits"),
                  const Tab(icon: Icon(Icons.chat_bubble_outline), text: "Chats"),
                ],
              ),
              actions: [
                IconButton(
                  icon: const Icon(Icons.logout, color: Colors.white),
                  onPressed: () => ref.read(authServiceProvider).signOut(),
                ),
              ],
            ),
            backgroundColor: const Color(0xFFF5F5F5), 
            body: TabBarView(
              children: [
                const PendingRequestsTab(),
                const LiveQueueTab(),
                if (isSpecialist)
                  const ScheduleTab(), 
                const ChatsTab(),
              ],
            ),
          ),
        );
      },
    );
  }
}
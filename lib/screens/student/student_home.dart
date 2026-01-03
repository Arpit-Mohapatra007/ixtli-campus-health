import 'package:campus_health/widgets/live_queue_card.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import '../../providers/auth_provider.dart';

class StudentHome extends ConsumerWidget {
  const StudentHome({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Student Dashboard"),
        actions: [
          IconButton(
            icon: const Icon(Icons.logout),
            onPressed: () => ref.read(authServiceProvider).signOut(),
          )
        ],
      ),
      body: Column(
        children: [
          const LiveQueueCard(),
          const SizedBox(height: 20),
          Center(
            child: ElevatedButton(
                onPressed: () => context.push('/student/book'), 
                child: const Text("Book Appointment"),
              ),
            ),
        ],
      ),
    );
  }
}
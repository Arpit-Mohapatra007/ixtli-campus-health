import 'package:flutter/material.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import '../../providers/auth_provider.dart';

class DoctorHome extends ConsumerWidget {
  const DoctorHome({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Scaffold(
      backgroundColor: Colors.teal[50], 
      appBar: AppBar(title: const Text("Doctor Portal"), backgroundColor: Colors.teal),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Text("No Appointments Yet"),
            const SizedBox(height: 20),
            ElevatedButton(
              onPressed: () => ref.read(authServiceProvider).signOut(),
              child: const Text("Logout"),
            )
          ],
        ),
      ),
    );
  }
}
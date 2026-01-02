import 'package:flutter/material.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import '../../providers/auth_provider.dart';

class DriverHome extends ConsumerWidget {
  const DriverHome({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Scaffold(
      backgroundColor: Colors.blueGrey[900],
      appBar: AppBar(title: const Text("Ambulance Dispatch"), backgroundColor: Colors.redAccent),
      body: Center(
        child: ElevatedButton(
          onPressed: () => ref.read(authServiceProvider).signOut(),
          child: const Text("Logout"),
        ),
      ),
    );
  }
}
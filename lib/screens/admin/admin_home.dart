import 'package:flutter/material.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:flutter_hooks/flutter_hooks.dart';
import '../../providers/auth_provider.dart';
import 'tabs/sentinel_tab.dart';
import 'tabs/inventory_tab.dart';
import 'tabs/manage_content_tab.dart';

class AdminHome extends HookConsumerWidget {
  const AdminHome({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final selectedIndex = useState(0);

    final tabs = [
      const SentinelTab(),
      const InventoryTab(),
      const ManageContentTab(),
    ];

    return Scaffold(
      appBar: AppBar(
        title: const Text("Admin Dashboard"),
        backgroundColor: Colors.blueGrey,
        foregroundColor: Colors.white,
        actions: [
          IconButton(
            icon: const Icon(Icons.logout),
            onPressed: () => ref.read(authServiceProvider).signOut(),
          )
        ],
      ),
      body: tabs[selectedIndex.value],
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: selectedIndex.value,
        onTap: (val) => selectedIndex.value = val,
        items: const [
          BottomNavigationBarItem(
            icon: Icon(Icons.shield),
            label: "Sentinel",
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.inventory),
            label: "Inventory",
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.edit_document),
            label: "Manage Content",
          ),
        ],
      ),
    );
  }
}
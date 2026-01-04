import 'package:flutter/material.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:intl/intl.dart';
import '../../../services/content_service.dart';

class ManageContentTab extends StatelessWidget {
  const ManageContentTab({super.key});

  @override
  Widget build(BuildContext context) {
    return DefaultTabController(
      length: 3,
      child: Scaffold(
        appBar: const TabBar(
          labelColor: Colors.blue,
          unselectedLabelColor: Colors.grey,
          indicatorColor: Colors.blue,
          tabs: [
            Tab(icon: Icon(Icons.local_hospital), text: "Hospitals"),
            Tab(icon: Icon(Icons.contact_phone), text: "Contacts"),
            Tab(icon: Icon(Icons.calendar_month), text: "Schedule"),
          ],
        ),
        body: const TabBarView(
          children: [
            _ManageHospitals(),
            _ManageContacts(),
            _ManageSchedule(),
          ],
        ),
      ),
    );
  }
}

class _ManageHospitals extends ConsumerWidget {
  const _ManageHospitals();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final hospitalsAsync = ref.watch(hospitalsProvider);

    void showAddDialog() {
      final nameCtrl = TextEditingController();
      final docCtrl = TextEditingController();
      final phoneCtrl = TextEditingController();
      final distCtrl = TextEditingController();
      final linkCtrl = TextEditingController(); 

      showDialog(
        context: context,
        builder: (ctx) => AlertDialog(
          title: const Text("Add Hospital"),
          content: SingleChildScrollView(
            child: Column(
              children: [
                TextField(controller: nameCtrl, decoration: const InputDecoration(labelText: "Hospital Name")),
                TextField(controller: docCtrl, decoration: const InputDecoration(labelText: "Doctor Name")),
                TextField(controller: phoneCtrl, decoration: const InputDecoration(labelText: "Phone Number")),
                TextField(controller: distCtrl, decoration: const InputDecoration(labelText: "Distance (e.g. 2.5 km)")),
                TextField(
                  controller: linkCtrl, 
                  decoration: const InputDecoration(
                    labelText: "Google Maps Link", 
                    hintText: "Paste full link here (https://maps...)",
                    helperText: "Go to Google Maps > Share > Copy Link"
                  )
                ),
              ],
            ),
          ),
          actions: [
            TextButton(onPressed: () => Navigator.pop(ctx), child: const Text("Cancel")),
            ElevatedButton(
              onPressed: () {
                if (nameCtrl.text.isNotEmpty) {
                  ref.read(contentServiceProvider).addHospital({
                    'name': nameCtrl.text,
                    'doctor': docCtrl.text,
                    'phone': phoneCtrl.text,
                    'distance': distCtrl.text,
                    'mapLink': linkCtrl.text,
                  });
                  Navigator.pop(ctx);
                }
              },
              child: const Text("Add"),
            )
          ],
        ),
      );
    }

    return Scaffold(
      floatingActionButton: FloatingActionButton(
        onPressed: showAddDialog,
        child: const Icon(Icons.add),
      ),
      body: hospitalsAsync.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, _) => Center(child: Text("Error: $e")),
        data: (list) {
          if (list.isEmpty) return const Center(child: Text("No hospitals added."));
          return ListView.builder(
            itemCount: list.length,
            itemBuilder: (ctx, i) {
              final item = list[i];
              return ListTile(
                title: Text(item['name']),
                subtitle: Text("${item['distance']} • ${item['mapLink'] != null ? 'Has Map Link' : 'No Link'}"),
                trailing: IconButton(
                  icon: const Icon(Icons.delete, color: Colors.red),
                  onPressed: () => ref.read(contentServiceProvider).deleteHospital(item['id']),
                ),
              );
            },
          );
        },
      ),
    );
  }
}

class _ManageContacts extends ConsumerWidget {
  const _ManageContacts();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final contactsAsync = ref.watch(contactsProvider);

    void showAddDialog() {
      final roleCtrl = TextEditingController();
      final nameCtrl = TextEditingController();
      final phoneCtrl = TextEditingController();
      String selectedIcon = 'person';

      showDialog(
        context: context,
        builder: (ctx) => StatefulBuilder(
          builder: (context, setState) => AlertDialog(
            title: const Text("Add Contact"),
            content: SingleChildScrollView(
              child: Column(
                children: [
                  TextField(controller: roleCtrl, decoration: const InputDecoration(labelText: "Role (e.g. Dean)")),
                  TextField(controller: nameCtrl, decoration: const InputDecoration(labelText: "Name")),
                  TextField(controller: phoneCtrl, decoration: const InputDecoration(labelText: "Phone")),
                  const SizedBox(height: 10),
                  DropdownButton<String>(
                    value: selectedIcon,
                    isExpanded: true,
                    items: const [
                      DropdownMenuItem(value: 'person', child: Text("Person/General")),
                      DropdownMenuItem(value: 'ambulance', child: Text("Ambulance")),
                      DropdownMenuItem(value: 'security', child: Text("Security")),
                      DropdownMenuItem(value: 'admin', child: Text("Warden/Admin")),
                    ],
                    onChanged: (val) => setState(() => selectedIcon = val!),
                  )
                ],
              ),
            ),
            actions: [
              TextButton(onPressed: () => Navigator.pop(ctx), child: const Text("Cancel")),
              ElevatedButton(
                onPressed: () {
                  if (roleCtrl.text.isNotEmpty) {
                    ref.read(contentServiceProvider).addContact({
                      'role': roleCtrl.text,
                      'name': nameCtrl.text,
                      'phone': phoneCtrl.text,
                      'icon': selectedIcon,
                      'priority': 1,
                    });
                    Navigator.pop(ctx);
                  }
                },
                child: const Text("Add"),
              )
            ],
          ),
        ),
      );
    }

    return Scaffold(
      floatingActionButton: FloatingActionButton(
        onPressed: showAddDialog,
        child: const Icon(Icons.add),
      ),
      body: contactsAsync.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, _) => Center(child: Text("Error: $e")),
        data: (list) {
          if (list.isEmpty) return const Center(child: Text("No contacts added."));
          return ListView.builder(
            itemCount: list.length,
            itemBuilder: (ctx, i) {
              final item = list[i];
              IconData iconData;
              switch (item['icon']) {
                case 'ambulance': iconData = Icons.medical_services; break;
                case 'security': iconData = Icons.security; break;
                case 'admin': iconData = Icons.admin_panel_settings; break;
                default: iconData = Icons.person;
              }

              return ListTile(
                leading: CircleAvatar(child: Icon(iconData, size: 20)),
                title: Text(item['role']),
                subtitle: Text("${item['name']} • ${item['phone']}"),
                trailing: IconButton(
                  icon: const Icon(Icons.delete, color: Colors.red),
                  onPressed: () => ref.read(contentServiceProvider).deleteContact(item['id']),
                ),
              );
            },
          );
        },
      ),
    );
  }
}

class _ManageSchedule extends ConsumerWidget {
  const _ManageSchedule();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final scheduleAsync = ref.watch(specialistScheduleProvider);

    void showAddDialog() async {
      final date = await showDatePicker(
        context: context, 
        firstDate: DateTime.now(), 
        lastDate: DateTime.now().add(const Duration(days: 365)),
        initialDate: DateTime.now(),
      );
      if (date == null) return;
      if (!context.mounted) return;

      final specCtrl = TextEditingController();
      showDialog(
        context: context,
        builder: (ctx) => AlertDialog(
          title: Text("Visit on ${DateFormat('MMM d').format(date)}"),
          content: TextField(controller: specCtrl, decoration: const InputDecoration(labelText: "Specialist (e.g. Cardiologist)")),
          actions: [
            TextButton(onPressed: () => Navigator.pop(ctx), child: const Text("Cancel")),
            ElevatedButton(
              onPressed: () {
                if (specCtrl.text.isNotEmpty) {
                  ref.read(contentServiceProvider).addSpecialistVisit(date, specCtrl.text);
                  Navigator.pop(ctx);
                }
              },
              child: const Text("Schedule"),
            )
          ],
        ),
      );
    }

    return Scaffold(
      floatingActionButton: FloatingActionButton(
        onPressed: showAddDialog,
        child: const Icon(Icons.add),
      ),
      body: scheduleAsync.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, _) => Center(child: Text("Error: $e")),
        data: (list) {
          if (list.isEmpty) return const Center(child: Text("No upcoming visits."));
          return ListView.builder(
            itemCount: list.length,
            itemBuilder: (ctx, i) {
              final item = list[i];
              final date = item['date'] as DateTime;
              return ListTile(
                leading: Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(color: Colors.pink[50], borderRadius: BorderRadius.circular(8)),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(DateFormat('MMM').format(date), style: const TextStyle(fontSize: 10, fontWeight: FontWeight.bold)),
                      Text(DateFormat('d').format(date), style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.pink)),
                    ],
                  ),
                ),
                title: Text(item['specialist']),
                subtitle: Text(DateFormat('EEEE').format(date)),
                trailing: IconButton(
                  icon: const Icon(Icons.delete, color: Colors.red),
                  onPressed: () => ref.read(contentServiceProvider).deleteSpecialistVisit(item['id']),
                ),
              );
            },
          );
        },
      ),
    );
  }
}
import 'package:flutter/material.dart';
import 'package:flutter_hooks/flutter_hooks.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import '../../providers/pharmacy_provider.dart';
import '../../providers/auth_provider.dart';
import 'package:go_router/go_router.dart';

class ConsultationScreen extends HookConsumerWidget {
  final Map<String, dynamic> appointmentData;
  final String appointmentId;

  const ConsultationScreen({
    super.key,
    required this.appointmentData,
    required this.appointmentId,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final diagnosisController = useTextEditingController();
    final menuController = useTextEditingController(); 
    
    final selectedMeds = useState<List<Map<String, dynamic>>>([]);
    final selectedMedId = useState<String?>(null);
    
    final inventoryAsync = ref.watch(inventoryProvider);
    final currentUser = ref.watch(authServiceProvider).currentUser;

    void addMedicine(List<Map<String, dynamic>> inventory) {
      if (selectedMedId.value == null) return;
      
      final med = inventory.firstWhere((m) => m['id'] == selectedMedId.value);
      
      final exists = selectedMeds.value.any((m) => m['id'] == med['id']);
      if (exists) {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("Medicine already added!")));
        return;
      }

      selectedMeds.value = [...selectedMeds.value, {
        'id': med['id'],
        'name': med['name'],
        'qty': 1,
        'type': med['type']
      }];

      selectedMedId.value = null; 
      menuController.clear();     
    }

    Future<void> finishConsultation() async {
      if (diagnosisController.text.isEmpty) {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("Please enter a diagnosis")));
        return;
      }

      try {
        await ref.read(pharmacyServiceProvider).submitPrescription(
          appointmentId: appointmentId,
          studentId: appointmentData['studentId'],
          studentName: appointmentData['studentName'],
          doctorId: currentUser!.uid,
          diagnosis: diagnosisController.text,
          medicines: selectedMeds.value,
          hostel: appointmentData['hostel'] ?? 'Unknown',
          roomNumber: appointmentData['roomNumber'] ?? 'Unknown',
        );
        
        if (context.mounted) {
          context.pop(); 
          ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("Prescription Sent! Appointment Completed.")));
        }
      } catch (e) {
        if (context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text("Error: $e")));
        }
      }
    }

    return Scaffold(
      appBar: AppBar(
        title: const Text("Consultation", style: TextStyle(color: Colors.white)), 
        backgroundColor: Colors.teal,
        iconTheme: const IconThemeData(color: Colors.white),
      ),
      backgroundColor: const Color(0xFFF5F5F5),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Card(
              elevation: 2,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              color: Colors.white,
              child: ListTile(
                leading: CircleAvatar(
                  backgroundColor: Colors.teal[50],
                  child: const Icon(Icons.person, color: Colors.teal),
                ),
                title: Text(appointmentData['studentName'], style: const TextStyle(fontWeight: FontWeight.bold)),
                subtitle: Text("Hostel: ${appointmentData['hostel'] ?? 'N/A'} • Token: #${appointmentData['token_number']}"),
              ),
            ),
            const SizedBox(height: 20),

            const Text("Diagnosis", style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
            const SizedBox(height: 8),
            TextField(
              controller: diagnosisController,
              decoration: InputDecoration(
                hintText: "e.g. Viral Fever, Migraine...",
                filled: true,
                fillColor: Colors.white,
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
              ),
              maxLines: 2,
            ),
            const SizedBox(height: 20),

            const Text("Prescribe Medicine", style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
            const SizedBox(height: 8),
            inventoryAsync.when(
              loading: () => const LinearProgressIndicator(),
              error: (e, _) => Text("Error loading inventory: $e"),
              data: (inventory) {
                return Row(
                  crossAxisAlignment: CrossAxisAlignment.start, 
                  children: [
                    Expanded(
                      child: LayoutBuilder(
                        builder: (context, constraints) {
                          return DropdownMenu<String>(
                            width: constraints.maxWidth,
                            controller: menuController,
                            enableFilter: true, 
                            requestFocusOnTap: true, 
                            hintText: "Select Medicine",
                            
                            filterCallback: (entries, filter) {
                              final query = filter.toLowerCase();
                              if (query.isEmpty) return entries;
                              return entries.where((entry) {
                                return entry.label.toLowerCase().startsWith(query);
                              }).toList();
                            },

                            dropdownMenuEntries: inventory.map<DropdownMenuEntry<String>>((med) {
                              return DropdownMenuEntry<String>(
                                value: med['id'] as String,
                                label: "${med['name']} (${med['stock']} left)",
                              );
                            }).toList(),

                            onSelected: (String? id) {
                              selectedMedId.value = id;
                            },

                            inputDecorationTheme: InputDecorationTheme(
                              filled: true,
                              fillColor: Colors.white,
                              contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 14),
                              border: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(10),
                                borderSide: BorderSide(color: Colors.grey.shade400),
                              ),
                            ),
                          );
                        }
                      ),
                    ),
                    const SizedBox(width: 10),
                    SizedBox(
                      height: 56, 
                      child: ElevatedButton(
                        onPressed: () => addMedicine(inventory),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.teal, 
                          foregroundColor: Colors.white,
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                          padding: const EdgeInsets.symmetric(horizontal: 20)
                        ),
                        child: const Text("Add"),
                      ),
                    ),
                  ],
                );
              },
            ),

            const SizedBox(height: 20),

            if (selectedMeds.value.isNotEmpty) ...[
              const Text("Prescribed Items:", style: TextStyle(fontWeight: FontWeight.bold)),
              const SizedBox(height: 5),
              ListView.builder(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                itemCount: selectedMeds.value.length,
                itemBuilder: (ctx, i) {
                  final item = selectedMeds.value[i];
                  return Card(
                    margin: const EdgeInsets.symmetric(vertical: 4),
                    child: ListTile(
                      title: Text(item['name'], style: const TextStyle(fontWeight: FontWeight.bold)),
                      subtitle: Text("Type: ${item['type']}"),
                      trailing: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          IconButton(
                            icon: const Icon(Icons.remove_circle_outline, color: Colors.red),
                            onPressed: () {
                              if (item['qty'] > 1) {
                                final newList = [...selectedMeds.value];
                                newList[i]['qty']--;
                                selectedMeds.value = newList; 
                              } else {
                                final newList = [...selectedMeds.value];
                                newList.removeAt(i);
                                selectedMeds.value = newList;
                              }
                            },
                          ),
                          Text("${item['qty']}", style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                          IconButton(
                            icon: const Icon(Icons.add_circle_outline, color: Colors.green),
                            onPressed: () {
                                final newList = [...selectedMeds.value];
                                newList[i]['qty']++;
                                selectedMeds.value = newList;
                            },
                          ),
                        ],
                      ),
                    ),
                  );
                },
              ),
            ],

            const SizedBox(height: 30),

            SizedBox(
              width: double.infinity,
              height: 50,
              child: ElevatedButton.icon(
                onPressed: finishConsultation,
                icon: const Icon(Icons.check_circle),
                label: const Text("Complete Consultation", style: TextStyle(fontSize: 18)),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.teal[700],
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
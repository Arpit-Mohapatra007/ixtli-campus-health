import 'package:flutter/material.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import '../../../providers/pharmacy_provider.dart';

class InventoryTab extends ConsumerWidget {
  const InventoryTab({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final inventoryAsync = ref.watch(inventoryProvider);

    void showRestockDialog(BuildContext context, String medId, String medName) {
      final controller = TextEditingController(); 
      
      showDialog(
        context: context, 
        builder: (ctx) => AlertDialog(
          title: Text("Restock $medName"),
          content: TextField(
            controller: controller,
            keyboardType: TextInputType.number,
            autofocus: true,
            decoration: const InputDecoration(
              labelText: "Quantity to Add",
              hintText: "e.g. 50",
              border: OutlineInputBorder(),
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(ctx), 
              child: const Text("Cancel")
            ),
            ElevatedButton(
              onPressed: () async {
                final amount = int.tryParse(controller.text);
                if (amount != null && amount > 0) {
                  await ref.read(pharmacyServiceProvider).restockMedicine(medId, amount);
                  if (ctx.mounted) {
                    Navigator.pop(ctx);
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(content: Text("Added $amount units to $medName"), backgroundColor: Colors.green)
                    );
                  }
                }
              },
              style: ElevatedButton.styleFrom(backgroundColor: Colors.green, foregroundColor: Colors.white), 
              child: const Text("Confirm"),
            )
          ],
        )
      );
    }

    return Container(
      color: Colors.white,
      child: inventoryAsync.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, _) => Center(child: Text("Error: $e")),
        data: (meds) {
          if (meds.isEmpty) return const Center(child: Text("Inventory Empty"));
          
          return ListView.builder(
            padding: const EdgeInsets.all(12),
            itemCount: meds.length,
            itemBuilder: (ctx, i) {
              final med = meds[i];
              final stock = med['stock'] as int;
              final isLow = stock < 20;

              return Card(
                elevation: 2,
                margin: const EdgeInsets.symmetric(vertical: 6),
                child: ListTile(
                  leading: CircleAvatar(
                    backgroundColor: isLow ? Colors.red[100] : Colors.green[100],
                    child: Icon(Icons.local_pharmacy, color: isLow ? Colors.red : Colors.green),
                  ),
                  title: Text(med['name'], style: const TextStyle(fontWeight: FontWeight.bold)),
                  subtitle: Text("${med['type']} • Stock: $stock"),
                  trailing: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      if (isLow)
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                          margin: const EdgeInsets.only(right: 10),
                          decoration: BoxDecoration(
                            color: Colors.red,
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: const Text("LOW", style: TextStyle(color: Colors.white, fontSize: 10, fontWeight: FontWeight.bold)),
                        ),
                      IconButton.filled(
                        icon: const Icon(Icons.add),
                        style: IconButton.styleFrom(backgroundColor: Colors.blueGrey),
                        onPressed: () => showRestockDialog(context, med['id'], med['name']),
                      ),
                    ],
                  ),
                ),
              );
            },
          );
        },
      ),
    );
  }
}
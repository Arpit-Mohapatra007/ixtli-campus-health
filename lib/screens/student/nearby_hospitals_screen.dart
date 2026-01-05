import 'package:campus_health/providers/content_provider.dart' show hospitalsProvider;
import 'package:flutter/material.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:url_launcher/url_launcher.dart';

class NearbyHospitalsScreen extends ConsumerWidget {
  const NearbyHospitalsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final hospitalsAsync = ref.watch(hospitalsProvider);

    Future<void> openMap(String? link) async {
      if (link == null || link.isEmpty) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text("Map link unavailable for this hospital"))
        );
        return;
      }

      final uri = Uri.parse(link);
      
      try {
        if (!await launchUrl(uri, mode: LaunchMode.externalApplication)) {
           if (context.mounted) {
             ScaffoldMessenger.of(context).showSnackBar(
               const SnackBar(content: Text("Could not open map link"))
             );
           }
        }
      } catch (e) {
        if (context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text("Error: $e"))
          );
        }
      }
    }

    return Scaffold(
      appBar: AppBar(title: const Text("Nearby Hospitals"), backgroundColor: Colors.teal, foregroundColor: Colors.white),
      body: hospitalsAsync.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, _) => Center(child: Text("Error: $e")),
        data: (hospitals) {
          if (hospitals.isEmpty) return const Center(child: Text("No hospitals info available"));
          
          return ListView.builder(
            padding: const EdgeInsets.all(16),
            itemCount: hospitals.length,
            itemBuilder: (context, index) {
              final hospital = hospitals[index];
              final name = hospital['name'] ?? 'Unknown';
              final mapLink = hospital['mapLink'];
              final distance = hospital['distance'] ?? 'Unknown Distance';

              return Card(
                elevation: 4,
                margin: const EdgeInsets.only(bottom: 20),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
                clipBehavior: Clip.antiAlias,
                child: Column(
                  children: [
                    InkWell(
                      onTap: () => openMap(mapLink),
                      child: Container(
                        height: 140,
                        width: double.infinity,
                        decoration: BoxDecoration(
                          color: Colors.blueGrey[50],
                          image: const DecorationImage(
                            image: NetworkImage("https://img.freepik.com/free-vector/city-map-background-blue-tones_23-2148299443.jpg?w=1060"), 
                            fit: BoxFit.cover,
                            opacity: 0.4
                          ),
                        ),
                        child: Stack(
                          alignment: Alignment.center,
                          children: [
                            const Icon(Icons.location_on, size: 50, color: Colors.red),
                            Positioned(
                              bottom: 10,
                              right: 10,
                              child: Container(
                                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                                decoration: BoxDecoration(
                                  color: Colors.white,
                                  borderRadius: BorderRadius.circular(20),
                                  boxShadow: [BoxShadow(blurRadius: 2, color: Colors.black)]
                                ),
                                child: Row(
                                  children: [
                                    const Icon(Icons.map, size: 14, color: Colors.blue),
                                    const SizedBox(width: 5),
                                    Text("Open Map ($distance)", style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 12)),
                                  ],
                                ),
                              ),
                            )
                          ],
                        ),
                      ),
                    ),
                    
                    ListTile(
                      title: Text(name, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 18)),
                      subtitle: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          if (hospital['doctor'] != null) 
                            Padding(
                              padding: const EdgeInsets.only(top: 4.0),
                              child: Text("${hospital['doctor']}"),
                            ),
                        ],
                      ),
                      trailing: ElevatedButton.icon(
                        icon: const Icon(Icons.call, size: 18),
                        label: const Text("Call"),
                        style: ElevatedButton.styleFrom(backgroundColor: Colors.green, foregroundColor: Colors.white),
                        onPressed: () {
                           if (hospital['phone'] != null) {
                             launchUrl(Uri.parse("tel:${hospital['phone']}"));
                           }
                        },
                      ),
                    ),
                  ],
                ),
              );
            },
          );
        },
      ),
    );
  }
}
import 'package:campus_health/providers/content_provider.dart' show hospitalsProvider;
import 'package:flutter/material.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart'; 

class NearbyHospitalsScreen extends ConsumerWidget {
  const NearbyHospitalsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final hospitalsAsync = ref.watch(hospitalsProvider);

    Future<void> openMap(String? link) async {
      if (link == null || link.isEmpty) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text("Map link unavailable"))
        );
        return;
      }
      final uri = Uri.parse(link);
      try {
        if (!await launchUrl(uri, mode: LaunchMode.externalApplication)) {
           if (context.mounted) {
             ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("Could not open map")));
           }
        }
      } catch (e) {
        if (context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text("Error: $e")));
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
              final double? lat = hospital['lat'];
              final double? lng = hospital['lng'];
              final bool hasCoords = lat != null && lng != null;

              return Card(
                elevation: 4,
                margin: const EdgeInsets.only(bottom: 20),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
                clipBehavior: Clip.antiAlias,
                child: Column(
                  children: [
                    SizedBox(
                      height: 160,
                      width: double.infinity,
                      child: hasCoords 
                        ? FlutterMap(
                            options: MapOptions(
                              initialCenter: LatLng(lat, lng),
                              initialZoom: 15.0,
                              interactionOptions: const InteractionOptions(
                                flags: InteractiveFlag.none,
                              ),
                              onTap: (_, __) => openMap(mapLink),
                            ),
                            children: [
                              TileLayer(
                                urlTemplate: 'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
                                userAgentPackageName: 'com.example.campus_health',
                              ),
                              MarkerLayer(
                                markers: [
                                  Marker(
                                    point: LatLng(lat, lng),
                                    width: 40,
                                    height: 40,
                                    child: const Icon(Icons.location_on, color: Colors.red, size: 40),
                                  ),
                                ],
                              ),
                              Positioned(
                                bottom: 10,
                                right: 10,
                                child: Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                                  decoration: BoxDecoration(
                                    color: Colors.white,
                                    borderRadius: BorderRadius.circular(20),
                                    boxShadow: const [BoxShadow(color: Colors.black26, blurRadius: 4)]
                                  ),
                                  child: Row(
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      const Icon(Icons.map, size: 14, color: Colors.blue),
                                      const SizedBox(width: 4),
                                      Text("Tap to Navigate ($distance)", style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 12)),
                                    ],
                                  ),
                                ),
                              )
                            ],
                          )
                        : Container(
                            color: Colors.grey[200],
                            alignment: Alignment.center,
                            child: const Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Icon(Icons.map_outlined, size: 40, color: Colors.grey),
                                SizedBox(height: 5),
                                Text("Map Preview Unavailable", style: TextStyle(color: Colors.grey)),
                              ],
                            ),
                          ),
                    ),
                    ListTile(
                      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                      title: Text(name, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 18)),
                      subtitle: hospital['doctor'] != null 
                          ? Text("Dr. ${hospital['doctor']}", style: const TextStyle(fontWeight: FontWeight.w500)) 
                          : null,
                      trailing: ElevatedButton.icon(
                        icon: const Icon(Icons.call, size: 18),
                        label: const Text("Call"),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.green, 
                          foregroundColor: Colors.white,
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20))
                        ),
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
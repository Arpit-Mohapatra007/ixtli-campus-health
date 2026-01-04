import 'package:flutter/material.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../services/content_service.dart';

class AuthoritiesContactScreen extends ConsumerWidget {
  const AuthoritiesContactScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final contactsAsync = ref.watch(contactsProvider);

    IconData getIcon(String? type) {
       switch (type) {
        case 'ambulance': return Icons.medical_services;
        case 'security': return Icons.security;
        case 'admin': return Icons.admin_panel_settings;
        default: return Icons.person;
      }
    }

    return Scaffold(
      appBar: AppBar(title: const Text("Emergency Contacts"), backgroundColor: Colors.redAccent, foregroundColor: Colors.white),
      body: contactsAsync.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, _) => Center(child: Text("Error: $e")),
        data: (contacts) {
          if (contacts.isEmpty) return const Center(child: Text("No contacts available"));

          return ListView.builder(
            padding: const EdgeInsets.all(16),
            itemCount: contacts.length,
            itemBuilder: (context, index) {
              final contact = contacts[index];
              return Card(
                elevation: 2,
                margin: const EdgeInsets.only(bottom: 12),
                child: ListTile(
                  leading: CircleAvatar(
                    backgroundColor: Colors.red[50],
                    child: Icon(getIcon(contact['icon']), color: Colors.red),
                  ),
                  title: Text(contact['role'] ?? 'Official', style: const TextStyle(fontWeight: FontWeight.bold)),
                  subtitle: Text("${contact['name'] ?? ''}"),
                  trailing: IconButton(
                    icon: const Icon(Icons.call, color: Colors.green),
                    onPressed: () {
                      if (contact['phone'] != null) {
                        launchUrl(Uri.parse("tel:${contact['phone']}"));
                      }
                    },
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
import 'package:cloud_firestore/cloud_firestore.dart';

class SentinelService {
  final FirebaseFirestore _db = FirebaseFirestore.instance;
  final _roomRegex = RegExp(r"^([A-Z0-9]+)([1-4])(\d{2})$");

  Stream<List<String>> getOutbreakMessages() {
    final yesterday = DateTime.now().subtract(const Duration(hours: 48));
    
    return _db.collection('prescriptions')
        .where('timestamp', isGreaterThan: Timestamp.fromDate(yesterday))
        .snapshots()
        .map((snapshot) {
          Map<String, int> locationCounts = {};
          
          for (var doc in snapshot.docs) {
            final data = doc.data();
            String room = data['roomNumber'] ?? "";
            String hostel = data['hostel'] ?? "Unknown";
            
            final match = _roomRegex.firstMatch(room);
            if (match != null) {
              String wing = match.group(1)!; 
              String floor = match.group(2)!; 
              
              String key = "$hostel|$wing|$floor";
              locationCounts[key] = (locationCounts[key] ?? 0) + 1;
            }
          }

          List<String> messages = [];
          
          locationCounts.forEach((key, caseCount) {
            if (caseCount >= 2) { 
              final parts = key.split('|');
              messages.add("$caseCount cases in Wing ${parts[1]} of ${parts[2]}rd Floor in ${parts[0]}");
            }
          });
          
          if (messages.isEmpty) messages.add("No active outbreaks detected.");
          return messages;
        });
  }

  Future<void> sendBroadcast({
    required String hostel,
    String? floor, 
    String? wing,
    required String message
  }) async {
    await _db.collection('broadcasts').add({
      'targetHostel': hostel,
      'targetFloor': floor ?? "All",
      'targetWing': wing ?? "All",
      'message': message,
      'timestamp': FieldValue.serverTimestamp(),
      'sentBy': 'Admin'
    });
  }
}
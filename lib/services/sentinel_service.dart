import 'package:cloud_firestore/cloud_firestore.dart';

class SentinelService {
  final FirebaseFirestore _db = FirebaseFirestore.instance;

  Stream<List<Map<String, dynamic>>> getOutbreakAlerts() {
    final yesterday = DateTime.now().subtract(const Duration(hours: 24));
    
    return _db.collection('prescriptions')
        .where('timestamp', isGreaterThan: Timestamp.fromDate(yesterday))
        .snapshots()
        .map((snapshot) {
          
          final Map<String, int> clusterCounts = {};
          final Map<String, Map<String, dynamic>> alertMetadata = {};

          for (var doc in snapshot.docs) {
            final data = doc.data();
            final hostel = data['hostel'] as String? ?? 'Unknown';
            final diagnosisRaw = data['diagnosis'] as String? ?? '';
            
            final diagnosis = diagnosisRaw.trim().toUpperCase();

            if (hostel == 'Unknown' || diagnosis.isEmpty) continue;

            final key = "$hostel|$diagnosis"; 

            clusterCounts[key] = (clusterCounts[key] ?? 0) + 1;
            
            if (!alertMetadata.containsKey(key)) {
              alertMetadata[key] = {
                'hostel': hostel,
                'diagnosis': diagnosisRaw, 
                'count': 0,
              };
            }
          }

          final List<Map<String, dynamic>> alerts = [];
          
          clusterCounts.forEach((key, caseCount) {
            if (caseCount >= 2) { 
              final alert = alertMetadata[key]!;
              alert['count'] = caseCount;
              
              if (caseCount >= 5) {
                alert['severity'] = 'CRITICAL'; 
              } else {
                alert['severity'] = 'WARNING'; 
              }
              
              alerts.add(alert);
            }
          });

          return alerts;
        });
  }
}
import 'package:cloud_firestore/cloud_firestore.dart';
import '../utils/app_exception.dart'; 

class PharmacyService {
  final FirebaseFirestore _db = FirebaseFirestore.instance;

  Stream<List<Map<String, dynamic>>> getInventory() {
    return _db.collection('inventory')
        .where('stock', isGreaterThan: 0)
        .orderBy('stock') 
        .snapshots()
        .map((snapshot) => snapshot.docs.map((doc) => {
              ...doc.data(),
              'id': doc.id,
            }).toList());
  }

  Future<void> submitPrescription({
    required String appointmentId,
    required String studentId,
    required String studentName,
    required String doctorId,
    required String diagnosis,
    required List<Map<String, dynamic>> medicines,
    required String hostel,
    required String roomNumber,
  }) async {
    return _db.runTransaction((transaction) async {
      final presRef = _db.collection('prescriptions').doc();
      final appRef = _db.collection('appointments').doc(appointmentId);
      
      Map<String, DocumentSnapshot> medSnapshots = {};

      for (var med in medicines) {
        final medId = med['id'];
        final medRef = _db.collection('inventory').doc(medId);
        final snapshot = await transaction.get(medRef);
        
        if (!snapshot.exists) {
          throw AppException("Medicine ${med['name']} not found in database!");
        }
        
        int currentStock = (snapshot.data() as Map<String, dynamic>)['stock'] ?? 0;
        int requestedQty = med['qty'];
        
        if (currentStock < requestedQty) {
          throw AppException("Insufficient stock for ${med['name']}. Only $currentStock left.");
        }

        medSnapshots[medId] = snapshot;
      }

      transaction.set(presRef, {
        'appointmentId': appointmentId,
        'studentId': studentId,
        'studentName': studentName,
        'doctorId': doctorId,
        'diagnosis': diagnosis.trim(),
        'medicines': medicines,
        'timestamp': FieldValue.serverTimestamp(),
        'hostel': hostel,
        'roomNumber': roomNumber,
      });

      for (var med in medicines) {
        final medId = med['id'];
        final snapshot = medSnapshots[medId]!;
        final medRef = _db.collection('inventory').doc(medId);
        
        int currentStock = (snapshot.data() as Map<String, dynamic>)['stock'];
        int newStock = currentStock - (med['qty'] as int);
        
        transaction.update(medRef, {'stock': newStock});
      }

      transaction.update(appRef, {'status': 'completed'});
    });
  }
}
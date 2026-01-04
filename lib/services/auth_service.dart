import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/user_model.dart';
import '../utils/app_exception.dart';
import 'notification_service.dart';

class AuthService {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _db = FirebaseFirestore.instance;
  
  User? get currentUser => _auth.currentUser;
  Stream<User?> get authStateChanges => _auth.authStateChanges();

  Future<void> signUp({
    required String email, 
    required String password, 
  }) async {
    final registryQuery = await _db.collection('college_registry')
        .where('email', isEqualTo: email)
        .limit(1)
        .get();

    if (registryQuery.docs.isEmpty) {
      throw AppException("This email is not registered with the college database.");
    }

    final data = registryQuery.docs.first.data();

    UserCredential result = await _auth.createUserWithEmailAndPassword(
      email: email, 
      password: password
    );

    UserModel newUser = UserModel(
      uid: result.user!.uid,
      email: email,
      name: data['name'] ?? 'Student',
      role: data['role'] ?? 'student', 
      hostel: data['hostel'] ?? 'Unknown',
      roomNumber: data['roomNumber'] ?? 'Unknown', 
      bloodGroup: data['bloodGroup'] ?? 'Unknown',
      emergencyContact: data['emergencyContact'] ?? '',
      dob: data['dob'] != null ? (data['dob'] as Timestamp).toDate() : null,
      specialization: data['specialization'],
    );

    await _db.collection('users').doc(newUser.uid).set(newUser.toMap());

    await NotificationService().uploadFcmToken();
  }

  Future<void> signIn(String email, String password) async {
    try {
      await _auth.signInWithEmailAndPassword(email: email, password: password);

      await NotificationService().uploadFcmToken();
      
    } catch (e) {
      throw AppException.from(e); 
    }
  }

  Future<void> signOut() async {
    await _auth.signOut();
  }
}
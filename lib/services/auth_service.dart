import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/user_model.dart';

class AuthService {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _db = FirebaseFirestore.instance;

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
    throw Exception("This email is not registered with the college database.");
  }

  final collegeData = registryQuery.docs.first.data();
  
  UserCredential result = await _auth.createUserWithEmailAndPassword(
    email: email, 
    password: password
  );

  UserModel newUser = UserModel(
    uid: result.user!.uid,
    email: email,
    name: collegeData['name'],
    role: collegeData['role'], 
    hostel: collegeData['hostel'],
    roomNumber: collegeData['roomNumber'],
  );
  
  await _db.collection('users').doc(newUser.uid).set(newUser.toMap());
}

  Future<void> signIn(String email, String password) async {
    await _auth.signInWithEmailAndPassword(email: email, password: password);
  }

  Future<void> signOut() async {
    await _auth.signOut();
  }
}
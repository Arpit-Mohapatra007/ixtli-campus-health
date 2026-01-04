import 'package:cloud_firestore/cloud_firestore.dart';

class UserModel {
  final String uid;
  final String email;
  final String name;
  final String role;
  final String hostel;
  final String roomNumber;
  final String bloodGroup;
  final String emergencyContact;
  final DateTime? dob;
  final String? specialization;
  final String? fcmToken; 

  UserModel({
    required this.uid,
    required this.email,
    required this.name,
    required this.role,
    this.hostel = 'Unknown',
    this.roomNumber = 'Unknown',
    this.bloodGroup = 'Unknown',
    this.emergencyContact = '',
    this.dob,
    this.specialization,
    this.fcmToken, 
  });

  String get age {
    if (dob == null) return "N/A";
    final now = DateTime.now();
    int age = now.year - dob!.year;
    if (now.month < dob!.month || (now.month == dob!.month && now.day < dob!.day)) {
      age--;
    }
    return age.toString();
  }

  factory UserModel.fromMap(Map<String, dynamic> map, String uid) {
    return UserModel(
      uid: uid,
      email: map['email'] ?? '',
      name: map['name'] ?? '',
      role: map['role'] ?? 'student',
      hostel: map['hostel'] ?? 'Unknown',
      roomNumber: map['roomNumber'] ?? 'Unknown',
      bloodGroup: map['bloodGroup'] ?? 'Unknown',
      emergencyContact: map['emergencyContact'] ?? '',
      dob: map['dob'] != null ? (map['dob'] as Timestamp).toDate() : null,
      specialization: map['specialization'],
      fcmToken: map['fcmToken'], 
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'email': email,
      'name': name,
      'role': role,
      'hostel': hostel,
      'roomNumber': roomNumber,
      'bloodGroup': bloodGroup,
      'emergencyContact': emergencyContact,
      'dob': dob != null ? Timestamp.fromDate(dob!) : null,
      'specialization': specialization,
      'fcmToken': fcmToken,
    };
  }
}
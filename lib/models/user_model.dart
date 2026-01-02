class UserModel {
  final String uid;
  final String email;
  final String name;
  final String role; 
  final String? hostel;
  final String? roomNumber; 

  UserModel({
    required this.uid,
    required this.email,
    required this.name,
    required this.role,
    this.hostel,
    this.roomNumber,
  });

  factory UserModel.fromMap(Map<String, dynamic> map, String uid) {
    return UserModel(
      uid: uid,
      email: map['email'] ?? '',
      name: map['name'] ?? '',
      role: map['role'] ?? 'student',
      hostel: map['hostel'],
      roomNumber: map['roomNumber'],
    );
  }

   Map<String, dynamic> toMap() {
    return {
      'email': email,
      'name': name,
      'role': role,
      'hostel': hostel,
      'roomNumber': roomNumber,
    };
  }
}
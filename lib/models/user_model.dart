// lib/models/user_model.dart
import 'package:cloud_firestore/cloud_firestore.dart';

class UserModel {
  final String uid;
  final String name;
  final String email;
  final String phone;
  final String photoUrl;
  final String bio;
  final bool isOnline;
  final DateTime lastSeen;
  final String fcmToken;
  final DateTime createdAt;

  const UserModel({
    required this.uid,
    required this.name,
    required this.email,
    this.phone = '',
    this.photoUrl = '',
    this.bio = '',
    this.isOnline = false,
    required this.lastSeen,
    this.fcmToken = '',
    required this.createdAt,
  });

  factory UserModel.fromMap(Map<String, dynamic> map, String id) {
    return UserModel(
      uid: id,
      name: map['name'] as String? ?? '',
      email: map['email'] as String? ?? '',
      phone: map['phone'] as String? ?? '',
      photoUrl: map['photoUrl'] as String? ?? '',
      bio: map['bio'] as String? ?? '',
      isOnline: map['isOnline'] as bool? ?? false,
      lastSeen: (map['lastSeen'] as Timestamp?)?.toDate() ?? DateTime.now(),
      fcmToken: map['fcmToken'] as String? ?? '',
      createdAt: (map['createdAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
    );
  }

  factory UserModel.fromDoc(DocumentSnapshot doc) {
    return UserModel.fromMap(doc.data() as Map<String, dynamic>, doc.id);
  }

  Map<String, dynamic> toMap() => {
        'name': name,
        'email': email,
        'phone': phone,
        'photoUrl': photoUrl,
        'bio': bio,
        'isOnline': isOnline,
        'lastSeen': Timestamp.fromDate(lastSeen),
        'fcmToken': fcmToken,
        'createdAt': Timestamp.fromDate(createdAt),
      };

  UserModel copyWith({
    String? name,
    String? email,
    String? phone,
    String? photoUrl,
    String? bio,
    bool? isOnline,
    DateTime? lastSeen,
    String? fcmToken,
  }) =>
      UserModel(
        uid: uid,
        name: name ?? this.name,
        email: email ?? this.email,
        phone: phone ?? this.phone,
        photoUrl: photoUrl ?? this.photoUrl,
        bio: bio ?? this.bio,
        isOnline: isOnline ?? this.isOnline,
        lastSeen: lastSeen ?? this.lastSeen,
        fcmToken: fcmToken ?? this.fcmToken,
        createdAt: createdAt,
      );
}

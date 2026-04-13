// lib/services/auth_service.dart
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import '../models/user_model.dart';
import '../core/constants/app_constants.dart';

class AuthService {
  AuthService._();
  static final AuthService instance = AuthService._();

  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _db = FirebaseFirestore.instance;

  User? get currentUser => _auth.currentUser;
  Stream<User?> get authStateChanges => _auth.authStateChanges();

  // ─── Register ──────────────────────────────────────
  Future<UserCredential> register({
    required String name,
    required String email,
    required String password,
  }) async {
    final credential = await _auth.createUserWithEmailAndPassword(
      email: email.trim(),
      password: password,
    );

    await credential.user!.updateDisplayName(name.trim());

    final token = await FirebaseMessaging.instance.getToken();

    final user = UserModel(
      uid: credential.user!.uid,
      name: name.trim(),
      email: email.trim(),
      lastSeen: DateTime.now(),
      createdAt: DateTime.now(),
      fcmToken: token ?? '',
    );

    await _db
        .collection(AppConstants.usersCollection)
        .doc(credential.user!.uid)
        .set(user.toMap());

    return credential;
  }

  // ─── Login ─────────────────────────────────────────
  Future<UserCredential> login({
    required String email,
    required String password,
  }) async {
    final credential = await _auth.signInWithEmailAndPassword(
      email: email.trim(),
      password: password,
    );

    // Update FCM token & online status
    final token = await FirebaseMessaging.instance.getToken();
    await _db
        .collection(AppConstants.usersCollection)
        .doc(credential.user!.uid)
        .update({
      'isOnline': true,
      'lastSeen': FieldValue.serverTimestamp(),
      if (token != null) 'fcmToken': token,
    });

    return credential;
  }

  // ─── Logout ────────────────────────────────────────
  Future<void> logout() async {
    if (currentUser != null) {
      await _db
          .collection(AppConstants.usersCollection)
          .doc(currentUser!.uid)
          .update({
        'isOnline': false,
        'lastSeen': FieldValue.serverTimestamp(),
      });
    }
    await _auth.signOut();
  }

  // ─── Reset Password ────────────────────────────────
  Future<void> resetPassword(String email) async {
    await _auth.sendPasswordResetEmail(email: email.trim());
  }

  // ─── Get Current User Data ─────────────────────────
  Future<UserModel?> getCurrentUserData() async {
    if (currentUser == null) return null;
    final doc = await _db
        .collection(AppConstants.usersCollection)
        .doc(currentUser!.uid)
        .get();
    if (!doc.exists) return null;
    return UserModel.fromDoc(doc);
  }

  // ─── Update Profile ────────────────────────────────
  Future<void> updateProfile({
    String? name,
    String? bio,
    String? phone,
    String? photoUrl,
  }) async {
    if (currentUser == null) return;
    final data = <String, dynamic>{};
    if (name != null) data['name'] = name;
    if (bio != null) data['bio'] = bio;
    if (phone != null) data['phone'] = phone;
    if (photoUrl != null) data['photoUrl'] = photoUrl;

    await _db
        .collection(AppConstants.usersCollection)
        .doc(currentUser!.uid)
        .update(data);

    if (name != null) await currentUser!.updateDisplayName(name);
  }

  // ─── Update Online Status ──────────────────────────
  Future<void> setOnlineStatus(bool isOnline) async {
    if (currentUser == null) return;
    await _db
        .collection(AppConstants.usersCollection)
        .doc(currentUser!.uid)
        .update({
      'isOnline': isOnline,
      'lastSeen': FieldValue.serverTimestamp(),
    });
  }

  // ─── Search Users ──────────────────────────────────
  Future<List<UserModel>> searchUsers(String query) async {
    if (query.isEmpty) return [];
    final snap = await _db
        .collection(AppConstants.usersCollection)
        .where('name', isGreaterThanOrEqualTo: query)
        .where('name', isLessThanOrEqualTo: '$query\uf8ff')
        .limit(20)
        .get();
    return snap.docs
        .map((d) => UserModel.fromDoc(d))
        .where((u) => u.uid != currentUser?.uid)
        .toList();
  }

  // ─── Stream User ───────────────────────────────────
  Stream<UserModel?> streamUser(String uid) {
    return _db
        .collection(AppConstants.usersCollection)
        .doc(uid)
        .snapshots()
        .map((doc) => doc.exists ? UserModel.fromDoc(doc) : null);
  }
}

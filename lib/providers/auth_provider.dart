// lib/providers/auth_provider.dart
import 'package:flutter/foundation.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../models/user_model.dart';
import '../services/auth_service.dart';

enum AuthStatus { initial, loading, authenticated, unauthenticated, error }

class AuthProvider extends ChangeNotifier {
  AuthStatus _status = AuthStatus.initial;
  UserModel? _user;
  String _errorMessage = '';

  AuthStatus get status       => _status;
  UserModel? get user         => _user;
  String get errorMessage     => _errorMessage;
  bool get isAuthenticated    => _status == AuthStatus.authenticated;
  bool get isLoading          => _status == AuthStatus.loading;

  AuthProvider() {
    _init();
  }

  void _init() {
    AuthService.instance.authStateChanges.listen((firebaseUser) async {
      if (firebaseUser != null) {
        await _loadUser(firebaseUser);
      } else {
        _status = AuthStatus.unauthenticated;
        _user = null;
        notifyListeners();
      }
    });
  }

  Future<void> _loadUser(User firebaseUser) async {
    final userData = await AuthService.instance.getCurrentUserData();
    _user = userData;
    _status = AuthStatus.authenticated;
    notifyListeners();
  }

  Future<bool> register({
    required String name,
    required String email,
    required String password,
  }) async {
    _setLoading();
    try {
      await AuthService.instance.register(
        name: name,
        email: email,
        password: password,
      );
      return true;
    } on FirebaseAuthException catch (e) {
      _setError(_mapFirebaseError(e.code));
      return false;
    }
  }

  Future<bool> login({
    required String email,
    required String password,
  }) async {
    _setLoading();
    try {
      await AuthService.instance.login(email: email, password: password);
      return true;
    } on FirebaseAuthException catch (e) {
      _setError(_mapFirebaseError(e.code));
      return false;
    }
  }

  Future<void> logout() async {
    await AuthService.instance.logout();
  }

  Future<bool> resetPassword(String email) async {
    _setLoading();
    try {
      await AuthService.instance.resetPassword(email);
      _status = AuthStatus.unauthenticated;
      notifyListeners();
      return true;
    } on FirebaseAuthException catch (e) {
      _setError(_mapFirebaseError(e.code));
      return false;
    }
  }

  Future<void> refreshUser() async {
    final u = await AuthService.instance.getCurrentUserData();
    _user = u;
    notifyListeners();
  }

  void _setLoading() {
    _status = AuthStatus.loading;
    _errorMessage = '';
    notifyListeners();
  }

  void _setError(String msg) {
    _status = AuthStatus.error;
    _errorMessage = msg;
    notifyListeners();
  }

  String _mapFirebaseError(String code) {
    switch (code) {
      case 'user-not-found':       return 'لا يوجد حساب بهذا البريد الإلكتروني';
      case 'wrong-password':       return 'كلمة المرور غير صحيحة';
      case 'email-already-in-use': return 'البريد الإلكتروني مستخدم مسبقاً';
      case 'invalid-email':        return 'البريد الإلكتروني غير صالح';
      case 'weak-password':        return 'كلمة المرور ضعيفة جداً (6 أحرف على الأقل)';
      case 'network-request-failed': return 'تحقق من اتصالك بالإنترنت';
      case 'too-many-requests':    return 'محاولات كثيرة، حاول لاحقاً';
      case 'invalid-credential':   return 'البريد أو كلمة المرور غير صحيحة';
      default:                     return 'حدث خطأ، حاول مرة أخرى';
    }
  }
}

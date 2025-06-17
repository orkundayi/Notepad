import 'package:flutter/foundation.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../models/user.dart';
import '../services/auth_service.dart';

class AuthProvider with ChangeNotifier {
  final AuthService _authService = AuthService();

  AppUser? _user;
  bool _isLoading = false;
  String? _errorMessage;
  bool _isFirebaseAvailable = false;

  AppUser? get user => _user;
  bool get isLoading => _isLoading;
  String? get errorMessage => _errorMessage;
  bool get isAuthenticated => _user != null;
  bool get isFirebaseAvailable => _isFirebaseAvailable;

  AuthProvider() {
    _initializeAuth();
  }
  void _initializeAuth() {
    // Firebase artık Windows'ta da destekleniyor
    _isFirebaseAvailable = true;

    if (_isFirebaseAvailable) {
      // Listen to auth state changes
      _authService.authStateChanges.listen((User? firebaseUser) {
        _user =
            firebaseUser != null
                ? AppUser(
                  uid: firebaseUser.uid,
                  email: firebaseUser.email ?? '',
                  displayName: firebaseUser.displayName,
                  lastLogin: DateTime.now(),
                )
                : null;
        notifyListeners();
      });
    }
  } // Sign in with email and password

  Future<bool> signIn(String email, String password) async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      AppUser? user = await _authService.signInWithEmailAndPassword(
        email,
        password,
      );
      _user = user;
      _isLoading = false;
      notifyListeners();
      return user != null;
    } catch (e) {
      _errorMessage = _getErrorMessage(e.toString());
      _isLoading = false;
      notifyListeners();
      return false;
    }
  } // Register with email and password

  Future<bool> register(String email, String password) async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      AppUser? user = await _authService.registerWithEmailAndPassword(
        email,
        password,
      );
      _user = user;
      _isLoading = false;
      notifyListeners();
      return user != null;
    } catch (e) {
      _errorMessage = _getErrorMessage(e.toString());
      _isLoading = false;
      notifyListeners();
      return false;
    }
  }

  // Sign out
  Future<void> signOut() async {
    _isLoading = true;
    notifyListeners();

    try {
      await _authService.signOut();
      _user = null;
      _errorMessage = null;
    } catch (e) {
      _errorMessage = _getErrorMessage(e.toString());
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  // Sign up alias for register
  Future<bool> signUp(String email, String password) async {
    return await register(email, password);
  }

  // Reset password
  Future<bool> resetPassword(String email) async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      await _authService.resetPassword(email);
      _isLoading = false;
      notifyListeners();
      return true;
    } catch (e) {
      _errorMessage = _getErrorMessage(e.toString());
      _isLoading = false;
      notifyListeners();
      return false;
    }
  }

  // Clear error message
  void clearError() {
    _errorMessage = null;
    notifyListeners();
  }

  // Get user-friendly error messages
  String _getErrorMessage(String error) {
    if (error.contains('user-not-found')) {
      return 'Bu e-posta adresiyle kayıtlı kullanıcı bulunamadı.';
    } else if (error.contains('wrong-password')) {
      return 'Hatalı şifre girdiniz.';
    } else if (error.contains('email-already-in-use')) {
      return 'Bu e-posta adresi zaten kullanılıyor.';
    } else if (error.contains('weak-password')) {
      return 'Şifre çok zayıf. En az 6 karakter olmalıdır.';
    } else if (error.contains('invalid-email')) {
      return 'Geçersiz e-posta adresi.';
    } else if (error.contains('too-many-requests')) {
      return 'Çok fazla deneme yapıldı. Lütfen daha sonra tekrar deneyin.';
    } else if (error.contains('network-request-failed')) {
      return 'İnternet bağlantınızı kontrol edin.';
    } else {
      return 'Bir hata oluştu. Lütfen tekrar deneyin.';
    }
  }
}

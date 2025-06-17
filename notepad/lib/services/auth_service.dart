import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart';
import '../models/user.dart';
import 'firestore_service.dart';
import '../utils/platform_checker.dart';

class AuthService {
  FirebaseAuth? _auth;
  final FirestoreService _firestoreService = FirestoreService();

  AuthService() {
    // Firebase Auth sadece mobile ve web'de çalışır
    if (PlatformChecker.supportsFirebaseAuth) {
      _auth = FirebaseAuth.instance;
    }
  }

  // Get current user stream
  Stream<User?> get authStateChanges {
    if (_auth != null) {
      return _auth!.authStateChanges();
    }
    return Stream.value(null);
  }

  // Get current user
  User? get currentUser => _auth?.currentUser;

  // Convert Firebase User to AppUser
  AppUser? _userFromFirebaseUser(User? user) {
    return user != null
        ? AppUser(
          uid: user.uid,
          email: user.email ?? '',
          displayName: user.displayName,
          lastLogin: DateTime.now(),
        )
        : null;
  }

  // Sign in with email and password
  Future<AppUser?> signInWithEmailAndPassword(
    String email,
    String password,
  ) async {
    if (_auth == null) {
      throw Exception('Firebase bu platformda desteklenmiyor');
    }
    try {
      UserCredential result = await _auth!.signInWithEmailAndPassword(
        email: email,
        password: password,
      );

      // Update last login time
      if (result.user != null) {
        await _firestoreService.updateUserLastLogin(result.user!.uid);
      }

      return _userFromFirebaseUser(result.user);
    } catch (e) {
      throw Exception('Giriş hatası: ${e.toString()}');
    }
  }

  // Register with email and password
  Future<AppUser?> registerWithEmailAndPassword(
    String email,
    String password,
  ) async {
    if (_auth == null) {
      throw Exception('Firebase bu platformda desteklenmiyor');
    }
    try {
      if (kDebugMode) {
        print('Kayıt işlemi başlıyor: $email');
      }
      UserCredential result = await _auth!.createUserWithEmailAndPassword(
        email: email,
        password: password,
      );
      if (kDebugMode) {
        print('Firebase Auth kayıt başarılı: ${result.user?.uid}');
      }

      // Create user object
      AppUser? appUser = _userFromFirebaseUser(result.user);

      // Save user profile to Firestore
      if (appUser != null) {
        if (kDebugMode) {
          print('Firestore\'a kullanıcı profili kaydediliyor...');
        }
        await _firestoreService.createUserProfile(appUser);
        if (kDebugMode) {
          print('Firestore profil kaydı tamamlandı');
        }
      }

      return appUser;
    } catch (e) {
      if (kDebugMode) {
        print('Kayıt hatası: $e');
      }
      throw Exception('Kayıt hatası: ${e.toString()}');
    }
  }

  // Sign out
  Future<void> signOut() async {
    if (_auth == null) return;

    try {
      await _auth!.signOut();
    } catch (e) {
      throw Exception('Çıkış hatası: ${e.toString()}');
    }
  }

  // Reset password
  Future<void> resetPassword(String email) async {
    if (_auth == null) {
      throw Exception('Firebase bu platformda desteklenmiyor');
    }

    try {
      await _auth!.sendPasswordResetEmail(email: email);
    } catch (e) {
      throw Exception('Şifre sıfırlama hatası: ${e.toString()}');
    }
  }

  // Check if user is signed in
  bool get isSignedIn => _auth?.currentUser != null;

  // Get current app user
  AppUser? get currentAppUser => _userFromFirebaseUser(_auth?.currentUser);
}

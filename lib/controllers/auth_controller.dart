import 'dart:async';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart';
import '../models/user_model.dart';
import '../services/auth_service.dart';

class AuthController extends ChangeNotifier {
  final AuthService _service = AuthService();
  StreamSubscription<User?>? _sub;
  bool _registering = false;

  User? firebaseUser; //Firebase Authentication.
  UserModel? currentUser; //Firestore
  bool initializing = true; // écran de démarrage
  bool isLoading = false; // pendant login/inscription
  String? error;

  AuthController() {
    _sub = _service.authStateChanges.listen(_onAuthChanged);
  }

  Future<void> _onAuthChanged(User? user) async {
    firebaseUser = user;

    // Pendant l'inscription, register() charge lui-même le profil
    if (_registering) return;

    if (user != null) {
      currentUser = await _service.getUser(user.uid);
      if (currentUser == null) {
        // compte Auth sans profil Firestore : on déconnecte
        await _service.signOut();
        return;
      }
    } else {
      currentUser = null;
    }
    initializing = false;
    notifyListeners();
  }

  Future<bool> login(String email, String password) async {
    _start();
    try {
      await _service.signIn(email.trim(), password);
      return _finish(true);
    } catch (e) {
      return _finish(false, AuthService.errorMessage(e));
    }
  }

  Future<bool> register(String name, String email, String password) async {
    _registering = true;
    _start();
    try {
      currentUser = await _service.signUp(
        name: name.trim(),
        email: email.trim(),
        password: password,
      );
      firebaseUser = FirebaseAuth.instance.currentUser;
      initializing = false;
      _registering = false;
      return _finish(true);
    } catch (e) {
      _registering = false;
      // si le compte Auth a été créé mais pas le profil, on annule la session
      try {
        await _service.signOut();
      } catch (_) {}
      return _finish(false, AuthService.errorMessage(e));
    }
  }

  Future<bool> resetPassword(String email) async {
    _start();
    try {
      await _service.resetPassword(email.trim());
      return _finish(true);
    } catch (e) {
      return _finish(false, AuthService.errorMessage(e));
    }
  }
    /// Recharge le profil (compteur de commandes, points de fidélité)
  Future<void> refreshProfile() async {
    final uid = firebaseUser?.uid;
    if (uid == null) return;
    try {
      final fresh = await _service.getUser(uid);
      if (fresh != null) {
        currentUser = fresh;
        notifyListeners();
      }
    } catch (_) {}
  }

  Future<void> logout() => _service.signOut();

  /// Renvoie null si OK, sinon le message d'erreur
  Future<String?> updateProfile({
    required String name,
    required String address,
    String? photoBase64,
  }) async {
    final uid = firebaseUser?.uid;
    if (uid == null) return 'Vous n\'êtes pas connecté.';
    try {
      final updated = await _service.updateProfile(
        uid: uid,
        name: name.trim(),
        address: address.trim(),
        photoBase64: photoBase64,
      );
      if (updated != null) currentUser = updated;
      notifyListeners();
      return null;
    } catch (e) {
      return AuthService.errorMessage(e);
    }
  }
  void _start() {
    isLoading = true;
    error = null;
    notifyListeners();
  }

  bool _finish(bool ok, [String? err]) {
    isLoading = false;
    error = err;
    notifyListeners();
    return ok;
  }

  @override
  void dispose() {
    _sub?.cancel();
    super.dispose();
  }
    Future<String?> resendVerification() async {
    try {
      await _service.sendVerificationEmail();
      return null;
    } catch (e) {
      return AuthService.errorMessage(e);
    }
  }

  Future<void> checkVerified() async {
    final ok = await _service.reloadAndCheckVerified();
    if (ok) {
      firebaseUser = FirebaseAuth.instance.currentUser;
      notifyListeners();
    }
  }
}
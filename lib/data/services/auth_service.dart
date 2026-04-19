import 'dart:async';

import 'package:firebase_auth/firebase_auth.dart';
import 'package:google_sign_in/google_sign_in.dart';

import '../models/auth_user.dart';
import 'firebase_bootstrap.dart';

class AuthService {
  AuthService({bool useFirebaseAuth = false, GoogleSignIn? googleSignIn})
    : _useFirebaseAuth = useFirebaseAuth,
      _googleSignIn = googleSignIn ?? GoogleSignIn.instance;

  final bool _useFirebaseAuth;
  final GoogleSignIn _googleSignIn;

  final StreamController<AuthUser?> _localAuthController =
      StreamController<AuthUser?>.broadcast();

  AuthUser? _localCurrentUser;
  Future<bool>? _firebaseAvailability;

  Stream<AuthUser?> authStateChanges() async* {
    final canUseFirebase = await _isFirebaseAvailable();
    if (canUseFirebase) {
      yield _mapFirebaseUser(FirebaseAuth.instance.currentUser);
      yield* FirebaseAuth.instance.authStateChanges().map(_mapFirebaseUser);
      return;
    }

    yield _localCurrentUser;
    yield* _localAuthController.stream;
  }

  Future<AuthUser?> signInWithGoogle() async {
    final canUseFirebase = await _isFirebaseAvailable();
    if (canUseFirebase) {
      await _googleSignIn.initialize();
      final googleAccount = await _googleSignIn.authenticate();
      final googleAuthentication = googleAccount.authentication;
      final credential = GoogleAuthProvider.credential(
        idToken: googleAuthentication.idToken,
      );

      final userCredential = await FirebaseAuth.instance.signInWithCredential(
        credential,
      );

      return _mapFirebaseUser(userCredential.user);
    }

    const localUser = AuthUser(
      uid: 'local_google_driver',
      email: 'driver@gasplit.local',
      displayName: 'Driver',
    );
    _localCurrentUser = localUser;
    _localAuthController.add(localUser);
    return localUser;
  }

  Future<AuthUser> signInWithEmailPassword({
    required String email,
    required String password,
  }) async {
    final normalizedEmail = email.trim().toLowerCase();
    final canUseFirebase = await _isFirebaseAvailable();

    if (canUseFirebase) {
      final userCredential = await FirebaseAuth.instance
          .signInWithEmailAndPassword(
            email: normalizedEmail,
            password: password,
          );
      final mapped = _mapFirebaseUser(userCredential.user);
      if (mapped == null) {
        throw Exception('Unable to sign in with email and password.');
      }
      return mapped;
    }

    final localUser = AuthUser(
      uid: 'local_email_${normalizedEmail.hashCode}',
      email: normalizedEmail,
      displayName: _displayNameFromEmail(normalizedEmail),
    );
    _localCurrentUser = localUser;
    _localAuthController.add(localUser);
    return localUser;
  }

  Future<AuthUser> createAccountWithEmailPassword({
    required String email,
    required String password,
  }) async {
    final normalizedEmail = email.trim().toLowerCase();
    final canUseFirebase = await _isFirebaseAvailable();

    if (canUseFirebase) {
      final userCredential = await FirebaseAuth.instance
          .createUserWithEmailAndPassword(
            email: normalizedEmail,
            password: password,
          );
      final mapped = _mapFirebaseUser(userCredential.user);
      if (mapped == null) {
        throw Exception('Unable to create account.');
      }
      return mapped;
    }

    final localUser = AuthUser(
      uid: 'local_created_${normalizedEmail.hashCode}',
      email: normalizedEmail,
      displayName: _displayNameFromEmail(normalizedEmail),
    );
    _localCurrentUser = localUser;
    _localAuthController.add(localUser);
    return localUser;
  }

  Future<void> signOut() async {
    final canUseFirebase = await _isFirebaseAvailable();
    if (canUseFirebase) {
      try {
        await _googleSignIn.signOut();
      } catch (_) {
        // Ignore non-critical Google session cleanup failures.
      }
      await FirebaseAuth.instance.signOut();
      return;
    }

    _localCurrentUser = null;
    _localAuthController.add(null);
  }

  void dispose() {
    _localAuthController.close();
  }

  Future<bool> _isFirebaseAvailable() {
    _firebaseAvailability ??= _resolveFirebaseAvailability();
    return _firebaseAvailability!;
  }

  Future<bool> _resolveFirebaseAvailability() async {
    if (!_useFirebaseAuth) {
      return false;
    }

    final initialized = await FirebaseBootstrap.ensureInitialized();
    if (!initialized) {
      return false;
    }

    return true;
  }

  AuthUser? _mapFirebaseUser(User? user) {
    if (user == null) {
      return null;
    }

    final email = user.email?.trim() ?? '';
    final displayName = user.displayName?.trim();

    return AuthUser(
      uid: user.uid,
      email: email,
      displayName: displayName != null && displayName.isNotEmpty
          ? displayName
          : _displayNameFromEmail(email),
    );
  }

  String _displayNameFromEmail(String email) {
    final atIndex = email.indexOf('@');
    if (atIndex <= 0) {
      return 'Driver';
    }
    final raw = email.substring(0, atIndex).replaceAll('.', ' ').trim();
    if (raw.isEmpty) {
      return 'Driver';
    }
    final normalized = raw[0].toUpperCase() + raw.substring(1);
    return normalized;
  }
}

import '../models/auth_user.dart';
import '../services/auth_service.dart';

class AuthRepository {
  AuthRepository({required AuthService authService})
    : _authService = authService;

  final AuthService _authService;

  Stream<AuthUser?> authStateChanges() {
    return _authService.authStateChanges();
  }

  Future<AuthUser?> signInWithGoogle() {
    return _authService.signInWithGoogle();
  }

  Future<AuthUser> signInWithEmailPassword({
    required String email,
    required String password,
  }) {
    return _authService.signInWithEmailPassword(
      email: email,
      password: password,
    );
  }

  Future<AuthUser> createAccountWithEmailPassword({
    required String email,
    required String password,
  }) {
    return _authService.createAccountWithEmailPassword(
      email: email,
      password: password,
    );
  }

  Future<void> signOut() {
    return _authService.signOut();
  }
}

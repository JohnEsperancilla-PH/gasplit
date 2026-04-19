import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../core/constants/backend_config.dart';
import '../data/models/auth_user.dart';
import '../data/repositories/auth_repository.dart';
import '../data/services/auth_service.dart';

final authServiceProvider = Provider<AuthService>((ref) {
  final service = AuthService(useFirebaseAuth: kUseFirebaseBackend);
  ref.onDispose(service.dispose);
  return service;
});

final authRepositoryProvider = Provider<AuthRepository>((ref) {
  return AuthRepository(authService: ref.read(authServiceProvider));
});

final authStateProvider = StreamProvider<AuthUser?>((ref) {
  return ref.watch(authRepositoryProvider).authStateChanges();
});

final authControllerProvider = Provider<AuthController>((ref) {
  return AuthController(ref.read(authRepositoryProvider));
});

class AuthController {
  AuthController(this._authRepository);

  final AuthRepository _authRepository;

  Future<AuthUser?> signInWithGoogle() {
    return _authRepository.signInWithGoogle();
  }

  Future<AuthUser> signInWithEmailPassword({
    required String email,
    required String password,
  }) {
    return _authRepository.signInWithEmailPassword(
      email: email,
      password: password,
    );
  }

  Future<AuthUser> createAccountWithEmailPassword({
    required String email,
    required String password,
  }) {
    return _authRepository.createAccountWithEmailPassword(
      email: email,
      password: password,
    );
  }

  Future<void> signOut() {
    return _authRepository.signOut();
  }
}

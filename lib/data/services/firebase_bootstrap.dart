import 'package:firebase_core/firebase_core.dart';

class FirebaseBootstrap {
  FirebaseBootstrap._();

  static Future<bool>? _initialization;

  static Future<bool> ensureInitialized() {
    _initialization ??= _initialize();
    return _initialization!;
  }

  static Future<bool> _initialize() async {
    try {
      if (Firebase.apps.isNotEmpty) {
        return true;
      }

      await Firebase.initializeApp();
      return true;
    } catch (_) {
      return false;
    }
  }
}

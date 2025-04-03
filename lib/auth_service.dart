// AuthService handles user authentication logic using Firebase Auth.
// It provides methods for logging in and registering users securely.

import 'package:firebase_auth/firebase_auth.dart';

class AuthService {
  final FirebaseAuth _auth = FirebaseAuth.instance;

  /// Logs in a user with the provided [email] and [password].
  /// Returns `true` if login is successful, otherwise `false`.
  Future<bool> loginUser(String email, String password) async {
    try {
      await _auth.signInWithEmailAndPassword(email: email, password: password);
      return true;
    } on FirebaseAuthException catch (e) {
      print('Login error: ${e.message}');
      return false;
    }
  }

  /// Registers a new user with [name], [email], and [password].
  /// Returns `true` if registration is successful, otherwise `false`.
  Future<bool> registerUser(String name, String email, String password) async {
    try {
      final UserCredential userCredential = await _auth.createUserWithEmailAndPassword(
        email: email,
        password: password,
      );

      return true;
    } on FirebaseAuthException catch (e) {
      print('Registration error: ${e.message}');
      return false;
    }
  }
}

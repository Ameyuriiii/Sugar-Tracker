import 'package:firebase_auth/firebase_auth.dart';

class AuthService {
  final FirebaseAuth _auth = FirebaseAuth.instance;

  Future<bool> loginUser(String email, String password) async {
    try {
      await _auth.signInWithEmailAndPassword(email: email, password: password);
      return true;
    } on FirebaseAuthException catch (e) {
      print('Login error: ${e.message}');
      return false;
    }
  }

  Future<bool> registerUser(String name, String email, String password) async {
    try {
      final UserCredential userCredential = await _auth.createUserWithEmailAndPassword(
        email: email,
        password: password,
      );

      // You can optionally save additional user information (e.g., name) to Firestore here
      // Example:
      // await FirebaseFirestore.instance.collection('users').doc(userCredential.user!.uid).set({
      //   'name': name,
      //   'email': email,
      // });

      return true;
    } on FirebaseAuthException catch (e) {
      print('Registration error: ${e.message}');
      return false;
    }
  }
}

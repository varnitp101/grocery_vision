import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_sign_in/google_sign_in.dart';

final authStateProvider = StreamProvider<User?>((ref) {
  return FirebaseAuth.instance.authStateChanges();
});

final authControllerProvider = Provider<AuthController>((ref) {
  return AuthController();
});

class AuthController {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final GoogleSignIn _googleSignIn = GoogleSignIn.instance;
  bool _isGoogleSignInInitialized = false;

  Future<UserCredential?> signInWithGoogle() async {
    try {
      if (!_isGoogleSignInInitialized) {
        await _googleSignIn.initialize();
        _isGoogleSignInInitialized = true;
      }

      final googleUser = await _googleSignIn.authenticate();
      final googleAuth = googleUser.authentication;

      final authZ = await googleUser.authorizationClient.authorizeScopes(['email', 'profile']);

      final AuthCredential credential = GoogleAuthProvider.credential(
        accessToken: authZ.accessToken,
        idToken: googleAuth.idToken,
      );

      return await _auth.signInWithCredential(credential);
    } catch (e) {
      rethrow;
    }
  }

  Future<UserCredential> signInWithEmail(String email, String password) async {
    return await _auth.signInWithEmailAndPassword(email: email, password: password);
  }

  Future<UserCredential> signUpWithEmail(String email, String password) async {
    return await _auth.createUserWithEmailAndPassword(email: email, password: password);
  }

  Future<void> signOut() async {
    await _googleSignIn.signOut();
    await _auth.signOut();
  }
}

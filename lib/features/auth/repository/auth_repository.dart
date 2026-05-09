import 'package:firebase_auth/firebase_auth.dart';
import 'package:google_sign_in/google_sign_in.dart';

class AuthRepository {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final GoogleSignIn _googleSignIn = GoogleSignIn.instance;

  Stream<User?> get authStateChanges => _auth.authStateChanges();
  User? get currentUser => _auth.currentUser;

  Future<UserCredential> signInWithEmail(String email, String password) async {
    return await _auth.signInWithEmailAndPassword(
      email: email.trim(),
      password: password.trim(),
    );
  }

  Future<UserCredential> signUpWithEmail(
      String email, String password, String name) async {
    final cred = await _auth.createUserWithEmailAndPassword(
      email: email.trim(),
      password: password.trim(),
    );
    await cred.user?.updateDisplayName(name.trim());
    return cred;
  }

  bool _isGoogleAuthInitialized = false;

  Future<UserCredential> signInWithGoogle() async {
    try {
      if (!_isGoogleAuthInitialized) {
        await _googleSignIn.initialize();
        _isGoogleAuthInitialized = true;
      }
      final googleUser = await _googleSignIn.authenticate();
      final authentication = googleUser.authentication;
      final authz = await googleUser.authorizationClient.authorizationForScopes(['email']);
      
      final credential = GoogleAuthProvider.credential(
        accessToken: authz?.accessToken,
        idToken: authentication.idToken,
      );
      return await _auth.signInWithCredential(credential);
    } catch (e) {
      throw Exception('Google sign-in failed: $e');
    }
  }

  Future<void> signOut() async {
    await Future.wait([_auth.signOut(), _googleSignIn.signOut()]);
  }
}
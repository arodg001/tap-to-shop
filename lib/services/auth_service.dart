import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

// Provider defined in auth_wrapper.dart is reused here
// You might move firebaseAuthProvider here if preferred for organization
import 'package:shopapp/core/widgets/auth_wrapper.dart';

// Service class for Firebase Authentication
class AuthService {
  final FirebaseAuth _firebaseAuth;

  AuthService(this._firebaseAuth);

  // Sign in with email and password
  Future<UserCredential> signInWithEmailAndPassword(
      String email, String password) async {
    try {
      return await _firebaseAuth.signInWithEmailAndPassword(
        email: email,
        password: password,
      );
    } on FirebaseAuthException catch (e) {
      // Handle specific Firebase Auth errors
      print('Firebase Auth Error (Sign In): ${e.code} - ${e.message}');
      throw Exception('Failed to sign in: ${e.message}'); // Re-throw generic for UI
    } catch (e) {
      print('Generic Error (Sign In): $e');
      throw Exception('An unexpected error occurred during sign in.');
    }
  }

  // Register with email and password
  Future<UserCredential> createUserWithEmailAndPassword(
      String email, String password) async {
    try {
      return await _firebaseAuth.createUserWithEmailAndPassword(
        email: email,
        password: password,
      );
      // Optionally: Send verification email, create user profile in Firestore
    } on FirebaseAuthException catch (e) {
      print('Firebase Auth Error (Register): ${e.code} - ${e.message}');
      throw Exception('Failed to register: ${e.message}');
    } catch (e) {
      print('Generic Error (Register): $e');
      throw Exception('An unexpected error occurred during registration.');
    }
  }

  // Sign out
  Future<void> signOut() async {
    try {
      await _firebaseAuth.signOut();
    } catch (e) {
       print('Generic Error (Sign Out): $e');
      throw Exception('An unexpected error occurred during sign out.');
    }
  }

  // Get current user (can be null)
  User? getCurrentUser() {
    return _firebaseAuth.currentUser;
  }
}

// Provider for AuthService
final authServiceProvider = Provider<AuthService>((ref) {
  // Watch the firebaseAuthProvider (defined in AuthWrapper)
  final firebaseAuth = ref.watch(firebaseAuthProvider);
  return AuthService(firebaseAuth);
}); 
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:sign_in_with_apple/sign_in_with_apple.dart';
import 'dart:io'; // For Platform check

import 'package:shopapp/core/widgets/auth_wrapper.dart';

// Service class for Firebase Authentication
class AuthService {
  final FirebaseAuth _firebaseAuth;
  // Add GoogleSignIn instance
  final GoogleSignIn _googleSignIn = GoogleSignIn();

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
      print('Firebase Auth Error (Sign In): ${e.code} - ${e.message}');
      throw Exception('Failed to sign in: ${e.message}');
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
    } on FirebaseAuthException catch (e) {
      print('Firebase Auth Error (Register): ${e.code} - ${e.message}');
      throw Exception('Failed to register: ${e.message}');
    } catch (e) {
      print('Generic Error (Register): $e');
      throw Exception('An unexpected error occurred during registration.');
    }
  }

  // Sign in with Google
  Future<UserCredential> signInWithGoogle() async {
    try {
      // Trigger the Google authentication flow
      final GoogleSignInAccount? googleUser = await _googleSignIn.signIn();

      if (googleUser == null) {
        // User cancelled the flow
        throw Exception('Google sign in cancelled.');
      }

      // Obtain the auth details from the request
      final GoogleSignInAuthentication googleAuth = await googleUser.authentication;

      // Create a new Firebase credential
      final AuthCredential credential = GoogleAuthProvider.credential(
        accessToken: googleAuth.accessToken,
        idToken: googleAuth.idToken,
      );

      // Sign in to Firebase with the credential
      return await _firebaseAuth.signInWithCredential(credential);
    } on FirebaseAuthException catch (e) {
       print('Firebase Auth Error (Google Sign In): ${e.code} - ${e.message}');
       throw Exception('Google Sign-In failed: ${e.message}');
    } catch (e) {
       print('Generic Error (Google Sign In): $e');
       throw Exception('An unexpected error occurred during Google Sign-In.');
    }
  }

  // Sign in with Apple
  Future<UserCredential> signInWithApple() async {
     if (!Platform.isIOS && !Platform.isMacOS) {
         throw UnsupportedError('Sign in with Apple is only supported on iOS and macOS.');
     }

    try {
        final AuthorizationCredentialAppleID appleCredential = await SignInWithApple.getAppleIDCredential(
            scopes: [
                AppleIDAuthorizationScopes.email,
                AppleIDAuthorizationScopes.fullName,
            ],
            // Optional: Use if you have a web service component for validation
            // webAuthenticationOptions: WebAuthenticationOptions(
            //     clientId: 'YOUR_SERVICE_ID', // e.g., com.example.app
            //     redirectUri: Uri.parse('YOUR_REDIRECT_URI'),
            // ),
            // Optional: Add nonce for replay protection
            // nonce: 'your_nonce_string',
            // state: 'your_state_string',
        );

        final OAuthCredential credential = OAuthProvider("apple.com").credential(
            idToken: appleCredential.identityToken,
            accessToken: appleCredential.authorizationCode, // May not always be needed/present
            // Use the nonce if you generated one
            // rawNonce: 'your_nonce_string',
        );

        // Sign in to Firebase
        final userCredential = await _firebaseAuth.signInWithCredential(credential);

        // Note: Apple only provides name details on the *first* sign-in.
        // You might want to update the user's profile name here if it's the first time.
        // if (userCredential.additionalUserInfo?.isNewUser ?? false) {
        //   String? name = "${appleCredential.givenName ?? ''} ${appleCredential.familyName ?? ''}".trim();
        //   if (name.isNotEmpty && userCredential.user != null) {
        //      await userCredential.user!.updateDisplayName(name);
        //      // Consider updating your Firestore record too
        //   }
        // }

        return userCredential;

    } on FirebaseAuthException catch (e) {
      print('Firebase Auth Error (Apple Sign In): ${e.code} - ${e.message}');
      throw Exception('Apple Sign-In failed: ${e.message}');
    } catch (e) {
      print('Generic Error (Apple Sign In): $e');
      // Handle specific errors from SignInWithApple, e.g., cancelled
      if (e is SignInWithAppleAuthorizationException && e.code == AuthorizationErrorCode.canceled) {
          throw Exception('Apple sign in cancelled.');
      }
      throw Exception('An unexpected error occurred during Apple Sign-In.');
    }
  }

  // Sign out
  Future<void> signOut() async {
    try {
      // Also sign out from Google if needed
      await _googleSignIn.signOut();
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
  final firebaseAuth = ref.watch(firebaseAuthProvider);
  return AuthService(firebaseAuth);
});
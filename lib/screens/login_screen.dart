import 'dart:io'; // For Platform check
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shopapp/models/user_model.dart';
import 'package:shopapp/services/auth_service.dart';
import 'package:shopapp/services/database_service.dart'; // Import DatabaseService

// State provider to manage loading state
final _loadingProvider = StateProvider<bool>((ref) => false);

class LoginScreen extends ConsumerStatefulWidget {
  const LoginScreen({super.key});
  static const String routeName = '/login';

  @override
  ConsumerState<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends ConsumerState<LoginScreen> {
  final _formKey = GlobalKey<FormState>();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  bool _isLogin = true; // Toggle between Login and Register

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  // Helper to show snackbar errors
  void _showError(String message) {
      if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(content: Text(message), backgroundColor: Colors.red),
          );
      }
  }

  // Helper to create/update user record after any sign-in method
  Future<void> _upsertUserAfterSignIn(UserCredential userCredential) async {
      final dbService = ref.read(databaseServiceProvider);
      if (userCredential.user != null) {
          final user = userCredential.user!;
          final newUser = UserModel(
              userId: user.uid,
              email: user.email ?? 'no-email@example.com', // Provide default if email is null
              name: user.displayName,
              createdAt: user.metadata.creationTime ?? DateTime.now(),
          );
          try {
            await dbService.upsertUserRecord(newUser);
          } catch (dbError) {
             // Log DB error but don't block login
             print('Error saving user record after sign-in: $dbError');
              _showError('Could not save user data, but login successful.');
          }
      }
  }

  // --- Submit Methods ---
  Future<void> _submitEmailPasswordForm() async {
    if (!(_formKey.currentState?.validate() ?? false)) return;
    ref.read(_loadingProvider.notifier).state = true;
    final email = _emailController.text.trim();
    final password = _passwordController.text.trim();
    final authService = ref.read(authServiceProvider);

    try {
      UserCredential userCredential;
      if (_isLogin) {
        userCredential = await authService.signInWithEmailAndPassword(email, password);
        print('Email Login successful: ${userCredential.user?.uid}');
        // Don't upsert user record on standard login, only on registration/OAuth
      } else {
        userCredential = await authService.createUserWithEmailAndPassword(email, password);
        print('Email Registration successful: ${userCredential.user?.uid}');
        await _upsertUserAfterSignIn(userCredential);
      }
    } catch (e) {
      _showError(e.toString());
    } finally {
      if (mounted) {
        ref.read(_loadingProvider.notifier).state = false;
      }
    }
  }

  Future<void> _submitGoogleSignIn() async {
      ref.read(_loadingProvider.notifier).state = true;
      final authService = ref.read(authServiceProvider);
      try {
         final userCredential = await authService.signInWithGoogle();
         print('Google Sign-In successful: ${userCredential.user?.uid}');
         await _upsertUserAfterSignIn(userCredential);
      } catch (e) {
         _showError(e.toString());
      } finally {
         if (mounted) {
            ref.read(_loadingProvider.notifier).state = false;
         }
      }
  }

   Future<void> _submitAppleSignIn() async {
      ref.read(_loadingProvider.notifier).state = true;
      final authService = ref.read(authServiceProvider);
      try {
         final userCredential = await authService.signInWithApple();
         print('Apple Sign-In successful: ${userCredential.user?.uid}');
         await _upsertUserAfterSignIn(userCredential);
      } catch (e) {
         _showError(e.toString());
      } finally {
         if (mounted) {
            ref.read(_loadingProvider.notifier).state = false;
         }
      }
  }

  @override
  Widget build(BuildContext context) {
    final isLoading = ref.watch(_loadingProvider);

    return Scaffold(
      appBar: AppBar(title: Text(_isLogin ? 'Login' : 'Register')),
      body: Center(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(16.0),
          child: Form(
            key: _formKey,
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                TextFormField(
                  controller: _emailController,
                  enabled: !isLoading,
                  decoration: const InputDecoration(labelText: 'Email'),
                  keyboardType: TextInputType.emailAddress,
                  validator: (value) {
                    if (value == null || value.trim().isEmpty || !value.contains('@')) {
                      return 'Please enter a valid email address.';
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 12),
                TextFormField(
                  controller: _passwordController,
                  enabled: !isLoading,
                  decoration: const InputDecoration(labelText: 'Password'),
                  obscureText: true,
                  validator: (value) {
                    if (value == null || value.trim().length < 6) {
                      return 'Password must be at least 6 characters long.';
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 20),
                if (isLoading)
                  const CircularProgressIndicator()
                else
                  ElevatedButton(
                    onPressed: _submitEmailPasswordForm,
                    child: Text(_isLogin ? 'Login' : 'Register'),
                  ),
                const SizedBox(height: 12),
                TextButton(
                  onPressed: isLoading ? null : () {
                    setState(() {
                      _isLogin = !_isLogin;
                    });
                  },
                  child: Text(
                      _isLogin ? 'Create an account' : 'I already have an account'),
                ),
                const SizedBox(height: 20),
                const Divider(),
                const SizedBox(height: 10),
                if (!isLoading)
                    ElevatedButton.icon(
                        icon: const Icon(Icons.g_mobiledata),
                        label: const Text('Sign in with Google'),
                        onPressed: _submitGoogleSignIn,
                        style: ElevatedButton.styleFrom(backgroundColor: Colors.white, foregroundColor: Colors.black),
                    ),
                const SizedBox(height: 10),
                if (!isLoading && (Platform.isIOS || Platform.isMacOS))
                    ElevatedButton.icon(
                        icon: const Icon(Icons.apple),
                        label: const Text('Sign in with Apple'),
                        onPressed: _submitAppleSignIn,
                         style: ElevatedButton.styleFrom(backgroundColor: Colors.black, foregroundColor: Colors.white),
                    ),
              ],
            ),
          ),
        ),
      ),
    );
  }
} 
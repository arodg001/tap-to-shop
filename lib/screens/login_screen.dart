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

  Future<void> _submitForm() async {
    if (_formKey.currentState!.validate()) {
      ref.read(_loadingProvider.notifier).state = true;
      final email = _emailController.text.trim();
      final password = _passwordController.text.trim();
      final authService = ref.read(authServiceProvider);
      final dbService = ref.read(databaseServiceProvider); // Get DatabaseService

      try {
        UserCredential userCredential;
        if (_isLogin) {
          userCredential = await authService.signInWithEmailAndPassword(email, password);
          print('Login successful: ${userCredential.user?.uid}');
        } else {
          userCredential = await authService.createUserWithEmailAndPassword(email, password);
          print('Registration successful: ${userCredential.user?.uid}');
          // Create user record in Firestore after registration
          if (userCredential.user != null) {
             final newUser = UserModel(
                userId: userCredential.user!.uid,
                email: userCredential.user!.email!,
                createdAt: DateTime.now(),
                // name: userCredential.user?.displayName, // Name might not be available immediately
             );
             await dbService.upsertUserRecord(newUser);
          }
        }
        // Navigation to HomeScreen is handled by AuthWrapper listening to auth state changes
      } catch (e) {
        // Show error message
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text(e.toString())),
          );
        }
      } finally {
         // Check mounted again before updating state
        if (mounted) {
            ref.read(_loadingProvider.notifier).state = false;
        }
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
                    onPressed: _submitForm,
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
                // TODO: Add buttons for Google/Apple OAuth
              ],
            ),
          ),
        ),
      ),
    );
  }
} 
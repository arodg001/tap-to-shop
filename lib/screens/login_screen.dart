import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

// TODO: Implement Firebase Auth Login

class LoginScreen extends ConsumerWidget {
  const LoginScreen({super.key});

  static const String routeName = '/login';

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Scaffold(
      appBar: AppBar(title: const Text('Login')),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Text('Login Screen Placeholder'),
            const SizedBox(height: 20),
            ElevatedButton(
              // TODO: Replace with actual login logic
              onPressed: () {
                // Simulate login - navigate to home
                 Navigator.pushReplacementNamed(context, '/home'); // Placeholder
              },
              child: const Text('Simulate Login'),
            ),
             const SizedBox(height: 20),
             ElevatedButton(
              // TODO: Add registration navigation/logic
              onPressed: () {
                 // TODO: Navigate to registration screen or show dialog
                 ScaffoldMessenger.of(context).showSnackBar(
                   const SnackBar(content: Text('Registration TBD')),
                 );
              },
              child: const Text('Register'),
            ),
          ],
        ),
      ),
    );
  }
} 
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shopapp/features/capture/screens/capture_screen.dart'; // Import CaptureScreen
import 'package:shopapp/screens/profile_screen.dart'; // Import ProfileScreen
import 'package:shopapp/services/auth_service.dart'; // Import AuthService

// TODO: Add Firebase Auth Logout
// TODO: Import ProfileScreen

class HomeScreen extends ConsumerWidget {
  const HomeScreen({super.key});

  static const String routeName = '/home';

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Tap-to-Shop Home'),
        actions: [
          IconButton(
            icon: const Icon(Icons.person),
            tooltip: 'Profile',
            onPressed: () {
              Navigator.pushNamed(context, ProfileScreen.routeName); // Use named route
            },
          ),
          IconButton(
            icon: const Icon(Icons.logout),
            tooltip: 'Logout',
            onPressed: () async {
              try {
                await ref.read(authServiceProvider).signOut();
                // Navigation back to LoginScreen is handled by AuthWrapper
              } catch (e) {
                 if (context.mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(content: Text('Logout failed: ${e.toString()}')),
                    );
                 }
              }
            },
          ),
        ],
      ),
      body: Center(
        child: Column(
           mainAxisAlignment: MainAxisAlignment.center,
           children: [
              const Text('Home Screen - History TBD'),
              const SizedBox(height: 30),
              ElevatedButton.icon(
                icon: const Icon(Icons.camera_alt),
                label: const Text('Tap to Capture'),
                onPressed: () {
                   Navigator.pushNamed(context, CaptureScreen.routeName); // Use named route
                },
                style: ElevatedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(horizontal: 30, vertical: 15),
                  textStyle: const TextStyle(fontSize: 18)
                ),
              ),
           ],
        ),
      ),
    );
  }
} 
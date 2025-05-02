import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shopapp/features/capture/screens/capture_screen.dart'; // Import CaptureScreen
import 'package:shopapp/screens/profile_screen.dart'; // Import ProfileScreen
import 'package:shopapp/screens/results_screen.dart'; // Import ResultsScreen
import 'package:shopapp/services/auth_service.dart'; // Import AuthService
import 'package:shopapp/services/database_service.dart'; // Import DatabaseService
import 'package:shopapp/models/capture_session_model.dart'; // Import CaptureSessionModel
import 'package:intl/intl.dart'; // For date formatting

// TODO: Add Firebase Auth Logout
// TODO: Import ProfileScreen

// Provider to fetch session history for the current user
final sessionHistoryProvider = StreamProvider<List<CaptureSessionModel>>((ref) {
  final authService = ref.watch(authServiceProvider);
  final dbService = ref.watch(databaseServiceProvider);
  final user = authService.getCurrentUser();

  if (user != null) {
    return dbService.getUserSessionHistory(user.uid);
  } else {
    return Stream.value([]); // Return empty stream if not logged in
  }
});

class HomeScreen extends ConsumerWidget {
  const HomeScreen({super.key});

  static const String routeName = '/home';

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final sessionHistory = ref.watch(sessionHistoryProvider);

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
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: ElevatedButton.icon(
              icon: const Icon(Icons.camera_alt),
              label: const Text('Tap to Capture'),
              onPressed: () {
                Navigator.pushNamed(context, CaptureScreen.routeName); // Use named route
              },
              style: ElevatedButton.styleFrom(
                padding: const EdgeInsets.symmetric(horizontal: 30, vertical: 15),
                textStyle: const TextStyle(fontSize: 18),
                minimumSize: const Size(double.infinity, 50), // Make button wider
              ),
            ),
          ),
          const Divider(),
          const Padding(
            padding: EdgeInsets.symmetric(vertical: 8.0),
            child: Text('Capture History', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
          ),
          Expanded(
            child: sessionHistory.when(
              data: (sessions) {
                if (sessions.isEmpty) {
                  return const Center(child: Text('No capture history yet.'));
                }
                return ListView.builder(
                  itemCount: sessions.length,
                  itemBuilder: (context, index) {
                    final session = sessions[index];
                    return ListTile(
                      // TODO: Replace leading with image thumbnail if available
                      leading: const Icon(Icons.image_search),
                      title: Text('Session ${session.sessionId.substring(0, 8)}...'), // Show partial ID
                      subtitle: Text(DateFormat.yMd().add_jm().format(session.timestamp)), // Format timestamp
                      onTap: () {
                        Navigator.pushNamed(
                          context,
                          ResultsScreen.routeName,
                          arguments: session.sessionId,
                        );
                      },
                    );
                  },
                );
              },
              loading: () => const Center(child: CircularProgressIndicator()),
              error: (error, stack) => Center(child: Text('Error loading history: $error')),
            ),
          ),
        ],
      ),
    );
  }
} 
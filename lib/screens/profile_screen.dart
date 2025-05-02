import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

// TODO: Implement Profile fetching/updating

class ProfileScreen extends ConsumerWidget {
  const ProfileScreen({super.key});

  static const String routeName = '/profile';

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Scaffold(
      appBar: AppBar(title: const Text('Profile & Settings')),
      body: const Center(
        child: Text('Profile Screen Placeholder'),
        // TODO: Display UserProfileModel data
        // TODO: Add controls to update preferences
      ),
    );
  }
} 
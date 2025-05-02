import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shopapp/models/user_profile_model.dart';
import 'package:shopapp/services/auth_service.dart';
import 'package:shopapp/services/database_service.dart';

// Provider to fetch the current user's profile
final userProfileProvider = FutureProvider<UserProfileModel?>((ref) async {
  final authService = ref.watch(authServiceProvider);
  final dbService = ref.watch(databaseServiceProvider);
  final user = authService.getCurrentUser();

  if (user != null) {
    final profile = await dbService.getUserProfile(user.uid);
    // If profile doesn't exist, create a default one (optional)
    return profile ?? UserProfileModel(userId: user.uid);
  } else {
    return null; // No user logged in
  }
});

// StateNotifier provider to manage the editable profile state
final editableProfileProvider = StateNotifierProvider<EditableProfileNotifier, AsyncValue<UserProfileModel?>>((ref) {
     final initialProfile = ref.watch(userProfileProvider);
     return EditableProfileNotifier(ref, initialProfile);
});

class EditableProfileNotifier extends StateNotifier<AsyncValue<UserProfileModel?>> {
  final Ref _ref;
  EditableProfileNotifier(this._ref, AsyncValue<UserProfileModel?> initialState)
      : super(initialState);

  // Update local state (does not save to DB yet)
  void updateProfileData(UserProfileModel updatedProfile) {
     state = AsyncData(updatedProfile);
  }

  // Save the current state to Firestore
  Future<void> saveProfile() async {
     final profileToSave = state.value;
     if (profileToSave == null) return; // Cannot save if null

     final dbService = _ref.read(databaseServiceProvider);
     final currentAsyncState = state;

     state = const AsyncLoading(); // Set loading state before saving
     try {
       await dbService.updateUserProfile(profileToSave);
       state = AsyncData(profileToSave); // Update state with saved data
       print('Profile saved successfully!');
     } catch (e, stackTrace) {
       print('Error saving profile: $e');
       // Revert to previous state on error or keep loading with error message?
       state = AsyncError(e, stackTrace).copyWithPrevious(currentAsyncState);
       throw Exception('Failed to save profile'); // Re-throw for UI handling
     }
  }
}

class ProfileScreen extends ConsumerWidget {
  const ProfileScreen({super.key});
  static const String routeName = '/profile';

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final profileState = ref.watch(editableProfileProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Profile & Settings'),
        actions: [
           profileState.maybeWhen(
             data: (profile) => IconButton(
                icon: const Icon(Icons.save),
                tooltip: 'Save Profile',
                onPressed: () async {
                    try {
                      await ref.read(editableProfileProvider.notifier).saveProfile();
                       if (context.mounted) {
                         ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(content: Text('Profile Saved!')),
                         );
                       }
                    } catch (e) {
                       if (context.mounted) {
                         ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(content: Text('Error saving: ${e.toString()}')),
                         );
                       }
                    }
                }
             ),
             loading: () => const Padding(
                 padding: EdgeInsets.all(8.0),
                 child: SizedBox(width: 24, height: 24, child: CircularProgressIndicator(strokeWidth: 2))),
             orElse: () => const SizedBox.shrink(),
          ),
        ]
      ),
      body: profileState.when(
        data: (profile) {
          if (profile == null) {
            return const Center(child: Text('User not logged in or profile not found.'));
          }
          // Build form with current profile data
          return _buildProfileForm(context, ref, profile);
        },
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (error, stack) => Center(
            child: Padding(
              padding: const EdgeInsets.all(16.0),
              child: Text('Error loading profile: $error')
            )),
      ),
    );
  }

  Widget _buildProfileForm(BuildContext context, WidgetRef ref, UserProfileModel currentProfile) {
    // Create local controllers or state based on currentProfile if needed for complex edits
    // For simple dropdowns/selections, directly use currentProfile and update via notifier

    return ListView(
        padding: const EdgeInsets.all(16.0),
        children: [
          // --- Persona Selection --- 
           Text('Shopping Persona', style: Theme.of(context).textTheme.titleMedium),
           DropdownButton<ShoppingPersona?>(
             value: currentProfile.persona,
             isExpanded: true,
             hint: const Text('Select your primary shopping focus'),
             items: ShoppingPersona.values.map((persona) {
               return DropdownMenuItem(
                 value: persona,
                 child: Text(persona.name), // Simple display name
               );
             }).toList(),
             onChanged: (ShoppingPersona? newValue) {
                 ref.read(editableProfileProvider.notifier)
                    .updateProfileData(currentProfile.copyWith(persona: newValue));
             },
           ),
           const SizedBox(height: 20),

           // --- Streaming Platform Selection --- 
           Text('Favorite Streaming Platform', style: Theme.of(context).textTheme.titleMedium),
           DropdownButton<StreamingPlatform?>(
             value: currentProfile.platform,
             isExpanded: true,
             hint: const Text('Select your go-to streaming service'),
             items: StreamingPlatform.values.map((platform) {
               return DropdownMenuItem(
                 value: platform,
                 child: Text(platform.name), // Simple display name
               );
             }).toList(),
             onChanged: (StreamingPlatform? newValue) {
                ref.read(editableProfileProvider.notifier)
                    .updateProfileData(currentProfile.copyWith(platform: newValue));
             },
           ),
           const SizedBox(height: 20),

            // --- Favorite Retailers (Example using simple text display) ---
           Text('Favorite Retailers', style: Theme.of(context).textTheme.titleMedium),
           // TODO: Implement a proper multi-select widget (e.g., chips, dialog)
           Text(currentProfile.favoriteRetailers.isEmpty
               ? 'No favorite retailers selected.'
               : currentProfile.favoriteRetailers.join(', ')
           ),
           ElevatedButton(onPressed: () {
               // TODO: Show dialog or navigate to multi-select screen
               ScaffoldMessenger.of(context).showSnackBar(
                 const SnackBar(content: Text('Retailer selection TBD')),
               );
           }, child: const Text('Edit Retailers')),
        ],
     );
  }
} 
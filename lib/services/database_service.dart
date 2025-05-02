import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shopapp/models/capture_session_model.dart';
import 'package:shopapp/models/user_model.dart';
import 'package:shopapp/models/user_profile_model.dart';

// Service class for Firestore interactions
class DatabaseService {
  final FirebaseFirestore _db;

  DatabaseService(this._db);

  // === User ===
  CollectionReference<UserModel> get usersCollection =>
      _db.collection('users').withConverter<UserModel>(
            fromFirestore: (snapshot, _) => UserModel.fromJson(snapshot.data()!),
            toFirestore: (user, _) => user.toJson(),
          );

  // Create or update user record
  Future<void> upsertUserRecord(UserModel user) async {
    try {
      // Use set with merge: true to create or update
      await usersCollection.doc(user.userId).set(user, SetOptions(merge: true));
      print('User record created/updated for ${user.userId}');
    } catch (e) {
       print('Error upserting user record: $e');
       // Consider how to handle this error (e.g., logging)
       // It might not be critical to block the user if this fails
       throw Exception('Failed to save user data.');
    }
  }

  // === Profile ===
   CollectionReference<UserProfileModel> get profilesCollection =>
      _db.collection('profiles').withConverter<UserProfileModel>(
            fromFirestore: (snapshot, _) => UserProfileModel.fromJson(snapshot.data()!),
            toFirestore: (profile, _) => profile.toJson(),
          );

  // Get user profile
  Future<UserProfileModel?> getUserProfile(String userId) async {
     try {
      final doc = await profilesCollection.doc(userId).get();
      return doc.data(); // Returns null if document doesn't exist
    } catch (e) {
      print('Error getting user profile for $userId: $e');
      return null; // Or rethrow
    }
  }

  // Update user profile
  Future<void> updateUserProfile(UserProfileModel profile) async {
     try {
       await profilesCollection.doc(profile.userId).set(profile, SetOptions(merge: true));
       print('Profile updated for ${profile.userId}');
    } catch (e) {
      print('Error updating user profile for ${profile.userId}: $e');
      throw Exception('Failed to update profile.');
    }
  }

  // === Sessions ===
  CollectionReference<CaptureSessionModel> get sessionsCollection =>
      _db.collection('sessions').withConverter<CaptureSessionModel>(
            fromFirestore: (snapshot, _) => CaptureSessionModel.fromJson(snapshot.data()!),
            toFirestore: (session, _) => session.toJson(),
          );

  // Get session history for a user, ordered by timestamp descending
  Stream<List<CaptureSessionModel>> getUserSessionHistory(String userId) {
     return sessionsCollection
         .where('userId', isEqualTo: userId)
         .orderBy('timestamp', descending: true)
         .limit(20) // Limit results for performance
         .snapshots()
         .map((snapshot) => snapshot.docs.map((doc) => doc.data()).toList())
         .handleError((error) {
            print('Error fetching session history for $userId: $error');
            return []; // Return empty list on error
          });
  }

  // TODO: Add method to fetch combined results (MatchResult + AffiliateLink) for a session
}

// Provider for FirebaseFirestore instance
final firestoreProvider = Provider<FirebaseFirestore>((ref) => FirebaseFirestore.instance);

// Provider for DatabaseService
final databaseServiceProvider = Provider<DatabaseService>((ref) {
  final firestore = ref.watch(firestoreProvider);
  return DatabaseService(firestore);
}); 
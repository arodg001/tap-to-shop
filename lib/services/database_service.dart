import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shopapp/models/user_model.dart';

// Service class for Firestore interactions
class DatabaseService {
  final FirebaseFirestore _db;

  DatabaseService(this._db);

  // Get reference to the users collection
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

  // TODO: Add methods for profile operations (get/update UserProfileModel)
  // TODO: Add methods for session history, results, etc.
}

// Provider for FirebaseFirestore instance
final firestoreProvider = Provider<FirebaseFirestore>((ref) => FirebaseFirestore.instance);

// Provider for DatabaseService
final databaseServiceProvider = Provider<DatabaseService>((ref) {
  final firestore = ref.watch(firestoreProvider);
  return DatabaseService(firestore);
}); 
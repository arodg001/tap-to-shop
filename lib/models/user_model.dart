import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart';

@immutable
class UserModel {
  final String userId;
  final String email;
  final String? name; // Optional based on auth provider
  final DateTime createdAt;

  const UserModel({
    required this.userId,
    required this.email,
    this.name,
    required this.createdAt,
  });

  // Factory constructor for creating a new UserModel instance from a map
  factory UserModel.fromJson(Map<String, dynamic> json) {
    return UserModel(
      userId: json['userId'] as String,
      email: json['email'] as String,
      name: json['name'] as String?,
      createdAt: (json['createdAt'] as Timestamp).toDate(),
    );
  }

  // Method for converting a UserModel instance to a map
  Map<String, dynamic> toJson() {
    return {
      'userId': userId,
      'email': email,
      'name': name,
      'createdAt': Timestamp.fromDate(createdAt),
    };
  }

  // CopyWith method for immutability
  UserModel copyWith({
    String? userId,
    String? email,
    String? name,
    DateTime? createdAt,
  }) {
    return UserModel(
      userId: userId ?? this.userId,
      email: email ?? this.email,
      name: name ?? this.name,
      createdAt: createdAt ?? this.createdAt,
    );
  }

  @override
  String toString() {
    return 'UserModel(userId: $userId, email: $email, name: $name, createdAt: $createdAt)';
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;

    return other is UserModel &&
        other.userId == userId &&
        other.email == email &&
        other.name == name &&
        other.createdAt == createdAt;
  }

  @override
  int get hashCode {
    return userId.hashCode ^ email.hashCode ^ name.hashCode ^ createdAt.hashCode;
  }
} 
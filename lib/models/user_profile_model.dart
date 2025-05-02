import 'package:flutter/foundation.dart';

// Define enums for categorical data
enum StreamingPlatform {
  netflix, hulu, disneyPlus, amazonPrime, hboMax, appleTv, other
}

enum ShoppingPersona {
  self, significantOther, child, friend, other
}

@immutable
class UserProfileModel {
  final String userId; // Foreign Key to UserModel
  final StreamingPlatform? platform; // Favorite streaming platform
  final ShoppingPersona? persona;
  final List<String> favoriteRetailers; // List of retailer names or IDs

  const UserProfileModel({
    required this.userId,
    this.platform,
    this.persona,
    this.favoriteRetailers = const [], // Default to empty list
  });

  // Factory constructor for creating a new UserProfileModel instance from a map
  factory UserProfileModel.fromJson(Map<String, dynamic> json) {
    return UserProfileModel(
      userId: json['userId'] as String,
      platform: json['platform'] != null
          ? StreamingPlatform.values.byName(json['platform'] as String)
          : null,
      persona: json['persona'] != null
          ? ShoppingPersona.values.byName(json['persona'] as String)
          : null,
      favoriteRetailers:
          List<String>.from(json['favoriteRetailers'] as List? ?? []),
    );
  }

  // Method for converting a UserProfileModel instance to a map
  Map<String, dynamic> toJson() {
    return {
      'userId': userId,
      'platform': platform?.name,
      'persona': persona?.name,
      'favoriteRetailers': favoriteRetailers,
    };
  }

  // CopyWith method
  UserProfileModel copyWith({
    String? userId,
    StreamingPlatform? platform,
    ShoppingPersona? persona,
    List<String>? favoriteRetailers,
  }) {
    return UserProfileModel(
      userId: userId ?? this.userId,
      platform: platform ?? this.platform,
      persona: persona ?? this.persona,
      favoriteRetailers: favoriteRetailers ?? this.favoriteRetailers,
    );
  }

  @override
  String toString() {
    return 'UserProfileModel(userId: $userId, platform: $platform, persona: $persona, favoriteRetailers: $favoriteRetailers)';
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;

    return other is UserProfileModel &&
        other.userId == userId &&
        other.platform == platform &&
        other.persona == persona &&
        listEquals(other.favoriteRetailers, favoriteRetailers);
  }

  @override
  int get hashCode {
    return userId.hashCode ^
           platform.hashCode ^
           persona.hashCode ^
           favoriteRetailers.hashCode;
  }
} 
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart';

@immutable
class CaptureSessionModel {
  final String sessionId;
  final String userId; // Foreign Key to UserModel
  final String imageUri; // URI to the uploaded image (e.g., GCS path)
  final DateTime timestamp;

  const CaptureSessionModel({
    required this.sessionId,
    required this.userId,
    required this.imageUri,
    required this.timestamp,
  });

  factory CaptureSessionModel.fromJson(Map<String, dynamic> json) {
    return CaptureSessionModel(
      sessionId: json['sessionId'] as String,
      userId: json['userId'] as String,
      imageUri: json['imageUri'] as String,
      timestamp: (json['timestamp'] as Timestamp).toDate(),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'sessionId': sessionId,
      'userId': userId,
      'imageUri': imageUri,
      'timestamp': Timestamp.fromDate(timestamp),
    };
  }

  CaptureSessionModel copyWith({
    String? sessionId,
    String? userId,
    String? imageUri,
    DateTime? timestamp,
  }) {
    return CaptureSessionModel(
      sessionId: sessionId ?? this.sessionId,
      userId: userId ?? this.userId,
      imageUri: imageUri ?? this.imageUri,
      timestamp: timestamp ?? this.timestamp,
    );
  }

  @override
  String toString() {
    return 'CaptureSessionModel(sessionId: $sessionId, userId: $userId, imageUri: $imageUri, timestamp: $timestamp)';
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;

    return other is CaptureSessionModel &&
        other.sessionId == sessionId &&
        other.userId == userId &&
        other.imageUri == imageUri &&
        other.timestamp == timestamp;
  }

  @override
  int get hashCode {
    return sessionId.hashCode ^
           userId.hashCode ^
           imageUri.hashCode ^
           timestamp.hashCode;
  }
} 
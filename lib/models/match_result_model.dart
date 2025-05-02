import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart';

@immutable
class MatchResultModel {
  final String resultId;
  final String sessionId; // Foreign Key to CaptureSessionModel
  final String productId; // ID from Google Cloud Vision Product Search
  final double score; // Confidence score from Product Search
  final DateTime timestamp;

  const MatchResultModel({
    required this.resultId,
    required this.sessionId,
    required this.productId,
    required this.score,
    required this.timestamp,
  });

  factory MatchResultModel.fromJson(Map<String, dynamic> json) {
    return MatchResultModel(
      resultId: json['resultId'] as String,
      sessionId: json['sessionId'] as String,
      productId: json['productId'] as String,
      score: (json['score'] as num).toDouble(),
      timestamp: (json['timestamp'] as Timestamp).toDate(),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'resultId': resultId,
      'sessionId': sessionId,
      'productId': productId,
      'score': score,
      'timestamp': Timestamp.fromDate(timestamp),
    };
  }

  MatchResultModel copyWith({
    String? resultId,
    String? sessionId,
    String? productId,
    double? score,
    DateTime? timestamp,
  }) {
    return MatchResultModel(
      resultId: resultId ?? this.resultId,
      sessionId: sessionId ?? this.sessionId,
      productId: productId ?? this.productId,
      score: score ?? this.score,
      timestamp: timestamp ?? this.timestamp,
    );
  }

  @override
  String toString() {
    return 'MatchResultModel(resultId: $resultId, sessionId: $sessionId, productId: $productId, score: $score, timestamp: $timestamp)';
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;

    return other is MatchResultModel &&
        other.resultId == resultId &&
        other.sessionId == sessionId &&
        other.productId == productId &&
        other.score == score &&
        other.timestamp == timestamp;
  }

  @override
  int get hashCode {
    return resultId.hashCode ^
           sessionId.hashCode ^
           productId.hashCode ^
           score.hashCode ^
           timestamp.hashCode;
  }
} 
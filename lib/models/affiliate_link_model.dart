import 'package:flutter/foundation.dart';

@immutable
class AffiliateLinkModel {
  final String linkId;
  final String productId; // Matches productId in MatchResultModel
  final String retailer;
  final String urlTemplate; // Template for constructing the final affiliate URL
  final double? commission; // Optional commission rate

  const AffiliateLinkModel({
    required this.linkId,
    required this.productId,
    required this.retailer,
    required this.urlTemplate,
    this.commission,
  });

   factory AffiliateLinkModel.fromJson(Map<String, dynamic> json) {
    return AffiliateLinkModel(
      linkId: json['linkId'] as String,
      productId: json['productId'] as String,
      retailer: json['retailer'] as String,
      urlTemplate: json['urlTemplate'] as String,
      commission: (json['commission'] as num?)?.toDouble(),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'linkId': linkId,
      'productId': productId,
      'retailer': retailer,
      'urlTemplate': urlTemplate,
      'commission': commission,
    };
  }

  AffiliateLinkModel copyWith({
    String? linkId,
    String? productId,
    String? retailer,
    String? urlTemplate,
    double? commission,
  }) {
    return AffiliateLinkModel(
      linkId: linkId ?? this.linkId,
      productId: productId ?? this.productId,
      retailer: retailer ?? this.retailer,
      urlTemplate: urlTemplate ?? this.urlTemplate,
      commission: commission ?? this.commission,
    );
  }

  @override
  String toString() {
    return 'AffiliateLinkModel(linkId: $linkId, productId: $productId, retailer: $retailer, urlTemplate: $urlTemplate, commission: $commission)';
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;

    return other is AffiliateLinkModel &&
        other.linkId == linkId &&
        other.productId == productId &&
        other.retailer == retailer &&
        other.urlTemplate == urlTemplate &&
        other.commission == commission;
  }

  @override
  int get hashCode {
    return linkId.hashCode ^
           productId.hashCode ^
           retailer.hashCode ^
           urlTemplate.hashCode ^
           commission.hashCode;
  }
} 
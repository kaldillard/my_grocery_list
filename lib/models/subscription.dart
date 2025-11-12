import 'package:equatable/equatable.dart';

enum SubscriptionTier {
  free,
  pro,
  family;

  String get displayName {
    switch (this) {
      case SubscriptionTier.free:
        return 'Free';
      case SubscriptionTier.pro:
        return 'Pro';
      case SubscriptionTier.family:
        return 'Family';
    }
  }

  String get description {
    switch (this) {
      case SubscriptionTier.free:
        return '1 user, 1 list';
      case SubscriptionTier.pro:
        return '1 user, unlimited lists';
      case SubscriptionTier.family:
        return 'Up to 5 users, unlimited lists';
    }
  }
}

class PricingConfig extends Equatable {
  final SubscriptionTier tier;
  final double basePrice;
  final double? perAdditionalUserPrice;
  final int? maxBaseUsers;
  final int? maxLists; // null means unlimited
  final DateTime effectiveFrom;
  final bool isGrandfathered;

  const PricingConfig({
    required this.tier,
    required this.basePrice,
    this.perAdditionalUserPrice,
    this.maxBaseUsers,
    this.maxLists,
    required this.effectiveFrom,
    this.isGrandfathered = false,
  });

  factory PricingConfig.fromJson(Map<String, dynamic> json) {
    return PricingConfig(
      tier: SubscriptionTier.values.firstWhere((e) => e.name == json['tier']),
      basePrice: (json['base_price'] as num).toDouble(),
      perAdditionalUserPrice:
          json['per_additional_user_price'] != null
              ? (json['per_additional_user_price'] as num).toDouble()
              : null,
      maxBaseUsers: json['max_base_users'] as int?,
      maxLists: json['max_lists'] as int?,
      effectiveFrom: DateTime.parse(json['effective_from'] as String),
    );
  }

  double calculatePrice(int memberCount) {
    if (tier != SubscriptionTier.family) {
      return basePrice;
    }

    if (memberCount <= (maxBaseUsers ?? 5)) {
      return basePrice;
    }

    final additionalUsers = memberCount - (maxBaseUsers ?? 5);
    return basePrice + (additionalUsers * (perAdditionalUserPrice ?? 0.99));
  }

  @override
  List<Object?> get props => [
    tier,
    basePrice,
    perAdditionalUserPrice,
    maxBaseUsers,
    maxLists,
    effectiveFrom,
    isGrandfathered,
  ];
}

class Subscription extends Equatable {
  final String id;
  final String familyId;
  final String userId;
  final SubscriptionTier tier;
  final String? stripeCustomerId;
  final String? stripeSubscriptionId;
  final String status;
  final double monthlyPrice;
  final bool isGrandfathered;
  final DateTime? grandfatheredAt;
  final int? maxLists;
  final int maxMembers;
  final DateTime? currentPeriodStart;
  final DateTime? currentPeriodEnd;
  final bool cancelAtPeriodEnd;
  final DateTime createdAt;

  const Subscription({
    required this.id,
    required this.familyId,
    required this.userId,
    required this.tier,
    this.stripeCustomerId,
    this.stripeSubscriptionId,
    required this.status,
    required this.monthlyPrice,
    this.isGrandfathered = false,
    this.grandfatheredAt,
    this.maxLists,
    required this.maxMembers,
    this.currentPeriodStart,
    this.currentPeriodEnd,
    this.cancelAtPeriodEnd = false,
    required this.createdAt,
  });

  bool get isActive =>
      status == 'active' &&
      (currentPeriodEnd == null || currentPeriodEnd!.isAfter(DateTime.now()));

  bool get isFree => tier == SubscriptionTier.free;

  factory Subscription.fromJson(Map<String, dynamic> json) {
    return Subscription(
      id: json['id'] as String,
      familyId: json['family_id'] as String,
      userId: json['user_id'] as String,
      tier: SubscriptionTier.values.firstWhere((e) => e.name == json['tier']),
      stripeCustomerId: json['stripe_customer_id'] as String?,
      stripeSubscriptionId: json['stripe_subscription_id'] as String?,
      status: json['status'] as String,
      monthlyPrice: (json['monthly_price'] as num).toDouble(),
      isGrandfathered: json['is_grandfathered'] as bool? ?? false,
      grandfatheredAt:
          json['grandfathered_at'] != null
              ? DateTime.parse(json['grandfathered_at'] as String)
              : null,
      maxLists: json['max_lists'] as int?,
      maxMembers: json['max_members'] as int,
      currentPeriodStart:
          json['current_period_start'] != null
              ? DateTime.parse(json['current_period_start'] as String)
              : null,
      currentPeriodEnd:
          json['current_period_end'] != null
              ? DateTime.parse(json['current_period_end'] as String)
              : null,
      cancelAtPeriodEnd: json['cancel_at_period_end'] as bool? ?? false,
      createdAt: DateTime.parse(json['created_at'] as String),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'family_id': familyId,
      'user_id': userId,
      'tier': tier.name,
      'stripe_customer_id': stripeCustomerId,
      'stripe_subscription_id': stripeSubscriptionId,
      'status': status,
      'monthly_price': monthlyPrice,
      'is_grandfathered': isGrandfathered,
      'grandfathered_at': grandfatheredAt?.toIso8601String(),
      'max_lists': maxLists,
      'max_members': maxMembers,
      'current_period_start': currentPeriodStart?.toIso8601String(),
      'current_period_end': currentPeriodEnd?.toIso8601String(),
      'cancel_at_period_end': cancelAtPeriodEnd,
      'created_at': createdAt.toIso8601String(),
    };
  }

  @override
  List<Object?> get props => [
    id,
    familyId,
    userId,
    tier,
    stripeCustomerId,
    stripeSubscriptionId,
    status,
    monthlyPrice,
    isGrandfathered,
    grandfatheredAt,
    maxLists,
    maxMembers,
    currentPeriodStart,
    currentPeriodEnd,
    cancelAtPeriodEnd,
    createdAt,
  ];
}

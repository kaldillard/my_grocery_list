// lib/blocs/subscription/subscription_state.dart

import 'package:my_grocery_list/models/subscription.dart';

abstract class SubscriptionState {}

class SubscriptionInitial extends SubscriptionState {}

class SubscriptionLoading extends SubscriptionState {}

class SubscriptionLoaded extends SubscriptionState {
  final Subscription subscription;

  SubscriptionLoaded(this.subscription);

  // Helper getters
  bool get hasActiveSubscription =>
      subscription.status == 'active' &&
      subscription.tier != SubscriptionTier.free;

  SubscriptionTier get tier => subscription.tier;

  bool get isUnlimited => subscription.maxLists == null;

  int get maxLists => subscription.maxLists ?? 999; // null means unlimited

  int get maxMembers => subscription.maxMembers;
}

class SubscriptionError extends SubscriptionState {
  final String message;

  SubscriptionError(this.message);
}

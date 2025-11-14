// lib/blocs/subscription/subscription_event.dart

import 'package:my_grocery_list/models/subscription.dart';

abstract class SubscriptionEvent {}

class LoadSubscription extends SubscriptionEvent {}

class RefreshSubscription extends SubscriptionEvent {}

// New events for Realtime
class SubscriptionUpdated extends SubscriptionEvent {
  final Subscription? subscription;

  SubscriptionUpdated({required this.subscription});
}

class StartListeningToSubscription extends SubscriptionEvent {}

class StopListeningToSubscription extends SubscriptionEvent {}

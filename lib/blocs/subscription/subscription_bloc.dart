import 'dart:async';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:my_grocery_list/models/subscription.dart';
import 'package:my_grocery_list/services/supabase_service.dart';
import 'subscription_event.dart';
import 'subscription_state.dart';

class SubscriptionBloc extends Bloc<SubscriptionEvent, SubscriptionState> {
  final SupabaseService supabaseService;
  StreamSubscription<Subscription?>? _subscriptionListener;

  SubscriptionBloc({required this.supabaseService})
    : super(SubscriptionInitial()) {
    on<LoadSubscription>(_onLoadSubscription);
    on<RefreshSubscription>(_onRefreshSubscription);
    on<SubscriptionUpdated>(_onSubscriptionUpdated);
    on<StartListeningToSubscription>(_onStartListening);
    on<StopListeningToSubscription>(_onStopListening);
    on<ResetSubscription>(_onResetSubscription);
  }

  Future<void> _onLoadSubscription(
    LoadSubscription event,
    Emitter<SubscriptionState> emit,
  ) async {
    print(
      '📥 Loading subscription for user: ${supabaseService.currentUser?.id}',
    );
    emit(SubscriptionLoading());

    try {
      final subscription = await supabaseService.fetchCurrentSubscription();

      if (subscription != null) {
        print(
          '✅ Found subscription: ${subscription.tier} - ${subscription.status}',
        );
        emit(SubscriptionLoaded(subscription));
      } else {
        print('ℹ️ No subscription found - using free tier');
        emit(SubscriptionLoaded(_createFreeSubscription()));
      }

      add(StartListeningToSubscription());
    } catch (e) {
      print('❌ Error loading subscription: $e');
      emit(SubscriptionError(e.toString()));
    }
  }

  Future<void> _onRefreshSubscription(
    RefreshSubscription event,
    Emitter<SubscriptionState> emit,
  ) async {
    // Don't show loading state during refresh
    try {
      final subscription = await supabaseService.fetchCurrentSubscription();

      if (subscription != null) {
        emit(SubscriptionLoaded(subscription));
      } else {
        emit(SubscriptionLoaded(_createFreeSubscription()));
      }
    } catch (e) {
      // If refresh fails, just keep current state
      print('Error refreshing subscription: $e');
    }
  }

  Future<void> _onStartListening(
    StartListeningToSubscription event,
    Emitter<SubscriptionState> emit,
  ) async {
    try {
      print('🎧 Starting realtime subscription listener in BLoC');

      // Cancel existing listener if any
      await _subscriptionListener?.cancel();

      // Start listening to the service's subscription stream
      await supabaseService.startListeningToSubscription();

      // Subscribe to updates
      _subscriptionListener = supabaseService.subscriptionStream.listen(
        (subscription) {
          print('🔔 Received subscription update in BLoC');
          add(SubscriptionUpdated(subscription: subscription));
        },
        onError: (error) {
          print('❌ Error in subscription stream: $error');
        },
      );

      print('✅ Realtime listener started');
    } catch (e) {
      print('❌ Error starting subscription listener: $e');
    }
  }

  Future<void> _onStopListening(
    StopListeningToSubscription event,
    Emitter<SubscriptionState> emit,
  ) async {
    print('🔇 Stopping subscription listener');
    await _subscriptionListener?.cancel();
    _subscriptionListener = null;
    await supabaseService.stopListeningToSubscription();
  }

  void _onSubscriptionUpdated(
    SubscriptionUpdated event,
    Emitter<SubscriptionState> emit,
  ) {
    print('📊 Updating subscription state');

    if (event.subscription != null) {
      print('✅ Subscription tier: ${event.subscription!.tier}');
      print('✅ Subscription status: ${event.subscription!.status}');
      emit(SubscriptionLoaded(event.subscription!));
    } else {
      print('ℹ️ No subscription, using free tier');
      emit(SubscriptionLoaded(_createFreeSubscription()));
    }
  }

  Subscription _createFreeSubscription() {
    return Subscription(
      id: 'free',
      familyId: '',
      userId: supabaseService.currentUser!.id,
      tier: SubscriptionTier.free,
      status: 'active',
      monthlyPrice: 0.0,
      maxMembers: 1,
      maxLists: 1,
      createdAt: DateTime.now(),
    );
  }

  @override
  Future<void> close() {
    _subscriptionListener?.cancel();
    supabaseService.stopListeningToSubscription();
    return super.close();
  }

  void _onResetSubscription(
    ResetSubscription event,
    Emitter<SubscriptionState> emit,
  ) {
    print('🔄 Resetting subscription state');

    // Stop listening
    _subscriptionListener?.cancel();
    _subscriptionListener = null;
    supabaseService.stopListeningToSubscription();

    // Reset to initial state
    emit(SubscriptionInitial());
  }
}

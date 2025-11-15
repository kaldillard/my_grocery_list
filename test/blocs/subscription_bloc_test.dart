import 'package:bloc_test/bloc_test.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:my_grocery_list/blocs/subscription/subscription_bloc.dart';
import 'package:my_grocery_list/blocs/subscription/subscription_event.dart';
import 'package:my_grocery_list/blocs/subscription/subscription_state.dart';
import 'package:my_grocery_list/models/subscription.dart';
import 'package:my_grocery_list/services/supabase_service.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class MockSupabaseService extends Mock implements SupabaseService {}

class MockUser extends Mock implements User {}

void main() {
  group('SubscriptionBloc', () {
    late MockSupabaseService mockSupabaseService;
    late MockUser mockUser;

    setUp(() {
      mockSupabaseService = MockSupabaseService();
      mockUser = MockUser();

      // Setup default mocks
      when(() => mockUser.id).thenReturn('test-user-id');
      when(() => mockSupabaseService.currentUser).thenReturn(mockUser);

      // Fix: Return proper Future<void> instead of null
      when(
        () => mockSupabaseService.stopListeningToSubscription(),
      ).thenAnswer((_) async {});

      when(
        () => mockSupabaseService.startListeningToSubscription(),
      ).thenAnswer((_) async {});

      when(
        () => mockSupabaseService.subscriptionStream,
      ).thenAnswer((_) => Stream.value(null));
    });

    test('initial state is SubscriptionInitial', () {
      final bloc = SubscriptionBloc(supabaseService: mockSupabaseService);
      expect(bloc.state, isA<SubscriptionInitial>());
      bloc.close();
    });

    blocTest<SubscriptionBloc, SubscriptionState>(
      'emits [SubscriptionLoading, SubscriptionLoaded] with free tier when no subscription',
      setUp: () {
        when(
          () => mockSupabaseService.fetchCurrentSubscription(),
        ).thenAnswer((_) async => null);
      },
      build: () => SubscriptionBloc(supabaseService: mockSupabaseService),
      act: (bloc) => bloc.add(LoadSubscription()),
      expect:
          () => [
            isA<SubscriptionLoading>(),
            isA<SubscriptionLoaded>().having(
              (s) => s.subscription.tier,
              'tier',
              SubscriptionTier.free,
            ),
          ],
    );

    blocTest<SubscriptionBloc, SubscriptionState>(
      'emits [SubscriptionLoaded] with actual subscription data',
      setUp: () {
        final subscription = Subscription(
          id: 'sub-1',
          familyId: 'family-1',
          userId: 'test-user-id',
          tier: SubscriptionTier.pro,
          status: 'active',
          monthlyPrice: 1.99,
          maxMembers: 1,
          createdAt: DateTime.now(),
        );

        when(
          () => mockSupabaseService.fetchCurrentSubscription(),
        ).thenAnswer((_) async => subscription);
      },
      build: () => SubscriptionBloc(supabaseService: mockSupabaseService),
      act: (bloc) => bloc.add(LoadSubscription()),
      expect:
          () => [
            isA<SubscriptionLoading>(),
            isA<SubscriptionLoaded>().having(
              (s) => s.subscription.tier,
              'tier',
              SubscriptionTier.pro,
            ),
          ],
    );

    blocTest<SubscriptionBloc, SubscriptionState>(
      'emits [SubscriptionError] on failure',
      setUp: () {
        when(
          () => mockSupabaseService.fetchCurrentSubscription(),
        ).thenThrow(Exception('Network error'));
      },
      build: () => SubscriptionBloc(supabaseService: mockSupabaseService),
      act: (bloc) => bloc.add(LoadSubscription()),
      expect:
          () => [
            isA<SubscriptionLoading>(),
            isA<SubscriptionError>().having(
              (s) => s.message,
              'message',
              contains('Network error'),
            ),
          ],
    );

    blocTest<SubscriptionBloc, SubscriptionState>(
      'resets to initial state on ResetSubscription',
      build: () => SubscriptionBloc(supabaseService: mockSupabaseService),
      seed:
          () => SubscriptionLoaded(
            Subscription(
              id: 'sub-1',
              familyId: 'family-1',
              userId: 'test-user-id',
              tier: SubscriptionTier.pro,
              status: 'active',
              monthlyPrice: 1.99,
              maxMembers: 1,
              createdAt: DateTime.now(),
            ),
          ),
      act: (bloc) => bloc.add(ResetSubscription()),
      expect: () => [isA<SubscriptionInitial>()],
      verify: (_) {
        // Verify that stopListeningToSubscription was called
        verify(
          () => mockSupabaseService.stopListeningToSubscription(),
        ).called(1);
      },
    );
  });
}

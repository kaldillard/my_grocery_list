import 'package:mocktail/mocktail.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:my_grocery_list/services/supabase_service.dart';

// Base mocks
class MockSupabaseService extends Mock implements SupabaseService {}

class MockSupabaseClient extends Mock implements SupabaseClient {}

class MockGoTrueClient extends Mock implements GoTrueClient {}

class MockRealtimeClient extends Mock implements RealtimeClient {}

class MockRealtimeChannel extends Mock implements RealtimeChannel {}

class MockUser extends Mock implements User {}

class MockSession extends Mock implements Session {}

/// Factory class to create commonly needed mocks with default behavior
class MockFactory {
  /// Create a mock SupabaseService with basic auth behavior
  static MockSupabaseService createSupabaseService({
    User? currentUser,
    bool isAuthenticated = false,
  }) {
    final mock = MockSupabaseService();

    when(() => mock.currentUser).thenReturn(currentUser);
    when(() => mock.authStateChanges).thenAnswer(
      (_) => Stream.value(
        AuthState(
          AuthChangeEvent.signedIn,
          Session(
            accessToken: 'test-token',
            tokenType: 'bearer',
            user: currentUser!,
          ),
        ),
      ),
    );

    return mock;
  }

  /// Create a mock user
  static User createMockUser({
    String id = 'test-user-id',
    String email = 'test@example.com',
  }) {
    final mock = MockUser();
    when(() => mock.id).thenReturn(id);
    when(() => mock.email).thenReturn(email);
    return mock;
  }

  /// Create a mock RealtimeChannel
  static MockRealtimeChannel createRealtimeChannel() {
    final mock = MockRealtimeChannel();
    when(() => mock.unsubscribe()).thenAnswer((_) async => 'ok');
    return mock;
  }

  /// Setup basic Supabase mocks for grocery operations
  static void setupGroceryMocks(MockSupabaseService service) {
    when(
      () => service.getGroceryItemsForList(any()),
    ).thenAnswer((_) async => []);
    when(
      () => service.addGroceryItemToList(
        listId: any(named: 'listId'),
        name: any(named: 'name'),
        addedById: any(named: 'addedById'),
        quantity: any(named: 'quantity'),
        category: any(named: 'category'),
        notes: any(named: 'notes'),
      ),
    ).thenAnswer((_) async {});
    when(
      () => service.updateGroceryItem(any(), any()),
    ).thenAnswer((_) async {});
    when(() => service.deleteGroceryItem(any())).thenAnswer((_) async {});
    when(
      () => service.updateGroceryItemQuantity(any(), any()),
    ).thenAnswer((_) async {});
    when(
      () => service.clearCompletedItemsInList(any()),
    ).thenAnswer((_) async {});
    when(
      () => service.subscribeToGroceryItemsInList(any(), any()),
    ).thenReturn(createRealtimeChannel());
  }

  /// Setup basic family operation mocks
  static void setupFamilyMocks(MockSupabaseService service) {
    when(() => service.getFamilyMembers(any())).thenAnswer((_) async => []);
    when(
      () => service.getCurrentFamilyMember(any()),
    ).thenAnswer((_) async => null);
    when(
      () => service.addFamilyMember(
        familyId: any(named: 'familyId'),
        displayName: any(named: 'displayName'),
        color: any(named: 'color'),
      ),
    ).thenAnswer((_) async {});
  }

  /// Setup subscription mocks
  static void setupSubscriptionMocks(MockSupabaseService service) {
    when(
      () => service.fetchCurrentSubscription(),
    ).thenAnswer((_) async => null);
    when(() => service.startListeningToSubscription()).thenAnswer((_) async {});
    when(() => service.stopListeningToSubscription()).thenAnswer((_) async {});
    when(
      () => service.subscriptionStream,
    ).thenAnswer((_) => const Stream.empty());
  }
}

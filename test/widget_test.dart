import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:my_grocery_list/app.dart';
import 'package:my_grocery_list/services/supabase_service.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

// Mock classes
class MockSupabaseService extends Mock implements SupabaseService {}

class MockRealtimeChannel extends Mock implements RealtimeChannel {}

class MockAuthState extends Fake implements AuthState {}

void main() {
  late MockSupabaseService mockSupabaseService;
  late MockRealtimeChannel mockChannel;

  setUp(() {
    mockSupabaseService = MockSupabaseService();
    mockChannel = MockRealtimeChannel();

    // Register fallback values
    registerFallbackValue(MockAuthState());

    // Setup default mocks for all required methods
    when(() => mockSupabaseService.currentUser).thenReturn(null);

    when(() => mockSupabaseService.authStateChanges).thenAnswer(
      (_) => Stream.value(AuthState(AuthChangeEvent.signedOut, null)),
    );

    when(
      () => mockSupabaseService.subscribeToGroceryItemsInList(any(), any()),
    ).thenReturn(mockChannel);

    when(() => mockChannel.unsubscribe()).thenAnswer((_) async => 'ok');

    // Fix: Return proper Future<void> instead of null
    when(
      () => mockSupabaseService.stopListeningToSubscription(),
    ).thenAnswer((_) async {});

    when(
      () => mockSupabaseService.fetchCurrentSubscription(),
    ).thenAnswer((_) async => null);

    when(
      () => mockSupabaseService.subscriptionStream,
    ).thenAnswer((_) => Stream.value(null));

    when(
      () => mockSupabaseService.startListeningToSubscription(),
    ).thenAnswer((_) async {});
  });

  testWidgets('App initializes without crashing', (WidgetTester tester) async {
    await tester.pumpWidget(MyApp(supabaseService: mockSupabaseService));
    await tester.pumpAndSettle();

    // App should load and show login screen when not authenticated
    expect(find.byType(MyApp), findsOneWidget);
  });
}

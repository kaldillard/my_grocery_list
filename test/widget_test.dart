import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:my_grocery_list/services/supabase_service.dart';
import 'package:my_grocery_list/app.dart';

class MockSupabaseService extends Mock implements SupabaseService {}

void main() {
  testWidgets('App initializes without crashing', (WidgetTester tester) async {
    final mockSupabaseService = MockSupabaseService();

    // Setup basic mocks
    when(() => mockSupabaseService.currentUser).thenReturn(null);
    when(
      () => mockSupabaseService.authStateChanges,
    ).thenAnswer((_) => const Stream.empty());

    await tester.pumpWidget(MyApp(supabaseService: mockSupabaseService));

    // Verify the app renders
    expect(find.byType(MyApp), findsOneWidget);
  });
}

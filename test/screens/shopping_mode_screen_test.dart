import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:my_grocery_list/blocs/grocery/grocery_bloc.dart';
import 'package:my_grocery_list/blocs/grocery/grocery_event.dart';
import 'package:my_grocery_list/blocs/grocery/grocery_state.dart';
import 'package:my_grocery_list/models/category.dart';
import 'package:my_grocery_list/models/grocery_item.dart';
import 'package:my_grocery_list/screens/shopping_mode_screen.dart';

class MockGroceryBloc extends Mock implements GroceryBloc {}

void main() {
  group('ShoppingModeScreen', () {
    late MockGroceryBloc mockGroceryBloc;

    setUp(() {
      mockGroceryBloc = MockGroceryBloc();
      registerFallbackValue(ToggleGroceryItem(''));
    });

    Widget buildWidget(GroceryState state) {
      when(() => mockGroceryBloc.state).thenReturn(state);
      when(() => mockGroceryBloc.stream).thenAnswer((_) => Stream.value(state));

      return BlocProvider<GroceryBloc>.value(
        value: mockGroceryBloc,
        child: const MaterialApp(home: ShoppingModeScreen()),
      );
    }

    testWidgets('shows empty state when all items completed', (tester) async {
      final state = GroceryState(
        items: [
          GroceryItem(
            id: '1',
            name: 'Milk',
            addedBy: 'John',
            addedAt: DateTime.now(),
            isCompleted: true,
          ),
        ],
      );

      await tester.pumpWidget(buildWidget(state));

      expect(find.text('All items checked off!'), findsOneWidget);
      expect(find.text('You\'re done shopping!'), findsOneWidget);
      expect(find.byIcon(Icons.check_circle_outline), findsOneWidget);
    });

    testWidgets('displays progress bar with correct values', (tester) async {
      final state = GroceryState(
        items: [
          GroceryItem(
            id: '1',
            name: 'Milk',
            addedBy: 'John',
            addedAt: DateTime.now(),
            isCompleted: true,
          ),
          GroceryItem(
            id: '2',
            name: 'Bread',
            addedBy: 'Jane',
            addedAt: DateTime.now(),
            isCompleted: false,
          ),
          GroceryItem(
            id: '3',
            name: 'Eggs',
            addedBy: 'John',
            addedAt: DateTime.now(),
            isCompleted: false,
          ),
        ],
      );

      await tester.pumpWidget(buildWidget(state));

      // Check progress text
      expect(find.text('1 / 3'), findsOneWidget);
      expect(find.text('2 remaining'), findsOneWidget);

      // Check progress bar exists
      expect(find.byType(LinearProgressIndicator), findsOneWidget);
    });

    testWidgets('displays active items in simple list mode', (tester) async {
      final state = GroceryState(
        items: [
          GroceryItem(
            id: '1',
            name: 'Milk',
            addedBy: 'John',
            addedAt: DateTime.now(),
            isCompleted: false,
            category: GroceryCategory.dairy,
          ),
          GroceryItem(
            id: '2',
            name: 'Bread',
            addedBy: 'Jane',
            addedAt: DateTime.now(),
            isCompleted: false,
            category: GroceryCategory.bakery,
          ),
        ],
      );

      await tester.pumpWidget(buildWidget(state));

      expect(find.text('Milk'), findsOneWidget);
      expect(find.text('Bread'), findsOneWidget);
    });

    testWidgets('groups items by category when enabled', (tester) async {
      final state = GroceryState(
        items: [
          GroceryItem(
            id: '1',
            name: 'Milk',
            addedBy: 'John',
            addedAt: DateTime.now(),
            isCompleted: false,
            category: GroceryCategory.dairy,
          ),
          GroceryItem(
            id: '2',
            name: 'Cheese',
            addedBy: 'Jane',
            addedAt: DateTime.now(),
            isCompleted: false,
            category: GroceryCategory.dairy,
          ),
          GroceryItem(
            id: '3',
            name: 'Bread',
            addedBy: 'John',
            addedAt: DateTime.now(),
            isCompleted: false,
            category: GroceryCategory.bakery,
          ),
        ],
      );

      await tester.pumpWidget(buildWidget(state));

      // Should show category headers
      expect(find.text(GroceryCategory.dairy.displayName), findsOneWidget);
      expect(find.text(GroceryCategory.bakery.displayName), findsOneWidget);

      // Should show item counts
      expect(find.text('2'), findsOneWidget); // Dairy count badge
    });

    testWidgets('displays quantity badge for items with quantity > 1', (
      tester,
    ) async {
      final state = GroceryState(
        items: [
          GroceryItem(
            id: '1',
            name: 'Milk',
            addedBy: 'John',
            addedAt: DateTime.now(),
            isCompleted: false,
            quantity: 3,
          ),
        ],
      );

      await tester.pumpWidget(buildWidget(state));

      expect(find.text('x3'), findsOneWidget);
    });

    testWidgets('displays notes when present', (tester) async {
      final state = GroceryState(
        items: [
          GroceryItem(
            id: '1',
            name: 'Milk',
            addedBy: 'John',
            addedAt: DateTime.now(),
            isCompleted: false,
            notes: 'Get organic',
          ),
        ],
      );

      await tester.pumpWidget(buildWidget(state));

      expect(find.text('Get organic'), findsOneWidget);
    });

    testWidgets('tapping item toggles completion', (tester) async {
      final state = GroceryState(
        items: [
          GroceryItem(
            id: '1',
            name: 'Milk',
            addedBy: 'John',
            addedAt: DateTime.now(),
            isCompleted: false,
          ),
        ],
      );

      await tester.pumpWidget(buildWidget(state));

      await tester.tap(find.byType(Card));

      verify(() => mockGroceryBloc.add(ToggleGroceryItem('1'))).called(1);
    });

    testWidgets('toggle button switches between list modes', (tester) async {
      final state = GroceryState(
        items: [
          GroceryItem(
            id: '1',
            name: 'Milk',
            addedBy: 'John',
            addedAt: DateTime.now(),
            isCompleted: false,
            category: GroceryCategory.dairy,
          ),
        ],
      );

      await tester.pumpWidget(buildWidget(state));

      // Initially grouped (icon should be 'category')
      expect(find.byIcon(Icons.category), findsOneWidget);

      // Tap to toggle
      await tester.tap(find.byIcon(Icons.category));
      await tester.pumpAndSettle();

      // Now should show 'list' icon
      expect(find.byIcon(Icons.list), findsOneWidget);
    });

    testWidgets('shows loading indicator when loading', (tester) async {
      const state = GroceryState(isLoading: true);

      await tester.pumpWidget(buildWidget(state));

      expect(find.byType(CircularProgressIndicator), findsOneWidget);
    });
  });
}

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:my_grocery_list/blocs/family/family_state.dart';
import 'package:my_grocery_list/blocs/grocery/grocery_bloc.dart';
import 'package:my_grocery_list/blocs/grocery/grocery_event.dart';
import 'package:my_grocery_list/blocs/grocery/grocery_state.dart';
import 'package:my_grocery_list/models/category.dart';
import 'package:my_grocery_list/models/family_member.dart';
import 'package:my_grocery_list/models/grocery_item.dart';
import 'package:my_grocery_list/widgets/grocery_tile.dart';

class MockGroceryBloc extends Mock implements GroceryBloc {}

void main() {
  group('GroceryTile', () {
    late MockGroceryBloc mockGroceryBloc;
    late GroceryItem testItem;
    late FamilyState testFamilyState;

    setUp(() {
      mockGroceryBloc = MockGroceryBloc();

      testItem = GroceryItem(
        id: 'item-1',
        name: 'Milk',
        addedBy: 'John',
        addedAt: DateTime.now(),
        quantity: 2,
        category: GroceryCategory.dairy,
        notes: 'Get organic',
      );

      testFamilyState = const FamilyState(
        members: [FamilyMember(id: '1', name: 'John', color: '#FF6B6B')],
      );

      // Register fallback values for mocktail
      registerFallbackValue(ToggleGroceryItem(''));
      registerFallbackValue(UpdateGroceryItemQuantity('', 1));
      registerFallbackValue(DeleteGroceryItem(''));

      // Fix: Mock the stream property
      when(
        () => mockGroceryBloc.stream,
      ).thenAnswer((_) => Stream<GroceryState>.empty());

      // Mock the state
      when(() => mockGroceryBloc.state).thenReturn(const GroceryState());
    });

    Widget buildWidget() {
      return BlocProvider<GroceryBloc>.value(
        value: mockGroceryBloc,
        child: MaterialApp(
          home: Scaffold(
            body: GroceryTile(item: testItem, familyState: testFamilyState),
          ),
        ),
      );
    }

    testWidgets('displays item name', (tester) async {
      await tester.pumpWidget(buildWidget());

      expect(find.text('Milk'), findsOneWidget);
    });

    testWidgets('displays quantity', (tester) async {
      await tester.pumpWidget(buildWidget());

      expect(find.text('2'), findsOneWidget);
    });

    testWidgets('displays added by text', (tester) async {
      await tester.pumpWidget(buildWidget());

      expect(find.text('Added by John'), findsOneWidget);
    });

    testWidgets('displays notes when present', (tester) async {
      await tester.pumpWidget(buildWidget());

      expect(find.text('Get organic'), findsOneWidget);
    });

    testWidgets('displays category icon', (tester) async {
      await tester.pumpWidget(buildWidget());

      expect(find.byIcon(GroceryCategory.dairy.icon), findsOneWidget);
    });

    testWidgets('tapping checkbox toggles item', (tester) async {
      await tester.pumpWidget(buildWidget());

      final checkbox = find.byType(Checkbox);
      await tester.tap(checkbox);

      verify(() => mockGroceryBloc.add(ToggleGroceryItem('item-1'))).called(1);
    });

    testWidgets('increment button increases quantity', (tester) async {
      await tester.pumpWidget(buildWidget());

      // Find the increment button (second add icon)
      final addButtons = find.byIcon(Icons.add);
      await tester.tap(addButtons.last);

      verify(
        () => mockGroceryBloc.add(UpdateGroceryItemQuantity('item-1', 3)),
      ).called(1);
    });

    testWidgets('decrement button decreases quantity', (tester) async {
      await tester.pumpWidget(buildWidget());

      final removeButton = find.byIcon(Icons.remove);
      await tester.tap(removeButton);

      verify(
        () => mockGroceryBloc.add(UpdateGroceryItemQuantity('item-1', 1)),
      ).called(1);
    });

    testWidgets('decrement button disabled when quantity is 1', (tester) async {
      final itemWithQuantity1 = testItem.copyWith(quantity: 1);

      await tester.pumpWidget(
        BlocProvider<GroceryBloc>.value(
          value: mockGroceryBloc,
          child: MaterialApp(
            home: Scaffold(
              body: GroceryTile(
                item: itemWithQuantity1,
                familyState: testFamilyState,
              ),
            ),
          ),
        ),
      );

      final removeButton = find.byIcon(Icons.remove);
      await tester.tap(removeButton);

      // Should not call the event when quantity is 1
      verifyNever(
        () => mockGroceryBloc.add(any(that: isA<UpdateGroceryItemQuantity>())),
      );
    });

    testWidgets('shows completed styling when item is completed', (
      tester,
    ) async {
      final completedItem = testItem.copyWith(isCompleted: true);

      await tester.pumpWidget(
        BlocProvider<GroceryBloc>.value(
          value: mockGroceryBloc,
          child: MaterialApp(
            home: Scaffold(
              body: GroceryTile(
                item: completedItem,
                familyState: testFamilyState,
              ),
            ),
          ),
        ),
      );

      // Find the text widget and check its style
      final textWidget = tester.widget<Text>(find.text('Milk'));
      expect(textWidget.style?.decoration, TextDecoration.lineThrough);
      expect(textWidget.style?.color, Colors.grey);
    });

    testWidgets('dismissing removes item', (tester) async {
      await tester.pumpWidget(buildWidget());

      // Swipe to dismiss
      await tester.drag(find.byType(Card), const Offset(-500, 0));
      await tester.pumpAndSettle();

      verify(() => mockGroceryBloc.add(DeleteGroceryItem('item-1'))).called(1);
    });

    testWidgets('tapping tile opens edit dialog', (tester) async {
      await tester.pumpWidget(buildWidget());

      await tester.tap(find.byType(Card));
      await tester.pumpAndSettle();

      // Check if dialog is shown
      expect(find.text('Edit Item'), findsOneWidget);
    });
  });
}

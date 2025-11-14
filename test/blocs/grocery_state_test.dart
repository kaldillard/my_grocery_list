import 'package:flutter_test/flutter_test.dart';
import 'package:my_grocery_list/blocs/grocery/grocery_state.dart';
import 'package:my_grocery_list/models/category.dart';
import 'package:my_grocery_list/models/grocery_item.dart';

void main() {
  group('GroceryState', () {
    late DateTime testDate;
    late List<GroceryItem> testItems;

    setUp(() {
      testDate = DateTime(2025, 1, 15);
      testItems = [
        GroceryItem(
          id: '1',
          name: 'Milk',
          addedBy: 'John',
          addedAt: testDate,
          isCompleted: false,
          quantity: 2,
          category: GroceryCategory.dairy,
        ),
        GroceryItem(
          id: '2',
          name: 'Bread',
          addedBy: 'Jane',
          addedAt: testDate,
          isCompleted: true,
          quantity: 1,
          category: GroceryCategory.bakery,
        ),
        GroceryItem(
          id: '3',
          name: 'Apples',
          addedBy: 'John',
          addedAt: testDate,
          isCompleted: false,
          quantity: 5,
          category: GroceryCategory.produce,
        ),
      ];
    });

    test('creates state with default values', () {
      const state = GroceryState();

      expect(state.items, isEmpty);
      expect(state.isLoading, false);
      expect(state.selectedCategory, isNull);
    });

    test('copyWith creates new instance with updated values', () {
      const original = GroceryState(isLoading: false);
      final updated = original.copyWith(
        isLoading: true,
        selectedCategory: GroceryCategory.dairy,
      );

      expect(updated.isLoading, true);
      expect(updated.selectedCategory, GroceryCategory.dairy);
      expect(original.isLoading, false); // Original unchanged
    });

    test('activeItems returns only uncompleted items', () {
      final state = GroceryState(items: testItems);

      expect(state.activeItems.length, 2);
      expect(state.activeItems.every((item) => !item.isCompleted), true);
    });

    test('completedItems returns only completed items', () {
      final state = GroceryState(items: testItems);

      expect(state.completedItems.length, 1);
      expect(state.completedItems.every((item) => item.isCompleted), true);
    });

    test('itemsByCategory filters correctly', () {
      final state = GroceryState(items: testItems);
      final dairyItems = state.itemsByCategory(GroceryCategory.dairy);

      expect(dairyItems.length, 1);
      expect(dairyItems.first.name, 'Milk');
    });

    test('categoryCounts calculates correctly', () {
      final state = GroceryState(items: testItems);
      final counts = state.categoryCounts;

      expect(counts[GroceryCategory.dairy], 1);
      expect(counts[GroceryCategory.produce], 1);
      expect(
        counts[GroceryCategory.bakery],
        isNull,
      ); // Completed item not counted
    });

    test('completionPercentage calculates correctly', () {
      final state = GroceryState(items: testItems);

      // 1 completed out of 3 = 0.333...
      expect(state.completionPercentage, closeTo(0.333, 0.01));
    });

    test('completionPercentage returns 0 for empty list', () {
      const state = GroceryState();

      expect(state.completionPercentage, 0.0);
    });

    test('totalQuantity sums only active items', () {
      final state = GroceryState(items: testItems);

      // Milk (2) + Apples (5) = 7 (Bread is completed)
      expect(state.totalQuantity, 7);
    });

    test('totalQuantity returns 0 for empty list', () {
      const state = GroceryState();

      expect(state.totalQuantity, 0);
    });

    test('equality works correctly', () {
      final state1 = GroceryState(items: testItems, isLoading: false);
      final state2 = GroceryState(items: testItems, isLoading: false);
      final state3 = GroceryState(items: testItems, isLoading: true);

      expect(state1, equals(state2));
      expect(state1, isNot(equals(state3)));
    });

    test('props includes all properties', () {
      final state = GroceryState(
        items: testItems,
        isLoading: true,
        selectedCategory: GroceryCategory.dairy,
      );

      expect(state.props.length, 3);
      expect(state.props, contains(testItems));
      expect(state.props, contains(true));
      expect(state.props, contains(GroceryCategory.dairy));
    });
  });
}

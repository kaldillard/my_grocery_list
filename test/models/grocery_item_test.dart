import 'package:flutter_test/flutter_test.dart';
import 'package:my_grocery_list/models/category.dart';
import 'package:my_grocery_list/models/grocery_item.dart';

void main() {
  group('GroceryItem', () {
    late DateTime testDate;

    setUp(() {
      testDate = DateTime(2025, 1, 15);
    });

    test('creates item with default values', () {
      final item = GroceryItem(
        id: '1',
        name: 'Milk',
        addedBy: 'John',
        addedAt: testDate,
      );

      expect(item.id, '1');
      expect(item.name, 'Milk');
      expect(item.isCompleted, false);
      expect(item.quantity, 1);
      expect(item.category, GroceryCategory.other);
      expect(item.notes, isNull);
    });

    test('creates item with all properties', () {
      final item = GroceryItem(
        id: '2',
        name: 'Organic Milk',
        addedBy: 'Jane',
        addedAt: testDate,
        isCompleted: true,
        quantity: 2,
        category: GroceryCategory.dairy,
        notes: 'Get organic brand',
      );

      expect(item.id, '2');
      expect(item.name, 'Organic Milk');
      expect(item.isCompleted, true);
      expect(item.quantity, 2);
      expect(item.category, GroceryCategory.dairy);
      expect(item.notes, 'Get organic brand');
    });

    test('copyWith creates new instance with updated values', () {
      final original = GroceryItem(
        id: '1',
        name: 'Milk',
        addedBy: 'John',
        addedAt: testDate,
      );

      final updated = original.copyWith(
        name: 'Almond Milk',
        quantity: 3,
        notes: 'Unsweetened',
      );

      expect(updated.id, '1'); // Unchanged
      expect(updated.name, 'Almond Milk'); // Changed
      expect(updated.quantity, 3); // Changed
      expect(updated.notes, 'Unsweetened'); // Changed
      expect(updated.addedBy, 'John'); // Unchanged
    });

    test('toJson serializes correctly', () {
      final item = GroceryItem(
        id: '1',
        name: 'Milk',
        addedBy: 'John',
        addedAt: testDate,
        quantity: 2,
        category: GroceryCategory.dairy,
        notes: 'Organic',
      );

      final json = item.toJson();

      expect(json['id'], '1');
      expect(json['name'], 'Milk');
      expect(json['quantity'], 2);
      expect(json['category'], 'dairy');
      expect(json['notes'], 'Organic');
      expect(json['isCompleted'], false);
    });

    test('fromJson deserializes correctly', () {
      final json = {
        'id': '1',
        'name': 'Milk',
        'addedBy': 'John',
        'addedAt': testDate.toIso8601String(),
        'quantity': 2,
        'category': 'dairy',
        'notes': 'Organic',
        'isCompleted': true,
      };

      final item = GroceryItem.fromJson(json);

      expect(item.id, '1');
      expect(item.name, 'Milk');
      expect(item.quantity, 2);
      expect(item.category, GroceryCategory.dairy);
      expect(item.notes, 'Organic');
      expect(item.isCompleted, true);
    });

    test('fromJson handles missing optional fields', () {
      final json = {
        'id': '1',
        'name': 'Milk',
        'addedBy': 'John',
        'addedAt': testDate.toIso8601String(),
      };

      final item = GroceryItem.fromJson(json);

      expect(item.quantity, 1); // Default
      expect(item.category, GroceryCategory.other); // Default
      expect(item.notes, isNull);
      expect(item.isCompleted, false); // Default
    });

    test('equality works correctly', () {
      final item1 = GroceryItem(
        id: '1',
        name: 'Milk',
        addedBy: 'John',
        addedAt: testDate,
      );

      final item2 = GroceryItem(
        id: '1',
        name: 'Milk',
        addedBy: 'John',
        addedAt: testDate,
      );

      final item3 = GroceryItem(
        id: '2',
        name: 'Milk',
        addedBy: 'John',
        addedAt: testDate,
      );

      expect(item1, equals(item2));
      expect(item1, isNot(equals(item3)));
    });
  });

  group('GroceryCategory', () {
    test('has correct display names', () {
      expect(GroceryCategory.produce.displayName, 'Produce');
      expect(GroceryCategory.dairy.displayName, 'Dairy & Eggs');
      expect(GroceryCategory.meat.displayName, 'Meat & Seafood');
    });

    test('has icons for all categories', () {
      for (var category in GroceryCategory.values) {
        expect(category.icon, isNotNull);
      }
    });

    test('has colors for all categories', () {
      for (var category in GroceryCategory.values) {
        expect(category.color, isNotNull);
      }
    });
  });
}

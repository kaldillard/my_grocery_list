import 'package:flutter/material.dart';

enum GroceryCategory {
  produce,
  dairy,
  meat,
  bakery,
  frozen,
  pantry,
  beverages,
  snacks,
  household,
  personal,
  other;

  String get displayName {
    switch (this) {
      case GroceryCategory.produce:
        return 'Produce';
      case GroceryCategory.dairy:
        return 'Dairy & Eggs';
      case GroceryCategory.meat:
        return 'Meat & Seafood';
      case GroceryCategory.bakery:
        return 'Bakery';
      case GroceryCategory.frozen:
        return 'Frozen';
      case GroceryCategory.pantry:
        return 'Pantry';
      case GroceryCategory.beverages:
        return 'Beverages';
      case GroceryCategory.snacks:
        return 'Snacks';
      case GroceryCategory.household:
        return 'Household';
      case GroceryCategory.personal:
        return 'Personal Care';
      case GroceryCategory.other:
        return 'Other';
    }
  }

  IconData get icon {
    switch (this) {
      case GroceryCategory.produce:
        return Icons.eco;
      case GroceryCategory.dairy:
        return Icons.local_drink;
      case GroceryCategory.meat:
        return Icons.set_meal;
      case GroceryCategory.bakery:
        return Icons.bakery_dining;
      case GroceryCategory.frozen:
        return Icons.ac_unit;
      case GroceryCategory.pantry:
        return Icons.kitchen;
      case GroceryCategory.beverages:
        return Icons.coffee;
      case GroceryCategory.snacks:
        return Icons.cookie;
      case GroceryCategory.household:
        return Icons.cleaning_services;
      case GroceryCategory.personal:
        return Icons.self_improvement;
      case GroceryCategory.other:
        return Icons.category;
    }
  }

  Color get color {
    switch (this) {
      case GroceryCategory.produce:
        return Colors.green;
      case GroceryCategory.dairy:
        return Colors.blue;
      case GroceryCategory.meat:
        return Colors.red;
      case GroceryCategory.bakery:
        return Colors.orange;
      case GroceryCategory.frozen:
        return Colors.lightBlue;
      case GroceryCategory.pantry:
        return Colors.brown;
      case GroceryCategory.beverages:
        return Colors.amber;
      case GroceryCategory.snacks:
        return Colors.purple;
      case GroceryCategory.household:
        return Colors.teal;
      case GroceryCategory.personal:
        return Colors.pink;
      case GroceryCategory.other:
        return Colors.grey;
    }
  }
}

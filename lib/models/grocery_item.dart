// lib/models/grocery_item.dart
import 'package:equatable/equatable.dart';
import 'package:my_grocery_list/models/category.dart';

class GroceryItem extends Equatable {
  final String id;
  final String name;
  final bool isCompleted;
  final String addedBy;
  final DateTime addedAt;
  final int quantity;
  final GroceryCategory category; // NEW
  final String? notes; // NEW

  const GroceryItem({
    required this.id,
    required this.name,
    this.isCompleted = false,
    required this.addedBy,
    required this.addedAt,
    this.quantity = 1,
    this.category = GroceryCategory.other, // NEW: Default category
    this.notes, // NEW: Optional notes
  });

  /// Create a copy of this item with some fields replaced
  GroceryItem copyWith({
    String? id,
    String? name,
    bool? isCompleted,
    String? addedBy,
    DateTime? addedAt,
    int? quantity,
    GroceryCategory? category, // NEW
    String? notes, // NEW
  }) {
    return GroceryItem(
      id: id ?? this.id,
      name: name ?? this.name,
      isCompleted: isCompleted ?? this.isCompleted,
      addedBy: addedBy ?? this.addedBy,
      addedAt: addedAt ?? this.addedAt,
      quantity: quantity ?? this.quantity,
      category: category ?? this.category, // NEW
      notes: notes ?? this.notes, // NEW
    );
  }

  /// Convert this item to JSON
  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'isCompleted': isCompleted,
      'addedBy': addedBy,
      'addedAt': addedAt.toIso8601String(),
      'quantity': quantity,
      'category': category.name, // NEW
      'notes': notes, // NEW
    };
  }

  /// Create an item from JSON
  factory GroceryItem.fromJson(Map<String, dynamic> json) {
    return GroceryItem(
      id: json['id'] as String,
      name: json['name'] as String,
      isCompleted: json['isCompleted'] as bool? ?? false,
      addedBy: json['addedBy'] as String,
      addedAt: DateTime.parse(json['addedAt'] as String),
      quantity: json['quantity'] as int? ?? 1,
      category:
          json['category'] != null
              ? GroceryCategory.values.firstWhere(
                (e) => e.name == json['category'],
                orElse: () => GroceryCategory.other,
              )
              : GroceryCategory.other, // NEW
      notes: json['notes'] as String?, // NEW
    );
  }

  @override
  List<Object?> get props => [
    id,
    name,
    isCompleted,
    addedBy,
    addedAt,
    quantity,
    category,
    notes,
  ];

  @override
  String toString() {
    return 'GroceryItem(id: $id, name: $name, quantity: $quantity, category: ${category.name}, isCompleted: $isCompleted, addedBy: $addedBy, notes: $notes)';
  }
}

import 'package:equatable/equatable.dart';

class GroceryItem extends Equatable {
  final String id;
  final String name;
  final bool isCompleted;
  final String addedBy;
  final DateTime addedAt;

  const GroceryItem({
    required this.id,
    required this.name,
    this.isCompleted = false,
    required this.addedBy,
    required this.addedAt,
  });

  /// Create a copy of this item with some fields replaced
  GroceryItem copyWith({
    String? id,
    String? name,
    bool? isCompleted,
    String? addedBy,
    DateTime? addedAt,
  }) {
    return GroceryItem(
      id: id ?? this.id,
      name: name ?? this.name,
      isCompleted: isCompleted ?? this.isCompleted,
      addedBy: addedBy ?? this.addedBy,
      addedAt: addedAt ?? this.addedAt,
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
    );
  }

  @override
  List<Object?> get props => [id, name, isCompleted, addedBy, addedAt];

  @override
  String toString() {
    return 'GroceryItem(id: $id, name: $name, isCompleted: $isCompleted, addedBy: $addedBy, addedAt: $addedAt)';
  }
}

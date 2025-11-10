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

  @override
  List<Object?> get props => [id, name, isCompleted, addedBy, addedAt];
}

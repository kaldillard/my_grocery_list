// lib/blocs/grocery/grocery_event.dart
import 'package:equatable/equatable.dart';
import 'package:my_grocery_list/models/category.dart';

abstract class GroceryEvent extends Equatable {
  @override
  List<Object?> get props => [];
}

class LoadGroceryData extends GroceryEvent {}

class AddGroceryItem extends GroceryEvent {
  final String name;
  final String addedByMemberId;
  final int quantity;
  final GroceryCategory category; // NEW
  final String? notes; // NEW

  AddGroceryItem(
    this.name,
    this.addedByMemberId, {
    this.quantity = 1,
    this.category = GroceryCategory.other, // NEW
    this.notes, // NEW
  });

  @override
  List<Object?> get props => [name, addedByMemberId, quantity, category, notes];
}

class ToggleGroceryItem extends GroceryEvent {
  final String id;

  ToggleGroceryItem(this.id);

  @override
  List<Object?> get props => [id];
}

class DeleteGroceryItem extends GroceryEvent {
  final String id;

  DeleteGroceryItem(this.id);

  @override
  List<Object?> get props => [id];
}

class UpdateGroceryItemQuantity extends GroceryEvent {
  final String id;
  final int quantity;

  UpdateGroceryItemQuantity(this.id, this.quantity);

  @override
  List<Object?> get props => [id, quantity];
}

// NEW: Event to update item details
class UpdateGroceryItem extends GroceryEvent {
  final String id;
  final String? name;
  final GroceryCategory? category;
  final String? notes;

  UpdateGroceryItem(this.id, {this.name, this.category, this.notes});

  @override
  List<Object?> get props => [id, name, category, notes];
}

class ClearCompletedItems extends GroceryEvent {}

class GroceryItemsUpdated extends GroceryEvent {
  final List<Map<String, dynamic>> items;

  GroceryItemsUpdated(this.items);

  @override
  List<Object?> get props => [items];
}

import 'package:equatable/equatable.dart';

abstract class GroceryEvent extends Equatable {
  @override
  List<Object?> get props => [];
}

class LoadGroceryData extends GroceryEvent {}

class AddGroceryItem extends GroceryEvent {
  final String name;
  final String addedByMemberId; // Changed from name to member ID

  AddGroceryItem(this.name, this.addedByMemberId);

  @override
  List<Object?> get props => [name, addedByMemberId];
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

class ClearCompletedItems extends GroceryEvent {}

class GroceryItemsUpdated extends GroceryEvent {
  final List<Map<String, dynamic>> items;

  GroceryItemsUpdated(this.items);

  @override
  List<Object?> get props => [items];
}

import 'package:equatable/equatable.dart';

abstract class GroceryEvent extends Equatable {
  @override
  List<Object?> get props => [];
}

class LoadGroceryData extends GroceryEvent {}

class AddGroceryItem extends GroceryEvent {
  final String name;
  final String addedBy;

  AddGroceryItem(this.name, this.addedBy);

  @override
  List<Object?> get props => [name, addedBy];
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

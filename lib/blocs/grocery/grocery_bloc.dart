import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:my_grocery_list/blocs/grocery/grocery_event.dart';
import 'package:my_grocery_list/blocs/grocery/grocery_state.dart';
import 'package:my_grocery_list/models/grocery_item.dart';
import 'package:uuid/uuid.dart';

class GroceryBloc extends Bloc<GroceryEvent, GroceryState> {
  GroceryBloc() : super(const GroceryState()) {
    on<LoadGroceryData>(_onLoadGroceryData);
    on<AddGroceryItem>(_onAddGroceryItem);
    on<ToggleGroceryItem>(_onToggleGroceryItem);
    on<DeleteGroceryItem>(_onDeleteGroceryItem);
    on<ClearCompletedItems>(_onClearCompletedItems);
  }

  Future<void> _onLoadGroceryData(
    LoadGroceryData event,
    Emitter<GroceryState> emit,
  ) async {
    emit(state.copyWith(isLoading: true));
    // Simulate loading from storage
    await Future.delayed(const Duration(milliseconds: 300));
    emit(state.copyWith(isLoading: false));
  }

  void _onAddGroceryItem(AddGroceryItem event, Emitter<GroceryState> emit) {
    final newItem = GroceryItem(
      id: const Uuid().v4(),
      name: event.name,
      addedBy: event.addedBy,
      addedAt: DateTime.now(),
    );
    emit(state.copyWith(items: [...state.items, newItem]));
  }

  void _onToggleGroceryItem(
    ToggleGroceryItem event,
    Emitter<GroceryState> emit,
  ) {
    final updatedItems =
        state.items.map((item) {
          if (item.id == event.id) {
            return item.copyWith(isCompleted: !item.isCompleted);
          }
          return item;
        }).toList();
    emit(state.copyWith(items: updatedItems));
  }

  void _onDeleteGroceryItem(
    DeleteGroceryItem event,
    Emitter<GroceryState> emit,
  ) {
    final updatedItems =
        state.items.where((item) => item.id != event.id).toList();
    emit(state.copyWith(items: updatedItems));
  }

  void _onClearCompletedItems(
    ClearCompletedItems event,
    Emitter<GroceryState> emit,
  ) {
    final updatedItems =
        state.items.where((item) => !item.isCompleted).toList();
    emit(state.copyWith(items: updatedItems));
  }
}

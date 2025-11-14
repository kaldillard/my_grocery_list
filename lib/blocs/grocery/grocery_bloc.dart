// lib/blocs/grocery/grocery_bloc.dart
import 'dart:async';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../services/supabase_service.dart';
import '../../models/grocery_item.dart';
import '../../models/category.dart';
import 'grocery_event.dart';
import 'grocery_state.dart';

class GroceryBloc extends Bloc<GroceryEvent, GroceryState> {
  final SupabaseService supabaseService;
  final String listId;
  RealtimeChannel? _subscription;

  GroceryBloc({required this.supabaseService, required this.listId})
    : super(const GroceryState()) {
    on<LoadGroceryData>(_onLoadGroceryData);
    on<AddGroceryItem>(_onAddGroceryItem);
    on<ToggleGroceryItem>(_onToggleGroceryItem);
    on<DeleteGroceryItem>(_onDeleteGroceryItem);
    on<UpdateGroceryItemQuantity>(_onUpdateGroceryItemQuantity);
    on<UpdateGroceryItem>(_onUpdateGroceryItem); // NEW
    on<ClearCompletedItems>(_onClearCompletedItems);
    on<GroceryItemsUpdated>(_onGroceryItemsUpdated);

    _setupRealtimeSubscription();
  }

  void _setupRealtimeSubscription() {
    print('GroceryBloc - Setting up real-time subscription for list: $listId');

    _subscription = supabaseService.subscribeToGroceryItemsInList(listId, (
      items,
    ) {
      print('GroceryBloc - Real-time update received: ${items.length} items');
      add(GroceryItemsUpdated(items));
    });
  }

  Future<void> _onLoadGroceryData(
    LoadGroceryData event,
    Emitter<GroceryState> emit,
  ) async {
    emit(state.copyWith(isLoading: true));
    try {
      final itemsData = await supabaseService.getGroceryItemsForList(listId);
      final items = _mapToGroceryItems(itemsData);
      emit(state.copyWith(items: items, isLoading: false));
    } catch (e) {
      emit(state.copyWith(isLoading: false));
      print('Error loading grocery items: $e');
    }
  }

  Future<void> _onAddGroceryItem(
    AddGroceryItem event,
    Emitter<GroceryState> emit,
  ) async {
    try {
      await supabaseService.addGroceryItemToList(
        listId: listId,
        name: event.name,
        addedById: event.addedByMemberId,
        quantity: event.quantity,
        category: event.category, // NEW
        notes: event.notes, // NEW
      );
    } catch (e) {
      print('Error adding grocery item: $e');
    }
  }

  Future<void> _onToggleGroceryItem(
    ToggleGroceryItem event,
    Emitter<GroceryState> emit,
  ) async {
    try {
      final item = state.items.firstWhere((i) => i.id == event.id);
      await supabaseService.updateGroceryItem(event.id, !item.isCompleted);
    } catch (e) {
      print('Error toggling grocery item: $e');
    }
  }

  Future<void> _onDeleteGroceryItem(
    DeleteGroceryItem event,
    Emitter<GroceryState> emit,
  ) async {
    try {
      await supabaseService.deleteGroceryItem(event.id);
    } catch (e) {
      print('Error deleting grocery item: $e');
    }
  }

  Future<void> _onUpdateGroceryItemQuantity(
    UpdateGroceryItemQuantity event,
    Emitter<GroceryState> emit,
  ) async {
    try {
      await supabaseService.updateGroceryItemQuantity(event.id, event.quantity);
    } catch (e) {
      print('Error updating grocery item quantity: $e');
    }
  }

  // NEW: Handler for updating item details
  Future<void> _onUpdateGroceryItem(
    UpdateGroceryItem event,
    Emitter<GroceryState> emit,
  ) async {
    try {
      await supabaseService.updateGroceryItemDetails(
        event.id,
        name: event.name,
        category: event.category,
        notes: event.notes,
      );
    } catch (e) {
      print('Error updating grocery item: $e');
    }
  }

  Future<void> _onClearCompletedItems(
    ClearCompletedItems event,
    Emitter<GroceryState> emit,
  ) async {
    try {
      await supabaseService.clearCompletedItemsInList(listId);
    } catch (e) {
      print('Error clearing completed items: $e');
    }
  }

  void _onGroceryItemsUpdated(
    GroceryItemsUpdated event,
    Emitter<GroceryState> emit,
  ) {
    final items = _mapToGroceryItems(event.items);
    emit(state.copyWith(items: items));
  }

  List<GroceryItem> _mapToGroceryItems(List<Map<String, dynamic>> data) {
    return data.map((item) {
      final memberData = item['family_members'] as Map<String, dynamic>?;
      final addedBy = memberData?['display_name'] ?? 'Unknown';

      return GroceryItem(
        id: item['id'] as String,
        name: item['name'] as String,
        isCompleted: item['is_completed'] as bool? ?? false,
        addedBy: addedBy,
        addedAt: DateTime.parse(item['added_at'] as String),
        quantity: item['quantity'] as int? ?? 1,
        category:
            item['category'] != null
                ? GroceryCategory.values.firstWhere(
                  (e) => e.name == item['category'],
                  orElse: () => GroceryCategory.other,
                )
                : GroceryCategory.other, // NEW
        notes: item['notes'] as String?, // NEW
      );
    }).toList();
  }

  @override
  Future<void> close() {
    _subscription?.unsubscribe();
    return super.close();
  }
}

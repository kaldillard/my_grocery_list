// lib/blocs/grocery/grocery_bloc.dart

import 'dart:async';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../services/supabase_service.dart';
import '../../models/grocery_item.dart';
import 'grocery_event.dart';
import 'grocery_state.dart';

class GroceryBloc extends Bloc<GroceryEvent, GroceryState> {
  final SupabaseService supabaseService;
  final String familyId;
  RealtimeChannel? _subscription;

  GroceryBloc({required this.supabaseService, required this.familyId})
    : super(const GroceryState()) {
    on<LoadGroceryData>(_onLoadGroceryData);
    on<AddGroceryItem>(_onAddGroceryItem);
    on<ToggleGroceryItem>(_onToggleGroceryItem);
    on<DeleteGroceryItem>(_onDeleteGroceryItem);
    on<ClearCompletedItems>(_onClearCompletedItems);
    on<GroceryItemsUpdated>(_onGroceryItemsUpdated);

    // Subscribe to real-time updates
    _setupRealtimeSubscription();
  }

  void _setupRealtimeSubscription() {
    print(
      'GroceryBloc - Setting up real-time subscription for family: $familyId',
    );

    _subscription = supabaseService.subscribeToGroceryItems(familyId, (items) {
      print('GroceryBloc - Real-time update received: ${items.length} items');
      add(GroceryItemsUpdated(items));
    });

    // Check if subscription was successful
    // print('GroceryBloc - Subscription status: ${_subscription?.status}');
  }

  Future<void> _onLoadGroceryData(
    LoadGroceryData event,
    Emitter<GroceryState> emit,
  ) async {
    emit(state.copyWith(isLoading: true));
    try {
      final itemsData = await supabaseService.getGroceryItems(familyId);
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
      await supabaseService.addGroceryItem(
        familyId: familyId,
        name: event.name,
        addedById: event.addedByMemberId,
      );
      // Real-time subscription will handle the update
    } catch (e) {
      print('Error adding grocery item: $e');
    }
  }

  Future<void> _onToggleGroceryItem(
    ToggleGroceryItem event,
    Emitter<GroceryState> emit,
  ) async {
    try {
      // Find the item to get its current state
      final item = state.items.firstWhere((i) => i.id == event.id);
      await supabaseService.updateGroceryItem(event.id, !item.isCompleted);
      // Real-time subscription will handle the update
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
      // Real-time subscription will handle the update
    } catch (e) {
      print('Error deleting grocery item: $e');
    }
  }

  Future<void> _onClearCompletedItems(
    ClearCompletedItems event,
    Emitter<GroceryState> emit,
  ) async {
    try {
      await supabaseService.clearCompletedItems(familyId);
      // Real-time subscription will handle the update
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
      // Extract member info from the joined data
      final memberData = item['family_members'] as Map<String, dynamic>?;
      final addedBy = memberData?['display_name'] ?? 'Unknown';

      return GroceryItem(
        id: item['id'] as String,
        name: item['name'] as String,
        isCompleted: item['is_completed'] as bool? ?? false,
        addedBy: addedBy,
        addedAt: DateTime.parse(item['added_at'] as String),
      );
    }).toList();
  }

  @override
  Future<void> close() {
    _subscription?.unsubscribe();
    return super.close();
  }
}

// lib/blocs/grocery/grocery_state.dart
import 'package:equatable/equatable.dart';
import 'package:my_grocery_list/models/grocery_item.dart';
import 'package:my_grocery_list/models/category.dart';

class GroceryState extends Equatable {
  final List<GroceryItem> items;
  final bool isLoading;
  final GroceryCategory? selectedCategory; // NEW: Optional filter

  const GroceryState({
    this.items = const [],
    this.isLoading = false,
    this.selectedCategory,
  });

  GroceryState copyWith({
    List<GroceryItem>? items,
    bool? isLoading,
    GroceryCategory? selectedCategory,
  }) {
    return GroceryState(
      items: items ?? this.items,
      isLoading: isLoading ?? this.isLoading,
      selectedCategory: selectedCategory ?? this.selectedCategory,
    );
  }

  // Helper getters
  List<GroceryItem> get activeItems =>
      items.where((item) => !item.isCompleted).toList();

  List<GroceryItem> get completedItems =>
      items.where((item) => item.isCompleted).toList();

  // Get items by category
  List<GroceryItem> itemsByCategory(GroceryCategory category) =>
      items.where((item) => item.category == category).toList();

  // Get category counts
  Map<GroceryCategory, int> get categoryCounts {
    final counts = <GroceryCategory, int>{};
    for (var item in activeItems) {
      counts[item.category] = (counts[item.category] ?? 0) + 1;
    }
    return counts;
  }

  // Progress tracking
  double get completionPercentage {
    if (items.isEmpty) return 0.0;
    return completedItems.length / items.length;
  }

  int get totalQuantity {
    return activeItems.fold(0, (sum, item) => sum + item.quantity);
  }

  @override
  List<Object?> get props => [items, isLoading, selectedCategory];
}

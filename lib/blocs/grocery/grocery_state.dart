import 'package:equatable/equatable.dart';
import 'package:my_grocery_list/models/grocery_item.dart';

class GroceryState extends Equatable {
  final List<GroceryItem> items;
  final bool isLoading;

  const GroceryState({this.items = const [], this.isLoading = false});

  GroceryState copyWith({List<GroceryItem>? items, bool? isLoading}) {
    return GroceryState(
      items: items ?? this.items,
      isLoading: isLoading ?? this.isLoading,
    );
  }

  @override
  List<Object?> get props => [items, isLoading];
}

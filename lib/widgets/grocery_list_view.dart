// lib/widgets/grocery_list_view.dart
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:my_grocery_list/blocs/family/family_bloc.dart';
import 'package:my_grocery_list/blocs/family/family_state.dart';
import 'package:my_grocery_list/blocs/grocery/grocery_bloc.dart';
import 'package:my_grocery_list/blocs/grocery/grocery_state.dart';
import 'package:my_grocery_list/models/category.dart';
import 'package:my_grocery_list/models/grocery_item.dart';
import 'package:my_grocery_list/widgets/grocery_tile.dart';

class GroceryListView extends StatefulWidget {
  const GroceryListView({super.key});

  @override
  State<GroceryListView> createState() => _GroceryListViewState();
}

class _GroceryListViewState extends State<GroceryListView> {
  bool _groupByCategory = true;

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<GroceryBloc, GroceryState>(
      builder: (context, groceryState) {
        return BlocBuilder<FamilyBloc, FamilyState>(
          builder: (context, familyState) {
            if (groceryState.isLoading) {
              return const Center(child: CircularProgressIndicator());
            }

            if (groceryState.items.isEmpty) {
              return const Center(
                child: Text(
                  'No items yet.\nAdd your first grocery item!',
                  textAlign: TextAlign.center,
                  style: TextStyle(fontSize: 16, color: Colors.grey),
                ),
              );
            }

            final activeItems =
                groceryState.items.where((i) => !i.isCompleted).toList();
            final completedItems =
                groceryState.items.where((i) => i.isCompleted).toList();

            return Column(
              children: [
                // Toggle for grouping
                Padding(
                  padding: const EdgeInsets.all(8.0),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.end,
                    children: [
                      const Text('Group by category'),
                      Switch(
                        value: _groupByCategory,
                        onChanged: (value) {
                          setState(() => _groupByCategory = value);
                        },
                      ),
                    ],
                  ),
                ),
                Expanded(
                  child: ListView(
                    children: [
                      if (activeItems.isNotEmpty) ...[
                        const Padding(
                          padding: EdgeInsets.fromLTRB(16, 8, 16, 8),
                          child: Text(
                            'TO BUY',
                            style: TextStyle(
                              fontSize: 14,
                              fontWeight: FontWeight.bold,
                              color: Colors.grey,
                            ),
                          ),
                        ),
                        if (_groupByCategory)
                          ..._buildGroupedItems(activeItems, familyState)
                        else
                          ...activeItems.map(
                            (item) => GroceryTile(
                              item: item,
                              familyState: familyState,
                            ),
                          ),
                      ],
                      if (completedItems.isNotEmpty) ...[
                        const Padding(
                          padding: EdgeInsets.fromLTRB(16, 16, 16, 8),
                          child: Text(
                            'COMPLETED',
                            style: TextStyle(
                              fontSize: 14,
                              fontWeight: FontWeight.bold,
                              color: Colors.grey,
                            ),
                          ),
                        ),
                        ...completedItems.map(
                          (item) =>
                              GroceryTile(item: item, familyState: familyState),
                        ),
                      ],
                    ],
                  ),
                ),
              ],
            );
          },
        );
      },
    );
  }

  List<Widget> _buildGroupedItems(
    List<GroceryItem> items,
    FamilyState familyState,
  ) {
    final grouped = <GroceryCategory, List<GroceryItem>>{};

    for (var item in items) {
      grouped.putIfAbsent(item.category, () => []).add(item);
    }

    final sortedCategories =
        grouped.keys.toList()
          ..sort((a, b) => a.displayName.compareTo(b.displayName));

    return sortedCategories.expand((category) {
      final categoryItems = grouped[category]!;
      return [
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 12, 16, 4),
          child: Row(
            children: [
              Icon(category.icon, size: 18, color: category.color),
              const SizedBox(width: 8),
              Text(
                category.displayName,
                style: TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                  color: category.color,
                ),
              ),
              const SizedBox(width: 8),
              Text(
                '(${categoryItems.length})',
                style: TextStyle(fontSize: 12, color: Colors.grey[600]),
              ),
            ],
          ),
        ),
        ...categoryItems.map(
          (item) => GroceryTile(item: item, familyState: familyState),
        ),
      ];
    }).toList();
  }
}

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:my_grocery_list/blocs/family/family_bloc.dart';
import 'package:my_grocery_list/blocs/family/family_state.dart';
import 'package:my_grocery_list/blocs/grocery/grocery_bloc.dart';
import 'package:my_grocery_list/blocs/grocery/grocery_state.dart';
import 'package:my_grocery_list/widgets/grocery_tile.dart';

class GroceryListView extends StatefulWidget {
  const GroceryListView({super.key});

  @override
  State<GroceryListView> createState() => _GroceryListViewState();
}

class _GroceryListViewState extends State<GroceryListView> {
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

            return ListView(
              children: [
                if (activeItems.isNotEmpty) ...[
                  const Padding(
                    padding: EdgeInsets.fromLTRB(16, 8, 16, 8),
                    child: Text(
                      'TO BUY',
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.bold,
                        color: Colors.grey,
                      ),
                    ),
                  ),
                  ...activeItems.map(
                    (item) => GroceryTile(item: item, familyState: familyState),
                  ),
                ],
                if (completedItems.isNotEmpty) ...[
                  const Padding(
                    padding: EdgeInsets.fromLTRB(16, 16, 16, 8),
                    child: Text(
                      'COMPLETED',
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.bold,
                        color: Colors.grey,
                      ),
                    ),
                  ),
                  ...completedItems.map(
                    (item) => GroceryTile(item: item, familyState: familyState),
                  ),
                ],
              ],
            );
          },
        );
      },
    );
  }
}

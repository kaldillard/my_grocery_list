import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:my_grocery_list/blocs/family/family_bloc.dart';
import 'package:my_grocery_list/blocs/family/family_event.dart';
import 'package:my_grocery_list/blocs/family/family_state.dart';
import 'package:my_grocery_list/blocs/grocery/grocery_bloc.dart';
import 'package:my_grocery_list/blocs/grocery/grocery_event.dart';
import 'package:my_grocery_list/blocs/grocery/grocery_state.dart';
import 'package:my_grocery_list/models/family_member.dart';
import 'package:my_grocery_list/models/grocery_item.dart';
import 'package:my_grocery_list/utils/color_utils.dart';
import 'package:my_grocery_list/widgets/add_item_input.dart';
import 'package:my_grocery_list/widgets/family_manager_sheet.dart';
import 'package:my_grocery_list/widgets/family_selector.dart';
import 'package:my_grocery_list/widgets/grocery_list_view.dart';

class GroceryListScreen extends StatelessWidget {
  const GroceryListScreen({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Family Grocery List'),
        actions: [
          IconButton(
            icon: const Icon(Icons.people),
            onPressed: () => _showFamilyManager(context),
          ),
          BlocBuilder<GroceryBloc, GroceryState>(
            builder: (context, state) {
              final hasCompleted = state.items.any((item) => item.isCompleted);
              return hasCompleted
                  ? IconButton(
                    icon: const Icon(Icons.delete_sweep),
                    onPressed: () {
                      context.read<GroceryBloc>().add(ClearCompletedItems());
                    },
                  )
                  : const SizedBox.shrink();
            },
          ),
        ],
      ),
      body: Column(
        children: [
          FamilySelector(),

          Expanded(child: GroceryListView()),
          AddItemInput(),
        ],
      ),
    );
  }

  void _showFamilyManager(BuildContext context) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      builder: (context) => const FamilyManagerSheet(),
    );
  }
}

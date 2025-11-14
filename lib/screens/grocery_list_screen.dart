// lib/screens/grocery_list_screen.dart
import 'dart:io' show Platform;
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:my_grocery_list/blocs/grocery/grocery_bloc.dart';
import 'package:my_grocery_list/blocs/grocery/grocery_event.dart';
import 'package:my_grocery_list/blocs/grocery/grocery_state.dart';
import 'package:my_grocery_list/screens/family_member_screen.dart';
import 'package:my_grocery_list/screens/shopping_mode_screen.dart';
import 'package:my_grocery_list/screens/subscription_screen.dart';
import 'package:my_grocery_list/services/supabase_service.dart';
import 'package:my_grocery_list/widgets/add_item_input.dart';
import 'package:my_grocery_list/widgets/family_manager_sheet.dart';
import 'package:my_grocery_list/widgets/grocery_list_view.dart';

class GroceryListScreen extends StatelessWidget {
  final String familyId;
  final String familyName;
  const GroceryListScreen({
    super.key,
    required this.familyId,
    required this.familyName,
  });

  bool get _canShowSubscription {
    if (kIsWeb) return true;
    try {
      return !Platform.isIOS;
    } catch (e) {
      return true;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Family Grocery List'),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios),
          onPressed: () {
            Navigator.pop(context);
          },
        ),
        actions: [
          // Shopping mode button
          BlocBuilder<GroceryBloc, GroceryState>(
            builder: (context, state) {
              final hasActiveItems = state.items.any(
                (item) => !item.isCompleted,
              );
              return IconButton(
                icon: const Icon(Icons.shopping_cart),
                tooltip: 'Shopping Mode',
                onPressed:
                    hasActiveItems
                        ? () {
                          // Pass the existing GroceryBloc to ShoppingModeScreen
                          Navigator.of(context).push(
                            MaterialPageRoute(
                              builder:
                                  (_) => BlocProvider.value(
                                    value: context.read<GroceryBloc>(),
                                    child: const ShoppingModeScreen(),
                                  ),
                            ),
                          );
                        }
                        : null,
              );
            },
          ),

          if (_canShowSubscription)
            IconButton(
              icon: const Icon(Icons.workspace_premium),
              tooltip: 'Manage Subscription',
              onPressed: () {
                final supabaseService = context.read<SupabaseService>();
                final familyId = supabaseService.getSelectedFamilyId();

                Navigator.of(context).push(
                  MaterialPageRoute(
                    builder: (_) => SubscriptionScreen(familyId: familyId),
                  ),
                );
              },
            ),

          IconButton(
            icon: const Icon(Icons.people),
            tooltip: 'Manage Family Members',
            onPressed: () {
              Navigator.of(context).push(
                MaterialPageRoute(
                  builder:
                      (_) => FamilyMembersScreen(
                        familyId: familyId,
                        familyName: familyName,
                      ),
                ),
              );
            },
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
          const Expanded(child: GroceryListView()),
          const AddItemInput(),
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

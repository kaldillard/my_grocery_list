// lib/screens/grocery_list_screen.dart
import 'dart:io' show Platform;
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:my_grocery_list/blocs/grocery/grocery_bloc.dart';
import 'package:my_grocery_list/blocs/grocery/grocery_event.dart';
import 'package:my_grocery_list/blocs/grocery/grocery_state.dart';
import 'package:my_grocery_list/screens/family_list_screen.dart';
import 'package:my_grocery_list/screens/subscription_screen.dart';
import 'package:my_grocery_list/services/supabase_service.dart';
import 'package:my_grocery_list/widgets/add_item_input.dart';
import 'package:my_grocery_list/widgets/family_manager_sheet.dart';
import 'package:my_grocery_list/widgets/family_selector.dart';
import 'package:my_grocery_list/widgets/grocery_list_view.dart';

class GroceryListScreen extends StatelessWidget {
  const GroceryListScreen({Key? key}) : super(key: key);

  // Helper to check if we should show subscription button
  bool get _canShowSubscription {
    // Only show on Web and Android (not iOS)
    if (kIsWeb) return true;
    try {
      return !Platform.isIOS; // Hide on iOS to comply with App Store rules
    } catch (e) {
      return true; // Default to showing if platform check fails
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Family Grocery List'),
        leading: IconButton(
          icon: const Icon(Icons.list),
          onPressed: () {
            Navigator.of(
              context,
            ).push(MaterialPageRoute(builder: (_) => const FamilyListScreen()));
          },
        ),
        actions: [
          // Only show subscription button on non-iOS platforms
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

// lib/screens/shopping_mode_screen.dart
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:my_grocery_list/blocs/grocery/grocery_bloc.dart';
import 'package:my_grocery_list/blocs/grocery/grocery_event.dart';
import 'package:my_grocery_list/blocs/grocery/grocery_state.dart';
import 'package:my_grocery_list/models/category.dart';
import 'package:my_grocery_list/models/grocery_item.dart';

class ShoppingModeScreen extends StatefulWidget {
  const ShoppingModeScreen({super.key});

  @override
  State<ShoppingModeScreen> createState() => _ShoppingModeScreenState();
}

class _ShoppingModeScreenState extends State<ShoppingModeScreen> {
  bool _groupByCategory = true;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[100],
      appBar: AppBar(
        title: const Text('Shopping Mode'),
        actions: [
          IconButton(
            icon: Icon(_groupByCategory ? Icons.category : Icons.list),
            onPressed: () {
              setState(() => _groupByCategory = !_groupByCategory);
            },
          ),
        ],
      ),
      body: BlocBuilder<GroceryBloc, GroceryState>(
        builder: (context, state) {
          if (state.isLoading) {
            return const Center(child: CircularProgressIndicator());
          }

          final activeItems = state.items.where((i) => !i.isCompleted).toList();

          if (activeItems.isEmpty) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    Icons.check_circle_outline,
                    size: 80,
                    color: Colors.green[300],
                  ),
                  const SizedBox(height: 16),
                  const Text(
                    'All items checked off!',
                    style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 8),
                  const Text(
                    'You\'re done shopping!',
                    style: TextStyle(color: Colors.grey),
                  ),
                ],
              ),
            );
          }

          return Column(
            children: [
              // Progress bar
              Container(
                padding: const EdgeInsets.all(16),
                color: Colors.white,
                child: Column(
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          '${state.items.where((i) => i.isCompleted).length} / ${state.items.length}',
                          style: const TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        Text(
                          '${activeItems.length} remaining',
                          style: TextStyle(color: Colors.grey[600]),
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    LinearProgressIndicator(
                      value:
                          state.items.isEmpty
                              ? 0
                              : state.items.where((i) => i.isCompleted).length /
                                  state.items.length,
                      minHeight: 8,
                      borderRadius: BorderRadius.circular(4),
                    ),
                  ],
                ),
              ),

              // Items list
              Expanded(
                child:
                    _groupByCategory
                        ? _buildGroupedList(activeItems)
                        : _buildSimpleList(activeItems),
              ),
            ],
          );
        },
      ),
    );
  }

  Widget _buildSimpleList(List<GroceryItem> items) {
    return ListView.builder(
      padding: const EdgeInsets.all(8),
      itemCount: items.length,
      itemBuilder: (context, index) {
        final item = items[index];
        return _buildShoppingTile(item);
      },
    );
  }

  Widget _buildGroupedList(List<GroceryItem> items) {
    final grouped = <GroceryCategory, List<GroceryItem>>{};

    for (var item in items) {
      grouped.putIfAbsent(item.category, () => []).add(item);
    }

    final sortedCategories =
        grouped.keys.toList()
          ..sort((a, b) => a.displayName.compareTo(b.displayName));

    return ListView.builder(
      padding: const EdgeInsets.all(8),
      itemCount: sortedCategories.length,
      itemBuilder: (context, index) {
        final category = sortedCategories[index];
        final categoryItems = grouped[category]!;

        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Category header
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              margin: const EdgeInsets.only(top: 8),
              decoration: BoxDecoration(
                color: category.color.withOpacity(0.1),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Row(
                children: [
                  Icon(category.icon, color: category.color, size: 24),
                  const SizedBox(width: 12),
                  Text(
                    category.displayName,
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: category.color,
                    ),
                  ),
                  const SizedBox(width: 8),
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 8,
                      vertical: 2,
                    ),
                    decoration: BoxDecoration(
                      color: category.color,
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Text(
                      '${categoryItems.length}',
                      style: const TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.bold,
                        fontSize: 12,
                      ),
                    ),
                  ),
                ],
              ),
            ),
            // Category items
            ...categoryItems.map((item) => _buildShoppingTile(item)),
          ],
        );
      },
    );
  }

  Widget _buildShoppingTile(GroceryItem item) {
    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      elevation: 2,
      child: InkWell(
        onTap: () {
          context.read<GroceryBloc>().add(ToggleGroceryItem(item.id));
        },
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Row(
            children: [
              // Large checkbox
              Container(
                width: 32,
                height: 32,
                decoration: BoxDecoration(
                  border: Border.all(color: Colors.grey[400]!, width: 2),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: const Icon(Icons.check, size: 0), // Empty for now
              ),
              const SizedBox(width: 16),

              // Item details
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Expanded(
                          child: Text(
                            item.name,
                            style: const TextStyle(
                              fontSize: 20,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ),
                        if (item.quantity > 1)
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 12,
                              vertical: 4,
                            ),
                            decoration: BoxDecoration(
                              color: Colors.blue[100],
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: Text(
                              'x${item.quantity}',
                              style: TextStyle(
                                fontWeight: FontWeight.bold,
                                color: Colors.blue[900],
                                fontSize: 16,
                              ),
                            ),
                          ),
                      ],
                    ),
                    if (item.notes != null && item.notes!.isNotEmpty) ...[
                      const SizedBox(height: 4),
                      Text(
                        item.notes!,
                        style: TextStyle(
                          fontSize: 14,
                          color: Colors.grey[700],
                          fontStyle: FontStyle.italic,
                        ),
                      ),
                    ],
                  ],
                ),
              ),

              // Category icon
              const SizedBox(width: 8),
              Icon(
                item.category.icon,
                color: item.category.color.withOpacity(0.5),
                size: 24,
              ),
            ],
          ),
        ),
      ),
    );
  }
}
